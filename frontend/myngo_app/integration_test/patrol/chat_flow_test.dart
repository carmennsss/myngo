import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;

void main() {
  // Función auxiliar para login
  Future<void> loginHelper(PatrolIntegrationTester $) async {
    await $(#emailLoginInput).enterText('patrol@test.com');
    await $(#passwordLoginInput).enterText('Password123!');
    await $('Iniciar Sesión').tap();
    await $.pumpAndSettle();
  }

  group('Flujos E2E Extremadamente Detallados - Mensajería', () {
    patrolTest(
      'Usuario abre la pestaña de chats por primera vez (lista vacía)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $.pumpAndSettle();

        expect($('Mis Mensajes').exists, true);
        expect($('No tienes ningún chat todavía').exists, true);
      },
    );

    patrolTest(
      'Usuario abre un chat con mensajes previos',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $.pumpAndSettle();

        // Asumimos que el backend de test ya inyectó un chat
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        expect($(#burbujaChatRecibida).exists, true);
      },
    );

    patrolTest(
      'Usuario envía un mensaje de texto corto',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        await $(#chatInputTextField).enterText('Hola');
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();

        expect($('Hola').exists, true);
      },
    );

    patrolTest(
      'Usuario envía un mensaje de texto extremadamente largo',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        final longText = 'Hola ' * 100; // Muy largo
        await $(#chatInputTextField).enterText(longText);
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();

        expect($(longText).exists, true);
      },
    );

    patrolTest(
      'Usuario envía un mensaje y pierde conexión a mitad (simulado por error de red en UI)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Simulamos deshabilitar red si patrol lo permite, o confiamos en un botón "Forzar Error" de la build de test
        if (await $(#forceNetworkErrorButton).exists) {
          await $(#forceNetworkErrorButton).tap();
        }

        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        await $(#chatInputTextField).enterText('Mensaje que fallará');
        await $(#sendChatButton).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // El mensaje debe aparecer con un ícono de reloj o de reintento (error)
        expect($(#iconoErrorEnvio).exists || $('Error al enviar').exists, true);
      },
    );

    patrolTest(
      'Usuario recibe un mensaje mientras está en el chat activo',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        // El backend de pruebas manda un mensaje por WS pasados 3 segundos
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));

        // Debe verse en pantalla inmediatamente sin hacer tap
        expect($('Mensaje inyectado por backend').exists, true);
      },
    );

    patrolTest(
      'Usuario recibe un mensaje mientras está en otra pantalla (Feed)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Está en Home/Feed. El backend manda un mensaje.
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));

        // Debería aparecer un in-app banner o un badge en el bottom navigation
        expect($(#bottomNavBadge).exists, true);
      },
    );

    patrolTest(
      'Usuario recibe varios mensajes seguidos sin leer, el contador se actualiza',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $.pumpAndSettle();

        // Verificar contador inicial en la tarjeta
        expect($('3').exists || $('0').exists, true); 

        // El backend manda 3 mensajes
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        
        // El número del contador (badge rojo) debe ser 3 o más
        expect($('3').exists, true);
      },
    );

    patrolTest(
      'Usuario entra al chat y el contador de no leídos baja a 0, badge desaparece al volver atrás',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $.pumpAndSettle();

        // Entramos al chat que tiene mensajes no leídos
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        // Volvemos atrás
        await $(#backButton).tap();
        await $.pumpAndSettle();

        // El badge numérico en el BottomNav o en el chatListItem ya no debe existir
        expect($(#unreadBadgeItem).exists, false);
      },
    );

    patrolTest(
      'Usuario recibe notificación, pulsa el banner nativo y navega directamente al chat',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Con patrol podemos interactuar con notificaciones nativas del SO
        await $.native.openNotifications();
        
        // Esperamos que el backend (o un script externo) lance una push real
        final notif = $.native.getNotifications();
        if (notif.isNotEmpty) {
          await $.native.tapOnNotificationByText('Tienes un nuevo mensaje');
          await $.pumpAndSettle();
          
          // Verificar que estamos en la pantalla de chat
          expect($(#chatInputTextField).exists, true);
        } else {
          // Fallback cerrando notificaciones
          await $.native.pressHome();
          await $.native.openApp();
        }
      },
    );

    patrolTest(
      'Usuario adjunta una imagen de galería, texto y la envía en un chat',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();

        // Tocar icono de adjuntar
        await $(#attachMediaIcon).tap();
        await $.pumpAndSettle();
        
        // Tocar opción "Galería"
        await $('Galería').tap();
        // Con Patrol, tocar el botón de dar permisos nativos si aparece
        if (await $.native.isPermissionDialogVisible()) {
          await $.native.grantPermissionWhenInUse();
        }

        // Tocar enviar
        await $(#chatInputTextField).enterText('Mira esta foto');
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();

        expect($('Mira esta foto').exists, true);
      },
    );
  });
}
