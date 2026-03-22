from django.urls import path
from .views import PublicacionList, PublicacionCreate, PublicacionDetail, GaleriaList,DocumentosUtilidad

urlpatterns = [
    path('publicaciones/', PublicacionList.as_view(), name='publicacion-list'),
    path('publicaciones/crear/', PublicacionCreate.as_view(), name='publicacion-create'),
    path('publicaciones/<int:pk>/', PublicacionDetail.as_view(), name='publicacion-detail'),
    path('galeria/', GaleriaList.as_view(), name='galeria-list'),
    path('reglas_comunidad/',DocumentosUtilidad.as_view(),name="reglas_comunidad"),
]
