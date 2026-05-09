import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_mejoras.dart';
import 'package:myngo_app/models/catalogo_mejoras.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late ServicioMejoras servicioMejoras;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    servicioMejoras = ServicioMejoras(httpClient: mockClient);
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ServicioMejoras - REST API', () {
    test('obtenerCatalogoGestion devuelve lista de mejoras', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      final responseBody = jsonEncode({
        'results': [
          {
            'id': 1,
            'nombre': 'Mejora Premium',
            'precio': 100,
          },
          {
            'id': 2,
            'nombre': 'Mejora Estandar',
            'precio': 50,
          },
        ],
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioMejoras.obtenerCatalogoGestion(1);

      expect(resultado.exito, true);
      expect(resultado.datos?.length, 2);
      expect(resultado.datos?[0].id, 1);
    });

    test('votar devuelve éxito cuando se vota correctamente', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      final responseBody = jsonEncode({
        'mensaje': 'Voto registrado exitosamente',
        'nueva_media': {'media': 4.5},
      });

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioMejoras.votar(
        idReceptorUsuario: 1,
        idReceptorComunidad: null,
        cantidadEstrellas: 5,
      );

      expect(resultado.exito, true);
    });

    test('comprarMejora devuelve éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      final responseBody = jsonEncode({'mensaje': 'Compra realizada', 'puntos_restantes': 900});

      when(() => mockClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioMejoras.comprarMejora(1);

      expect(resultado.exito, true);
      expect(resultado.mensaje, contains('Compra'));
    });
  });
}

