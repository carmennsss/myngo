from django.db import models
from django.core.validators import MaxValueValidator, MinValueValidator
class Usuario(models.Model):
    id = models.AutoField(primary_key=True)
    nombre_usuario=models.CharField(max_length=150)
    email=models.EmailField(max_length=255,unique=True)
    contrasena=models.CharField(max_length=255)
    es_verificado=models.BooleanField(default=False,null=True, blank=True)
    rating_actual=models.DecimalField(max_digits=3,decimal_places=2,default=0.00, 
        null=True, 
        blank=True)
    fecha_registro=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.id} - {self.nombre_usuario}"

class Perfil(models.Model):
    id=models.AutoField(primary_key=True)
    usuario=models.OneToOneField(Usuario, on_delete=models.CASCADE, related_name='perfil')
    biografia=models.TextField(blank=True, null=True)
    url_avatar=models.URLField(max_length=500, blank=True, null=True)
    puntos = models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0),       # No permite puntos negativos
            MaxValueValidator(5000)     # Máximo permitido: 5,000
        ],
        help_text="Los puntos no pueden exceder los 5,000."
    )
    fecha_actualizacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
class Seguimiento(models.Model):
    id=models.AutoField(primary_key=True)
    seguidor=models.ForeignKey(Usuario,on_delete=models.CASCADE,related_name='siguiendo')
    seguido_usuario=models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='seguidores', null=True, blank=True)
    seguida_comunidad = models.ForeignKey('communities.Comunidad', on_delete=models.CASCADE, related_name='seguidores', null=True, blank=True)
    estado=models.CharField(default="Aceptado")
    fecha_seguimiento=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
