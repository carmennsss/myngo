import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Social (Mensajes y Perfiles)', () {
    
    Future<void> loginHelper(PatrolIntegrationTester $) async {
      await $(#emailLoginInput).enterText('social@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
    }

    patrolTest('Variante 1: Entra, busca un amigo por nombre, le escribe y espera respuesta', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 3);
      
      await $(#searchGlobalIcon).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#searchGlobalInput), 'amigo_real', makeMistake: true);
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      
      if (await $(#userSearchResultItem).exists) {
        await $(#userSearchResultItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); // Cotillea perfil
        
        if (await $('Enviar Mensaje').exists) {
          await $('Enviar Mensaje').tap();
          await $.pumpAndSettle();
          
          await humano.humanType($(#chatInputTextField), 'Hola, ¿estás ahí?', makeMistake: false);
          await $(#sendChatButton).tap();
          await $.pumpAndSettle();
          
          // Se queda esperando en el chat
          await humano.pauseToRead(minSeconds: 8, maxSeconds: 12);
        }
      }
    });

    patrolTest('Variante 2: Entra a los mensajes directos, abre el último, lo lee pero no responde', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      
      if (await $(#chatListItem).exists) {
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 5, maxSeconds: 8); // Lee todo
        
        // Lo deja en visto
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 3: Manda 3 mensajes seguidos dividiendo las frases (típico chat)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      
      if (await $(#chatListItem).exists) {
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.humanType($(#chatInputTextField), 'Oye', makeMistake: false);
        await $(#sendChatButton).tap();
        await humano.pauseToRead(minSeconds: 0, maxSeconds: 1);
        
        await humano.humanType($(#chatInputTextField), 'sabes qué?', makeMistake: false);
        await $(#sendChatButton).tap();
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
        
        await humano.humanType($(#chatInputTextField), 'luego te cuento', makeMistake: false);
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 4: Recibe una notificación mientras hace scroll por el feed y va al chat instantáneamente', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.humanScroll($(#listaPublicaciones), times: 2);
      
      // Simula que entra un WS push (backend test inyecta tras X segundos)
      await $.pumpAndSettle(timeout: const Duration(seconds: 4));
      
      if (await $(#inAppNotificationBanner).exists) {
        await $(#inAppNotificationBanner).tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // Lee el chat nuevo
      }
    });

    patrolTest('Variante 5: Edita su foto de perfil para que los amigos la vean', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await $('Editar Perfil').tap();
      await $.pumpAndSettle();
      
      if (await $(#editAvatarIcon).exists) {
        await $(#editAvatarIcon).tap();
        await $.pumpAndSettle();
        await $('Mocked Image').tap();
        await $.pumpAndSettle();
      }
      
      await $('Guardar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    });

    patrolTest('Variante 6: Revisa la lista de seguidores de otro usuario', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      if (await $(#postAuthorAvatar).exists) {
        await $(#postAuthorAvatar).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        
        if (await $('Seguidores').exists) {
          await $('Seguidores').tap();
          await $.pumpAndSettle();
          
          await humano.humanScroll($(#listaSeguidores), times: 2);
          
          await $(#backButton).tap();
          await $.pumpAndSettle();
        }
      }
    });

    patrolTest('Variante 7: Comienza a seguir a 3 personas en el feed de inicio', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      for (int i=0; i<3; i++) {
        if (await $(#followButton).exists) {
          await $(#followButton).first.tap();
          await $.pumpAndSettle();
          await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
        }
        await $.native.swipe(from: const Offset(0.5, 0.7), to: const Offset(0.5, 0.3));
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 8: Entra al chat y usa un color de tema comprado (Myngo Points)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavMessages).tap();
      await $(#chatListItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#opcionesChat).exists) {
        await $(#opcionesChat).tap();
        await $.pumpAndSettle();
        
        await $('Personalizar').tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 4); // Elige el color
        
        if (await $(#colorThemeCyber).exists) {
          await $(#colorThemeCyber).tap();
          await $('Aplicar').tap();
          await $.pumpAndSettle();
        }
      }
    });

    patrolTest('Variante 9: Ignora a un usuario eliminando el chat', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      
      if (await $(#chatListItem).exists) {
        // Long press no soportado nativamente igual que tap, pero probemos si hay botón de borrar
        await $.native.swipe(from: const Offset(0.8, 0.5), to: const Offset(0.2, 0.5)); // Swipe en el chatItem
        await $.pumpAndSettle();
        
        if (await $('Eliminar chat').exists) {
          await $('Eliminar chat').tap();
          await $.pumpAndSettle();
        }
      }
    });

    patrolTest('Variante 10: Ve un comentario ofensivo y lo reporta', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      if (await $(#postItemCard).exists) {
        await $(#commentButton).first.tap();
        await $.pumpAndSettle();
        
        if (await $(#commentItem).exists) {
          await $(#opcionesComentario).first.tap();
          await $.pumpAndSettle();
          
          await $('Reportar').tap();
          await $.pumpAndSettle();
          
          await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // Lee las razones
          await $('Ofensivo').tap();
          await $('Enviar Reporte').tap();
          await $.pumpAndSettle();
          
          expect($('Reporte enviado').exists, true);
        }
      }
    });
  });
}
