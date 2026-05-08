"""Vistas del dominio de comunidades.

Gestiona la creación, listado, detalle y administración de comunidades,
así como las operaciones de membresía (unirse, roles, peticiones de unión).
"""

from django.db import models
from rest_framework import filters, generics, permissions, status, pagination
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.views import APIView

from notificaciones.models import Notificacion
from usuarios.models import Seguimiento

from .models import Comunidad, MiembrosComunidad, TagComunidad
from .serializers import ComunidadSerializer, MiembroComunidadSerializer, TagComunidadSerializer
from mensajeria.models import SalaChat
import uuid


class TagComunidadList(generics.ListAPIView):
    """Lista o busca etiquetas de comunidades."""
    queryset = TagComunidad.objects.all()
    serializer_class = TagComunidadSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['nombre']
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        """Opcionalmente filtra por los más usados o por búsqueda."""
        qs = super().get_queryset()
        if self.request.query_params.get('popular'):
            qs = qs.annotate(num_comunidades=models.Count('comunidades')).order_by('-num_comunidades')
        return qs


class ComunidadListCreate(generics.ListCreateAPIView):
    """Lista todas las comunidades o crea una nueva.

    Soporta búsqueda por nombre y descripción. Al crear, el usuario
    autenticado pasa a ser el creador y se le asigna el rol Administrador.
    """

    serializer_class = ComunidadSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['nombre', 'descripcion', 'tags__nombre']
    permission_classes = [IsAuthenticatedOrReadOnly]
    pagination_class = pagination.PageNumberPagination

    def get_queryset(self):
        """Retorna el conjunto de comunidades con anotaciones de membresía para el usuario actual.

        Returns:
            QuerySet: Lista de comunidades anotadas con metadatos de acceso y rol.
        """
        from django.db.models import Count, Exists, OuterRef, Subquery
        usuario = self.request.user
        queryset = Comunidad.objects.all()

        # Filtrado por tags (AND)
        tags_param = self.request.query_params.get('tags')
        if tags_param:
            tags_list = []
            for t in self.request.query_params.getlist('tags'):
                tags_list.extend(t.split(','))
            
            # Filtramos comunidades que tengan TODOS los tags especificados
            for tag in tags_list:
                queryset = queryset.filter(tags__nombre__iexact=tag)

        # Filtrado por rating mínimo
        min_rating = self.request.query_params.get('min_rating')
        if min_rating and min_rating.isdigit():
            queryset = queryset.filter(min_rating_acceso__gte=int(min_rating))

        # Filtrado por rating máximo (opcional, para el sistema de 5 estrellas)
        max_rating = self.request.query_params.get('max_rating')
        if max_rating and max_rating.isdigit():
            queryset = queryset.filter(min_rating_acceso__lte=int(max_rating))

        queryset = queryset.annotate(
            anotado_miembros_count=models.Count('miembros_comunidades', distinct=True)
        )
        if usuario and usuario.is_authenticated:
            from django.db.models import Exists, OuterRef, Subquery
            queryset = queryset.annotate(
                anotado_es_miembro=Exists(
                    MiembrosComunidad.objects.filter(
                        usuario=usuario, comunidad=OuterRef('pk')
                    )
                ),
                anotado_es_pendiente=Exists(
                    Seguimiento.objects.filter(
                        seguidor=usuario,
                        seguida_comunidad=OuterRef('pk'),
                        estado='SOLICITUD',
                    )
                ),
                anotado_mi_rol=Subquery(
                    MiembrosComunidad.objects.filter(
                        usuario=usuario, comunidad=OuterRef('pk')
                    ).values('rol')[:1]
                ),
            )
        return queryset.order_by('-fecha_creacion')

    def perform_create(self, serializer):
        """Asigna al usuario actual como creador y administrador de la nueva comunidad.

        Args:
            serializer: Serializador con los datos de la comunidad.
        """
        comunidad = serializer.save(creador=self.request.user)
        MiembrosComunidad.objects.create(
            usuario=self.request.user,
            comunidad=comunidad,
            rol='Administrador',
        )


class MisComunidadesList(generics.ListAPIView):
    """Lista las comunidades donde el usuario es miembro o creador."""

    serializer_class = ComunidadSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Retorna las comunidades vinculadas al usuario autenticado.

        Returns:
            QuerySet: Comunidades donde el usuario participa.
        """
        from django.db.models import Count, Exists, OuterRef, Subquery
        usuario = self.request.user
        return (
            Comunidad.objects.filter(
                models.Q(creador=usuario)
                | models.Q(miembros_comunidades__usuario=usuario)
            )
            .distinct()
            .annotate(
                anotado_miembros_count=Count('miembros_comunidades', distinct=True),
                anotado_es_miembro=Exists(
                    MiembrosComunidad.objects.filter(
                        usuario=usuario, comunidad=OuterRef('pk')
                    )
                ),
                anotado_es_pendiente=Exists(
                    Seguimiento.objects.filter(
                        seguidor=usuario,
                        seguida_comunidad=OuterRef('pk'),
                        estado='SOLICITUD',
                    )
                ),
                anotado_mi_rol=Subquery(
                    MiembrosComunidad.objects.filter(
                        usuario=usuario, comunidad=OuterRef('pk')
                    ).values('rol')[:1]
                ),
            )
            .order_by('-fecha_creacion')
        )


class UnirseComunidad(APIView):
    """Permite a un usuario unirse a una comunidad pública o solicitar acceso a una privada.

    Si la comunidad tiene un rating mínimo de acceso, se verifica antes de proceder.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Procesa la solicitud de unión a una comunidad.

        Args:
            request: Petición POST.
            pk (int): ID de la comunidad.

        Returns:
            Response: Resultado de la operación (unido, solicitud enviada o error).
        """
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response(
                {'error': 'La comunidad no existe'}, status=status.HTTP_404_NOT_FOUND
            )

        usuario = request.user

        if usuario.rating_medio < comunidad.min_rating_acceso:
            return Response(
                {
                    'error': (
                        f'¡Miau! No tienes suficiente reputación para unirte. '
                        f'Se requiere un rating de {comunidad.min_rating_acceso}, '
                        f'pero tu media es de {usuario.rating_medio}.'
                    )
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        if MiembrosComunidad.objects.filter(usuario=usuario, comunidad=comunidad).exists():
            return Response(
                {'mensaje': 'Ya eres miembro de esta comunidad.', 'estado': 'ACEPTADO'},
                status=status.HTTP_200_OK,
            )

        solicitud = Seguimiento.objects.filter(
            seguidor=usuario, seguida_comunidad=comunidad
        ).first()

        if solicitud:
            if solicitud.estado == 'DENEGADO':
                solicitud.estado = 'SOLICITUD' if not comunidad.es_publica else 'ACEPTADO'
                solicitud.save()
                if solicitud.estado == 'ACEPTADO':
                    MiembrosComunidad.objects.get_or_create(
                        usuario=usuario, comunidad=comunidad
                    )
                return Response(
                    {'mensaje': 'Solicitud reintentada', 'estado': solicitud.estado},
                    status=status.HTTP_200_OK,
                )
            estado_msg = {
                'SOLICITUD': 'Ya tienes una solicitud pendiente de aprobación.',
                'ACEPTADO': 'Ya eres miembro de esta comunidad.',
                'DENEGADO': 'Tu solicitud ha sido rechazada anteriormente.',
            }.get(solicitud.estado, f'Estado actual: {solicitud.estado}')
            return Response(
                {'mensaje': estado_msg, 'estado': solicitud.estado},
                status=status.HTTP_200_OK,
            )

        estado = 'ACEPTADO' if comunidad.es_publica else 'SOLICITUD'
        if not comunidad.es_publica:
            solicitud = Seguimiento.objects.create(
                seguidor=usuario, seguida_comunidad=comunidad, estado=estado
            )
            Notificacion.objects.create(
                usuario=comunidad.creador,
                tipo='PETICION_UNION',
                mensaje=(
                    f'¡Miau! {usuario.nombre_usuario} quiere unirse a '
                    f"tu comunidad '{comunidad.nombre}'."
                ),
                referencia_usuario=usuario,
                referencia_comunidad=comunidad,
                referencia_id=solicitud.id,
            )
        else:
            MiembrosComunidad.objects.create(usuario=usuario, comunidad=comunidad)

        mensaje = (
            'Te has unido a la comunidad'
            if comunidad.es_publica
            else 'Solicitud enviada a la comunidad privada'
        )
        return Response({'mensaje': mensaje, 'estado': estado}, status=status.HTTP_201_CREATED)


class ResponderPeticionUnion(APIView):
    """Permite al administrador de una comunidad aceptar o rechazar una petición de unión."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Acepta o rechaza la petición de un usuario para unirse a la comunidad.

        Args:
            request: Petición POST con el booleano ``aceptar``.
            pk (int): ID de la petición de seguimiento.

        Returns:
            Response: Confirmación de la acción.
        """
        try:
            peticion = Seguimiento.objects.get(pk=pk)
        except Seguimiento.DoesNotExist:
            return Response(
                {'error': 'La petición no existe'}, status=status.HTTP_404_NOT_FOUND
            )

        if peticion.seguida_comunidad.creador != request.user:
            return Response(
                {'error': 'No tienes permiso'}, status=status.HTTP_403_FORBIDDEN
            )

        aceptar = request.data.get('aceptar', False)
        if aceptar:
            MiembrosComunidad.objects.get_or_create(
                usuario=peticion.seguidor, comunidad=peticion.seguida_comunidad
            )

            Notificacion.objects.create(
                usuario=peticion.seguidor,
                tipo='PETICION_ACEPTADA',
                mensaje=f"¡Miau! Has sido aceptado en '{peticion.seguida_comunidad.nombre}'.",
                referencia_comunidad=peticion.seguida_comunidad,
            )
            peticion.delete()
        else:
            peticion.estado = 'DENEGADO'
            peticion.save()

        return Response({'mensaje': 'Respuesta enviada'}, status=status.HTTP_200_OK)


class ListarMiembrosComunidad(generics.ListAPIView):
    """Retorna la lista de miembros de una comunidad, incluyendo al creador."""

    serializer_class = MiembroComunidadSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    pagination_class = pagination.PageNumberPagination

    def get_queryset(self):
        """Obtiene todos los miembros de la comunidad."""
        pk = self.kwargs.get('pk')
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return MiembrosComunidad.objects.none()
        
        return MiembrosComunidad.objects.filter(comunidad=comunidad).select_related('usuario', 'usuario__perfil').order_by('rol', '-fecha_union')

    def list(self, request, *args, **kwargs):
        """Sobrescribe para incluir al creador si es la primera página."""
        pk = self.kwargs.get('pk')
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response({'error': 'Comunidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        miembros_data = []
        
        # Si es la primera página, añadimos al creador manualmente
        page_num = request.query_params.get('page', '1')
        if page_num == '1' and comunidad.creador:
            from django.core.files.storage import default_storage
            url_av = comunidad.creador.url_avatar
            if url_av and not url_av.startswith('http'):
                url_av = default_storage.url(url_av.lstrip('/'))

            miembros_data.append({
                'id': -1,
                'usuario_id': comunidad.creador.id,
                'perfil_id': getattr(comunidad.creador.perfil, 'id', 0) if hasattr(comunidad.creador, 'perfil') else 0,
                'usuario_nombre': comunidad.creador.nombre_usuario,
                'usuario_avatar': url_av,
                'rol': 'Creador',
                'fecha_union': comunidad.fecha_creacion.isoformat() if comunidad.fecha_creacion else None,
            })

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            for m in serializer.data:
                if comunidad.creador and m['usuario_id'] == comunidad.creador.id:
                    continue
                miembros_data.append(m)
            
            # Devolvemos una respuesta compatible con lo que espera el frontend
            res = self.get_paginated_response(miembros_data)
            res.data['exito'] = True
            res.data['datos'] = res.data.pop('results')
            return res

        serializer = self.get_serializer(queryset, many=True)
        for m in serializer.data:
            if comunidad.creador and m['usuario_id'] == comunidad.creador.id:
                continue
            miembros_data.append(m)
        return Response({'exito': True, 'datos': miembros_data})

class ListarMiembrosComunidadOld(APIView):
    """Retorna la lista de miembros de una comunidad, incluyendo al creador."""

    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request, pk):
        """Obtiene todos los miembros (creador + registrados) de la comunidad.

        Args:
            request: Petición GET.
            pk (int): ID de la comunidad.

        Returns:
            Response: Lista de miembros con roles y datos básicos.
        """
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response({'error': 'Comunidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        from django.core.files.storage import default_storage

        def construir_url_avatar(usuario):
            if not usuario or not usuario.url_avatar:
                return None
            url = usuario.url_avatar
            if url.startswith('http'):
                return url
            return default_storage.url(url.lstrip('/'))

        miembros_data = []

        # 1. Añadir al creador siempre al principio
        if comunidad.creador:
            miembros_data.append({
                'id': -1, # ID ficticio para el creador
                'usuario_id': comunidad.creador.id,
                'perfil_id': getattr(comunidad.creador.perfil, 'id', 0) if hasattr(comunidad.creador, 'perfil') else 0,
                'usuario_nombre': comunidad.creador.nombre_usuario,
                'usuario_avatar': construir_url_avatar(comunidad.creador),
                'rol': 'Creador',
                'fecha_union': comunidad.fecha_creacion.isoformat() if comunidad.fecha_creacion else None,
            })

        # 2. Añadir al resto de miembros
        miembros = (
            MiembrosComunidad.objects.filter(comunidad=comunidad)
            .select_related('usuario', 'usuario__perfil')
            .order_by('rol', '-fecha_union')
        )
        
        for m in miembros:
            # Evitar duplicar al creador si por error está en la tabla de miembros
            if comunidad.creador and m.usuario.id == comunidad.creador.id:
                continue
                
            miembros_data.append({
                'id': m.id,
                'usuario_id': m.usuario.id,
                'perfil_id': getattr(m.usuario.perfil, 'id', 0) if hasattr(m.usuario, 'perfil') else 0,
                'usuario_nombre': m.usuario.nombre_usuario,
                'usuario_avatar': construir_url_avatar(m.usuario),
                'rol': m.rol,
                'fecha_union': m.fecha_union.isoformat() if m.fecha_union else None,
            })

        return Response(miembros_data)


class ComunidadDetail(generics.RetrieveUpdateDestroyAPIView):
    """Recupera, actualiza o elimina una comunidad específica.

    Solo el creador o los gestores (Administrador/Moderador) pueden modificarla.
    Solo el creador puede eliminarla.
    """

    queryset = Comunidad.objects.all()
    serializer_class = ComunidadSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_object(self):
        """Busca la comunidad por PK o por Nombre."""
        queryset = self.filter_queryset(self.get_queryset())
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        val = self.kwargs[lookup_url_kwarg]

        # Intentar por ID
        if str(val).isdigit():
            obj = queryset.filter(pk=val).first()
            if obj:
                self.check_object_permissions(self.request, obj)
                return obj
        
        # Intentar por Nombre
        obj = queryset.filter(nombre=val).first()
        if obj:
            self.check_object_permissions(self.request, obj)
            return obj

        from django.http import Http404
        raise Http404("No se encontró ninguna comunidad con ese identificador.")

    def perform_update(self, serializer):
        """Valida permisos de gestión antes de actualizar la comunidad.

        Args:
            serializer: Serializador con los datos a actualizar.
        """
        comunidad = self.get_object()
        usuario = self.request.user
        es_gestor = comunidad.creador == usuario or MiembrosComunidad.objects.filter(
            usuario=usuario, comunidad=comunidad, rol__in=['Administrador', 'Moderador']
        ).exists()
        if not es_gestor:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied(
                'Solo los administradores y moderadores pueden modificar la comunidad.'
            )
        serializer.save()

    def perform_destroy(self, instance):
        """Valida que solo el creador original pueda eliminar la comunidad.

        Args:
            instance: Instancia de Comunidad a eliminar.
        """
        if instance.creador != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Solo el creador puede borrar la comunidad.')
        instance.delete()


class AdminDashboardView(APIView):
    """Dashboard centralizado para el administrador de la comunidad.

    Retorna solicitudes de unión pendientes, reportes de contenido activos
    y la lista de miembros con sus roles.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        """Obtiene un resumen de gestión para la comunidad.

        Args:
            request: Petición GET.
            pk (int): ID de la comunidad.

        Returns:
            Response: Datos para el dashboard de administración.
        """
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response({'error': 'Comunidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        es_gestor = comunidad.creador == request.user or MiembrosComunidad.objects.filter(
            usuario=request.user,
            comunidad=comunidad,
            rol__in=['Administrador', 'Moderador'],
        ).exists()
        if not es_gestor:
            return Response(
                {'error': 'No tienes permisos de gestión en esta comunidad'}, status=status.HTTP_403_FORBIDDEN
            )

        solicitudes = Seguimiento.objects.filter(
            seguida_comunidad=comunidad, estado='SOLICITUD'
        )
        solicitudes_data = [
            {
                'id': s.id,
                'usuario_nombre': s.seguidor.nombre_usuario,
                'usuario_id': s.seguidor.id,
                'fecha': s.fecha_seguimiento,
            }
            for s in solicitudes
        ]

        from contenido.models import Reporte
        from contenido.serializers import ReporteSerializer
        reportes = Reporte.objects.filter(comunidad=comunidad, estado='PENDIENTE')
        reportes_data = ReporteSerializer(
            reportes, many=True, context={'request': request}
        ).data

        miembros = (
            MiembrosComunidad.objects.filter(comunidad=comunidad)
            .select_related('usuario')
            .order_by('rol', '-fecha_union')
        )
        miembros_data = [
            {
                'id': m.id,
                'usuario_id': m.usuario.id,
                'usuario_nombre': m.usuario.nombre_usuario,
                'usuario_avatar': m.usuario.url_avatar or None,
                'rol': m.rol,
                'fecha_union': m.fecha_union,
            }
            for m in miembros
        ]

        return Response(
            {
                'comunidad_nombre': comunidad.nombre,
                'solicitudes_pendientes': solicitudes_data,
                'reportes_activos': reportes_data,
                'miembros': miembros_data,
            }
        )


class GestionarRolMiembro(APIView):
    """Permite al administrador cambiar el rol de un miembro (Miembro ↔ Moderador)."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        """Actualiza el rol de un usuario miembro dentro de la comunidad.

        Args:
            request: Petición POST con el nuevo ``rol``.
            pk (int): ID de la relación MiembrosComunidad.

        Returns:
            Response: Confirmación del cambio de rol.
        """
        try:
            miembro = MiembrosComunidad.objects.get(pk=pk)
        except MiembrosComunidad.DoesNotExist:
            return Response({'error': 'El miembro no existe'}, status=status.HTTP_404_NOT_FOUND)

        if miembro.comunidad.creador != request.user:
            return Response({'error': 'No tienes permiso para cambiar roles'}, status=status.HTTP_403_FORBIDDEN)

        nuevo_rol = request.data.get('rol')
        if nuevo_rol not in ['Miembro', 'Moderador']:
            return Response({'error': 'Rol no válido'}, status=status.HTTP_400_BAD_REQUEST)

        miembro.rol = nuevo_rol
        miembro.save()

        Notificacion.objects.create(
            usuario=miembro.usuario,
            tipo='ROL_ACTUALIZADO',
            mensaje=(
                f"¡Miau! Tu rol en '{miembro.comunidad.nombre}' "
                f'ha sido actualizado a {nuevo_rol}.'
            ),
            referencia_comunidad=miembro.comunidad,
        )
        return Response({'mensaje': f'Rol actualizado a {nuevo_rol}'})


class ObtenerRolUsuarioEnComunidad(APIView):
    """Retorna el rol de un usuario específico dentro de una comunidad.

    Útil para mostrar insignias en el perfil del usuario.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        """Consulta el rol de un usuario por su ID en la comunidad especificada.

        Args:
            request: Petición GET con parámetro ``usuario_id``.
            pk (int): ID de la comunidad.

        Returns:
            Response: Rol del usuario ('Administrador', 'Moderador', 'Miembro', 'Visitante').
        """
        usuario_id = request.query_params.get('usuario_id')
        if not usuario_id:
            # Si no se pasa usuario_id, usamos el del usuario autenticado
            usuario_id = request.user.id
            
        try:
            # 1. Verificar si es el creador (tiene prioridad sobre la tabla de miembros)
            comunidad = Comunidad.objects.filter(id=pk).first()
            if not comunidad:
                # Intentar por nombre si pk es un string
                comunidad = Comunidad.objects.filter(nombre=pk).first()
            
            if comunidad and str(comunidad.creador_id) == str(usuario_id):
                return Response({'rol': 'Administrador'})

            # 2. Buscar en la tabla de miembros
            miembro = MiembrosComunidad.objects.filter(
                comunidad=comunidad, usuario_id=usuario_id
            ).first()
            
            if miembro:
                return Response({'rol': miembro.rol})
                
            return Response({'rol': 'Visitante'})
        except Exception as e:
            return Response({'rol': 'Visitante', 'debug': str(e)})

