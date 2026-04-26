import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../models/publicacion.dart';
import 'servicio_usuarios.dart';
import '../utils/configuracion.dart';

/// Servicio independiente para los feeds de inicio (Social y Galería).
class ServicioInicio {
  static const String _urlBase = '${Configuracion.baseUrl}/contenido';
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene publicaciones del feed de inicio (Galería - solo imágenes).
  Future<RespuestaApi<List<Publicacion>>> obtenerPostsInicio({
    int limit = 20,
    int offset = 0,
    String? etiquetas,
  }) async {
    try {
      String url = '$_urlBase/inicio_galeria/?limit=$limit&offset=$offset';
      if (etiquetas != null && etiquetas.isNotEmpty) {
        url += '&etiquetas=${Uri.encodeComponent(etiquetas)}';
      }

      final respuesta = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final String decodedBody = utf8.decode(respuesta.bodyBytes);
        final dynamic body = jsonDecode(decodedBody);
        final List<dynamic> results = body is Map ? (body['results'] ?? []) : [];
        
        return RespuestaApi(
          exito: true,
          mensaje: 'Galería de inicio cargada',
          datos: results.map((j) => Publicacion.fromJson(j as Map<String, dynamic>)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar galería: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene publicaciones del feed social (Todos los posts - estilo Threads).
  Future<RespuestaApi<List<Publicacion>>> obtenerFeedSocial({
    int limit = 20,
    int offset = 0,
    String? etiquetas,
  }) async {
    try {
      String url = '$_urlBase/inicio_feed/?limit=$limit&offset=$offset';
      if (etiquetas != null && etiquetas.isNotEmpty) {
        url += '&etiquetas=${Uri.encodeComponent(etiquetas)}';
      }

      final respuesta = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final String decodedBody = utf8.decode(respuesta.bodyBytes);
        final dynamic body = jsonDecode(decodedBody);
        final List<dynamic> results = body is Map ? (body['results'] ?? []) : [];
        
        return RespuestaApi(
          exito: true,
          mensaje: 'Feed social cargado',
          datos: results.map((j) => Publicacion.fromJson(j as Map<String, dynamic>)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar feed social: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
