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
    Descarga una imagen de una URL externa y la sube manualmente a S3.
    Retorna el nombre del archivo relativo para guardar en el modelo.
    """
    try:
        # 1. Descargar la imagen
        response = requests.get(url_externa, timeout=15)
        response.raise_for_status()
        
        content_type = response.headers.get('Content-Type', 'image/jpeg')
        # Determinar extensión simple
        ext = 'jpg'
        if 'png' in content_type: ext = 'png'
        elif 'gif' in content_type: ext = 'gif'
        elif 'webp' in content_type: ext = 'webp'
        
        file_name = f"{uuid.uuid4()}.{ext}"
        full_path = f"{sub_path}/{file_name}"
        
        # 2. Subir a S3 manualmente (boto3)
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
        
    except Exception as e:
        print(f"   [!] Error procesando imagen {url_externa}: {e}")
        return None

def crear_publicacion_completa(autor, comunidad, titulo, contenido, tags_list, num_imagenes=1):
    """
    Crea un post con múltiples imágenes subidas a S3 y etiquetas.
    """
    try:
        # Crear la publicación básica
        post = Publicacion.objects.create(
            autor=autor,
            comunidad=comunidad,
            titulo=titulo,
            contenido_texto=contenido
        )
        
        # Generar etiquetas (formato string separado por comas para ImagenGaleria)
        etiquetas_str = ", ".join(tags_list)
        
        # Descargar y asociar imágenes
        for i in range(num_imagenes):
            # Usamos Picsum con una semilla para variedad
            url_img = f"https://picsum.photos/seed/{uuid.uuid4()}/1080/1080"
            ruta_s3 = descargar_y_subir_a_s3(url_img, f"posts/{post.id}")
            
            if ruta_s3:
                # Crear instancia de ImagenGaleria
                img_instancia = ImagenGaleria.objects.create(
                    propietario=autor,
                    url_s3=ruta_s3, # django-storages lo manejará si le pasamos el path relativo
                    comunidad=comunidad,
                    etiquetas=etiquetas_str,
                    tipo_archivo='I'
                )
                
                # Asociar al post con orden
                PublicacionImagen.objects.create(
                    publicacion=post,
                    imagen=img_instancia,
                    orden=i
                )
                
                # Si es la primera, ponerla como imagen principal (compatibilidad)
                if i == 0:
                    post.imagen = img_instancia
                    post.save()
        
        return post
        
    except Exception as e:
        print(f"   [!] Error creando publicación completa: {e}")
        return None
