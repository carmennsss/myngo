from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Publicacion, Comentario, Imagenes_galeria
from .ia_service import validar_contenido_toxico

@receiver(post_save, sender=Publicacion)
def procesar_publicacion(sender, instance, created, **kwargs):
    if created:
        # 1. Moderación IA (Texto)
        if instance.contenido_texto:
            es_seguro = validar_contenido_toxico(instance.contenido_texto)
            if not es_seguro:
                instance.es_valido_ia = False
                instance.save(update_fields=['es_valido_ia'])

        # 2. La imagen ya está vinculada via FK (instance.imagen)
        # No es necesario crear un registro adicional en Imagenes_galeria
        # porque el propio create de la publicacion recibe el ID de la imagen ya creada.

@receiver(post_save, sender=Comentario)
def procesar_comentario(sender, instance, created, **kwargs):
    if created and instance.contenido:
        es_seguro = validar_contenido_toxico(instance.contenido)
        if not es_seguro:
            instance.es_valido_ia = False
            instance.save(update_fields=['es_valido_ia'])
