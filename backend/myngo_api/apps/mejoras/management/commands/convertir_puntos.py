import math
from django.core.management.base import BaseCommand
from usuarios.models import Usuario, Perfil

class Command(BaseCommand):
    help = 'Convierte el rating medio de los usuarios en puntos diarios ( Gamificación )'

    def handle(self, *args, **options):
        usuarios = Usuario.objects.all()
        actualizados = 0

        for usuario in usuarios:
            # 1. Obtener el rating medio
            rating = usuario.rating_medio
            
            # 2. Calcular puntos a sumar (ej: 4.5 estrellas -> +45 puntos)
            # Usamos math.floor para evitar decimales en puntos
            puntos_a_sumar = math.floor(float(rating) * 10)

            if puntos_a_sumar > 0:
                # 3. Obtener o crear perfil
                perfil, created = Perfil.objects.get_or_create(usuario=usuario)
                
                # 4. Sumar puntos respetando el límite de 5000
                nuevo_total = perfil.puntos + puntos_a_sumar
                if nuevo_total > 5000:
                    nuevo_total = 5000
                
                perfil.puntos = nuevo_total
                perfil.save()
                actualizados += 1

        self.stdout.write(self.style.SUCCESS(f'¡Miau! Se han actualizado puntos para {actualizados} usuarios.'))
