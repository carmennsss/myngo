import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db import transaction, connection

from usuarios.models import Usuario, Perfil, Seguimiento
from comunidades.models import Comunidad, TagComunidad, MiembrosComunidad
from contenido.models import Publicacion, ImagenGaleria, Comentario, MeGusta, PostGuardado, Reporte
from mejoras.models import Voto, CatalogoMejoras, PeticionMejora, MejoraUsuario

class Command(BaseCommand):
    help = 'Limpia la base de datos y genera datos de prueba variados para Myngo.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Iniciando limpieza de base de datos...'))
        try:
            self.limpiar_db_raw()
            self.stdout.write(self.style.SUCCESS('Base de datos limpia.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error al limpiar la base de datos: {e}'))
            self.stdout.write('Intentando limpieza suave...')
            try:
                self.limpiar_db_soft()
            except:
                pass

        self.stdout.write('Generando nuevos datos...')
        
        with transaction.atomic():
            self.stdout.write('Creando tags...')
            tags = self.crear_tags()
            
            self.stdout.write('Creando usuarios...')
            usuarios = self.crear_usuarios()
            
            self.stdout.write('Creando comunidades...')
            comunidades = self.crear_comunidades(usuarios, tags)
            
            self.stdout.write('Asignando miembros...')
            self.asignar_miembros(usuarios, comunidades)
            
            self.stdout.write('Creando catalogo de mejoras...')
            self.crear_catalogo(usuarios, comunidades)
            
            self.stdout.write('Creando posts...')
            posts = self.crear_posts(usuarios, comunidades)
            
            self.stdout.write('Creando interacciones...')
            self.crear_interacciones(usuarios, posts)
            
            self.stdout.write('Creando votos...')
            self.crear_votos(usuarios, comunidades)

        self.stdout.write(self.style.SUCCESS('Poblacion de base de datos completada con exito!'))

    def limpiar_db_raw(self):
        """Limpia la base de datos usando SQL crudo para saltar FK checks."""
        tables = [
            'votos', 'me_gustas', 'comentarios', 'posts_guardados', 'reportes',
            'mejoras_usuario', 'peticiones_mejora', 'catalogo_mejoras',
            'publicacion_imagenes', 'publicacion', 'imagenes_galeria', 
            'miembros_comunidades', 'seguimientos', 'comunidades_tags', 'comunidades'
        ]
        with connection.cursor() as cursor:
            cursor.execute('SET FOREIGN_KEY_CHECKS = 0;')
            for table in tables:
                cursor.execute(f'DELETE FROM {table};')
            cursor.execute('SET FOREIGN_KEY_CHECKS = 1;')
        
        # Usuarios no staff (ORM para manejar perfiles si fuera necesario, pero DELETE CASCADE debería bastar)
        Usuario.objects.filter(is_staff=False).delete()

    def limpiar_db_soft(self):
        models_to_delete = [
            Voto, MeGusta, Comentario, PostGuardado, Reporte,
            MejoraUsuario, PeticionMejora, CatalogoMejoras,
            Publicacion, ImagenGaleria, MiembrosComunidad,
            Seguimiento, Comunidad, TagComunidad
        ]
        for model in models_to_delete:
            model.objects.all().delete()
        Usuario.objects.filter(is_staff=False).delete()

    def crear_tags(self):
        nombres_tags = [
            'Videojuegos', 'Moda', 'Cocina', 'Tecnologia', 'Musica', 
            'Deporte', 'Viajes', 'Cine', 'Arte', 'Mascotas', 
            'Programacion', 'Lectura', 'Naturaleza', 'Salud', 'Motor',
            'Anime', 'Fotografia', 'Fitness', 'Historia', 'Ciencia'
        ]
        return [TagComunidad.objects.get_or_create(nombre=n)[0] for n in nombres_tags]

    def crear_usuarios(self):
        nombres = [
            'MichiPro', 'CatLover', 'GatoConBotas', 'LunaGatuna', 'FelixTheCat',
            'SiamesMaster', 'Garfield', 'KittenPurr', 'WhiskerWarrior', 'MeowMixer',
            'Pawsitive', 'TabbyTail', 'CalicoQueen', 'PersianPrince', 'ShadowProwler',
            'MistyMew', 'GingerSnap', 'OliverTwist', 'Simba', 'Nala',
            'Chloe', 'Bella', 'Smokey', 'Tiger', 'Kitty', 'Max', 'Luna', 'Cooper',
            'Lola', 'Buddy', 'Rocky', 'Bear', 'Leo', 'Milo', 'Jack'
        ]
        
        avatares = [
            "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200",
            "https://images.unsplash.com/photo-1573865526739-10659fef78a1?w=200",
            "https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=200",
            "https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=200",
            None
        ]

        usuarios = []
        for i, nombre in enumerate(nombres):
            email = f"user{i}@myngo.com"
            u, created = Usuario.objects.get_or_create(email=email, defaults={'nombre_usuario': nombre})
            if created:
                u.set_password('password123')
                u.save()
            
            p, _ = Perfil.objects.get_or_create(usuario=u)
            p.biografia = f"Hola, soy {nombre}. Mi bio numero {i}."
            p.avatar = random.choice(avatares)
            p.puntos = random.randint(100, 5000)
            p.estado = random.choice(['ACTIVO', 'DESCONECTADO', 'OCUPADO'])
            if i % 5 == 0:
                p.estilo_post = {"background": "linear-gradient(to top, #a18cd1 0%, #fbc2eb 100%)", "border": "2px solid #a18cd1"}
            p.save()
            usuarios.append(u)
        return usuarios

    def crear_comunidades(self, usuarios, tags):
        tematicas = [
            ("Gamer's Den", 'Videojuegos'), ('Alta Costura', 'Moda'), ('Chef Myngo', 'Cocina'),
            ('Techies', 'Tecnologia'), ('Melomanos', 'Musica'), ('Atletas', 'Deporte'),
            ('Viajeros', 'Viajes'), ('Cineastas', 'Cine'), ('Arte', 'Arte'), ('Mundo Felino', 'Gatos'),
            ('Pythonistas', 'Programacion'), ('Club Lectura', 'Libros'), ('Vida Verde', 'Ecologia'),
            ('Mente Sana', 'Salud'), ('Ruta 66', 'Coches'), ('Fotografos', 'Fotos'),
            ('Anime Fan', 'Anime'), ('Fitness', 'Deporte'), ('Historia', 'Cultura'), ('Espacio', 'Ciencia')
        ]
        
        comunidades = []
        for i, (nombre, desc) in enumerate(tematicas):
            c, _ = Comunidad.objects.get_or_create(
                nombre=nombre,
                defaults={
                    'descripcion': desc,
                    'creador': random.choice(usuarios),
                    'es_publica': (i % 5 != 0),
                    'color_tema': random.choice(['#C35E34', '#248EA6', '#D95F43', '#4A4440'])
                }
            )
            c.tags.set(random.sample(tags, random.randint(1, 3)))
            comunidades.append(c)
        return comunidades

    def asignar_miembros(self, usuarios, comunidades):
        miembros = []
        for c in comunidades:
            for m in random.sample(usuarios, random.randint(10, len(usuarios))):
                if m != c.creador:
                    miembros.append(MiembrosComunidad(usuario=m, comunidad=c))
        MiembrosComunidad.objects.bulk_create(miembros, ignore_conflicts=True)

    def crear_catalogo(self, usuarios, comunidades):
        mejoras = []
        for c in comunidades:
            mejoras.append(CatalogoMejoras(tipo='Estilo Premium', precio_puntos=500, comunidad=c, creador=c.creador))
        CatalogoMejoras.objects.bulk_create(mejoras)

    def crear_posts(self, usuarios, comunidades):
        img_urls = [
            "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600",
            "https://images.unsplash.com/photo-1573865526739-10659fef78a1?w=600",
            "https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600",
            "https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=600"
        ]
        video_url = "https://www.w3schools.com/html/mov_bbb.mp4"

        posts = []
        for i in range(110):
            autor = random.choice(usuarios)
            comunidad = random.choice(comunidades) if random.random() > 0.2 else None
            p = Publicacion.objects.create(
                autor=autor, comunidad=comunidad, titulo=f"Post #{i+1}", 
                contenido_texto=f"Contenido del post {i+1}. " + "Miau " * random.randint(1, 10)
            )
            
            dice = random.random()
            if dice < 0.15: # Video
                v = ImagenGaleria.objects.create(propietario=autor, url_s3=video_url, tipo_archivo='V')
                p.imagen = v
            elif dice < 0.4: # Gallery
                imgs = [ImagenGaleria.objects.create(propietario=autor, url_s3=random.choice(img_urls)) for _ in range(3)]
                p.imagenes.set(imgs)
                p.imagen = imgs[0]
            elif dice < 0.8: # Single image
                p.imagen = ImagenGaleria.objects.create(propietario=autor, url_s3=random.choice(img_urls))
            
            p.save()
            posts.append(p)
        return posts

    def crear_interacciones(self, usuarios, posts):
        likes = []
        comms = []
        saves = []
        for p in posts:
            for u in random.sample(usuarios, random.randint(0, 15)):
                likes.append(MeGusta(usuario=u, publicacion=p))
            for _ in range(random.randint(0, 5)):
                comms.append(Comentario(autor=random.choice(usuarios), publicacion=p, contenido="Genial!"))
            if random.random() > 0.8:
                saves.append(PostGuardado(usuario=random.choice(usuarios), publicacion=p))
        
        MeGusta.objects.bulk_create(likes, ignore_conflicts=True)
        Comentario.objects.bulk_create(comms)
        PostGuardado.objects.bulk_create(saves, ignore_conflicts=True)

    def crear_votos(self, usuarios, comunidades):
        votos = []
        for _ in range(200):
            u1, u2 = random.sample(usuarios, 2)
            votos.append(Voto(votante=u1, receptor_usuario=u2, estrellas=random.randint(1, 5)))
        for _ in range(100):
            votos.append(Voto(votante=random.choice(usuarios), receptor_comunidad=random.choice(comunidades), estrellas=random.randint(1, 5)))
        Voto.objects.bulk_create(votos)
