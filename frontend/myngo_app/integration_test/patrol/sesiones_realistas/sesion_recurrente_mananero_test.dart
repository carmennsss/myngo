import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Recurrente Mañanero', () {
    
    Future<void> loginHelper(PatrolIntegrationTester $) async {
      await $(#emailLoginInput).enterText('mananero@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
    }

    patrolTest('Variante 1: Entra, va a notificaciones, abre una, feed, chat y sale', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      // Usuario mañanero abre la app medio dormido
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      // Directo a notificaciones
      await $(#notificacionesIcon).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 6);
      
      if (await $(#notificacionItem).exists) {
        await $(#notificacionItem).first.tap();
        await $.pumpAndSettle();
        
        // Pausa para leer adonde le llevó la notificación (ej. un post)
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
        
        // Vuelve al feed
        await $(#backButton).tap();
        await $.pumpAndSettle();
        await $(#bottomNavHome).tap();
        await $.pumpAndSettle();
      }
      
      // Hace scroll en el feed
      if (await $(#listaPublicaciones).exists) {
        await humano.humanScroll($(#listaPublicaciones), times: 4);
      }
      
      // Revisa sus chats
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      if (await $(#chatListItem).exists) {
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        // Lee mensajes
        await humano.pauseToRead(minSeconds: 4, maxSeconds: 6);
        
        // Responde rápido
        await humano.humanType($(#chatInputTextField), 'Buenos días!', makeMistake: true);
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      }
    });

    patrolTest('Variante 2: Ignora notificaciones, va directo al feed y da likes', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      
      // Scroll y dar like a todo lo que pilla (típico comportamiento matutino automático)
      for (int i = 0; i < 3; i++) {
        if (await $(#likeButton).exists) {
          await $(#likeButton).first.tap();
          await $.pumpAndSettle();
        }
        await $.native.swipe(from: const Offset(0.5, 0.7), to: const Offset(0.5, 0.4));
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      }
    });

    patrolTest('Variante 3: Entra a comunidad, lee novedades pero no escribe nada', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      if (await $(#comunidadCardItem).exists) {
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();
        
        await $(#tabPublicacionesComunidad).tap();
        await $.pumpAndSettle();
        
        // Lee pero no hace nada
        await humano.humanScroll($(#listaPublicaciones), times: 2);
        
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 4: Abre un chat con un amigo, borra el mensaje a la mitad y no manda nada', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      
      if (await $(#chatListItem).exists) {
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.humanType($(#chatInputTextField), 'Hola, hoy he soñado que...', makeMistake: false);
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
        
        // Se lo piensa mejor y lo borra todo
        await $(#chatInputTextField).enterText('');
        await $.pumpAndSettle();
        
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 5: Abre la app pero la minimiza rápido porque entra al trabajo', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      await $.native.pressHome();
    });

    patrolTest('Variante 6: Cierra sesión sin querer (dedos torpes), luego vuelve a entrar', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await $(#opcionesPerfilButton).tap();
      await $.pumpAndSettle();
      
      // Tap accidental
      await $('Cerrar Sesión').tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // "Ay mierda"
      
      await loginHelper($);
    });

    patrolTest('Variante 7: Borra todas las notificaciones haciendo swipe', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#notificacionesIcon).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      
      while (await $(#notificacionItem).exists) {
        await $.native.swipe(from: const Offset(0.8, 0.5), to: const Offset(0.2, 0.5));
        await $.pumpAndSettle();
        await humano.pauseToRead(minSeconds: 0, maxSeconds: 1); // Rápido
      }
    });

    patrolTest('Variante 8: Entra al feed, refresca 3 veces a ver si hay algo nuevo', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      for (int i = 0; i < 3; i++) {
        await $.native.swipe(from: const Offset(0.5, 0.2), to: const Offset(0.5, 0.8));
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      }
    });

    patrolTest('Variante 9: Abre el feed, y usa la búsqueda global para buscar a un usuario', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      if (await $(#searchGlobalIcon).exists) {
        await $(#searchGlobalIcon).tap();
        await $.pumpAndSettle();
        
        await humano.humanType($(#searchGlobalInput), 'Juan', makeMistake: false);
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 10: Toca la galería de un post y hace zoom', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      if (await $(#postItemImage).exists) {
        await $(#postItemImage).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
        
        // Simular zoom (pinch) es posible con patrol pero complejo, simulamos doble tap
        await $(#fullscreenImageDialog).tap();
        await $(#fullscreenImageDialog).tap(); 
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
        
        await $(#cerrarFullscreen).tap();
        await $.pumpAndSettle();
      }
    });
  });
}
