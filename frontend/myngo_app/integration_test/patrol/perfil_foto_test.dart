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

  group('Flujos E2E - Foto de Perfil', () {
    patrolTest(
      'Usuario cambia su foto de perfil desde el detalle de perfil',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Navegar al perfil propio desde la barra inferior
        if (await $(#bottomNavProfile).exists) {
          await $(#bottomNavProfile).tap();
          await $.pumpAndSettle();
        } else if (await $(#profileIconNav).exists) {
          await $(#profileIconNav).tap();
          await $.pumpAndSettle();
        }

        // Pulsar el avatar para cambiarlo (icono de cámara)
        if (await $(#editAvatarButton).exists) {
          await $(#editAvatarButton).tap();
          await $.pumpAndSettle();
        } else if (await $(#avatarCameraIcon).exists) {
          await $(#avatarCameraIcon).tap();
          await $.pumpAndSettle();
        }

        // Seleccionar una imagen mockeada desde la galería
        await $.native.pickImageFromGallery();
        await $.pumpAndSettle(timeout: const Duration(seconds: 15));

        // Verificar que la operación fue exitosa
        expect(
          $('Avatar actualizado').exists ||
          $('Perfil actualizado').exists ||
          $('éxito').exists,
          true,
        );
      },
    );

    patrolTest(
      'Usuario cambia su foto de perfil desde personalización de perfil',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Navegar al perfil propio
        if (await $(#bottomNavProfile).exists) {
          await $(#bottomNavProfile).tap();
          await $.pumpAndSettle();
        } else if (await $(#profileIconNav).exists) {
          await $(#profileIconNav).tap();
          await $.pumpAndSettle();
        }

        // Abrir pantalla de personalización
        if (await $(#customizeProfileButton).exists) {
          await $(#customizeProfileButton).tap();
          await $.pumpAndSettle();
        } else if (await $('Personalizar Perfil').exists) {
          await $('Personalizar Perfil').tap();
          await $.pumpAndSettle();
        }

        // Seleccionar avatar
        if (await $(#avatarSection).exists) {
          await $(#avatarSection).tap();
          await $.pumpAndSettle();
        } else if (await $('Avatar').exists) {
          await $('Avatar').tap();
          await $.pumpAndSettle();
        }

        // Elegir imagen de galería
        await $.native.pickImageFromGallery();
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));

        // Guardar cambios
        if (await $('Guardar Cambios').exists) {
          await $('Guardar Cambios').tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 10));
        }

        // Verificar éxito
        expect(
          $('Guardado').exists ||
          $('éxito').exists ||
          $('Perfil personalizado').exists,
          true,
        );
      },
    );
  });
}
