from rest_framework import serializers
from .models import Usuario, Perfil, Seguimiento

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = '__all__'
        extra_kwargs = {
            'contrasena': {'write_only': True}
        }

class PerfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Perfil
        fields = '__all__'

class SeguimientoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Seguimiento
        fields = '__all__'
