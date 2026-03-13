from django.db import models
from users.models import Usuario
from communities.models import Comunidad
class Notificacion(models.Model):
    id=models.AutoField(primary_key=True)
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    tipo=models.CharField(max_length=50)
    mensaje=models.TextField()
    leida=models.BooleanField(default=False)
    referencia_usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    referencia_comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    fecha_notoficacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
