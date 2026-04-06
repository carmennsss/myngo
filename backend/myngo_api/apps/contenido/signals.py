from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Publicacion, Me_gustas, Comentario
from notificaciones.models import Notificacion

@receiver(post_save, sender=Publicacion)
def sincronizar_imagen_galeria(sender, instance, created, **kwargs):
    """
    Asegura que la imagen de una publicación esté sincronizada con la 
    comunidad y visibilidad de la publicación.
    """
    if instance.imagen:
        imagen = instance.imagen
        modificado = False

        # Sincronizar comunidad
        if imagen.comunidad != instance.comunidad:
            imagen.comunidad = instance.comunidad
            modificado = True
        
        # Sincronizar visibilidad (si la comunidad es privada, la imagen también)
        if instance.comunidad and not instance.comunidad.es_publica:
            if imagen.es_publica:
                imagen.es_publica = False
                modificado = True
        
        if modificado:
            imagen.save()

@receiver(post_save, sender=Me_gustas)
def notificar_like(sender, instance, created, **kwargs):
    """
    Notifica al autor de la publicación cuando alguien le da me gusta.
    """
    if created and instance.usuario != instance.publicacion.autor:
        Notificacion.objects.create(
            usuario=instance.publicacion.autor,
            tipo='LIKE',
            mensaje=f"¡Miau! A {instance.usuario.nombre_usuario} le ha gustado tu post: '{instance.publicacion.titulo or 'Publicación'}' 🐾",
            referencia_usuario=instance.usuario,
            referencia_id=instance.publicacion.id
        )

@receiver(post_save, sender=Comentario)
def notificar_comentario(sender, instance, created, **kwargs):
    """
    Notifica al autor de la publicación cuando alguien comenta.
    """
    if created and instance.autor != instance.publicacion.autor:
        Notificacion.objects.create(
            usuario=instance.publicacion.autor,
            tipo='COMENTARIO',
            mensaje=f"¡Psss! {instance.autor.nombre_usuario} ha comentado tu post: '{instance.publicacion.titulo or 'Publicación'}' ✨",
            referencia_usuario=instance.autor,
            referencia_id=instance.publicacion.id
        )
