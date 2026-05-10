import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publicacion.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

// Nos trae el contenido para llenar la pantalla principal.
// Diferencia la vista de galería (fotos) de la vista social (muro estilo Twitter).
class ServicioInicio {
  // URL de los endpoints de contenido
  static const String _urlBase = '${Configuracion.baseUrl}/contenido';
  
  final _servicioUsuarios = ServicioUsuarios();

  // Prepara el token de sesión para que el servidor sepa quién está haciendo la petición
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Pide las imágenes más destacadas o recientes para la galería inicial
  Future<RespuestaApi<List<Publicacion>>> obtenerPostsInicio({
    int limit = 20,
    int offset = 0,
    String? etiquetas,
  }) async {
    try {
      final queryParams = [
        'limit=$limit',
        'offset=$offset',
        if (etiquetas != null && etiquetas.isNotEmpty) 'etiquetas=${Uri.encodeComponent(etiquetas)}',
      ].join('&');

      final url = '$_urlBase/inicio_galeria/?$queryParams';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final cuerpoDecodificado = utf8.decode(respuesta.bodyBytes);
        final dynamic cuerpo = jsonDecode(cuerpoDecodificado);
        final List<dynamic> resultados = cuerpo is Map ? (cuerpo['results'] ?? []) : [];

        return RespuestaApi(
          exito: true,
          mensaje: 'Galería de inicio recuperada',
          datos: resultados.map((j) => Publicacion.fromJson(j as Map<String, dynamic>)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar la galería (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // Pide las publicaciones de texto, debates o anuncios para el muro social
  Future<RespuestaApi<List<Publicacion>>> obtenerFeedSocial({
    int limit = 20,
    int offset = 0,
    String? etiquetas,
  }) async {
    try {
      final queryParams = [
        'limit=$limit',
        'offset=$offset',
        if (etiquetas != null && etiquetas.isNotEmpty) 'etiquetas=${Uri.encodeComponent(etiquetas)}',
      ].join('&');

      final url = '$_urlBase/inicio_feed/?$queryParams';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final cuerpoDecodificado = utf8.decode(respuesta.bodyBytes);
        final dynamic cuerpo = jsonDecode(cuerpoDecodificado);
        final List<dynamic> resultados = cuerpo is Map ? (cuerpo['results'] ?? []) : [];

        return RespuestaApi(
          exito: true,
          mensaje: 'Feed social recuperado',
          datos: resultados.map((j) => Publicacion.fromJson(j as Map<String, dynamic>)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar feed social (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
