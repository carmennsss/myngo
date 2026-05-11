import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';
import 'package:myngo_app/models/usuario.dart';
import 'package:myngo_app/models/respuesta_api.dart';

class MockClient extends Mock implements http.Client {}
class MockDio extends Mock implements dio.Dio {}

void main() {
  late ServicioUsuarios servicioUsuarios;
  late MockClient mockClient;
  late MockDio mockDio;

  setUp(() {
    mockClient = MockClient();
    mockDio = MockDio();
    servicioUsuarios = ServicioUsuarios(httpClient: mockClient, dioClient: mockDio);
    
    // Register fallback URIs for mocktail
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ServicioUsuarios - Autenticación', () {
    test('iniciarSesion retorna éxito y guarda token si credenciales son correctas', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final responseBody = jsonEncode({
        'token': 'test_token',
        'datos': {
          'id': 1,
          'nombre_usuario': 'testuser',
          'email': 'test@test.com'
        }
      });

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await servicioUsuarios.iniciarSesion('test@test.com', 'password123');

      expect(result.exito, true);
      expect(result.datos, isA<Usuario>());
      expect(result.datos?.nombreUsuario, 'testuser');
      expect(prefs.getString('auth_token'), 'test_token');
      expect(prefs.getInt('usuario_id'), 1);
    });

    test('iniciarSesion retorna error si el servidor devuelve HTML (crashed)', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('<!DOCTYPE html><html>error</html>', 500));

      final result = await servicioUsuarios.iniciarSesion('test@test.com', 'password123');

      expect(result.exito, false);
      expect(result.mensaje, contains('Error técnico'));
    });

    test('registrarse devuelve Usuario en caso de éxito', () async {
      final responseBody = jsonEncode({
        'mensaje': 'Usuario creado',
        'datos': {
          'id': 2,
          'nombre_usuario': 'nuevo_user',
          'email': 'nuevo@test.com'
        }
      });

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(responseBody, 201));

      final result = await servicioUsuarios.registrarse('nuevo_user', 'nuevo@test.com', 'password123');

      expect(result.exito, true);
      expect(result.datos?.nombreUsuario, 'nuevo_user');
    });
  });

  group('ServicioUsuarios - Gestión de Sesión', () {
    test('cerrarSesion elimina las claves de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'usuario_id': 1,
        'nombre_usuario': 'testuser'
      });
      final prefs = await SharedPreferences.getInstance();

      await servicioUsuarios.cerrarSesion();

      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getInt('usuario_id'), isNull);
      expect(prefs.getString('nombre_usuario'), isNull);
    });
  });

  group('ServicioUsuarios - Obtención de datos', () {
    test('obtenerDatosUsuario devuelve usuario correctamente', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      final responseBody = jsonEncode({
        'id': 1,
        'nombre_usuario': 'testuser',
        'email': 'test@test.com'
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await servicioUsuarios.obtenerDatosUsuario(1);

      expect(result.exito, true);
      expect(result.datos?.nombreUsuario, 'testuser');
    });

    test('listarUsuarios devuelve lista paginada de usuarios', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      final responseBody = jsonEncode({
        'results': [
          {'id': 1, 'nombre_usuario': 'user1'},
          {'id': 2, 'nombre_usuario': 'user2'}
        ]
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await servicioUsuarios.listarUsuarios(pagina: 1);

      expect(result.exito, true);
      expect(result.datos?.length, 2);
      expect(result.datos?[0].nombreUsuario, 'user1');
    });
  });
}
