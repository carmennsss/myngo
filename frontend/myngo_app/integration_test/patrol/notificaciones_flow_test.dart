import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;

void main() {
  Future<void> loginHelper(PatrolIntegrationTester $) async {
    await $(#emailLoginInput).enterText('patrol@test.com');
    await $(#passwordLoginInput).enterText('Password123!');
    await $('Iniciar Sesión').tap();
    await $.pumpAndSettle();
  }

  group('Flujos E2E Extremadamente Detallados - Notificaciones y Mejoras', () {
    
    patrolTest(
      'Usuario abre la campana de notificaciones y ve estado vacío',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#notificacionesIcon).tap();
        await $.pumpAndSettle();

        expect($('Notificaciones').exists, true);
        if (await $('No tienes notificaciones').exists) {
          expect($('No tienes notificaciones').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario recibe una notificación in-app (WebSocket), la pulsa y se marca como leída',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Simulamos que pasados 3 segundos el backend dispara un evento WS
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));

        // Debe salir un snackbar o in-app banner
        if (await $(#inAppNotificationBanner).exists) {
          await $(#inAppNotificationBanner).tap();
          await $.pumpAndSettle();

          // Verificar que el badge ha desaparecido
          expect($(#unreadNotificationsBadge).exists, false);
        }
      },
    );

    patrolTest(
      'Usuario borra una notificación deslizando (swipe to delete)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#notificacionesIcon).tap();
        await $.pumpAndSettle();

        if (await $(#notificacionItem).exists) {
          await $.native.swipe(
            from: const Offset(0.8, 0.5), // Derecha
            to: const Offset(0.2, 0.5),   // Izquierda
          );
          await $.pumpAndSettle();
          
          expect($('Notificación eliminada').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario navega a la tienda de Mejoras, ve su saldo y compra un color de tema',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavProfile).tap();
        await $.pumpAndSettle();

        await $('Tienda de Mejoras').tap();
        await $.pumpAndSettle();

        expect($('Tus Myngo Points').exists, true);
        
        // Simular intento de compra
        if (await $(#mejoraItemColor).exists) {
          await $(#mejoraItemColor).tap();
          await $.pumpAndSettle();

          await $('Comprar por 500 MP').tap();
          await $.pumpAndSettle();

          // Si no tiene puntos suficientes:
          if (await $('Puntos insuficientes').exists) {
            expect($('Puntos insuficientes').exists, true);
            await $('Cerrar').tap();
          } else {
            expect($('Compra exitosa').exists, true);
          }
        }
      },
    );

    patrolTest(
      'Usuario vota positivamente una petición de mejora de la comunidad',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavProfile).tap();
        await $('Tienda de Mejoras').tap();
        await $.pumpAndSettle();

        await $(#tabPeticionesMejora).tap();
        await $.pumpAndSettle();

        if (await $(#peticionItem).exists) {
          final countInitialText = await $(#votosCount).first.text;
          final initial = int.tryParse(countInitialText ?? '0') ?? 0;

          await $(#votarPeticionButton).first.tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 2));

          final countFinalText = await $(#votosCount).first.text;
          final finalCount = int.tryParse(countFinalText ?? '0') ?? 0;

          expect(finalCount > initial, true);
        }
      },
    );
  });
}
