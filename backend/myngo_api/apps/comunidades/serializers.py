"""Serializadores del dominio de comunidades."""

from rest_framework import serializers

from usuarios.models import Seguimiento

from .models import Comunidad, MiembrosComunidad


class ComunidadSerializer(serializers.ModelSerializer):
    """Serializador completo de una comunidad con campos calculados por contexto.

    Incluye metadatos sobre la relación del usuario actual con la comunidad,
    como su rol, si es miembro o si tiene solicitudes pendientes.
    """

    rating_medio = serializers.ReadOnlyField()
    creador_nombre = serializers.ReadOnlyField(source='creador.nombre_usuario')
    es_miembro = serializers.SerializerMethodField()
    es_pendiente = serializers.SerializerMethodField()
    conteo_pendiente_admin = serializers.SerializerMethodField()
    mi_rol = serializers.SerializerMethodField()
    miembros_count = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos expuestos."""
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'url_avatar', 'url_fondo', 'fondo_posts_config',
            'fuente_comunidad', 'es_publica', 'es_verificada', 'rating_medio',
            'min_rating_acceso', 'color_tema', 'fecha_creacion', 'es_miembro',
            'es_pendiente', 'conteo_pendiente_admin', 'mi_rol', 'miembros_count',
            'tienda_habilitada',
        ]
        extra_kwargs = {'creador': {'read_only': True}}
        
    def to_internal_value(self, data):
        """Maneja la conversión de campos JSON enviados como string en multipart.
        
        Si fondo_posts_config llega como string (típico en subidas de archivos),
        se intenta parsear a diccionario para que el modelo lo valide correctamente.
        """
        if 'fondo_posts_config' in data and isinstance(data['fondo_posts_config'], str):
            import json
            try:
                data = data.copy()
                data['fondo_posts_config'] = json.loads(data['fondo_posts_config'])
            except (ValueError, TypeError):
                pass
        return super().to_internal_value(data)

    def get_es_miembro(self, obj):
        """Indica si el usuario de la petición es miembro de esta comunidad.

        Args:
            obj: Instancia de Comunidad.

        Returns:
            bool: True si el usuario es miembro o el creador.
        """
        if hasattr(obj, 'anotado_es_miembro'):
            return obj.anotado_es_miembro
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            if obj.creador == request.user:
                return True
            return MiembrosComunidad.objects.filter(
                usuario=request.user, comunidad=obj
            ).exists()
        return False

    def get_es_pendiente(self, obj):
        """Indica si el usuario tiene una solicitud de unión pendiente.

        Args:
            obj: Instancia de Comunidad.

        Returns:
            bool: True si hay una solicitud en estado 'SOLICITUD'.
        """
        if hasattr(obj, 'anotado_es_pendiente'):
            return obj.anotado_es_pendiente
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            return Seguimiento.objects.filter(
                seguidor=request.user,
                seguida_comunidad=obj,
                estado='SOLICITUD',
            ).exists()
        return False

    def get_mi_rol(self, obj):
        """Retorna el rol del usuario en la comunidad, o None si no es miembro.

        Args:
            obj: Instancia de Comunidad.

        Returns:
            str: Rol ('Administrador', 'Moderador', 'Miembro') o None.
        """
        if hasattr(obj, 'anotado_mi_rol'):
            return obj.anotado_mi_rol
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            if obj.creador == request.user:
                return 'Administrador'
            miembro = MiembrosComunidad.objects.filter(
                usuario=request.user, comunidad=obj
            ).first()
            if miembro:
                return miembro.rol
        return None

    def get_conteo_pendiente_admin(self, obj):
        """Suma solicitudes de unión y reportes pendientes para administradores.

        Args:
            obj: Instancia de Comunidad.

        Returns:
            int: Total de acciones pendientes de gestión.
        """
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            es_gestor = obj.creador == request.user or MiembrosComunidad.objects.filter(
                usuario=request.user,
                comunidad=obj,
                rol__in=['Administrador', 'Moderador'],
            ).exists()
            if es_gestor:
                from contenido.models import Reporte
                solicitudes = Seguimiento.objects.filter(
                    seguida_comunidad=obj, estado='SOLICITUD'
                ).count()
                reportes = Reporte.objects.filter(
                    comunidad=obj, estado='PENDIENTE'
                ).count()
                return solicitudes + reportes
        return 0

    def get_miembros_count(self, obj):
        """Retorna el número de miembros de la comunidad, incluyendo el creador.

        Args:
            obj: Instancia de Comunidad.

        Returns:
            int: Cantidad total de miembros.
        """
        if hasattr(obj, 'anotado_miembros_count'):
            return obj.anotado_miembros_count
        count = MiembrosComunidad.objects.filter(comunidad=obj).count()
        if obj.creador and not MiembrosComunidad.objects.filter(
            comunidad=obj, usuario=obj.creador
        ).exists():
            count += 1
        return count

    def to_representation(self, instance):
        """Convierte las URLs de imágenes S3 a rutas absolutas.

        Args:
            instance: Instancia de Comunidad.

        Returns:
            dict: Representación serializada con URLs de imagen válidas.
        """
        data = super().to_representation(instance)
        for campo in ['url_portada', 'url_avatar', 'url_fondo']:
            img_field = getattr(instance, campo, None)
            if img_field:
                try:
                    data[campo] = img_field.url
                except Exception:
                    data[campo] = ''
            else:
                data[campo] = ''
        return data


class MiembroComunidadSerializer(serializers.ModelSerializer):
    """Serializador básico de la relación usuario-comunidad con su rol."""

    class Meta:
        """Configuración del modelo y campos (todos)."""
        model = MiembrosComunidad
        fields = '__all__'
