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
    es_general = models.BooleanField(default=False) # Identifica la sala principal de una comunidad
    invite_token = models.CharField(
        max_length=100, unique=True, null=True, blank=True
    )
    miembros = models.ManyToManyField(
        Usuario, related_name='salas_pertenecientes', through='ParticipanteChat', blank=True
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    # Customización colaborativa
    avatar_s3 = models.CharField(max_length=500, null=True, blank=True)
    configuracion = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return self.nombre


class PersonalizacionChat(models.Model):
    """Configuración visual compartida de una sala de chat."""
    
    class Meta:
        db_table = 'chat_personalizacion'
        
    sala = models.OneToOneField(SalaChat, on_delete=models.CASCADE, related_name='personalizacion_v2')
    color_fondo = models.CharField(max_length=50, null=True, blank=True)
    color_burbuja_mio = models.CharField(max_length=50, null=True, blank=True)
    color_burbuja_otro = models.CharField(max_length=50, null=True, blank=True)
    color_texto_mio = models.CharField(max_length=50, null=True, blank=True)
    color_texto_otro = models.CharField(max_length=50, null=True, blank=True)
    color_nombre_mio = models.CharField(max_length=50, null=True, blank=True)
    color_nombre_otro = models.CharField(max_length=50, null=True, blank=True)
    gradiente_fondo = models.CharField(max_length=200, null=True, blank=True)
    patron_fondo = models.CharField(max_length=50, null=True, blank=True)
    imagen_fondo_s3 = models.CharField(max_length=500, null=True, blank=True)
    forma_burbuja = models.CharField(max_length=50, default='redondeada')
    estilo_burbuja = models.CharField(max_length=50, default='estandar')
    font_size = models.IntegerField(default=14)
    tema = models.CharField(max_length=20, default='claro')
    
    def __str__(self):
        return f"Personalización de {self.sala.nombre}"


class ApodoPersonalizado(models.Model):
    """Apodo que un usuario le asigna a otro dentro de una sala específica."""
    
    class Meta:
        db_table = 'chat_apodos'
        unique_together = ('sala', 'asignador', 'asignado')
        
    sala = models.ForeignKey(SalaChat, on_delete=models.CASCADE, related_name='apodos_personalizados')
    asignador = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='apodos_dados')
    asignado = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='apodos_recibidos')
    apodo = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.asignador} llama '{self.apodo}' a {self.asignado} en {self.sala}"


class ParticipanteChat(models.Model):
    """Relación de pertenencia de un usuario a una sala de chat."""

    class Meta:
        db_table = 'participantes_chat'

    sala = models.ForeignKey(SalaChat, on_delete=models.CASCADE)
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    fecha_union = models.DateTimeField(auto_now_add=True)
    apodo = models.CharField(max_length=100, null=True, blank=True)

    def __str__(self):
        return f"{self.usuario.nombre_usuario} en {self.sala.nombre}"


class MensajeChat(models.Model):
    """Mensaje individual enviado dentro de una sala de chat.

    Soporta texto, imágenes, vídeos y mensajes de sistema.
    """
    TIPO_CHOICES = (
        ('TEXTO', 'Texto'),
        ('IMAGEN', 'Imagen'),
        ('VIDEO', 'Vídeo'),
        ('SISTEMA', 'Sistema'),
    )

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
    
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='TEXTO')

    def __str__(self):
        return f"Mensaje #{self.id} ({self.tipo}) en {self.sala.nombre}"