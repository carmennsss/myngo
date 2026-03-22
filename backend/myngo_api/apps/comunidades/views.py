from rest_framework import generics, filters, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
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
    permission_classes = [IsAuthenticated]

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
                solicitud=Seguimiento.objects.create(seguidor=usuario,seguido_comunidad=comunidad,estado=estado)
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
