from django.db import models
from django.core.validators import MaxValueValidator, MinValueValidator
from users.models import Usuario
from communities.models import Comunidad
class Voto(models.Model):
    id = models.AutoField(primary_key=True)
    votante= models.ForeignKey(Usuario,on_delete=models.CASCADE)
    receptor_usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE,null=True, blank=True)
    receptor_comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True, blank=True)
    estrellas=models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0),       # No permite puntos negativos
            MaxValueValidator(5)     # Máximo permitido: 5,000
        ],
        help_text="Las estrellas no pueden ser más de 5"
    )
    fecha_voto=models.DateTimeField(auto_now_add=True)
class Catalogo_mejoras(models.Model):
    id = models.AutoField(primary_key=True)
    nombre=models.CharField(max_length=100)
    tipo=models.CharField(max_length=50)
    precio_puntos=models.IntegerField()
    url_recurso=models.URLField(max_length=500)
class Mejoras_usuario(models.Model):
    id = models.AutoField(primary_key=True)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    mejora=models.ForeignKey(Catalogo_mejoras,on_delete=models.CASCADE)
    esta_equipada=models.BooleanField(default=False)
    fecha_adquisicion=models.DateTimeField(auto_now_add=True)
def __str__(self):
    return self # TODO