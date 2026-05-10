import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Frustrado (Caminos de error)', () {

    patrolTest('Variante 1: Falla login 3 veces, a la cuarta acierta', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      for (int i=1; i<=3; i++) {
        await $(#emailLoginInput).enterText('frustrado@test.com');
        await $(#passwordLoginInput).enterText('MalaPass$i');
        await $('Iniciar Sesión').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));
        
        expect($('credenciales').exists || $('Error').exists, true);
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2); // Bufa enfadado
      }
      
      // Cuarta vez buena
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      expect($('Feed Global').exists || $(#bottomNavHome).exists, true);
    });

    patrolTest('Variante 2: Escribe un post súper largo, pierde conexión al darle a publicar', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'Post muy largo e importante que me ha costado pensar...', makeMistake: false);
      
      // Simular pérdida red
      if (await $(#forceNetworkErrorButton).exists) {
        await $(#forceNetworkErrorButton).tap();
      }
      
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 6));
      
      expect($('Error de red').exists || $('Conexión').exists, true);
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); // Frustración total
    });

    patrolTest('Variante 3: Entra a un chat, manda imagen pero le da error por archivo muy grande', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavMessages).tap();
      await $(#chatListItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#attachMediaIcon).exists) {
        await $(#attachMediaIcon).tap();
        await $.pumpAndSettle();
        
        // Simular elegir imagen gigante
        if (await $('Mocked Giant Image').exists) {
          await $('Mocked Giant Image').tap();
          await $.pumpAndSettle();
          
          await $(#sendChatButton).tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 4));
          
          expect($('excede').exists || $('demasiado grande').exists, true);
          await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
        }
      }
    });

    patrolTest('Variante 4: Hace clic en una notificación Push de un post que ya fue eliminado (404)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      // Simula entrar por deep link a contenido borrado
      // Depende de la implementación mock, lo forzamos navegando y asumiendo 404
      if (await $(#openDeletedPostMock).exists) {
        await $(#openDeletedPostMock).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));
        
        expect($('No encontrado').exists || $('eliminado').exists, true);
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 4); // "Vaya por Dios"
        
        await $(#backToHomeButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 5: Intenta comprar un cosmético, le da error de pasarela de pago, vuelve a intentar', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavProfile).tap();
      await $('Tienda de Mejoras').tap();
      await $.pumpAndSettle();
      
      if (await $(#mejoraItemColor).exists) {
        await $(#mejoraItemColor).tap();
        await $.pumpAndSettle();
        
        // Simular error de servidor 500
        if (await $(#force500ErrorButton).exists) {
          await $(#force500ErrorButton).tap();
        }
        
        await $('Comprar por 500 MP').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        
        expect($('Error').exists, true);
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        
        // Quita error y reintenta
        if (await $(#force500ErrorButton).exists) {
          await $(#force500ErrorButton).tap(); // Toggle
        }
        await $('Comprar por 500 MP').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        expect($('Compra exitosa').exists, true);
      }
    });

    patrolTest('Variante 6: Actualiza el feed, no carga, se enfada y hace pull-to-refresh furiosamente 5 veces', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      if (await $(#forceNetworkErrorButton).exists) {
        await $(#forceNetworkErrorButton).tap();
      }
      
      for (int i=0; i<5; i++) {
        await $.native.swipe(from: const Offset(0.5, 0.2), to: const Offset(0.5, 0.8));
        await $.pumpAndSettle(timeout: const Duration(seconds: 2));
      }
      
      expect($('Error de red').exists, true);
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 4);
    });

    patrolTest('Variante 7: Su sesión caduca a mitad de estar leyendo un post, es expulsado al login', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      if (await $(#postItemCard).exists) {
        await $(#postItemCard).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // Leyendo...
        
        // Expulsado!
        if (await $(#forceSessionExpireButton).exists) {
          await $(#forceSessionExpireButton).tap();
          await $.pumpAndSettle();
          
          // Requiere llamada a API para fallar 401, forzamos un like para trigger
          await $(#likeButton).first.tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 3));
          
          expect($('Iniciar Sesión').exists, true);
          await humano.pauseToRead(minSeconds: 4, maxSeconds: 6); // "...¿Qué acaba de pasar?"
        }
      }
    });

    patrolTest('Variante 8: Trata de seguir a un usuario pero el backend falla silenciosamente, el botón parpadea', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      if (await $(#followButton).exists) {
        if (await $(#force500ErrorButton).exists) await $(#force500ErrorButton).tap();
        
        await $(#followButton).first.tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        
        // Debería volver al estado original o mostrar snackbar
        expect($('Seguir').exists || $('Error').exists, true);
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      }
    });

    patrolTest('Variante 9: Escribe en el buscador algo raro y el teclado no se cierra', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#searchGlobalIcon).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#searchGlobalInput), '¿!123!?', makeMistake: false);
      
      // Pulsa fuera para forzar unfocus
      await $.native.tap(const Offset(0.5, 0.5));
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
    });

    patrolTest('Variante 10: Intenta subir de nivel pero le sale un cartel de que no tiene experiencia', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('frustrado@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      if (await $(#upgradeNivelBoton).exists) {
        await $(#upgradeNivelBoton).tap();
        await $.pumpAndSettle();
        
        expect($('XP insuficiente').exists, true);
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 4);
      }
    });

  });
}
