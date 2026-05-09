"""Configuración de rutas de URL para el módulo de mejoras (tienda y votos)."""

from django.urls import path

from .views import (
    CatalogoMejorasGlobales,
    ComprarMejoraView,
    EquipacionMejorasGlobales,
    MisMejorasView,
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
    path('tienda/comprar/<int:pk>/', ComprarMejoraView.as_view(), name='comprar-mejora'),
    path('tienda/mis-mejoras/', MisMejorasView.as_view(), name='mis-mejoras'),
    path('tienda/equipar/', EquipacionMejorasGlobales.as_view(), name='equipar-mejora'),
]
