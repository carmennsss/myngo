# Manually squashed migration for 'contenido' app
# Replaces 0001 to 0018

import contenido.models
import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models

class Migration(migrations.Migration):

    replaces = [
        ('contenido', '0001_initial'),
        ('contenido', '0002_alter_imagenes_galeria_url_s3_and_more'),
        ('contenido', '0003_remove_imagenes_galeria_es_publica_and_more'),
        ('contenido', '0004_alter_imagenes_galeria_comunidad'),
        ('contenido', '0005_remove_publicacion_url_archivo_s3_publicacion_imagen_and_more'),
        ('contenido', '0006_coleccion_comunidad_coleccion_descripcion_and_more'),
        ('contenido', '0007_reporte'),
        ('contenido', '0008_alter_imagenes_galeria_url_s3'),
        ('contenido', '0009_publicacion_imagenes'),
        ('contenido', '0010_postguardado'),
        ('contenido', '0011_rename_imagenes_galeria_imagengaleria_and_more'),
        ('contenido', '0012_alter_imagengaleria_url_s3'),
        ('contenido', '0013_remove_publicacion_imagenes'),
        ('contenido', '0014_publicacionimagen_publicacion_imagenes'),
        ('contenido', '0015_alter_publicacion_imagenes'),
        ('contenido', '0016_rename_imagen_publicacionimagen_imagengaleria_and_more'),
        ('contenido', '0017_comentario_padre'),
        ('contenido', '0018_alter_coleccion_imagenes_alter_publicacion_imagen'),
    ]

    dependencies = [
        ('comunidades', '0010_miembroscomunidad_delete_miembros_comunidades'),
        ('usuarios', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ImagenGaleria',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('url_s3', models.FileField(blank=True, max_length=500, null=True, upload_to=contenido.models._definir_ruta_almacenamiento)),
                ('tipo_archivo', models.CharField(choices=[('I', 'Imagen'), ('V', 'Video')], default='I', max_length=1)),
                ('relacion_aspecto', models.FloatField(default=1.0)),
                ('es_publica', models.BooleanField(default=True)),
                ('fecha_subida', models.DateTimeField(auto_now_add=True)),
                ('etiquetas', models.CharField(blank=True, max_length=200, null=True)),
                ('comunidad', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='comunidades.comunidad')),
                ('propietario', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'imagenes_galeria'},
        ),
        migrations.CreateModel(
            name='Publicacion',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titulo', models.CharField(blank=True, max_length=200, null=True)),
                ('contenido_texto', models.TextField(blank=True, null=True)),
                ('relacion_aspecto', models.FloatField(default=1.0)),
                ('es_valido_ia', models.BooleanField(default=True)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('autor', models.ForeignKey(blank=True, on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
                ('comunidad', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='comunidades.comunidad')),
                ('imagen', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='contenido.ImagenGaleria')),
            ],
            options={'db_table': 'publicacion'},
        ),
        migrations.CreateModel(
            name='PublicacionImagen',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('orden', models.PositiveIntegerField(default=0)),
                ('imagengaleria', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='contenido.ImagenGaleria')),
                ('publicacion', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='contenido.publicacion')),
            ],
            options={
                'db_table': 'publicacion_imagenes',
                'ordering': ['orden'],
                'unique_together': {('publicacion', 'imagengaleria')},
            },
        ),
        migrations.AddField(
            model_name='publicacion',
            name='imagenes',
            field=models.ManyToManyField(blank=True, related_name='publicaciones_asociadas', through='contenido.PublicacionImagen', to='contenido.ImagenGaleria'),
        ),
        migrations.CreateModel(
            name='Coleccion',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nombre_coleccion', models.CharField(max_length=100)),
                ('descripcion', models.TextField(blank=True, null=True)),
                ('categoria', models.CharField(blank=True, max_length=50, null=True)),
                ('es_privada', models.BooleanField(default=False)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('comunidad', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='comunidades.comunidad')),
                ('usuario', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
                ('imagenes', models.ManyToManyField(related_name='en_colecciones', to='contenido.ImagenGaleria')),
            ],
            options={'db_table': 'colecciones'},
        ),
        migrations.CreateModel(
            name='MeGusta',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('fecha_like', models.DateTimeField(auto_now_add=True)),
                ('publicacion', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='contenido.publicacion')),
                ('usuario', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'me_gustas'},
        ),
        migrations.CreateModel(
            name='Comentario',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('contenido', models.TextField()),
                ('es_valido_ia', models.BooleanField(default=True)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('autor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
                ('padre', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='respuestas', to='contenido.comentario')),
                ('publicacion', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='contenido.publicacion')),
            ],
            options={'db_table': 'comentarios'},
        ),
        migrations.CreateModel(
            name='Reporte',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('tipo_objeto', models.CharField(choices=[('POST', 'Publicación'), ('IMAGEN', 'Imagen'), ('COMUNIDAD', 'Comunidad'), ('COMENTARIO', 'Comentario')], max_length=20)),
                ('objeto_id', models.IntegerField()),
                ('motivo', models.CharField(max_length=100)),
                ('comentario', models.TextField(blank=True, null=True)),
                ('estado', models.CharField(choices=[('PENDIENTE', 'Pendiente'), ('RESUELTO', 'Resuelto'), ('DESESTIMADO', 'Desestimado')], default='PENDIENTE', max_length=20)),
                ('fecha_reporte', models.DateTimeField(auto_now_add=True)),
                ('comunidad', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='comunidades.comunidad')),
                ('informador', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reportes_enviados', to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'reportes'},
        ),
        migrations.CreateModel(
            name='PostGuardado',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('fecha_guardado', models.DateTimeField(auto_now_add=True)),
                ('publicacion', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='guardado_por', to='contenido.publicacion')),
                ('usuario', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='posts_guardados', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'posts_guardados',
                'unique_together': {('usuario', 'publicacion')},
            },
        ),
    ]
