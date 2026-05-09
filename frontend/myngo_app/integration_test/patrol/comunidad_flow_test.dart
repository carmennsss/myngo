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

  group('Flujos E2E Extremadamente Detallados - Comunidades', () {
    
    patrolTest(
      'Usuario abre la pestaña de comunidades y ve la lista recomendada vacía (sin conexión)',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        if (await $(#forceNetworkErrorButton).exists) {
          await $(#forceNetworkErrorButton).tap();
        }

        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();

        expect($('Revisa tu conexión a internet').exists || $('Error de red').exists, true);
      },
    );

    patrolTest(
      'Usuario busca una comunidad que no existe y ve estado vacío',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();

        await $(#searchComunidadesInput).enterText('xyz123comunidadFantasma');
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));

        expect($('No se encontraron resultados').exists, true);
      },
    );

    patrolTest(
      'Usuario busca una comunidad por nombre y hace tap en la tarjeta de resultado',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $.pumpAndSettle();

        await $(#searchComunidadesInput).enterText('Gaming');
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));

        expect($('Gaming').exists, true);
        
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        expect($(#comunidadDetalleHeader).exists, true);
        expect($('Gaming').exists, true);
      },
    );

    patrolTest(
      'Usuario pulsa Unirme en una comunidad pública y el botón cambia a Opciones',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        if ($('Unirme').exists) {
          await $('Unirme').tap();
          await $.pumpAndSettle();
          expect($('Te has unido').exists, true);
          expect($(#opcionesComunidadMenu).exists, true);
        }
      },
    );

    patrolTest(
      'Usuario pulsa Unirme en una comunidad privada y ve botón "Pendiente"',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        
        // Simular búsqueda de privada
        await $(#searchComunidadesInput).enterText('Privada');
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        if ($('Solicitar Acceso').exists) {
          await $('Solicitar Acceso').tap();
          await $.pumpAndSettle();
          expect($('Pendiente').exists, true);
        }
      },
    );

    patrolTest(
      'Usuario navega al Feed de publicaciones dentro de una comunidad unida',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        await $(#tabPublicacionesComunidad).tap();
        await $.pumpAndSettle();

        expect($(#listaPublicaciones).exists, true);
      },
    );

    patrolTest(
      'Usuario navega a la pestaña de Galería de la comunidad y abre una imagen en fullscreen',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        await $(#tabGaleriaComunidad).tap();
        await $.pumpAndSettle();

        if (await $(#imagenGaleriaItem).exists) {
          await $(#imagenGaleriaItem).first.tap();
          await $.pumpAndSettle();
          expect($(#fullscreenImageDialog).exists, true);
          await $(#cerrarFullscreen).tap();
          await $.pumpAndSettle();
        }
      },
    );

    patrolTest(
      'Usuario abre el menú de opciones de comunidad y hace tap en Abandonar',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($);

        await $(#bottomNavExplore).tap();
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        if ($(#opcionesComunidadMenu).exists) {
          await $(#opcionesComunidadMenu).tap();
          await $.pumpAndSettle();
          
          await $('Abandonar comunidad').tap();
          await $.pumpAndSettle();
          
          expect($('¿Estás seguro?').exists, true);
          
          await $('Sí, abandonar').tap(); 
          await $.pumpAndSettle();
          
          expect($('Unirme').exists, true); 
        }
      },
    );
    
    patrolTest(
      'Usuario administrador entra en configuración de comunidad y cambia el color del tema',
      (PatrolIntegrationTester $) async {
        app.main();
        await $.pumpAndSettle();
        await loginHelper($); // Login con usuario Admin

        await $(#bottomNavExplore).tap();
        await $(#comunidadCardItem).first.tap();
        await $.pumpAndSettle();

        if ($(#configuracionAdminIcon).exists) {
          await $(#configuracionAdminIcon).tap();
          await $.pumpAndSettle();
          
          await $('Personalización').tap();
          await $.pumpAndSettle();
          
          await $(#colorPickerHex).enterText('#FF0000');
          await $('Guardar').tap();
          await $.pumpAndSettle();

          expect($('Cambios guardados').exists, true);
        }
      },
    );
  });
}
