"""Configuración de la aplicación de mejoras."""

from django.apps import AppConfig


class MejorasConfig(AppConfig):
    """Configuración para el módulo de mejoras.

    Carga las señales del dominio al inicializar la aplicación.
    """

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'mejoras'

    def ready(self):
        """Importación de señales de mejoras."""
        import mejoras.signals
