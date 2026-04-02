import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/imagen_galeria.dart';
import '../models/respuesta_api.dart';
import 'servicio_usuarios.dart';

/// Servicio para la pantalla de inicio: galería aleatoria estilo Pinterest.
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

  /// Obtiene imágenes aleatorias para el feed de inicio.
  /// Incluye imágenes de comunidades públicas, comunidades del usuario,
  /// perfiles públicos y perfiles que el usuario sigue.
  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleriaInicio({String? query}) async {
    try {
      String url = '${_urlBase}inicio_galeria/';
      if (query != null && query.trim().isNotEmpty) {
        url += '?etiquetas=${Uri.encodeComponent(query.trim())}';
      }
      
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);
        final List<dynamic> lista =
            datos is List ? datos : (datos['results'] ?? []);
        final imagenes = lista.map((i) => ImagenGaleria.fromJson(i)).toList();
        return RespuestaApi(
          exito: true,
          datos: imagenes,
          mensaje: 'Galería de inicio cargada',
        );
      }
      return RespuestaApi(
        exito: false,
        mensaje: 'Error: ${respuesta.statusCode}',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
