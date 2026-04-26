from rest_framework import serializers
from django.conf import settings
from django.core.files.storage import default_storage
from .models import Publicacion, Imagenes_galeria, Coleccion, Me_gustas, Comentario, Reporte, PostGuardado
import urllib.parse

class PublicacionSerializer(serializers.ModelSerializer):
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
    # Campo explícito para devolver el ID de la imagen como integer garantizado
    imagen_id = serializers.IntegerField(source='imagen.id', read_only=True, allow_null=True)
    es_valido_ia = serializers.BooleanField(read_only=True)
    urls_imagenes = serializers.SerializerMethodField()
    imagenes_ids = serializers.SerializerMethodField()

    likes_count = serializers.SerializerMethodField()
    comentarios_count = serializers.SerializerMethodField()
    usuario_dio_like = serializers.SerializerMethodField()
    usuario_guardo_post = serializers.SerializerMethodField()

    class Meta:
        model = Publicacion
        fields = [
            'id', 'autor', 'autor_nombre', 'autor_foto', 'autor_marco', 'autor_fondo', 'autor_estado', 'autor_estilo_post', 'comunidad', 'comunidad_nombre',
            'creador_comunidad_id', 'titulo', 'contenido_texto', 'imagen', 'imagen_id',
            'url_imagen', 'urls_imagenes', 'imagenes_ids', 'relacion_aspecto', 'es_valido_ia', 'etiquetas', 'fecha_creacion',
            'likes_count', 'comentarios_count', 'usuario_dio_like', 'usuario_guardo_post'
        ]

    def get_url_imagen(self, obj):
        if obj.imagen and obj.imagen.url_s3:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url_s3.url)
            return obj.imagen.url_s3.url
        return None

    def get_autor_nombre(self, obj):
        return obj.autor.nombre_usuario if obj.autor else "Anónimo"

    def get_autor_foto(self, obj):
        try:
            if not obj.autor: return None
            url = obj.autor.url_avatar
            if not url: return None
            if url.startswith('http'): return url
            return default_storage.url(url.lstrip('/'))
        except:
            return None

    def get_autor_marco(self, obj):
        try:
            # Accedemos directamente al perfil asociado al autor
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.marco:
                return None
            
            marco_path = perfil.marco
            if marco_path.startswith('http'):
                return marco_path
            return default_storage.url(marco_path.lstrip('/'))
        except:
            return None

    def get_autor_fondo(self, obj):
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.fondo:
                return None
            
            fondo_path = perfil.fondo
            if fondo_path.startswith('http'):
                return fondo_path
            return default_storage.url(fondo_path.lstrip('/'))
        except:
            return None

    def get_autor_estado(self, obj):
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            return perfil.estado if perfil else 'DESCONECTADO'
        except:
            return 'DESCONECTADO'

    def get_autor_estilo_post(self, obj):
        try:
            estilo = obj.autor.perfil.estilo_post
            if not estilo:
                return None
            
            url_fondo = estilo.get('url_fondo') or estilo.get('backgroundImage')
            if url_fondo:
                try:
                    if not url_fondo.startswith('http'):
                        url_fondo = default_storage.url(url_fondo.lstrip('/'))
                except:
                    pass

            # Normalizar para el frontend (fondo, borde, url_fondo, degradados)
            return {
                'fondo': estilo.get('fondo') or estilo.get('background'),
                'fondo_inicio': estilo.get('fondo_inicio'),
                'fondo_fin': estilo.get('fondo_fin'),
                'borde': estilo.get('borde') or estilo.get('border'),
                'url_fondo': url_fondo,
            }
        except:
            return None

    def get_urls_imagenes(self, obj):
        urls = []
        request = self.context.get('request')
        for img in obj.imagenes.all()[:4]: # Max 4 imagenes
            if img.url_s3:
                urls.append(request.build_absolute_uri(img.url_s3.url) if request else img.url_s3.url)
        if not urls and obj.imagen and obj.imagen.url_s3:
            urls.append(request.build_absolute_uri(obj.imagen.url_s3.url) if request else obj.imagen.url_s3.url)
        return urls

    def get_imagenes_ids(self, obj):
        ids = list(obj.imagenes.values_list('id', flat=True))[:4]
        if not ids and obj.imagen:
            ids.append(obj.imagen.id)
        return ids

    def get_likes_count(self, obj):
        if hasattr(obj, 'anotado_likes_count'):
            return obj.anotado_likes_count
        return Me_gustas.objects.filter(publicacion=obj).count()

    def get_comentarios_count(self, obj):
        if hasattr(obj, 'anotado_comentarios_count'):
            return obj.anotado_comentarios_count
        return Comentario.objects.filter(publicacion=obj).count()

    def get_usuario_dio_like(self, obj):
        if hasattr(obj, 'anotado_usuario_dio_like'):
            return obj.anotado_usuario_dio_like
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Me_gustas.objects.filter(publicacion=obj, usuario=request.user).exists()
        return False

    def get_usuario_guardo_post(self, obj):
        if hasattr(obj, 'anotado_usuario_guardo_post'):
            return obj.anotado_usuario_guardo_post
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostGuardado.objects.filter(publicacion=obj, usuario=request.user).exists()
        return False

class ImagenGaleriaSerializer(serializers.ModelSerializer):
    url_archivo = serializers.SerializerMethodField()
    propietario_nombre = serializers.ReadOnlyField(source='propietario.nombre_usuario')
    creador_comunidad_id = serializers.ReadOnlyField(source='comunidad.creador.id')
    comunidad_nombre = serializers.ReadOnlyField(source='comunidad.nombre')
    usuario_es_miembro = serializers.SerializerMethodField()

    class Meta:
        model = Imagenes_galeria
        fields = [
            'id', 'propietario', 'propietario_nombre', 'comunidad', 'comunidad_nombre',
            'creador_comunidad_id', 'usuario_es_miembro',
            'url_s3', 'url_archivo', 'tipo_archivo', 
            'relacion_aspecto', 'es_publica', 'fecha_subida', 'etiquetas'
        ]
        read_only_fields = ['propietario']

    def get_url_archivo(self, obj):
        if obj.url_s3:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.url_s3.url)
            return obj.url_s3.url
        return None

    def get_usuario_es_miembro(self, obj):
        if not obj.comunidad:
            return False
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from comunidades.models import Miembros_comunidades
            return Miembros_comunidades.objects.filter(
                comunidad=obj.comunidad, usuario=request.user
            ).exists()
        return False

class ColeccionSerializer(serializers.ModelSerializer):
    propietario_nombre = serializers.ReadOnlyField(source='usuario.nombre_usuario')
    numero_imagenes = serializers.SerializerMethodField()
    previsualizaciones = serializers.SerializerMethodField()

    class Meta:
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
        return obj.imagenes.count() if obj.id else 0

    def get_previsualizaciones(self, obj):
        if not obj.id:
            return []
        imagenes = obj.imagenes.all().order_by('-fecha_subida')[:4]
        request = self.context.get('request')
        urls = []
        for img in imagenes:
            if img.url_s3:
                if request:
                    urls.append(request.build_absolute_uri(img.url_s3.url))
                else:
                    urls.append(img.url_s3.url)
        return urls

# ImagenesEnColeccionesSerializer eliminado ya que el modelo fue removido

class MeGustasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Me_gustas
        fields = '__all__'

class ComentarioSerializer(serializers.ModelSerializer):
    autor_nombre = serializers.ReadOnlyField(source='autor.nombre_usuario')
    autor_nombre = serializers.SerializerMethodField()
    autor_foto = serializers.SerializerMethodField()
    autor_marco = serializers.SerializerMethodField()
    autor_fondo = serializers.SerializerMethodField()

    class Meta:
        model = Comentario
        fields = ['id', 'publicacion', 'autor', 'autor_nombre', 'autor_foto', 'autor_marco', 'autor_fondo', 'contenido', 'fecha_creacion']
        read_only_fields = ['autor', 'publicacion']

    def get_autor_nombre(self, obj):
        return obj.autor.nombre_usuario if obj.autor else "Anónimo"

    def get_autor_foto(self, obj):
        try:
            if not obj.autor: return None
            url = obj.autor.url_avatar
            if not url: return None
            if url.startswith('http'): return url
            return default_storage.url(url.lstrip('/'))
        except:
            return None

    def get_autor_marco(self, obj):
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.marco:
                return None
            path = perfil.marco
            if path.startswith('http'): return path
            return default_storage.url(path.lstrip('/'))
        except:
            return None

    def get_autor_fondo(self, obj):
        try:
            perfil = getattr(obj.autor, 'perfil', None)
            if not perfil or not perfil.fondo:
                return None
            path = perfil.fondo
            if path.startswith('http'): return path
            return default_storage.url(path.lstrip('/'))
        except:
            return None

class ReporteSerializer(serializers.ModelSerializer):
    informador_nombre = serializers.ReadOnlyField(source='informador.nombre_usuario')
    
    class Meta:
        model = Reporte
        fields = [
            'id', 'informador', 'informador_nombre', 'tipo_objeto', 
            'objeto_id', 'motivo', 'comentario', 'comunidad', 
            'estado', 'fecha_reporte'
        ]
        read_only_fields = ['informador']
