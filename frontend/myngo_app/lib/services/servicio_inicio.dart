import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publicacion.dart';
import '../models/imagen_galeria.dart';
import '../models/respuesta_api.dart';
import 'servicio_usuarios.dart';

/// Servicio para la pantalla de inicio.
class ServicioInicio {
  static const String _urlBase = 'http://127.0.0.1:8000/contenido/';
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene publicaciones de comunidades públicas para el feed de inicio.
  Future<RespuestaApi<List<Publicacion>>> obtenerPostsInicio({String? query}) async {
    try {
      String url = '${_urlBase}publicaciones/';
      if (query != null && query.trim().isNotEmpty) {
        url += '?search=${Uri.encodeComponent(query.trim())}';
      }
      
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> lista = datos is List ? datos : (datos['results'] ?? []);
        final posts = lista.map((i) => Publicacion.fromJson(i)).toList();
        
        // Ordenar por popularidad (likes + comentarios) si no hay query
        if (query == null || query.isEmpty) {
          posts.sort((a, b) => (b.likesCount + b.comentariosCount).compareTo(a.likesCount + a.comentariosCount));
        }

        return RespuestaApi(
          exito: true,
          datos: posts,
          mensaje: 'Posts de inicio cargados',
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Miau... No hemos podido conectar con el servidor. ¡Comprueba tu red! 🐾');
    }
  }

  /// Obtiene imágenes aleatorias (mantenido por compatibilidad si se requiere en otras partes).
  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleriaInicio({String? query}) async {
    try {
      return RespuestaApi(exito: false, mensaje: 'No implementado');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
