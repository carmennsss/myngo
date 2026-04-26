from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.db.models import Q, Count
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Salas_chat, Mensajes_chat
from .serializers import SalaChatSerializer, MensajeChatSerializer
from usuarios.models import Usuario
import uuid


class SalaChatListCreate(generics.ListCreateAPIView):
    serializer_class = SalaChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        from django.db.models import Max, OuterRef, Subquery, Count
        
        # Subconsulta para contar mensajes no leídos de otros para esta sala
        no_leidos_subquery = Mensajes_chat.objects.filter(
            sala=OuterRef('pk'),
            leido=False
        ).exclude(emisor=self.request.user).values('sala').annotate(cnt=Count('id')).values('cnt')

        return Salas_chat.objects.filter(
            Q(miembros=self.request.user) | Q(es_publica=True)
        ).distinct().annotate(
            fecha_ultimo_mensaje=Max('mensajes__fecha_envio'),
            count_no_leidos=Subquery(no_leidos_subquery)
        ).prefetch_related(
            'miembros',
            'miembros__perfil'
        ).order_by('-fecha_ultimo_mensaje', '-fecha_creacion')

    def create(self, request, *args, **kwargs):
        nombre = request.data.get('nombre', f'Sala_{request.user.nombre_usuario}')
        es_grupal = request.data.get('es_grupal', False)
        otro_usuario_id = request.data.get('otro_usuario_id')

        # Si es privada y ya existe una sala entre estos dos usuarios, devolver la existente
        if not es_grupal and otro_usuario_id:
            try:
                otro = Usuario.objects.get(pk=otro_usuario_id)
                sala_existente = Salas_chat.objects.filter(
                    es_grupal=False,
                    miembros=request.user
                ).filter(miembros=otro).first()

                if sala_existente:
                    return Response(
                        SalaChatSerializer(sala_existente, context={'request': request}).data,
                        status=status.HTTP_200_OK
                    )
            except Usuario.DoesNotExist:
                pass

        # Crear nueva sala
        sala = Salas_chat.objects.create(
            nombre=nombre,
            es_grupal=es_grupal,
            invite_token=str(uuid.uuid4()),
        )
        sala.miembros.add(request.user)

        if otro_usuario_id:
            try:
                sala.miembros.add(Usuario.objects.get(pk=otro_usuario_id))
            except Usuario.DoesNotExist:
                pass

        return Response(
            SalaChatSerializer(sala, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def agregar_miembro(request, pk):
    try:
        sala = Salas_chat.objects.get(pk=pk)
        user_id = request.data.get('user_id')
        usuario_a_agregar = Usuario.objects.get(pk=user_id)

        if not sala.miembros.filter(id=request.user.id).exists():
            return Response({"error": "No tienes permiso para añadir miembros"}, status=status.HTTP_403_FORBIDDEN)

        sala.miembros.add(usuario_a_agregar)
        return Response({"mensaje": f"Usuario {usuario_a_agregar.nombre_usuario} añadido correctamente"})
    except Salas_chat.DoesNotExist:
        return Response({"error": "Sala no encontrada"}, status=status.HTTP_404_NOT_FOUND)
    except Usuario.DoesNotExist:
        return Response({"error": "Usuario no encontrado"}, status=status.HTTP_404_NOT_FOUND)


class MensajesChatList(generics.ListAPIView):
    serializer_class = MensajeChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        sala_id = self.kwargs.get('sala_id')
        if not Salas_chat.objects.filter(
            Q(id=sala_id, miembros=self.request.user) | Q(id=sala_id, es_publica=True)
        ).exists():
            return Mensajes_chat.objects.none()
        return Mensajes_chat.objects.filter(sala_id=sala_id).order_by('-fecha_envio')[:50]


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def conteo_no_leidos(request):
    """
    Devuelve el total de mensajes no leídos del usuario autenticado
    y un desglose por sala.
    """
    usuario = request.user
    # Salas donde el usuario es miembro
    salas = Salas_chat.objects.filter(miembros=usuario)

    total = 0
    por_sala = []
    for sala in salas:
        count = sala.mensajes.filter(leido=False).exclude(emisor=usuario).count()
        if count > 0:
            por_sala.append({'sala_id': sala.id, 'count': count})
            total += count

    return Response({'total': total, 'por_sala': por_sala})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def marcar_leidos(request, sala_id):
    """
    Marca como leídos todos los mensajes de la sala enviados por otros usuarios.
    Luego notifica por WebSocket a los emisores afectados.
    """
    try:
        sala = Salas_chat.objects.get(
            pk=sala_id,
            miembros=request.user
        )
    except Salas_chat.DoesNotExist:
        return Response({"error": "Sala no encontrada o sin acceso"}, status=status.HTTP_404_NOT_FOUND)

    # Mensajes no leídos de otros en esta sala
    mensajes_nuevos = sala.mensajes.filter(leido=False).exclude(emisor=request.user)
    ids_leidos = list(mensajes_nuevos.values_list('id', flat=True))

    if ids_leidos:
        mensajes_nuevos.update(leido=True)

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

    return Response({'marcados': len(ids_leidos)})
