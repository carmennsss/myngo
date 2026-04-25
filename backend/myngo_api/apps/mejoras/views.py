from datetime import datetime, time
from django.utils import timezone
from django.conf import settings
from django.core.files.storage import default_storage
from django.db.models import Avg, Count
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Voto, Catalogo_mejoras, PeticionMejora, Mejoras_usuario
from .serializers import (
    VotoSerializer, RankingSerializer, EstadoVotoSerializer,
    CatalogoMejorasSerializer, PeticionMejoraSerializer, MejorasUsuarioSerializer
)
from usuarios.models import Usuario, Perfil
from comunidades.models import Comunidad, Miembros_comunidades

class CatalogoMejorasGlobales(generics.ListAPIView):
    serializer_class = CatalogoMejorasSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Catalogo_mejoras.objects.filter(comunidad__isnull=True, esta_activo=True)
class EquipacionMejorasGlobales(APIView):
    permission_classes = [permissions.IsAuthenticated]
    def post(self,request):
        user=request.user
        mejora_id=request.data.get('mejora_id')
        if mejora_id is None:
            return Response({"error": "mejora_id es requerido"}, status=status.HTTP_400_BAD_REQUEST)
        else:
            try:
                mejora_u= Mejoras_usuario.objects.get(mejora_id=mejora_id,usuario=user)
                if mejora_u:
                    mejora_u.esta_equipada=not mejora_u.esta_equipada
                    if mejora_u.esta_equipada:
                        Mejoras_usuario.objects.filter(usuario=user, esta_equipada=True, mejora__tipo=mejora_u.mejora.tipo).exclude(pk=mejora_u.pk).update(esta_equipada=False)
                    mejora_u.save()
                    perfil=Perfil.objects.get(usuario=user)
                    if perfil:
                        if mejora_u.mejora.tipo.casefold()=="avatar":
                            perfil.avatar=mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
                        elif mejora_u.mejora.tipo.casefold()=="fondo":
                            perfil.fondo=mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
                        elif mejora_u.mejora.tipo.casefold()=="marco":
                            perfil.marco=mejora_u.mejora.url_recurso.name if mejora_u.esta_equipada else None
                        elif mejora_u.mejora.tipo.casefold() in ["estilo_post", "estilo post"]:
                            # El estilo del post viene en datos_extra (fondo, borde, etc)
                            perfil.estilo_post = mejora_u.mejora.datos_extra if mejora_u.esta_equipada else None
                        
                        # Guardar cambios
                        perfil.save()
                        if mejora_u.esta_equipada:
                            return Response({"resultado": "La mejora se ha equipado"}, status=status.HTTP_200_OK)
                        else:
                            return Response({"resultado": "La mejora se ha desequipado"}, status=status.HTTP_200_OK)
            except Mejoras_usuario.DoesNotExist:
                return Response({"error": "Mejora no encontrada"}, status=status.HTTP_404_NOT_FOUND)
            except Perfil.DoesNotExist:
                return Response({"error": "Perfil no encontrado"}, status=status.HTTP_404_NOT_FOUND)
class CatalogoMejorasComunidad(generics.ListAPIView):
    serializer_class = CatalogoMejorasSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        comunidad_id = self.kwargs.get('comunidad_id')
        # Si es moderador, ver todo. Si no, solo activos.
        es_mod = Miembros_comunidades.objects.filter(
            usuario=self.request.user, 
            comunidad_id=comunidad_id, 
            rol__in=['Administrador', 'Moderador']
        ).exists()
        
        if es_mod:
            return Catalogo_mejoras.objects.filter(comunidad_id=comunidad_id)
        return Catalogo_mejoras.objects.filter(comunidad_id=comunidad_id, esta_activo=True)

class PeticionMejoraCreate(generics.CreateAPIView):
    serializer_class = PeticionMejoraSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        peticion = serializer.save(usuario=self.request.user)
        # Notificar a los administradores y moderadores de la comunidad
        from notificaciones.models import Notificacion
        mods = Miembros_comunidades.objects.filter(
            comunidad=peticion.comunidad,
            rol__in=['Administrador', 'Moderador']
        )
        for mod in mods:
            Notificacion.objects.create(
                usuario=mod.usuario,
                tipo='NUEVA_PROPUESTA_TIENDA',
                mensaje=f"Hay una nueva propuesta de {peticion.tipo} para revisar en {peticion.comunidad.nombre}.",
                referencia_comunidad=peticion.comunidad,
                referencia_id=peticion.id
            )

class PeticionMejoraModeracionList(generics.ListAPIView):
    serializer_class = PeticionMejoraSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        comunidad_id = self.kwargs.get('comunidad_id')
        # Verificar que sea admin o moderador
        es_mod = Miembros_comunidades.objects.filter(
            usuario=self.request.user, 
            comunidad_id=comunidad_id, 
            rol__in=['Administrador', 'Moderador']
        ).exists()
        
        if not es_mod:
            return PeticionMejora.objects.none()
            
        return PeticionMejora.objects.filter(comunidad_id=comunidad_id, estado='PENDIENTE')

class PeticionMejoraModerar(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            peticion = PeticionMejora.objects.get(pk=pk)
        except PeticionMejora.DoesNotExist:
            return Response({"error": "Petición no encontrada"}, status=status.HTTP_404_NOT_FOUND)

        # Verificar permisos
        es_mod = Miembros_comunidades.objects.filter(
            usuario=request.user, 
            comunidad=peticion.comunidad, 
            rol__in=['Administrador', 'Moderador']
        ).exists()
        
        if not es_mod:
            return Response({"error": "No tienes permisos para moderar en esta comunidad"}, status=status.HTTP_403_FORBIDDEN)

        decision = request.data.get('estado') # 'APROBADO' o 'RECHAZADO'
        precio = int(request.data.get('precio', 0))

        if decision not in ['APROBADO', 'RECHAZADO']:
            return Response({"error": "Estado inválido"}, status=status.HTTP_400_BAD_REQUEST)

        if decision == 'APROBADO' and precio < 100:
             return Response({"error": "El precio para items de comunidad debe ser al menos 100."}, status=status.HTTP_400_BAD_REQUEST)

        peticion.estado = decision
        if decision == 'APROBADO':
            # Crear el item en el catálogo, pero inactivo por defecto
            Catalogo_mejoras.objects.create(
                tipo=peticion.tipo,
                precio_puntos=precio,
                url_recurso=peticion.url_recurso,
                comunidad=peticion.comunidad,
                creador=peticion.usuario,
                esta_activo=True 
            )
        
        peticion.save()

        # Notificar al creador de la propuesta sobre la decisión
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

        return Response({"mensaje": f"Petición {decision.lower()} correctamente"})

class ComprarMejoraView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            mejora = Catalogo_mejoras.objects.get(pk=pk)
        except Catalogo_mejoras.DoesNotExist:
            return Response({"error": "Mejora no encontrada"}, status=status.HTTP_404_NOT_FOUND)

        perfil = request.user.perfil
        if perfil.puntos < mejora.precio_puntos:
            return Response({"error": "No tienes suficientes puntos"}, status=status.HTTP_400_BAD_REQUEST)

        # Verificar si ya la tiene
        if Mejoras_usuario.objects.filter(usuario=request.user, mejora=mejora).exists():
            return Response({"error": "Ya posees esta mejora"}, status=status.HTTP_400_BAD_REQUEST)

        # Restar puntos y otorgar mejora
        perfil.puntos -= mejora.precio_puntos
        perfil.save()

        Mejoras_usuario.objects.create(usuario=request.user, mejora=mejora)

        return Response({"mensaje": "Compra realizada con éxito", "puntos_restantes": perfil.puntos})

class MisMejorasView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        mejoras_usuario = Mejoras_usuario.objects.filter(usuario=request.user)
        serializer = MejorasUsuarioSerializer(mejoras_usuario, many=True)
        return Response(serializer.data)
class GestionCatalogoComunidad(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, comunidad_id):
        # Verificar permisos
        es_mod = Miembros_comunidades.objects.filter(
            usuario=request.user, 
            comunidad_id=comunidad_id, 
            rol__in=['Administrador', 'Moderador']
        ).exists()
        
        if not es_mod:
            return Response({"error": "No tienes permisos"}, status=status.HTTP_403_FORBIDDEN)
            
        items = Catalogo_mejoras.objects.filter(comunidad_id=comunidad_id)
        serializer = CatalogoMejorasSerializer(items, many=True)
        return Response(serializer.data)

    def patch(self, request, comunidad_id):
        item_id = request.data.get('item_id')
        esta_activo = request.data.get('esta_activo')
        precio = request.data.get('precio')

        try:
            item = Catalogo_mejoras.objects.get(pk=item_id, comunidad_id=comunidad_id)
        except Catalogo_mejoras.DoesNotExist:
            return Response({"error": "Item no encontrado"}, status=status.HTTP_404_NOT_FOUND)

        # Verificar permisos
        es_mod = Miembros_comunidades.objects.filter(
            usuario=request.user, 
            comunidad_id=comunidad_id, 
            rol__in=['Administrador', 'Moderador']
        ).exists()
        
        if not es_mod:
            return Response({"error": "No tienes permisos"}, status=status.HTTP_403_FORBIDDEN)

        if esta_activo is not None:
            item.esta_activo = esta_activo
        if precio is not None:
            if int(precio) < 100:
                return Response({"error": "El precio mínimo es 100"}, status=status.HTTP_400_BAD_REQUEST)
            item.precio_puntos = int(precio)
            
        item.save()
        return Response({"mensaje": "Catálogo actualizado", "esta_activo": item.esta_activo, "precio": item.precio_puntos})
    
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
        hoy = timezone.now().date()
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

        # Buscar si ya existe un voto hoy para este RECEPTOR
        voto = Voto.objects.filter(**search_kwargs).first()
        
        # SI EL VOTO ES NUEVO, COMPROBAR LÍMITE DE 50 PERSONAS/COMUNIDADES HOY
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
            "receptor":receptor.id,
            "votante": votante.id,
            "nueva_media": receptor.rating_actual,
        }, status=status.HTTP_200_OK)

class RankingUsuariosView(generics.ListAPIView):
    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        # Evitar colisión con 'rating_medio' property usando un alias temporal
        # También anotamos el conteo para cumplir con el requisito de 10 votos
        return Usuario.objects.annotate(
            rating_db=Avg('votos_recibidos_perfil__estrellas'),
            votos_count=Count('votos_recibidos_perfil')
        ).filter(votos_count__gte=10).order_by('-rating_db')[:10]

    def list(self, request, *args, **kwargs):
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
    serializer_class = RankingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Comunidad.objects.annotate(
            rating_db=Avg('votos_recibidos_comunidad__estrellas'),
            votos_count=Count('votos_recibidos_comunidad')
        ).filter(votos_count__gte=10).order_by('-rating_db')[:10]

    def list(self, request, *args, **kwargs):
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
