"""Punto de entrada del módulo de vistas de contenido.

Re-exporta todas las vistas desde los submódulos para mantener
la compatibilidad con las URLs existentes.
"""

from .views_colecciones import ColeccionViewSet
from .views_galeria import (
    GaleriaDetalleExtendido,
    GaleriaList,
    ImagenGaleriaDetail,
    InicioGaleria,
)
from .views_interaccion import (
    ComentarioListCreate,
    DocumentosUtilidad,
    InicioFeed,
    ToggleLikeView,
    TogglePostGuardadoView,
)
from .views_moderacion import ComentarioDetail, ReporteListCreate, ResolverReporteView
from .views_publicaciones import (
    PublicacionCreate,
    PublicacionDelete,
    PublicacionDetail,
    PublicacionList,
)

__all__ = [
    'DocumentosUtilidad',
    'PublicacionList',
    'PublicacionCreate',
    'PublicacionDelete',
    'PublicacionDetail',
    'ImagenGaleriaDetail',
    'ReporteListCreate',
    'ComentarioDetail',
    'GaleriaList',
    'GaleriaDetalleExtendido',
    'InicioGaleria',
    'InicioFeed',
    'ColeccionViewSet',
    'ToggleLikeView',
    'ComentarioListCreate',
    'ResolverReporteView',
    'TogglePostGuardadoView',
]