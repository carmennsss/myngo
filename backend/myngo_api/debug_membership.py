import os
import sys
import django

# Add the project and apps directory to sys.path
base_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(base_dir)
sys.path.append(os.path.join(base_dir, 'apps'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from comunidades.models import Comunidad, Miembros_comunidades
from usuarios.models import Usuario

def check_membership():
    comunidad_id = 3
    print("=== INSPECCIONANDO MEMBRESÍAS (COMUNIDAD 3) ===")
    try:
        comunidad = Comunidad.objects.get(id=comunidad_id)
        print(f"Comunidad: {comunidad.nombre} (ID: {comunidad.id})")
        print(f"Creador: {comunidad.creador.nombre_usuario if comunidad.creador else 'N/A'} ({comunidad.creador.email if comunidad.creador else 'N/A'})")
        
        miembros = Miembros_comunidades.objects.filter(comunidad=comunidad)
        print(f"\nMiembros/Peticiones ({miembros.count()}):")
        for m in miembros:
            print(f"- Usuario: {m.usuario.nombre_usuario} ({m.usuario.email}), Rol: {m.rol}")
            
    except Comunidad.DoesNotExist:
        print(f"Comunidad {comunidad_id} no existe.")

def create_test_communities():
    print("\n=== CREANDO COMUNIDADES DE PRUEBA (PRUEBA2) ===")
    try:
        usuario = Usuario.objects.get(nombre_usuario='prueba2')
    except Usuario.DoesNotExist:
        try:
            usuario = Usuario.objects.get(email='prueba2@myngo.com')
        except Usuario.DoesNotExist:
            print("Usuario 'prueba2' no encontrado. No se pueden crear comunidades.")
            return

    comunidades_data = [
        {"nombre": "Gatos del Barrio 🐾", "descripcion": "Una comunidad para los gatos que dominan el barrio.", "es_publica": True},
        {"nombre": "Miau Secret Club 🤫", "descripcion": "Solo para gatos elegantes y educados. Privada.", "es_publica": False},
    ]

    for data in comunidades_data:
        comunidad, created = Comunidad.objects.get_or_create(
            nombre=data["nombre"],
            defaults={
                "descripcion": data["descripcion"],
                "es_publica": data["es_publica"],
                "creador": usuario
            }
        )
        if created:
            print(f"Creada: {comunidad.nombre} (ID: {comunidad.id})")
            # Unirse como admin
            Miembros_comunidades.objects.create(
                usuario=usuario,
                comunidad=comunidad,
                rol="Administrador",
            )
        else:
            print(f"Ya existe: {comunidad.nombre}")

if __name__ == "__main__":
    check_membership()
    create_test_communities()
