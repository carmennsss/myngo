import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_notificaciones.dart';
import 'package:myngo_app/models/notificacion.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late ServicioNotificaciones servicioNotificaciones;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    servicioNotificaciones = ServicioNotificaciones(httpClient: mockClient);
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ServicioNotificaciones - REST API', () {
    test('obtenerNotificaciones devuelve una lista de notificaciones', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode([
        {
          'id': 1,
          'tipo': 'MENSAJE_CHAT',
          'mensaje': 'Tienes un nuevo mensaje',
          'leida': false,
          'fecha_creacion': '2023-01-01T10:00:00Z'
        }
      ]);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final resultado = await servicioNotificaciones.listarNotificaciones();

      expect(resultado.exito, true);
      expect(resultado.datos?.length, 1);
      expect(resultado.datos?[0].mensaje, 'Tienes un nuevo mensaje');
      expect(resultado.datos?[0].tipo, 'MENSAJE_CHAT');
    });

    test('marcarLeida envía POST y devuelve éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      when(() => mockClient.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final resultado = await servicioNotificaciones.marcarComoLeida(1);

      expect(resultado.exito, true);
      expect(resultado.mensaje, 'Notificación actualizada');
    });

    test('responderSolicitudInteractiva envía POST y devuelve éxito', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: '{"accion":"ACEPTAR"}'))
          .thenAnswer((_) async => http.Response(
            jsonEncode({"mensaje": "Operación realizada"}), 
            200,
            headers: {'content-type': 'application/json; charset=utf-8'}
          ));

      final resultado = await servicioNotificaciones.responderSolicitudInteractiva(1, 'ACEPTAR');

      expect(resultado.exito, true);
      expect(resultado.mensaje, 'Operación realizada');
    });
  });
}
