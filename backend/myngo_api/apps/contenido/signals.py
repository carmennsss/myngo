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

        # 2. Integración automática en Galería
        if instance.url_archivo_s3 and instance.comunidad:
            Imagenes_galeria.objects.create(
                propietario=instance.autor,
                comunidad=instance.comunidad,
                url_s3=instance.url_archivo_s3.name,
                relacion_aspecto=instance.relacion_aspecto,
                es_publica=True
            )

@receiver(post_save, sender=Comentario)
def procesar_comentario(sender, instance, created, **kwargs):
    if created and instance.contenido:
        es_seguro = validar_contenido_toxico(instance.contenido)
        if not es_seguro:
            instance.es_valido_ia = False
            instance.save(update_fields=['es_valido_ia'])
