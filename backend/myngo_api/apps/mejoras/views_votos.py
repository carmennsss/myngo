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

    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request):
        """Consulta el estado del voto del usuario actual hacia un receptor específico.

        Args:
            request: Petición con query params 'receptor_usuario' o 'receptor_comunidad'.

        Returns:
            Response: Estado del voto, puntuación, total de votos y tiempo hasta reseteo.
        """
        if request.user.is_authenticated:
            votante = request.user
        else:
            votante = Usuario.objects.filter(pk=1).first() or Usuario.objects.first()

        receptor_usuario_id = request.query_params.get('receptor_usuario')
        receptor_comunidad_id = request.query_params.get('receptor_comunidad')

        hoy = timezone.now().date()
        filter_kwargs = {'votante': votante, 'fecha_voto__date': hoy}
        count_filter = {}

        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                filter_kwargs['receptor_usuario'] = receptor
                count_filter['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({'error': 'Usuario no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                filter_kwargs['receptor_comunidad'] = receptor
                count_filter['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({'error': 'Comunidad no encontrada.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Falta receptor.'}, status=status.HTTP_400_BAD_REQUEST)

        voto_hoy = Voto.objects.filter(**filter_kwargs).first()
        total_votos = Voto.objects.filter(**count_filter).count()

        ahora = timezone.now()
        mañana = datetime.combine(ahora.date() + timezone.timedelta(days=1), time.min)
        mañana = timezone.make_aware(mañana, ahora.tzinfo)
        segundos_restantes = int((mañana - ahora).total_seconds())

        return Response({
            "ha_votado_hoy": voto_hoy is not None,
            "puntuacion_actual": voto_hoy.estrellas if voto_hoy else None,
            "total_votos": total_votos,
            "segundos_hasta_medianoche": segundos_restantes
        })

    def post(self, request):
        """Registra o actualiza un voto de estrellas.

        Args:
            request: Datos con 'receptor_usuario' o 'receptor_comunidad' y 'estrellas'.

        Returns:
            Response: Confirmación del voto y nueva media del receptor.
        """
        if request.user and request.user.is_authenticated:
            votante = request.user
        else:
            votante = Usuario.objects.filter(pk=1).first() or Usuario.objects.first()

        receptor_usuario_id = request.data.get('receptor_usuario')
        receptor_comunidad_id = request.data.get('receptor_comunidad')
        estrellas = request.data.get('estrellas')

        if not estrellas or not (0 <= int(estrellas) <= 5):
            return Response(
                {'error': 'La puntuación debe estar entre 0 y 5.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        hoy = timezone.now().date()
        search_kwargs = {'votante': votante, 'fecha_voto__date': hoy}
        create_kwargs = {'votante': votante, 'estrellas': estrellas}

        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                search_kwargs['receptor_usuario'] = receptor
                create_kwargs['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({'error': 'Usuario no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                search_kwargs['receptor_comunidad'] = receptor
                create_kwargs['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({'error': 'Comunidad no encontrada.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response(
                {'error': 'Debes especificar un receptor (usuario o comunidad).'},
                status=status.HTTP_400_BAD_REQUEST
            )

        voto = Voto.objects.filter(**search_kwargs).first()

        if not voto:
            votos_hoy_count = Voto.objects.filter(votante=votante, fecha_voto__date=hoy).count()
            if votos_hoy_count >= 50:
                return Response({
                    "error": "Has alcanzado el límite de 50 votos diarios. ¡Vuelve mañana! 🐾"
                }, status=status.HTTP_400_BAD_REQUEST)

        if voto:
            voto.estrellas = estrellas
            voto.save()
            mensaje = "Voto actualizado correctamente."
        else:
            voto = Voto.objects.create(**create_kwargs)
            mensaje = "Voto registrado correctamente."

        receptor.refresh_from_db()

        return Response({
            "mensaje": mensaje,
            "receptor": receptor.id,
            "votante": votante.id,
            "nueva_media": receptor.rating_actual,
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
