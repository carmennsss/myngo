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
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

from usuarios.models import Usuario
from .models import MensajeChat, SalaChat, ParticipanteChat, PersonalizacionChat, ApodoPersonalizado
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
        
        # Filtramos salas donde el usuario es miembro
        queryset = SalaChat.objects.filter(miembros=self.request.user)
        
        comunidad_id = self.request.query_params.get('comunidad_id')
        if comunidad_id:
            queryset = queryset.filter(comunidad_id=comunidad_id)

        # Anotamos la fecha de última actividad (mensaje más reciente o creación de la sala)
        # Usamos distinct() antes de la anotación para evitar duplicados por el join de miembros
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


class MensajesChatPagination(pagination.PageNumberPagination):
    page_size = 30


class MensajesChatList(generics.ListAPIView):
    """Recupera el historial de mensajes de una sala."""
    serializer_class = MensajeChatSerializer
    pagination_class = MensajesChatPagination
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        sala_id = self.kwargs['sala_id']
        if not SalaChat.objects.filter(id=sala_id, miembros=self.request.user).exists():
            return MensajeChat.objects.none()
        return MensajeChat.objects.filter(sala_id=sala_id).order_by('-fecha_envio')


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
    salas = SalaChat.objects.filter(miembros=request.user)
    no_leidos = MensajeChat.objects.filter(sala__in=salas).exclude(leido_por=request.user).exclude(emisor=request.user)
    total = no_leidos.count()
    por_sala = no_leidos.values('sala_id').annotate(count=Count('id'))
    return Response({'total': total, 'por_sala': list(por_sala)})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def agregar_miembro(request, pk):
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
def subir_avatar_sala(request, pk):
    """Sube una imagen a S3 y la establece como avatar de la sala."""
    try:
        sala = SalaChat.objects.get(pk=pk, miembros=request.user)
        imagen = request.FILES.get('avatar')
        
        if not imagen:
            return Response({'error': 'No se proporcionó ninguna imagen'}, status=400)
            
        # Usamos ImagenGaleria como almacén temporal/permanente para S3
        from contenido.models import ImagenGaleria
        img_instancia = ImagenGaleria.objects.create(
            propietario=request.user,
            url_s3=imagen,
            comunidad_id=sala.comunidad_id,
            tipo_archivo='I'
        )
        
        sala.avatar_s3 = img_instancia.url_s3.url
        sala.save()
        
        return Response({
            'status': 'ok',
            'url_avatar': sala.avatar_s3
        })
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
