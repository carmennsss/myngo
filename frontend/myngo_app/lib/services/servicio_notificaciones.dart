import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notificacion.dart';
import '../models/respuesta_api.dart';
import 'servicio_usuarios.dart';

class ServicioNotificaciones {
  final String _baseUrl = 'http://127.0.0.1:8000/notificaciones/';
  final _servicioUsuarios = ServicioUsuarios();

  Future<RespuestaApi<List<Notificacion>>> listarNotificaciones() async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final respuesta = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        final datos = json.decode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> listaJson = datos;
        final lista = listaJson.map((n) => Notificacion.fromJson(n)).toList();
        return RespuestaApi(exito: true, datos: lista, mensaje: 'Notificaciones cargadas');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar notificaciones: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> responderSolicitud(int notificacionId, String accion) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final respuesta = await http.post(
        Uri.parse('$_baseUrl$notificacionId/responder/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({'accion': accion}),
      );

      if (respuesta.statusCode == 200) {
        final datos = json.decode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: datos['mensaje']);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al responder: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> marcarTodasLeidas() async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final respuesta = await http.post(
        Uri.parse('${_baseUrl}marcar-leidas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Notificaciones marcadas como leídas');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al marcar como leídas: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> marcarLeida(int id) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final respuesta = await http.post(
        Uri.parse('$_baseUrl$id/marcar-leida/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Notificación marcada como leída');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<int> obtenerConteoNoLeidas() async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final respuesta = await http.get(
        Uri.parse('${_baseUrl}no-leidas/count/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (respuesta.statusCode == 200) {
        final datos = json.decode(utf8.decode(respuesta.bodyBytes));
        return datos['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
