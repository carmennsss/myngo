"""Vistas para la gestión de salas de chat y mensajes.

Proporciona endpoints para listar, crear y administrar la pertenencia a salas,
así como para recuperar el historial de mensajes y gestionar estados de lectura.
"""

import uuid

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db.models import Count, Max, OuterRef, Q, Subquery
from django.utils import timezone
from rest_framework import generics, pagination, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

from usuarios.models import Usuario
from .models import MensajeChat, SalaChat
from .serializers import MensajeChatSerializer, SalaChatSerializer


class SalaChatListCreate(generics.ListCreateAPIView):
    """Lista y crea salas de chat.

    Anota las salas con la fecha del último mensaje y el conteo de mensajes
    no leídos para el usuario que realiza la petición.
    """

    serializer_class = SalaChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        """Incluye el request en el contexto del serializador.

        Returns:
            dict: Contexto del serializador.
        """
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        """Obtiene las salas del usuario con anotaciones de actividad.

        Returns:
            QuerySet: Salas de chat ordenadas por actividad reciente.
        """
        # Subconsulta para contar mensajes no leídos de otros para esta sala
        no_leidos_subquery = MensajeChat.objects.filter(
            sala=OuterRef('pk'),
        ).exclude(leido_por=self.request.user).exclude(emisor=self.request.user).values('sala').annotate(cnt=Count('id')).values('cnt')

        queryset = SalaChat.objects.all()
        comunidad_id = self.request.query_params.get('comunidad_id')

        if comunidad_id:
            # Si se pide una comunidad específica, solo mostrar salas de esa comunidad
            queryset = queryset.filter(comunidad_id=comunidad_id)
        else:
            # Si no hay comunidad (pestaña mensajes global), mostrar SOLO mis chats privados (DMs)
            # Filtramos para que comunidad sea NULL
            queryset = queryset.filter(
                miembros=self.request.user,
                comunidad__isnull=True
            )

        return queryset.distinct().annotate(
            fecha_ultimo_mensaje=Max('mensajes__fecha_envio'),
            count_no_leidos=Subquery(no_leidos_subquery)
        ).prefetch_related(
            'miembros',
            'miembros__perfil'
        ).order_by('-fecha_ultimo_mensaje', '-fecha_creacion')

    def create(self, request, *args, **kwargs):
        """Crea una sala de chat grupal o privada.

        Si se intenta crear una sala privada que ya existe entre los mismos
        usuarios, se devuelve la instancia existente.

        Args:
            request: Datos con 'nombre', 'es_grupal', 'es_publica', 'comunidad_id' y 'miembros_ids'.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Sala creada o encontrada.
        """
        nombre = request.data.get('nombre', f'Sala_{request.user.nombre_usuario}')
        es_grupal = request.data.get('es_grupal', False)
        es_publica = request.data.get('es_publica', False)
        comunidad_id = request.data.get('comunidad_id')
        otro_usuario_id = request.data.get('otro_usuario_id')
        miembros_ids = request.data.get('miembros_ids', [])

        # Si es privada y ya existe una sala entre estos dos usuarios, devolver la existente
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

        # Crear nueva sala
        sala = SalaChat.objects.create(
            nombre=nombre,
            es_grupal=es_grupal,
            es_publica=es_publica,
            comunidad_id=comunidad_id,
            invite_token=str(uuid.uuid4()),
        )
        sala.miembros.add(request.user)

        # Añadir otro usuario (si se proporcionó uno solo)
        if otro_usuario_id:
            try:
                sala.miembros.add(Usuario.objects.get(pk=otro_usuario_id))
            except Usuario.DoesNotExist:
                pass
        
        # Añadir lista de miembros
        if miembros_ids:
            for m_id in miembros_ids:
                if m_id == request.user.id:
                    continue
                try:
                    sala.miembros.add(Usuario.objects.get(pk=m_id))
                except Usuario.DoesNotExist:
                    pass

        return Response(
            SalaChatSerializer(sala, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def agregar_miembro(request, pk):
    """Añade un nuevo miembro a una sala de chat existente.

    Args:
        request: Datos con 'user_id'.
        pk (int): ID de la sala.

    Returns:
        Response: Resultado de la operación.
    """
    try:
        sala = SalaChat.objects.get(pk=pk)
        user_id = request.data.get('user_id')
        usuario_a_agregar = Usuario.objects.get(pk=user_id)

        if not sala.miembros.filter(id=request.user.id).exists():
            return Response(
                {'error': 'No tienes permiso para añadir miembros'},
                status=status.HTTP_403_FORBIDDEN
            )

        sala.miembros.add(usuario_a_agregar)
        return Response({
            'mensaje': f'Usuario {usuario_a_agregar.nombre_usuario} añadido correctamente'
        })
    except SalaChat.DoesNotExist:
        return Response({'error': 'Sala no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    except Usuario.DoesNotExist:
        return Response({'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)


class MensajePagination(pagination.LimitOffsetPagination):
    """Paginación para el historial de mensajes (30 por defecto)."""

    default_limit = 30
    max_limit = 100


class MensajesChatList(generics.ListAPIView):
    """Recupera el historial de mensajes de una sala específica."""

    serializer_class = MensajeChatSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = MensajePagination

    def get_queryset(self):
        """Obtiene los mensajes de la sala validando acceso.

        Returns:
            QuerySet: Mensajes ordenados cronológicamente a la inversa.
        """
        sala_id = self.kwargs.get('sala_id')
        if not SalaChat.objects.filter(
            Q(id=sala_id, miembros=self.request.user) | Q(id=sala_id, es_publica=True)
        ).exists():
            return MensajeChat.objects.none()
        return MensajeChat.objects.filter(sala_id=sala_id)\
            .exclude(borrado_para=self.request.user)\
            .select_related('emisor', 'emisor__perfil')\
            .order_by('-fecha_envio')


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def conteo_no_leidos(request):
    """Devuelve el total de mensajes no leídos del usuario y un desglose por sala.

    Args:
        request: Petición GET.

    Returns:
        Response: Total de no leídos y lista por sala.
    """
    usuario = request.user
    salas = SalaChat.objects.filter(miembros=usuario)

    total = 0
    por_sala = []
    for sala in salas:
        count = sala.mensajes.exclude(leido_por=usuario).exclude(emisor_id=usuario.id).count()
        if count > 0:
            por_sala.append({'sala_id': sala.id, 'count': count})
            total += count

    return Response({'total': total, 'por_sala': por_sala})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def marcar_leidos(request, sala_id):
    """Marca como leídos los mensajes de una sala y notifica por WebSocket.

    Args:
        request: Petición POST.
        sala_id (int): ID de la sala.

    Returns:
        Response: Número de mensajes marcados.
    """
    try:
        sala = SalaChat.objects.get(
            pk=sala_id,
            miembros=request.user
        )
    except SalaChat.DoesNotExist:
        return Response(
            {'error': 'Sala no encontrada o sin acceso'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Mensajes no leídos por mí en esta sala
    mensajes_nuevos = sala.mensajes.exclude(leido_por=request.user).exclude(emisor_id=request.user.id)

    ids_leidos = list(mensajes_nuevos.values_list('id', flat=True))

    if ids_leidos:
        for msg in mensajes_nuevos:
            msg.leido_por.add(request.user)

        # Notificar por WebSocket al canal de la sala
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{sala_id}',
            {
                'type': 'messages_read',
                'leidos_ids': ids_leidos,
                'leido_por': request.user.id,
            }
        )

@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def editar_mensaje(request, mensaje_id):
    try:
        mensaje = MensajeChat.objects.get(pk=mensaje_id, emisor=request.user)
        nuevo_contenido = request.data.get('contenido')
        if not nuevo_contenido:
            return Response({'error': 'Contenido vacío'}, status=status.HTTP_400_BAD_REQUEST)
        
        mensaje.contenido = nuevo_contenido
        mensaje.es_editado = True
        mensaje.fecha_edicion = timezone.now()
        mensaje.save()

        # Notificar por WebSocket
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{mensaje.sala.id}',
            {
                'type': 'message_edited',
                'mensaje_id': mensaje.id,
                'nuevo_contenido': nuevo_contenido,
            }
        )
        return Response({'mensaje': 'Editado correctamente'})
    except MensajeChat.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado o no eres el autor'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def borrar_mensaje(request, mensaje_id):
    try:
        mensaje = MensajeChat.objects.get(pk=mensaje_id)
        para_todos = request.data.get('para_todos', False)

        if para_todos:
            if mensaje.emisor != request.user:
                return Response({'error': 'No puedes borrar mensajes de otros para todos'}, status=status.HTTP_403_FORBIDDEN)
            mensaje.borrado_para_todos = True
            mensaje.contenido = "Mensaje borrado"
            mensaje.save()
            
            # Notificar por WebSocket
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'chat_{mensaje.sala.id}',
                {
                    'type': 'message_deleted',
                    'mensaje_id': mensaje.id,
                    'para_todos': True
                }
            )
        else:
            mensaje.borrado_para.add(request.user)
        
        return Response({'mensaje': 'Borrado correctamente'})
    except MensajeChat.DoesNotExist:
        return Response({'error': 'Mensaje no encontrado'}, status=status.HTTP_404_NOT_FOUND)
