from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.db.models import Q
from .models import Salas_chat, Mensajes_chat
from .serializers import SalaChatSerializer, MensajeChatSerializer
from usuarios.models import Usuario
import uuid

class SalaChatListCreate(generics.ListCreateAPIView):
    serializer_class = SalaChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Salas_chat.objects.filter(
            Q(miembros=self.request.user) | Q(es_publica=True)
        ).distinct().order_by('-fecha_creacion')

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
                    return Response(SalaChatSerializer(sala_existente).data, status=status.HTTP_200_OK)
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

        return Response(SalaChatSerializer(sala).data, status=status.HTTP_201_CREATED)


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
