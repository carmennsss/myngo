from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import Salas_chat, Mensajes_chat
from .serializers import SalaChatSerializer, MensajeChatSerializer

class SalaChatList(generics.ListAPIView):
    serializer_class = SalaChatSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        comunidad_id = self.request.query_params.get('comunidad_id')
        if comunidad_id:
            return Salas_chat.objects.filter(comunidad_id=comunidad_id)
        return Salas_chat.objects.none()

class MensajeChatList(generics.ListAPIView):
    serializer_class = MensajeChatSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        sala_id = self.request.query_params.get('sala_id')
        if sala_id:
            return Mensajes_chat.objects.filter(sala_id=sala_id).order_by('fecha_envio')
        return Mensajes_chat.objects.none()
