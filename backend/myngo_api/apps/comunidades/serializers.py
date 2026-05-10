"""Serializadores del dominio de comunidades."""

from rest_framework import serializers

from usuarios.models import Seguimiento

from .models import Comunidad, MiembrosComunidad, TagComunidad


class TagComunidadSerializer(serializers.ModelSerializer):
    """Serializador de etiquetas temáticas."""

    class Meta:
        model = TagComunidad
        fields = ['id', 'nombre', 'slug']


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
    tags_detalle = TagComunidadSerializer(source='tags', many=True, read_only=True)

    class Meta:
        """Configuración del modelo y campos expuestos."""
        model = Comunidad
        fields = [
            'id', 'nombre', 'descripcion', 'creador', 'creador_nombre',
            'url_portada', 'url_avatar', 'url_fondo', 'url_marco', 'fondo_posts_config',
            'fuente_comunidad', 'es_publica', 'es_verificada', 'rating_medio',
            'min_rating_acceso', 'color_tema', 'fecha_creacion', 'es_miembro',
            'es_pendiente', 'conteo_pendiente_admin', 'mi_rol', 'miembros_count',
            'tienda_habilitada', 'tags', 'tags_detalle',
        ]
        extra_kwargs = {'creador': {'read_only': True}}
        
    def to_internal_value(self, data):
        """Maneja la conversión de campos multipart y evita errores de validación en tags.
        
        Si los datos vienen de un formulario (QueryDict), extraemos y limpiamos
        los campos que requieren procesamiento especial.
        """
        import json
        
        # Trabajamos sobre una copia mutable para no alterar el original de la request
        if hasattr(data, 'copy'):
            data = data.copy()
        else:
            data = dict(data)
            
        if 'fondo_posts_config' in data:
            val = data.get('fondo_posts_config')
            
            if isinstance(val, list) and len(val) > 0:
                val = val[0]
                
            if isinstance(val, str):
                val_stripped = val.strip()
                if val_stripped and val_stripped not in ['null', 'undefined', '']:
                    try:
                        data['fondo_posts_config'] = json.loads(val_stripped)
                    except:
                        pass 
        
        for bool_field in ['es_publica', 'es_verificada', 'tienda_habilitada']:
            if bool_field in data:
                val = data.get(bool_field)
                if isinstance(val, str):
                    val_low = val.lower()
                    data[bool_field] = (val_low == 'true' or val_low == '1' or val_low == 'yes')

        if 'tags' in data:
            tags_val = data.get('tags')
            if isinstance(tags_val, str) or (isinstance(tags_val, list) and len(tags_val) > 0 and isinstance(tags_val[0], str)):
                if hasattr(data, 'pop'):
                    data.pop('tags')
                else:
                    del data['tags']

        if 'fondo_posts_config' in data and isinstance(data['fondo_posts_config'], str):
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
        """Asegura que los campos calculados y las URLs se devuelvan correctamente."""
        return super().to_representation(instance)

    def _set_tags(self, instance, tags_data):
        """Asocia o crea etiquetas por nombre."""
        if tags_data is not None:
            tags = []
            for tag_name in tags_data:
                tag, _ = TagComunidad.objects.get_or_create(nombre=tag_name.strip())
                tags.append(tag)
            instance.tags.set(tags)

    def create(self, validated_data):
        """Crea la comunidad y gestiona los tags."""
        request_data = self.context['request'].data
        tags_data = None
        
        if 'tags' in request_data:
            if hasattr(request_data, 'getlist'):
                tags_data = request_data.getlist('tags')
            else:
                tags_data = request_data.get('tags')
                
        instance = super().create(validated_data)
        self._set_tags(instance, tags_data)
        return instance

    def update(self, instance, validated_data):
        """Actualiza la comunidad y sus tags."""
        request_data = self.context['request'].data
        tags_data = None
        
        if 'tags' in request_data:
            if hasattr(request_data, 'getlist'):
                tags_data = request_data.getlist('tags')
            else:
                tags_data = request_data.get('tags')

        instance = super().update(instance, validated_data)
        if tags_data is not None:
            self._set_tags(instance, tags_data)
        return instance


class MiembroComunidadSerializer(serializers.ModelSerializer):
    """Serializador de la relación usuario-comunidad con detalles del perfil."""
    
    usuario_nombre = serializers.ReadOnlyField(source='usuario.nombre_usuario')
    usuario_avatar = serializers.SerializerMethodField()
    perfil_id = serializers.ReadOnlyField(source='usuario.perfil.id')

    class Meta:
        """Configuración del modelo y campos expuestos."""
        model = MiembrosComunidad
        fields = ['id', 'usuario', 'usuario_id', 'usuario_nombre', 'usuario_avatar', 'perfil_id', 'rol', 'fecha_union']

    def get_usuario_avatar(self, obj):
        """Retorna la URL completa del avatar del usuario."""
        if obj.usuario.url_avatar:
            from django.core.files.storage import default_storage
            url = obj.usuario.url_avatar
            if url.startswith('http'):
                return url
            return default_storage.url(url.lstrip('/'))
        return ''
