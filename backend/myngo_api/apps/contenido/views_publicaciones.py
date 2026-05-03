"""Vistas de publicaciones: listado, creación, detalle y eliminación."""

from django.db import transaction
from django.db.models import Count, Exists, IntegerField, OuterRef, Q, Subquery, Value
from django.db.models.functions import Coalesce
from rest_framework import filters, generics, pagination, permissions, serializers, status
from rest_framework.response import Response

from comunidades.models import Comunidad
from notificaciones.models import Notificacion
from usuarios.models import Perfil, Seguimiento

from .ia_service import validar_contenido_toxico
from .models import Comentario, ImagenGaleria, MeGusta, PostGuardado, Publicacion, Reporte
from .permissions import IsAuthorOrAdmin
from .serializers import PublicacionSerializer


class PaginacionGaleria(pagination.LimitOffsetPagination):
    """Paginación estándar para listas de contenido. Límite por defecto: 20 items."""

    default_limit = 20
    max_limit = 100


class PublicacionList(generics.ListAPIView):
    """Lista publicaciones filtrando por comunidad, perfil o feed global.

    Aplica controles de privacidad y anota conteos de likes, comentarios
    y estado de interacción del usuario autenticado.
    """

    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['fecha_creacion']
    pagination_class = PaginacionGaleria

    def get_queryset(self):
        """Filtra y anota las publicaciones según los parámetros de la consulta.

        Returns:
            QuerySet: Publicaciones filtradas y anotadas con metadatos de interacción.
        """
        from django.db.models import IntegerField
        user = self.request.user
        comunidad_id = self.request.query_params.get('comunidad_id')
        perfil_id = self.request.query_params.get('perfil_id')
        solo_guardados = self.request.query_params.get('solo_guardados')

        qs = (
            Publicacion.objects.filter(es_valido_ia=True)
            .select_related('autor', 'comunidad', 'imagen', 'autor__perfil')
            .prefetch_related('imagenes')
        )

        likes_subquery = (
            MeGusta.objects.filter(publicacion=OuterRef('pk'))
            .values('publicacion')
            .annotate(count=Count('id'))
            .values('count')
        )
        comentarios_subquery = (
            Comentario.objects.filter(publicacion=OuterRef('pk'))
            .values('publicacion')
            .annotate(count=Count('id'))
            .values('count')
        )

        if user.is_authenticated:
            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_subquery, output_field=IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(comentarios_subquery, output_field=IntegerField()), Value(0)),
                anotado_usuario_dio_like=Exists(MeGusta.objects.filter(publicacion=OuterRef('pk'), usuario=user)),
                anotado_usuario_guardo_post=Exists(PostGuardado.objects.filter(publicacion=OuterRef('pk'), usuario=user)),
            )
        else:
            qs = qs.annotate(
                anotado_likes_count=Coalesce(Subquery(likes_subquery, output_field=IntegerField()), Value(0)),
                anotado_comentarios_count=Coalesce(Subquery(comentarios_subquery, output_field=IntegerField()), Value(0)),
            )

        if solo_guardados == 'true' and user.is_authenticated:
            qs = qs.filter(
                Q(guardado_por__usuario=user) | Q(imagenes__en_colecciones__usuario=user)
            ).distinct()
            if comunidad_id:
                qs = qs.filter(comunidad_id=comunidad_id)
            return qs.order_by('-fecha_creacion')

        if comunidad_id:
            try:
                comunidad = Comunidad.objects.get(id=comunidad_id)
            except Comunidad.DoesNotExist:
                return Publicacion.objects.none()
            if not comunidad.es_publica:
                if user.is_authenticated:
                    es_miembro = Seguimiento.objects.filter(
                        seguidor=user, seguida_comunidad=comunidad, estado='ACEPTADO'
                    ).exists()
                    if not es_miembro and comunidad.creador != user:
                        return Publicacion.objects.none()
                else:
                    return Publicacion.objects.none()
            return qs.filter(comunidad_id=comunidad_id).distinct().order_by('-fecha_creacion')

        if perfil_id:
            try:
                perfil = Perfil.objects.get(id=perfil_id)
            except Perfil.DoesNotExist:
                return Publicacion.objects.none()
            if not perfil.es_publico:
                if user.is_authenticated:
                    es_miembro = Seguimiento.objects.filter(
                        seguidor=user, seguido_usuario=perfil.usuario, estado='ACEPTADO'
                    ).exists()
                    if not es_miembro and perfil.usuario != user:
                        return Publicacion.objects.none()
                else:
                    return Publicacion.objects.none()
            return qs.filter(autor=perfil.usuario, comunidad__isnull=True).distinct().order_by('-fecha_creacion')

        # Filtro por etiquetas (tags)
        tags_query = self.request.query_params.get('tags')
        if tags_query:
            tags = [t.strip() for t in tags_query.split(',') if t.strip()]
            search_mode = self.request.query_params.get('tag_mode', 'OR').upper()
            
            if search_mode == 'AND':
                for tag in tags:
                    qs = qs.filter(
                        Q(titulo__icontains=tag) | 
                        Q(contenido_texto__icontains=tag) | 
                        Q(imagenes__etiquetas__icontains=tag)
                    )
            else: # OR por defecto
                q_or = Q()
                for tag in tags:
                    q_or |= Q(titulo__icontains=tag)
                    q_or |= Q(contenido_texto__icontains=tag)
                    q_or |= Q(imagenes__etiquetas__icontains=tag)
                qs = qs.filter(q_or)

        return qs.filter(
            Q(comunidad__es_publica=True) |
            Q(autor__perfil__es_publico=True, comunidad__isnull=True)
        ).distinct().order_by('-fecha_creacion')


class PublicacionCreate(generics.CreateAPIView):
    """Crea una nueva publicación con hasta 4 imágenes adjuntas.

    Valida el contenido mediante IA antes de guardar. Si la transacción
    falla, se revierte automáticamente.
    """

    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        """Procesa la creación de una publicación y sus imágenes asociadas.

        Args:
            request: Petición con datos de post y archivos multimedia.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Datos de la publicación creada o mensaje de error.
        """
        from django.db import transaction
        archivos = request.FILES.getlist('url_archivo_s3[]') or request.FILES.getlist('url_archivo_s3')
        titulo = request.data.get('titulo', '') or ''
        contenido_texto = request.data.get('contenido_texto', '') or ''
        texto = f"{titulo} {contenido_texto}".strip()
        es_valido = validar_contenido_toxico(texto)
        try:
            with transaction.atomic():
                serializer = self.get_serializer(data=request.data)
                serializer.is_valid(raise_exception=True)
                publicacion = serializer.save(autor=request.user, es_valido_ia=es_valido)
                from .models import PublicacionImagen
                for i, archivo in enumerate(archivos[:4]):
                    # Validación de tamaño (100 MB = 100 * 1024 * 1024 bytes)
                    if archivo.size > 100 * 1024 * 1024:
                        raise Exception(f"El archivo {archivo.name} supera el límite de 100MB.")

                    # Detección de tipo
                    tipo = 'V' if (archivo.content_type and archivo.content_type.startswith('video/')) else 'I'

                    img_instancia = ImagenGaleria.objects.create(
                        propietario=request.user,
                        url_s3=archivo,
                        comunidad_id=request.data.get('comunidad') or None,
                        relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0)),
                        etiquetas=request.data.get('etiquetas', ''),
                        tipo_archivo=tipo,
                    )
                    
                    # Crear la relación con orden
                    PublicacionImagen.objects.create(
                        publicacion=publicacion,
                        imagengaleria=img_instancia,
                        orden=i
                    )
                    
                    # Si es la primera, guardarla también como imagen principal
                    if i == 0:
                        publicacion.imagen = img_instancia
                        publicacion.save()

                return Response(
                    PublicacionSerializer(publicacion, context={'request': request}).data,
                    status=status.HTTP_201_CREATED,
                )
        except Exception as e:
            return Response(
                {'error': f'Se ha cancelado la creación de la publicación debido a un error: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )


class PublicacionDelete(generics.DestroyAPIView):
    """Elimina una publicación y sus imágenes asociadas.

    Si quien borra no es el autor (es administrador), envía una notificación al autor.
    Resuelve automáticamente los reportes pendientes sobre la publicación.
    """

    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        """Ejecuta la eliminación física del post y lógica de notificación.

        Args:
            request: Petición DELETE.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Confirmación de eliminación.
        """
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        titulo_seguro = instance.titulo or 'Sin título'

        if instance.autor != request.user:
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo='CONTENIDO_BORRADO',
                mensaje=f"Tu post '{titulo_seguro[:20]}...' ha sido borrado por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.comunidad,
            )

        Reporte.objects.filter(
            tipo_objeto='POST', objeto_id=instance.id, estado='PENDIENTE'
        ).update(estado='RESUELTO')

        imgs = list(instance.imagenes.all())
        if instance.imagen and instance.imagen not in imgs:
            instance.imagen.delete()
        for img in imgs:
            img.delete()

        instance.delete()
        return Response({'mensaje': 'Publicación eliminada correctamente'}, status=status.HTTP_200_OK)


class PublicacionDetail(generics.RetrieveUpdateDestroyAPIView):
    """Recupera, actualiza o elimina una publicación específica.

    La actualización valida el nuevo contenido con el filtro de toxicidad de IA.
    """

    queryset = Publicacion.objects.all()
    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

    def update(self, request, *args, **kwargs):
        """Actualiza el contenido del post tras validar toxicidad.

        Args:
            request: Petición PATCH/PUT.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Datos actualizados del post.
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        titulo = request.data.get('titulo') if request.data.get('titulo') is not None else (instance.titulo or '')
        contenido_texto = (
            request.data.get('contenido_texto')
            if request.data.get('contenido_texto') is not None
            else (instance.contenido_texto or '')
        )
        texto = f"{titulo} {contenido_texto}".strip()
        es_valido = validar_contenido_toxico(texto)
        serializer.save(es_valido_ia=es_valido)
        self.perform_update(serializer)
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        """Elimina el post y limpia recursos asociados (imágenes, reportes).

        Args:
            request: Petición DELETE.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Confirmación de eliminación.
        """
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        titulo_seguro = instance.titulo or 'Sin título'
        if instance.autor != request.user:
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo='CONTENIDO_BORRADO',
                mensaje=f"Tu post '{titulo_seguro[:20]}...' ha sido borrado por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.comunidad,
            )
        Reporte.objects.filter(
            tipo_objeto='POST', objeto_id=instance.id, estado='PENDIENTE'
        ).update(estado='RESUELTO')
        imgs = list(instance.imagenes.all())
        if instance.imagen and instance.imagen not in imgs:
            instance.imagen.delete()
        for img in imgs:
            img.delete()
        instance.delete()
        return Response({'mensaje': 'Publicación eliminada correctamente'}, status=status.HTTP_200_OK)
