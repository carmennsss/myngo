import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from usuarios.models import Usuario

usuarios_prueba = [
    {"nombre": "GatitoPrueba1", "email": "prueba1@myngo.com", "pass": "123456"},
    {"nombre": "MichiPrueba2", "email": "prueba2@myngo.com", "pass": "123456"},
    {"nombre": "KarenPrueba3", "email": "prueba3@myngo.com", "pass": "123456"},
]

for d in usuarios_prueba:
    usuario, created = Usuario.objects.get_or_create(
        email=d["email"],
        defaults={"nombre_usuario": d["nombre"]}
    )
    if created or not usuario.has_usable_password():
        usuario.set_password(d["pass"])
        usuario.is_active = True
        usuario.save()
        print(f"Usuario {d['nombre']} creado/actualizado con éxito. 🐈")
    else:
        print(f"Usuario {d['nombre']} ya existía. 🐾")
