"""Script de utilidad para poblar el catálogo de la tienda con estilos de post iniciales."""

import os
import sys
import django

# Asegurar que el modulo myngo_api es resoluble
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myngo_api.settings')
django.setup()

from mejoras.models import CatalogoMejoras


def crear_estilos_iniciales():
    """Crea un conjunto predefinido de estilos de post en el catálogo si no existen.

    Los estilos incluyen colores de fondo y borde para personalizar la apariencia
    de las publicaciones en la plataforma.
    """
    estilos = [
        {
            'tipo': 'Estilo Post',
            'precio_puntos': 500,
            'datos_extra': {'fondo': 'FFFBE9E0', 'borde': 'FFC35E34', 'nombre': 'Rosa Pastel'}
        },
        {
            'tipo': 'Estilo Post',
            'precio_puntos': 500,
            'datos_extra': {'fondo': 'FFE3F2FD', 'borde': 'FF1976D2', 'nombre': 'Azul Cielo'}
        },
        {
            'tipo': 'Estilo Post',
            'precio_puntos': 500,
            'datos_extra': {'fondo': 'FFE8F5E9', 'borde': 'FF388E3C', 'nombre': 'Verde Suave'}
        }
    ]

    for e in estilos:
        # Evitar duplicados basados en el nombre dentro de datos_extra
        nombre = e['datos_extra']['nombre']
        if not CatalogoMejoras.objects.filter(tipo=e['tipo'], datos_extra__nombre=nombre).exists():
            CatalogoMejoras.objects.create(
                tipo=e['tipo'],
                precio_puntos=e['precio_puntos'],
                datos_extra=e['datos_extra'],
                esta_activo=True
            )
            print(f"Estilo '{nombre}' creado.")
        else:
            print(f"El estilo '{nombre}' ya existe.")


if __name__ == "__main__":
    crear_estilos_iniciales()
    print('Proceso finalizado.')
