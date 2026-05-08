import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comentario.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de gestionar las interacciones sociales en publicaciones.
///
/// Administra los "me gusta", el sistema de comentarios y la funcionalidad
/// de guardar publicaciones para acceso rápido posterior.
class ServicioInteraccion {
  /// URL base para las peticiones de interacción.
  static const String _urlBase = '${Configuracion.baseUrl}/contenido';

  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Alterna el estado de "me gusta" en una publicación específica.
  Future<RespuestaApi<Map<String, dynamic>>> alternarMeGusta(int publicacionId) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/publicaciones/$publicacionId/like/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Interacción registrada',
          datos: jsonDecode(respuesta.body),
        );
      }

      String mensajeError = 'No se pudo procesar el me gusta';
      try {
        final Map<String, dynamic> cuerpo = jsonDecode(respuesta.body);
        mensajeError = cuerpo['error'] ?? cuerpo['detail'] ?? mensajeError;
      } catch (_) {}

      return RespuestaApi(exito: false, mensaje: mensajeError);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera los comentarios de una publicación con soporte para paginación.
  Future<RespuestaApi<List<Comentario>>> obtenerComentarios(
    int publicacionId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final url = '$_urlBase/publicaciones/$publicacionId/comentarios/?limit=$limit&offset=$offset';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List listaJson = (datosJson is Map)
            ? (datosJson['results'] ?? [])
            : (datosJson is List ? datosJson : []);
            
        final comentarios = listaJson.map((j) => Comentario.fromJson(j)).toList();
        return RespuestaApi(
          exito: true,
          mensaje: 'Comentarios recuperados',
          datos: comentarios,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar comentarios');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Publica un nuevo comentario en la plataforma.
  Future<RespuestaApi<Comentario>> crearComentario(int publicacionId, String texto, {int? padreId}) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/publicaciones/$publicacionId/comentarios/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'contenido': texto,
          if (padreId != null) 'padre': padreId,
        }),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Comentario publicado',
          datos: Comentario.fromJson(jsonDecode(respuesta.body)),
        );
      }

      String mensajeError = 'Error al enviar comentario';
      try {
        final Map<String, dynamic> cuerpo = jsonDecode(respuesta.body);
        mensajeError = cuerpo['error'] ?? cuerpo['detail'] ?? mensajeError;
      } catch (_) {}

      return RespuestaApi(exito: false, mensaje: mensajeError);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Alterna si una publicación está guardada en el perfil del usuario.
  Future<RespuestaApi<Map<String, dynamic>>> alternarGuardado(int publicacionId) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/publicaciones/$publicacionId/guardar/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Estado de guardado actualizado',
          datos: jsonDecode(respuesta.body),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar el guardado');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
