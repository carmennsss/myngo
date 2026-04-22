from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PublicacionList, PublicacionCreate, PublicacionDetail, 
    GaleriaList, GaleriaDetalleExtendido, DocumentosUtilidad, InicioGaleria, ColeccionViewSet,
    ReporteListCreate, ImagenGaleriaDetail, ComentarioDetail,
    ToggleLikeView, ComentarioListCreate, ResolverReporteView, TogglePostGuardadoView
)

router = DefaultRouter()
router.register(r'colecciones', ColeccionViewSet, basename='coleccion')

urlpatterns = [
    path('publicaciones/', PublicacionList.as_view(), name='publicacion-list'),
    path('publicaciones/crear/', PublicacionCreate.as_view(), name='publicacion-create'),
    path('publicaciones/<int:pk>/', PublicacionDetail.as_view(), name='publicacion-detail'),
    path('galeria/', GaleriaList.as_view(), name='galeria-list'),
    path('galeria/<int:pk>/', ImagenGaleriaDetail.as_view(), name='galeria-item-detail'),
    path('galeria/<int:pk>/detalles/', GaleriaDetalleExtendido.as_view(), name='galeria-detalle'),
    path('reportes/', ReporteListCreate.as_view(), name='reporte-list'),
    path('reportes/<int:pk>/resolver/', ResolverReporteView.as_view(), name='reporte-resolver'),
    path('publicaciones/<int:pk>/like/', ToggleLikeView.as_view(), name='publicacion-like'),
    path('publicaciones/<int:pk>/guardar/', TogglePostGuardadoView.as_view(), name='publicacion-guardar'),
    path('publicaciones/<int:pk>/comentarios/', ComentarioListCreate.as_view(), name='publicacion-comentarios'),
    path('comentarios/<int:pk>/', ComentarioDetail.as_view(), name='comentario-detail'),
    path('reglas_comunidad/',DocumentosUtilidad.as_view(),name="reglas_comunidad"),
    path('inicio_galeria/',InicioGaleria.as_view(),name="inicio_galeria"),
    path('', include(router.urls)),
]
