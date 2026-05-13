import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/comentario.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'api_base.dart';
import '../utils/manejo_errores.dart';
import 'servicio_usuarios.dart';

// Maneja las interacciones sociales con los posts.
// Los likes, los comentarios, y la opción de guardar posts favoritos.
class ServicioInteraccion {
  // URL base para las interacciones
  static const String _urlBase = '${Configuracion.baseUrl}/contenido';

  final _servicioUsuarios = ServicioUsuarios();

  // Adjunta el token a la petición
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return ApiBase.obtenerHeaders(token: token);
  }

  // Da o quita el like a un post (hace de interruptor)
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
      debugPrint('[ERROR ServicioInteraccion] $e');
      return RespuestaApi(exito: false, mensaje: getFriendlyError(e));
    }
  }

  // Trae los comentarios de un post para mostrarlos debajo de la foto
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
      debugPrint('[ERROR ServicioInteraccion] $e');
      return RespuestaApi(exito: false, mensaje: getFriendlyError(e));
    }
  }

  // Envía el texto que acabas de escribir como comentario en un post
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
      debugPrint('[ERROR ServicioInteraccion] $e');
      return RespuestaApi(exito: false, mensaje: getFriendlyError(e));
    }
  }

  // Guarda o quita un post de tu carpeta personal de favoritos (interruptor)
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
      debugPrint('[ERROR ServicioInteraccion] $e');
      return RespuestaApi(exito: false, mensaje: getFriendlyError(e));
    }
  }

  // Borra tu comentario de un post
  Future<RespuestaApi<bool>> eliminarComentario(int comentarioId) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlBase/comentarios/$comentarioId/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 204) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Comentario eliminado',
          datos: true,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar comentario');
    } catch (e) {
      debugPrint('[ERROR ServicioInteraccion] $e');
      return RespuestaApi(exito: false, mensaje: getFriendlyError(e));
    }
  }
}
