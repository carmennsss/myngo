"""Configuración de la aplicación de notificaciones."""

from django.apps import AppConfig


class NotificacionesConfig(AppConfig):
    """Configuración para el módulo de notificaciones."""

    def ready(self):
        import notificaciones.signals

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'notificaciones'
