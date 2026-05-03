from django.db.models.signals import post_save
from django.dispatch import receiver
from comunidades.models import MiembrosComunidad, Comunidad
from .models import SalaChat

@receiver(post_save, sender=MiembrosComunidad)
def agregar_miembro_a_chat_comunidad(sender, instance, created, **kwargs):
    """
    Cuando un usuario se une a una comunidad, se le añade automáticamente 
    a la sala de chat de esa comunidad.
    """
    if created:
        comunidad = instance.comunidad
        usuario = instance.usuario
        
        # Buscar la sala de chat de la comunidad
        # Usamos filter y first para evitar excepciones si no existe (aunque debería existir)
        sala = SalaChat.objects.filter(comunidad=comunidad, es_grupal=True).first()
        
        if sala:
            sala.miembros.add(usuario)

@receiver(post_save, sender=Comunidad)
def crear_sala_chat_comunidad(sender, instance, created, **kwargs):
    """
    Cuando se crea una nueva comunidad, se crea automáticamente su sala de chat.
    """
    if created:
        SalaChat.objects.create(
            nombre=f"Chat de {instance.nombre}",
            comunidad=instance,
            es_grupal=True,
            es_publica=True # Pública para que aparezca en búsquedas/exploración si se desea
        )
        # El creador se añade automáticamente si es miembro (manejado por el otro signal o manualmente)
