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

    def perform_create(self, serializer):
        serializer.save(autor=self.request.user)

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
