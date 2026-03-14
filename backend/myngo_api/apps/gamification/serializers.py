from rest_framework import serializers
from .models import Voto, Catalogo_mejoras, Mejoras_usuario

class VotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Voto
        fields = '__all__'

class CatalogoMejorasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Catalogo_mejoras
        fields = '__all__'

class MejorasUsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mejoras_usuario
        fields = '__all__'
