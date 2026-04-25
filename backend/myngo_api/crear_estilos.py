import os
import django
import sys

# Asegurar que el modulo myngo_api es resoluble
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myngo_api.settings')
django.setup()

from mejoras.models import Catalogo_mejoras

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
    if not Catalogo_mejoras.objects.filter(tipo=e['tipo'], datos_extra__nombre=e['datos_extra']['nombre']).exists():
        Catalogo_mejoras.objects.create(
            tipo=e['tipo'], 
            precio_puntos=e['precio_puntos'], 
            datos_extra=e['datos_extra'], 
            esta_activo=True
        )

print('Estilos creados')
