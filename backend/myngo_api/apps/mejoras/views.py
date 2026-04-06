from datetime import datetime, time
from django.utils import timezone
from django.db.models import Avg
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Voto,Catalogo_mejoras
from .serializers import VotoSerializer, RankingSerializer, EstadoVotoSerializer,CatalogoMejorasSerializer
from usuarios.models import Usuario
from comunidades.models import Comunidad

class CatalogoMejoras(generics.ListAPIView):
    serializer_class = CatalogoMejorasSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        tipo=self.kwargs.get('tipo')
        mejoras=Catalogo_mejoras.objects.filter(tipo=tipo)
        return mejoras
    
class VotoAPIView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request):
        if request.user.is_authenticated:
            votante = request.user
        else:
            # Fallback para usuarios no logueados (usar primer usuario como invitado)
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
                return Response({"error": "Usuario no encontrado."}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                filter_kwargs['receptor_comunidad'] = receptor
                count_filter['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({"error": "Comunidad no encontrada."}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({"error": "Falta receptor."}, status=status.HTTP_400_BAD_REQUEST)

        # Buscar voto de hoy
        voto_hoy = Voto.objects.filter(**filter_kwargs).first()
        
        # Calcular total de votos históricos para el requisito de 10
        total_votos = Voto.objects.filter(**count_filter).count()

        # Calcular segundos hasta medianoche
        ahora = timezone.now()
        mañana = datetime.combine(ahora.date() + timezone.timedelta(days=1), time.min)
        mañana = timezone.make_aware(mañana, ahora.tzinfo)
        segundos_restantes = int((mañana - ahora).total_seconds())

        data = {
            "ha_votado_hoy": voto_hoy is not None,
            "puntuacion_actual": voto_hoy.estrellas if voto_hoy else None,
            "total_votos": total_votos,
            "segundos_hasta_medianoche": segundos_restantes
        }

        return Response(data)

    def post(self, request):
        if request.user and request.user.is_authenticated:
            votante = request.user
        else:
            # Fallback para pruebas anónimas
            votante = Usuario.objects.filter(pk=1).first() or Usuario.objects.first()

        receptor_usuario_id = request.data.get('receptor_usuario')
        receptor_comunidad_id = request.data.get('receptor_comunidad')
        estrellas = request.data.get('estrellas')

        if not estrellas or not (0 <= int(estrellas) <= 5):
            return Response({"error": "La puntuación debe estar entre 0 y 5."}, 
                            status=status.HTTP_400_BAD_REQUEST)

        hoy = timezone.now().date()
        receptor = None
        
        # Base de búsqueda para evitar duplicados hoy
        search_kwargs = {'votante': votante, 'fecha_voto__date': hoy}
        create_kwargs = {'votante': votante, 'estrellas': estrellas}

        if receptor_usuario_id:
            try:
                receptor = Usuario.objects.get(pk=receptor_usuario_id)
                search_kwargs['receptor_usuario'] = receptor
                create_kwargs['receptor_usuario'] = receptor
            except Usuario.DoesNotExist:
                return Response({"error": "Usuario no encontrado."}, status=status.HTTP_404_NOT_FOUND)
        elif receptor_comunidad_id:
            try:
                receptor = Comunidad.objects.get(pk=receptor_comunidad_id)
                search_kwargs['receptor_comunidad'] = receptor
                create_kwargs['receptor_comunidad'] = receptor
            except Comunidad.DoesNotExist:
                return Response({"error": "Comunidad no encontrada."}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({"error": "Debes especificar un receptor (usuario o comunidad)."}, 
                            status=status.HTTP_400_BAD_REQUEST)

        # Buscar si ya existe un voto hoy
        voto = Voto.objects.filter(**search_kwargs).first()
        
        if voto:
            voto.estrellas = estrellas
            voto.save()
            mensaje = "Voto actualizado correctamente."
        else:
            voto = Voto.objects.create(**create_kwargs)
            mensaje = "Voto registrado correctamente."

        return Response({"mensaje": mensaje, "estrellas": voto.estrellas}, status=status.HTTP_200_OK)

class RankingUsuariosView(generics.ListAPIView):
    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        # Query optimizada: Media histórica
        return Usuario.objects.annotate(
            rating_medio=Avg('votos_recibidos_perfil__estrellas')
        ).filter(rating_medio__isnull=False).order_by('-rating_medio')[:10]
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        data = []
        for u in queryset:
            data.append({
                "id": u.id,
                "nombre": u.nombre_usuario,
                "rating_medio": round(float(u.rating_medio), 2),
                "url_foto": u.perfil.url_avatar if hasattr(u, 'perfil') else None
            })
        return Response(data)

class RankingComunidadesView(generics.ListAPIView):
    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Comunidad.objects.annotate(
            rating_medio=Avg('votos_recibidos_comunidad__estrellas')
        ).filter(rating_medio__isnull=False).order_by('-rating_medio')[:10]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        data = []
        for c in queryset:
            data.append({
                "id": c.id,
                "nombre": c.nombre,
                "rating_medio": round(float(c.rating_medio), 2),
                "url_foto": c.url_portada.url if c.url_portada else None
            })
        return Response(data)
