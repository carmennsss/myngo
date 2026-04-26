from django.db import models
from comunidades.models import Comunidad
from usuarios.models import Usuario
class Salas_chat(models.Model):
    class Meta:
        db_table = 'salas_chat'
    nombre=models.CharField(max_length=100)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE, null=True, blank=True) # Opcional si es global
    es_grupal=models.BooleanField(default=False)
    es_publica=models.BooleanField(default=False)
    invite_token=models.CharField(max_length=100, unique=True, null=True, blank=True)
    miembros=models.ManyToManyField(Usuario, related_name='salas_pertenecientes', blank=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.nombre
    
class Participantes_chat(models.Model):
    class Meta:
        db_table = 'participantes_chat'
    sala=models.ForeignKey(Salas_chat,on_delete=models.CASCADE)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    fecha_union=models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"{self.usuario.nombre_usuario} en {self.sala.nombre}"
class Mensajes_chat(models.Model):
    class Meta:
        db_table = 'mensajes_chat'
    sala=models.ForeignKey(Salas_chat, on_delete=models.CASCADE, related_name='mensajes')
    emisor=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    contenido=models.TextField(null=True, blank=True)
    url_archivo_s3=models.CharField(max_length=500,null=True,blank=True)
    fecha_envio=models.DateTimeField(auto_now_add=True)
    leido=models.BooleanField(default=False)
    def __str__(self):
        return f"Mensaje #{self.id} en {self.sala.nombre}"