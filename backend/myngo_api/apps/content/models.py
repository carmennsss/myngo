from django.db import models
from users.models import Usuario
from communities.models import Comunidad
class Publicacion(models.Model):
    id = models.AutoField(primary_key=True)
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE,blank=True)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True, blank=True)
    titulo=models.CharField(max_length=200,null=True,null=True, blank=True)
    contenido_texto=models.TextField(null=True, blank=True)
    url_archivo_s3=models.CharField(max_length=500)
    relacion_aspecto=models.FloatField(default=1.0)
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

class Imagenes_galeria(models.Model):
    id = models.AutoField(primary_key=True)
    propietario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    url_s3=models.CharField(max_length=500)
    relacion_aspecto=models.FloatField(default=1.0)
    es_publica=models.BooleanField(default=True)
    fecha_subida=models.DateTimeField(auto_now_add=True)

class Coleccion(models.Model):
    id = models.AutoField(primary_key=True)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    nombre_coleccion=models.CharField(max_length=100)
    categoria=models.CharField(max_length=50,null=True, blank=True)
    es_privada=models.BooleanField(default=False)
    imagenes=models.ManyToManyField(Imagenes_galeria, related_name='en_colecciones')
    fecha_creacion=models.DateTimeField(auto_now_add=True)

class Imagenes_en_colecciones(models.Model):
    id = models.AutoField(primary_key=True)
    coleccion=models.ForeignKey(Coleccion,on_delete=models.CASCADE)
    imagen=models.ForeignKey(Imagenes_galeria,on_delete=models.CASCADE)

class Me_gustas(models.Model):
    id = models.AutoField(primary_key=True)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    fecha_like=models.DateTimeField(auto_now_add=True)
class Comentario(models.Model):
    id = models.AutoField(primary_key=True)
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    contenido=models.TextField()
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
    