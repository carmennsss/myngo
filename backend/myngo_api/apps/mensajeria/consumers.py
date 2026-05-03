"""Consumidores de WebSocket para el sistema de chat y presencia.

Incluye la lógica de envío/recepción de mensajes en tiempo real,
gestión de estado online/offline (presencia) y notificaciones push.
"""

import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.utils import timezone

from usuarios.models import Perfil, Usuario
from .models import MensajeChat, SalaChat


class ChatConsumer(AsyncWebsocketConsumer):
    """Consumidor para la comunicación en tiempo real dentro de una sala de chat."""

    async def connect(self):
        """Establece la conexión WebSocket y valida la pertenencia a la sala."""
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
        leidos_ids = await self.marcar_mensajes_como_leidos()
        
        if leidos_ids:
            # Notificar a los demás que sus mensajes han sido leídos
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'messages_read',
                    'leidos_ids': leidos_ids,
                    'leido_por': self.user.id
                }
            )

        # Notificar a los demás que se ha unido (solo en comunidades)
        is_community = await self.is_community_room(self.room_id)
        if is_community:
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_joined',
                    'user_id': self.user.id,
                    'username': self.user.nombre_usuario or f"Usuario_{self.user.id}"
                }
            )

    async def disconnect(self, close_code):
        """Abandona el grupo de la sala al desconectarse."""
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        """Procesa los mensajes entrantes del cliente WebSocket."""
        data = json.loads(text_data)
        message_type = data.get('type', 'message')

        if message_type == 'message':
            content = data.get('content')
            if content:
                # Guardar en BD
                msg = await self.save_message(self.user, self.room_id, content, referencia_id=data.get('referencia_a'))

                # Broadcast al canal de la sala
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': msg.id,
                        'client_id': data.get('client_id'),
                        'content': content,
                        'user_id': self.user.id,
                        'username': self.user.nombre_usuario,
                        'timestamp': msg.fecha_envio.isoformat(),
                        'leido_por_ids': [],
                        'referencia_a': data.get('referencia_a'),
                        'referencia_a_detalle': await self.get_msg_detail(data.get('referencia_a')),
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
            leidos_ids = await self.marcar_mensajes_como_leidos()
            if leidos_ids:
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'messages_read',
                        'leidos_ids': leidos_ids,
                        'leido_por': self.user.id
                    }
                )

        elif message_type == 'typing':
            # Notificar que el usuario está escribiendo
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_typing',
                    'user_id': self.user.id,
                    'username': self.user.nombre_usuario,
                    'is_typing': data.get('is_typing', True)
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
        """Envía el mensaje de chat al cliente."""
        await self.send(text_data=json.dumps(event))

    async def user_joined(self, event):
        """Notifica que un usuario se ha unido (excepto a él mismo)."""
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def user_left(self, event):
        """Notifica que un usuario ha salido (excepto a él mismo)."""
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def member_added(self, event):
        """Notifica que un nuevo miembro fue añadido a la sala."""
        await self.send(text_data=json.dumps(event))

    async def messages_read(self, event):
        """Notifica que los mensajes han sido leídos."""
        await self.send(text_data=json.dumps(event))

    async def user_typing(self, event):
        """Notifica que un usuario está escribiendo."""
        # No enviamos la notificación al propio usuario que escribe
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def message_edited(self, event):
        """Notifica que un mensaje ha sido editado."""
        await self.send(text_data=json.dumps(event))

    async def message_deleted(self, event):
        """Notifica que un mensaje ha sido borrado para todos."""
        await self.send(text_data=json.dumps(event))

    # ── Métodos de BD ─────────────────────────────────────────────────

    @database_sync_to_async
    def is_member(self, user, room_id):
        """Verifica si el usuario pertenece a la sala de chat."""
        return SalaChat.objects.filter(id=room_id, miembros=user).exists()

    @database_sync_to_async
    def is_community_room(self, room_id):
        """Verifica si la sala pertenece a una comunidad."""
        try:
            return SalaChat.objects.get(id=room_id).comunidad is not None
        except SalaChat.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, user, room_id, content, referencia_id=None):
        """Guarda un nuevo mensaje en la base de datos."""
        room = SalaChat.objects.get(id=room_id)
        return MensajeChat.objects.create(
            sala=room, 
            emisor=user, 
            contenido=content,
            referencia_a_id=referencia_id
        )

    @database_sync_to_async
    def marcar_mensajes_como_leidos(self):
        """Marca como leídos los mensajes no leídos por el usuario actual."""
        mensajes = MensajeChat.objects.filter(
            sala_id=self.room_id,
        ).exclude(leido_por=self.user).exclude(emisor_id=self.user.id)
        
        ids = list(mensajes.values_list('id', flat=True))
        if ids:
            for msg in mensajes:
                msg.leido_por.add(self.user)
        return ids

    @database_sync_to_async
    def get_msg_detail(self, msg_id):
        if not msg_id: return None
        try:
            m = MensajeChat.objects.get(id=msg_id)
            return {
                'id': m.id,
                'emisor_nombre': m.emisor.nombre_usuario,
                'contenido': m.contenido if not m.borrado_para_todos else 'Mensaje borrado'
            }
        except: return None

    @database_sync_to_async
    def get_miembros_ids(self, room_id, exclude_user_id=None):
        """Obtiene la lista de IDs de todos los miembros de la sala."""
        qs = SalaChat.objects.get(id=room_id).miembros.all()
        if exclude_user_id:
            qs = qs.exclude(id=exclude_user_id)
        return list(qs.values_list('id', flat=True))

    @database_sync_to_async
    def get_sala_nombre(self, room_id):
        """Obtiene el nombre de la sala de chat."""
        return SalaChat.objects.get(id=room_id).nombre

    @database_sync_to_async
    def add_member_to_room(self, user_id, room_id):
        """Añade un usuario a la sala de chat."""
        try:
            room = SalaChat.objects.get(id=room_id)
            user = Usuario.objects.get(id=user_id)
            room.miembros.add(user)
            return True
        except Exception:
            return False

    @database_sync_to_async
    def get_user_avatar(self, user_id):
        """Obtiene la URL del avatar de un usuario."""
        try:
            perfil = Perfil.objects.get(usuario_id=user_id)
            return perfil.avatar.url if perfil.avatar else None
        except Exception:
            return None


class PresenceConsumer(AsyncWebsocketConsumer):
    """Consumidor global para gestionar el estado de presencia (online/offline)."""

    async def connect(self):
        """Establece conexión de presencia y marca al usuario como online."""
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return

        self.group_name = 'online_users'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

        estado_actual = await self.establecer_usuario_online(True)

        online_ids = await self.get_online_user_ids()
        await self.send(text_data=json.dumps({
            'type': 'presence_connection_established',
            'user_id': self.user.id,
            'status': estado_actual,
            'online_users': online_ids,
        }))

        await self.channel_layer.group_send(
            self.group_name,
            {
                'type': 'status_change',
                'user_id': self.user.id,
                'status': estado_actual
            }
        )

    async def disconnect(self, close_code):
        """Marca al usuario como offline al desconectarse."""
        if not self.user.is_anonymous:
            await self.establecer_usuario_online(False)

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
        """Procesa actualizaciones de heartbeat y cambios manuales de estado."""
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'heartbeat':
            await self.actualizar_heartbeat()
            # Limpiar fantasmas en cada heartbeat y notificar al grupo
            fantasmas_ids = await self.limpiar_fantasmas()
            for f_id in fantasmas_ids:
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        'type': 'status_change',
                        'user_id': f_id,
                        'status': 'DESCONECTADO',
                        'last_seen': timezone.now().isoformat()
                    }
                )
        elif message_type == 'change_status':
            new_status = data.get('status')
            if new_status in ['ACTIVO', 'OCUPADO']:
                estado_actual = await self.actualizar_estado(new_status)
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        'type': 'status_change',
                        'user_id': self.user.id,
                        'status': estado_actual
                    }
                )

    async def status_change(self, event):
        """Notifica el cambio de estado de un usuario al grupo."""
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def actualizar_estado(self, new_status):
        """Actualiza el estado de disponibilidad del usuario."""
        try:
            perfil = Perfil.objects.get(usuario=self.user)
            perfil.estado = new_status
            perfil.save()
            return perfil.estado
        except Exception:
            return 'DESCONECTADO'

    @database_sync_to_async
    def actualizar_heartbeat(self):
        """Actualiza la fecha de última conexión activa."""
        try:
            Perfil.objects.filter(usuario=self.user).update(last_seen=timezone.now(), esta_online=True)
        except Exception:
            pass

    @database_sync_to_async
    def establecer_usuario_online(self, is_online):
        """Actualiza los flags de conexión online/offline en la base de datos."""
        try:
            perfil = Perfil.objects.get(usuario=self.user)
            perfil.esta_online = is_online
            perfil.last_seen = timezone.now()
            
            if is_online:
                if perfil.estado != 'OCUPADO':
                    perfil.estado = 'ACTIVO'
            else:
                perfil.estado = 'DESCONECTADO'
                perfil.last_seen = timezone.now()
            
            perfil.save()
            return perfil.estado
        except Exception:
            return 'DESCONECTADO'

    @database_sync_to_async
    def limpiar_fantasmas(self):
        """Busca usuarios inactivos por más de 2 min, los desconecta y retorna sus IDs."""
        try:
            umbral = timezone.now() - timezone.timedelta(minutes=2)
            fantasmas = Perfil.objects.filter(esta_online=True, last_seen__lt=umbral)
            fantasmas_ids = list(fantasmas.values_list('usuario_id', flat=True))
            if fantasmas_ids:
                fantasmas.update(esta_online=False, estado='DESCONECTADO')
            return fantasmas_ids
        except Exception:
            return []

    @database_sync_to_async
    def get_online_user_ids(self):
        """Retorna los IDs de usuarios online, limpiando usuarios fantasmas."""
        try:
            umbral = timezone.now() - timezone.timedelta(minutes=2)
            Perfil.objects.filter(esta_online=True, last_seen__lt=umbral).update(esta_online=False, estado='DESCONECTADO')
        except Exception:
            pass
        return list(Perfil.objects.filter(esta_online=True).values_list('usuario_id', flat=True))


class NotificacionesChatConsumer(AsyncWebsocketConsumer):
    """Canal WebSocket personal para recibir notificaciones de mensajes pendientes."""

    async def connect(self):
        """Une al usuario a su grupo de notificaciones personal."""
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
        """Abandona el grupo de notificaciones personal."""
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        """Ignora mensajes recibidos del cliente."""
        pass

    async def new_message_notification(self, event):
        """Reenvía la notificación de nuevo mensaje al cliente."""
        await self.send(text_data=json.dumps(event))
