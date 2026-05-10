import 'package:flutter_test/flutter_test.dart';
import 'package:myngo_app/models/usuario.dart';
import 'package:myngo_app/models/comunidad.dart';
import 'package:myngo_app/models/publicacion.dart';
import 'package:myngo_app/models/sala_chat.dart';

void main() {
  group('Tests de Modelos (Parseo y Serialización)', () {
    test('Usuario.fromJson parsea correctamente', () {
      final json = {
        'id': 1,
        'perfil_id': 2,
        'nombre_usuario': 'testuser',
        'email': 'test@test.com',
        'es_verificado': true,
        'biografia': 'Bio test'
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, 1);
      expect(usuario.nombreUsuario, 'testuser');
      expect(usuario.email, 'test@test.com');
      expect(usuario.esVerificado, true);
      expect(usuario.biografia, 'Bio test');
    });

    test('Comunidad.fromJson y toJson funcionan correctamente', () {
      final json = {
        'id': 5,
        'nombre': 'Devs',
        'descripcion': 'Comunidad de desarrolladores',
        'es_publica': false,
        'es_verificada': false,
        'es_miembro': true,
        'min_rating_acceso': 100,
        'miembros_count': 10,
        'url_portada': 'http://image.com/portada.jpg',
        'rating_medio': 3.5,
        'fecha_creacion': '2023-10-01T12:00:00Z',
        'creador_nombre': 'Admin'
      };

      final comunidad = Comunidad.fromJson(json);

      expect(comunidad.id, 5);
      expect(comunidad.nombre, 'Devs');
      expect(comunidad.esPublica, false);
      expect(comunidad.minRatingAcceso, 100);
      expect(comunidad.miembrosCount, 10);
      expect(comunidad.urlPortada, 'http://image.com/portada.jpg');

      final serialized = comunidad.toJson();
      expect(serialized['nombre'], 'Devs');
    });

    test('Publicacion.fromJson parsea correctamente', () {
      final json = {
        'id': 10,
        'titulo': 'Nuevo Post',
        'contenido_texto': 'Contenido',
        'fecha_creacion': '2023-10-01T12:00:00Z',
        'autor': 1,
        'autor_nombre': 'testuser',
        'comunidad': 5,
        'likes_count': 7,
        'comentarios_count': 2
      };

      final publicacion = Publicacion.fromJson(json);

      expect(publicacion.id, 10);
      expect(publicacion.titulo, 'Nuevo Post');
      expect(publicacion.autorNombre, 'testuser');
      expect(publicacion.likesCount, 7);
    });

    test('SalaChat.fromJson parsea correctamente', () {
      final json = {
        'id': 20,
        'nombre': 'Sala General',
        'es_grupal': true,
        'comunidad': 5,
        'fecha_creacion': '2023-10-01T12:00:00Z',
        'num_miembros': 12,
        'creador': 1
      };

      final sala = SalaChat.fromJson(json);

      expect(sala.id, 20);
      expect(sala.nombre, 'Sala General');
      expect(sala.esGrupal, true);
      expect(sala.comunidadId, 5);
      expect(sala.numMiembros, 12);
      expect(sala.creador, 1);
    });
  });
}

