from comunidades.models import Miembros_comunidades
from rest_framework import generics, filters, permissions
from .models import Publicacion, Imagenes_galeria, Coleccion
from .serializers import PublicacionSerializer, ImagenGaleriaSerializer, ColeccionSerializer
from .permissions import IsAuthorOrAdmin
from comunidades.models import Comunidad
from rest_framework.views import APIView,status
from rest_framework.response import Response
from core import settings
from django.http import JsonResponse
from django.core.files.storage import default_storage
from usuarios.models import Seguimiento
from django.db.models import Q
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
        user = self.request.user
        comunidad_id = self.request.query_params.get('comunidad_id')
        
        # Filtro base: Solo válidos por IA para usuarios normales
        # (Los admins podrían ver todo para moderar)
        qs = Publicacion.objects.filter(es_valido_ia=True)
        
        if comunidad_id:
            try:
                comunidad = Comunidad.objects.get(id=comunidad_id)
            except Comunidad.DoesNotExist:
                return Publicacion.objects.none()

            if not comunidad.es_publica:
                if user.is_authenticated:
                    # Verificar membresía aceptada
                    es_miembro = Seguimiento.objects.filter(
                        seguidor=user, 
                        seguida_comunidad=comunidad, 
                        estado='ACEPTADO'
                    ).exists()
                    if not es_miembro and comunidad.creador != user:
                        return Publicacion.objects.none()
                else:
                    # Usuario anónimo no puede ver comunidad privada
                    return Publicacion.objects.none()
            
            return qs.filter(comunidad_id=comunidad_id).order_by('-fecha_creacion')
        
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
                    comunidad_id=request.data.get('comunidad') or None,
                    url_s3=archivo,
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
    def perform_destroy(self, instance):
        if instance.imagen:
            instance.imagen.delete()
        instance.delete()
        return Response(status=200)
class PublicacionDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Publicacion.objects.all()
    serializer_class = PublicacionSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthorOrAdmin]

class GaleriaList(generics.ListAPIView):
    serializer_class = ImagenGaleriaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        comunidad_id = self.request.query_params.get('comunidad_id')
        if comunidad_id:
            return Imagenes_galeria.objects.filter(comunidad_id=comunidad_id).order_by('-fecha_subida')
        return Imagenes_galeria.objects.none()
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