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

  group('Flujos E2E - Galería y Subida de Imágenes', () {
    patrolTest(
      'Usuario abre la galería de una comunidad y ve el grid vacío',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Navegar a la pestaña de comunidades
        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();

        // Buscar y entrar en una comunidad
        if (await $(#communityCard).exists) {
          await $(#communityCard).first.tap();
          await $.pumpAndSettle();
        }

        // Ir a la pestaña de galería dentro de la comunidad
        await $('GALERÍA').tap();
        await $.pumpAndSettle();

        // Verificar que el grid de galería está presente
        expect($(#masonryGrid).exists, true);
      },
    );

    patrolTest(
      'Usuario sube una imagen a la galería de comunidad con éxito',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Navegar a comunidades y entrar a una
        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();
        if (await $(#communityCard).exists) {
          await $(#communityCard).first.tap();
          await $.pumpAndSettle();
        }

        // Ir a galería
        await $('GALERÍA').tap();
        await $.pumpAndSettle();

        // Pulsar el FAB/Botón de subir imagen
        if (await $(#uploadImageFab).exists) {
          await $(#uploadImageFab).tap();
          await $.pumpAndSettle();
        } else if (await $(#galleryUploadButton).exists) {
          await $(#galleryUploadButton).tap();
          await $.pumpAndSettle();
        }

        // Seleccionar imagen desde la galería nativa mockeada
        await $.native.pickImageFromGallery();
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));

        // Verificar que el toast de éxito aparece
        expect(
          $('Imagen subida correctamente').exists ||
          $('Subida exitosa').exists,
          true,
        );
      },
    );

    patrolTest(
      'Usuario intenta subir imagen sin conexión y ve error de red',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Desactivar WiFi para simular error de red
        await $.native.disableWifi();
        await $.pumpAndSettle();

        // Navegar a galería
        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();
        if (await $(#communityCard).exists) {
          await $(#communityCard).first.tap();
          await $.pumpAndSettle();
        }
        await $('GALERÍA').tap();
        await $.pumpAndSettle();

        // Intentar subir
        if (await $(#galleryUploadButton).exists) {
          await $(#galleryUploadButton).tap();
          await $.pumpAndSettle();

          await $.native.pickImageFromGallery();
          await $.pumpAndSettle(timeout: const Duration(seconds: 10));

          expect(
            $('Error').exists ||
            $('Error de conexión').exists ||
            $('inténtalo de nuevo').exists,
            true,
          );
        }

        // Restaurar conexión
        await $.native.enableWifi();
        await $.pumpAndSettle();
      },
    );
  });
}
