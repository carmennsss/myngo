import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myngo_app/main.dart' as app;

void main() {
  group('Flujos E2E Extremadamente Detallados - Auth y Perfil', () {
    
    patrolTest(
      'Flujo de Login con email vacío (falla validación local)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $(#passwordLoginInput).enterText('Password123!');
        await $('Iniciar Sesión').tap();
        await $.pumpAndSettle();

        expect($('Por favor ingresa tu correo electrónico').exists, true);
      },
    );

    patrolTest(
      'Flujo de Login con credenciales incorrectas (error del servidor)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $(#emailLoginInput).enterText('noexiste@test.com');
        await $(#passwordLoginInput).enterText('wrongpass');
        await $('Iniciar Sesión').tap();
        
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        expect($('Error en la autenticación').exists || $('credenciales').exists, true);
      },
    );

    patrolTest(
      'Flujo de Login exitoso y cierre de sesión posterior',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $(#emailLoginInput).enterText('patrol@test.com');
        await $(#passwordLoginInput).enterText('Password123!');
        await $('Iniciar Sesión').tap();
        
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // Estamos dentro de la app
        expect($('Feed Global').exists || $(#bottomNavHome).exists, true);

        // Navegar a perfil para cerrar sesión
        await $(#bottomNavProfile).tap();
        await $.pumpAndSettle();

        await $(#opcionesPerfilButton).tap();
        await $.pumpAndSettle();

        await $('Cerrar Sesión').tap();
        await $.pumpAndSettle();

        // Debe redirigir de vuelta al Login
        expect($('Iniciar Sesión').exists, true);
        expect($('Regístrate aquí').exists, true);
      },
    );

    patrolTest(
      'Flujo de Registro con contraseñas que no coinciden',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $('Regístrate aquí').tap();
        await $.pumpAndSettle();
        
        await $(#nombreUsuarioInput).enterText('testuser');
        await $(#emailInput).enterText('test@test.com');
        await $(#passwordInput).enterText('Password123!');
        await $(#confirmarPasswordInput).enterText('Password456!');
        
        await $('Registrarse').tap();
        await $.pumpAndSettle();

        expect($('Las contraseñas no coinciden').exists, true);
      },
    );

    patrolTest(
      'Flujo de Registro con email ya existente',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $('Regístrate aquí').tap();
        await $.pumpAndSettle();
        
        await $(#nombreUsuarioInput).enterText('patrol');
        await $(#emailInput).enterText('patrol@test.com'); // Ya existe
        await $(#passwordInput).enterText('Password123!');
        await $(#confirmarPasswordInput).enterText('Password123!');
        
        await $('Registrarse').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        expect($('correo ya está en uso').exists || $('error').exists, true);
      },
    );

    patrolTest(
      'Flujo completo de Registro feliz, auto-login y edición de perfil',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();

        await $('Regístrate aquí').tap();
        await $.pumpAndSettle();
        
        final uid = DateTime.now().millisecondsSinceEpoch;
        final newEmail = 'patrol$uid@test.com';

        await $(#nombreUsuarioInput).enterText('user$uid');
        await $(#emailInput).enterText(newEmail);
        await $(#passwordInput).enterText('Password123!');
        await $(#confirmarPasswordInput).enterText('Password123!');
        
        await $('Registrarse').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // Login con el nuevo user
        await $(#emailLoginInput).enterText(newEmail);
        await $(#passwordLoginInput).enterText('Password123!');
        await $('Iniciar Sesión').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // Editar perfil
        await $(#bottomNavProfile).tap();
        await $.pumpAndSettle();

        await $('Editar Perfil').tap();
        await $.pumpAndSettle();

        await $(#bioInput).enterText('Esta es mi nueva biografía e2e');
        await $('Guardar').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));

        expect($('Esta es mi nueva biografía e2e').exists, true);
      },
    );
  });
}
