from django.contrib.auth.signals import user_logged_in
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Perfil, Seguimiento
from notificaciones.models import Notificacion

@receiver(user_logged_in)
def actualizar_puntos_al_loguear(sender, request, user, **kwargs):
    # Accedemos al perfil usando la relación inversa
    if hasattr(user, 'perfil'):
        user.perfil.recalcular_puntos()

@receiver(post_save, sender=Seguimiento)
def notificar_seguimiento(sender, instance, created, **kwargs):
    """
    Notifica al usuario o al creador de la comunidad cuando alguien los sigue o pide unirse.
    """
    if created:
        if instance.seguido_usuario:
            tipo = 'PETICION_SEGUIMIENTO' if instance.estado == 'SOLICITUD' else 'SEGUIMIENTO'
            mensaje = f"¡Miau! {instance.seguidor.nombre_usuario} quiere seguirte. 🐾" if instance.estado == 'SOLICITUD' else f"¡Psss! {instance.seguidor.nombre_usuario} ha empezado a seguirte. ✨"
            
            Notificacion.objects.create(
                usuario=instance.seguido_usuario,
                tipo=tipo,
                mensaje=mensaje,
                referencia_usuario=instance.seguidor,
                referencia_id=instance.id
            )
        elif instance.seguida_comunidad and instance.seguida_comunidad.creador:
            if instance.estado == 'SOLICITUD':
                Notificacion.objects.create(
                    usuario=instance.seguida_comunidad.creador,
                    tipo='PETICION_UNION',
                    mensaje=f"¡Miau! {instance.seguidor.nombre_usuario} quiere unirse a '{instance.seguida_comunidad.nombre}'. 🐾",
                    referencia_usuario=instance.seguidor,
                    referencia_comunidad=instance.seguida_comunidad,
                    referencia_id=instance.id
                )
            elif instance.estado == 'ACEPTADO':
                # Si es un seguimiento directo a comunidad pública (opcional notificar al creador)
                pass