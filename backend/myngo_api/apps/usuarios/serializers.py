from rest_framework import serializers
from django.conf import settings
from django.core.files.storage import default_storage
from .models import Usuario, Perfil, Seguimiento

class UsuarioSerializer(serializers.ModelSerializer):
    # Campos calculados y de relación
    perfil_id = serializers.SerializerMethodField()  
    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()
    url_avatar = serializers.SerializerMethodField()
    biografia = serializers.SerializerMethodField()
    es_publico = serializers.SerializerMethodField()
    fondo = serializers.SerializerMethodField()
    marco = serializers.SerializerMethodField()
    estilo_post = serializers.SerializerMethodField()
    puntos = serializers.SerializerMethodField()
    estado = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
           'id', 'perfil_id','nombre_usuario', 'email', 'es_verificado', 'rating_actual',
            'fecha_registro', 'password', 'numero_seguidores', 'numero_seguidos',
            'estado_seguimiento', 'url_avatar', 'fondo', 'marco', 'estilo_post', 'biografia', 'es_publico', 'puntos', 'estado'
        ]
        extra_kwargs = {
            'password': {'write_only': True}
        }

    # --- MÉTODOS PARA EXTRAER DATOS DEL PERFIL RELACIONADO ---
    
    def _get_perfil(self, obj):
        # Intentamos obtener el perfil asociado al usuario
        return getattr(obj, 'perfil', None)

    def get_perfil_id(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.id if perfil else 0
    
    def get_numero_seguidores(self, obj):
        if hasattr(obj, 'anotado_seguidores'):
            return obj.anotado_seguidores
        return obj.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        if hasattr(obj, 'anotado_seguidos'):
            return obj.anotado_seguidos
        return obj.siguiendo.filter(estado='ACEPTADO').count()

    def get_estado_seguimiento(self, obj):
        # Si ya viene anotado, lo usamos directamente
        if hasattr(obj, 'anotado_estado_seguimiento'):
            return obj.anotado_estado_seguimiento
            
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # Si el objeto es un Usuario, accedemos directamente a sus seguidores
            seguimiento = obj.seguidores.filter(seguidor=request.user).first()
            if seguimiento:
                return seguimiento.estado
        return None

    def get_url_avatar(self, obj):
        perfil = self._get_perfil(obj)
        if perfil and perfil.avatar:
            if perfil.avatar.startswith('http'):
                return perfil.avatar
            return default_storage.url(perfil.avatar.lstrip('/'))
        return None

    def get_biografia(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.biografia if perfil else ""
        
    def get_es_publico(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.es_publico if perfil else True

    def get_fondo(self, obj):
        perfil = self._get_perfil(obj)
        if perfil and perfil.fondo:
            if perfil.fondo.startswith('http'):
                return perfil.fondo
            return default_storage.url(perfil.fondo.lstrip('/'))
        return None

    def get_marco(self, obj):
        perfil = self._get_perfil(obj)
        if perfil and perfil.marco:
            if perfil.marco.startswith('http'):
                return perfil.marco
            return default_storage.url(perfil.marco.lstrip('/'))
        return None

    def get_estilo_post(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.estilo_post if perfil else None

    def get_puntos(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.puntos if perfil else 0

    def get_estado(self, obj):
        perfil = self._get_perfil(obj)
        return perfil.estado if perfil else 'DESCONECTADO'

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)
        return super().update(instance, validated_data)

class PerfilSerializer(serializers.ModelSerializer):
    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()
    url_avatar=serializers.SerializerMethodField()
    datos_usuario = UsuarioSerializer(source='usuario', read_only=True)
    class Meta:
        model = Perfil
        fields =['biografia', 'url_avatar', 'fondo', 'marco', 'estilo_post', 'numero_seguidores','numero_seguidos','datos_usuario','estado_seguimiento']

    def get_numero_seguidores(self, obj):
        return obj.usuario.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        return obj.usuario.siguiendo.filter(estado='ACEPTADO').count()
    def get_url_avatar(self,obj):
        return obj.avatar
    def get_estado_seguimiento(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            seguimiento = obj.usuario.seguidores.filter(seguidor=request.user).first()
            if seguimiento:
                return seguimiento.estado
        return None

class SeguimientoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Seguimiento
        fields = '__all__'
