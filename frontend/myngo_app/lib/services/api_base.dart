import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;

/// Clase base para centralizar la configuración de todas las peticiones de la App.
/// Aquí gestionamos los headers globales como el bypass de ngrok.
class ApiBase {
  /// Header obligatorio para saltar el aviso de ngrok en todas las peticiones.
  static const Map<String, String> _headersGlobales = {
    'ngrok-skip-browser-warning': 'true',
  };

  /// Genera el mapa de cabeceras estándar para peticiones http.
  static Map<String, String> obtenerHeaders({String? token, Map<String, String>? adicionales}) {
    final headers = {
      'Content-Type': 'application/json',
      ..._headersGlobales,
    };
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    if (adicionales != null) {
      headers.addAll(adicionales);
    }
    return headers;
  }

  /// Configura una instancia de Dio con los headers globales e interceptores.
  static void configurarDio(dio.Dio dioClient, {String? token}) {
    dioClient.options.headers.addAll(_headersGlobales);
    if (token != null) {
      dioClient.options.headers['Authorization'] = 'Token $token';
    }
    
    // Añadimos un interceptor para asegurar que el header esté en cada petición
    // por si acaso se limpian las opciones en algún punto.
    dioClient.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(_headersGlobales);
          return handler.next(options);
        },
      ),
    );
  }
}
