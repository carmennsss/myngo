from django.db import models
from usuarios.models import Usuario
class Comunidad(models.Model):
    class Meta:
        db_table = 'comunidades'
    nombre=models.CharField(max_length=100,unique=True)
    descripcion=models.TextField(blank=True, null=True)
    creador=models.ForeignKey(Usuario, on_delete=models.SET_NULL, null=True)
    url_portada=models.ImageField(upload_to='portadas/', blank=True, null=True)
    es_publica=models.BooleanField(default=True)
    es_verificada=models.BooleanField(default=False)
    rating_actual=models.DecimalField(max_digits=3,decimal_places=2,null=True,blank=True,default=0.00)
    min_rating_acceso=models.DecimalField(max_digits=3,decimal_places=2,default=0.00)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre

    @property
    def rating_medio(self):
        """
        Calcula la media de estrellas recibidas por esta comunidad.
        """
        from mejoras.models import Voto
        votos = Voto.objects.filter(receptor_comunidad=self)
        if votos.count() < 10:
            return 0.0
        
        media = votos.aggregate(models.Avg('estrellas'))['estrellas__avg']
        return round(float(media), 2)
    
class Miembros_comunidades(models.Model):
    class Meta:
        db_table = 'miembros_comunidades'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE)
    rol=models.CharField(max_length=20,default="Miembro")
    fecha_union=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.usuario.nombre_usuario} en {self.comunidad.nombre}"