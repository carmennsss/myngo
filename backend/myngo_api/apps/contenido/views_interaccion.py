"""Vistas de interacciones: likes, comentarios, posts guardados y documentos legales.

También incluye el feed principal de inicio.
"""

from django.db.models import Count, Exists, OuterRef, Q, Subquery, Value
from django.db.models.functions import Coalesce
from rest_framework import generics, pagination, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import MiembrosComunidad
from django.core.files.storage import default_storage
from notificaciones.models import Notificacion
from usuarios.models import Seguimiento

from .models import (
    Comentario, Coleccion, ImagenGaleria, MeGusta, PostGuardado,
    Publicacion, Reporte,
)
from .serializers import ComentarioSerializer, PublicacionSerializer, ReporteSerializer


class PaginacionGaleria(pagination.LimitOffsetPagination):
    """Paginación estándar para listas de contenido. Límite por defecto: 20 items."""

    default_limit = 20
    max_limit = 100


class DocumentosUtilidad(APIView):
    """Endpoint para obtener las rutas de documentos legales de Myngo almacenados en S3."""

    def get(self, request):
        """Obtiene la URL de las reglas de la comunidad.

        Args:
            request: Petición GET.

        Returns:
            Response: URL del documento PDF.
        """
        nombre_archivo = 'legal/Reglas_comunidad.pdf'
        try:
            url_s3 = default_storage.url(nombre_archivo)
            return Response({'reglas_comunidad': url_s3}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class InicioFeed(generics.ListAPIView):
    """Feed principal de publicaciones para la pantalla de inicio.

    Combina contenido de comunidades del usuario, publicaciones de perfiles seguidos
    y contenido público. Aplica anotaciones de likes y estado de interacción.
    """

    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = PaginacionGaleria

    def get_queryset(self):
        """Construye el feed personalizado según las relaciones del usuario.

        Returns:
            QuerySet: Publicaciones ordenadas por fecha de creación.
        """
        from django.db import models as db_models
        usuario = self.request.user if self.request.user.is_authenticated else None
        etiquetas = self.request.query_params.get('etiquetas')
        qs = Publicacion.objects.filter(es_valido_ia=True)

        if usuario:
            mis_comunidades_ids = MiembrosComunidad.objects.filter(usuario=usuario).values_list('comunidad_id', flat=True)
            mis_seguidos_ids = Seguimiento.objects.filter(seguidor=usuario, estado='ACEPTADO').values_list('seguido_usuario_id', flat=True)
            qs = qs.filter(
                Q(comunidad_id__in=mis_comunidades_ids)
                | Q(autor_id__in=mis_seguidos_ids)
                | Q(comunidad__es_publica=True)
                | Q(autor__perfil__es_publico=True, comunidad__isnull=True)
                | Q(autor=usuario)
            ).distinct()
            likes_sub = MeGusta.objects.filter(publicacion=OuterRef('pk')).values('publicacion').annotate(cnt=Count('id')).values('cnt')
            coments_sub = Comentario.objects.filter(publicacion=OuterRef('pk')).values('publicacion').annotate(cnt=Count('id')).values('cnt')
            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_sub, output_field=db_models.IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(coments_sub, output_field=db_models.IntegerField()), Value(0)),
                anotado_usuario_dio_like=Exists(MeGusta.objects.filter(publicacion=OuterRef('pk'), usuario=usuario)),
                anotado_usuario_guardo_post=Exists(PostGuardado.objects.filter(publicacion=OuterRef('pk'), usuario=usuario)),
            )
        else:
            qs = qs.filter(
                Q(comunidad__es_publica=True) | Q(autor__perfil__es_publico=True, comunidad__isnull=True)
            ).distinct()
            from django.db import models as db_models
            likes_sub = MeGusta.objects.filter(publicacion=OuterRef('pk')).values('publicacion').annotate(cnt=Count('id')).values('cnt')
            coments_sub = Comentario.objects.filter(publicacion=OuterRef('pk')).values('publicacion').annotate(cnt=Count('id')).values('cnt')
            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_sub, output_field=db_models.IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(coments_sub, output_field=db_models.IntegerField()), Value(0)),
            )

        qs = qs.select_related('autor', 'comunidad', 'imagen', 'autor__perfil')
        if etiquetas:
            qs = qs.filter(contenido_texto__icontains=etiquetas)
        return qs.order_by('-fecha_creacion')


class ToggleLikeView(APIView):
    """Alterna el estado de like de un usuario sobre una publicación."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        """Añade o elimina un like a la publicación.

        Args:
            request: Petición POST.
            pk (int): ID de la publicación.

        Returns:
            Response: Resultado de la operación.
        """
        try:
            publicacion = Publicacion.objects.get(pk=pk)
        except Publicacion.DoesNotExist:
            return Response({'error': 'Publicación no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        if publicacion.comunidad:
            es_miembro = MiembrosComunidad.objects.filter(
                usuario=request.user, comunidad=publicacion.comunidad
            ).exists()
            if not es_miembro:
                return Response(
                    {'error': 'Debes ser miembro de la comunidad para interactuar con este post 🐾'},
                    status=status.HTTP_403_FORBIDDEN,
                )

        like, created = MeGusta.objects.get_or_create(usuario=request.user, publicacion=publicacion)
        if not created:
            like.delete()
            return Response({'mensaje': 'Like eliminado', 'resultado': 'unliked'}, status=status.HTTP_200_OK)

        if publicacion.autor != request.user:
            Notificacion.objects.create(
                usuario=publicacion.autor,
                tipo='LIKE',
                mensaje=f'A {request.user.nombre_usuario} le ha gustado tu miau-post ✨',
                referencia_id=publicacion.id,
            )
        return Response({'mensaje': 'Like añadido', 'resultado': 'liked'}, status=status.HTTP_201_CREATED)


class ComentarioListCreate(generics.ListCreateAPIView):
    """Lista y crea comentarios sobre una publicación específica.

    Solo los miembros pueden comentar en publicaciones de comunidades.
    """

    serializer_class = ComentarioSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        """Lista los comentarios de la publicación ordenados cronológicamente.

        Returns:
            QuerySet: Comentarios de la publicación.
        """
        publicacion_id = self.kwargs.get('pk')
        return Comentario.objects.filter(publicacion_id=publicacion_id).order_by('fecha_creacion')

    def perform_create(self, serializer):
        """Crea un nuevo comentario tras validar membresía si aplica.

        Args:
            serializer: Serializador con el contenido del comentario.
        """
        try:
            publicacion = Publicacion.objects.get(pk=self.kwargs.get('pk'))
        except Publicacion.DoesNotExist:
            raise serializers.ValidationError({'error': 'La publicación no existe'})

        if publicacion.comunidad:
            es_miembro = MiembrosComunidad.objects.filter(
                usuario=self.request.user, comunidad=publicacion.comunidad
            ).exists()
            if not es_miembro:
                raise permissions.PermissionDenied('Debes ser miembro de la comunidad para comentar 🐾')

        serializer.save(autor=self.request.user, publicacion=publicacion)
        if publicacion.autor != self.request.user:
            Notificacion.objects.create(
                usuario=publicacion.autor,
                tipo='COMENTARIO',
                mensaje=f'{self.request.user.nombre_usuario} ha comentado tu miau-post 🐾',
                referencia_id=publicacion.id,
            )


class TogglePostGuardadoView(APIView):
    """Alterna el estado de guardado de una publicación en el perfil del usuario."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        """Guarda o elimina la publicación de la lista de guardados del usuario.

        Args:
            request: Petición POST.
            pk (int): ID de la publicación.

        Returns:
            Response: Resultado de la operación.
        """
        try:
            publicacion = Publicacion.objects.get(pk=pk)
        except Publicacion.DoesNotExist:
            return Response({'error': 'Publicación no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        guardado, created = PostGuardado.objects.get_or_create(usuario=request.user, publicacion=publicacion)
        if not created:
            guardado.delete()
            return Response({'mensaje': 'Post eliminado de guardados', 'resultado': 'removed'}, status=status.HTTP_200_OK)
        return Response({'mensaje': 'Post guardado en tu perfil', 'resultado': 'added'}, status=status.HTTP_201_CREATED)
