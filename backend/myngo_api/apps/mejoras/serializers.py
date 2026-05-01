"""Serializadores del dominio de mejoras: votos, catálogo, peticiones y adquisiciones."""

from rest_framework import serializers

from .models import CatalogoMejoras, MejoraUsuario, PeticionMejora, Voto


class VotoSerializer(serializers.ModelSerializer):
    """Serializador básico de un voto de estrellas."""

    class Meta:
        model = Voto
        fields = ['id', 'votante', 'receptor_usuario', 'receptor_comunidad', 'estrellas', 'fecha_voto']
        read_only_fields = ['id', 'votante', 'fecha_voto']


class RankingSerializer(serializers.Serializer):
    """Serializador genérico para rankings de usuarios o comunidades."""

    id = serializers.IntegerField()
    nombre = serializers.CharField()
    rating_medio = serializers.FloatField()
    url_foto = serializers.CharField(required=False)


class EstadoVotoSerializer(serializers.Serializer):
    """Serializador del estado del voto del usuario en el día actual."""

    ha_votado_hoy = serializers.BooleanField()
    puntuacion_actual = serializers.IntegerField(allow_null=True)
    total_votos = serializers.IntegerField()
    segundos_hasta_medianoche = serializers.IntegerField()


class CatalogoMejorasSerializer(serializers.ModelSerializer):
    """Serializador de un item del catálogo de la tienda."""

    nombre_creador = serializers.ReadOnlyField(source='creador.nombre_usuario')

    class Meta:
        model = CatalogoMejoras
        fields = [
            'id', 'tipo', 'precio_puntos', 'url_recurso', 'comunidad',
            'creador', 'nombre_creador', 'esta_activo', 'fecha_creacion', 'datos_extra',
        ]


class PeticionMejoraSerializer(serializers.ModelSerializer):
    """Serializador de una propuesta de item para la tienda de una comunidad."""

    nombre_usuario = serializers.ReadOnlyField(source='usuario.nombre_usuario')
    nombre_comunidad = serializers.ReadOnlyField(source='comunidad.nombre')

    class Meta:
        model = PeticionMejora
        fields = [
            'id', 'usuario', 'nombre_usuario', 'comunidad', 'nombre_comunidad',
            'tipo', 'url_recurso', 'estado', 'precio_sugerido', 'fecha_creacion',
        ]
        read_only_fields = ['id', 'usuario', 'estado', 'fecha_creacion']


class MejorasUsuarioSerializer(serializers.ModelSerializer):
    """Serializador de una mejora adquirida por un usuario, con detalles del item."""

    mejora_detalles = CatalogoMejorasSerializer(source='mejora', read_only=True)

    class Meta:
        model = MejoraUsuario
        fields = ['id', 'usuario', 'mejora', 'mejora_detalles', 'esta_equipada', 'fecha_adquisicion']
