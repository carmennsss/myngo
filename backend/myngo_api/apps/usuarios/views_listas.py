from rest_framework import generics, permissions
from rest_framework.response import Response
from .models import Usuario, Seguimiento
from .serializers import UsuarioSerializer
from rest_framework.exceptions import PermissionDenied
from django.shortcuts import get_object_or_404

class ListaSeguidores(generics.ListAPIView):
    """Retorna la lista de usuarios que siguen a un usuario específico."""
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        usuario_id = self.kwargs.get('usuario_id')
        target_user = get_object_or_404(Usuario, id=usuario_id)
        
        # Reglas de privacidad:
        # 1. Si es tu propio perfil, puedes verlo.
        # 2. Si el perfil es público, cualquiera puede verlo.
        # 3. Si el perfil es privado, solo seguidores aceptados pueden verlo.
        
        user_request = self.request.user
        es_propio = user_request.is_authenticated and user_request.id == target_user.id
        es_publico = target_user.es_publico
        es_seguidor = False
        
        if user_request.is_authenticated and not es_propio and not es_publico:
            es_seguidor = Seguimiento.objects.filter(
                seguidor=user_request,
                seguido_usuario=target_user,
                estado='ACEPTADO'
            ).exists()
            
        if not (es_propio or es_publico or es_seguidor):
            raise PermissionDenied("Este perfil es privado. Debes seguir al usuario para ver esta lista.")

        return Usuario.objects.filter(
            siguiendo__seguido_usuario_id=usuario_id,
            siguiendo__estado='ACEPTADO'
        ).select_related('perfil').order_by('nombre_usuario')

class ListaSeguidos(generics.ListAPIView):
    """Retorna la lista de usuarios a los que sigue un usuario específico."""
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        usuario_id = self.kwargs.get('usuario_id')
        target_user = get_object_or_404(Usuario, id=usuario_id)
        
        user_request = self.request.user
        es_propio = user_request.is_authenticated and user_request.id == target_user.id
        es_publico = target_user.es_publico
        es_seguidor = False
        
        if user_request.is_authenticated and not es_propio and not es_publico:
            es_seguidor = Seguimiento.objects.filter(
                seguidor=user_request,
                seguido_usuario=target_user,
                estado='ACEPTADO'
            ).exists()
            
        if not (es_propio or es_publico or es_seguidor):
            raise PermissionDenied("Este perfil es privado. Debes seguir al usuario para ver esta lista.")

        # Filtramos solo usuarios seguidos (excluimos comunidades)
        return Usuario.objects.filter(
            seguidores__seguidor_id=usuario_id,
            seguidores__estado='ACEPTADO',
            seguidores__seguido_usuario__isnull=False
        ).select_related('perfil').order_by('nombre_usuario')
