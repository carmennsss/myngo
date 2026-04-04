from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Publicacion, Imagenes_galeria

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
        # Esto es una lógica adicional para reforzar la privacidad
        if instance.comunidad and not instance.comunidad.es_publica:
            if imagen.es_publica:
                imagen.es_publica = False
                modificado = True
        
        if modificado:
            imagen.save()
