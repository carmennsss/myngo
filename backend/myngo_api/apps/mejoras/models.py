"""Modelos del dominio de mejoras: votos, catálogo de items, peticiones
de usuarios y registro de mejoras adquiridas.
"""

from django.db import models
from django.core.validators import MaxValueValidator, MinValueValidator

from comunidades.models import Comunidad
from usuarios.models import Usuario


class Voto(models.Model):
    """
    Registra la valoración otorgada por un usuario a otro perfil o comunidad.
    Controla la integridad del sistema permitiendo una calificación diaria por receptor.
    """

    class Meta:
        db_table = 'votos'

    votante = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='votos_emitidos',
    )
    receptor_usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='votos_recibidos_perfil',
    )
    receptor_comunidad = models.ForeignKey(
        Comunidad,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='votos_recibidos_comunidad',
    )
    estrellas = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(5)],
        help_text="Las estrellas no pueden ser más de 5.",
    )
    fecha_voto = models.DateTimeField(auto_now_add=True)


class CatalogoMejoras(models.Model):
    """
    Define los artículos disponibles para su adquisición mediante puntos. Incluye 
    mejoras visuales globales y elementos específicos de comunidades.
    """

    class Meta:
        db_table = 'catalogo_mejoras'

    tipo = models.CharField(max_length=50)
    precio_puntos = models.IntegerField()
    url_recurso = models.ImageField(
        upload_to='tienda/', max_length=500, null=True, blank=True
    )
    comunidad = models.ForeignKey(
        Comunidad,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='items_tienda',
    )
    creador = models.ForeignKey(
        Usuario,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='mejoras_creadas',
    )
    esta_activo = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    datos_extra = models.JSONField(null=True, blank=True)


class PeticionMejora(models.Model):
    """
    Gestiona las propuestas de creación de nuevos artículos para la tienda. 
    Permite un flujo de aprobación por parte de los administradores de la comunidad.
    """

    ESTADOS = [
        ('PENDIENTE', 'Pendiente'),
        ('APROBADO', 'Aprobado'),
        ('RECHAZADO', 'Rechazado'),
    ]

    class Meta:
        db_table = 'peticiones_mejora'

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='peticiones_enviadas',
    )
    comunidad = models.ForeignKey(
        Comunidad,
        on_delete=models.CASCADE,
        related_name='peticiones_recibidas',
    )
    tipo = models.CharField(max_length=50)
    url_recurso = models.ImageField(upload_to='peticiones_tienda/', max_length=500)
    estado = models.CharField(max_length=20, default='PENDIENTE', choices=ESTADOS)
    precio_sugerido = models.IntegerField(default=0)
    fecha_creacion = models.DateTimeField(auto_now_add=True)


class MejoraUsuario(models.Model):
    """
    Representa la propiedad de un artículo del catálogo por parte de un usuario, 
    gestionando su estado de equipamiento en el perfil.
    """

    class Meta:
        db_table = 'mejoras_usuario'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    mejora = models.ForeignKey(CatalogoMejoras, on_delete=models.CASCADE)
    esta_equipada = models.BooleanField(default=False)
    fecha_adquisicion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.usuario.nombre_usuario} - {self.mejora.tipo} {self.mejora.id}"