import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notificacion.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de notificaciones del usuario.
///
/// Provee métodos para listar avisos, marcarlos como leídos y procesar
/// respuestas a solicitudes interactivas (seguimiento, uniones, etc.).
class ServicioNotificaciones {
  /// URL base para los endpoints de notificaciones.
  static const String _urlNotificaciones = '${Configuracion.baseUrl}/notificaciones/';
  
  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Recupera la lista completa de notificaciones del usuario autenticado.
  Future<RespuestaApi<List<Notificacion>>> listarNotificaciones() async {
    try {
      final respuesta = await http.get(
        Uri.parse(_urlNotificaciones),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = json.decode(utf8.decode(respuesta.bodyBytes));
        final listaNotificaciones = datosJson.map((n) => Notificacion.fromJson(n)).toList();
        return RespuestaApi(
          exito: true,
          datos: listaNotificaciones,
          mensaje: 'Notificaciones cargadas con éxito',
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar notificaciones (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Responde a una solicitud (aceptar/rechazar) vinculada a una notificación.
  Future<RespuestaApi<void>> responderSolicitudInteractiva(int idNotificacion, String accion) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlNotificaciones$idNotificacion/responder/'),
        headers: await _obtenerCabeceras(),
        body: json.encode({'accion': accion}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final datosJson = json.decode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: datosJson['mensaje'] ?? 'Operación realizada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar la respuesta');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Marca todas las notificaciones pendientes como leídas.
  Future<RespuestaApi<void>> marcarTodasComoLeidas() async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlNotificaciones}marcar-leidas/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Todas las notificaciones marcadas como leídas');
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudieron marcar las notificaciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Marca una notificación individual como leída.
  Future<RespuestaApi<void>> marcarComoLeida(int idNotificacion) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlNotificaciones$idNotificacion/marcar-leida/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Notificación actualizada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar la notificación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene el conteo numérico de notificaciones sin leer.
  Future<int> obtenerConteoNoLeidas() async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlNotificaciones}no-leidas/count/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datosJson = json.decode(utf8.decode(respuesta.bodyBytes));
        return datosJson['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
