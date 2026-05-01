"""Configuración de rutas de URL para el módulo de contenido."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    ColeccionViewSet,
    ComentarioDetail,
    ComentarioListCreate,
    DocumentosUtilidad,
    GaleriaDetalleExtendido,
    GaleriaList,
    ImagenGaleriaDetail,
    InicioFeed,
    InicioGaleria,
    PublicacionCreate,
    PublicacionDetail,
    PublicacionList,
    ReporteListCreate,
    ResolverReporteView,
    ToggleLikeView,
    TogglePostGuardadoView,
)

router = DefaultRouter()
router.register(r'colecciones', ColeccionViewSet, basename='coleccion')

urlpatterns = [
    # Publicaciones (Posts)
    path('publicaciones/', PublicacionList.as_view(), name='publicacion-list'),
    path('publicaciones/crear/', PublicacionCreate.as_view(), name='publicacion-create'),
    path('publicaciones/<int:pk>/', PublicacionDetail.as_view(), name='publicacion-detail'),
    path('publicaciones/<int:pk>/like/', ToggleLikeView.as_view(), name='publicacion-like'),
    path('publicaciones/<int:pk>/guardar/', TogglePostGuardadoView.as_view(), name='publicacion-guardar'),
    path('publicaciones/<int:pk>/comentarios/', ComentarioListCreate.as_view(), name='publicacion-comentarios'),

    # Galería e Imágenes
    path('galeria/', GaleriaList.as_view(), name='galeria-list'),
    path('galeria/<int:pk>/', ImagenGaleriaDetail.as_view(), name='galeria-item-detail'),
    path('galeria/<int:pk>/detalles/', GaleriaDetalleExtendido.as_view(), name='galeria-detalle'),

    # Feeds e Inicio
    path('inicio_feed/', InicioFeed.as_view(), name="inicio_feed"),
    path('inicio_galeria/', InicioGaleria.as_view(), name="inicio_galeria"),

    # Comentarios y Moderación
    path('comentarios/<int:pk>/', ComentarioDetail.as_view(), name='comentario-detail'),
    path('reportes/', ReporteListCreate.as_view(), name='reporte-list'),
    path('reportes/<int:pk>/resolver/', ResolverReporteView.as_view(), name='reporte-resolver'),

    # Utilidades
    path('reglas_comunidad/', DocumentosUtilidad.as_view(), name="reglas_comunidad"),
    path('', include(router.urls)),
]
