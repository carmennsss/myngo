from django.db.models.signals import post_save
from django.dispatch import receiver
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from .models import Notificacion
import json

@receiver(post_save, sender=Notificacion)
def enviar_notificacion_realtime(sender, instance, created, **kwargs):
    """Envía la notificación vía WebSocket en cuanto se crea en la BD."""
    if created:
        channel_layer = get_channel_layer()
        group_name = f'user_{instance.usuario.id}_notif'
        
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'generic_notification',
                'id': instance.id,
                'tipo': instance.tipo,
                'mensaje': instance.mensaje,
                'referencia_id': instance.referencia_id,
                'id_comunidad': instance.referencia_comunidad.id if instance.referencia_comunidad else None,
                'nombre_comunidad': instance.referencia_comunidad.nombre if instance.referencia_comunidad else None,
                'fecha': instance.fecha_notificacion.isoformat()
            }
        )
