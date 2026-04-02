from django.db import models
from usuarios.models import Usuario
from comunidades.models import Comunidad

class Imagenes_galeria(models.Model):
    class Meta:
        db_table = 'imagenes_galeria'
    propietario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True,blank=True)
    url_s3=models.ImageField(upload_to='publicaciones/archivos', max_length=500,null=True,blank=True)
    relacion_aspecto=models.FloatField(default=1.0)
    fecha_subida=models.DateTimeField(auto_now_add=True)
    etiquetas=models.CharField(max_length=200,null=True, blank=True)

class Publicacion(models.Model):
    class Meta:
        db_table = 'publicacion'
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE,blank=True)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True, blank=True)
    titulo=models.CharField(max_length=200,null=True, blank=True)
    contenido_texto=models.TextField(null=True, blank=True)
    imagen=models.ForeignKey(Imagenes_galeria,on_delete=models.CASCADE,null=True,blank=True)
    relacion_aspecto=models.FloatField(default=1.0)
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)


class Coleccion(models.Model):
    class Meta:
        db_table = 'colecciones'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    nombre_coleccion=models.CharField(max_length=100)
    categoria=models.CharField(max_length=50,null=True, blank=True)
    es_privada=models.BooleanField(default=False)
    imagenes=models.ManyToManyField(Imagenes_galeria, related_name='en_colecciones')
    fecha_creacion=models.DateTimeField(auto_now_add=True)

class Imagenes_en_colecciones(models.Model):
    class Meta:
        db_table = 'imagenes_en_colecciones'
    coleccion=models.ForeignKey(Coleccion,on_delete=models.CASCADE)
    imagen=models.ForeignKey(Imagenes_galeria,on_delete=models.CASCADE)

class Me_gustas(models.Model):
    class Meta:
        db_table = 'me_gustas'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    fecha_like=models.DateTimeField(auto_now_add=True)
class Comentario(models.Model):
    class Meta:
        db_table = 'comentarios'
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    contenido=models.TextField()
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
    