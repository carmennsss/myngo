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

    Los fondos tienen dos ranuras independientes: 'banner' y 'fondo_feed'.
    El resto de tipos solo permiten una mejora equipada a la vez.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Equipa o desequipa una mejora específica.

        Args:
            request: Datos con 'mejora_id' y opcionalmente 'destino' ('banner' o 'fondo_feed').

        Returns:
            Response: Confirmación del cambio de estado.
        """
        from django.db import models as dj_models

        user = request.user
        mejora_id = request.data.get('mejora_id')
        destino = request.data.get('destino', 'banner')  # 'banner' o 'fondo_feed'

        if mejora_id is None:
            return Response({'error': 'mejora_id es requerido'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            mejora_u = MejoraUsuario.objects.get(mejora_id=mejora_id, usuario=user)
            perfil = Perfil.objects.get(usuario=user)
            tipo = mejora_u.mejora.tipo.casefold()

            mejora_u.esta_equipada = not mejora_u.esta_equipada
            va_a_equipar = mejora_u.esta_equipada

            if va_a_equipar:
                if tipo == 'fondo':
                    if destino == 'fondo_feed':
                        # El fondo del feed va a la ranura 'fondo_perfil' (según feedback usuario)
                        MejoraUsuario.objects.filter(
                            usuario=user,
                            esta_equipada=True,
                            mejora__tipo=mejora_u.mejora.tipo,
                        ).filter(
                            dj_models.Q(mejora__url_recurso=perfil.fondo_perfil)
                        ).exclude(pk=mejora_u.pk).update(esta_equipada=False)
                        perfil.fondo_perfil = mejora_u.mejora.url_recurso.name
                    else:
                        # El banner va a la ranura 'fondo'
                        MejoraUsuario.objects.filter(
                            usuario=user,
                            esta_equipada=True,
                            mejora__tipo=mejora_u.mejora.tipo,
                        ).filter(
                            dj_models.Q(mejora__url_recurso=perfil.fondo)
                        ).exclude(pk=mejora_u.pk).update(esta_equipada=False)
                        perfil.fondo = mejora_u.mejora.url_recurso.name
                else:
                    MejoraUsuario.objects.filter(
                        usuario=user,
                        esta_equipada=True,
                        mejora__tipo=mejora_u.mejora.tipo,
                    ).exclude(pk=mejora_u.pk).update(esta_equipada=False)

                    if tipo == 'avatar':
                        perfil.avatar = mejora_u.mejora.url_recurso.name
                    elif tipo == 'marco':
                        perfil.marco = mejora_u.mejora.url_recurso.name
                    elif tipo in ['estilo_post', 'estilo post']:
                        perfil.estilo_post = mejora_u.mejora.datos_extra
            else:
                if tipo == 'fondo':
                    nombre_recurso = mejora_u.mejora.url_recurso.name
                    # Limpiamos ambos campos si coinciden para evitar inconsistencias
                    if perfil.fondo == nombre_recurso:
                        perfil.fondo = None
                    if perfil.fondo_perfil == nombre_recurso:
                        perfil.fondo_perfil = None
                elif tipo == 'avatar':
                    perfil.avatar = None
                elif tipo == 'marco':
                    perfil.marco = None
                elif tipo in ['estilo_post', 'estilo post']:
                    perfil.estilo_post = None

            mejora_u.save()
            perfil.save()

            mensaje = 'La mejora se ha equipado' if va_a_equipar else 'La mejora se ha desequipado'
            return Response({'resultado': mensaje}, status=status.HTTP_200_OK)

        except MejoraUsuario.DoesNotExist:
            return Response({'error': 'Mejora no encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except Perfil.DoesNotExist:
            return Response({'error': 'Perfil no encontrado'}, status=status.HTTP_404_NOT_FOUND)

class EquipacionMejoraComunidad(APIView):
    """Permite a los administradores y creadores equipar mejoras a la comunidad.

    Las mejoras de la comunidad (avatar, marco, fondo) son visibles para todos los visitantes.
    Solo el creador o miembros con rol 'Administrador' pueden aplicar estos cambios.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Aplica una mejora del catálogo a la comunidad.

        Args:
            request: Datos con 'mejora_id' y 'comunidad_id'.

        Returns:
            Response: Confirmación del cambio.
        """
        from comunidades.models import Comunidad, MiembrosComunidad

        mejora_id = request.data.get('mejora_id')
        comunidad_id = request.data.get('comunidad_id')

        if not mejora_id or not comunidad_id:
            return Response(
                {'error': 'mejora_id y comunidad_id son requeridos'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            comunidad = Comunidad.objects.get(pk=comunidad_id)
            mejora = CatalogoMejoras.objects.get(pk=mejora_id)
            
            es_creador = comunidad.creador == request.user
            es_admin = MiembrosComunidad.objects.filter(
                usuario=request.user,
                comunidad=comunidad,
                rol='Administrador'
            ).exists()

            if not es_creador and not es_admin:
                return Response(
                    {'error': 'Solo el creador o administradores pueden equipar mejoras a la comunidad.'},
                    status=status.HTTP_403_FORBIDDEN
                )

            tipo = mejora.tipo.casefold()
            
            if tipo == 'avatar':
                comunidad.url_avatar = mejora.url_recurso
            elif tipo == 'marco':
                comunidad.url_marco = mejora.url_recurso
            elif tipo == 'fondo':
                comunidad.url_fondo = mejora.url_recurso
            else:
                return Response({'error': f'Tipo de mejora {tipo} no aplicable a comunidad'}, status=status.HTTP_400_BAD_REQUEST)

            comunidad.save()
            return Response({'mensaje': f'Se ha equipado el {tipo} a la comunidad {comunidad.nombre}'})

        except Comunidad.DoesNotExist:
            return Response({'error': 'Comunidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except CatalogoMejoras.DoesNotExist:
            return Response({'error': 'Mejora no encontrada'}, status=status.HTTP_404_NOT_FOUND)
