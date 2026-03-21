from rest_framework import serializers
from .models import Comunidad, Miembros_comunidades

class ComunidadSerializer(serializers.ModelSerializer):
    rating_medio = serializers.ReadOnlyField()
    creador_nombre = serializers.ReadOnlyField(source='creador.nombre_usuario')
    es_miembro = serializers.SerializerMethodField()

    class Meta:
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'es_publica', 'es_verificada', 'rating_medio', 
            'fecha_creacion', 'es_miembro'
        ]
        extra_kwargs = {
            'creador': {'read_only': True}
        }

    def get_es_miembro(self, obj):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            # Es miembro si existe en la tabla y está aceptado
            return Miembros_comunidades.objects.filter(
                usuario=request.user, 
                comunidad=obj, 
                estado_peticion="ACEPTADO"
            ).exists()
        return False

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
