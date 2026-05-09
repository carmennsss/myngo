"""Modelos del dominio de comunidades.

Contiene la entidad Comunidad y la relación de membresía
MiembrosComunidad que asocia usuarios a comunidades con un rol.
"""

from django.db import models
from django.utils.text import slugify

from usuarios.models import Usuario


class TagComunidad(models.Model):
    """Categoría o etiqueta temática para clasificar comunidades."""

    class Meta:
        db_table = 'tags_comunidades'
        verbose_name_plural = "Tags de Comunidades"

    nombre = models.CharField(max_length=50, unique=True)
    slug = models.SlugField(max_length=60, unique=True, blank=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.nombre)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.nombre


class Comunidad(models.Model):
    """Comunidad temática de la plataforma Myngo.

    Las comunidades pueden ser públicas o privadas, disponer de tienda
    de mejoras, y ser personalizadas visualmente por sus administradores
    (avatar, portada, fondo, fuente tipográfica y colores del feed).
    """

    class Meta:
        db_table = 'comunidades'

    nombre = models.CharField(max_length=100, unique=True)
    descripcion = models.TextField(blank=True, null=True)
    creador = models.ForeignKey(Usuario, on_delete=models.SET_NULL, null=True)
    url_avatar = models.ImageField(
        upload_to='comunidades/avatares/', blank=True, null=True
    )
    url_portada = models.ImageField(upload_to='portadas/', blank=True, null=True)
    url_fondo = models.ImageField(
        upload_to='comunidades/fondos/', blank=True, null=True
    )
    url_marco = models.ImageField(
        upload_to='comunidades/marcos/', blank=True, null=True
    )
    fondo_posts_config = models.JSONField(blank=True, null=True)
    fuente_comunidad = models.CharField(max_length=50, blank=True, null=True)
    es_publica = models.BooleanField(default=True)
    es_verificada = models.BooleanField(default=False)
    rating_actual = models.DecimalField(
        max_digits=3, decimal_places=2, null=True, blank=True, default=0.00
    )
    min_rating_acceso = models.DecimalField(
        max_digits=3, decimal_places=2, default=0.00
    )
    color_tema = models.CharField(max_length=7, default='#C35E34')
    tienda_habilitada = models.BooleanField(default=False)
    tags = models.ManyToManyField(TagComunidad, related_name='comunidades', blank=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre

    @property
    def rating_medio(self):
        """Calcula la media de estrellas recibidas por esta comunidad.

        Solo se computa si la comunidad acumula al menos 10 votos.

        Returns:
            Media de estrellas redondeada a 2 decimales, o 0.0.
        """
        from mejoras.models import Voto
        votos = Voto.objects.filter(receptor_comunidad=self)
        if votos.count() < 10:
            return 0.0
        media = votos.aggregate(models.Avg('estrellas'))['estrellas__avg']
        return round(float(media), 2)


class MiembrosComunidad(models.Model):
    """Relación entre un usuario y una comunidad con un rol asignado.

    Un usuario puede ser Administrador, Moderador o Miembro.
    El creador de la comunidad no aparece aquí; se identifica
    directamente por el campo ``Comunidad.creador``.
    """

    ROLES = [
        ('Administrador', 'Administrador'),
        ('Moderador', 'Moderador'),
        ('Miembro', 'Miembro'),
    ]

    class Meta:
        db_table = 'miembros_comunidades'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    comunidad = models.ForeignKey(Comunidad, on_delete=models.CASCADE, related_name='miembros_comunidades')
    rol = models.CharField(max_length=20, choices=ROLES, default='Miembro')
    fecha_union = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.usuario.nombre_usuario} en {self.comunidad.nombre}"