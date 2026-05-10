import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myngo_app/screens/login/pantalla_login.dart';
import 'package:myngo_app/screens/registro/pantalla_registro.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';
import 'package:myngo_app/models/respuesta_api.dart';
import 'package:myngo_app/models/usuario.dart';
import 'package:provider/provider.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/providers/locale_notifier.dart';

class MockServicioUsuarios extends Mock implements ServicioUsuarios {}

void main() {
  late MockServicioUsuarios mockServicioUsuarios;

  setUpAll(() async {
    // Inicialización mínima de Tolgee para tests
    await Tolgee.init();
  });

  Widget buildTestableWidget(Widget widget) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
      ],
      child: MaterialApp(
        home: widget,
      ),
    );
  }

  setUp(() {
    // Aumentamos el tamaño de la pantalla para evitar desbordamientos en tests
    TestWidgetsFlutterBinding.ensureInitialized();
    final tester = TestWidgetsFlutterBinding.instance;
    tester.platformDispatcher.views.first.physicalSize = const Size(1920, 1080);
    tester.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  group('Auth Screens Widget Tests', () {
    testWidgets('PantallaLogin renderiza correctamente y muestra campos de email y password', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PantallaLogin()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Email + Password
      expect(find.byType(TextFormField), findsNWidgets(2));

      // El botón existe (buscamos por InkWell ya que BotonCarga lo usa internamente)
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('PantallaRegistro renderiza correctamente y muestra campos', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PantallaRegistro()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Nombre, Email, Password
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}

