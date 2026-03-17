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
    referencia_usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE,related_name='notificaciones_generadas', null=True, blank=True)
    referencia_comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE, null=True, blank=True)
    referencia_id=models.IntegerField(null=True, blank=True)
    fecha_notificacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.tipo} para {self.usuario.nombre_usuario}"
