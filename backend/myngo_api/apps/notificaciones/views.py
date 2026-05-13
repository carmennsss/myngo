# /**
#  * @author Carmen Tamayo Doña
#  * @author Ainhoa Gomez Toro
#  * @version 1.0
#  * @date 2026-05-14
#  */
"""Vistas para el sistema de notificaciones de Myngo.

Incluye el listado de notificaciones, el conteo de no leídas,
el marcado masivo o individual de lectura, y la gestión de respuestas
a solicitudes de unión o seguimiento.
"""

from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import MiembrosComunidad
from usuarios.models import Seguimiento
from .models import Notificacion
from .serializers import NotificacionSerializer


class NotificacionList(generics.ListAPIView):
    """Lista todas las notificaciones del usuario autenticado en orden cronológico inverso."""

    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Obtiene las notificaciones del usuario actual.

        Returns:
            QuerySet: Notificaciones ordenadas por fecha.
        """
        return Notificacion.objects.filter(usuario=self.request.user).order_by('-fecha_notificacion')


class ResponderSolicitudUnion(APIView):
    """Acepta o rechaza una solicitud de unión a comunidad o seguimiento de perfil privado.

    Tras la respuesta, crea los registros correspondientes (MiembrosComunidad o actualización
    de Seguimiento) y envía una notificación de respuesta al solicitante.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Procesa la respuesta (ACEPTAR/RECHAZAR) a una notificación de solicitud.

        Args:
            request: Datos con 'accion' ('ACEPTAR'/'RECHAZAR').
            pk (int): ID de la notificación.

        Returns:
            Response: Resultado de la operación.
        """
        try:
            notificacion = Notificacion.objects.get(pk=pk, usuario=request.user)
        except Notificacion.DoesNotExist:
            return Response({'error': 'Notificación no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        accion = request.data.get("accion")  # "ACEPTAR" o "RECHAZAR"

        if notificacion.referencia_comunidad:
            try:
                peticion = Seguimiento.objects.get(pk=notificacion.referencia_id)
            except Seguimiento.DoesNotExist:
                return Response({'error': 'Petición no encontrada'}, status=status.HTTP_404_NOT_FOUND)

            if accion == "ACEPTAR":
                peticion.estado = "ACEPTADO"
                peticion.save()
                MiembrosComunidad.objects.get_or_create(
                    usuario=peticion.seguidor,
                    comunidad=peticion.seguida_comunidad
                )
                mensaje_notif = (
                    f"¡Miau! Tu solicitud para unirte a "
                    f"'{peticion.seguida_comunidad.nombre}' ha sido aceptada. ✨"
                )
            elif accion == "RECHAZAR":
                peticion.estado = "DENEGADO"
                peticion.save()
                mensaje_notif = (
                    f"Lo sentimos, tu solicitud para unirte a "
                    f"'{peticion.seguida_comunidad.nombre}' ha sido rechazada. 🐾"
                )
            else:
                return Response({'error': 'Acción no válida'}, status=status.HTTP_400_BAD_REQUEST)

            Notificacion.objects.create(
                usuario=peticion.seguidor,
                tipo="RESPUESTA_PETICION",
                mensaje=mensaje_notif,
                referencia_comunidad=peticion.seguida_comunidad
            )

        elif notificacion.referencia_usuario:
            try:
                seguimiento = Seguimiento.objects.get(pk=notificacion.referencia_id)
            except Seguimiento.DoesNotExist:
                return Response({'error': 'Seguimiento no encontrado'}, status=status.HTTP_404_NOT_FOUND)

            if accion == "ACEPTAR":
                seguimiento.estado = "ACEPTADO"
                seguimiento.save()
                mensaje_notif = (
                    f"¡Miau! {request.user.nombre_usuario} ha aceptado "
                    f"tu solicitud de seguimiento. ✨"
                )
            elif accion == "RECHAZAR":
                seguimiento.estado = "DENEGADO"
                seguimiento.save()
                mensaje_notif = (
                    f"{request.user.nombre_usuario} ha rechazado "
                    f"tu solicitud de seguimiento. 🐾"
                )
            else:
                return Response({'error': 'Acción no válida'}, status=status.HTTP_400_BAD_REQUEST)

            Notificacion.objects.create(
                usuario=seguimiento.seguidor,
                tipo="RESPUESTA_PETICION",
                mensaje=mensaje_notif,
                referencia_usuario=request.user
            )
        else:
            return Response({'error': 'Petición inválida'}, status=status.HTTP_400_BAD_REQUEST)

        notificacion.leida = True
        notificacion.save()

        return Response({'mensaje': f"Solicitud {accion.lower()}da correctamente"})


class NotificacionesNoLeidasCount(APIView):
    """Devuelve el número total de notificaciones pendientes de leer del usuario."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Retorna el conteo de notificaciones no leídas.

        Args:
            request: Petición GET.

        Returns:
            Response: Objeto con el campo 'count'.
        """
        count = Notificacion.objects.filter(usuario=request.user, leida=False).count()
        return Response({'count': count})


class MarcarTodasLeidas(APIView):
    """Marca masivamente todas las notificaciones del usuario como leídas."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Actualiza todas las notificaciones pendientes a leídas.

        Args:
            request: Petición POST.

        Returns:
            Response: Número de notificaciones actualizadas.
        """
        actualizadas = Notificacion.objects.filter(
            usuario=request.user,
            leida=False
        ).update(leida=True)
        return Response({'actualizadas': actualizadas})


class MarcarNotificacionLeida(APIView):
    """Marca una notificación específica como leída por su ID."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Marca una única notificación como leída.

        Args:
            request: Petición POST.
            pk (int): ID de la notificación.

        Returns:
            Response: Confirmación del cambio.
        """
        try:
            notificacion = Notificacion.objects.get(pk=pk, usuario=request.user)
            notificacion.leida = True
            notificacion.save()
            return Response({'mensaje': 'Notificación marcada como leída'})
        except Notificacion.DoesNotExist:
            return Response({'error': 'Notificación no encontrada'}, status=status.HTTP_404_NOT_FOUND)
