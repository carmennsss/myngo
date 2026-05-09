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
            
            nuevo_nombre = request.data.get('nombre_usuario')
            if nuevo_nombre:
                if Usuario.objects.filter(nombre_usuario__iexact=nuevo_nombre).exclude(id=usuario.id).exists():
                    return Response(
                        {'exito': False, 'mensaje': 'Ese nombre de usuario ya está en uso por otra persona'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )

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
    search_fields = ['^usuario__nombre_usuario']
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
            
            # Desequipar avatares del inventario
            from mejoras.models import MejoraUsuario
            MejoraUsuario.objects.filter(
                usuario=request.user,
                mejora__tipo='avatar',
                esta_equipada=True
            ).update(esta_equipada=False)

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

            # Desequipar fondos (banner) del inventario
            from mejoras.models import MejoraUsuario
            MejoraUsuario.objects.filter(
                usuario=request.user,
                mejora__tipo='fondo',
                esta_equipada=True
            ).update(esta_equipada=False)

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

            # Desequipar fondos (feed) del inventario
            # Nota: El frontend suele usar fondo_perfil para el feed
            from mejoras.models import MejoraUsuario
            MejoraUsuario.objects.filter(
                usuario=request.user,
                mejora__tipo='fondo',
                esta_equipada=True
            ).update(esta_equipada=False)

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


class CambiarPassword(APIView):
    """Permite a un usuario autenticado cambiar su contraseña."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        usuario = request.user
        nueva_password = request.data.get('nueva_password')

        if not nueva_password:
            return Response({'exito': False, 'mensaje': 'La nueva contraseña es obligatoria.'}, status=status.HTTP_400_BAD_REQUEST)

        usuario.set_password(nueva_password)
        usuario.save()

        # Enviar correo de notificación
        from django.core.mail import send_mail
        from django.conf import settings
        from django.utils.html import strip_tags

        sujeto = 'Aviso de seguridad - Myngo 🐾'
        mensaje_html = f"""
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 10px; padding: 20px;">
            <h2 style="color: #6C63FF; text-align: center;">¡Hola, {usuario.nombre_usuario}!</h2>
            <p style="font-size: 16px; color: #333;">
                Te informamos de que la contraseña de tu cuenta de <strong>Myngo</strong> ha sido cambiada recientemente.
            </p>
            <p style="font-size: 14px; color: #555;">
                Si has sido tú, puedes ignorar este correo. Si no has sido tú, responde a este correo inmediatamente para que podamos ayudarte a proteger tu cuenta.
            </p>
            <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
            <div style="text-align: center; margin-top: 20px;">
                <span style="font-size: 18px;">🐾 Myngo Team</span>
            </div>
        </div>
        """
        try:
            send_mail(
                sujeto,
                strip_tags(mensaje_html),
                settings.EMAIL_HOST_USER,
                [usuario.email],
                html_message=mensaje_html,
                fail_silently=True,
            )
        except Exception:
            pass # No bloqueamos si falla el email

        return Response({'exito': True, 'mensaje': 'Contraseña actualizada correctamente.'}, status=status.HTTP_200_OK)


class EliminarCuenta(APIView):
    """Permite a un usuario eliminar su cuenta."""
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        usuario = request.user
        
        # Eliminar comunidades creadas por el usuario
        from comunidades.models import Comunidad
        Comunidad.objects.filter(creador=usuario).delete()

        # En lugar de eliminar físicamente para mantener las salas de chat intactas,
        # desactivamos la cuenta y ofuscamos los datos personales.
        import uuid
        identificador = str(uuid.uuid4())[:8]
        usuario.is_active = False
        usuario.email = f"eliminado_{identificador}@myngo.com"
        usuario.nombre_usuario = f"UsuarioEliminado_{identificador}"
        usuario.set_unusable_password()
        usuario.save()

        # Opcional: limpiar biografía o avatar si se quiere borrar todo rastro visual
        if hasattr(usuario, 'perfil'):
            usuario.perfil.biografia = ""
            usuario.perfil.avatar = None
            usuario.perfil.fondo = None
            usuario.perfil.fondo_perfil = None
            usuario.perfil.save()

        return Response({'exito': True, 'mensaje': 'Cuenta eliminada correctamente.'}, status=status.HTTP_200_OK)
