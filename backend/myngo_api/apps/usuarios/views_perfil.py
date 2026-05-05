"""Vistas de gestión de perfiles y datos de usuario."""

from django.core.files.storage import default_storage
from django.db import models
from django.db.models import Count, OuterRef, Subquery
from rest_framework import filters, generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.views import APIView

from contenido.models import ImagenGaleria

from .models import Perfil, Seguimiento, Usuario
from .serializers import PerfilSerializer, UsuarioSerializer

from rest_framework.pagination import PageNumberPagination

class DatosUsuarios(generics.ListAPIView):
    """Retorna datos de un usuario específico o de todos los usuarios del sistema.

    Esta vista permite obtener información detallada de un usuario mediante su ID
    o listar todos los usuarios registrados con información de seguidores y seguidos.
    """

    serializer_class = UsuarioSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['nombre_usuario', 'email']
    pagination_class = PageNumberPagination

    def get_queryset(self):
        """Retorna el conjunto de usuarios anotados."""
        usuarios = Usuario.objects.select_related('perfil').annotate(
            anotado_seguidores=Count('seguidores', filter=models.Q(seguidores__estado='ACEPTADO')),
            anotado_seguidos=Count('siguiendo', filter=models.Q(siguiendo__estado='ACEPTADO')),
        )
        if self.request.user and self.request.user.is_authenticated:
            usuarios = usuarios.exclude(id=self.request.user.id).annotate(
                anotado_estado_seguimiento=Subquery(
                    Seguimiento.objects.filter(
                        seguidor=self.request.user, seguido_usuario=OuterRef('pk')
                    ).values('estado')[:1]
                )
            )
        return usuarios.order_by('id')

    def get(self, request, usuario_id=None):
        """Obtiene los datos de un usuario por ID o nombre de usuario, o lista todos los usuarios con paginación."""
        if usuario_id:
            # Intenta primero como ID numérico
            try:
                usuario_id_int = int(usuario_id)
                usuario = Usuario.objects.filter(id=usuario_id_int).first()
            except (ValueError, TypeError):
                # Si falla, intenta como nombre de usuario
                usuario = Usuario.objects.filter(nombre_usuario=usuario_id).first()
            
            if usuario:
                serializer = self.get_serializer(usuario, context={'request': request})
                return Response({
                    'exito': True,
                    'mensaje': f'Los datos del usuario {usuario_id}',
                    'datos': serializer.data,
                })
            return Response(
                {'exito': False, 'mensaje': f'No existe el usuario con id o nombre {usuario_id}'},
                status=status.HTTP_404_NOT_FOUND,
            )

        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response({'exito': True, 'mensaje': 'Todos los usuarios del sistema', 'datos': serializer.data})

    def put(self, request):
        """Actualiza los datos de un usuario por su ID.

        Permite la actualización parcial de campos como nombre_usuario o email.

        Args:
            request: Petición PUT con ``id`` y los campos a actualizar en el body.

        Returns:
            Response: Datos actualizados o errores de validación.
        """
        usuario_id = request.data.get('id')
        try:
            usuario = Usuario.objects.get(id=usuario_id)
            serializer = UsuarioSerializer(usuario, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({'exito': True, 'mensaje': 'usuario actualizado', 'datos': serializer.data})
            return Response({'exito': False, 'errores': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Usuario.DoesNotExist:
            return Response(
                {'exito': False, 'errores': 'No existe un usuario con el ID proporcionado.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response({'exito': False, 'errores': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class GestionPerfiles(generics.ListCreateAPIView):
    """Lista todos los perfiles o crea uno nuevo.

    Excluye al propio usuario autenticado de la lista. Soporta búsqueda por nombre de usuario.
    """

    serializer_class = PerfilSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['usuario__nombre_usuario']
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        """Retorna el conjunto de perfiles filtrado por el usuario actual.

        Returns:
            QuerySet: Lista de perfiles ordenados por fecha de actualización.
        """
        perfiles = Perfil.objects.all().order_by('-fecha_actualizacion')
        if self.request.user and self.request.user.is_authenticated:
            perfiles = perfiles.exclude(usuario=self.request.user)
        return perfiles


class EditarPerfil(APIView):
    """Actualiza los datos del perfil de un usuario, incluyendo el avatar.

    Si se adjunta una imagen, se crea una entrada en ``ImagenGaleria`` y
    se almacena en S3 bajo la ruta de avatares de perfil.
    """

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        """Actualiza el perfil identificado por ``perfil_id`` en el cuerpo de la petición.

        Args:
            request: Petición PATCH con ``perfil_id`` y campos opcionales (biografía, avatar).

        Returns:
            Response: URL del nuevo avatar y datos del perfil actualizado.
        """
        perfil_id = request.data.get('perfil_id')
        if not perfil_id:
            return Response(
                {'exito': False, 'mensaje': 'No se ha enviado ningun perfil para editar'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            perfil = Perfil.objects.get(id=perfil_id)
        except Perfil.DoesNotExist:
            return Response(
                {'exito': False, 'mensaje': 'No existe ningún perfil registrado con ese id'},
                status=status.HTTP_404_NOT_FOUND,
            )

        imagen = request.FILES.get('url_avatar')
        if imagen:
            imagen_nueva = ImagenGaleria.objects.create(
                propietario=request.user,
                comunidad_id=request.data.get('comunidad') or None,
                relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0)),
                etiquetas=request.data.get('etiquetas', ''),
            )
            if request.data.get('es_perfil'):
                imagen_nueva._es_avatar = True
            imagen_nueva.url_s3 = imagen
            imagen_nueva.save()
            perfil.avatar = imagen_nueva.url_s3.name

        imagen_fondo = request.FILES.get('url_fondo')
        if imagen_fondo:
            imagen_nueva = ImagenGaleria.objects.create(
                propietario=request.user,
                comunidad_id=request.data.get('comunidad') or None,
                relacion_aspecto=float(request.data.get('relacion_aspecto', 1.5)),
                etiquetas=request.data.get('etiquetas', ''),
            )
            if request.data.get('es_perfil'):
                imagen_nueva._es_avatar = True
            imagen_nueva.url_s3 = imagen_fondo
            imagen_nueva.save()
            perfil.fondo = imagen_nueva.url_s3.name

        imagen_fondo_perfil = request.FILES.get('url_fondo_perfil')
        if imagen_fondo_perfil:
            imagen_nueva = ImagenGaleria.objects.create(
                propietario=request.user,
                comunidad_id=request.data.get('comunidad') or None,
                relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0)),
                etiquetas=request.data.get('etiquetas', ''),
            )
            if request.data.get('es_perfil'):
                imagen_nueva._es_avatar = True
            imagen_nueva.url_s3 = imagen_fondo_perfil
            imagen_nueva.save()
            perfil.fondo_perfil = imagen_nueva.url_s3.name

        serializer = PerfilSerializer(perfil, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            url_avatar = None
            if perfil.avatar:
                url_avatar = (
                    perfil.avatar
                    if perfil.avatar.startswith('http')
                    else default_storage.url(perfil.avatar.lstrip('/'))
                )
            return Response(
                {
                    'exito': True,
                    'mensaje': 'Perfil actualizado correctamente',
                    'url_avatar': url_avatar,
                    'datos': serializer.data,
                },
                status=status.HTTP_200_OK,
            )
        return Response({'exito': False, 'errores': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)


class RankingUsuarios(APIView):
    """Retorna los 10 usuarios con mayor rating, con anotaciones de seguimiento."""

    permission_classes = [AllowAny]

    def get(self, request):
        """Obtiene el Top 10 de usuarios basado en su reputación.

        Args:
            request: Petición GET.

        Returns:
            Response: Lista de usuarios del ranking.
        """
        usuarios = Usuario.objects.select_related('perfil').annotate(
            anotado_seguidores=Count('seguidores', filter=models.Q(seguidores__estado='ACEPTADO')),
            anotado_seguidos=Count('siguiendo', filter=models.Q(siguiendo__estado='ACEPTADO')),
        )
        if request.user and request.user.is_authenticated:
            usuarios = usuarios.annotate(
                anotado_estado_seguimiento=Subquery(
                    Seguimiento.objects.filter(
                        seguidor=request.user, seguido_usuario=OuterRef('pk')
                    ).values('estado')[:1]
                )
            )
        usuarios = usuarios.order_by('-rating_actual')[:10]
        serializer = UsuarioSerializer(usuarios, many=True, context={'request': request})
        return Response({'exito': True, 'datos': serializer.data}, status=status.HTTP_200_OK)
