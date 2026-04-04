from rest_framework import serializers
from .models import Usuario, Perfil, Seguimiento

class UsuarioSerializer(serializers.ModelSerializer):
    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
            'id', 'nombre_usuario', 'email', 'es_verificado', 'rating_actual', 
            'fecha_registro', 'password', 'numero_seguidores', 'numero_seguidos', 
            'estado_seguimiento'
        ]
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def get_numero_seguidores(self, obj):
        return obj.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        return obj.siguiendo.filter(estado='ACEPTADO').count()

    def get_estado_seguimiento(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # Si el objeto es un Usuario, accedemos directamente a sus seguidores
            seguimiento = obj.seguidores.filter(seguidor=request.user).first()
            if seguimiento:
                return seguimiento.estado
        return None

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)
        return super().update(instance, validated_data)

class PerfilSerializer(serializers.ModelSerializer):
    nombre_usuario = serializers.CharField(source='usuario.nombre_usuario', read_only=True)
    email = serializers.EmailField(source='usuario.email', read_only=True)
    es_verificado = serializers.BooleanField(source='usuario.es_verificado', read_only=True)
    rating_actual = serializers.FloatField(source='usuario.rating_actual', read_only=True)
    fecha_registro = serializers.DateTimeField(source='usuario.fecha_registro', read_only=True)
    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()

    class Meta:
        model = Perfil
        fields = '__all__'

    def get_numero_seguidores(self, obj):
        return obj.usuario.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        return obj.usuario.siguiendo.filter(estado='ACEPTADO').count()

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
