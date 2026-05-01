"""Vistas de moderación: reportes, resolución y comentarios eliminados por admins."""

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import MiembrosComunidad
from notificaciones.models import Notificacion

from .models import Comentario, Reporte
from .serializers import ComentarioSerializer, ReporteSerializer


class ReporteListCreate(generics.ListCreateAPIView):
    """Lista todos los reportes o crea uno nuevo.

    Al crear, notifica a los moderadores de la comunidad afectada.
    """

    queryset = Reporte.objects.all()
    serializer_class = ReporteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        reporte = serializer.save(informador=self.request.user)
        if reporte.comunidad:
            mods = MiembrosComunidad.objects.filter(
                comunidad=reporte.comunidad, rol__in=['Administrador', 'Moderador']
            )
            for mod in mods:
                if mod.usuario != self.request.user:
                    Notificacion.objects.create(
                        usuario=mod.usuario,
                        tipo='NUEVO_REPORTE',
                        mensaje=f"¡Atención! Hay un nuevo reporte de {reporte.tipo_objeto} en '{reporte.comunidad.nombre}'.",
                        referencia_comunidad=reporte.comunidad,
                        referencia_id=reporte.id,
                    )


class ComentarioDetail(generics.RetrieveUpdateDestroyAPIView):
    """Recupera, actualiza o elimina un comentario específico.

    Al eliminar como administrador, notifica al autor del comentario.
    """

    queryset = Comentario.objects.all()
    serializer_class = ComentarioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        if instance.autor != request.user:
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo='COMENTARIO_BORRADO',
                mensaje=f'Tu comentario ha sido borrado por un administrador. Motivo: {razon}',
                referencia_comunidad=instance.publicacion.comunidad,
            )
        Reporte.objects.filter(
            tipo_objeto='COMENTARIO', objeto_id=instance.id, estado='PENDIENTE'
        ).update(estado='RESUELTO')
        instance.delete()
        return Response({'mensaje': 'Comentario eliminado'}, status=status.HTTP_200_OK)


class ResolverReporteView(APIView):
    """Permite a moderadores o al creador de la comunidad resolver o desestimar un reporte."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            reporte = Reporte.objects.get(pk=pk)
        except Reporte.DoesNotExist:
            return Response({'error': 'Reporte no encontrado'}, status=404)

        if reporte.comunidad:
            es_gestor = reporte.comunidad.creador == request.user or MiembrosComunidad.objects.filter(
                usuario=request.user,
                comunidad=reporte.comunidad,
                rol__in=['Administrador', 'Moderador'],
            ).exists()
            if not es_gestor:
                return Response({'error': 'No tienes permiso para resolver este reporte'}, status=403)

        nuevo_estado = request.data.get('estado')
        if nuevo_estado not in ['RESUELTO', 'DESESTIMADO']:
            return Response({'error': 'Estado no válido'}, status=400)

        reporte.estado = nuevo_estado
        reporte.save()
        return Response({'mensaje': f'Reporte marcado como {nuevo_estado}'}, status=200)
