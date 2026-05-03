"""Señales del dominio de contenido.

Maneja la sincronización de metadatos de imágenes en la galería y las
notificaciones automáticas de interacciones (likes y comentarios).
"""

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

from notificaciones.models import Notificacion
from .models import Comentario, MeGusta, Publicacion, ImagenGaleria


@receiver(post_save, sender=Publicacion)
def sincronizar_imagen_galeria(sender, instance, created, **kwargs):
    """Sincroniza la comunidad y visibilidad de la imagen asociada a la publicación.

    Si la publicación pertenece a una comunidad privada, la imagen también
    se marca automáticamente como privada en la galería.

    Args:
        sender: Clase Publicacion.
        instance: Instancia de la publicación guardada.
        created: True si es una publicación nueva.
    """
    if not instance.imagen:
        return

    imagen = instance.imagen
    modificado = False

    # Sincronizar comunidad
    if imagen.comunidad != instance.comunidad:
        imagen.comunidad = instance.comunidad
        modificado = True

    # Sincronizar visibilidad (privacidad de comunidad heredada por la imagen)
    if instance.comunidad and not instance.comunidad.es_publica:
        if imagen.es_publica:
            imagen.es_publica = False
            modificado = True

    if modificado:
        imagen.save()


@receiver(post_save, sender=MeGusta)
def notificar_like(sender, instance, created, **kwargs):
    """Notifica al autor de una publicación cuando recibe un «me gusta».

    Args:
        sender: Clase MeGusta.
        instance: Instancia de la interacción.
        created: True si es un nuevo like.
    """
    if created and instance.usuario != instance.publicacion.autor:
        titulo = instance.publicacion.titulo or 'Publicación'
        Notificacion.objects.create(
            usuario=instance.publicacion.autor,
            tipo='LIKE',
            mensaje=(
                f"¡Miau! A {instance.usuario.nombre_usuario} le ha gustado "
                f"tu post: '{titulo}' 🐾"
            ),
            referencia_usuario=instance.usuario,
            referencia_id=instance.publicacion.id,
        )


@receiver(post_save, sender=Comentario)
def notificar_comentario(sender, instance, created, **kwargs):
    """Notifica al autor de una publicación cuando recibe un comentario nuevo.

    Args:
        sender: Clase Comentario.
        instance: Instancia del comentario.
        created: True si es un comentario nuevo.
    """
    if created and instance.autor != instance.publicacion.autor:
        titulo = instance.publicacion.titulo or 'Publicación'
        Notificacion.objects.create(
            usuario=instance.publicacion.autor,
            tipo='COMENTARIO',
            mensaje=(
                f"¡Psss! {instance.autor.nombre_usuario} ha comentado "
                f"tu post: '{titulo}' ✨"
            ),
            referencia_usuario=instance.autor,
            referencia_id=instance.publicacion.id,
        )


@receiver(post_delete, sender=ImagenGaleria)
def limpiar_archivo_s3(sender, instance, **kwargs):
    """Elimina el archivo físico de S3 cuando se borra el registro de la galería.

    Asegura que no queden archivos huérfanos en el almacenamiento en la nube
    tras borrar publicaciones o limpiar la galería.
    """
    if instance.url_s3:
        try:
            instance.url_s3.delete(save=False)
        except Exception as e:
            # No bloqueamos el borrado de la BD si falla S3, pero lo logueamos
            print(f"Error al eliminar archivo de S3: {str(e)}")

