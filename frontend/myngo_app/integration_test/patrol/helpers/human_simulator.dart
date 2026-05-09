import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

class HumanSimulator {
  final PatrolIntegrationTester $;
  final Random _rnd = Random();

  HumanSimulator(this.$);

  /// Simula el tiempo que un usuario real tardaría en leer una pantalla o pensar.
  Future<void> pauseToRead({int minSeconds = 2, int maxSeconds = 5}) async {
    final secs = _rnd.nextInt(maxSeconds - minSeconds + 1) + minSeconds;
    await Future.delayed(Duration(seconds: secs));
    await $.pumpAndSettle();
  }

  /// Simula una escritura humana realista, letra por letra, con posibilidad de error tipográfico y corrección.
  Future<void> humanType(Finder finder, String text, {bool makeMistake = true}) async {
    await $(finder).tap();
    await $.pumpAndSettle();

    String currentText = '';
    
    // Punto donde cometerá el error
    int mistakeIndex = makeMistake && text.length > 3 ? _rnd.nextInt(text.length - 2) + 1 : -1;

    for (int i = 0; i < text.length; i++) {
      if (i == mistakeIndex) {
        // Escribe una letra errónea
        currentText += String.fromCharCode(text.codeUnitAt(i) + 1);
        await $(finder).enterText(currentText);
        await Future.delayed(Duration(milliseconds: 150 + _rnd.nextInt(200)));
        
        // Se da cuenta del error
        await Future.delayed(Duration(milliseconds: 500));
        
        // Borra la letra
        currentText = currentText.substring(0, currentText.length - 1);
        await $(finder).enterText(currentText);
        await Future.delayed(Duration(milliseconds: 300));
      }

      currentText += text[i];
      await $(finder).enterText(currentText);
      
      // Retraso entre teclas (velocidad de escritura variable)
      await Future.delayed(Duration(milliseconds: 50 + _rnd.nextInt(150)));
    }
    
    // Ocultar teclado
    FocusManager.instance.primaryFocus?.unfocus();
    await $.pumpAndSettle();
  }

  /// Simula un scroll natural, parando para leer el contenido que va pasando.
  Future<void> humanScroll(Finder listFinder, {int times = 3}) async {
    for (int i = 0; i < times; i++) {
      await $.native.swipe(
        from: const Offset(0.5, 0.7),
        to: const Offset(0.5, 0.3),
      );
      await pauseToRead(minSeconds: 1, maxSeconds: 3);
    }
  }

  /// Simula un toque errático, donde el usuario pulsa un botón pero se arrepiente y vuelve atrás.
  Future<void> hesitateAndTap(Finder target, Finder backButton) async {
    await pauseToRead(minSeconds: 1, maxSeconds: 2);
    await $(target).tap();
    await $.pumpAndSettle();
    
    // Arrepentimiento rápido
    await Future.delayed(const Duration(milliseconds: 600));
    await $(backButton).tap();
    await $.pumpAndSettle();
    
    // Ahora sí entra de verdad
    await pauseToRead(minSeconds: 1, maxSeconds: 2);
    await $(target).tap();
    await $.pumpAndSettle();
  }
}
