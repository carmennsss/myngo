from rest_framework import serializers
from .models import Publicacion, Imagenes_galeria, Coleccion, Imagenes_en_colecciones, Me_gustas, Comentario

class PublicacionSerializer(serializers.ModelSerializer):
    autor_nombre = serializers.ReadOnlyField(source='autor.nombre_usuario')

    class Meta:
        model = Publicacion
        fields = [
            'id', 'autor', 'autor_nombre', 'comunidad', 'titulo', 
            'contenido_texto', 'url_archivo_s3', 'relacion_aspecto', 
            'fecha_creacion'
        ]

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
