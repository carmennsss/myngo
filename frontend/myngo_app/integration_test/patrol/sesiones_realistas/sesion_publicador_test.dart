import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Publicador de Contenido', () {
    
    Future<void> loginHelper(PatrolIntegrationTester $) async {
      await $(#emailLoginInput).enterText('publicador@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
    }

    patrolTest('Variante 1: Crea post con imagen y verifica en su perfil', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); // Piensa
      await humano.humanType($(#postTextInput), 'Mirad lo que he hecho hoy!', makeMistake: true);
      
      if (await $(#addPhotoIcon).exists) {
        await $(#addPhotoIcon).tap();
        await $.pumpAndSettle();
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // Elige la foto
        await $('Mocked Image').tap();
        await $.pumpAndSettle();
      }
      
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 3);
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10)); // Sube
      
      // Va a su perfil a ver cómo se ve en su muro
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 6); // Admira su post
      
      expect($('Mirad lo que he hecho hoy!').exists, true);
    });

    patrolTest('Variante 2: Escribe medio post y le da cancelar (botón atrás) y descarta', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'La verdad es que no sé qué publicar...', makeMistake: false);
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 6); // Se lo piensa
      
      // Se arrepiente
      await $(#backButton).tap();
      await $.pumpAndSettle();
      
      // Si hay dialog de confirmación "Desechar borrador"
      if (await $('Descartar').exists) {
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
        await $('Descartar').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 3: Sube 4 imágenes de golpe', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'Álbum completo E2E', makeMistake: false);
      
      if (await $(#addPhotoIcon).exists) {
        await $(#addPhotoIcon).tap();
        await $.pumpAndSettle();
        // Simular selección múltiple (puede no ser posible en mock, tap 4 veces)
        for (int i=0; i<4; i++) {
          await $('Mocked Image').tap();
          await $.pumpAndSettle();
        }
      }
      
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));
    });

    patrolTest('Variante 4: Intenta publicar sin contenido y la app le avisa', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      await $('Publicar').tap();
      await $.pumpAndSettle();
      
      expect($('vacía').exists, true);
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3); // Lee error
      
      await $(#backButton).tap();
      await $.pumpAndSettle();
    });

    patrolTest('Variante 5: Publica y al volver al feed lo refresca rápido para ver si alguien le ha dado like ya', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      await humano.humanType($(#postTextInput), 'Rápido', makeMistake: false);
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      // Ansioso por likes
      for (int i=0; i<5; i++) {
        await $.native.swipe(from: const Offset(0.5, 0.2), to: const Offset(0.5, 0.8));
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      }
    });

    patrolTest('Variante 6: Borra un post antiguo suyo', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      if (await $(#postOpcionesButton).exists) {
        await $(#postOpcionesButton).first.tap();
        await $.pumpAndSettle();
        
        await $('Eliminar').tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
        await $('Sí, eliminar').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 7: Edita la privacidad de su perfil', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await $(#opcionesPerfilButton).tap();
      await $.pumpAndSettle();
      
      await $('Privacidad').tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      if (await $(#switchPerfilPrivado).exists) {
        await $(#switchPerfilPrivado).tap();
        await $.pumpAndSettle();
      }
      
      await $(#backButton).tap();
      await $.pumpAndSettle();
    });

    patrolTest('Variante 8: Publica, entra a la comunidad, y lo republica ahí', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      // Esta vez publica estando DENTRO de una comunidad
      await $(#bottomNavExplore).tap();
      await $(#comunidadCardItem).first.tap();
      await $.pumpAndSettle();
      
      if (await $(#fabCreatePost).exists) {
        await $(#fabCreatePost).tap();
        await $.pumpAndSettle();
        
        await humano.humanType($(#postTextInput), 'Post para esta comunidad', makeMistake: false);
        await $('Publicar').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        
        expect($('Post para esta comunidad').exists, true);
      }
    });

    patrolTest('Variante 9: Abre crear post, escribe, cambia a otra app y luego vuelve a continuar', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'Texto inicial ', makeMistake: false);
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      await $.native.pressHome(); // Busca un link en Chrome
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 6);
      
      await $.native.openApp(); // Vuelve
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'y sigo escribiendo.', makeMistake: false);
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    });

    patrolTest('Variante 10: Escribe comentarios en posts de los demás sin parar', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      await loginHelper($);
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      for (int i=0; i<3; i++) {
        if (await $(#commentButton).exists) {
          await $(#commentButton).first.tap();
          await $.pumpAndSettle();
          
          await humano.humanType($(#commentInputTextField), '¡Genial!', makeMistake: false);
          await $(#sendCommentButton).tap();
          await $.pumpAndSettle();
          
          await $(#backButton).tap();
          await $.pumpAndSettle();
        }
        await $.native.swipe(from: const Offset(0.5, 0.7), to: const Offset(0.5, 0.4));
        await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      }
    });

  });
}
