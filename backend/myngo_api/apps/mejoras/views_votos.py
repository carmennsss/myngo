"""Vistas para el sistema de votos y rankings de reputación."""

from datetime import datetime, time
from django.core.files.storage import default_storage
from django.db.models import Avg, Count
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from comunidades.models import Comunidad
from usuarios.models import Usuario
from .models import Voto
from .serializers import RankingSerializer


class VotoAPIView(APIView):
    """Gestión de votos diarios para usuarios y comunidades.

    Permite consultar si un usuario ha votado hoy a un receptor y enviar un nuevo voto
    (máximo 50 votos diarios por usuario).
    """

    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get(self, request):
        """Consulta el estado del voto del usuario actual hacia un receptor específico.

        Implementa un cooldown de 24 horas desde el último voto emitido por el usuario
        hacia este receptor específico.
        """
        votante = request.user if request.user.is_authenticated else None
        
        receptor_usuario_id = request.query_params.get('receptor_usuario')
        receptor_comunidad_id = request.query_params.get('receptor_comunidad')

        count_filter = {}
        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                count_filter['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({'error': 'Usuario no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                count_filter['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({'error': 'Comunidad no encontrada.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Falta receptor.'}, status=status.HTTP_400_BAD_REQUEST)

        total_votos = Voto.objects.filter(**count_filter).count()

        if not votante:
            return Response({
                "ha_votado_hoy": False,
                "puntuacion_actual": None,
                "total_votos": total_votos,
                "segundos_hasta_reset": 0
            })

        ahora = timezone.now()
        manana = ahora.replace(hour=0, minute=0, second=0, microsecond=0) + timezone.timedelta(days=1)
        segundos_hasta_medianoche = int((manana - ahora).total_seconds())

        ultimo_voto = Voto.objects.filter(
            votante=votante, 
            fecha_voto__date=ahora.date(),
            **count_filter
        ).first()
        
        ha_votado = False
        puntuacion = None

        if ultimo_voto:
            ha_votado = True
            puntuacion = ultimo_voto.estrellas

        return Response({
            "ha_votado_hoy": ha_votado,
            "puntuacion_actual": puntuacion,
            "total_votos": total_votos,
            "segundos_hasta_medianoche": segundos_hasta_medianoche
        })

    def post(self, request):
        """Registra o actualiza un voto de estrellas con cooldown de 24h."""
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Debes iniciar sesión para votar.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        votante = request.user
        receptor_usuario_id = request.data.get('receptor_usuario')
        receptor_comunidad_id = request.data.get('receptor_comunidad')
        estrellas = request.data.get('estrellas')

        if estrellas is None or not (0 <= int(estrellas) <= 5):
            return Response(
                {'error': 'La puntuación debe estar entre 0 y 5.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        search_kwargs = {'votante': votante}
        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                search_kwargs['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({'error': 'Usuario no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                search_kwargs['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({'error': 'Comunidad no encontrada.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Falta receptor.'}, status=status.HTTP_400_BAD_REQUEST)

        ahora = timezone.now()
        voto_hoy = Voto.objects.filter(fecha_voto__date=ahora.date(), **search_kwargs).first()
        
        if voto_hoy:
            # Actualizar voto existente hoy
            voto_hoy.estrellas = estrellas
            voto_hoy.save()
            mensaje = "Voto actualizado correctamente."
        else:
            # Límite global de 50 votos nuevos por día
            votos_hoy_total = Voto.objects.filter(
                votante=votante, 
                fecha_voto__date=ahora.date()
            ).count()
            
            if votos_hoy_total >= 50:
                return Response({
                    "error": "Has alcanzado el límite de 50 votos diarios. 🐾"
                }, status=status.HTTP_400_BAD_REQUEST)

            # Crear nuevo voto
            search_kwargs['estrellas'] = estrellas
            Voto.objects.create(**search_kwargs)
            mensaje = "Voto registrado correctamente."

        receptor.refresh_from_db()
        return Response({
            "mensaje": mensaje,
            "receptor": receptor.id,
            "votante": votante.id,
            "nueva_media": receptor.rating_actual,
        }, status=status.HTTP_200_OK)

    def delete(self, request):
        """Elimina un voto registrado hoy para un receptor.

        Args:
            request: Petición con query params 'receptor_usuario' o 'receptor_comunidad'.

        Returns:
            Response: Confirmación de eliminación y nueva media.
        """
        if not request.user or not request.user.is_authenticated:
            return Response({'error': 'Debes iniciar sesión para votar.'}, status=status.HTTP_401_UNAUTHORIZED)
        
        votante = request.user

        receptor_usuario_id = request.query_params.get('receptor_usuario')
        receptor_comunidad_id = request.query_params.get('receptor_comunidad')

        hoy = timezone.now().date()
        filter_kwargs = {'votante': votante, 'fecha_voto__date': hoy}

        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                filter_kwargs['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({'error': 'Usuario no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                filter_kwargs['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({'error': 'Comunidad no encontrada.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Falta receptor.'}, status=status.HTTP_400_BAD_REQUEST)

        voto = Voto.objects.filter(**filter_kwargs).first()
        if not voto:
            return Response({'error': 'No has votado hoy a este receptor.'}, status=status.HTTP_404_NOT_FOUND)

        voto.delete()
        receptor.refresh_from_db()

        return Response({
            "mensaje": "Voto eliminado correctamente.",
            "nueva_media": receptor.rating_actual
        }, status=status.HTTP_200_OK)


class RankingUsuariosView(generics.ListAPIView):
    """Lista los 10 usuarios con mejor reputación (mínimo 10 votos recibidos)."""

    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Obtiene los 10 mejores perfiles anotados con su media de rating.

        Returns:
            QuerySet: Usuarios con mejor reputación.
        """
        return Usuario.objects.annotate(
            rating_db=Avg('votos_recibidos_perfil__estrellas'),
            votos_count=Count('votos_recibidos_perfil')
        ).filter(votos_count__gte=10).order_by('-rating_db')[:10]

    def list(self, request, *args, **kwargs):
        """Retorna el ranking formateado con URLs de avatares resueltas.

        Args:
            request: Petición GET.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Lista de usuarios del ranking.
        """
        queryset = self.get_queryset()
        data = []
        for u in queryset:
            url_foto = None
            if hasattr(u, 'perfil') and u.perfil.avatar:
                if u.perfil.avatar.startswith('http'):
                    url_foto = u.perfil.avatar
                else:
                    url_foto = default_storage.url(u.perfil.avatar.lstrip('/'))

            data.append({
                "id": u.id,
                "nombre": u.nombre_usuario,
                "rating_medio": round(float(u.rating_db), 2) if u.rating_db else 0.0,
                "url_foto": url_foto
            })
        return Response(data)


class RankingComunidadesView(generics.ListAPIView):
    """Lista las 10 comunidades con mejor reputación (mínimo 10 votos recibidos)."""

    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Obtiene las 10 mejores comunidades anotadas con su media de rating.

        Returns:
            QuerySet: Comunidades con mejor reputación.
        """
        return Comunidad.objects.annotate(
            rating_db=Avg('votos_recibidos_comunidad__estrellas'),
            votos_count=Count('votos_recibidos_comunidad')
        ).filter(votos_count__gte=10).order_by('-rating_db')[:10]

    def list(self, request, *args, **kwargs):
        """Retorna el ranking de comunidades formateado.

        Args:
            request: Petición GET.
            *args: Argumentos adicionales.
            **kwargs: Argumentos de palabra clave.

        Returns:
            Response: Lista de comunidades del ranking.
        """
        queryset = self.get_queryset()
        data = []
        for c in queryset:
            data.append({
                "id": c.id,
                "nombre": c.nombre,
                "rating_medio": round(float(c.rating_db), 2) if c.rating_db else 0.0,
                "url_foto": c.url_portada.url if c.url_portada else None
            })
        return Response(data)
