"""Serializadores del dominio de usuarios: Usuario, Perfil y Seguimiento."""

from django.core.files.storage import default_storage
from rest_framework import serializers

from .models import Perfil, Seguimiento, Usuario


class UsuarioSerializer(serializers.ModelSerializer):
    """Serializador completo del usuario con campos calculados desde su perfil.

    Los campos de perfil (avatar, puntos, estado, etc.) se extraen mediante
    el método privado ``_get_perfil`` para evitar consultas repetidas.
    """

    perfil_id = serializers.SerializerMethodField()
    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()
    url_avatar = serializers.SerializerMethodField()
    biografia = serializers.SerializerMethodField()
    es_publico = serializers.SerializerMethodField()
    fondo = serializers.SerializerMethodField()
    marco = serializers.SerializerMethodField()
    estilo_post = serializers.SerializerMethodField()
    puntos = serializers.SerializerMethodField()
    estado = serializers.SerializerMethodField()
    fondo_perfil = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos del serializador."""
        model = Usuario
        fields = [
            'id', 'perfil_id', 'nombre_usuario', 'email', 'es_verificado',
            'rating_actual', 'fecha_registro', 'password', 'numero_seguidores',
            'numero_seguidos', 'estado_seguimiento', 'url_avatar', 'fondo',
            'marco', 'estilo_post', 'biografia', 'es_publico', 'puntos', 'estado',
            'fondo_perfil',
        ]
        extra_kwargs = {'password': {'write_only': True}}

    def _get_perfil(self, obj):
        """Retorna el perfil asociado al usuario, o None si no existe.

        Args:
            obj: Instancia del modelo Usuario.

        Returns:
            Instancia de Perfil o None.
        """
        return getattr(obj, 'perfil', None)

    def get_perfil_id(self, obj):
        """Obtiene el ID del perfil asociado.

        Args:
            obj: Instancia de Usuario.

        Returns:
            int: ID del perfil o 0 si no existe.
        """
        perfil = self._get_perfil(obj)
        return perfil.id if perfil else 0

    def get_numero_seguidores(self, obj):
        """Cuenta el número de seguidores aceptados.

        Args:
            obj: Instancia de Usuario.

        Returns:
            int: Cantidad de seguidores.
        """
        if hasattr(obj, 'anotado_seguidores'):
            return obj.anotado_seguidores
        return obj.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        """Cuenta el número de perfiles seguidos aceptados.

        Args:
            obj: Instancia de Usuario.

        Returns:
            int: Cantidad de seguidos.
        """
        if hasattr(obj, 'anotado_seguidos'):
            return obj.anotado_seguidos
        return obj.siguiendo.filter(estado='ACEPTADO').count()

    def get_estado_seguimiento(self, obj):
        """Determina el estado de seguimiento entre el usuario autenticado y el objetivo.

        Args:
            obj: Instancia de Usuario objetivo.

        Returns:
            str: Estado ('ACEPTADO', 'SOLICITUD', etc.) o None.
        """
        if hasattr(obj, 'anotado_estado_seguimiento'):
            return obj.anotado_estado_seguimiento
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            seguimiento = obj.seguidores.filter(seguidor=request.user).first()
            if seguimiento:
                return seguimiento.estado
        return None

    def get_url_avatar(self, obj):
        """Obtiene la URL pública del avatar.

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: URL absoluta o None.
        """
        perfil = self._get_perfil(obj)
        if perfil and perfil.avatar:
            if perfil.avatar.startswith('http'):
                return perfil.avatar
            return default_storage.url(perfil.avatar.lstrip('/'))
        return None

    def get_biografia(self, obj):
        """Obtiene la biografía del perfil.

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: Biografía o cadena vacía.
        """
        perfil = self._get_perfil(obj)
        return perfil.biografia if perfil else ''

    def get_es_publico(self, obj):
        """Indica si el perfil es público.

        Args:
            obj: Instancia de Usuario.

        Returns:
            bool: True si es público o no existe perfil.
        """
        perfil = self._get_perfil(obj)
        return perfil.es_publico if perfil else True

    def get_fondo(self, obj):
        """Obtiene la URL pública de la imagen de fondo.

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: URL absoluta o None.
        """
        perfil = self._get_perfil(obj)
        if perfil and perfil.fondo:
            if perfil.fondo.startswith('http'):
                return perfil.fondo
            return default_storage.url(perfil.fondo.lstrip('/'))
        return None

    def get_fondo_perfil(self, obj):
        """Obtiene la URL pública de la imagen de fondo del perfil (feed).

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: URL absoluta o None.
        """
        perfil = self._get_perfil(obj)
        if perfil and perfil.fondo_perfil:
            if perfil.fondo_perfil.startswith('http'):
                return perfil.fondo_perfil
            return default_storage.url(perfil.fondo_perfil.lstrip('/'))
        return None

    def get_marco(self, obj):
        """Obtiene la URL pública del marco de avatar.

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: URL absoluta o None.
        """
        perfil = self._get_perfil(obj)
        if perfil and perfil.marco:
            if perfil.marco.startswith('http'):
                return perfil.marco
            return default_storage.url(perfil.marco.lstrip('/'))
        return None

    def get_estilo_post(self, obj):
        """Obtiene el estilo de publicación personalizado.

        Args:
            obj: Instancia de Usuario.

        Returns:
            dict: Datos JSON del estilo o None.
        """
        perfil = self._get_perfil(obj)
        return perfil.estilo_post if perfil else None

    def get_puntos(self, obj):
        """Obtiene los puntos acumulados.

        Args:
            obj: Instancia de Usuario.

        Returns:
            int: Cantidad de puntos.
        """
        perfil = self._get_perfil(obj)
        return perfil.puntos if perfil else 0

    def get_estado(self, obj):
        """Obtiene el estado de conexión actual.

        Args:
            obj: Instancia de Usuario.

        Returns:
            str: Estado ('ACTIVO', 'OCUPADO', etc.).
        """
        perfil = self._get_perfil(obj)
        return perfil.estado if perfil else 'DESCONECTADO'

    def update(self, instance, validated_data):
        """Actualiza el usuario, hasheando la contraseña si se proporciona.

        Args:
            instance: Instancia de Usuario a actualizar.
            validated_data: Datos validados del serializador.

        Returns:
            Usuario: Instancia actualizada.
        """
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)
        return super().update(instance, validated_data)


class PerfilSerializer(serializers.ModelSerializer):
    """Serializador del perfil de usuario con datos sociales calculados."""

    numero_seguidores = serializers.SerializerMethodField()
    numero_seguidos = serializers.SerializerMethodField()
    estado_seguimiento = serializers.SerializerMethodField()
    url_avatar = serializers.SerializerMethodField()
    datos_usuario = UsuarioSerializer(source='usuario', read_only=True)

    class Meta:
        """Configuración del modelo y campos."""
        model = Perfil
        fields = [
            'biografia', 'url_avatar', 'fondo', 'fondo_perfil', 'marco', 'estilo_post',
            'numero_seguidores', 'numero_seguidos', 'datos_usuario', 'estado_seguimiento',
        ]

    def get_numero_seguidores(self, obj):
        """Cuenta seguidores aceptados.

        Args:
            obj: Instancia de Perfil.

        Returns:
            int: Cantidad de seguidores.
        """
        return obj.usuario.seguidores.filter(estado='ACEPTADO').count()

    def get_numero_seguidos(self, obj):
        """Cuenta seguidos aceptados.

        Args:
            obj: Instancia de Perfil.

        Returns:
            int: Cantidad de seguidos.
        """
        return obj.usuario.siguiendo.filter(estado='ACEPTADO').count()

    def get_url_avatar(self, obj):
        """Retorna el avatar como cadena.

        Args:
            obj: Instancia de Perfil.

        Returns:
            str: Ruta o URL del avatar.
        """
        return obj.avatar

    def get_estado_seguimiento(self, obj):
        """Determina el estado de seguimiento del usuario autenticado.

        Args:
            obj: Instancia de Perfil.

        Returns:
            str: Estado o None.
        """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            seguimiento = obj.usuario.seguidores.filter(seguidor=request.user).first()
            if seguimiento:
                return seguimiento.estado
        return None


class SeguimientoSerializer(serializers.ModelSerializer):
    """Serializador básico de la relación de seguimiento."""

    class Meta:
        """Configuración del modelo y campos (incluye todos)."""
        model = Seguimiento
        fields = '__all__'
