"""Vistas para la gestión de salas de chat y mensajes.

Proporciona endpoints para listar, crear y administrar la pertenencia a salas,
así como para recuperar el historial de mensajes y gestionar estados de lectura.
"""

import uuid
import json

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db.models import Count, Max, OuterRef, Q, Subquery
from django.utils import timezone
from rest_framework import generics, pagination, permissions, status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
import mimetypes
from django.core.exceptions import ValidationError

from usuarios.models import Usuario
from .models import MensajeChat, SalaChat, ParticipanteChat, PersonalizacionChat, ApodoPersonalizado
from contenido.models import ImagenGaleria
from .serializers import MensajeChatSerializer, SalaChatSerializer, ParticipanteChatSerializer


class SalaChatListCreate(generics.ListCreateAPIView):
    """Lista y crea salas de chat."""

    serializer_class = SalaChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        from django.db.models.functions import Coalesce
        from django.db.models import Q
        
        comunidad_id = self.request.query_params.get('comunidad_id')
        
        if comunidad_id:
            # Si filtramos por comunidad, mostramos salas donde el usuario es miembro O son públicas
            queryset = SalaChat.objects.filter(
                Q(comunidad_id=comunidad_id) & (Q(miembros=self.request.user) | Q(es_publica=True))
            )
        else:
            # En la lista general (Mis Chats), solo mostramos donde el usuario es miembro
            queryset = SalaChat.objects.filter(miembros=self.request.user)

        # Anotamos la fecha de última actividad
        return queryset.distinct().annotate(
            ultima_actividad=Coalesce(Max('mensajes__fecha_envio'), 'fecha_creacion')
        ).prefetch_related(
            'miembros',
            'miembros__perfil',
            'personalizacion_v2'
        ).order_by('-ultima_actividad')

    def create(self, request, *args, **kwargs):
        nombre = request.data.get('nombre', f'Sala_{request.user.nombre_usuario}')
        es_grupal = request.data.get('es_grupal', False)
        es_publica = request.data.get('es_publica', False)
        comunidad_id = request.data.get('comunidad_id')
        otro_usuario_id = request.data.get('otro_usuario_id')
        miembros_ids = request.data.get('miembros_ids', [])

        if not es_grupal and otro_usuario_id:
            try:
                otro = Usuario.objects.get(pk=otro_usuario_id)
                sala_existente = SalaChat.objects.filter(
                    es_grupal=False,
                    miembros=request.user,
                    comunidad_id=comunidad_id
                ).filter(miembros=otro).first()

                if sala_existente:
                    return Response(
                        SalaChatSerializer(sala_existente, context={'request': request}).data,
                        status=status.HTTP_200_OK
                    )
            except Usuario.DoesNotExist:
                pass

        if comunidad_id:
            # Validar que el nombre sea único en esta comunidad para evitar confusión
            existe_nombre = SalaChat.objects.filter(comunidad_id=comunidad_id, nombre=nombre).exists()
            if existe_nombre:
                return Response(
                    {'error': f'Ya existe una sala llamada "{nombre}" en esta comunidad.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        sala = SalaChat.objects.create(
            nombre=nombre,
            es_grupal=es_grupal,
            es_publica=es_publica,
            comunidad_id=comunidad_id,
            invite_token=str(uuid.uuid4()),
            creador=request.user,
        )
        sala.miembros.add(request.user)

        if otro_usuario_id:
            try:
                sala.miembros.add(Usuario.objects.get(pk=otro_usuario_id))
            except Usuario.DoesNotExist:
                pass
        
        if miembros_ids:
            for m_id in miembros_ids:
                if m_id == request.user.id: continue
                try:
                    sala.miembros.add(Usuario.objects.get(pk=m_id))
                except Usuario.DoesNotExist:
                    pass

        channel_layer = get_channel_layer()
        for miembro in sala.miembros.all():
            if miembro.id != request.user.id:
                async_to_sync(channel_layer.group_send)(
                    f'user_{miembro.id}_notif',
                    {
                        'type': 'new_chat_notification',
                        'sala_id': sala.id,
                        'nombre': sala.nombre,
                        'es_grupal': sala.es_grupal,
                    }
                )

        return Response(
            SalaChatSerializer(sala, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


class SalaChatDetail(generics.RetrieveAPIView):
    """Recupera los detalles de una sala de chat específica."""
    serializer_class = SalaChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Aseguramos que el usuario solo pueda ver salas de las que es miembro
        return SalaChat.objects.filter(miembros=self.request.user)


class MensajesChatPagination(pagination.LimitOffsetPagination):
    default_limit = 30
    max_limit = 100


class MensajesChatList(generics.ListAPIView):
    """Recupera el historial de mensajes de una sala."""
    serializer_class = MensajeChatSerializer
    pagination_class = MensajesChatPagination
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        sala_id = self.kwargs['sala_id']
        if not SalaChat.objects.filter(id=sala_id, miembros=self.request.user).exists():
            return MensajeChat.objects.none()
        # Excluimos mensajes borrados localmente por el usuario
        return MensajeChat.objects.filter(sala_id=sala_id).exclude(borrado_para=self.request.user).order_by('-fecha_envio')


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def marcar_leidos(request, sala_id):
    """Marca todos los mensajes de una sala como leídos por el usuario."""
    try:
        sala = SalaChat.objects.get(id=sala_id, miembros=request.user)
        mensajes_no_leidos = MensajeChat.objects.filter(
            sala=sala
        ).exclude(leido_por=request.user).exclude(emisor=request.user)

        leidos_ids = list(mensajes_no_leidos.values_list('id', flat=True))
        for mensaje in mensajes_no_leidos:
            mensaje.leido_por.add(request.user)

        if leidos_ids:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{sala_id}',
                {
                    'type': 'messages_read',
                    'leidos_ids': leidos_ids,
                    'leido_por': request.user.id
                }
            )

        return Response({'status': 'ok', 'count': len(leidos_ids)})
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=404)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def conteo_no_leidos(request):
    """Obtiene el número total de mensajes no leídos del usuario en todas sus salas."""
    salas = SalaChat.objects.filter(miembros=request.user)
    no_leidos = MensajeChat.objects.filter(
        sala__in=salas
    ).exclude(
        leido_por=request.user
    ).exclude(
        emisor=request.user
    ).exclude(
        tipo='SISTEMA'
    )
    total = no_leidos.count()
    por_sala = no_leidos.values('sala_id').annotate(count=Count('id'))
    return Response({'total': total, 'por_sala': list(por_sala)})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def agregar_miembro(request, pk):
    """Añade un usuario a una sala de chat grupal existente."""
    try:
        sala = SalaChat.objects.get(pk=pk, miembros=request.user)
        if not sala.es_grupal:
            return Response({'error': 'Solo se pueden añadir miembros a salas grupales'}, status=400)
            
        usuario_id = request.data.get('usuario_id')
        usuario = Usuario.objects.get(pk=usuario_id)
        sala.miembros.add(usuario)
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{pk}',
            {
                'type': 'user_joined',
                'user_id': usuario.id,
                'username': usuario.nombre_usuario
            }
        )
        return Response({'status': 'ok'})
    except (SalaChat.DoesNotExist, Usuario.DoesNotExist):
        return Response({'error': 'No encontrado'}, status=404)


@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def editar_mensaje(request, mensaje_id):
    """Modifica el contenido de un mensaje enviado previamente por el usuario."""
    try:
        mensaje = MensajeChat.objects.get(id=mensaje_id, emisor=request.user)
        nuevo_contenido = request.data.get('contenido')
        if not nuevo_contenido: return Response({'error': 'Contenido requerido'}, status=400)
            
        mensaje.contenido = nuevo_contenido
        mensaje.es_editado = True
        mensaje.save()
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{mensaje.sala.id}',
            {
                'type': 'message_edited',
                'mensaje_id': mensaje.id,
                'nuevo_contenido': nuevo_contenido
            }
        )
        return Response({'status': 'ok'})
    except MensajeChat.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado o sin permisos'}, status=404)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def borrar_mensaje(request, mensaje_id):
    """Borra un mensaje localmente o para todos los participantes si el usuario es el emisor."""
    try:
        mensaje = MensajeChat.objects.get(id=mensaje_id)
        para_todos = request.data.get('para_todos', False)
        
        if para_todos:
            if mensaje.emisor != request.user:
                return Response({'error': 'No puedes borrar mensajes de otros para todos'}, status=403)
            mensaje.borrado_para_todos = True
            mensaje.contenido = "Mensaje borrado"
            mensaje.url_archivo_s3 = None
            mensaje.save()
            
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{mensaje.sala.id}',
                {
                    'type': 'message_deleted', 'mensaje_id': mensaje.id, 'para_todos': True
                }
            )
        else:
            # Borrado local (para mí)
            mensaje.borrado_para.add(request.user)
            
        return Response({'status': 'ok'})
    except MensajeChat.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado'}, status=404)


@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def actualizar_sala(request, pk):
    """Actualiza configuración visual y metadatos de una sala."""
    try:
        sala = SalaChat.objects.get(pk=pk, miembros=request.user)
        nombre = request.data.get('nombre')
        avatar_s3 = request.data.get('avatar_s3')
        visual_config = request.data.get('personalizacion')
        
        cambios = []
        
        if nombre and nombre != sala.nombre:
            sala.nombre = nombre
            cambios.append(f"ha cambiado el nombre del chat a '{nombre}'")
            
        if avatar_s3 and avatar_s3 != sala.avatar_s3:
            sala.avatar_s3 = avatar_s3
            cambios.append("ha cambiado la foto del chat")
            
        sala.save()
        
        if visual_config:
            perso, created = PersonalizacionChat.objects.get_or_create(sala=sala)
            
            campos_visuales = {
                'color_fondo': 'el fondo del chat',
                'color_burbuja_mio': 'el color de sus burbujas',
                'color_burbuja_otro': 'el color de las burbujas de los demás',
                'color_texto_mio': 'el color del texto propio',
                'color_texto_otro': 'el color del texto de otros',
                'color_nombre_mio': 'el color de su nombre',
                'color_nombre_otro': 'el color del nombre de los demás',
                'gradiente_fondo': 'el gradiente de fondo',
                'patron_fondo': 'el patrón de fondo',
                'forma_burbuja': 'la forma de las burbujas',
                'estilo_burbuja': 'el estilo de las burbujas',
                'font_size': 'el tamaño de fuente',
                'tema': 'el tema del chat',
                'imagen_fondo_s3': 'la imagen de fondo',
            }
            
            visual_modified = False
            for campo, descripcion in campos_visuales.items():
                if campo in visual_config and visual_config[campo] != getattr(perso, campo):
                    setattr(perso, campo, visual_config[campo])
                    cambios.append(f"ha cambiado {descripcion}")
                    visual_modified = True
            
            if visual_modified: perso.save()

        # Crear mensajes de sistema
        for cambio in cambios:
            MensajeChat.objects.create(
                sala=sala,
                emisor=request.user,
                contenido=f"💬 {request.user.nombre_usuario} {cambio}",
                tipo='SISTEMA'
            )

        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{pk}',
            {
                'type': 'room_updated',
                'data': SalaChatSerializer(sala, context={'request': request}).data,
                'system_messages': [f"💬 {request.user.nombre_usuario} {c}" for c in cambios]
            }
        )
        
        return Response(SalaChatSerializer(sala, context={'request': request}).data)
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=404)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def actualizar_apodo_personalizado(request, sala_id):
    """Establece un apodo privado para otro usuario en un chat."""
    try:
        sala = SalaChat.objects.get(id=sala_id, miembros=request.user)
        objetivo_id = request.data.get('usuario_id')
        nuevo_apodo = request.data.get('apodo')
        
        if not objetivo_id:
            return Response({'error': 'usuario_id requerido'}, status=400)
            
        objetivo = Usuario.objects.get(id=objetivo_id)
        
        if nuevo_apodo:
            ApodoPersonalizado.objects.update_or_create(
                sala=sala, asignador=request.user, asignado=objetivo,
                defaults={'apodo': nuevo_apodo}
            )
            
            MensajeChat.objects.create(
                sala=sala, emisor=request.user,
                contenido=f"💬 {request.user.nombre_usuario} le ha puesto el apodo '{nuevo_apodo}' a {objetivo.nombre_usuario}",
                tipo='SISTEMA'
            )
            
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{sala_id}',
                {
                    'type': 'nickname_updated',
                    'asignador_id': request.user.id,
                    'asignado_id': objetivo.id,
                    'apodo': nuevo_apodo
                }
            )
        else:
            ApodoPersonalizado.objects.filter(sala=sala, asignador=request.user, asignado=objetivo).delete()

        return Response({'status': 'ok'})
    except (SalaChat.DoesNotExist, Usuario.DoesNotExist):
        return Response({'error': 'No encontrado'}, status=404)


@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def actualizar_participante(request, sala_id):
    """Actualiza los metadatos de un participante (apodo global)."""
    try:
        participante = ParticipanteChat.objects.get(sala_id=sala_id, usuario=request.user)
        apodo = request.data.get('apodo')
        if apodo is not None:
            participante.apodo = apodo
            participante.save()
            
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{sala_id}',
                {
                    'type': 'participant_updated', 'usuario_id': request.user.id, 'apodo': apodo
                }
            )
        return Response({'status': 'ok', 'apodo': apodo})
    except ParticipanteChat.DoesNotExist:
        return Response({'error': 'Participante no encontrado'}, status=404)
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def obtener_sala_general_comunidad(request, comunidad_id):
    """Obtiene la sala marcada como general o principal de una comunidad."""
    try:
        # Priorizar sala marcada como es_general
        sala = SalaChat.objects.filter(comunidad_id=comunidad_id, es_general=True).first()
        
        if not sala:
            # Fallback por nombre
            sala = SalaChat.objects.filter(
                comunidad_id=comunidad_id,
                es_grupal=True
            ).filter(Q(nombre__icontains='General') | Q(nombre__icontains='Chat de')).first()
        
        if not sala:
            # Fallback final: cualquier sala grupal
            sala = SalaChat.objects.filter(comunidad_id=comunidad_id, es_grupal=True).first()
            
        if sala:
            return Response(SalaChatSerializer(sala, context={'request': request}).data)
        return Response({'error': 'No se encontró sala para esta comunidad'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def subir_avatar_sala(request, pk):
    """Sube una imagen a S3 y la establece como avatar de la sala."""
    try:
        sala = SalaChat.objects.get(pk=pk, miembros=request.user)
        imagen = request.FILES.get('avatar')
        
        if not imagen:
            return Response({'error': 'No se proporcionó ninguna imagen'}, status=400)
            
        # Usamos ImagenGaleria como almacén temporal/permanente para S3
        from contenido.models import ImagenGaleria
        img_instancia = ImagenGaleria(
            propietario=request.user,
            url_s3=imagen,
            comunidad_id=sala.comunidad_id,
            tipo_archivo='I'
        )
        img_instancia._es_avatar = True # Es un avatar, no contenido de chat
        img_instancia.save()
        
        sala.avatar_s3 = img_instancia.url_s3.name
        sala.save()
        
        from django.core.files.storage import default_storage
        return Response({
            'status': 'ok',
            'url_avatar': default_storage.url(sala.avatar_s3)
        })
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_chat_image(request, sala_id):
    """Sube múltiples imágenes/vídeos para un mensaje de chat y lo notifica vía WS.
    
    Adopta la lógica de publicaciones: subida local previa y envío atómico al final.
    Soporta hasta 4 archivos multimedia en un solo mensaje.
    """
    try:
        # Validamos que el usuario pertenezca a la sala
        sala = SalaChat.objects.get(id=sala_id, miembros=request.user)
        
        # Obtener archivos (múltiples nombres posibles para compatibilidad)
        archivos = (
            request.FILES.getlist('imagenes[]') or 
            request.FILES.getlist('imagen') or 
            request.FILES.getlist('url_archivo_s3[]') or
            request.FILES.getlist('archivos[]')
        )
        contenido = request.data.get('contenido', '') or request.data.get('content', '')
        
        if not archivos and not contenido:
            return Response({'error': 'No se proporcionó contenido ni archivos'}, status=status.HTTP_400_BAD_REQUEST)
            
        from django.db import transaction
        from contenido.models import ImagenGaleria
        
        with transaction.atomic():
            # Determinar tipo base del mensaje
            tipo_mensaje = 'TEXTO'
            if archivos:
                tipo_mensaje = 'IMAGEN' # Por defecto si hay archivos
            
            # Crear instancia de MensajeChat
            mensaje = MensajeChat.objects.create(
                sala=sala,
                emisor=request.user,
                contenido=contenido,
                tipo=tipo_mensaje,
                referencia_a_id=request.data.get('referencia_a')
            )
            
            # Procesar hasta 4 archivos multimedia
            for i, archivo in enumerate(archivos[:4]):
                # Detección de tipo (Lógica de views_publicaciones.py)
                tipo_archivo = 'I'
                content_type = archivo.content_type or ''
                extension = archivo.name.lower().split('.')[-1] if archivo.name else ''
                
                if content_type.startswith('video/') or extension in ['mp4', 'mov', 'avi', 'mkv', 'webm']:
                    tipo_archivo = 'V'
                    mensaje.tipo = 'VIDEO' # Si hay al menos un vídeo, el mensaje es tipo VIDEO
                
                img_instancia = ImagenGaleria(
                    propietario=request.user,
                    url_s3=archivo,
                    comunidad_id=sala.comunidad_id,
                    tipo_archivo=tipo_archivo,
                    relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0))
                )
                img_instancia._es_chat = True # Forzamos ruta chat/contenido/
                img_instancia.save()
                
                mensaje.imagenes.add(img_instancia)
                if i == 0:
                    mensaje.imagen_principal = img_instancia
            
            mensaje.save()
        
        # Notificamos el nuevo mensaje vía WebSocket
        serializer = MensajeChatSerializer(mensaje, context={'request': request})
        message_data = serializer.data
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{sala_id}',
            {
                'type': 'chat_message',
                **message_data,
                'message_id': mensaje.id, # Compatibilidad
                'user_id': request.user.id,
                'username': request.user.nombre_usuario,
            }
        )
        
        # Respuesta final al cliente
        return Response(message_data, status=status.HTTP_200_OK)
        
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada o no eres miembro'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ChatMediaUploadView(generics.CreateAPIView):
    """Sube un archivo multimedia para el chat sin crear el mensaje todavía.
    
    Valida el tipo de archivo (MIME) y el tamaño máximo.
    """
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, *args, **kwargs):
        archivo = request.FILES.get('file')
        room_id = request.data.get('room_id')

        if not archivo:
            return Response({'error': 'No se proporcionó ningún archivo'}, status=status.HTTP_400_BAD_REQUEST)

        # Verificamos el tamaño del archivo
        size_mb = archivo.size / (1024 * 1024)
        
        # Detección de MIME usando mimetypes y content_type del archivo
        mime = archivo.content_type or mimetypes.guess_type(archivo.name)[0] or 'application/octet-stream'

        tipo_archivo = 'I'
        if mime.startswith('image/'):
            if size_mb > 10:
                return Response({'error': 'La imagen excede los 10MB permitidos'}, status=status.HTTP_400_BAD_REQUEST)
            tipo_archivo = 'I'
        elif mime.startswith('video/'):
            if size_mb > 50:
                return Response({'error': 'El vídeo excede los 50MB permitidos'}, status=status.HTTP_400_BAD_REQUEST)
            tipo_archivo = 'V'
        else:
            return Response({'error': 'Tipo de archivo no soportado'}, status=status.HTTP_400_BAD_REQUEST)

        # Guardamos el archivo en la galería centralizada
        try:
            img_instancia = ImagenGaleria(
                propietario=request.user,
                url_s3=archivo,
                tipo_archivo=tipo_archivo
            )
            img_instancia._es_chat = True # Forzamos ruta chat/contenido/
            img_instancia.save()

            return Response({
                'file_url': img_instancia.url_s3.url,
                'file_type': 'image' if tipo_archivo == 'I' else 'video',
                'name': archivo.name,
                'id': img_instancia.id
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': 'Error al procesar el archivo multimedia'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def salir_sala(request, sala_id):
    """Permite a un usuario abandonar una sala de chat."""
    try:
        sala = SalaChat.objects.get(id=sala_id)
        
        # Borrar el registro de participante de forma explícita
        borrados, _ = ParticipanteChat.objects.filter(sala=sala, usuario=request.user).delete()
        
        if borrados > 0:
            # Notificar al resto vía WS
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{sala_id}',
                {
                    'type': 'user_left',
                    'user_id': request.user.id,
                    'username': request.user.nombre_usuario
                }
            )
            
            # Mensaje de sistema
            MensajeChat.objects.create(
                sala=sala,
                emisor=request.user,
                contenido=f"🚪 {request.user.nombre_usuario} ha abandonado la sala.",
                tipo='SISTEMA'
            )
        
        return Response({'status': 'ok'})
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=404)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def expulsar_miembro(request, sala_id):
    """Permite al creador expulsar a un miembro de la sala."""
    try:
        sala = SalaChat.objects.get(id=sala_id, creador=request.user)
        usuario_id = request.data.get('usuario_id')
        if not usuario_id:
            return Response({'error': 'ID de usuario requerido'}, status=400)
            
        usuario = Usuario.objects.get(id=usuario_id)
        if usuario == request.user:
            return Response({'error': 'No puedes expulsarte a ti mismo'}, status=400)
            
        sala.miembros.remove(usuario)
        
        # Notificar
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{sala_id}',
            {
                'type': 'user_kicked',
                'user_id': usuario.id,
                'username': usuario.nombre_usuario
            }
        )
        
        # Mensaje de sistema
        MensajeChat.objects.create(
            sala=sala,
            emisor=request.user,
            contenido=f"🚫 {usuario.nombre_usuario} ha sido expulsado por el administrador.",
            tipo='SISTEMA'
        )
        
        return Response({'status': 'ok'})
    except SalaChat.DoesNotExist:
        return Response({'error': 'No tienes permisos o la sala no existe'}, status=403)
    except Usuario.DoesNotExist:
        return Response({'error': 'Usuario no encontrado'}, status=404)
@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def eliminar_sala(request, sala_id):
    """Permite al creador de la sala o al creador de la comunidad eliminarla."""
    try:
        # Buscamos la sala
        sala = SalaChat.objects.get(id=sala_id)
        
        # Verificamos si es el creador de la sala
        es_creador_sala = sala.creador == request.user
        
        # Fallback para salas antiguas
        if sala.creador is None and not es_creador_sala:
            from .models import ParticipanteChat
            primer = ParticipanteChat.objects.filter(sala=sala).order_by('id').first()
            if primer and primer.usuario == request.user:
                es_creador_sala = True
                
        # Verificamos si es el dueño de la comunidad
        es_dueno_comunidad = False
        if sala.comunidad_id:
            from comunidades.models import Comunidad
            try:
                comunidad = Comunidad.objects.get(id=sala.comunidad_id)
                es_dueno_comunidad = comunidad.creador == request.user
            except Comunidad.DoesNotExist:
                pass
        
        if not (es_creador_sala or es_dueno_comunidad):
            return Response({'error': 'No tienes permisos para eliminar esta sala'}, status=403)
        
        id_borrada = sala.id
        nombre_borrada = sala.nombre
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{id_borrada}',
            {
                'type': 'room_deleted',
                'sala_id': id_borrada,
                'nombre': nombre_borrada
            }
        )
        
        sala.delete()
        return Response({'status': 'ok', 'mensaje': 'Sala eliminada correctamente'})
    except SalaChat.DoesNotExist:
        return Response({'error': 'La sala no existe'}, status=404)
