from rest_framework import generics, filters, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .models import Comunidad, Miembros_comunidades
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
            estado_peticion="ACEPTADO"
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
            models.Q(miembros_comunidades__usuario=usuario, miembros_comunidades__estado_peticion="ACEPTADO")
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
        
        # Verificar si ya es miembro o tiene petición
        miembro_existente = Miembros_comunidades.objects.filter(usuario=usuario, comunidad=comunidad).first()
        if miembro_existente:
            if miembro_existente.estado_peticion == "RECHAZADO":
                # Si fue rechazado, permitir volver a intentar
                miembro_existente.estado_peticion = "PENDIENTE" if not comunidad.es_publica else "ACEPTADO"
                miembro_existente.save()
            else:
                estado_msg = {
                    "PENDIENTE": "Ya tienes una solicitud pendiente de aprobación.",
                    "ACEPTADO": "Ya eres miembro de esta comunidad.",
                    "RECHAZADO": "Tu solicitud ha sido rechazada anteriormente."
                }.get(miembro_existente.estado_peticion, f"Estado actual: {miembro_existente.estado_peticion}")
                
                return Response({
                    "mensaje": estado_msg,
                    "estado": miembro_existente.estado_peticion
                }, status=status.HTTP_200_OK)
        else:
            # Lógica según privacidad
            estado = "ACEPTADO" if comunidad.es_publica else "PENDIENTE"
            miembro_existente = Miembros_comunidades.objects.create(
                usuario=usuario,
                comunidad=comunidad,
                estado_peticion=estado
            )

        if not comunidad.es_publica and miembro_existente.estado_peticion == "PENDIENTE":
            # Notificar al administrador (creador)
            Notificacion.objects.create(
                usuario=comunidad.creador,
                tipo="PETICION_UNION",
                mensaje=f"¡Miau! {usuario.nombre_usuario} quiere unirse a tu comunidad '{comunidad.nombre}'.",
                referencia_usuario=usuario,
                referencia_comunidad=comunidad,
                referencia_id=miembro_existente.id
            )

        mensaje = "Te has unido a la comunidad" if comunidad.es_publica else "Solicitud enviada a la comunidad privada"
        return Response({"mensaje": mensaje, "estado": miembro_existente.estado_peticion}, status=status.HTTP_201_CREATED)

class ResponderPeticionUnion(APIView):
    """
    Permite al administrador de una comunidad aceptar o rechazar una petición de unión.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            peticion = Miembros_comunidades.objects.get(pk=pk)
        except Miembros_comunidades.DoesNotExist:
            return Response({"error": "La petición no existe"}, status=status.HTTP_404_NOT_FOUND)

        # Verificar que el usuario actual es el creador de la comunidad
        if peticion.comunidad.creador != request.user:
            return Response({"error": "No tienes permiso para responder a esta petición"}, status=status.HTTP_403_FORBIDDEN)

        aceptar = request.data.get('aceptar', False)
        
        if aceptar:
            peticion.estado_peticion = "ACEPTADO"
            peticion.save()
            # Notificar al usuario que su petición fue aceptada
            Notificacion.objects.create(
                usuario=peticion.usuario,
                tipo="PETICION_ACEPTADA",
                mensaje=f"¡Miau! Has sido aceptado en la comunidad '{peticion.comunidad.nombre}'.",
                referencia_comunidad=peticion.comunidad
            )
        else:
            peticion.estado_peticion = "RECHAZADO"
            peticion.save()
            # Notificar al usuario que su petición fue rechazada
            Notificacion.objects.create(
                usuario=peticion.usuario,
                tipo="PETICION_RECHAZADA",
                mensaje=f"Lo sentimos, tu solicitud para unirte a '{peticion.comunidad.nombre}' ha sido rechazada.",
                referencia_comunidad=peticion.comunidad
            )

        # Marcar la notificación original como leída (si existe)
        Notificacion.objects.filter(
            usuario=request.user, 
            tipo="PETICION_UNION", 
            referencia_id=peticion.id
        ).update(leida=True)

        return Response({"mensaje": "Respuesta enviada"}, status=status.HTTP_200_OK)
