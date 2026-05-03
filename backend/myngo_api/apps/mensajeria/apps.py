"""Configuración de la aplicación de mensajería."""

from django.apps import AppConfig


class MensajeriaConfig(AppConfig):
    """Configuración para el módulo de mensajería."""

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'mensajeria'

    def ready(self):
        import mensajeria.signals
