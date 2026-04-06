from rest_framework import generics, filters, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from .models import Comunidad, Miembros_comunidades
from usuarios.models import Seguimiento
from .serializers import ComunidadSerializer, MiembroComunidadSerializer
from notificaciones.models import Notificacion
from django.db import models
class ComunidadListCreate(generics.ListCreateAPIView):
    """
    Vista para listar todas las comunidades o crear una nueva.
    Soporta búsqueda por nombre.
    """
    queryset = Comunidad.objects.all().order_by('-fecha_creacion')
    serializer_class = ComunidadSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['nombre', 'descripcion']
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        # El creador es siempre el usuario logueado
        comunidad = serializer.save(creador=self.request.user)
        # El creador se une automáticamente como Administrador
        Miembros_comunidades.objects.create(
            usuario=self.request.user,
            comunidad=comunidad,
            rol="Administrador",
        )

class MisComunidadesList(generics.ListAPIView):
    """
    Lista las comunidades donde el usuario es miembro o creador.
    """
    serializer_class = ComunidadSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        usuario = self.request.user
        return Comunidad.objects.filter(
            models.Q(creador=usuario) | 
            models.Q(miembros_comunidades__usuario=usuario)
        ).distinct().order_by('-fecha_creacion')

class UnirseComunidad(APIView):
    """
    Permite a un usuario unirse a una comunidad pública o solicitar acceso a una privada.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response({"error": "La comunidad no existe"}, status=status.HTTP_404_NOT_FOUND)

        usuario = request.user
        
        # --- REQUISITO DE ACCESO POR RATING ---
        if usuario.rating_medio < comunidad.min_rating_acceso:
            return Response({
                "error": f"¡Miau! No tienes suficiente reputación para unirte. "
                         f"Se requiere un rating de {comunidad.min_rating_acceso}, "
                         f"pero tu media es de {usuario.rating_medio}."
            }, status=status.HTTP_403_FORBIDDEN)
        # ---------------------------------------

        if Miembros_comunidades.objects.filter(usuario=usuario, comunidad=comunidad).exists():
            return Response({"mensaje": "Ya eres miembro de esta comunidad.", "estado": "ACEPTADO"}, status=status.HTTP_200_OK)
        
        # Verificar si ya es miembro o tiene petición
        solicitud = Seguimiento.objects.filter(seguidor=usuario, seguida_comunidad=comunidad).first()
        if solicitud:#Existe solicitud
            if solicitud.estado == "DENEGADO":
                # Si fue rechazado, permitir volver a intentar
                solicitud.estado = "SOLICITUD" if not comunidad.es_publica else "ACEPTADO"
                solicitud.save()
                if solicitud.estado == "ACEPTADO":
                    Miembros_comunidades.objects.get_or_create(usuario=usuario, comunidad=comunidad)
                return Response({"mensaje": "Solicitud reintentada", "estado": solicitud.estado}, status=status.HTTP_200_OK)
            else:
                estado_msg = {
                    "SOLICITUD": "Ya tienes una solicitud pendiente de aprobación.",
                    "ACEPTADO": "Ya eres miembro de esta comunidad.",
                    "DENEGADO": "Tu solicitud ha sido rechazada anteriormente."
                }.get(solicitud.estado, f"Estado actual: {solicitud.estado}")
                
                return Response({
                    "mensaje": estado_msg,
                    "estado": solicitud.estado
                }, status=status.HTTP_200_OK)
        else:#si no hay solicitud
            # Lógica según privacidad
            estado = "ACEPTADO" if comunidad.es_publica else "SOLICITUD"
            if not comunidad.es_publica and estado == "SOLICITUD":#si la comunidad es privada
                solicitud=Seguimiento.objects.create(seguidor=usuario,seguida_comunidad=comunidad,estado=estado)
                # Notificar al administrador (creador)
                Notificacion.objects.create(
                    usuario=comunidad.creador,
                    tipo="PETICION_UNION",
                    mensaje=f"¡Miau! {usuario.nombre_usuario} quiere unirse a tu comunidad '{comunidad.nombre}'.",
                    referencia_usuario=usuario,
                    referencia_comunidad=comunidad,
                    referencia_id=solicitud.id
                )
            else:#si es publica se crea el miembro directamente
                Miembros_comunidades.objects.create(usuario=usuario,comunidad=comunidad)
            mensaje = "Te has unido a la comunidad" if comunidad.es_publica else "Solicitud enviada a la comunidad privada"
            return Response({"mensaje": mensaje, "estado": estado}, status=status.HTTP_201_CREATED)

class ResponderPeticionUnion(APIView):
    """
    Permite al administrador de una comunidad aceptar o rechazar una petición de unión.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            # LAS PETICIONES PENDIENTES ESTÁN EN SEGUIMIENTO
            peticion = Seguimiento.objects.get(pk=pk)
        except Seguimiento.DoesNotExist:
            return Response({"error": "La petición no existe"}, status=status.HTTP_404_NOT_FOUND)

        if peticion.seguida_comunidad.creador != request.user:
            return Response({"error": "No tienes permiso"}, status=status.HTTP_403_FORBIDDEN)

        aceptar = request.data.get('aceptar', False)
        
        if aceptar:
            # 1. Crear el registro oficial de miembro
            Miembros_comunidades.objects.get_or_create(
                usuario=peticion.seguidor,
                comunidad=peticion.seguida_comunidad
            )
            # 2. Notificar y borrar la petición (para no duplicar)
            Notificacion.objects.create(
                usuario=peticion.seguidor,
                tipo="PETICION_ACEPTADA",
                mensaje=f"¡Miau! Has sido aceptado en '{peticion.seguida_comunidad.nombre}'.",
                referencia_comunidad=peticion.seguida_comunidad
            )
            peticion.delete() # Ya es miembro, no hace falta la solicitud
        else:
            # Si se rechaza, la marcamos como DENEGADO en Seguimiento
            peticion.estado = "DENEGADO"
            peticion.save()
            
        return Response({"mensaje": "Respuesta enviada"}, status=status.HTTP_200_OK)

class ComunidadDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Comunidad.objects.all()
    serializer_class = ComunidadSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_destroy(self, instance):
        if instance.creador != self.request.user:
            return Response({"error": "Solo el creador puede borrar la comunidad"}, status=403)
        instance.delete()
        return Response(status=204)

class AdminDashboardView(APIView):
    """
    Dashboard centralizado para el administrador de la comunidad.
    Retorna solicitudes de unión y reportes de contenido pendientes.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            comunidad = Comunidad.objects.get(pk=pk)
        except Comunidad.DoesNotExist:
            return Response({"error": "Comunidad no encontrada"}, status=404)

        if comunidad.creador != request.user and not Miembros_comunidades.objects.filter(
            usuario=request.user, comunidad=comunidad, rol__in=['Administrador', 'Moderador']
        ).exists():
            return Response({"error": "No tienes permisos de gestión en esta comunidad"}, status=403)

        # 1. Solicitudes de unión pendientes
        solicitudes = Seguimiento.objects.filter(seguida_comunidad=comunidad, estado='SOLICITUD')
        solicitudes_data = [{
            'id': s.id,
            'usuario_nombre': s.seguidor.nombre_usuario,
            'usuario_id': s.seguidor.id,
            'fecha': s.fecha_seguimiento
        } for s in solicitudes]

        # 2. Reportes pendientes
        from contenido.models import Reporte
        from contenido.serializers import ReporteSerializer
        reportes = Reporte.objects.filter(comunidad=comunidad, estado='PENDIENTE')
        reportes_data = ReporteSerializer(reportes, many=True, context={'request': request}).data

        # 3. Miembros de la comunidad (para gestión de roles)
        miembros = Miembros_comunidades.objects.filter(comunidad=comunidad).select_related('usuario').order_by('rol', '-fecha_union')
        miembros_data = [{
            'id': m.id,
            'usuario_id': m.usuario.id,
            'usuario_nombre': m.usuario.nombre_usuario,
            'usuario_avatar': m.usuario.url_avatar if m.usuario.url_avatar else None,
            'rol': m.rol,
            'fecha_union': m.fecha_union
        } for m in miembros]

        return Response({
            'comunidad_nombre': comunidad.nombre,
            'solicitudes_pendientes': solicitudes_data,
            'reportes_activos': reportes_data,
            'miembros': miembros_data
        })

class GestionarRolMiembro(APIView):
    """
    Permite al administrador cambiar el rol de un miembro (Miembro <-> Moderador).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            miembro = Miembros_comunidades.objects.get(pk=pk)
        except Miembros_comunidades.DoesNotExist:
            return Response({"error": "El miembro no existe"}, status=404)

        if miembro.comunidad.creador != request.user:
            return Response({"error": "No tienes permiso para cambiar roles"}, status=403)

        nuevo_rol = request.data.get('rol')
        if nuevo_rol not in ['Miembro', 'Moderador']:
            return Response({"error": "Rol no válido"}, status=400)

        miembro.rol = nuevo_rol
        miembro.save()

        # Notificar al usuario
        Notificacion.objects.create(
            usuario=miembro.usuario,
            tipo="ROL_ACTUALIZADO",
            mensaje=f"¡Miau! Tu rol en '{miembro.comunidad.nombre}' ha sido actualizado a {nuevo_rol}.",
            referencia_comunidad=miembro.comunidad
        )

        return Response({"mensaje": f"Rol actualizado a {nuevo_rol}"})

class ObtenerRolUsuarioEnComunidad(APIView):
    """
    Retorna el rol de un usuario específico dentro de una comunidad.
    Útil para mostrar insignias en el perfil.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        usuario_id = request.query_params.get('usuario_id')
        if not usuario_id:
            return Response({"error": "usuario_id es requerido"}, status=400)
            
        try:
            miembro = Miembros_comunidades.objects.filter(comunidad_id=pk, usuario_id=usuario_id).first()
            if miembro:
                return Response({"rol": miembro.rol})
            
            # Si es el creador pero no está en la tabla (raro pero posible)
            comunidad = Comunidad.objects.get(id=pk)
            if str(comunidad.creador_id) == str(usuario_id):
                return Response({"rol": "Administrador"})
                
            return Response({"rol": "Visitante"})
        except Exception:
            return Response({"rol": "Visitante"})

