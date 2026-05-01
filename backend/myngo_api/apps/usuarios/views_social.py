"""Vistas de gestión de seguimiento y relaciones sociales entre usuarios."""

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from notificaciones.models import Notificacion

from .models import Perfil, Seguimiento, Usuario
from .serializers import SeguimientoSerializer


class SeguimientoUsuarios(APIView):
    """Crea o actualiza relaciones de seguimiento entre usuarios."""

    def post(self, request):
        """Crea un nuevo seguimiento.

        Args:
            request: Petición POST con los datos del seguimiento.

        Returns:
            Response: Datos creados o errores de validación.
        """
        serializer = SeguimientoSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {'exito': True, 'mensaje': 'Seguimiento creado', 'datos': serializer.data},
                status=status.HTTP_201_CREATED,
            )
        return Response({'exito': False, 'errores': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request):
        """Actualiza el estado de un seguimiento existente (ACEPTADO o DENEGADO).

        Args:
            request: Petición PUT con ``id`` y ``estado``.

        Returns:
            Response: Datos actualizados o error descriptivo.
        """
        seguimiento_id = request.data.get('id')
        estado = request.data.get('estado', '')
        try:
            seguimiento = Seguimiento.objects.get(id=seguimiento_id)
            if estado.upper() not in ['ACEPTADO', 'DENEGADO']:
                return Response(
                    {'exito': False, 'mensaje': f"¡Error! La cadena '{estado}' no es una opcion valida'"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            serializer = SeguimientoSerializer(seguimiento, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({'exito': True, 'mensaje': 'Seguimiento actualizado en estado', 'datos': serializer.data})
            return Response({'exito': False, 'errores': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Seguimiento.DoesNotExist:
            return Response(
                {'exito': False, 'errores': 'No existe un seguimiento con el ID proporcionado.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response({'exito': False, 'errores': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class SeguirPerfil(APIView):
    """Gestiona la acción de seguir o dejar de seguir un perfil de usuario.

    Permite seguimiento directo en perfiles públicos o envío de solicitud
    en perfiles privados. Si ya existe seguimiento, lo elimina (unfollow).
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request, nombre_usuario):
        """Crea una relación de seguimiento o envía una solicitud según la privacidad.

        Si ya existe una relación, se procede a eliminarla (dejar de seguir).

        Args:
            request: Petición POST.
            nombre_usuario (str): Nombre de usuario del perfil objetivo.

        Returns:
            Response: Mensaje descriptivo de la acción realizada y el nuevo estado.
        """
        if request.user and request.user.is_authenticated:
            usuario = request.user
        else:
            usuario = Usuario.objects.filter(pk=1).first() or Usuario.objects.first()

        try:
            perfil = Perfil.objects.get(usuario__nombre_usuario=nombre_usuario)
        except Perfil.DoesNotExist:
            return Response({'error': 'El perfil no existe'}, status=status.HTTP_404_NOT_FOUND)

        if perfil.usuario == usuario:
            return Response({'error': 'No puedes seguirte a ti mismo'}, status=status.HTTP_400_BAD_REQUEST)

        seguimiento = Seguimiento.objects.filter(seguidor=usuario, seguido_usuario=perfil.usuario).first()
        if seguimiento:
            if seguimiento.estado == 'SOLICITUD':
                return Response({'mensaje': 'Ya has mandado una solicitud a este usuario'}, status=status.HTTP_200_OK)
            elif seguimiento.estado == 'DENEGADO':
                seguimiento.estado = 'SOLICITUD'
                seguimiento.save()
                return Response({'mensaje': 'Solicitud reintentada', 'estado': seguimiento.estado}, status=status.HTTP_200_OK)
            else:
                seguimiento.delete()
                return Response({'mensaje': 'Has dejado de seguir a este usuario', 'estado': None}, status=status.HTTP_200_OK)

        estado = 'ACEPTADO' if perfil.es_publico else 'SOLICITUD'
        seguimiento = Seguimiento.objects.create(
            seguidor=usuario, seguido_usuario=perfil.usuario, estado=estado
        )
        if not perfil.es_publico and seguimiento.estado == 'SOLICITUD':
            Notificacion.objects.create(
                usuario=perfil.usuario,
                tipo='PETICION_SEGUIMIENTO',
                mensaje=f'¡Miau! {usuario.nombre_usuario} quiere seguirte.',
                referencia_usuario=usuario,
                referencia_id=seguimiento.id,
            )
        mensaje = 'Has seguido a este perfil' if perfil.es_publico else 'Solicitud enviada al perfil'
        return Response({'mensaje': mensaje, 'estado': seguimiento.estado}, status=status.HTTP_201_CREATED)


class ResponderPeticionUnion(APIView):
    """Permite al usuario receptor aceptar o rechazar una solicitud de seguimiento."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Acepta o rechaza una petición de seguimiento por su ID.

        Args:
            request: Petición POST con el booleano ``aceptar``.
            pk (int): ID de la instancia de Seguimiento (petición).

        Returns:
            Response: Confirmación de la respuesta enviada.
        """
        try:
            peticion = Seguimiento.objects.get(pk=pk)
        except Seguimiento.DoesNotExist:
            return Response({'error': 'La petición no existe'}, status=status.HTTP_404_NOT_FOUND)

        if peticion.seguido_usuario != request.user:
            return Response({'error': 'No tienes permiso'}, status=status.HTTP_403_FORBIDDEN)

        aceptar = request.data.get('aceptar', False)
        if aceptar:
            peticion.estado = 'ACEPTADO'
            peticion.save()
            Notificacion.objects.create(
                usuario=peticion.seguidor,
                tipo='PETICION_ACEPTADA',
                mensaje=f"¡Miau! El usuario '{peticion.seguido_usuario.nombre_usuario}' ha aceptado la solicitud de amistad.",
                referencia_usuario=peticion.seguido_usuario,
            )
        else:
            peticion.estado = 'DENEGADO'
            peticion.save()

        Notificacion.objects.filter(
            usuario=request.user, tipo='PETICION_UNION', referencia_id=peticion.id
        ).update(leida=True)
        return Response({'mensaje': 'Respuesta enviada'}, status=status.HTTP_200_OK)
