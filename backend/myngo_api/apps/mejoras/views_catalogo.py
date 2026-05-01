"""Vistas del catálogo de mejoras de la tienda."""

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import MiembrosComunidad
from .models import CatalogoMejoras
from .serializers import CatalogoMejorasSerializer


class CatalogoMejorasGlobales(generics.ListAPIView):
    """Lista los items del catálogo global (no asociados a una comunidad)."""

    serializer_class = CatalogoMejorasSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Obtiene solo las mejoras globales activas.

        Returns:
            QuerySet: Items del catálogo global.
        """
        return CatalogoMejoras.objects.filter(comunidad__isnull=True, esta_activo=True)


class CatalogoMejorasComunidad(generics.ListAPIView):
    """Lista los items del catálogo de una comunidad específica.

    Los moderadores pueden ver todos los items (incluyendo inactivos),
    mientras que los usuarios normales solo ven los activos.
    """

    serializer_class = CatalogoMejorasSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Filtra el catálogo de la comunidad según el rol del usuario.

        Returns:
            QuerySet: Items del catálogo de la comunidad.
        """
        comunidad_id = self.kwargs.get('comunidad_id')
        es_mod = MiembrosComunidad.objects.filter(
            usuario=self.request.user,
            comunidad_id=comunidad_id,
            rol__in=['Administrador', 'Moderador'],
        ).exists()

        if es_mod:
            return CatalogoMejoras.objects.filter(comunidad_id=comunidad_id)
        return CatalogoMejoras.objects.filter(comunidad_id=comunidad_id, esta_activo=True)


class GestionCatalogoComunidad(APIView):
    """Gestión administrativa del catálogo de una comunidad.

    Permite a los moderadores listar, activar/desactivar items y cambiar precios.
    """

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, comunidad_id):
        """Lista todos los items del catálogo de la comunidad (solo para gestores).

        Args:
            request: Petición GET.
            comunidad_id (int): ID de la comunidad.

        Returns:
            Response: Lista completa del catálogo.
        """
        es_mod = MiembrosComunidad.objects.filter(
            usuario=request.user,
            comunidad_id=comunidad_id,
            rol__in=['Administrador', 'Moderador'],
        ).exists()

        if not es_mod:
            return Response({'error': 'No tienes permisos'}, status=status.HTTP_403_FORBIDDEN)

        items = CatalogoMejoras.objects.filter(comunidad_id=comunidad_id)
        serializer = CatalogoMejorasSerializer(items, many=True)
        return Response(serializer.data)

    def patch(self, request, comunidad_id):
        """Actualiza el estado o precio de un item del catálogo.

        Args:
            request: Datos con 'item_id', 'esta_activo' y/or 'precio'.
            comunidad_id (int): ID de la comunidad.

        Returns:
            Response: Item actualizado o error de validación.
        """
        item_id = request.data.get('item_id')
        esta_activo = request.data.get('esta_activo')
        precio = request.data.get('precio')

        try:
            item = CatalogoMejoras.objects.get(pk=item_id, comunidad_id=comunidad_id)
        except CatalogoMejoras.DoesNotExist:
            return Response({'error': 'Item no encontrado'}, status=status.HTTP_404_NOT_FOUND)

        es_mod = MiembrosComunidad.objects.filter(
            usuario=request.user,
            comunidad_id=comunidad_id,
            rol__in=['Administrador', 'Moderador'],
        ).exists()

        if not es_mod:
            return Response({'error': 'No tienes permisos'}, status=status.HTTP_403_FORBIDDEN)

        if esta_activo is not None:
            item.esta_activo = esta_activo
        if precio is not None:
            if int(precio) < 100:
                return Response({'error': 'El precio mínimo es 100'}, status=status.HTTP_400_BAD_REQUEST)
            item.precio_puntos = int(precio)

        item.save()
        return Response({
            'mensaje': 'Catálogo actualizado',
            'esta_activo': item.esta_activo,
            'precio': item.precio_puntos,
        })
