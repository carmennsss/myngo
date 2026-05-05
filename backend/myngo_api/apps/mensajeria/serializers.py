"""Serializadores para el dominio de mensajería.

Transforma los modelos SalaChat y MensajeChat en formatos JSON,
incluyendo detalles de miembros y estados de lectura.
"""

from rest_framework import serializers

from usuarios.serializers import UsuarioSerializer
from .models import MensajeChat, SalaChat, ParticipanteChat, PersonalizacionChat, ApodoPersonalizado


class PersonalizacionChatSerializer(serializers.ModelSerializer):
    """Serializador para la configuración visual de la sala."""
    class Meta:
        model = PersonalizacionChat
        fields = [
            'color_fondo', 'color_burbuja_mio', 'color_burbuja_otro',
            'color_texto_mio', 'color_texto_otro', 'color_nombre_mio',
            'color_nombre_otro', 'gradiente_fondo', 'patron_fondo',
            'imagen_fondo_s3', 'forma_burbuja', 'estilo_burbuja',
            'font_size', 'tema'
        ]


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
            'fecha_edicion', 'borrado_para_todos', 'borrado_para_mi',
            'tipo'
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


class ParticipanteChatSerializer(serializers.ModelSerializer):
    """Serializador para participantes de una sala, con apodos globales y personalizados."""
    usuario_detalle = UsuarioSerializer(source='usuario', read_only=True)
    apodo_personalizado = serializers.SerializerMethodField()

    class Meta:
        model = ParticipanteChat
        fields = [
            'id', 'sala', 'usuario', 'usuario_detalle', 
            'fecha_union', 'apodo', 'apodo_personalizado'
        ]

    def get_apodo_personalizado(self, obj):
        """Obtiene el apodo privado que el usuario actual le ha dado a este participante."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            try:
                # Buscamos si el usuario que hace la petición le ha dado un apodo a este usuario
                return ApodoPersonalizado.objects.get(
                    sala=obj.sala,
                    asignador=request.user,
                    asignado=obj.usuario
                ).apodo
            except ApodoPersonalizado.DoesNotExist:
                return None
        return None


class SalaChatSerializer(serializers.ModelSerializer):
    """Serializador para salas de chat, incluyendo personalización y datos dinámicos."""

    miembros_detalle = UsuarioSerializer(source='miembros', many=True, read_only=True)
    ultimo_mensaje = serializers.SerializerMethodField()
    mensajes_no_leidos = serializers.SerializerMethodField()
    participantes_data = serializers.SerializerMethodField()
    otro_usuario_id = serializers.SerializerMethodField()
    personalizacion = PersonalizacionChatSerializer(source='personalizacion_v2', read_only=True)

    class Meta:
        model = SalaChat
        fields = [
            'id', 'nombre', 'es_grupal', 'es_publica', 'invite_token',
            'miembros', 'miembros_detalle', 'ultimo_mensaje',
            'mensajes_no_leidos', 'fecha_creacion', 'avatar_s3', 
            'configuracion', 'participantes_data', 'personalizacion',
            'otro_usuario_id'
        ]

    def get_otro_usuario_id(self, obj):
        """Para DMs, obtiene el ID del interlocutor."""
        if obj.es_grupal: return None
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            otro = obj.miembros.exclude(id=request.user.id).first()
            return otro.id if otro else None
        return None

    def get_participantes_data(self, obj):
        """Obtiene los participantes con sus apodos (usando el contexto para los personalizados)."""
        participantes = ParticipanteChat.objects.filter(sala=obj)
        return ParticipanteChatSerializer(participantes, many=True, context=self.context).data

    def get_ultimo_mensaje(self, obj):
        """Obtiene el último mensaje enviado en la sala."""
        ultimo = obj.mensajes.all().order_by('-fecha_envio').first()
        if ultimo:
            return MensajeChatSerializer(ultimo, context=self.context).data
        return None

    def get_mensajes_no_leidos(self, obj):
        """Obtiene el conteo de mensajes no leídos para el usuario actual."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.mensajes.exclude(leido_por=request.user).exclude(emisor=request.user).count()
        return 0
