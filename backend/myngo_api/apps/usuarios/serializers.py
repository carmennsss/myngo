from rest_framework import serializers
from .models import Usuario, Perfil, Seguimiento

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'nombre_usuario', 'email', 'es_verificado', 'rating_actual', 'fecha_registro', 'password']
        extra_kwargs = {
            'password': {'write_only': True}
        }

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

    class Meta:
        model = Perfil
        fields = '__all__'

class SeguimientoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Seguimiento
        fields = '__all__'
