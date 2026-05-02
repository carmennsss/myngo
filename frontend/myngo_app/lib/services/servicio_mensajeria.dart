import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de mensajería instantánea y presencia en tiempo real.
///
/// Implementa comunicación bidireccional mediante WebSockets para el chat,
/// estados de conexión (presencia) y notificaciones internas. Además, provee
/// métodos REST para la gestión persistente de salas y mensajes.
class ServicioMensajeria {
  WebSocketChannel? _canalChat;
  WebSocketChannel? _canalPresencia;
  WebSocketChannel? _canalNotificaciones;

  Timer? _temporizadorReconexion;
  Timer? _temporizadorLatido;

  bool _estaConectadoChat = false;
  bool _estaConectadoPresencia = false;
  bool _estaConectadoNotificaciones = false;

  final _servicioUsuarios = ServicioUsuarios();
  static const String _urlApi = Configuracion.baseUrl;
  static const String _urlWs = Configuracion.wsUrl;

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // --- MÉTODOS REST ---

  /// Crea una nueva sala de chat privada con otro usuario.
  Future<Map<String, dynamic>?> crearSalaPrivada(int idOtroUsuario) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlApi/mensajeria/salas/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'otro_usuario_id': idOtroUsuario}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  /// Recupera todas las salas de chat en las que participa el usuario.
  Future<List<Map<String, dynamic>>> obtenerSalasChat() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlApi/mensajeria/salas/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(respuesta.bodyBytes)));
      }
    } catch (_) {}
    return [];
  }

  /// Obtiene el conteo de mensajes no leídos global y por sala.
  Future<Map<String, dynamic>> obtenerConteoMensajesNoLeidos() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlApi/mensajeria/no-leidos/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'total': 0, 'por_sala': []};
  }

  /// Marca todos los mensajes de una sala específica como leídos.
  Future<void> marcarMensajesComoLeidos(int idSala) async {
    try {
      await http.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/marcar-leidos/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // --- WEBSOCKETS ---

  /// Conecta el WebSocket a una sala de chat específica.
  void conectarASala(int idSala, Function(Map<String, dynamic>) alRecibirMensaje, {VoidCallback? alConectar}) {
    _iniciarConexionChat(idSala, alRecibirMensaje, alConectar: alConectar);
  }

  Future<void> _iniciarConexionChat(int idSala, Function(Map<String, dynamic>) alRecibirMensaje, {VoidCallback? alConectar}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;

      final url = Uri.parse("$_urlWs/chat/$idSala/?token=$token");
      _canalChat = WebSocketChannel.connect(url);
      _estaConectadoChat = true;
      if (alConectar != null) alConectar();

      _canalChat!.stream.listen(
        (datos) => alRecibirMensaje(jsonDecode(datos)),
        onDone: () {
          _estaConectadoChat = false;
          _reconectarChat(idSala, alRecibirMensaje);
        },
        onError: (err) {
          _estaConectadoChat = false;
          _reconectarChat(idSala, alRecibirMensaje);
        },
      );
    } catch (e) {
      _estaConectadoChat = false;
      _reconectarChat(idSala, alRecibirMensaje);
    }
  }

  /// Conecta al sistema de presencia para sincronizar estados de conexión.
  Future<void> conectarPresencia(Function(Map<String, dynamic>) alCambiarEstado) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;

      final urlLimpia = _urlWs.endsWith('/') ? _urlWs.substring(0, _urlWs.length - 1) : _urlWs;
      final url = Uri.parse("$urlLimpia/presence/?token=$token");

      _canalPresencia = WebSocketChannel.connect(url);
      _estaConectadoPresencia = true;

      _canalPresencia!.stream.listen(
        (datos) => alCambiarEstado(jsonDecode(datos)),
        onDone: () {
          _estaConectadoPresencia = false;
          _reconectarPresencia(alCambiarEstado);
        },
        onError: (err) {
          _estaConectadoPresencia = false;
          _reconectarPresencia(alCambiarEstado);
        },
      );

      _temporizadorLatido?.cancel();
      _temporizadorLatido = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_estaConectadoPresencia) enviarLatido();
      });
    } catch (e) {
      _estaConectadoPresencia = false;
      _reconectarPresencia(alCambiarEstado);
    }
  }

  /// Conecta al canal de notificaciones globales del chat.
  Future<void> conectarNotificacionesPersonales(Function(Map<String, dynamic>) alRecibirNotificacion) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;

      // Cerrar conexión previa si existe
      _canalNotificaciones?.sink.close();

      final url = Uri.parse("$_urlWs/chat-notificaciones/?token=$token");
      _canalNotificaciones = WebSocketChannel.connect(url);
      _estaConectadoNotificaciones = true;

      _canalNotificaciones!.stream.listen(
        (datos) => alRecibirNotificacion(jsonDecode(datos)),
        onDone: () {
          _estaConectadoNotificaciones = false;
          _reconectarNotificaciones(alRecibirNotificacion);
        },
        onError: (err) {
          _estaConectadoNotificaciones = false;
          _reconectarNotificaciones(alRecibirNotificacion);
        },
      );
    } catch (e) {
      _estaConectadoNotificaciones = false;
      _reconectarNotificaciones(alRecibirNotificacion);
    }
  }

  // --- RECONEXIÓN ---

  void _reconectarChat(int idSala, Function(Map<String, dynamic>) callback) {
    _temporizadorReconexion?.cancel();
    _temporizadorReconexion = Timer(const Duration(seconds: 3), () {
      if (!_estaConectadoChat) conectarASala(idSala, callback);
    });
  }

  void _reconectarPresencia(Function(Map<String, dynamic>) callback) {
    _temporizadorReconexion?.cancel();
    _temporizadorReconexion = Timer(const Duration(seconds: 5), () {
      if (!_estaConectadoPresencia) conectarPresencia(callback);
    });
  }

  void _reconectarNotificaciones(Function(Map<String, dynamic>) callback) {
    Timer(const Duration(seconds: 5), () {
      if (!_estaConectadoNotificaciones) conectarNotificacionesPersonales(callback);
    });
  }

  // --- COMUNICACIÓN ---

  /// Envía un mensaje de texto por el WebSocket de la sala actual.
  void enviarMensajeChat(String contenido, {String? idCliente}) {
    if (_estaConectadoChat && _canalChat != null) {
      _canalChat!.sink.add(jsonEncode({
        'type': 'message',
        'content': contenido,
        'client_id': idCliente,
      }));
    }
  }

  /// Sincroniza el estado de lectura mediante WebSocket.
  void marcarMensajesLeidosWS() {
    if (_estaConectadoChat && _canalChat != null) {
      _canalChat!.sink.add(jsonEncode({'type': 'read_messages'}));
    }
  }

  /// Envía una petición para añadir a un usuario a la sala grupal.
  void agregarMiembroSala(int idUsuario) {
    if (_estaConectadoChat && _canalChat != null) {
      _canalChat!.sink.add(jsonEncode({
        'type': 'add_member',
        'user_id': idUsuario,
      }));
    }
  }

  /// Notifica si el usuario está escribiendo o ha dejado de hacerlo.
  void enviarEventoTyping(int idSala, bool estaEscribiendo) {
    if (_estaConectadoChat && _canalChat != null) {
      _canalChat!.sink.add(jsonEncode({
        'type': 'typing',
        'is_typing': estaEscribiendo,
      }));
    }
  }

  /// Envía un paquete de mantenimiento para evitar el cierre por inactividad.
  void enviarLatido() {
    if (_estaConectadoPresencia && _canalPresencia != null) {
      _canalPresencia!.sink.add(jsonEncode({'type': 'heartbeat'}));
    }
  }

  /// Actualiza el estado de disponibilidad del usuario (Online, Offline, etc.).
  void cambiarEstadoDisponibilidad(String nuevoEstado) {
    if (_estaConectadoPresencia && _canalPresencia != null) {
      _canalPresencia!.sink.add(jsonEncode({
        'type': 'change_status',
        'status': nuevoEstado,
      }));
    }
  }

  // --- CICLO DE VIDA ---

  /// Cierra todas las conexiones y libera los recursos del servicio.
  void dispose() {
    _temporizadorReconexion?.cancel();
    _temporizadorLatido?.cancel();
    _canalChat?.sink.close();
    _canalPresencia?.sink.close();
    _canalNotificaciones?.sink.close();
  }

  /// Cierra exclusivamente la conexión de notificaciones.
  void cerrarNotificaciones() {
    _canalNotificaciones?.sink.close();
    _estaConectadoNotificaciones = false;
  }
}
