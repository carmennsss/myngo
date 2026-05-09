import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Experto en Comunidades', () {
    
    Future<void> loginHelper(PatrolIntegrationTester $) async {
      await $(#emailLoginInput).enterText('comunidad@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
    }

    patrolTest('Variante 1: Navega por catálogo de comunidades, lee todo y se une a la tercera', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      // Ve tres comunidades en lista
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      // Entra a la primera, no le gusta
      if (await $(#comunidadCardItem).exists) {
        await $(#comunidadCardItem).at(0).tap();
        await $.pumpAndSettle();
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        await $(#backButton).tap();
        await $.pumpAndSettle();
        
        // Entra a la segunda
        await $(#comunidadCardItem).at(1).tap();
        await $.pumpAndSettle();
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        await $(#backButton).tap();
        await $.pumpAndSettle();
        
        // Se une a la tercera
        await $(#comunidadCardItem).at(2).tap();
        await $.pumpAndSettle();
        await humano.pauseToRead(minSeconds: 5, maxSeconds: 7); // La lee entera
        await $('Unirme').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 2: Entra al feed exclusivo de la comunidad y crea un post allí', (PatrolIntegrationTester $) async {
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
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
        
        if (await $(#fabCreatePost).exists) {
          await $(#fabCreatePost).tap();
          await $.pumpAndSettle();
          
          await humano.humanType($(#postTextInput), '¡Hola a todos los del grupo!', makeMistake: false);
          await $('Publicar').tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        }
      }
    });

    patrolTest('Variante 3: Entra a una comunidad privada y solicita acceso', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      await $(#searchComunidadesInput).enterText('Secreta');
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      
      if (await $(#comunidadCardItem).exists) {
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 4);
        
        if (await $('Solicitar Acceso').exists) {
          await $('Solicitar Acceso').tap();
          await $.pumpAndSettle();
          expect($('Pendiente').exists, true);
        }
      }
    });

    patrolTest('Variante 4: Sale de una comunidad pero se arrepiente en el último momento', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#opcionesComunidadMenu).exists) {
        await $(#opcionesComunidadMenu).tap();
        await $.pumpAndSettle();
        
        await $('Abandonar comunidad').tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); // Mira el mensaje de advertencia
        
        // Se arrepiente
        await $('Cancelar').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 5: Es admin y echa a un usuario por mal comportamiento', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($); // Inicia como admin
      
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#configuracionAdminIcon).exists) {
        await $(#configuracionAdminIcon).tap();
        await $.pumpAndSettle();
        
        await $('Miembros').tap();
        await $.pumpAndSettle();
        
        await humano.humanScroll($(#listaMiembros), times: 1);
        
        if (await $(#opcionesMiembroIcon).exists) {
          await $(#opcionesMiembroIcon).first.tap();
          await $.pumpAndSettle();
          
          await $('Expulsar').tap();
          await $.pumpAndSettle();
          await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
          await $('Confirmar expulsión').tap();
          await $.pumpAndSettle();
        }
      }
    });

    patrolTest('Variante 6: Edita la descripción y la imagen de portada de su propia comunidad', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($); 
      
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#configuracionAdminIcon).exists) {
        await $(#configuracionAdminIcon).tap();
        await $.pumpAndSettle();
        
        await $('Información General').tap();
        await $.pumpAndSettle();
        
        await humano.humanType($(#descripcionInput), ' Nueva info oficial', makeMistake: false);
        
        await $(#cambiarPortadaIcon).tap();
        await $.pumpAndSettle();
        await $('Mocked Image').tap();
        await $.pumpAndSettle();
        
        await $('Guardar').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      }
    });

    patrolTest('Variante 7: Busca por tags (Ej: #Programación) en el buscador', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#searchComunidadesInput), '#Programación', makeMistake: false);
      await $.pumpAndSettle(timeout: const Duration(seconds: 4));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
    });

    patrolTest('Variante 8: Trata de unirse a una comunidad pero tiene Myngo Points/Rating insuficiente', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($); // Usuario novato
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      // Comunidad VIP
      await $(#searchComunidadesInput).enterText('VIP');
      await $.pumpAndSettle();
      
      if (await $(#comunidadCardItem).exists) {
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();
        
        if (await $('Unirme').exists) {
          await $('Unirme').tap();
          await $.pumpAndSettle();
          
          expect($('rating').exists || $('insuficientes').exists, true);
          await humano.pauseToRead(minSeconds: 3, maxSeconds: 4); // Lee por qué no puede
        }
      }
    });

    patrolTest('Variante 9: Abre el chat grupal de la comunidad y envía varios emojis', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#tabChatComunidad).exists) {
        await $(#tabChatComunidad).tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        
        await $(#chatInputTextField).enterText('🚀🔥🎮');
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 10: Comparte el link de invitación a una comunidad a un amigo por chat privado', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#compartirIcon).exists) {
        await $(#compartirIcon).tap();
        await $.pumpAndSettle();
        
        await $('Copiar enlace').tap();
        await $.pumpAndSettle();
        
        // Ahora va al chat a pegarlo
        await $(#bottomNavMessages).tap();
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        await $(#chatInputTextField).enterText('Únete a esto: myngo.app/c/123');
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();
      }
    });
  });
}
