from django.db import models
from communities.models import Comunidad
from users.models import Usuario
class Salas_chat(models.Model):
    id=models.AutoField(primary_key=True)
    nombre=models.CharField(max_length=100)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    es_grupal=models.BooleanField(default=False)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self
    
class Participantes_chat(models.Model):
    id=models.AutoField(primary_key=True)
    sala=models.ForeignKey(Salas_chat,on_delete=models.CASCADE)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    fecha_union=models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self # TODO
class Mensajes_chat(models.Model):
    id=models.AutoField(primary_key=True)
    sala=models.ForeignKey(Salas_chat, on_delete=models.CASCADE, related_name='mensajes')
    emisor=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    contenido=models.TextField(null=True, blank=True)
    url_archivo_s3=models.CharField(max_length=500,null=True,blank=True)
    fecha_envio=models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self # TODO