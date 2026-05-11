import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_comunidades.dart';
import 'package:myngo_app/models/comunidad.dart';

class MockClient extends Mock implements http.Client {}
class MockDio extends Mock implements dio.Dio {}

void main() {
  late ServicioComunidades servicioComunidades;
  late MockClient mockClient;
  late MockDio mockDio;

  setUp(() {
    mockClient = MockClient();
    mockDio = MockDio();
    servicioComunidades = ServicioComunidades(httpClient: mockClient, dioClient: mockDio);
    
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ServicioComunidades - REST API', () {
    test('listarComunidades devuelve una lista de comunidades en caso de éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({
        'results': [
          {'id': 1, 'nombre': 'Comunidad 1', 'es_publica': true},
          {'id': 2, 'nombre': 'Comunidad Privada', 'es_publica': false}
        ]
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioComunidades.listarComunidades();

      expect(resultado.exito, true);
      expect(resultado.datos?.length, 2);
      expect(resultado.datos?[0].nombre, 'Comunidad 1');
      expect(resultado.datos?[1].esPublica, false);
    });

    test('obtenerComunidad devuelve el detalle de una comunidad', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({
        'id': 1, 
        'nombre': 'Comunidad Info', 
        'descripcion': 'Demo info',
        'es_publica': true
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioComunidades.obtenerComunidad(1);

      expect(resultado.exito, true);
      expect(resultado.datos, isNotNull);
      expect(resultado.datos?.nombre, 'Comunidad Info');
      expect(resultado.datos?.descripcion, 'Demo info');
    });

    test('unirseAComunidad realiza el post y devuelve éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({'mensaje': 'Te has unido correctamente'});

      when(() => mockClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioComunidades.unirseAComunidad(1);

      expect(resultado.exito, true);
      expect(resultado.mensaje, 'Operación realizada correctamente');
    });

    test('abandonarComunidad devuelve éxito cuando el servidor responde 200', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      when(() => mockClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final resultado = await servicioComunidades.abandonarComunidad(1);

      expect(resultado.exito, true);
      expect(resultado.mensaje, 'Has abandonado la comunidad');
    });

    test('crearComunidad usa Dio para Multipart y devuelve Comunidad si éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      final mockedResponse = dio.Response(
        data: {
          'id': 5,
          'nombre': 'Nueva Comunidad Dio',
          'es_publica': true
        },
        statusCode: 201,
        requestOptions: dio.RequestOptions(path: ''),
      );

      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => mockedResponse);

final nueva = Comunidad(
        id: 0,
        nombre: 'Nueva Comunidad Dio',
        descripcion: 'Desc',
        creadorNombre: 'Test',
        urlPortada: '',
        esPublica: true,
        esVerificada: false,
        esMiembro: true,
        ratingMedio: 0.0,
        minRatingAcceso: 0,
        fechaCreacion: DateTime.now(),
      );

      final resultado = await servicioComunidades.crearComunidad(nueva);

      expect(resultado.exito, true);
      expect(resultado.datos?.nombre, 'Nueva Comunidad Dio');
      expect(resultado.datos?.id, 5);
    });
  });
}
