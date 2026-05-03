"""Modelos del dominio de mensajería: salas, participantes y mensajes de chat."""

from django.db import models

from comunidades.models import Comunidad
from usuarios.models import Usuario


class SalaChat(models.Model):
    """Sala de conversación para usuarios.

    Puede estar vinculada a una comunidad o ser una sala privada global.
    Las salas pueden ser grupales o individuales (DM).
    """

    class Meta:
        db_table = 'salas_chat'

    nombre = models.CharField(max_length=100)
    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, null=True, blank=True
    )
    es_grupal = models.BooleanField(default=False)
    es_publica = models.BooleanField(default=False)
    invite_token = models.CharField(
        max_length=100, unique=True, null=True, blank=True
    )
    miembros = models.ManyToManyField(
        Usuario, related_name='salas_pertenecientes', through='SalaChatMiembro', blank=True
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre


class SalaChatMiembro(models.Model):
    """
    Modelo intermedio explícito para forzar el mapeo de la columna antigua 'salas_chat_id'.
    Se usa managed=False para que Django no intente crear o alterar esta tabla.
    """
    class Meta:
        db_table = 'salas_chat_miembros'
        managed = False

    salachat = models.ForeignKey(SalaChat, on_delete=models.CASCADE, db_column='salachat_id')
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, db_column='usuario_id')



class ParticipanteChat(models.Model):
    """Relación de pertenencia de un usuario a una sala de chat."""

    class Meta:
        db_table = 'participantes_chat'

    sala = models.ForeignKey(SalaChat, on_delete=models.CASCADE)
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    fecha_union = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.usuario.nombre_usuario} en {self.sala.nombre}"


class MensajeChat(models.Model):
    """Mensaje individual enviado dentro de una sala de chat.

    Soporta texto y referencias a archivos almacenados en S3.
    Mantiene el estado de lectura del mensaje.
    """

    class Meta:
        db_table = 'mensajes_chat'

    sala = models.ForeignKey(
        SalaChat, on_delete=models.CASCADE, related_name='mensajes'
    )
    emisor = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    contenido = models.TextField(null=True, blank=True)
    url_archivo_s3 = models.CharField(max_length=500, null=True, blank=True)
    fecha_envio = models.DateTimeField(auto_now_add=True)
    leido_por = models.ManyToManyField(Usuario, related_name='mensajes_leidos', blank=True)
    referencia_a = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='respuestas')
    es_editado = models.BooleanField(default=False)
    fecha_edicion = models.DateTimeField(null=True, blank=True)
    borrado_para_todos = models.BooleanField(default=False)
    borrado_para = models.ManyToManyField(Usuario, related_name='mensajes_borrados_localmente', blank=True)

    def __str__(self):
        return f"Mensaje #{self.id} en {self.sala.nombre}"