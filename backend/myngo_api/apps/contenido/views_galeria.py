"""Vistas de galería de imágenes y colecciones."""

from django.db.models import Count, Exists, OuterRef, Q, Subquery, Value, IntegerField
from django.db.models.functions import Coalesce
from rest_framework import generics, pagination, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import Comunidad, MiembrosComunidad
from notificaciones.models import Notificacion
from usuarios.models import Seguimiento

from .models import Coleccion, Comentario, ImagenGaleria, MeGusta, PostGuardado, Publicacion, Reporte
from .permissions import IsAuthorOrAdmin
from .serializers import ColeccionSerializer, ImagenGaleriaSerializer, PublicacionSerializer


class PaginacionGaleria(pagination.LimitOffsetPagination):
    """Paginación estándar para listas de contenido. Límite por defecto: 20 items."""

    default_limit = 20
    max_limit = 100


class GaleriaList(generics.ListCreateAPIView):
    """Lista imágenes de la galería filtrando por comunidad, usuario o colección.

    Aplica controles de privacidad según el tipo de galería consultada.
    """

    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = PaginacionGaleria

    def get_queryset(self):
        """Filtra el conjunto de imágenes según el contexto (comunidad, usuario, colección).
        
        Aplica validaciones de privacidad y asegura que en galerías públicas solo se
        muestren imágenes asociadas a publicaciones (evitando fotos de chats).
        """
        try:
            comunidad_id = self.request.query_params.get('comunidad_id')
            propietario_id = self.request.query_params.get('usuario_id')
            coleccion_id = self.request.query_params.get('coleccion_id')
            
            qs = ImagenGaleria.objects.exclude(url_s3__icontains='chat/contenido')

            if coleccion_id:
                try:
                    coleccion = Coleccion.objects.get(id=coleccion_id)
                    if coleccion.es_privada and coleccion.usuario != self.request.user:
                        return ImagenGaleria.objects.none()
                    qs = coleccion.imagenes.all()
                except (Coleccion.DoesNotExist, ValueError, TypeError):
                    return ImagenGaleria.objects.none()

            elif comunidad_id:
                try:
                    comunidad = Comunidad.objects.get(id=comunidad_id)
                    if not comunidad.es_publica:
                        es_miembro = MiembrosComunidad.objects.filter(
                            comunidad=comunidad, usuario=self.request.user
                        ).exists()
                        if not es_miembro and comunidad.creador != self.request.user:
                            return ImagenGaleria.objects.none()
                    
                    # Mostramos imágenes que pertenecen a posts de esta comunidad
                    # o que fueron subidas directamente a la comunidad (raw/crudas)
                    qs = qs.filter(
                        Q(comunidad=comunidad) |
                        Q(publicacion__comunidad=comunidad) | 
                        Q(publicaciones_asociadas__comunidad=comunidad)
                    ).distinct()
                except (Comunidad.DoesNotExist, ValueError, TypeError):
                    return ImagenGaleria.objects.none()

            elif propietario_id:
                try:
                    if str(propietario_id) == str(self.request.user.id):
                        qs = qs.filter(propietario_id=propietario_id)
                    else:
                        qs = qs.filter(propietario_id=propietario_id, es_publica=True)
                        # Si es perfil ajeno, solo mostramos lo que esté en posts
                        qs = qs.filter(
                            Q(publicacion__isnull=False) | Q(publicaciones_asociadas__isnull=False)
                        ).distinct()
                except (ValueError, TypeError):
                    return ImagenGaleria.objects.none()
            else:
                # Explorar global: solo posts públicos
                qs = qs.filter(
                    Q(publicacion__isnull=False) | Q(publicaciones_asociadas__isnull=False),
                    es_publica=True
                ).distinct()

            return qs.order_by('-fecha_subida', 'id')
        except Exception:
            return ImagenGaleria.objects.none()

    def perform_create(self, serializer):
        """Asigna automáticamente el propietario a la nueva imagen.

        Args:
            serializer: Serializador con los datos de la imagen.
        """
        serializer.save(propietario=self.request.user)


class GaleriaDetalleExtendido(generics.RetrieveAPIView):
    """Retorna una imagen con sus publicaciones y colecciones asociadas."""

    queryset = ImagenGaleria.objects.all()
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def retrieve(self, request, *args, **kwargs):
        """Construye una respuesta extendida con relaciones de la imagen.

        Args:
            request: Petición GET.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Datos de la imagen, post asociado y colecciones donde aparece.
        """
        imagen = self.get_object()
        pub = Publicacion.objects.filter(imagen=imagen).first()
        pub_data = PublicacionSerializer(pub, context={'request': request}).data if pub else None
        cols = Coleccion.objects.filter(imagenes=imagen).filter(
            Q(es_privada=False) | Q(usuario=request.user)
        )
        cols_data = [{'id': c.id, 'nombre': c.nombre_coleccion, 'privada': c.es_privada} for c in cols]
        return Response({
            'imagen': self.get_serializer(imagen).data,
            'publicacion': pub_data,
            'colecciones': cols_data,
        })


class ImagenGaleriaDetail(generics.RetrieveUpdateDestroyAPIView):
    """Recupera, actualiza o elimina una imagen de la galería.

    Al eliminar, si el propietario no es quien borra, notifica al autor.
    """

    queryset = ImagenGaleria.objects.all()
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

    def destroy(self, request, *args, **kwargs):
        """Elimina la imagen y gestiona notificaciones y reportes.

        Args:
            request: Petición DELETE.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Confirmación de eliminación.
        """
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        if instance.propietario != request.user:
            Notificacion.objects.create(
                usuario=instance.propietario,
                tipo='CONTENIDO_BORRADO',
                mensaje=f'Tu imagen de la galería ha sido borrada por un administrador. Motivo: {razon}',
                referencia_comunidad=instance.comunidad,
            )
        Reporte.objects.filter(
            tipo_objeto='IMAGEN', objeto_id=instance.id, estado='PENDIENTE'
        ).update(estado='RESUELTO')
        instance.delete()
        return Response({'mensaje': 'Imagen eliminada'}, status=status.HTTP_200_OK)


class InicioGaleria(generics.ListAPIView):
    """Feed de imágenes para la pantalla de exploración de galería.

    Incluye contenido de comunidades del usuario, seguidos y perfiles públicos.
    """

    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = PaginacionGaleria

    def get_queryset(self):
        """Genera el feed de imágenes para la galería de inicio.

        Lógica:
        1. Obtener mis comunidades (donde soy miembro).
        2. Obtener mis amigos (usuarios que sigo con estado ACEPTADO).
        3. Mostrar posts que tengan foto Y cumplan al menos una:
           - Son de mis amigos
           - Son de mis comunidades
           - Son míos
           - Son de un perfil público
           - Son de una comunidad pública

        Returns:
            QuerySet: Publicaciones con imagen filtradas y anotadas.
        """
        usuario = self.request.user if self.request.user.is_authenticated else None
        etiquetas = self.request.query_params.get('etiquetas')

        # Base: solo posts válidos por IA que tengan al menos una foto
        qs = Publicacion.objects.filter(es_valido_ia=True).filter(
            Q(imagen__isnull=False) | Q(imagenes__isnull=False)
        )

        # Subqueries de anotaciones (reutilizables)
        likes_sub = MeGusta.objects.filter(
            publicacion=OuterRef('pk')
        ).values('publicacion').annotate(cnt=Count('id')).values('cnt')

        coments_sub = Comentario.objects.filter(
            publicacion=OuterRef('pk')
        ).values('publicacion').annotate(cnt=Count('id')).values('cnt')

        if usuario:
            # Comunidades donde el usuario es miembro
            mis_comunidades_ids = list(
                MiembrosComunidad.objects.filter(
                    usuario=usuario
                ).values_list('comunidad_id', flat=True)
            )

            # Usuarios que el usuario sigue con solicitud aceptada
            mis_amigos_ids = list(
                Seguimiento.objects.filter(
                    seguidor=usuario,
                    seguido_usuario__isnull=False,
                    estado='ACEPTADO'
                ).values_list('seguido_usuario_id', flat=True)
            )

            # Aplicamos filtros de visibilidad social
            qs = qs.filter(
                Q(autor=usuario) |                                  # Mis propios posts
                Q(autor_id__in=mis_amigos_ids) |                    # Posts de mis amigos
                Q(comunidad_id__in=mis_comunidades_ids) |           # Posts de mis comunidades
                (Q(autor__perfil__es_publico=True) & Q(comunidad__isnull=True)) |  # Posts de perfiles públicos (no en comunidad)
                (Q(comunidad__es_publica=True) & Q(comunidad__isnull=False))       # Posts de comunidades públicas
            )

            # Anotaciones con estado de interacción del usuario actual
            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_sub, output_field=IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(coments_sub, output_field=IntegerField()), Value(0)),
                anotado_usuario_dio_like=Exists(
                    MeGusta.objects.filter(publicacion=OuterRef('pk'), usuario=usuario)
                ),
                anotado_usuario_guardo_post=Exists(
                    PostGuardado.objects.filter(publicacion=OuterRef('pk'), usuario=usuario)
                ),
            )
        else:
            # Sin autenticar: perfiles públicos (sin comunidad) y comunidades públicas
            qs = qs.filter(
                (Q(autor__perfil__es_publico=True) & Q(comunidad__isnull=True)) |
                (Q(comunidad__es_publica=True) & Q(comunidad__isnull=False))
            )

            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_sub, output_field=IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(coments_sub, output_field=IntegerField()), Value(0)),
            )

        # Eliminar duplicados (por el M2M de imagenes)
        qs = qs.distinct()

        # Carga optimizada de relaciones
        qs = qs.select_related(
            'autor', 'autor__perfil', 'comunidad', 'imagen'
        ).prefetch_related('imagenes')

        # Filtro opcional por etiquetas
        if etiquetas:
            qs = qs.filter(
                Q(imagen__etiquetas__icontains=etiquetas) |
                Q(imagenes__etiquetas__icontains=etiquetas)
            ).distinct()

        return qs.order_by('-fecha_creacion')


class ColeccionViewSet:
    """Importado desde views.py principal para mantener compatibilidad."""
    pass
