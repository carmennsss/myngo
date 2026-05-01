"""Configuración de la aplicación de contenido."""

from django.apps import AppConfig


class ContenidoConfig(AppConfig):
    """Configuración para el módulo de contenido.

    Carga las señales del dominio al inicializar la aplicación.
    """

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'contenido'

    def ready(self):
        """Importación de señales de contenido."""
        import contenido.signals
