from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Voto
from notificaciones.models import Notificacion

@receiver(post_save, sender=Voto)
def notificar_voto(sender, instance, created, **kwargs):
    """
    Notifica al usuario o al creador de la comunidad cuando reciben una puntuación.
    """
    if created:
        if instance.receptor_usuario:
            Notificacion.objects.create(
                usuario=instance.receptor_usuario,
                tipo='VOTO',
                mensaje=f"¡Miau! {instance.votante.nombre_usuario} te ha puntuado con {instance.estrellas} estrellas. ✨",
                referencia_usuario=instance.votante,
                referencia_id=instance.id
            )
        elif instance.receptor_comunidad and instance.receptor_comunidad.creador:
            Notificacion.objects.create(
                usuario=instance.receptor_comunidad.creador,
                tipo='VOTO',
                mensaje=f"¡Psss! Tu comunidad '{instance.receptor_comunidad.nombre}' ha recibido {instance.estrellas} estrellas de {instance.votante.nombre_usuario}. 🐾",
                referencia_usuario=instance.votante,
                referencia_comunidad=instance.receptor_comunidad,
                referencia_id=instance.id
            )
@receiver(post_save, sender=Voto)
def actualizar_rating(sender,instance,created, **kwargs):
    """
    Actualiza el rating del usuario o comunidad receptor después de recibir un voto.
    """
    if instance.receptor_usuario:
        receptor = instance.receptor_usuario
        votos = Voto.objects.filter(receptor_usuario=receptor)
    elif instance.receptor_comunidad:
        receptor = instance.receptor_comunidad
        votos = Voto.objects.filter(receptor_comunidad=receptor)
    else:
        return
        
    if votos.count() >= 10:
        total_estrellas = sum(voto.estrellas for voto in votos)
        receptor.rating_actual = total_estrellas / votos.count()
        receptor.save()