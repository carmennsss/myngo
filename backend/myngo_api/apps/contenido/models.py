"""Modelos del dominio de contenido: imágenes, publicaciones, colecciones,
interacciones (likes, comentarios), reportes y posts guardados.
"""

import os

from django.db import models

from comunidades.models import Comunidad
from usuarios.models import Usuario


from django.utils.text import get_valid_filename

def _definir_ruta_almacenamiento(instance, filename):
    """Determina la ruta S3 donde se almacenará un archivo de imagen.

    Si la instancia tiene el atributo temporal ``_es_avatar`` activado,
    el archivo se guarda en ``perfiles/avatar/``; en caso contrario,
    en ``publicaciones/archivos/``.
    """
    es_avatar = getattr(instance, '_es_avatar', False)
    ruta_s3 = 'perfiles/avatar' if es_avatar else 'publicaciones/archivos'
    
    # Sanitizamos el nombre del archivo para evitar problemas con espacios o caracteres especiales en S3
    nombre_limpio = get_valid_filename(filename)
    return f"{ruta_s3}/{nombre_limpio}"


class ImagenGaleria(models.Model):
    """Archivo multimedia (imagen o vídeo) subido por un usuario.

    Puede estar asociado a una comunidad o a un perfil de usuario.
    Se almacena en S3 mediante la función ``_definir_ruta_almacenamiento``.
    """

    TIPO_ARCHIVO = [
        ('I', 'Imagen'),
        ('V', 'Video'),
    ]

    class Meta:
        db_table = 'imagenes_galeria'

    propietario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, null=True, blank=True
    )
    url_s3 = models.FileField(
        upload_to=_definir_ruta_almacenamiento,
        max_length=500,
        null=True,
        blank=True,
    )
    tipo_archivo = models.CharField(
        max_length=1, choices=TIPO_ARCHIVO, default='I'
    )
    relacion_aspecto = models.FloatField(default=1.0)
    es_publica = models.BooleanField(default=True)
    fecha_subida = models.DateTimeField(auto_now_add=True)
    etiquetas = models.CharField(max_length=200, null=True, blank=True)


class Publicacion(models.Model):
    """Publicación de contenido dentro de una comunidad o perfil.

    Soporta texto, una imagen principal (campo ``imagen``, mantenido
    por compatibilidad) y hasta 4 imágenes adicionales via M2M.
    El campo ``es_valido_ia`` indica si el contenido superó el filtro
    de toxicidad aplicado en el momento de la creación.
    """

    class Meta:
        db_table = 'publicacion'

    autor = models.ForeignKey(Usuario, on_delete=models.CASCADE, blank=True)
    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, null=True, blank=True
    )
    titulo = models.CharField(max_length=200, null=True, blank=True)
    contenido_texto = models.TextField(null=True, blank=True)
    imagen = models.ForeignKey(
        ImagenGaleria,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    imagenes = models.ManyToManyField(
        ImagenGaleria,
        through='PublicacionImagen',
        through_fields=('publicacion', 'imagengaleria'),
        related_name='publicaciones_asociadas',
        blank=True,
    )
    relacion_aspecto = models.FloatField(default=1.0)
    es_valido_ia = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)


class PublicacionImagen(models.Model):
    """Modelo intermedio para asociar imágenes a posts con un orden específico."""
    
    class Meta:
        db_table = 'publicacion_imagenes'
        ordering = ['orden']
        unique_together = ('publicacion', 'imagengaleria')

    publicacion = models.ForeignKey(Publicacion, on_delete=models.CASCADE)
    imagengaleria = models.ForeignKey(ImagenGaleria, on_delete=models.CASCADE)
    orden = models.PositiveIntegerField(default=0)


class Coleccion(models.Model):
    """Agrupación de imágenes creada por un usuario, opcionalmente en una comunidad."""

    class Meta:
        db_table = 'colecciones'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, null=True, blank=True
    )
    nombre_coleccion = models.CharField(max_length=100)
    descripcion = models.TextField(null=True, blank=True)
    categoria = models.CharField(max_length=50, null=True, blank=True)
    es_privada = models.BooleanField(default=False)
    imagenes = models.ManyToManyField(ImagenGaleria, related_name='en_colecciones')
    fecha_creacion = models.DateTimeField(auto_now_add=True)


class MeGusta(models.Model):
    """Registro de un «me gusta» emitido por un usuario sobre una publicación."""

    class Meta:
        db_table = 'me_gustas'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    publicacion = models.ForeignKey(Publicacion, on_delete=models.CASCADE)
    fecha_like = models.DateTimeField(auto_now_add=True)


class Comentario(models.Model):
    """Comentario textual sobre una publicación.

    El campo ``es_valido_ia`` indica si el texto superó el filtro
    de toxicidad en el momento de la creación.
    """

    class Meta:
        db_table = 'comentarios'

    publicacion = models.ForeignKey(Publicacion, on_delete=models.CASCADE)
    autor = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    padre = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='respuestas')
    contenido = models.TextField()
    es_valido_ia = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comentario de {self.autor.nombre_usuario}"


class Reporte(models.Model):
    """Reporte de contenido inapropiado enviado por un usuario.

    Puede referirse a un post, imagen, comunidad o comentario.
    Los moderadores lo resuelven o desestinan mediante la vista correspondiente.
    """

    class Meta:
        db_table = 'reportes'

    TIPOS_OBJETO = [
        ('POST', 'Publicación'),
        ('IMAGEN', 'Imagen'),
        ('COMUNIDAD', 'Comunidad'),
        ('COMENTARIO', 'Comentario'),
    ]

    ESTADOS = [
        ('PENDIENTE', 'Pendiente'),
        ('RESUELTO', 'Resuelto'),
        ('DESESTIMADO', 'Desestimado'),
    ]

    informador = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='reportes_enviados',
    )
    tipo_objeto = models.CharField(max_length=20, choices=TIPOS_OBJETO)
    objeto_id = models.IntegerField()
    motivo = models.CharField(max_length=100)
    comentario = models.TextField(null=True, blank=True)
    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, null=True, blank=True
    )
    estado = models.CharField(max_length=20, default='PENDIENTE', choices=ESTADOS)
    fecha_reporte = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reporte {self.tipo_objeto} ({self.estado})"


class PostGuardado(models.Model):
    """Registro de una publicación guardada por un usuario en su perfil."""

    class Meta:
        db_table = 'posts_guardados'
        unique_together = ('usuario', 'publicacion')

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='posts_guardados',
    )
    publicacion = models.ForeignKey(
        Publicacion,
        on_delete=models.CASCADE,
        related_name='guardado_por',
    )
    fecha_guardado = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return (
            f"Post {self.publicacion_id} guardado por "
            f"{self.usuario.nombre_usuario}"
        )