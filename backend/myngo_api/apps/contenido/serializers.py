"""Serializadores del dominio de contenido: Publicaciones, Galería y Colecciones."""

import urllib.parse
from django.conf import settings
from django.core.files.storage import default_storage
from rest_framework import serializers

from .models import (
    Coleccion,
    Comentario,
    ImagenGaleria,
    MeGusta,
    PostGuardado,
    Publicacion,
    Reporte,
)


class PublicacionSerializer(serializers.ModelSerializer):
    """Serializador detallado de publicaciones con metadatos de autor y comunidad.

    Incluye lógica para resolver URLs de imágenes en S3 y estados de interacción
    (likes, guardados) para el usuario autenticado.
    """

    autor_perfil_id = serializers.ReadOnlyField(source='autor.perfil.id')
    autor_nombre = serializers.SerializerMethodField()
    autor_foto = serializers.SerializerMethodField()
    autor_marco = serializers.SerializerMethodField()
    autor_fondo = serializers.SerializerMethodField()
    autor_estado = serializers.SerializerMethodField()
    autor_estilo_post = serializers.SerializerMethodField()
    comunidad_nombre = serializers.ReadOnlyField(source='comunidad.nombre')
    creador_comunidad_id = serializers.ReadOnlyField(source='comunidad.creador.id')
    url_imagen = serializers.SerializerMethodField()
    etiquetas = serializers.ReadOnlyField(source='imagen.etiquetas')
    imagen_id = serializers.IntegerField(source='imagen.id', read_only=True, allow_null=True)
    es_valido_ia = serializers.BooleanField(read_only=True)
    urls_imagenes = serializers.SerializerMethodField()
    imagenes_ids = serializers.SerializerMethodField()
    media = serializers.SerializerMethodField()

    likes_count = serializers.SerializerMethodField()
    comentarios_count = serializers.SerializerMethodField()
    usuario_dio_like = serializers.SerializerMethodField()
    usuario_guardo_post = serializers.SerializerMethodField()
    usuario_es_miembro = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos del serializador."""
        model = Publicacion
        fields = [
            'id', 'autor', 'autor_perfil_id', 'autor_nombre', 'autor_foto', 'autor_marco', 'autor_fondo',
            'autor_estado', 'autor_estilo_post', 'comunidad', 'comunidad_nombre',
            'creador_comunidad_id', 'titulo', 'contenido_texto', 'imagen', 'imagen_id',
            'url_imagen', 'urls_imagenes', 'imagenes_ids', 'media', 'relacion_aspecto',
            'es_valido_ia', 'etiquetas', 'fecha_creacion', 'likes_count',
            'comentarios_count', 'usuario_dio_like', 'usuario_guardo_post', 'usuario_es_miembro',
        ]

    def get_media(self, obj):
        """Lista detallada de archivos multimedia (URL y tipo).
        
        Args:
            obj: Instancia de Publicacion.
            
        Returns:
            list: Objetos con 'url' y 'tipo' ('I' o 'V').
        """
        media_list = []
        
        # Obtener imágenes ordenadas mediante el modelo intermedio
        relaciones = obj.publicacionimagen_set.all().order_by('orden')[:4]
        
        if relaciones.exists():
            for rel in relaciones:
                img = rel.imagengaleria
                if img.url_s3:
                    # Las URLs de S3 ya son absolutas, no las pasemos a build_absolute_uri()
                    url = img.url_s3.url
                    media_list.append({
                        'url': url,
                        'tipo': img.tipo_archivo
                    })
        elif obj.imagen:
            # Fallback a la imagen principal para posts antiguos
            if obj.imagen.url_s3:
                # Las URLs de S3 ya son absolutas, no las pasemos a build_absolute_uri()
                url = obj.imagen.url_s3.url
                media_list.append({
                    'url': url,
                    'tipo': obj.imagen.tipo_archivo
                })
        return media_list

    def get_usuario_es_miembro(self, obj):
        """Indica si el usuario actual es miembro de la comunidad del post.
        
        Si el post no pertenece a ninguna comunidad, se considera abierto (True).
        Si el usuario es el autor, también es True.
        """
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            return False
            
        if not obj.comunidad_id:
            return True
            
        if obj.autor_id == request.user.id:
            return True

        # Intentar usar anotación si existe para mayor eficiencia
        if hasattr(obj, 'anotado_es_miembro'):
            return obj.anotado_es_miembro
            
        from comunidades.models import MiembrosComunidad
        return MiembrosComunidad.objects.filter(
            usuario=request.user, 
            comunidad_id=obj.comunidad_id
        ).exists()

    def get_url_imagen(self, obj):
        """Obtiene la URL absoluta de la imagen principal.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: URL absoluta o None.
        """
        if obj.imagen and obj.imagen.url_s3:
            # Las URLs de S3 ya son absolutas, devolver directamente
            return obj.imagen.url_s3.url
        return None

    def get_autor_nombre(self, obj):
        """Retorna el nombre de usuario del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: Nombre de usuario o "Anónimo".
        """
        return obj.autor.nombre_usuario if obj.autor else "Anónimo"

    def get_autor_foto(self, obj):
        """Obtiene la URL del avatar del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: URL absoluta del avatar o None.
        """
        try:
            if not obj.autor:
                return None
            url = obj.autor.url_avatar
            if not url:
                return None
            if url.startswith('http'):
                return url
            return default_storage.url(url.lstrip('/'))
        except Exception:
            return None

    def get_autor_marco(self, obj):
        """Obtiene la URL del marco de perfil del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: URL del marco o None.
        """
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.marco:
                return None
            marco_path = perfil.marco
            if marco_path.startswith('http'):
                return marco_path
            return default_storage.url(marco_path.lstrip('/'))
        except Exception:
            return None

    def get_autor_fondo(self, obj):
        """Obtiene la URL del fondo de perfil del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: URL del fondo o None.
        """
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.fondo:
                return None
            fondo_path = perfil.fondo
            if fondo_path.startswith('http'):
                return fondo_path
            return default_storage.url(fondo_path.lstrip('/'))
        except Exception:
            return None

    def get_autor_estado(self, obj):
        """Obtiene el estado de conexión del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            str: Estado o 'DESCONECTADO'.
        """
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            return perfil.estado if perfil else 'DESCONECTADO'
        except Exception:
            return 'DESCONECTADO'

    def get_autor_estilo_post(self, obj):
        """Retorna el estilo personalizado para el post basado en el perfil del autor.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            dict: Configuración de estilo (colores, fondos, bordes) o None.
        """
        try:
            estilo = obj.autor.perfil.estilo_post
            if not estilo:
                return None

            url_fondo = estilo.get('url_fondo') or estilo.get('backgroundImage')
            if url_fondo:
                try:
                    if not url_fondo.startswith('http'):
                        url_fondo = default_storage.url(url_fondo.lstrip('/'))
                except Exception:
                    pass

            return {
                'fondo': estilo.get('fondo') or estilo.get('background'),
                'fondo_inicio': estilo.get('fondo_inicio'),
                'fondo_fin': estilo.get('fondo_fin'),
                'borde': estilo.get('borde') or estilo.get('border'),
                'url_fondo': url_fondo,
            }
        except Exception:
            return None

    def get_urls_imagenes(self, obj):
        """Lista las URLs de todas las imágenes asociadas a la publicación (máx 4).

        Args:
            obj: Instancia de Publicacion.

        Returns:
            list: Lista de URLs absolutas.
        """
        urls = []
        relaciones = obj.publicacionimagen_set.all().order_by('orden')[:4]
        
        for rel in relaciones:
            img = rel.imagengaleria
            if img.url_s3:
                # Las URLs de S3 ya son absolutas, no las pasemos a build_absolute_uri()
                urls.append(img.url_s3.url)
        
        if not urls and obj.imagen and obj.imagen.url_s3:
            # Las URLs de S3 ya son absolutas, no las pasemos a build_absolute_uri()
            urls.append(obj.imagen.url_s3.url)
        return urls

    def get_imagenes_ids(self, obj):
        """Lista los IDs de todas las imágenes asociadas.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            list: Lista de IDs (int).
        """
        ids = list(obj.imagenes.values_list('id', flat=True))[:4]
        if not ids and obj.imagen:
            ids.append(obj.imagen.id)
        return ids

    def get_likes_count(self, obj):
        """Cuenta el total de likes de la publicación.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            int: Cantidad de likes.
        """
        if hasattr(obj, 'anotado_likes_count'):
            return obj.anotado_likes_count
        return MeGusta.objects.filter(publicacion=obj).count()

    def get_comentarios_count(self, obj):
        """Cuenta el total de comentarios de la publicación.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            int: Cantidad de comentarios.
        """
        if hasattr(obj, 'anotado_comentarios_count'):
            return obj.anotado_comentarios_count
        return Comentario.objects.filter(publicacion=obj).count()

    def get_usuario_dio_like(self, obj):
        """Indica si el usuario actual ha dado like a esta publicación.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            bool: True si el usuario autenticado dio like.
        """
        if hasattr(obj, 'anotado_usuario_dio_like'):
            return obj.anotado_usuario_dio_like
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return MeGusta.objects.filter(publicacion=obj, usuario=request.user).exists()
        return False

    def get_usuario_guardo_post(self, obj):
        """Indica si el usuario actual ha guardado esta publicación.

        Args:
            obj: Instancia de Publicacion.

        Returns:
            bool: True si el usuario autenticado guardó el post.
        """
        if hasattr(obj, 'anotado_usuario_guardo_post'):
            return obj.anotado_usuario_guardo_post
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostGuardado.objects.filter(publicacion=obj, usuario=request.user).exists()
        return False


class ImagenGaleriaSerializer(serializers.ModelSerializer):
    """Serializador de archivos multimedia de la galería."""

    url_archivo = serializers.SerializerMethodField()
    propietario_nombre = serializers.ReadOnlyField(source='propietario.nombre_usuario')
    creador_comunidad_id = serializers.ReadOnlyField(source='comunidad.creador.id')
    comunidad_nombre = serializers.ReadOnlyField(source='comunidad.nombre')
    usuario_es_miembro = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos."""
        model = ImagenGaleria
        fields = [
            'id', 'propietario', 'propietario_nombre', 'comunidad', 'comunidad_nombre',
            'creador_comunidad_id', 'usuario_es_miembro',
            'url_s3', 'url_archivo', 'tipo_archivo',
            'relacion_aspecto', 'es_publica', 'fecha_subida', 'etiquetas'
        ]
        read_only_fields = ['propietario']

    def get_url_archivo(self, obj):
        """Obtiene la URL pública del archivo en S3.

        Args:
            obj: Instancia de ImagenGaleria.

        Returns:
            str: URL absoluta.
        """
        if obj.url_s3:
            # Las URLs de S3 ya son absolutas, devolverlas directamente
            return obj.url_s3.url
        return None

    def get_usuario_es_miembro(self, obj):
        """Verifica si el usuario actual es miembro de la comunidad de la imagen.

        Args:
            obj: Instancia de ImagenGaleria.

        Returns:
            bool: True si es miembro o no hay comunidad asociada.
        """
        if not obj.comunidad:
            return False
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from comunidades.models import MiembrosComunidad
            return MiembrosComunidad.objects.filter(
                comunidad=obj.comunidad, usuario=request.user
            ).exists()
        return False


class ColeccionSerializer(serializers.ModelSerializer):
    """Serializador de colecciones personales o de comunidad."""

    propietario_nombre = serializers.ReadOnlyField(source='usuario.nombre_usuario')
    numero_imagenes = serializers.SerializerMethodField()
    previsualizaciones = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos."""
        model = Coleccion
        fields = [
            'id', 'usuario', 'propietario_nombre', 'comunidad', 'nombre_coleccion',
            'descripcion', 'categoria', 'es_privada',
            'imagenes', 'numero_imagenes', 'previsualizaciones', 'fecha_creacion'
        ]
        read_only_fields = ['numero_imagenes', 'previsualizaciones', 'usuario']
        extra_kwargs = {
            'imagenes': {'required': False}
        }

    def get_numero_imagenes(self, obj):
        """Cuenta el total de imágenes en la colección.

        Args:
            obj: Instancia de Coleccion.

        Returns:
            int: Cantidad de imágenes.
        """
        return obj.imagenes.count() if obj.id else 0

    def get_previsualizaciones(self, obj):
        """Obtiene las URLs de las últimas 4 imágenes para previsualización.

        Args:
            obj: Instancia de Coleccion.

        Returns:
            list: Lista de URLs absolutas.
        """
        if not obj.id:
            return []
        imagenes = obj.imagenes.all().order_by('-fecha_subida')[:4]
        urls = []
        for img in imagenes:
            if img.url_s3:
                # Las URLs de S3 ya son absolutas, no las pasemos a build_absolute_uri()
                urls.append(img.url_s3.url)
        return urls


class MeGustaSerializer(serializers.ModelSerializer):
    """Serializador básico de interacciones 'Me gusta'."""

    class Meta:
        """Configuración del modelo y campos."""
        model = MeGusta
        fields = '__all__'


class ComentarioSerializer(serializers.ModelSerializer):
    """Serializador de comentarios con metadatos del autor y soporte para respuestas."""

    autor_nombre = serializers.SerializerMethodField()
    autor_foto = serializers.SerializerMethodField()
    autor_marco = serializers.SerializerMethodField()
    autor_fondo = serializers.SerializerMethodField()
    respuestas = serializers.SerializerMethodField()
    puedo_borrar = serializers.SerializerMethodField()

    class Meta:
        """Configuración del modelo y campos."""
        model = Comentario
        fields = [
            'id', 'publicacion', 'autor', 'autor_nombre', 'autor_foto',
            'autor_marco', 'autor_fondo', 'contenido', 'padre',
            'respuestas', 'puedo_borrar', 'fecha_creacion'
        ]
        read_only_fields = ['autor', 'publicacion']

    def get_respuestas(self, obj):
        """Obtiene las respuestas anidadas del comentario.
        
        Args:
            obj: Instancia de Comentario.
            
        Returns:
            list: Lista de comentarios serializados.
        """
        # Solo serializamos respuestas para comentarios de primer nivel
        # para evitar recursión infinita (aunque en Myngo solo permitimos 1 nivel extra)
        if obj.padre is None:
            respuestas = obj.respuestas.all().order_by('fecha_creacion')
            return ComentarioSerializer(respuestas, many=True, context=self.context).data
        return []

    def get_autor_nombre(self, obj):
        """Nombre de usuario del autor.

        Args:
            obj: Instancia de Comentario.

        Returns:
            str: Nombre o "Anónimo".
        """
        return obj.autor.nombre_usuario if obj.autor else "Anónimo"

    def get_autor_foto(self, obj):
        """URL del avatar del autor.

        Args:
            obj: Instancia de Comentario.

        Returns:
            str: URL absoluta o None.
        """
        try:
            if not obj.autor:
                return None
            url = obj.autor.url_avatar
            if not url:
                return None
            if url.startswith('http'):
                return url
            return default_storage.url(url.lstrip('/'))
        except Exception:
            return None

    def get_autor_marco(self, obj):
        """URL del marco de perfil del autor.

        Args:
            obj: Instancia de Comentario.

        Returns:
            str: URL del marco o None.
        """
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.marco:
                return None
            path = perfil.marco
            if path.startswith('http'):
                return path
            return default_storage.url(path.lstrip('/'))
        except Exception:
            return None

    def get_autor_fondo(self, obj):
        """URL del fondo de perfil del autor.

        Args:
            obj: Instancia de Comentario.

        Returns:
            str: URL del fondo o None.
        """
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.fondo:
                return None
            path = perfil.fondo
            if path.startswith('http'):
                return path
            return default_storage.url(path.lstrip('/'))
        except Exception:
            return None

    def get_puedo_borrar(self, obj):
        """Indica si el usuario actual tiene permiso para borrar este comentario.
        
        Permitido si es el autor del comentario, si es el autor de la publicación,
        o si es admin/moderador de la comunidad.
        """
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
            
        # Caso 1: Es el autor del comentario
        if obj.autor_id == request.user.id:
            return True

        # Caso 2: Es el autor de la publicación original
        if obj.publicacion.autor_id == request.user.id:
            return True
            
        # Caso 3: Es admin/moderador de la comunidad donde se hizo el post
        if obj.publicacion.comunidad:
            comunidad = obj.publicacion.comunidad
            if comunidad.creador_id == request.user.id:
                return True
                
            from comunidades.models import MiembrosComunidad
            return MiembrosComunidad.objects.filter(
                usuario=request.user,
                comunidad=comunidad,
                rol__in=['Administrador', 'Moderador']
            ).exists()
            
        return False


class ReporteSerializer(serializers.ModelSerializer):
    """Serializador de reportes de contenido."""

    informador_nombre = serializers.ReadOnlyField(source='informador.nombre_usuario')

    class Meta:
        """Configuración del modelo y campos."""
        model = Reporte
        fields = [
            'id', 'informador', 'informador_nombre', 'tipo_objeto',
            'objeto_id', 'motivo', 'comentario', 'comunidad',
            'estado', 'fecha_reporte'
        ]
        read_only_fields = ['informador']
