"""Configuración de rutas de URL para el módulo de mejoras (tienda y votos)."""

from django.urls import path

from .views import (
    CatalogoMejorasComunidad,
    CatalogoMejorasGlobales,
    ComprarMejoraView,
    EquipacionMejorasGlobales,
    GestionCatalogoComunidad,
    MisMejorasView,
    PeticionMejoraCreate,
    PeticionMejoraModeracionList,
    PeticionMejoraModerar,
    RankingComunidadesView,
    RankingUsuariosView,
    VotoAPIView,
)

urlpatterns = [
    # Sistema de Votos y Rankings
    path('votar/', VotoAPIView.as_view(), name='votar'),
    path('ranking/usuarios/', RankingUsuariosView.as_view(), name='ranking-usuarios'),
    path('ranking/comunidades/', RankingComunidadesView.as_view(), name='ranking-comunidades'),

    # Tienda: Catálogo y Compras
    path('tienda/global/', CatalogoMejorasGlobales.as_view(), name='tienda-global'),
    path('tienda/comunidad/<int:comunidad_id>/', CatalogoMejorasComunidad.as_view(), name='tienda-comunidad'),
    path('tienda/comprar/<int:pk>/', ComprarMejoraView.as_view(), name='comprar-mejora'),
    path('tienda/mis-mejoras/', MisMejorasView.as_view(), name='mis-mejoras'),
    path('tienda/equipar/', EquipacionMejorasGlobales.as_view(), name='equipar-mejora'),

    # Tienda: Peticiones y Moderación
    path('tienda/peticiones/crear/', PeticionMejoraCreate.as_view(), name='crear-peticion'),
    path('tienda/peticiones/moderacion/<int:comunidad_id>/', PeticionMejoraModeracionList.as_view(), name='moderacion-peticiones'),
    path('tienda/peticiones/<int:pk>/moderar/', PeticionMejoraModerar.as_view(), name='moderar-peticion'),
    path('tienda/gestion/<int:comunidad_id>/', GestionCatalogoComunidad.as_view(), name='gestion-catalogo'),
]
