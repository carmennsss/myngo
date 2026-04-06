from django.apps import AppConfig


class MejorasConfig(AppConfig):
    name = 'mejoras'

    def ready(self):
        import mejoras.signals
