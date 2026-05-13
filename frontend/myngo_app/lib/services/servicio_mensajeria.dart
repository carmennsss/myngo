import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/configuracion.dart';
import '../models/sala_chat.dart';
import 'api_base.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de mensajería instantánea y presencia en tiempo real.
class ServicioMensajeria {
  static final ServicioMensajeria _instancia = ServicioMensajeria._interno();
  factory ServicioMensajeria() => _instancia;
  ServicioMensajeria._interno() {
    _client = http.Client();
  }

  late final http.Client _client;
  ServicioMensajeria.conCliente(http.Client client) {
    _client = client;
  }
  http.Client get client => _client;

  WebSocketChannel? _canalChat;
  WebSocketChannel? _canalPresencia;
  WebSocketChannel? _canalNotificaciones;
  WebSocketChannel? _canalComunidad;
  WebSocketChannel? _canalGlobal;
  WebSocketChannel? _canalPublicacion;

  Timer? _temporizadorReconexion;
  Timer? _temporizadorLatido;

  final _servicioUsuarios = ServicioUsuarios();
  static const String _urlApi = Configuracion.baseUrl;
  static const String _urlWs = Configuracion.wsUrl;

  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return ApiBase.obtenerHeaders(token: token);
  }

  Future<Map<String, dynamic>?> crearSala({
    String? nombre,
    bool esGrupal = false,
    bool esPublica = false,
    int? idOtroUsuario,
    List<int>? miembrosIds,
    int? comunidadId,
  }) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlApi/mensajeria/salas/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre,
          'es_grupal': esGrupal,
          'es_publica': esPublica,
          if (idOtroUsuario != null) 'otro_usuario_id': idOtroUsuario,
          if (miembrosIds != null) 'miembros_ids': miembrosIds,
          if (comunidadId != null) 'comunidad_id': comunidadId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> obtenerSalasChat() async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlApi/mensajeria/salas/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final body = utf8.decode(respuesta.bodyBytes);
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded.containsKey('results')) {
          return List<Map<String, dynamic>>.from(decoded['results']);
        }
        return [];
      }
    } catch (e) {
      debugPrint('Error en obtenerSalasChat: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> obtenerConteoMensajesNoLeidos() async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlApi/mensajeria/no-leidos/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'total': 0, 'por_sala': []};
  }

  Future<void> marcarMensajesComoLeidos(int idSala) async {
    try {
      await client.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/marcar-leidos/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesSala(int idSala, {int limit = 30, int offset = 0}) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/mensajes/?limit=$limit&offset=$offset'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<SalaChat?> obtenerDetalleSala(int idSala) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return SalaChat.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<SalaChat?> obtenerSalaGeneralComunidad(int idComunidad) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlApi/mensajeria/salas/comunidad/$idComunidad/general/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return SalaChat.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> enviarMensaje(int idSala, String texto) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/enviar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'texto': texto}),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  /// Actualiza la configuración y metadatos de una sala.
  Future<bool> actualizarSala(int idSala, {String? nombre, PersonalizacionChat? personalizacion, String? avatarS3}) async {
    try {
      final respuesta = await client.patch(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/actualizar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre,
          if (personalizacion != null) 'personalizacion': personalizacion.toJson(),
          if (avatarS3 != null) 'avatar_s3': avatarS3,
        }),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sube una imagen para usarla como avatar de la sala.
  Future<String?> subirAvatarSala(int idSala, XFile imagen) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('$_urlApi/mensajeria/salas/$idSala/subir-avatar/');
      var solicitud = http.MultipartRequest('POST', uri);

      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      if (kIsWeb) {
        final bytes = await imagen.readAsBytes();
        solicitud.files.add(http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: imagen.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        final mimeType = lookupMimeType(imagen.path) ?? 'image/jpeg';
        final typeParts = mimeType.split('/');
        solicitud.files.add(await http.MultipartFile.fromPath(
          'avatar', 
          imagen.path,
          contentType: MediaType(typeParts[0], typeParts[1]),
        ));
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return datos['url_avatar'];
      }
    } catch (_) {}
    return null;
  }

  /// Sube un archivo multimedia (imagen o vídeo) para el chat.
  Future<Map<String, dynamic>?> uploadMedia(int idSala, XFile archivo) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('$_urlApi/mensajeria/messages/upload/');
      var solicitud = http.MultipartRequest('POST', uri);

      if (token != null) solicitud.headers['Authorization'] = 'Token $token';
      solicitud.fields['room_id'] = idSala.toString();

      if (kIsWeb) {
        final bytes = await archivo.readAsBytes();
        solicitud.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: archivo.name,
          contentType: MediaType(
            archivo.name.toLowerCase().endsWith('.mp4') || 
            archivo.name.toLowerCase().endsWith('.mov') ||
            archivo.name.toLowerCase().endsWith('.webm') ? 'video' : 'image', 
            'octet-stream'
          ),
        ));
      } else {
        final mimeType = lookupMimeType(archivo.path) ?? 
                        (archivo.name.toLowerCase().endsWith('.mp4') ? 'video/mp4' : 'image/jpeg');
        final typeParts = mimeType.split('/');
        solicitud.files.add(await http.MultipartFile.fromPath(
          'file', 
          archivo.path,
          contentType: MediaType(typeParts[0], typeParts[1]),
        ));
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 60));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes));
      }
    } catch (e) {
    }
    return null;
  }

  Future<bool> agregarMiembro(int idSala, int usuarioId) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/agregar_miembro/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'usuario_id': usuarioId}),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Establece un apodo personalizado (privado) para otro usuario en un chat.
  Future<bool> actualizarApodoPersonalizado(int idSala, int usuarioId, String? apodo) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/apodo-personalizado/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'usuario_id': usuarioId,
          'apodo': apodo,
        }),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> borrarMensaje(int mensajeId, {bool paraTodos = false}) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlApi/mensajeria/mensajes/$mensajeId/borrar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'para_todos': paraTodos}),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editarMensaje(int mensajeId, String nuevoContenido) async {
    try {
      final respuesta = await client.patch(
        Uri.parse('$_urlApi/mensajeria/mensajes/$mensajeId/editar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'contenido': nuevoContenido}),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> abandonarSala(int idSala) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/salir/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> expulsarMiembro(int idSala, int usuarioId) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/expulsar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'usuario_id': usuarioId}),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> eliminarSala(int idSala) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlApi/mensajeria/salas/$idSala/eliminar/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 10));
      return respuesta.statusCode == 200 || respuesta.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void conectarASala(int idSala, Function(Map<String, dynamic>) alRecibirMensaje, {VoidCallback? alConectar}) {
    _iniciarConexionChat(idSala, alRecibirMensaje, alConectar: alConectar);
  }

  Future<void> _iniciarConexionChat(int idSala, Function(Map<String, dynamic>) alRecibirMensaje, {VoidCallback? alConectar}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;

      final url = Uri.parse("$_urlWs/chat/$idSala/?token=$token");
      _canalChat?.sink.close();
      _canalChat = WebSocketChannel.connect(url);
      
      _canalChat!.ready.then((_) {
        if (alConectar != null) alConectar();
      }).catchError((e) {
      });

      _canalChat!.stream.listen(
        (datos) => alRecibirMensaje(jsonDecode(datos)),
        onDone: () {
          _reconectarChat(idSala, alRecibirMensaje);
        },
        onError: (err) {
          _reconectarChat(idSala, alRecibirMensaje);
        },
      );
    } catch (e) {
      _reconectarChat(idSala, alRecibirMensaje);
    }
  }

  Future<void> conectarPresencia(Function(Map<String, dynamic>) alCambiarEstado) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;
      final urlLimpia = _urlWs.endsWith('/') ? _urlWs.substring(0, _urlWs.length - 1) : _urlWs;
      final url = Uri.parse("$urlLimpia/presence/?token=$token");
      _canalPresencia = WebSocketChannel.connect(url);

      _canalPresencia!.stream.listen(
        (datos) => alCambiarEstado(jsonDecode(datos)),
        onDone: () {
          _reconectarPresencia(alCambiarEstado);
        },
        onError: (err) {
          _reconectarPresencia(alCambiarEstado);
        },
      );

      _temporizadorLatido?.cancel();
      _temporizadorLatido = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_canalPresencia != null) enviarLatido();
      });
    } catch (e) {
      _reconectarPresencia(alCambiarEstado);
    }
  }

  Future<void> conectarNotificacionesPersonales(Function(Map<String, dynamic>) alRecibirNotificacion) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;
      _canalNotificaciones?.sink.close();
      final url = Uri.parse("$_urlWs/chat-notificaciones/?token=$token");
      _canalNotificaciones = WebSocketChannel.connect(url);
      _canalNotificaciones!.stream.listen(
        (datos) => alRecibirNotificacion(jsonDecode(datos)),
        onDone: () {
          _reconectarNotificaciones(alRecibirNotificacion);
        },
        onError: (err) {
          _reconectarNotificaciones(alRecibirNotificacion);
        },
      );
    } catch (e) {
      _reconectarNotificaciones(alRecibirNotificacion);
    }
  }

  void _reconectarChat(int idSala, Function(Map<String, dynamic>) callback) {
    _temporizadorReconexion?.cancel();
    _temporizadorReconexion = Timer(const Duration(seconds: 3), () {
      if (_canalChat == null) conectarASala(idSala, callback);
    });
  }

  void _reconectarPresencia(Function(Map<String, dynamic>) callback) {
    _temporizadorReconexion?.cancel();
    _temporizadorReconexion = Timer(const Duration(seconds: 5), () {
      if (_canalPresencia == null) conectarPresencia(callback);
    });
  }

  void _reconectarNotificaciones(Function(Map<String, dynamic>) callback) {
    Timer(const Duration(seconds: 5), () {
      if (_canalNotificaciones == null) conectarNotificacionesPersonales(callback);
    });
  }

  Future<void> conectarAComunidad(int idComunidad, Function(Map<String, dynamic>) alRecibirEvento) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;
      final url = Uri.parse("$_urlWs/comunidad/$idComunidad/?token=$token");
      _canalComunidad?.sink.close();
      _canalComunidad = WebSocketChannel.connect(url);
      _canalComunidad!.stream.listen(
        (datos) => alRecibirEvento(jsonDecode(datos)),
        onDone: () {
          _reconectarComunidad(idComunidad, alRecibirEvento);
        },
        onError: (err) {
          _reconectarComunidad(idComunidad, alRecibirEvento);
        },
      );
    } catch (e) {
      _reconectarComunidad(idComunidad, alRecibirEvento);
    }
  }

  Future<void> conectarAGlobal(Function(Map<String, dynamic>) alRecibirEvento) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;
      final url = Uri.parse("$_urlWs/global/?token=$token");
      _canalGlobal?.sink.close();
      _canalGlobal = WebSocketChannel.connect(url);
      _canalGlobal!.stream.listen(
        (datos) => alRecibirEvento(jsonDecode(datos)),
        onDone: () {
          _reconectarGlobal(alRecibirEvento);
        },
        onError: (err) {
          _reconectarGlobal(alRecibirEvento);
        },
      );
    } catch (e) {
      _reconectarGlobal(alRecibirEvento);
    }
  }

  void _reconectarComunidad(int idComunidad, Function(Map<String, dynamic>) callback) {
    Timer(const Duration(seconds: 5), () {
      if (_canalComunidad == null) conectarAComunidad(idComunidad, callback);
    });
  }

  void _reconectarGlobal(Function(Map<String, dynamic>) callback) {
    Timer(const Duration(seconds: 10), () {
      if (_canalGlobal == null) conectarAGlobal(callback);
    });
  }

  Future<bool> enviarMensajeChat(String contenido, {
    String? clientId, 
    int? referenciaA, 
    String? tipo, 
    String? urlArchivoS3,
    List<Map<String, dynamic>>? attachments,
  }) async {
    // Intentar por WebSocket si está disponible
    if (_canalChat != null) {
      try {
        _canalChat!.sink.add(jsonEncode({
          'type': 'message',
          'content': contenido,
          'client_id': clientId,
          'tipo': tipo ?? 'TEXTO',
          'url_archivo_s3': urlArchivoS3,
          if (attachments != null) 'attachments': attachments,
          if (referenciaA != null) 'referencia_a': referenciaA,
        }));
        return true;
      } catch (e) {
        debugPrint('Error enviando mensaje por WS: $e');
      }
    }

    // Fallback a API REST si el WebSocket falla o no está conectado
    try {
      return false; 
    } catch (_) {
      return false;
    }
  }

  void marcarMensajesLeidosWS() {
    if (_canalChat != null) {
      _canalChat!.sink.add(jsonEncode({'type': 'read_messages'}));
    }
  }

  /// Notifica si el usuario actual está escribiendo o no en la sala activa.
  void enviarEventoEscritura(bool escribiendo) {
    if (_canalChat != null) {
      try {
        _canalChat!.sink.add(jsonEncode({
          'type': 'typing',
          'is_typing': escribiendo,
        }));
      } catch (_) {}
    }
  }

  void enviarLatido() {
    if (_canalPresencia != null) {
      _canalPresencia!.sink.add(jsonEncode({'type': 'heartbeat'}));
    }
  }

  void cambiarEstadoDisponibilidad(String nuevoEstado) {
    if (_canalPresencia != null) {
      _canalPresencia!.sink.add(jsonEncode({
        'type': 'change_status',
        'status': nuevoEstado,
      }));
    }
  }

  /// Cierra todas las conexiones y marca al usuario como desconectado (solo para Logout).
  void limpiarParaCerrarSesion() {
    _temporizadorReconexion?.cancel();
    _temporizadorLatido?.cancel();
    
    // Notificamos explícitamente el cierre de sesión antes de romper el socket
    if (_canalPresencia != null) {
      try {
        _canalPresencia!.sink.add(jsonEncode({
          'type': 'change_status',
          'status': 'DESCONECTADO',
        }));
      } catch (_) {}
    }
    
    desconectarTodo();
  }

  /// Cierra físicamente todos los sockets abiertos sin excepción.
  void desconectarTodo() {
    _canalChat?.sink.close();
    _canalPresencia?.sink.close();
    _canalNotificaciones?.sink.close();
    _canalComunidad?.sink.close();
    _canalGlobal?.sink.close();
    _canalPublicacion?.sink.close();
    
    _canalChat = null;
    _canalPresencia = null;
    _canalNotificaciones = null;
    _canalComunidad = null;
    _canalGlobal = null;
    _canalPublicacion = null;
  }

  void dispose() {
    _canalChat?.sink.close();
    _canalComunidad?.sink.close();
    _canalPublicacion?.sink.close();
    _canalChat = null;
    _canalComunidad = null;
    _canalPublicacion = null;
  }

  void desconectarChat() {
    _canalChat?.sink.close();
    _canalChat = null;
  }

  void desconectarGlobal() {
    _canalGlobal?.sink.close();
    _canalGlobal = null;
  }

  void _reconectarPublicacion(int idPublicacion, Function(Map<String, dynamic>) callback) {
    Timer(const Duration(seconds: 5), () {
      if (_canalPublicacion == null) conectarAPublicacion(idPublicacion, callback);
    });
  }

  Future<void> conectarAPublicacion(int idPublicacion, Function(Map<String, dynamic>) alRecibirEvento) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      if (token == null) return;
      final url = Uri.parse("$_urlWs/publicacion/$idPublicacion/?token=$token");
      _canalPublicacion?.sink.close();
      _canalPublicacion = WebSocketChannel.connect(url);
      _canalPublicacion!.stream.listen(
        (datos) => alRecibirEvento(jsonDecode(datos)),
        onDone: () {
          _reconectarPublicacion(idPublicacion, alRecibirEvento);
        },
        onError: (err) {
          _reconectarPublicacion(idPublicacion, alRecibirEvento);
        },
      );
    } catch (e) {
      _reconectarPublicacion(idPublicacion, alRecibirEvento);
    }
  }
}
