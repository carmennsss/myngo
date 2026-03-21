from rest_framework import serializers
from .models import Salas_chat, Participantes_chat, Mensajes_chat

class SalaChatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Salas_chat
        fields = '__all__'

class MensajeChatSerializer(serializers.ModelSerializer):
    emisor_nombre = serializers.ReadOnlyField(source='emisor.nombre_usuario')

    class Meta:
        model = Mensajes_chat
        fields = ['id', 'sala', 'emisor', 'emisor_nombre', 'contenido', 'url_archivo_s3', 'fecha_envio']
