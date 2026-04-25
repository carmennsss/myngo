import os
import django

# Setup django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from mejoras.models import Catalogo_mejoras

def update_post_style_prices():
    # Update all items of type 'Estilo Post' to 250 points
    updated = Catalogo_mejoras.objects.filter(tipo__iexact='Estilo Post').update(precio_puntos=150)
    print(f"Se han actualizado {updated} estilos de post a 250 puntos.")

if __name__ == "__main__":
    update_post_style_prices()
