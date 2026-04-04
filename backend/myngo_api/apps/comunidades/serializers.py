from rest_framework import serializers
from .models import Comunidad, Miembros_comunidades

class ComunidadSerializer(serializers.ModelSerializer):
    rating_medio = serializers.ReadOnlyField()
    creador_nombre = serializers.ReadOnlyField(source='creador.nombre_usuario')
    es_miembro = serializers.SerializerMethodField()
    es_pendiente = serializers.SerializerMethodField()
    conteo_pendiente_admin = serializers.SerializerMethodField()

    class Meta:
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'es_publica', 'es_verificada', 'rating_medio', 
            'min_rating_acceso', 'fecha_creacion', 'es_miembro', 'es_pendiente',
            'conteo_pendiente_admin'
        ]
        extra_kwargs = {
            'creador': {'read_only': True}
        }

    def get_es_miembro(self, obj):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            # El creador siempre es miembro
            if obj.creador == request.user:
                return True
            # Es miembro si existe en la tabla
            return Miembros_comunidades.objects.filter(
                usuario=request.user, 
                comunidad=obj
            ).exists()
        return False

    def get_es_pendiente(self, obj):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            from usuarios.models import Seguimiento
            return Seguimiento.objects.filter(
                seguidor=request.user, 
                seguida_comunidad=obj,
                estado='SOLICITUD'
            ).exists()
        return False

    def get_conteo_pendiente_admin(self, obj):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated and obj.creador == request.user:
            from usuarios.models import Seguimiento
            from contenido.models import Reporte
            solicitudes = Seguimiento.objects.filter(seguida_comunidad=obj, estado='SOLICITUD').count()
            reportes = Reporte.objects.filter(comunidad=obj, estado='PENDIENTE').count()
            return solicitudes + reportes
        return 0

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
