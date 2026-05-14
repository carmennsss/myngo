import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_mensajeria.dart';
import 'package:myngo_app/models/sala_chat.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late ServicioMensajeria servicioMensajeria;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    servicioMensajeria = ServicioMensajeria.conCliente(mockClient);
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ServicioMensajeria - REST API', () {
    test('obtenerSalasChat devuelve lista de salas', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode([
        {'id': 1, 'nombre': 'Sala 1', 'es_grupal': false},
        {'id': 2, 'nombre': 'Sala Grupal', 'es_grupal': true}
      ]);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final salas = await servicioMensajeria.obtenerSalasChat();

      expect(salas.length, 2);
      expect(salas[0]['nombre'], 'Sala 1');
      expect(salas[1]['es_grupal'], true);
    });

    test('crearSala crea una nueva sala correctamente', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({
        'id': 3,
        'nombre': 'Nueva Sala'
      });

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(responseBody, 201));

      final resultado = await servicioMensajeria.crearSala(nombre: 'Nueva Sala');

      expect(resultado, isNotNull);
      expect(resultado?['nombre'], 'Nueva Sala');
    });

    test('obtenerMensajesSala devuelve lista de mensajes', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({
        'results': [
          {'id': 1, 'contenido': 'Hola'},
          {'id': 2, 'contenido': 'Mundo'}
        ]
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final mensajes = await servicioMensajeria.obtenerMensajesSala(1);

      expect(mensajes.length, 2);
      expect(mensajes[0]['contenido'], 'Hola');
    });

    test('enviarMensaje envía y retorna el mensaje creado', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'fake'});
      
      final responseBody = jsonEncode({
        'id': 10,
        'contenido': 'Mensaje de prueba'
      });

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(responseBody, 201));

      final resultado = await servicioMensajeria.enviarMensaje(1, 'Mensaje de prueba');

      expect(resultado, isNotNull);
      expect(resultado?['contenido'], 'Mensaje de prueba');
    });
  });

  // Los tests de WebSockets requieren un mock de WebSocketChannel que se implementará en los tests de integración
}
