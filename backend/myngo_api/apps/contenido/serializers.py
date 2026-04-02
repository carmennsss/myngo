from rest_framework import serializers
from .models import Publicacion, Imagenes_galeria, Coleccion, Imagenes_en_colecciones, Me_gustas, Comentario

class PublicacionSerializer(serializers.ModelSerializer):
    autor_nombre = serializers.ReadOnlyField(source='autor.nombre_usuario')
    comunidad_nombre = serializers.ReadOnlyField(source='comunidad.nombre')
    url_imagen = serializers.SerializerMethodField()
    etiquetas = serializers.ReadOnlyField(source='imagen.etiquetas')

    class Meta:
        model = Publicacion
        fields = [
            'id', 'autor', 'autor_nombre', 'comunidad', 'comunidad_nombre',
            'titulo', 'contenido_texto', 'imagen', 'url_imagen', 'relacion_aspecto',
            'etiquetas', 'fecha_creacion'
        ]

    def get_url_imagen(self, obj):
        if obj.imagen and obj.imagen.url_s3:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url_s3.url)
            return obj.imagen.url_s3.url
        return None

class ImagenGaleriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Imagenes_galeria
        fields = '__all__'

class ColeccionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coleccion
        fields = '__all__'

class ImagenesEnColeccionesSerializer(serializers.ModelSerializer):
    class Meta:
        model = Imagenes_en_colecciones
        fields = '__all__'

class MeGustasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Me_gustas
        fields = '__all__'

class ComentarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Comentario
        fields = '__all__'
