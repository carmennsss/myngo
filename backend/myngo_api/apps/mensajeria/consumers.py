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

        # Notificar a los demás que se ha unido
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_joined',
                'user_id': self.user.id,
                'username': self.user.nombre_usuario
            }
        )

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            # Notificar que se ha ido
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_left',
                    'user_id': self.user.id,
                    'username': self.user.nombre_usuario
                }
            )
            # Salir del grupo
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
                
                # Broadcast
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': msg.id,
                        'content': content,
                        'user_id': self.user.id,
                        'username': self.user.nombre_usuario,
                        'timestamp': msg.fecha_envio.isoformat()
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

    # Handlers para eventos de grupo
    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event))

    async def user_joined(self, event):
        await self.send(text_data=json.dumps(event))

    async def user_left(self, event):
        await self.send(text_data=json.dumps(event))

    async def member_added(self, event):
        await self.send(text_data=json.dumps(event))

    # Métodos de BD
    @database_sync_to_async
    def is_member(self, user, room_id):
        return Salas_chat.objects.filter(id=room_id, miembros=user).exists()

    @database_sync_to_async
    def save_message(self, user, room_id, content):
        room = Salas_chat.objects.get(id=room_id)
        return Mensajes_chat.objects.create(sala=room, emisor=user, contenido=content)

    @database_sync_to_async
    def add_member_to_room(self, user_id, room_id):
        try:
            room = Salas_chat.objects.get(id=room_id)
            user = Usuario.objects.get(id=user_id)
            room.miembros.add(user)
            return True
        except:
            return False

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

        # Marcar como online (respetando si está OCUPADO)
        estado_actual = await self.establecer_usuario_online()

        # Notificar estado real
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
            # Marcar como DESCONECTADO
            await self.update_user_status('DESCONECTADO')

            # Notificar
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
            # El heartbeat simplemente confirma que sigue ahí
            pass

    async def status_change(self, event):
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def establecer_usuario_online(self):
        perfil = self.user.perfil
        # Solo cambiamos a ACTIVO si NO está en OCUPADO
        if perfil.estado != 'OCUPADO':
            perfil.estado = 'ACTIVO'
            perfil.save()
        return perfil.estado

    @database_sync_to_async
    def update_user_status(self, nuevo_estado):
        perfil = self.user.perfil
        perfil.estado = nuevo_estado
        if nuevo_estado == 'DESCONECTADO':
            perfil.last_seen = timezone.now()
        perfil.save()
        
        
