"""Vistas de colecciones de imágenes."""

from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from comunidades.models import MiembrosComunidad

from .models import Coleccion, ImagenGaleria
from .serializers import ColeccionSerializer
from .views_galeria import PaginacionGaleria


class ColeccionViewSet(viewsets.ModelViewSet):
    """CRUD completo de colecciones, con control de permisos por rol y propiedad.

    Filtra por ``comunidad_id`` o ``usuario_id`` en los query params.
    La acción ``gestionar-imagenes`` permite añadir o quitar imágenes de una colección.
    """

    serializer_class = ColeccionSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = PaginacionGaleria

    def get_queryset(self):
        user = self.request.user
        comunidad_id = self.request.query_params.get('comunidad_id')
        usuario_id = self.request.query_params.get('usuario_id')

        if comunidad_id:
            return Coleccion.objects.filter(comunidad_id=comunidad_id)
        if usuario_id:
            if str(usuario_id) == str(user.id):
                return Coleccion.objects.filter(usuario_id=usuario_id)
            return Coleccion.objects.filter(usuario_id=usuario_id, es_privada=False)
        return Coleccion.objects.filter(usuario=user)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)

    def perform_destroy(self, instance):
        """Elimina una colección verificando que el usuario tenga permisos."""
        user = self.request.user
        if instance.comunidad:
            es_gestor = instance.comunidad.creador == user or MiembrosComunidad.objects.filter(
                usuario=user,
                comunidad=instance.comunidad,
                rol__in=['Administrador', 'Moderador'],
            ).exists()
            if not es_gestor:
                raise PermissionDenied('Solo el creador o moderadores pueden eliminar colecciones de comunidad.')
        elif instance.usuario and instance.usuario != user:
            raise PermissionDenied('Solo el propietario puede eliminar esta colección.')
        instance.delete()

    @action(detail=True, methods=['post'], url_path='gestionar_imagen')
    def gestionar_imagenes(self, request, pk=None):
        """Añade o elimina una imagen de la colección.

        Args:
            request: Petición POST con ``imagen_id`` y ``accion`` ('add'/'agregar' o 'remove'/'quitar').
            pk: ID de la colección.

        Returns:
            Response indicando el resultado de la operación.
        """
        coleccion = self.get_object()
        imagen_id = request.data.get('imagen_id')
        accion = request.data.get('accion')

        try:
            imagen = ImagenGaleria.objects.get(id=imagen_id)
        except ImagenGaleria.DoesNotExist:
            return Response({'error': 'Imagen no encontrada'}, status=404)

        if accion in ['add', 'agregar']:
            coleccion.imagenes.add(imagen)
            return Response({'status': 'Imagen añadida'})

        if accion in ['remove', 'quitar', 'remove']:
            if coleccion.comunidad:
                es_gestor = coleccion.comunidad.creador == request.user or MiembrosComunidad.objects.filter(
                    usuario=request.user,
                    comunidad=coleccion.comunidad,
                    rol__in=['Administrador', 'Moderador'],
                ).exists()
                if not es_gestor:
                    return Response({'error': 'Sin permiso para modificar esta colección'}, status=403)
            elif coleccion.usuario and coleccion.usuario != request.user:
                return Response({'error': 'Solo el propietario puede modificar esta colección'}, status=403)
            coleccion.imagenes.remove(imagen)
            return Response({'status': 'Imagen removida'})

        return Response({'error': 'Acción no válida'}, status=400)
