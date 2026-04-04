from rest_framework import serializers
from .models import Publicacion, Imagenes_galeria, Coleccion, Me_gustas, Comentario, Reporte

class PublicacionSerializer(serializers.ModelSerializer):
    autor_nombre = serializers.ReadOnlyField(source='autor.nombre_usuario')
    comunidad_nombre = serializers.ReadOnlyField(source='comunidad.nombre')
    creador_comunidad_id = serializers.ReadOnlyField(source='comunidad.creador.id')
    url_imagen = serializers.SerializerMethodField()
    etiquetas = serializers.ReadOnlyField(source='imagen.etiquetas')

    likes_count = serializers.SerializerMethodField()
    comentarios_count = serializers.SerializerMethodField()
    usuario_dio_like = serializers.SerializerMethodField()

    class Meta:
        model = Publicacion
        fields = [
            'id', 'autor', 'autor_nombre', 'comunidad', 'comunidad_nombre',
            'creador_comunidad_id', 'titulo', 'contenido_texto', 'imagen', 'url_imagen', 
            'relacion_aspecto', 'etiquetas', 'fecha_creacion',
            'likes_count', 'comentarios_count', 'usuario_dio_like'
        ]

    def get_url_imagen(self, obj):
        if obj.imagen and obj.imagen.url_s3:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url_s3.url)
            return obj.imagen.url_s3.url
        return None

    def get_likes_count(self, obj):
        return Me_gustas.objects.filter(publicacion=obj).count()

    def get_comentarios_count(self, obj):
        return Comentario.objects.filter(publicacion=obj).count()

    def get_usuario_dio_like(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Me_gustas.objects.filter(publicacion=obj, usuario=request.user).exists()
        return False

class ImagenGaleriaSerializer(serializers.ModelSerializer):
    url_archivo = serializers.SerializerMethodField()
    propietario_nombre = serializers.ReadOnlyField(source='propietario.nombre_usuario')
    creador_comunidad_id = serializers.ReadOnlyField(source='comunidad.creador.id')

    class Meta:
        model = Imagenes_galeria
        fields = [
            'id', 'propietario', 'propietario_nombre', 'comunidad', 'creador_comunidad_id',
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
    autor_foto = serializers.SerializerMethodField()

    class Meta:
        model = Comentario
        fields = ['id', 'publicacion', 'autor', 'autor_nombre', 'autor_foto', 'contenido', 'fecha_creacion']
        read_only_fields = ['autor', 'publicacion']

    def get_autor_foto(self, obj):
        if hasattr(obj.autor, 'perfil') and obj.autor.perfil.url_avatar:
            return obj.autor.perfil.url_avatar
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
