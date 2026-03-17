from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .models import Notificacion
from .serializers import NotificacionSerializer
from comunidades.models import Miembros_comunidades

class NotificacionList(generics.ListAPIView):
    """
    Lista las notificaciones del usuario autenticado.
    """
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notificacion.objects.filter(usuario=self.request.user).order_by('-fecha_notificacion')

class ResponderSolicitudUnion(APIView):
    """
    Acepta o rechaza una solicitud de unión a comunidad.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            notificacion = Notificacion.objects.get(pk=pk, usuario=request.user)
            peticion = Miembros_comunidades.objects.get(pk=notificacion.referencia_id)
        except (Notificacion.DoesNotExist, Miembros_comunidades.DoesNotExist):
            return Response({"error": "Petición no encontrada"}, status=status.HTTP_404_NOT_FOUND)

        accion = request.data.get("accion") # "ACEPTAR" o "RECHAZAR"
        
        if accion == "ACEPTAR":
            peticion.estado_peticion = "ACEPTADO"
            peticion.save()
            mensaje_notif = f"¡Miau! Tu solicitud para unirte a '{peticion.comunidad.nombre}' ha sido aceptada. ✨"
        elif accion == "RECHAZAR":
            peticion.delete()
            mensaje_notif = f"Lo sentimos, tu solicitud para unirte a '{peticion.comunidad.nombre}' ha sido rechazada. 🐾"
        else:
            return Response({"error": "Acción no válida"}, status=status.HTTP_400_BAD_REQUEST)

        # Notificar al usuario solicitante
        Notificacion.objects.create(
            usuario=peticion.usuario,
            tipo="RESPUESTA_PETICION",
            mensaje=mensaje_notif,
            referencia_comunidad=peticion.comunidad
        )

        # Marcar notificación original como leída
        notificacion.leida = True
        notificacion.save()

        return Response({"mensaje": f"Solicitud {accion.lower()}da correctamente"})


class NotificacionesNoLeidasCount(APIView):
    """
    Devuelve el número de notificaciones no leídas del usuario autenticado.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = Notificacion.objects.filter(usuario=request.user, leida=False).count()
        return Response({"count": count})


class MarcarTodasLeidas(APIView):
    """
    Marca todas las notificaciones no leídas del usuario como leídas.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        actualizadas = Notificacion.objects.filter(
            usuario=request.user, 
            leida=False
        ).exclude(tipo='PETICION_UNION').update(leida=True)
        return Response({"actualizadas": actualizadas})
