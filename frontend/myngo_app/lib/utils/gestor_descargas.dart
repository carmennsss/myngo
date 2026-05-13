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
        // En Mobile, abrimos externamente para que el navegador gestione la descarga.
        // Intentamos externalApplication primero para forzar al navegador.
        try {
          bool lanzado = false;
          if (await canLaunchUrl(uri)) {
            lanzado = await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          
          // Si falló canLaunch o launch, intentamos el modo por defecto como fallback.
          if (!lanzado) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } catch (e) {
          // Si todo falla, intentamos lanzar sin modo específico.
          await launchUrl(uri);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
