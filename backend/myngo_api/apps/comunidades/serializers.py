from rest_framework import serializers
from .models import Comunidad, Miembros_comunidades

class ComunidadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Comunidad
        fields = '__all__'

class MiembrosComunidadesSerializer(serializers.ModelSerializer):
    class Meta:
        model = Miembros_comunidades
        fields = '__all__'
