from django.db import models
from django.db.models import Q
from django.db.models.signals import post_save
from django.dispatch import receiver
from comunidades.models import MiembrosComunidad, Comunidad
from .models import SalaChat, ParticipanteChat

@receiver(post_save, sender=MiembrosComunidad)
def agregar_miembro_a_chat_comunidad(sender, instance, created, **kwargs):
    """
    Cuando un usuario se une a una comunidad, se le añade automáticamente 
    a la sala de chat de esa comunidad.
    """
    if created:
        comunidad = instance.comunidad
        usuario = instance.usuario
        
        sala = SalaChat.objects.filter(
            comunidad=comunidad, 
            es_grupal=True,
            es_general=True
        ).first()
        
        if not sala:
            sala = SalaChat.objects.filter(
                comunidad=comunidad, 
                es_grupal=True
            ).filter(
                Q(nombre__istartswith='Chat de') | Q(nombre__icontains='General')
            ).first()

        if sala:
            sala.miembros.add(usuario)

@receiver(post_save, sender=Comunidad)
def crear_sala_chat_comunidad(sender, instance, created, **kwargs):
    """
    Cuando se crea una nueva comunidad, se crea automáticamente su sala de chat principal.
    """
    if created:
        SalaChat.objects.create(
            nombre=f"Chat de {instance.nombre}",
            comunidad=instance,
            es_grupal=True,
            es_publica=True,
            es_general=True # Marcamos esta como la sala principal
        )
