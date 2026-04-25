from rest_framework import serializers
from .models import Salas_chat, Mensajes_chat, Participantes_chat
from usuarios.serializers import UsuarioSerializer

class MensajeChatSerializer(serializers.ModelSerializer):
    emisor_nombre = serializers.ReadOnlyField(source='emisor.nombre_usuario')
    emisor_foto = serializers.SerializerMethodField()

    class Meta:
        model = Mensajes_chat
        fields = ['id', 'sala', 'emisor', 'emisor_nombre', 'emisor_foto', 'contenido', 'fecha_envio']

    def get_emisor_foto(self, obj):
        if hasattr(obj.emisor, 'perfil') and obj.emisor.perfil.avatar:
            from django.core.files.storage import default_storage
            return default_storage.url(obj.emisor.perfil.avatar.lstrip('/'))
        return None

class SalaChatSerializer(serializers.ModelSerializer):
    miembros_detalle = UsuarioSerializer(source='miembros', many=True, read_only=True)
    ultimo_mensaje = serializers.SerializerMethodField()

    class Meta:
        model = Salas_chat
        fields = ['id', 'nombre', 'es_grupal', 'es_publica', 'invite_token', 'miembros', 'miembros_detalle', 'ultimo_mensaje', 'fecha_creacion']

    def get_ultimo_mensaje(self, obj):
        ultimo = obj.mensajes.order_by('-fecha_envio').first()
        if ultimo:
            return MensajeChatSerializer(ultimo).data
        return None
