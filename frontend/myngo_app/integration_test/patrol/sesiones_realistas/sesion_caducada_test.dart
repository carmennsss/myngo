import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario que vuelve tras mucho tiempo (Sesión Caducada)', () {

    patrolTest('Variante 1: Abre app, ve el login (token expirado), se frustra, recupera pass', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      // Asumimos que la app lo tiró al login directo.
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); // "Pero si yo ya estaba logueado"
      
      if (await $('Olvidé mi contraseña').exists) {
        await $('Olvidé mi contraseña').tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
        await $(#emailInput).enterText('caducado@test.com');
        await $('Enviar enlace de recuperación').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 4));
        
        expect($('revisa tu correo').exists, true);
        await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
        
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 2: Vuelve tras meses. Hace login, le han expulsado de su comunidad por inactividad', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await humano.humanType($(#emailLoginInput), 'fantasma@test.com', makeMistake: false);
      await humano.humanType($(#passwordLoginInput), 'Password123!', makeMistake: false);
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      
      await $('Mis Comunidades').tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 6);
      expect($('No estás en ninguna comunidad').exists || $(#comunidadCardItem).exists == false, true);
    });

    patrolTest('Variante 3: Tiene 99+ notificaciones. Hace scroll eterno y no lee nada', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('fantasma@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#notificacionesIcon).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // "Madre mía"
      
      await humano.humanScroll($(#listaNotificaciones), times: 6); // Scroll infinito
      
      if (await $('Marcar todas como leídas').exists) {
        await $('Marcar todas como leídas').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 4: Sus chats están llenos de mensajes nuevos. Entra al primero y lee.', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('fantasma@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5); 
      
      if (await $(#chatListItem).exists) {
        await $(#chatListItem).first.tap();
        await $.pumpAndSettle();
        
        await humano.pauseToRead(minSeconds: 8, maxSeconds: 15); // Mucho que leer
        
        await humano.humanType($(#chatInputTextField), 'Siento la demora, he vuelto', makeMistake: true);
        await $(#sendChatButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 5: Intenta usar funciones nuevas que no entiende (Ej: Peticiones de mejora)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('fantasma@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await $('Tienda de Mejoras').tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 6, maxSeconds: 8); // "¿Qué es esto de Myngo Points?"
      
      await $(#tabPeticionesMejora).tap();
      await $.pumpAndSettle();
      
      await humano.humanScroll($(#listaPeticiones), times: 2);
      
      if (await $(#votarPeticionButton).exists) {
        await $(#votarPeticionButton).first.tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 6: Ve que un usuario que seguía ha borrado su cuenta (404 en perfil)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('fantasma@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavProfile).tap();
      await $('Siguiendo').tap();
      await $.pumpAndSettle();
      
      if (await $(#userSearchResultItem).exists) {
        // Toca al primer amigo
        await $(#userSearchResultItem).first.tap();
        await $.pumpAndSettle();
        
        // Simular 404 perfil no existe
        if (await $(#forceProfile404).exists) await $(#forceProfile404).tap();
        
        expect($('Este usuario ya no existe').exists || $('Perfil no encontrado').exists, true);
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 4);
        
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 7: Borra la app desde la multitarea y no vuelve (simulado)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4); // Ve el login y no se acuerda de la pass
      
      // Simula matar la app en sistema (no openApp después)
      await $.native.pressHome();
    });

    patrolTest('Variante 8: Se olvida de su email, prueba con varios', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await humano.humanType($(#emailLoginInput), 'viejo1@test.com', makeMistake: false);
      await humano.humanType($(#passwordLoginInput), 'Password123!', makeMistake: false);
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 4));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      await $(#emailLoginInput).enterText('viejo2@test.com');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 4));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      await $(#emailLoginInput).enterText('fantasma@test.com'); // El bueno
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 4));
      
      expect($('Feed Global').exists || $(#bottomNavHome).exists, true);
    });

    patrolTest('Variante 9: Abre la app pero le sale un cartel de Forzar Actualización', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      if (await $(#forceUpdateMockDialog).exists) {
        expect($('Actualización requerida').exists, true);
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
        
        await $('Actualizar ahora').tap();
        await $.pumpAndSettle();
      }
    });

    patrolTest('Variante 10: Tras volver, publica "He vuelto!" y se auto-da Like', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $(#emailLoginInput).enterText('fantasma@test.com');
      await $(#passwordLoginInput).enterText('Password123!');
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), '¡Hola a todos! Cuánto tiempo', makeMistake: false);
      await $('Publicar').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      // Auto-like
      if (await $(#likeButton).exists) {
        await $(#likeButton).first.tap();
        await $.pumpAndSettle();
      }
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
    });
  });
}
