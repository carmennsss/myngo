from django.db import models
from users.models import Usuario
class Comunidad(models.Model):
    id=models.AutoField(primary_key=True)
    nombre=models.CharField(max_length=100,unique=True)
    descripcion=models.TextField(blank=True, null=True)
    creador=models.ForeignKey(Usuario, on_delete=models.SET_NULL, null=True)
    url_portada=models.CharField(max_length=500,blank=True, null=True)
    es_publica=models.BooleanField(default=True)
    es_verificada=models.BooleanField(default=False)
    rating_actual=models.DecimalField(max_digits=3,decimal_places=2,null=True,blank=True,default=0.00)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
    
class Miembros_comunidades(models.Model):
    id=models.AutoField(primary_key=True)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    rol=models.CharField(max_length=20,default="Miembro")
    estado_peticion=models.CharField(max_length=20,default="ACEPTADO")
    fecha_union=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO