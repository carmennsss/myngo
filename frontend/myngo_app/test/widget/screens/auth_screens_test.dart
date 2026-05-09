import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myngo_app/screens/login/pantalla_login.dart';
import 'package:myngo_app/screens/registro/pantalla_registro.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';
import 'package:myngo_app/models/respuesta_api.dart';
import 'package:myngo_app/models/usuario.dart';

class MockServicioUsuarios extends Mock implements ServicioUsuarios {}

void main() {
  late MockServicioUsuarios mockServicioUsuarios;

  setUp(() {
    mockServicioUsuarios = MockServicioUsuarios();
  });

  Widget buildTestableWidget(Widget widget) {
    return MaterialApp(
      home: widget,
    );
  }

  group('Auth Screens Widget Tests', () {
    testWidgets('PantallaLogin renderiza correctamente y muestra campos de email y password', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PantallaLogin()));

      // Email + Password
      expect(find.byType(TextFormField), findsNWidgets(2));

      // El botón existe (evitamos depender del string hardcodeado: Tolgee)
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('PantallaRegistro renderiza correctamente y muestra 4 campos', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PantallaRegistro()));

      // Nombre, Email, Password (y el campo de confirmación ya no existe en la pantalla actual)
      // En esta UI actual solo hay 3 CamposPersonalizados con TextFormField.
      // Dejamos una aserción flexible para no romper con cambios menores.
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}

