from django.contrib.auth.signals import user_logged_in
from django.dispatch import receiver
from .models import Perfil

@receiver(user_logged_in)
def actualizar_puntos_al_loguear(sender, request, user, **kwargs):
    # Accedemos al perfil usando la relación inversa
    if hasattr(user, 'perfil'):
        user.perfil.recalcular_puntos()