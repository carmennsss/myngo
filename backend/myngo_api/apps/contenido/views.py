from rest_framework import generics, filters, permissions, viewsets, pagination, serializers
from .models import Publicacion, Imagenes_galeria, Coleccion, Reporte, Comentario, Me_gustas
from .serializers import PublicacionSerializer, ImagenGaleriaSerializer, ColeccionSerializer, ReporteSerializer, ComentarioSerializer
from rest_framework.decorators import action
from .permissions import IsAuthorOrAdmin
from comunidades.models import Comunidad
from rest_framework.views import APIView,status
from rest_framework.response import Response
from core import settings
from django.http import JsonResponse
from django.core.files.storage import default_storage
from usuarios.models import Seguimiento, Usuario, Perfil
from django.db.models import Q
from comunidades.models import Miembros_comunidades
from notificaciones.models import Notificacion

class GaleriaPagination(pagination.LimitOffsetPagination):
    default_limit = 20
    max_limit = 100

class DocumentosUtilidad(APIView):
    """
    Endpoint para obtener las rutas de documentos legales de Myngo.
    """
    def get(self, request):
        nombre_archivo = "legal/Reglas_comunidad.pdf"
        
        # Al tener querystring_auth=True en settings, esto genera 
        # automáticamente la URL con el token de seguridad de Amazon
        try:
            url_s3 = default_storage.url(nombre_archivo)
            return Response({"reglas_comunidad": url_s3}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PublicacionList(generics.ListAPIView):
    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['fecha_creacion']

    def get_queryset(self):
        user = self.request.user #obtengo usuario
        comunidad_id = self.request.query_params.get('comunidad_id') #obtengo comunidad
        perfil_id=self.request.query_params.get('perfil_id') #obtengo perfil

        # Filtro base: Solo válidos por IA para usuarios normales
        # (Los admins podrían ver todo para moderar)
        qs = Publicacion.objects.filter(es_valido_ia=True)
        
        if comunidad_id:#si he recibido una comunidad
            try:
                comunidad = Comunidad.objects.get(id=comunidad_id)#extraigo comunidad
            except Comunidad.DoesNotExist:
                return Publicacion.objects.none()

            if not comunidad.es_publica:#si no es publica
                if user.is_authenticated:
                    # Verificar membresía aceptada
                    es_miembro = Seguimiento.objects.filter(
                        seguidor=user, 
                        seguida_comunidad=comunidad, 
                        estado='ACEPTADO'
                    ).exists()
                    if not es_miembro and comunidad.creador != user:#si el creador no es el usuario y no es miembro
                        return Publicacion.objects.none()
                else:
                    # Usuario anónimo no puede ver comunidad privada
                    return Publicacion.objects.none()
            
            return qs.filter(comunidad_id=comunidad_id).order_by('-fecha_creacion') #retorna publicaciones
        if perfil_id: #si he recibido perfil (que en frontend es el id del usuario)
            try:
                perfil=Perfil.objects.get(id=perfil_id)#extraigo perfil
            except Perfil.DoesNotExist:
                return Publicacion.objects.none()
            
            if not perfil.es_publico:#si no es publico
                if user.is_authenticated:
                    #compruebo amistad
                    es_miembro = Seguimiento.objects.filter(
                        seguidor=user, 
                        seguido_usuario=perfil.usuario, 
                        estado='ACEPTADO'
                    ).exists()
                    if not es_miembro and perfil.usuario != user:#si no es amigo y no es el propietario
                        return Publicacion.objects.none()
                else:
                    return Publicacion.objects.none()
            return qs.filter(autor=perfil.usuario,comunidad__isnull=True).order_by('-fecha_creacion')#devuelve publicaciones
        # Feed Global: últimas publicaciones de comunidades públicas
        return qs.filter(comunidad__es_publica=True).order_by('-fecha_creacion')

class PublicacionCreate(generics.CreateAPIView):
    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        archivo = request.FILES.get('url_archivo_s3')
        imagen_galeria = None

        # 1. Si viene imagen, crearla primero en Imagenes_galeria
        if archivo:
            try:
                imagen_galeria = Imagenes_galeria.objects.create(
                    propietario=request.user,
                    url_s3=archivo,
                    comunidad_id=request.data.get('comunidad') or None,
                    relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0)),
                    etiquetas=request.data.get('etiquetas', ''),
                )
            except Exception as e:
                return Response({'error': f'Error al guardar imagen: {e}'}, status=400)

        # 2. Crear la publicación con la FK a la imagen
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(autor=request.user, imagen=imagen_galeria)
        return Response(serializer.data, status=201)
class PublicacionDelete(generics.DestroyAPIView):
    serializer_class= PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        titulo_seguro = instance.titulo or "Sin título"
        
        # Si el que borra no es el autor (es admin), notificar
        if instance.autor != request.user:
            titulo_seguro = instance.titulo or "Sin título"
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo="CONTENIDO_BORRADO",
                mensaje=f"Tu post '{titulo_seguro[:20]}...' ha sido borrado por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.comunidad
            )
        
        # Auto-resolver reportes pendientes
        Reporte.objects.filter(tipo_objeto='POST', objeto_id=instance.id, estado='PENDIENTE').update(estado='RESUELTO')
            
        if instance.imagen:
            instance.imagen.delete()
        instance.delete()
        return Response({"mensaje": "Publicación eliminada correctamente"}, status=status.HTTP_200_OK)
class PublicacionDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Publicacion.objects.all()
    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        titulo_seguro = instance.titulo or "Sin título"
        
        # Si el que borra no es el autor (es admin), notificar
        if instance.autor != request.user:
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo="CONTENIDO_BORRADO",
                mensaje=f"Tu post '{titulo_seguro[:20]}...' ha sido borrado por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.comunidad
            )
        
        # Auto-resolver reportes pendientes
        Reporte.objects.filter(tipo_objeto='POST', objeto_id=instance.id, estado='PENDIENTE').update(estado='RESUELTO')
            
        if instance.imagen:
            instance.imagen.delete()
        instance.delete()
        return Response({"mensaje": "Publicación eliminada correctamente"}, status=status.HTTP_200_OK)

class ImagenGaleriaDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Imagenes_galeria.objects.all()
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        
        if instance.propietario != request.user:
            Notificacion.objects.create(
                usuario=instance.propietario,
                tipo="CONTENIDO_BORRADO",
                mensaje=f"Tu imagen de la galería ha sido borrada por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.comunidad
            )
        
        # Auto-resolver reportes pendientes
        Reporte.objects.filter(tipo_objeto='IMAGEN', objeto_id=instance.id, estado='PENDIENTE').update(estado='RESUELTO')
        
        instance.delete()
        return Response({"mensaje": "Imagen eliminada"}, status=status.HTTP_200_OK)

class ReporteListCreate(generics.ListCreateAPIView):
    queryset = Reporte.objects.all()
    serializer_class = ReporteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(informador=self.request.user)

class ComentarioDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Comentario.objects.all()
    serializer_class = ComentarioSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        razon = request.data.get('razon', 'Incumplimiento de normas')
        
        if instance.autor != request.user:
            Notificacion.objects.create(
                usuario=instance.autor,
                tipo="COMENTARIO_BORRADO",
                mensaje=f"Tu comentario ha sido borrado por un administrador. Motivo: {razon}",
                referencia_comunidad=instance.publicacion.comunidad
            )
        
        # Auto-resolver reportes pendientes
        Reporte.objects.filter(tipo_objeto='COMENTARIO', objeto_id=instance.id, estado='PENDIENTE').update(estado='RESUELTO')
        
        instance.delete()
        return Response({"mensaje": "Comentario eliminado"}, status=status.HTTP_200_OK)

class GaleriaList(generics.ListCreateAPIView):
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = GaleriaPagination

    def get_queryset(self):
        comunidad_id = self.request.query_params.get('comunidad_id')
        propietario_id = self.request.query_params.get('usuario_id')
        coleccion_id = self.request.query_params.get('coleccion_id')
        
        qs = Imagenes_galeria.objects.filter(es_publica=True)

        if coleccion_id:
            try:
                from .models import Coleccion
                coleccion = Coleccion.objects.get(id=coleccion_id)
                # Omitimos la verificación de privacidad estricta temporalmente si es el autor
                if coleccion.es_privada and getattr(coleccion, 'usuario', None) != self.request.user:
                    return Imagenes_galeria.objects.none()
                return coleccion.imagenes.all().order_by('-fecha_subida')
            except Exception:
                return Imagenes_galeria.objects.none()

        if comunidad_id:
            # Si es comunidad privada, verificar membresía
            try:
                comunidad = Comunidad.objects.get(id=comunidad_id)
                if not comunidad.es_publica:
                    es_miembro = Miembros_comunidades.objects.filter(
                        comunidad=comunidad, usuario=self.request.user
                    ).exists()
                    if not es_miembro and comunidad.creador != self.request.user:
                        return Imagenes_galeria.objects.none()
                return Imagenes_galeria.objects.filter(comunidad_id=comunidad_id).order_by('-fecha_subida')
            except Comunidad.DoesNotExist:
                return Imagenes_galeria.objects.none()

        if propietario_id:
            # Si es mi galería, veo todo; si es de otro, solo lo público
            if str(propietario_id) == str(self.request.user.id):
                return Imagenes_galeria.objects.filter(propietario_id=propietario_id).order_by('-fecha_subida')
            return qs.filter(propietario_id=propietario_id).order_by('-fecha_subida')
            
        return qs.order_by('-fecha_subida')

    def perform_create(self, serializer):
        serializer.save(propietario=self.request.user)

class GaleriaDetalleExtendido(generics.RetrieveAPIView):
    queryset = Imagenes_galeria.objects.all()
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def retrieve(self, request, *args, **kwargs):
        imagen = self.get_object()
        
        # Buscar publicaciones asociadas a esta imagen
        from .models import Publicacion, Coleccion
        from .serializers import PublicacionSerializer, ColeccionSerializer
        
        pub = Publicacion.objects.filter(imagen=imagen).first()
        pub_data = PublicacionSerializer(pub, context={'request': request}).data if pub else None

        # Buscar colecciones donde aparece esta imagen (sólo mostramos las públicas o propias)
        cols = Coleccion.objects.filter(imagenes=imagen)
        cols = cols.filter(Q(es_privada=False) | Q(usuario=request.user))
        cols_data = [{'id': c.id, 'nombre': c.nombre_coleccion, 'privada': c.es_privada} for c in cols]

        return Response({
            'imagen': self.get_serializer(imagen).data,
            'publicacion': pub_data,
            'colecciones': cols_data
        })

class InicioGaleria(generics.ListAPIView):
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        usuario = self.request.user if self.request.user.is_authenticated else None
        etiquetas = self.request.query_params.get('etiquetas', None)
        
        if usuario:
            comunidades_usuario=Miembros_comunidades.objects.filter(usuario=usuario).values_list('comunidad_id', flat=True)
            usuarios_seguidos=Seguimiento.objects.filter(seguidor=usuario,estado='ACEPTADO',seguido_usuario__isnull=False).values_list('seguido_usuario_id',flat=True)
            imagenes=Imagenes_galeria.objects.filter(Q(comunidad_id__in=comunidades_usuario)|Q(comunidad__es_publica=True)|Q(propietario_id__in=usuarios_seguidos)|Q(propietario__perfil__es_publico=True)).distinct()
        else:
            imagenes=Imagenes_galeria.objects.filter(Q(comunidad__es_publica=True)|Q(propietario__perfil__es_publico=True)).distinct()
            
        if etiquetas:
            imagenes = imagenes.filter(etiquetas__icontains=etiquetas)
            
        return imagenes.order_by('?')[:50]

class ColeccionViewSet(viewsets.ModelViewSet):
    serializer_class = ColeccionSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = GaleriaPagination

    def get_queryset(self):
        user = self.request.user
        comunidad_id = self.request.query_params.get('comunidad_id')
        usuario_id = self.request.query_params.get('usuario_id')

        if comunidad_id:
            return Coleccion.objects.filter(comunidad_id=comunidad_id)
        if usuario_id:
            if str(usuario_id) == str(user.id):
                return Coleccion.objects.filter(usuario_id=usuario_id)
            return Coleccion.objects.filter(usuario_id=usuario_id, es_privada=False)
        
        return Coleccion.objects.filter(usuario=user)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)

    @action(detail=True, methods=['post'], url_path='gestionar-imagenes')
    def gestionar_imagenes(self, request, pk=None):
        coleccion = self.get_object()
        imagen_id = request.data.get('imagen_id')
        accion = request.data.get('accion') # 'add' o 'remove'

        try:
            imagen = Imagenes_galeria.objects.get(id=imagen_id)
        except Imagenes_galeria.DoesNotExist:
            return Response({'error': 'Imagen no encontrada'}, status=404)

        if accion == 'add':
            coleccion.imagenes.add(imagen)
            return Response({'status': 'Imagen añadida'})
        elif accion == 'remove':
            coleccion.imagenes.remove(imagen)
            return Response({'status': 'Imagen removida'})
        
        return Response({'error': 'Acción no válida'}, status=400)

class ToggleLikeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            publicacion = Publicacion.objects.get(pk=pk)
        except Publicacion.DoesNotExist:
            return Response({'error': 'Publicación no encontrada'}, status=404)

        like, created = Me_gustas.objects.get_or_create(usuario=request.user, publicacion=publicacion)
        
        if not created:
            like.delete()
            return Response({'mensaje': 'Like eliminado', 'resultado': 'unliked'}, status=200)
        
        return Response({'mensaje': 'Like añadido', 'resultado': 'liked'}, status=201)

class ComentarioListCreate(generics.ListCreateAPIView):
    serializer_class = ComentarioSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        publicacion_id = self.kwargs.get('pk')
        return Comentario.objects.filter(publicacion_id=publicacion_id).order_by('fecha_creacion')

    def perform_create(self, serializer):
        try:
            publicacion = Publicacion.objects.get(pk=self.kwargs.get('pk'))
        except Publicacion.DoesNotExist:
            raise serializers.ValidationError("Publicación no encontrada")
        serializer.save(autor=self.request.user, publicacion=publicacion)

class ResolverReporteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            reporte = Reporte.objects.get(pk=pk)
        except Reporte.DoesNotExist:
            return Response({'error': 'Reporte no encontrado'}, status=404)

        # Solo el creador o moderadores de la comunidad pueden resolver
        if reporte.comunidad:
            es_gestor = reporte.comunidad.creador == request.user or Miembros_comunidades.objects.filter(
                usuario=request.user, comunidad=reporte.comunidad, rol__in=['Administrador', 'Moderador']
            ).exists()
            if not es_gestor:
                return Response({'error': 'No tienes permiso para resolver este reporte'}, status=403)

        nuevo_estado = request.data.get('estado')
        if nuevo_estado not in ['RESUELTO', 'DESESTIMADO']:
            return Response({'error': 'Estado no válido'}, status=400)

        reporte.estado = nuevo_estado
        reporte.save()
        
        return Response({'mensaje': f'Reporte marcado como {nuevo_estado}'}, status=200)