import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notificacion.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'api_base.dart';
import 'servicio_usuarios.dart';

// Gestiona la bandeja de entrada de notificaciones de la app.
// Nos sirve para ver quién nos ha seguido, avisos de comunidades y marcar los avisos como leídos.
class ServicioNotificaciones {
  late final http.Client _client;
  ServicioNotificaciones({http.Client? httpClient}) {
    _client = httpClient ?? http.Client();
  }
  http.Client get client => _client;

  // Ruta base del servidor para las notificaciones
  static const String _urlNotificaciones = '${Configuracion.baseUrl}/notificaciones/';
  
  final _servicioUsuarios = ServicioUsuarios();

  // Adjunta el token de sesión a la petición
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return ApiBase.obtenerHeaders(token: token);
  }

  // Pide al servidor todas las notificaciones (leídas y no leídas) del usuario
  Future<RespuestaApi<List<Notificacion>>> listarNotificaciones() async {
    try {
      final respuesta = await client.get(
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

  // Permite aceptar o rechazar solicitudes (ej. de seguimiento) directamente desde la campanita
  Future<RespuestaApi<void>> responderSolicitudInteractiva(int idNotificacion, String accion) async {
    try {
      final respuesta = await client.post(
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

  // Limpia la bandeja marcando todo como leído de golpe
  Future<RespuestaApi<void>> marcarTodasComoLeidas() async {
    try {
      final respuesta = await client.post(
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

  // Marca una sola notificación como leída (cuando pinchas en ella)
  Future<RespuestaApi<void>> marcarComoLeida(int idNotificacion) async {
    try {
      final respuesta = await client.post(
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

  // Nos dice cuántas notificaciones nuevas hay para poner el globito rojo en la campana
  Future<int> obtenerConteoNoLeidas() async {
    try {
      final respuesta = await client.get(
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
