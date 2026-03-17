import os
import sys
import django

# Add the project and apps directory to sys.path
base_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(base_dir)
sys.path.append(os.path.join(base_dir, 'apps'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from usuarios.models import Usuario

def list_users():
    print("=== LISTA DE USUARIOS ===")
    usuarios = Usuario.objects.all()
    for u in usuarios:
        print(f"ID: {u.id}, Username: {u.nombre_usuario}, Email: {u.email}")

if __name__ == "__main__":
    list_users()
