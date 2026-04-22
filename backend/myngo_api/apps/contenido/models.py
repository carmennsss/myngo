from django.db import models
from usuarios.models import Usuario
from comunidades.models import Comunidad
import os
class Imagenes_galeria(models.Model):
    class Meta:
        db_table = 'imagenes_galeria'
    
    TIPO_ARCHIVO = [
        ('I', 'Imagen'),
        ('V', 'Video'),
    ]
    
    def definir_ruta_almacenamiento(instance,filename):
        ruta_s3=""
    # Buscamos el atributo temporal 'es_avatar' que inyectaremos en la vista
    # Si no existe, por defecto es False
        es_avatar = getattr(instance, '_es_avatar', False)
        
        if es_avatar:
            ruta_s3="perfiles/avatar"
        else:
            ruta_s3="publicaciones/archivos"
        return os.path.join(ruta_s3, filename)
    
    propietario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True,blank=True)
    url_s3=models.ImageField(upload_to=definir_ruta_almacenamiento, max_length=500,null=True,blank=True)
    tipo_archivo=models.CharField(max_length=1, choices=TIPO_ARCHIVO, default='I')
    relacion_aspecto=models.FloatField(default=1.0)
    es_publica=models.BooleanField(default=True)
    fecha_subida=models.DateTimeField(auto_now_add=True)
    etiquetas=models.CharField(max_length=200,null=True, blank=True)

class Publicacion(models.Model):
    class Meta:
        db_table = 'publicacion'
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE,blank=True)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True, blank=True)
    titulo=models.CharField(max_length=200,null=True, blank=True)
    contenido_texto=models.TextField(null=True, blank=True)
    imagen=models.ForeignKey(Imagenes_galeria,on_delete=models.CASCADE,null=True,blank=True) # Mantenido por compatibilidad
    imagenes=models.ManyToManyField(Imagenes_galeria, related_name='publicaciones_asociadas', blank=True)
    relacion_aspecto=models.FloatField(default=1.0)
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)


class Coleccion(models.Model):
    class Meta:
        db_table = 'colecciones'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    comunidad=models.ForeignKey(Comunidad,on_delete=models.CASCADE,null=True, blank=True)
    nombre_coleccion=models.CharField(max_length=100)
    descripcion=models.TextField(null=True, blank=True)
    categoria=models.CharField(max_length=50,null=True, blank=True)
    es_privada=models.BooleanField(default=False)
    imagenes=models.ManyToManyField(Imagenes_galeria, related_name='en_colecciones')
    fecha_creacion=models.DateTimeField(auto_now_add=True)

# Eliminamos Imagenes_en_colecciones ya que el ManyToManyField genera la tabla intermedia automáticamente
# y no necesitamos campos extra por ahora.

class Me_gustas(models.Model):
    class Meta:
        db_table = 'me_gustas'
    usuario=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    fecha_like=models.DateTimeField(auto_now_add=True)
class Comentario(models.Model):
    class Meta:
        db_table = 'comentarios'
    publicacion=models.ForeignKey(Publicacion,on_delete=models.CASCADE)
    autor=models.ForeignKey(Usuario,on_delete=models.CASCADE)
    contenido=models.TextField()
    es_valido_ia=models.BooleanField(default=True)
    fecha_creacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
    
class Reporte(models.Model):
    class Meta:
        db_table = 'reportes'
    
    informador = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='reportes_enviados')
    tipo_objeto = models.CharField(max_length=20, choices=[
        ('POST', 'Publicación'),
        ('IMAGEN', 'Imagen'),
        ('COMUNIDAD', 'Comunidad'),
        ('COMENTARIO', 'Comentario'),
    ])
    objeto_id = models.IntegerField()
    motivo = models.CharField(max_length=100)
    comentario = models.TextField(null=True, blank=True)
    comunidad = models.ForeignKey(Comunidad, on_delete=models.CASCADE, null=True, blank=True)
    estado = models.CharField(max_length=20, default='PENDIENTE', choices=[
        ('PENDIENTE', 'Pendiente'),
        ('RESUELTO', 'Resuelto'),
        ('DESESTIMADO', 'Desestimado'),
    ])
    fecha_reporte = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reporte {self.tipo_objeto} ({self.estado})"

class PostGuardado(models.Model):
    class Meta:
        db_table = 'posts_guardados'
        unique_together = ('usuario', 'publicacion')
    
    usuario=models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='posts_guardados')
    publicacion=models.ForeignKey(Publicacion, on_delete=models.CASCADE, related_name='guardado_por')
    fecha_guardado=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Post {self.publicacion_id} guardado por {self.usuario.nombre_usuario}"