from rest_framework import serializers
from .models import Voto, Catalogo_mejoras, Mejoras_usuario

class VotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Voto
        fields = ['id', 'votante', 'receptor_usuario', 'receptor_comunidad', 'estrellas', 'fecha_voto']
        read_only_fields = ['id', 'votante', 'fecha_voto']

class RankingSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    nombre = serializers.CharField()
    rating_medio = serializers.FloatField()
    url_foto = serializers.CharField(required=False) # Para usuarios o comunidades

class EstadoVotoSerializer(serializers.Serializer):
    ha_votado_hoy = serializers.BooleanField()
    puntuacion_actual = serializers.IntegerField(allow_null=True)
    total_votos = serializers.IntegerField()
    segundos_hasta_medianoche = serializers.IntegerField()

class CatalogoMejorasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Catalogo_mejoras
        fields = '__all__'

class MejorasUsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mejoras_usuario
        fields = '__all__'
