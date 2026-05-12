import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';
import 'package:intl/message_format.dart';
import 'package:tolgee/src/translations/tolgee_translation_strategy.dart';
import 'package:provider/provider.dart';
import '../providers/locale_notifier.dart';

/// Helper para traducciones usando Tolgee de forma estática.
class TrHelper {
  /// Traduce una clave y permite pasar argumentos.
  /// Si se proporciona [context] y [defaultValue], se puede usar como fallback si Tolgee falla.
  static String tr(BuildContext context, String key, {Map<String, dynamic>? args, String? defaultValue}) {
    // Escuchar cambios de idioma para forzar rebuild del widget que llama a tr()
    try {
      Provider.of<LocaleNotifier>(context, listen: true);
    } catch (_) {
      // Si no hay provider en el contexto (ej: en el router), fallamos silenciosamente
    }

    try {
      final result = TolgeeTranslationsStrategy.instance.translate(key);
      
      if (result == null || result == key) {
        return defaultValue ?? key;
      }

      if (args == null) return result;
      
      final convertedArgs = args.map((k, v) => MapEntry(k, v as Object));
      return MessageFormat(result).format(convertedArgs);
    } catch (e) {
      return defaultValue ?? key;
    }
  }

  /// Versión simple de tr que no requiere contexto.
  static String translate(String key, [Map<String, dynamic>? args]) {
    try {
      final result = TolgeeTranslationsStrategy.instance.translate(key) ?? key;
      if (args == null) return result;
      final convertedArgs = args.map((k, v) => MapEntry(k, v as Object));
      return MessageFormat(result).format(convertedArgs);
    } catch (e) {
      return key;
    }
  }
}

/// Función global para compatibilidad. Permite uso posicional o nombrado.
String tr(String key, [Map<String, dynamic>? args]) {
  return TrHelper.translate(key, args);
}

/// Alias para soportar llamadas con parámetros nombrados como 'params'
String trNamed(String key, {Map<String, dynamic>? params}) {
  return TrHelper.translate(key, params);
}

/// Widget que permite envolver partes de la UI para que reaccionen al cambio de idioma.
/// Proporciona una función [tr] local al builder.
class TrWidget extends StatelessWidget {
  final Widget Function(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) builder;

  const TrWidget({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el locale para forzar el rebuild del builder
    context.watch<LocaleNotifier>();
    
    // Pasamos una función tr que ya lleva el contexto si fuera necesario.
    return builder(context, (String key, [Map<String, dynamic>? args]) {
      return TrHelper.translate(key, args);
    });
  }
}
