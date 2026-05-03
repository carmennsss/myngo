"""Vistas para la compra y equipación de mejoras por parte de los usuarios."""

from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from usuarios.models import Perfil
from .models import CatalogoMejoras, MejoraUsuario
from .serializers import MejorasUsuarioSerializer


class ComprarMejoraView(APIView):
    """Permite a un usuario adquirir un item del catálogo usando sus puntos.

    Verifica que el usuario tenga puntos suficientes y que no posea ya el item.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        """Procesa la compra de una mejora.

        Args:
            request: Petición POST.
            pk (int): ID de la mejora en el catálogo.

        Returns:
            Response: Resultado de la compra y puntos restantes.
        """
        try:
            mejora = CatalogoMejoras.objects.get(pk=pk)
        except CatalogoMejoras.DoesNotExist:
            return Response({'error': 'Mejora no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        perfil = request.user.perfil
        if perfil.puntos < mejora.precio_puntos:
            return Response({'error': 'No tienes suficientes puntos'}, status=status.HTTP_400_BAD_REQUEST)

        if MejoraUsuario.objects.filter(usuario=request.user, mejora=mejora).exists():
            return Response({'error': 'Ya posees esta mejora'}, status=status.HTTP_400_BAD_REQUEST)

        perfil.puntos -= mejora.precio_puntos
        perfil.save()

        MejoraUsuario.objects.create(usuario=request.user, mejora=mejora)

        return Response({
            'mensaje': 'Compra realizada con éxito',
            'puntos_restantes': perfil.puntos
        })


class MisMejorasView(APIView):
    """Lista todas las mejoras adquiridas por el usuario autenticado."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Retorna la colección de mejoras del usuario.

        Args:
            request: Petición GET.

        Returns:
            Response: Lista de mejoras serializadas.
        """
        mejoras_usuario = MejoraUsuario.objects.filter(usuario=request.user)
        serializer = MejorasUsuarioSerializer(mejoras_usuario, many=True)
        return Response(serializer.data)


class EquipacionMejorasGlobales(APIView):
    """Gestiona la equipación de mejoras (avatar, fondo, marco, estilo post) en el perfil.

    Al equipar una mejora, se desequipa automáticamente cualquier otra del mismo tipo.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Equipa o desequipa una mejora específica.

        Args:
            request: Datos con 'mejora_id'.

        Returns:
            Response: Confirmación del cambio de estado.
        """
        user = request.user
        mejora_id = request.data.get('mejora_id')

        if mejora_id is None:
            return Response({'error': 'mejora_id es requerido'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            mejora_u = MejoraUsuario.objects.get(mejora_id=mejora_id, usuario=user)
            mejora_u.esta_equipada = not mejora_u.esta_equipada

            if mejora_u.esta_equipada:
                MejoraUsuario.objects.filter(
                    usuario=user,
                    esta_equipada=True,
                    mejora__tipo=mejora_u.mejora.tipo
                ).exclude(pk=mejora_u.pk).update(esta_equipada=False)

            mejora_u.save()

            perfil = Perfil.objects.get(usuario=user)
            tipo = mejora_u.mejora.tipo.casefold()

            if tipo == "avatar":
                perfil.avatar = mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
            elif tipo == "fondo":
                destino = request.data.get('destino', 'banner')
                if destino == 'fondo_feed':
                    perfil.fondo_perfil = mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
                else:
                    perfil.fondo = mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
            elif tipo == "marco":
                perfil.marco = mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
            elif tipo in ["estilo_post", "estilo post"]:
                perfil.estilo_post = mejora_u.mejora.datos_extra if mejora_u.esta_equipada else None

            perfil.save()

            mensaje = "La mejora se ha equipado" if mejora_u.esta_equipada else "La mejora se ha desequipado"
            return Response({'resultado': mensaje}, status=status.HTTP_200_OK)

        except MejoraUsuario.DoesNotExist:
            return Response({'error': 'Mejora no encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except Perfil.DoesNotExist:
            return Response({'error': 'Perfil no encontrado'}, status=status.HTTP_404_NOT_FOUND)
