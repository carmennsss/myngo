import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import Salas_chat, Mensajes_chat, Participantes_chat
from usuarios.models import Usuario, Perfil


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'chat_{self.room_id}'
        self.user = self.scope['user']

        if self.user.is_anonymous:
            await self.close()
            return

        # Verificar si el usuario es miembro de la sala
        is_member = await self.is_member(self.user, self.room_id)
        if not is_member:
            await self.close()
            return

        # Unirse al grupo de la sala
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        # Marcar mensajes previos como leídos
        updated_count = await self.marcar_mensajes_como_leidos()
        
        if updated_count > 0:
            # Notificar a los demás que sus mensajes han sido leídos
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'messages_read',
                    'user_id': self.user.id
                }
            )

        # Notificar a los demás que se ha unido
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_joined',
                'user_id': self.user.id,
                'username': self.user.nombre_usuario or f"Usuario_{self.user.id}"
            }
        )

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            # Salir del grupo de la sala
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type', 'message')

        if message_type == 'message':
            content = data.get('content')
            if content:
                # Guardar en BD
                msg = await self.save_message(self.user, self.room_id, content)

                # Broadcast al canal de la sala
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': msg.id,
                        'client_id': data.get('client_id'), # Devolver el ID temporal del cliente
                        'content': content,
                        'user_id': self.user.id,
                        'username': self.user.nombre_usuario,
                        'timestamp': msg.fecha_envio.isoformat(),
                        'leido': False,
                    }
                )

                # Notificar a cada miembro (excepto el emisor) por su canal personal
                miembros_ids = await self.get_miembros_ids(self.room_id, exclude_user_id=self.user.id)
                sala_nombre = await self.get_sala_nombre(self.room_id)
                sender_avatar = await self.get_user_avatar(self.user.id)
                preview = content[:60] + ('...' if len(content) > 60 else '')

                for miembro_id in miembros_ids:
                    await self.channel_layer.group_send(
                        f'user_{miembro_id}_notif',
                        {
                            'type': 'new_message_notification',
                            'sala_id': int(self.room_id),
                            'sala_nombre': sala_nombre,
                            'sender_id': self.user.id,
                            'sender_username': self.user.nombre_usuario,
                            'sender_avatar': sender_avatar,
                            'preview': preview,
                        }
                    )

        elif message_type == 'read_messages':
            # El cliente indica que ha leído los mensajes de esta sala
            updated_count = await self.marcar_mensajes_como_leidos()
            if updated_count > 0:
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'messages_read',
                        'user_id': self.user.id
                    }
                )

        elif message_type == 'add_member':
            target_user_id = data.get('user_id')
            if target_user_id:
                success = await self.add_member_to_room(target_user_id, self.room_id)
                if success:
                    await self.channel_layer.group_send(
                        self.room_group_name,
                        {
                            'type': 'member_added',
                            'user_id': target_user_id,
                            'added_by': self.user.nombre_usuario
                        }
                    )

    # ── Handlers para eventos de grupo ────────────────────────────────
    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event))

    async def user_joined(self, event):
        # Evitar mostrar el mensaje de sistema al propio usuario que se acaba de conectar
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def user_left(self, event):
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def member_added(self, event):
        await self.send(text_data=json.dumps(event))

    async def messages_read(self, event):
        """Notifica al emisor que sus mensajes han sido leídos."""
        await self.send(text_data=json.dumps(event))

    # ── Métodos de BD ─────────────────────────────────────────────────
    @database_sync_to_async
    def is_member(self, user, room_id):
        return Salas_chat.objects.filter(id=room_id, miembros=user).exists()

    @database_sync_to_async
    def save_message(self, user, room_id, content):
        room = Salas_chat.objects.get(id=room_id)
        return Mensajes_chat.objects.create(sala=room, emisor=user, contenido=content)

    @database_sync_to_async
    def marcar_mensajes_como_leidos(self):
        """Marca como leídos los mensajes de la sala que el usuario no ha enviado."""
        # Buscamos mensajes que NO son del usuario actual y están sin leer
        mensajes = Mensajes_chat.objects.filter(
            sala_id=self.room_id,
            es_leido=False
        ).exclude(emisor=self.user)
        
        count = mensajes.count()
        if count > 0:
            mensajes.update(es_leido=True, fecha_lectura=timezone.now())
        return count

    @database_sync_to_async
    def get_miembros_ids(self, room_id, exclude_user_id=None):
        qs = Salas_chat.objects.get(id=room_id).miembros.all()
        if exclude_user_id:
            qs = qs.exclude(id=exclude_user_id)
        return list(qs.values_list('id', flat=True))

    @database_sync_to_async
    def get_sala_nombre(self, room_id):
        return Salas_chat.objects.get(id=room_id).nombre

    @database_sync_to_async
    def add_member_to_room(self, user_id, room_id):
        try:
            room = Salas_chat.objects.get(id=room_id)
            user = Usuario.objects.get(id=user_id)
            room.miembros.add(user)
            return True
        except Exception:
            return False
    @database_sync_to_async
    def get_user_avatar(self, user_id):
        try:
            perfil = Perfil.objects.get(usuario_id=user_id)
            return perfil.avatar.url if perfil.avatar else None
        except Exception:
            return None

class PresenceConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return

        self.group_name = 'online_users'

        # Unirse al grupo global de presencia
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

        # Marcar como online en BD y obtener el estado resultante (ACTIVO u OCUPADO)
        estado_actual = await self.establecer_usuario_online(True)

        # 1. Enviar al propio cliente confirmación de su estado y snapshot global
        online_ids = await self.get_online_user_ids()
        await self.send(text_data=json.dumps({
            'type': 'presence_connection_established',
            'user_id': self.user.id,
            'status': estado_actual,
            'online_users': online_ids,
        }))

        # 2. Notificar al resto del grupo que este usuario se ha conectado
        await self.channel_layer.group_send(
            self.group_name,
            {
                'type': 'status_change',
                'user_id': self.user.id,
                'status': estado_actual
            }
        )

    async def disconnect(self, close_code):
        if not self.user.is_anonymous:
            # Marcar como DESCONECTADO en BD
            await self.establecer_usuario_online(False)

            # Notificar al grupo
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'status_change',
                    'user_id': self.user.id,
                    'status': 'DESCONECTADO',
                    'last_seen': timezone.now().isoformat()
                }
            )

            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        data = json.loads(text_data)
        if data.get('type') == 'heartbeat':
            pass

    async def status_change(self, event):
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def establecer_usuario_online(self, is_online):
        try:
            # Obtenemos el perfil fresco de la BD
            perfil = Perfil.objects.get(usuario=self.user)
            perfil.esta_online = is_online
            
            if is_online:
                # Si se conecta y NO está ocupado, pasa a ACTIVO
                if perfil.estado != 'OCUPADO':
                    perfil.estado = 'ACTIVO'
            else:
                # Si se desconecta, pasa a DESCONECTADO
                perfil.estado = 'DESCONECTADO'
                perfil.last_seen = timezone.now()
            
            perfil.save()
            return perfil.estado
        except Exception:
            return 'DESCONECTADO'

    @database_sync_to_async
    def get_online_user_ids(self):
        """Retorna la lista de IDs de usuarios actualmente online según la BD."""
        return list(Perfil.objects.filter(esta_online=True).values_list('usuario_id', flat=True))


class NotificacionesChatConsumer(AsyncWebsocketConsumer):
    """
    Canal WebSocket personal por usuario.
    Recibe notificaciones de nuevos mensajes en cualquier sala
    aunque el usuario no esté en la pantalla de chat.
    """
    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return

        self.group_name = f'user_{self.user.id}_notif'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        # Este consumer solo recibe, no procesa mensajes del cliente
        pass

    async def new_message_notification(self, event):
        """Reenvía la notificación de nuevo mensaje al cliente Flutter."""
        await self.send(text_data=json.dumps(event))
