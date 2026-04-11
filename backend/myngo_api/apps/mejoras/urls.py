from django.urls import path
from .views import (
    VotoAPIView, RankingUsuariosView, RankingComunidadesView, CatalogoMejoras,
    CatalogoMejorasGlobales, CatalogoMejorasComunidad, PeticionMejoraCreate,
    PeticionMejoraModeracionList, PeticionMejoraModerar, ComprarMejoraView,
    GestionCatalogoComunidad
)

urlpatterns = [
    path('votar/', VotoAPIView.as_view(), name='votar'),
    path('ranking/usuarios/', RankingUsuariosView.as_view(), name='ranking-usuarios'),
    path('ranking/comunidades/', RankingComunidadesView.as_view(), name='ranking-comunidades'),
    path('tienda/global/', CatalogoMejorasGlobales.as_view(), name='tienda-global'),
    path('tienda/comunidad/<int:comunidad_id>/', CatalogoMejorasComunidad.as_view(), name='tienda-comunidad'),
    path('tienda/peticiones/crear/', PeticionMejoraCreate.as_view(), name='crear-peticion'),
    path('tienda/peticiones/moderacion/<int:comunidad_id>/', PeticionMejoraModeracionList.as_view(), name='moderacion-peticiones'),
    path('tienda/peticiones/<int:pk>/moderar/', PeticionMejoraModerar.as_view(), name='moderar-peticion'),
    path('tienda/gestion/<int:comunidad_id>/', GestionCatalogoComunidad.as_view(), name='gestion-catalogo'),
    path('tienda/comprar/<int:pk>/', ComprarMejoraView.as_view(), name='comprar-mejora'),
    path('tienda/<str:tipo>/', CatalogoMejoras.as_view(), name='catalogo-mejoras'),
]
