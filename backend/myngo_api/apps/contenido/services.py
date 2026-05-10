import requests
import uuid
import os
from django.core.files.base import ContentFile
from django.conf import settings
import boto3
from botocore.exceptions import ClientError
from .models import Publicacion, ImagenGaleria, PublicacionImagen

def descargar_y_subir_a_s3(url_externa, sub_path):
    """
    Descarga un recurso multimedia desde una URL externa y lo almacena 
    directamente en el bucket de S3 configurado.
    """
    try:
        response = requests.get(url_externa, timeout=15)
        response.raise_for_status()
        
        content_type = response.headers.get('Content-Type', 'image/jpeg')
        ext = 'jpg'
        if 'png' in content_type: ext = 'png'
        elif 'gif' in content_type: ext = 'gif'
        elif 'webp' in content_type: ext = 'webp'
        
        file_name = f"{uuid.uuid4()}.{ext}"
        full_path = f"{sub_path}/{file_name}"
        
        s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME
        )
        
        s3_client.put_object(
            Bucket=settings.AWS_STORAGE_BUCKET_NAME,
            Key=full_path,
            Body=response.content,
            ContentType=content_type,
            Metadata={'original_source': url_externa}
        )
        
        return full_path
        
    except Exception:
        return None

def crear_publicacion_completa(autor, comunidad, titulo, contenido, tags_list, num_imagenes=1):
    """
    Crea una instancia de Publicacion vinculando metadatos y descargando 
    recursos multimedia de ejemplo asociados a la galería.
    """
    try:
        post = Publicacion.objects.create(
            autor=autor,
            comunidad=comunidad,
            titulo=titulo,
            contenido_texto=contenido
        )
        
        etiquetas_str = ", ".join(tags_list)
        
        for i in range(num_imagenes):
            url_img = f"https://picsum.photos/seed/{uuid.uuid4()}/1080/1080"
            ruta_s3 = descargar_y_subir_a_s3(url_img, f"posts/{post.id}")
            
            if ruta_s3:
                img_instancia = ImagenGaleria.objects.create(
                    propietario=autor,
                    url_s3=ruta_s3,
                    comunidad=comunidad,
                    etiquetas=etiquetas_str,
                    tipo_archivo='I'
                )
                
                PublicacionImagen.objects.create(
                    publicacion=post,
                    imagen=img_instancia,
                    orden=i
                )
                
                if i == 0:
                    post.imagen = img_instancia
                    post.save()
        
        return post
        
    except Exception:
        return None
