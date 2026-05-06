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

        is_member = await self.is_member(self.user, self.room_id)
        if not is_member:
            await self.close()
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

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
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type', 'message')

        if message_type == 'message':
            content = data.get('content')
            url_archivo_s3 = data.get('url_archivo_s3')
            tipo = data.get('tipo', 'TEXTO')
            attachments_data = data.get('attachments', [])
            if content is not None or url_archivo_s3 is not None or attachments_data:
                msg = await self.save_message(
                    self.user, self.room_id, content, 
                    url_archivo_s3=url_archivo_s3, 
                    tipo=tipo,
                    referencia_id=data.get('referencia_a'),
                    attachments_data=attachments_data
                )

                preview_text = '📷 Foto' if tipo == 'IMAGEN' else (content[:60] + ('...' if len(content or '') > 60 else '') if content else 'Mensaje')

                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': msg.id,
                        'client_id': data.get('client_id'),
                        'content': content,
                        'url_archivo_s3': msg.url_archivo_s3.url if msg.url_archivo_s3 else None,
                        'tipo': tipo,
                        'user_id': self.user.id,
                        'username': self.user.nombre_usuario,
                        'timestamp': msg.fecha_envio.isoformat(),
                        'leido_por_ids': [],
                        'referencia_a': data.get('referencia_a'),
                        'referencia_a_detalle': await self.get_msg_detail(data.get('referencia_a')),
                        'media': await self.get_media_detail(msg),
                    }
                )

                miembros_ids = await self.get_miembros_ids(self.room_id, exclude_user_id=self.user.id)
                sala_nombre = await self.get_sala_nombre(self.room_id)
                sender_avatar = await self.get_user_avatar(self.user.id)

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
                            'preview': preview_text,
                        }
                    )

        elif message_type == 'read_messages':
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
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_typing',
                    'user_id': self.user.id,
                    'username': self.user.nombre_usuario,
                    'is_typing': data.get('is_typing', True)
                }
            )

    # ── Handlers ──────────────────────────────────────────────────────

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event))

    async def user_joined(self, event):
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def user_left(self, event):
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def member_added(self, event):
        await self.send(text_data=json.dumps(event))

    async def messages_read(self, event):
        await self.send(text_data=json.dumps(event))

    async def user_typing(self, event):
        if event.get('user_id') != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def message_edited(self, event):
        await self.send(text_data=json.dumps(event))

    async def message_deleted(self, event):
        await self.send(text_data=json.dumps(event))

    async def room_updated(self, event):
        await self.send(text_data=json.dumps(event))

    async def participant_updated(self, event):
        await self.send(text_data=json.dumps(event))

    async def nickname_updated(self, event):
        """Notifica cambio de apodo personalizado."""
        await self.send(text_data=json.dumps(event))

    # ── DB Methods ────────────────────────────────────────────────────

    @database_sync_to_async
    def is_member(self, user, room_id):
        return SalaChat.objects.filter(id=room_id, miembros=user).exists()

    @database_sync_to_async
    def is_community_room(self, room_id):
        try:
            return SalaChat.objects.get(id=room_id).comunidad is not None
        except:
            return False

    @database_sync_to_async
    def save_message(self, user, room_id, content=None, url_archivo_s3=None, tipo='TEXTO', referencia_id=None, attachments_data=None):
        room = SalaChat.objects.get(id=room_id)
        msg = MensajeChat.objects.create(
            sala=room, emisor=user, contenido=content, 
            url_archivo_s3=url_archivo_s3,
            tipo=tipo,
            referencia_a_id=referencia_id
        )
        
        if attachments_data:
            from contenido.models import ImagenGaleria
            for att in attachments_data:
                try:
                    att_id = att.get('id')
                    if att_id:
                        img = ImagenGaleria.objects.get(id=att_id)
                        msg.imagenes.add(img)
                        if not msg.imagen_principal:
                            msg.imagen_principal = img
                except ImagenGaleria.DoesNotExist:
                    pass
            msg.save()
            
        return msg

    @database_sync_to_async
    def get_media_detail(self, msg):
        media = []
        for img in msg.imagenes.all():
            media.append({
                'id': img.id,
                'url': img.url_s3.url if img.url_s3 else '',
                'tipo': img.tipo_archivo
            })
        return media

    @database_sync_to_async
    def marcar_mensajes_como_leidos(self):
        mensajes = MensajeChat.objects.filter(
            sala_id=self.room_id,
        ).exclude(leido_por=self.user).exclude(emisor_id=self.user.id)
        ids = list(mensajes.values_list('id', flat=True))
        if ids:
            for msg in mensajes:
                from .models import LecturaMensaje
                LecturaMensaje.objects.get_or_create(mensaje=msg, usuario=self.user)
        return ids

    @database_sync_to_async
    def get_msg_detail(self, msg_id):
        if not msg_id: return None
        try:
            m = MensajeChat.objects.get(id=msg_id)
            return {
                'id': m.id, 'emisor_nombre': m.emisor.nombre_usuario,
                'contenido': m.contenido if not m.borrado_para_todos else 'Mensaje borrado'
            }
        except: return None

    @database_sync_to_async
    def get_miembros_ids(self, room_id, exclude_user_id=None):
        qs = SalaChat.objects.get(id=room_id).miembros.all()
        if exclude_user_id: qs = qs.exclude(id=exclude_user_id)
        return list(qs.values_list('id', flat=True))

    @database_sync_to_async
    def get_sala_nombre(self, room_id):
        return SalaChat.objects.get(id=room_id).nombre

    @database_sync_to_async
    def get_user_avatar(self, user_id):
        try:
            perfil = Perfil.objects.get(usuario_id=user_id)
            return perfil.avatar.url if perfil.avatar else None
        except: return None


from django.core.cache import cache

class PresenceConsumer(AsyncWebsocketConsumer):
    """Consumidor global para gestionar el estado de presencia (online/offline)."""

    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return

        self.group_name = 'online_users'
        self.counter_key = f'presence_cnt_{self.user.id}'
        
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        # Incrementar contador de conexiones activas de forma segura
        count = await self.incrementar_contador_presencia()

        # Solo si es la primera conexión, marcamos como online oficialmente
        if count == 1:
            estado_actual = await self.establecer_usuario_online(True)
            await self.channel_layer.group_send(
                self.group_name,
                {'type': 'status_change', 'user_id': self.user.id, 'status': estado_actual}
            )
        else:
            # Si ya estaba conectado, simplemente obtenemos el estado actual
            estado_actual = await self.get_user_status()

        online_ids = await self.get_online_user_ids()
        
        await self.send(text_data=json.dumps({
            'type': 'presence_connection_established',
            'user_id': self.user.id,
            'status': estado_actual,
            'online_users': online_ids,
        }))

    async def disconnect(self, close_code):
        if not self.user.is_anonymous:
            # Decrementar contador de forma segura
            count = await self.decrementar_contador_presencia()

            # Solo si no quedan conexiones activas, marcamos como offline
            if count == 0:
                await self.establecer_usuario_online(False)
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        'type': 'status_change', 'user_id': self.user.id,
                        'status': 'DESCONECTADO', 'last_seen': timezone.now().isoformat()
                    }
                )
            
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        if message_type == 'heartbeat':
            await self.actualizar_heartbeat()
            # Opcional: limpiar fantasmas cada cierto tiempo o en cada heartbeat
            fantasmas_ids = await self.limpiar_fantasmas()
            for f_id in fantasmas_ids:
                await self.channel_layer.group_send(
                    self.group_name,
                    {'type': 'status_change', 'user_id': f_id, 'status': 'DESCONECTADO', 'last_seen': timezone.now().isoformat()}
                )
        elif message_type == 'change_status':
            new_status = data.get('status')
            if new_status in ['ACTIVO', 'OCUPADO']:
                estado_actual = await self.actualizar_estado(new_status)
                await self.channel_layer.group_send(
                    self.group_name,
                    {'type': 'status_change', 'user_id': self.user.id, 'status': estado_actual}
                )

    async def status_change(self, event):
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def get_user_status(self):
        try: return Perfil.objects.get(usuario=self.user).estado
        except: return 'DESCONECTADO'

    @database_sync_to_async
    def actualizar_estado(self, new_status):
        try:
            perfil = Perfil.objects.get(usuario=self.user)
            perfil.estado = new_status
            perfil.save()
            return perfil.estado
        except: return 'DESCONECTADO'

    @database_sync_to_async
    def actualizar_heartbeat(self):
        try: Perfil.objects.filter(usuario=self.user).update(last_seen=timezone.now(), esta_online=True)
        except: pass

    @database_sync_to_async
    def incrementar_contador_presencia(self):
        try:
            count = cache.get(self.counter_key, 0)
            count += 1
            cache.set(self.counter_key, count, timeout=3600)
            return count
        except: return 1

    @database_sync_to_async
    def decrementar_contador_presencia(self):
        try:
            count = cache.get(self.counter_key, 1)
            count = max(0, count - 1)
            cache.set(self.counter_key, count, timeout=3600)
            return count
        except: return 0

    @database_sync_to_async
    def establecer_usuario_online(self, is_online):
        try:
            perfil = Perfil.objects.get(usuario=self.user)
            perfil.esta_online = is_online
            perfil.last_seen = timezone.now()
            if is_online:
                if perfil.estado != 'OCUPADO': perfil.estado = 'ACTIVO'
            else:
                perfil.estado = 'DESCONECTADO'
            perfil.save()
            return perfil.estado
        except: return 'DESCONECTADO'

    @database_sync_to_async
    def limpiar_fantasmas(self):
        try:
            # Los fantasmas son aquellos que NO se han desconectado limpiamente
            # (su contador de cache podría ser > 0 o 0, pero no han enviado heartbeat)
            umbral = timezone.now() - timezone.timedelta(minutes=2)
            fantasmas = Perfil.objects.filter(esta_online=True, last_seen__lt=umbral)
            fantasmas_ids = list(fantasmas.values_list('usuario_id', flat=True))
            if fantasmas_ids: 
                fantasmas.update(esta_online=False, estado='DESCONECTADO')
                # Limpiar contadores de cache de fantasmas
                for f_id in fantasmas_ids:
                    cache.delete(f'presence_cnt_{f_id}')
            return fantasmas_ids
        except: return []

    @database_sync_to_async
    def get_online_user_ids(self):
        return list(Perfil.objects.filter(esta_online=True).values_list('usuario_id', flat=True))


class NotificacionesChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return
        self.group_name = f'user_{self.user.id}_notif'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'): await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data): pass

    async def new_message_notification(self, event): await self.send(text_data=json.dumps(event))

    async def new_chat_notification(self, event): await self.send(text_data=json.dumps(event))
