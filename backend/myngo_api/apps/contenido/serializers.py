from rest_framework import serializers
from .models import Publicacion, Imagenes_galeria, Coleccion, Imagenes_en_colecciones, Me_gustas, Comentario

class PublicacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Publicacion
        fields = '__all__'

class ImagenesGaleriaSerializer(serializers.ModelSerializer):
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
