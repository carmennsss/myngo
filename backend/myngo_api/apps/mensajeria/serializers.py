"""Serializadores para el dominio de mensajería.

Transforma los modelos SalaChat y MensajeChat en formatos JSON,
incluyendo detalles de miembros y estados de lectura.
"""

from rest_framework import serializers

from usuarios.serializers import UsuarioSerializer
from .models import MensajeChat, SalaChat


class MensajeChatSerializer(serializers.ModelSerializer):
    """Serializador para mensajes individuales del chat."""

    emisor_nombre = serializers.ReadOnlyField(source='emisor.nombre_usuario')
    emisor_foto = serializers.SerializerMethodField()
    content = serializers.ReadOnlyField(source='contenido')
    leido_por_ids = serializers.PrimaryKeyRelatedField(source='leido_por', many=True, read_only=True)
    referencia_a_detalle = serializers.SerializerMethodField()
    borrado_para_mi = serializers.SerializerMethodField()

    class Meta:
        model = MensajeChat
        fields = [
            'id', 'sala', 'emisor', 'emisor_nombre', 'emisor_foto',
            'content', 'url_archivo_s3', 'fecha_envio', 'leido_por_ids',
            'referencia_a', 'referencia_a_detalle', 'es_editado', 
            'fecha_edicion', 'borrado_para_todos', 'borrado_para_mi'
        ]

    def get_referencia_a_detalle(self, obj):
        if obj.referencia_a:
            return {
                'id': obj.referencia_a.id,
                'emisor_nombre': obj.referencia_a.emisor.nombre_usuario,
                'contenido': obj.referencia_a.contenido if not obj.referencia_a.borrado_para_todos else 'Mensaje borrado'
            }
        return None

    def get_borrado_para_mi(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.borrado_para.filter(id=request.user.id).exists()
        return False

    def get_emisor_foto(self, obj):
        """Obtiene la URL de la foto del emisor del mensaje."""
        if hasattr(obj.emisor, 'perfil') and obj.emisor.perfil.avatar:
            from django.core.files.storage import default_storage
            return default_storage.url(obj.emisor.perfil.avatar.lstrip('/'))
        return None


class SalaChatSerializer(serializers.ModelSerializer):
    """Serializador para salas de chat, incluyendo el último mensaje y no leídos."""

    miembros_detalle = UsuarioSerializer(source='miembros', many=True, read_only=True)
    ultimo_mensaje = serializers.SerializerMethodField()
    mensajes_no_leidos = serializers.SerializerMethodField()

    class Meta:
        model = SalaChat
        fields = [
            'id', 'nombre', 'es_grupal', 'es_publica', 'invite_token',
            'miembros', 'miembros_detalle', 'ultimo_mensaje',
            'mensajes_no_leidos', 'fecha_creacion'
        ]

    def get_ultimo_mensaje(self, obj):
        """Obtiene el último mensaje enviado en la sala."""
        if hasattr(obj, '_prefetched_objects_cache') and 'mensajes' in obj._prefetched_objects_cache:
            msgs = list(obj.mensajes.all())
            if msgs:
                return MensajeChatSerializer(msgs[0]).data

        ultimo = obj.mensajes.all().order_by('-fecha_envio').first()
        if ultimo:
            return MensajeChatSerializer(ultimo).data
        return None

    def get_mensajes_no_leidos(self, obj):
        """Obtiene el conteo de mensajes no leídos para el usuario actual."""
        if hasattr(obj, 'count_no_leidos'):
            return obj.count_no_leidos or 0

        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.mensajes.exclude(leido_por=request.user).exclude(emisor=request.user).count()
        return 0
