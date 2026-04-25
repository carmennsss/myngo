from rest_framework import serializers
from .models import Comunidad, Miembros_comunidades

class ComunidadSerializer(serializers.ModelSerializer):
    rating_medio = serializers.ReadOnlyField()
    creador_nombre = serializers.ReadOnlyField(source='creador.nombre_usuario')
    es_miembro = serializers.SerializerMethodField()
    es_pendiente = serializers.SerializerMethodField()
    conteo_pendiente_admin = serializers.SerializerMethodField()
    mi_rol = serializers.SerializerMethodField()
    miembros_count = serializers.SerializerMethodField()

    class Meta:
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'es_publica', 'es_verificada', 'rating_medio', 
            'min_rating_acceso', 'color_tema', 'fecha_creacion', 'es_miembro', 'es_pendiente',
            'conteo_pendiente_admin', 'mi_rol', 'miembros_count',
            'tienda_habilitada'
        ]
        extra_kwargs = {
            'creador': {'read_only': True}
        }

    def get_es_miembro(self, obj):
        if hasattr(obj, 'anotado_es_miembro'):
            return obj.anotado_es_miembro
            
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
        if hasattr(obj, 'anotado_es_pendiente'):
            return obj.anotado_es_pendiente
            
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            from usuarios.models import Seguimiento
            return Seguimiento.objects.filter(
                seguidor=request.user, 
                seguida_comunidad=obj,
                estado='SOLICITUD'
            ).exists()
        return False

        return False

    def get_mi_rol(self, obj):
        if hasattr(obj, 'anotado_mi_rol'):
            return obj.anotado_mi_rol
            
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            # Primero ver si es el creador
            if obj.creador == request.user:
                return "Administrador"
            # Luego ver si tiene rol en la tabla
            miembro = Miembros_comunidades.objects.filter(
                usuario=request.user, 
                comunidad=obj
            ).first()
            if miembro:
                return miembro.rol
        return None

    def get_conteo_pendiente_admin(self, obj):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            # Solo si es admin o moderador
            es_gestor = obj.creador == request.user or Miembros_comunidades.objects.filter(
                usuario=request.user, comunidad=obj, rol__in=['Administrador', 'Moderador']
            ).exists()
            
            if es_gestor:
                from usuarios.models import Seguimiento
                from contenido.models import Reporte
                solicitudes = Seguimiento.objects.filter(seguida_comunidad=obj, estado='SOLICITUD').count()
                reportes = Reporte.objects.filter(comunidad=obj, estado='PENDIENTE').count()
                return solicitudes + reportes
        return 0

    def get_miembros_count(self, obj):
        if hasattr(obj, 'anotado_miembros_count'):
            return obj.anotado_miembros_count
            
        # Contar miembros en la tabla + el creador si no está ya incluido
        count = Miembros_comunidades.objects.filter(comunidad=obj).count()
        # El creador puede no estar en la tabla de miembros, comprobamos
        if obj.creador and not Miembros_comunidades.objects.filter(comunidad=obj, usuario=obj.creador).exists():
            count += 1
        return count

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

