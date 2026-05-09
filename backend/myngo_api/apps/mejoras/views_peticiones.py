"""Vistas de peticiones y propuestas de mejoras por parte de los usuarios."""

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import MiembrosComunidad
from .models import CatalogoMejoras, PeticionMejora
from .serializers import PeticionMejoraSerializer


class PeticionMejoraCreate(generics.CreateAPIView):
    """Permite a un usuario enviar una propuesta de mejora para una comunidad.

    Al crearse, notifica a los moderadores de dicha comunidad.
    """

    serializer_class = PeticionMejoraSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        """Guarda la petición. Si es el creador, aprueba directamente. Si no, notifica a moderadores.

        Args:
            serializer: Serializador con los datos de la propuesta.
        """
        user = self.request.user
        peticion = serializer.save(usuario=user)
        
        # Si el usuario es el creador, aprobamos automáticamente y creamos el item
        if peticion.comunidad.creador == user:
            peticion.estado = 'APROBADO'
            peticion.save()
            
            CatalogoMejoras.objects.create(
                tipo=peticion.tipo,
                precio_puntos=peticion.precio_sugerido or 0,
                url_recurso=peticion.url_recurso,
                comunidad=peticion.comunidad,
                creador=user,
                esta_activo=True
            )
            return # No enviamos notificaciones si es el propio creador quien añade fondos

        from notificaciones.models import Notificacion
        
        # Obtener moderadores y administradores de la tabla de membresía
        mods = MiembrosComunidad.objects.filter(
            comunidad=peticion.comunidad,
            rol__in=['Administrador', 'Moderador']
        ).select_related('usuario')
        
        destinatarios = {mod.usuario for mod in mods}
        
        # Incluir también al creador de la comunidad si existe
        if peticion.comunidad.creador:
            destinatarios.add(peticion.comunidad.creador)
            
        for usuario in destinatarios:
            if usuario == user: continue # No notificarse a uno mismo
            Notificacion.objects.create(
                usuario=usuario,
                tipo='NUEVA_PROPUESTA_TIENDA',
                mensaje=(
                    f"Hay una nueva propuesta de {peticion.tipo} para revisar "
                    f"en {peticion.comunidad.nombre}."
                ),
                referencia_comunidad=peticion.comunidad,
                referencia_id=peticion.id
            )


class PeticionMejoraModeracionList(generics.ListAPIView):
    """Lista las peticiones de mejora pendientes de una comunidad (solo gestores)."""

    serializer_class = PeticionMejoraSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Obtiene las peticiones pendientes si el usuario es moderador o creador.

        Returns:
            QuerySet: Peticiones en estado 'PENDIENTE'.
        """
        comunidad_id = self.kwargs.get('comunidad_id')
        
        # Verificar si es el creador directo
        from comunidades.models import Comunidad
        try:
            comunidad = Comunidad.objects.get(id=comunidad_id)
            es_creador = comunidad.creador == self.request.user
        except Comunidad.DoesNotExist:
            es_creador = False

        # Verificar si es moderador en la tabla de membresía
        es_mod = MiembrosComunidad.objects.filter(
            usuario=self.request.user,
            comunidad_id=comunidad_id,
            rol__in=['Administrador', 'Moderador']
        ).exists()

        if not es_mod and not es_creador:
            return PeticionMejora.objects.none()

        return PeticionMejora.objects.filter(comunidad_id=comunidad_id, estado='PENDIENTE')


class PeticionMejoraModerar(APIView):
    """Permite a un moderador aprobar o rechazar una propuesta de mejora.

    Si se aprueba, se crea automáticamente un item activo en el catálogo.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        """Registra la decisión del moderador y notifica al proponente.

        Args:
            request: Datos con 'estado' ('APROBADO'/'RECHAZADO') y 'precio'.
            pk (int): ID de la petición.

        Returns:
            Response: Resultado de la moderación.
        """
        try:
            peticion = PeticionMejora.objects.get(pk=pk)
        except PeticionMejora.DoesNotExist:
            return Response({'error': 'Petición no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        # Verificar permisos (Moderador o Creador)
        es_creador = peticion.comunidad.creador == request.user
        es_mod = MiembrosComunidad.objects.filter(
            usuario=request.user,
            comunidad=peticion.comunidad,
            rol__in=['Administrador', 'Moderador']
        ).exists()

        if not es_mod and not es_creador:
            return Response(
                {'error': 'No tienes permisos para moderar en esta comunidad'},
                status=status.HTTP_403_FORBIDDEN
            )

        decision = request.data.get('estado')
        precio = int(request.data.get('precio', 0))

        if decision not in ['APROBADO', 'RECHAZADO']:
            return Response({'error': 'Estado inválido'}, status=status.HTTP_400_BAD_REQUEST)

        if decision == 'APROBADO' and precio < 100:
            return Response(
                {'error': 'El precio para items de comunidad debe ser al menos 100.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        peticion.estado = decision
        if decision == 'APROBADO':
            CatalogoMejoras.objects.create(
                tipo=peticion.tipo,
                precio_puntos=precio,
                url_recurso=peticion.url_recurso,
                comunidad=peticion.comunidad,
                creador=peticion.usuario,
                esta_activo=True
            )

        peticion.save()

        from notificaciones.models import Notificacion
        tipo_notif = 'PROPUESTA_TIENDA_ACEPTADA' if decision == 'APROBADO' else 'PROPUESTA_TIENDA_RECHAZADA'
        estado_text = "aceptada" if decision == 'APROBADO' else "rechazada"

        Notificacion.objects.create(
            usuario=peticion.usuario,
            tipo=tipo_notif,
            mensaje=f"Tu propuesta de {peticion.tipo} ha sido {estado_text} en {peticion.comunidad.nombre}.",
            referencia_comunidad=peticion.comunidad,
            referencia_id=peticion.id
        )

        return Response({'mensaje': f"Petición {decision.lower()} correctamente"})
