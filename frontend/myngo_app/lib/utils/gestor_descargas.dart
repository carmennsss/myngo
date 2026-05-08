import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// Importación condicional para Web
import 'gestor_descargas_web.dart' if (dart.library.io) 'gestor_descargas_mobile.dart';

/// Clase utilidad para gestionar descargas de archivos (imágenes/vídeos)
/// de forma consistente entre Web y Mobile.
class GestorDescargas {
  
  /// Inicia la descarga de un archivo desde una URL.
  /// En Web, intenta forzar la descarga usando Blobs (si CORS lo permite)
  /// o abre una nueva pestaña como fallback.
  static Future<void> descargar(String url, {String? nombreSugerido}) async {
    try {
      if (url.isEmpty) return;
      
      final uri = Uri.parse(url);
      String nombre = nombreSugerido ?? '';
      
      if (nombre.isEmpty) {
        if (uri.pathSegments.isNotEmpty) {
          nombre = uri.pathSegments.last;
        } else {
          nombre = 'archivo_myngo_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      if (kIsWeb) {
        // En Web usamos la implementación específica que usa dart:html
        await descargarArchivoWeb(url, nombre);
      } else {
        // En Mobile, abrimos externamente para que el navegador gestione la descarga
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Re-lanzamos para que la UI pueda mostrar un snackbar si lo desea,
      // pero con un log para debug.
      print('[GestorDescargas] Error en descarga: $e');
      rethrow;
    }
  }
}
