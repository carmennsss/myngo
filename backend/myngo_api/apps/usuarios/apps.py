"""Configuración de la aplicación de usuarios."""

from django.apps import AppConfig


class UsuariosConfig(AppConfig):
    """Configuración para el módulo de usuarios.

    Carga las señales del dominio al inicializar la aplicación.
    """

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'usuarios'

    def ready(self):
        """Importación de señales de usuarios."""
        import usuarios.signals
