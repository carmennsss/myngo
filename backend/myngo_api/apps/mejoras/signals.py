"""Señales del dominio de mejoras.

Maneja las notificaciones de votos y la actualización automática del rating
de usuarios y comunidades tras recibir nuevas puntuaciones.
"""

from django.db.models import Avg
from django.db.models.signals import post_save
from django.dispatch import receiver

from notificaciones.models import Notificacion
from .models import Voto


@receiver(post_save, sender=Voto)
def notificar_voto(sender, instance, created, **kwargs):
    """Notifica al receptor (usuario o creador de comunidad) cuando recibe un voto.

    Args:
        sender: Clase que emite la señal (Voto).
        instance: Instancia del voto guardado.
        created: True si es un voto nuevo.
    """
    if not created:
        return

    if instance.receptor_usuario:
        Notificacion.objects.create(
            usuario=instance.receptor_usuario,
            tipo='VOTO',
            mensaje=(
                f"¡Miau! {instance.votante.nombre_usuario} te ha puntuado con "
                f"{instance.estrellas} estrellas. ✨"
            ),
            referencia_usuario=instance.votante,
            referencia_id=instance.id,
        )
    elif instance.receptor_comunidad and instance.receptor_comunidad.creador:
        Notificacion.objects.create(
            usuario=instance.receptor_comunidad.creador,
            tipo='VOTO',
            mensaje=(
                f"¡Psss! Tu comunidad '{instance.receptor_comunidad.nombre}' "
                f"ha recibido {instance.estrellas} estrellas de {instance.votante.nombre_usuario}. 🐾"
            ),
            referencia_usuario=instance.votante,
            referencia_comunidad=instance.receptor_comunidad,
            referencia_id=instance.id,
        )


@receiver(post_save, sender=Voto)
def actualizar_rating(sender, instance, created, **kwargs):
    """Actualiza el rating_actual del receptor tras recibir un voto.

    El rating solo se calcula y actualiza si el receptor tiene al menos 10 votos.

    Args:
        sender: Clase Voto.
        instance: Instancia del voto.
        created: True si es un voto nuevo.
    """
    if instance.receptor_usuario:
        receptor = instance.receptor_usuario
        votos = Voto.objects.filter(receptor_usuario=receptor)
    elif instance.receptor_comunidad:
        receptor = instance.receptor_comunidad
        votos = Voto.objects.filter(receptor_comunidad=receptor)
    else:
        return

    # El rating solo se muestra/actualiza si hay 10 o más votos
    if votos.count() >= 10:
        media = votos.aggregate(Avg('estrellas'))['estrellas__avg']
        receptor.rating_actual = round(float(media), 2)
        receptor.save()