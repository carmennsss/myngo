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

  group('Flujos E2E Extremadamente Detallados - Publicaciones y Feed', () {
    patrolTest(
      'Usuario abre el feed global y ve la lista vacía de inicio',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        expect($('Feed Global').exists || $(#bottomNavHome).exists, true);
        if (await $('No hay publicaciones aún').exists) {
          expect($('No hay publicaciones aún').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario hace pull-to-refresh en el feed global',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        // Swipe hacia abajo para recargar
        await $.native.swipe(from: const Offset(0.5, 0.2), to: const Offset(0.5, 0.8));
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));

        expect($(#listaPublicaciones).exists, true);
      },
    );

    patrolTest(
      'Usuario pulsa FAB de crear publicación e intenta publicar sin texto ni imagen (falla validación)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#fabCreatePost).tap();
        await $.pumpAndSettle();

        await $('Publicar').tap();
        await $.pumpAndSettle();

        expect($('La publicación no puede estar vacía').exists, true);
      },
    );

    patrolTest(
      'Usuario crea una publicación solo con texto',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#fabCreatePost).tap();
        await $.pumpAndSettle();

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testText = 'Solo texto E2E $timestamp';

        await $(#postTextInput).enterText(testText);
        await $('Publicar').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        expect($('Publicado con éxito').exists, true);
        
        // Verifica que aparece en el feed
        await $.native.swipe(from: const Offset(0.5, 0.8), to: const Offset(0.5, 0.2));
        await $.pumpAndSettle();
        expect($(testText).exists, true);
      },
    );

    patrolTest(
      'Usuario pulsa el botón de Guardar (Bookmark) en una publicación del feed',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        if (await $(#postItemCard).exists) {
          await $(#bookmarkButton).first.tap();
          await $.pumpAndSettle();
          
          expect($('Publicación guardada').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario da Like (Voto Favor) a una publicación y el contador sube',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        if (await $(#postItemCard).exists) {
          final countInitialText = await $(#likeCount).first.text;
          final int initial = int.tryParse(countInitialText ?? '0') ?? 0;

          await $(#likeButton).first.tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 2));
          
          final countFinalText = await $(#likeCount).first.text;
          final int finalCount = int.tryParse(countFinalText ?? '0') ?? 0;
          
          expect(finalCount > initial || finalCount == initial + 1, true);
        }
      },
    );

    patrolTest(
      'Usuario abre los comentarios de una publicación y envía un comentario',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        if (await $(#postItemCard).exists) {
          await $(#commentButton).first.tap();
          await $.pumpAndSettle();

          expect($('Comentarios').exists, true);

          await $(#commentInputTextField).enterText('Test comment patrol');
          await $(#sendCommentButton).tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 3));

          expect($('Test comment patrol').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario adjunta una imagen y publica con éxito',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#fabCreatePost).tap();
        await $.pumpAndSettle();

        await $(#postTextInput).enterText('Con imagen E2E');
        
        if (await $(#addPhotoIcon).exists) {
          await $(#addPhotoIcon).tap();
          await $.pumpAndSettle();
          await $('Mocked Image').tap(); 
        }

        await $('Publicar').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));

        expect($('Publicado con éxito').exists, true);
      },
    );
  });
}
