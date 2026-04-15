from rest_framework import serializers
from .models import Voto, Catalogo_mejoras, Mejoras_usuario, PeticionMejora

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
    nombre_creador = serializers.ReadOnlyField(source='creador.nombre_usuario')
    class Meta:
        model = Catalogo_mejoras
        fields = ['id', 'tipo', 'precio_puntos', 'url_recurso', 'comunidad', 'creador', 'nombre_creador', 'esta_activo', 'fecha_creacion']

class PeticionMejoraSerializer(serializers.ModelSerializer):
    nombre_usuario = serializers.ReadOnlyField(source='usuario.nombre_usuario')
    nombre_comunidad = serializers.ReadOnlyField(source='comunidad.nombre')
    class Meta:
        model = PeticionMejora
        fields = ['id', 'usuario', 'nombre_usuario', 'comunidad', 'nombre_comunidad', 'tipo', 'url_recurso', 'estado', 'precio_sugerido', 'fecha_creacion']
        read_only_fields = ['id', 'usuario', 'estado', 'fecha_creacion']

class MejorasUsuarioSerializer(serializers.ModelSerializer):
    mejora_detalles = CatalogoMejorasSerializer(source='mejora', read_only=True)
    class Meta:
        model = Mejoras_usuario
        fields = ['id', 'usuario', 'mejora', 'mejora_detalles', 'esta_equipada', 'fecha_adquisicion']
