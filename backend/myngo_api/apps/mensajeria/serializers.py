from rest_framework import serializers
from .models import Salas_chat, Mensajes_chat, Participantes_chat
from usuarios.serializers import UsuarioSerializer

class MensajeChatSerializer(serializers.ModelSerializer):
    emisor_nombre = serializers.ReadOnlyField(source='emisor.nombre_usuario')
    emisor_foto = serializers.SerializerMethodField()

    content = serializers.ReadOnlyField(source='contenido')
    leido = serializers.BooleanField(source='es_leido', read_only=True)

    class Meta:
        model = Mensajes_chat
        fields = ['id', 'sala', 'emisor', 'emisor_nombre', 'emisor_foto', 'content', 'fecha_envio', 'leido']

    def get_emisor_foto(self, obj):
        if hasattr(obj.emisor, 'perfil') and obj.emisor.perfil.avatar:
            from django.core.files.storage import default_storage
            return default_storage.url(obj.emisor.perfil.avatar.lstrip('/'))
        return None

class SalaChatSerializer(serializers.ModelSerializer):
    miembros_detalle = UsuarioSerializer(source='miembros', many=True, read_only=True)
    ultimo_mensaje = serializers.SerializerMethodField()
    mensajes_no_leidos = serializers.SerializerMethodField()

    class Meta:
        model = Salas_chat
        fields = [
            'id', 'nombre', 'es_grupal', 'es_publica', 'invite_token',
            'miembros', 'miembros_detalle', 'ultimo_mensaje',
            'mensajes_no_leidos', 'fecha_creacion'
        ]

    def get_ultimo_mensaje(self, obj):
        # Si hemos prefetcheado los mensajes, podemos obtenerlo sin query
        # O si tenemos la fecha anotada, podríamos simplemente devolver eso, 
        # pero para el objeto completo necesitamos el mensaje.
        
        # Optimizamos intentando usar mensajes prefetcheados si existen
        if hasattr(obj, '_prefetched_objects_cache') and 'mensajes' in obj._prefetched_objects_cache:
            msgs = list(obj.mensajes.all())
            if msgs:
                # Asumimos que vienen ordenados por fecha desc (como en el prefetch)
                return MensajeChatSerializer(msgs[0]).data
        
        # Fallback (solo si no se optimizó en la vista)
        ultimo = obj.mensajes.all().order_by('-fecha_envio').first()
        if ultimo:
            return MensajeChatSerializer(ultimo).data
        return None

    def get_mensajes_no_leidos(self, obj):
        # Si el queryset tiene la anotación count_no_leidos, la usamos directamente
        if hasattr(obj, 'count_no_leidos'):
            return obj.count_no_leidos or 0
            
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.mensajes.filter(es_leido=False).exclude(emisor=request.user).count()
        return 0
