import os
import sys
import django

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.append(os.getcwd())
django.setup()

from usuarios.models import Usuario, Perfil

def add_points(username, amount):
    try:
        user = Usuario.objects.get(nombre_usuario=username)
        perfil, created = Perfil.objects.get_or_create(usuario=user)
        perfil.puntos = min(perfil.puntos + amount, 5000)
        perfil.save()
        print(f"Éxito: Se han añadido {amount} puntos al usuario '{username}'. Ahora tiene {perfil.puntos} puntos.")
    except Usuario.DoesNotExist:
        print(f"Error: El usuario '{username}' no existe.")
    except Exception as e:
        print(f"Error inesperado: {e}")

if __name__ == "__main__":
    add_points('robertoprueba1', 5000)
