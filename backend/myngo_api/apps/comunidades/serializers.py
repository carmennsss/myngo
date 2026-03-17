from rest_framework import serializers
from .models import Comunidad, Miembros_comunidades

class ComunidadSerializer(serializers.ModelSerializer):
    rating_medio = serializers.ReadOnlyField()
    creador_nombre = serializers.ReadOnlyField(source='creador.nombre_usuario')

    class Meta:
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'es_publica', 'es_verificada', 'rating_medio', 'fecha_creacion'
        ]
        extra_kwargs = {
            'creador': {'read_only': True}
        }

    def to_representation(self, instance):
        """
        Override to ensure url_portada returns the full absolute URL from S3.
        The ImageField.url property returns the full URL from the configured storage backend.
        """
        data = super().to_representation(instance)
        if instance.url_portada:
            try:
                data['url_portada'] = instance.url_portada.url
            except Exception:
                data['url_portada'] = ''
        else:
            data['url_portada'] = ''
        return data


class MiembroComunidadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Miembros_comunidades
        fields = '__all__'
