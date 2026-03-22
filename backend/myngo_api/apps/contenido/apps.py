from django.apps import AppConfig


class ContenidoConfig(AppConfig):
    name = 'contenido'
    default_auto_field = 'django.db.models.BigAutoField'

    def ready(self):
        import contenido.signals
