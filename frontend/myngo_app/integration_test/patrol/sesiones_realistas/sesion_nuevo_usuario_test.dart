import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;
import '../helpers/human_simulator.dart';

void main() {
  group('Sesión Hiper-Realista: Usuario Nuevo', () {
    
    patrolTest('Variante 1: Registro feliz clásico con equivocación en el email, explora feed y sale', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      // Mira la pantalla de inicio un rato
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      // Empieza a rellenar el formulario
      await humano.humanType($(#nombreUsuarioInput), 'nuevo_humano_1', makeMistake: false);
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
      
      // Comete un error de tipeo a propósito simulando dedos torpes
      await humano.humanType($(#emailInput), 'humano1@test.com', makeMistake: true);
      
      await humano.humanType($(#passwordInput), 'Password123!', makeMistake: false);
      await humano.humanType($(#confirmarPasswordInput), 'Password123!', makeMistake: false);
      
      // Duda antes de darle a registrar
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      // Entra al feed. Se queda mirando la UI.
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 7);
      
      // Hace scroll lento
      if (await $(#listaPublicaciones).exists) {
        await humano.humanScroll($(#listaPublicaciones), times: 3);
      }
      
      // Ve un post que le gusta, entra
      if (await $(#postItemCard).exists) {
        await $(#postItemCard).first.tap();
        await $.pumpAndSettle();
        
        // Lee el post
        await humano.pauseToRead(minSeconds: 5, maxSeconds: 8);
        
        // Vuelve atrás
        await $(#backButton).tap();
        await $.pumpAndSettle();
      }
      
      // Sale de la app (simulado cerrando test)
      await humano.pauseToRead(minSeconds: 1, maxSeconds: 2);
    });

    patrolTest('Variante 2: Falla la confirmación de contraseña, se frustra, corrige, entra al feed, ve perfil vacío', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#nombreUsuarioInput), 'humano_2', makeMistake: false);
      await humano.humanType($(#emailInput), 'humano2@test.com', makeMistake: false);
      
      // Pone contraseñas distintas
      await humano.humanType($(#passwordInput), 'Password123!', makeMistake: false);
      await humano.humanType($(#confirmarPasswordInput), 'Passwrod123!', makeMistake: false); // Error
      
      await $('Registrarse').tap();
      await $.pumpAndSettle();
      
      // Lee el error, se frustra (pausa larga)
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      // Borra y corrige
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      // Va a su propio perfil a ver cómo quedó
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      await $(#bottomNavProfile).tap();
      await $.pumpAndSettle();
      
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 6);
    });

    patrolTest('Variante 3: Usuario ansioso. Entra al feed, pulsa todos los tabs del BottomNav rápidamente sin leer', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('ansioso3');
      await $(#emailInput).enterText('ansioso3@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      // Toca todo súper rápido
      await $(#bottomNavExplore).tap();
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 0, maxSeconds: 1); // Casi sin pausa
      
      await $(#bottomNavMessages).tap();
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 0, maxSeconds: 1);
      
      await $(#notificacionesIcon).tap();
      await $.pumpAndSettle();
      await humano.pauseToRead(minSeconds: 0, maxSeconds: 1);
      
      await $(#backButton).tap();
      await $.pumpAndSettle();
      
      await $(#bottomNavHome).tap();
      await $.pumpAndSettle();
    });

    patrolTest('Variante 4: Entra, le gusta el primer post que ve, se mete al perfil de ese autor, luego sale de la app', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('perfilero4');
      await $(#emailInput).enterText('perfilero4@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      if (await $(#postItemCard).exists) {
        await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
        
        // Toca el avatar del autor
        if (await $(#postAuthorAvatar).exists) {
          await $(#postAuthorAvatar).first.tap();
          await $.pumpAndSettle();
          
          await humano.pauseToRead(minSeconds: 5, maxSeconds: 7); // Cotillea el perfil
          
          await $(#backButton).tap();
          await $.pumpAndSettle();
        }
      }
    });

    patrolTest('Variante 5: Llega al registro, se arrepiente, vuelve al login, luego se registra', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await humano.hesitateAndTap($('Regístrate aquí'), $(#backButton));
      
      // Ahora entra de verdad y lo hace
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('arrepentido5');
      await $(#emailInput).enterText('arrepentido5@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      expect($('Feed Global').exists || $(#bottomNavHome).exists, true);
    });

    patrolTest('Variante 6: Registro exitoso, intenta crear un post pero se le cierra la app a medias', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('creador6');
      await $(#emailInput).enterText('creador6@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      await $(#fabCreatePost).tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#postTextInput), 'Iba a escribir algo muy intere...', makeMistake: false);
      
      // Se simula salida forzosa (minimizar app) y volver a entrar
      await $.native.pressHome();
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      await $.native.openApp();
      await $.pumpAndSettle();
      
      // En flutter, si minimizas sin matar, sigues en la misma pantalla
      expect($(#postTextInput).exists, true);
    });

    patrolTest('Variante 7: Comete error en el email (no arroba) y recibe warning en vivo', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await humano.humanType($(#nombreUsuarioInput), 'usuario7', makeMistake: false);
      
      // Escribe sin arroba
      await humano.humanType($(#emailInput), 'usuario7gmail.com', makeMistake: false);
      
      // Al tocar otro campo, si hay validación onChange o onFocusLost, salta.
      await $(#passwordInput).tap();
      await $.pumpAndSettle();
      
      // Simular que el humano lee el error
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      // Vuelve a corregir
      await $(#emailInput).enterText('usuario7@gmail.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    });

    patrolTest('Variante 8: Trata de hacer login en lugar de registro por confusión, luego se da cuenta', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      // Es un usuario nuevo, pero intenta hacer login porque se confunde de botón
      await humano.humanType($(#emailLoginInput), 'nuevo8@test.com', makeMistake: false);
      await humano.humanType($(#passwordLoginInput), 'Password123!', makeMistake: false);
      await $('Iniciar Sesión').tap();
      await $.pumpAndSettle();
      
      // Ve el error "credenciales incorrectas"
      await humano.pauseToRead(minSeconds: 3, maxSeconds: 5);
      
      // Entiende que tiene que registrarse
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('nuevo8');
      await $(#emailInput).enterText('nuevo8@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    });

    patrolTest('Variante 9: Abre la app, la minimiza, vuelve, se registra', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      // Mira la pantalla 2 segs y alguien le habla en la vida real, minimiza la app
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 3);
      await $.native.pressHome();
      
      await humano.pauseToRead(minSeconds: 4, maxSeconds: 6);
      
      // Vuelve
      await $.native.openApp();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('distraido9');
      await $(#emailInput).enterText('distraido9@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    });

    patrolTest('Variante 10: Se registra, da permisos nativos de notificaciones nada más entrar (si los pide la app)', (PatrolIntegrationTester $) async {
      final humano = HumanSimulator($);
      app.main();
      await $.pumpAndSettle();
      
      await $('Regístrate aquí').tap();
      await $.pumpAndSettle();
      
      await $(#nombreUsuarioInput).enterText('permisos10');
      await $(#emailInput).enterText('permisos10@test.com');
      await $(#passwordInput).enterText('Password123!');
      await $(#confirmarPasswordInput).enterText('Password123!');
      await $('Registrarse').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      
      await humano.pauseToRead(minSeconds: 2, maxSeconds: 4);
      
      // Si la app escupe un popup nativo de "Allow Notifications" nada más entrar al feed
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }
      
      // Verifica que está dentro
      expect($('Feed Global').exists || $(#bottomNavHome).exists, true);
    });
  });
}
