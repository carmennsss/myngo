from django.db import models
from usuarios.models import Usuario
from comunidades.models import Comunidad
class Notificacion(models.Model):
    class Meta:
        db_table = 'notificaciones'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE,related_name='notificaciones_recibidas')
    tipo=models.CharField(max_length=50)
    mensaje=models.TextField()
    leida=models.BooleanField(default=False)
    referencia_usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE,related_name='notificaciones_generadas')
    referencia_comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    fecha_notoficacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
