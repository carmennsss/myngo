import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/configuracion.dart';

/// Servicio para gestionar la mensajería y presencia mediante WebSockets.
class ServicioChat {
  WebSocketChannel? _chatChannel;
  WebSocketChannel? _presenceChannel;
  
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  bool _isConnectedChat = false;
  bool _isConnectedPresence = false;

  static const _baseUrl = Configuracion.wsUrl;
  static const _apiUrl = Configuracion.baseUrl;

  /// Crea una sala de chat privada con otro usuario o la busca si ya existe.
  static Future<Map<String, dynamic>?> crearSalaPrivada(int otroUsuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/mensajeria/salas/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': 'Chat privado',
          'es_grupal': false,
          'otro_usuario_id': otroUsuarioId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Conecta a una sala de chat específica.
  Future<void> conectarASala(int roomId, Function(Map<String, dynamic>) onMessage) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final wsUrl = Uri.parse("$_baseUrl/chat/$roomId/?token=$token");
    
    try {
      _chatChannel = WebSocketChannel.connect(wsUrl);
      _isConnectedChat = true;

      _chatChannel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          onMessage(decoded);
        },
        onDone: () {
          _isConnectedChat = false;
          _intentarReconexionChat(roomId, onMessage);
        },
        onError: (error) {
          _isConnectedChat = false;
          _intentarReconexionChat(roomId, onMessage);
        },
      );
    } catch (e) {
      _isConnectedChat = false;
      _intentarReconexionChat(roomId, onMessage);
    }
  }

  /// Conecta al sistema de presencia global.
  Future<void> conectarPresencia(Function(Map<String, dynamic>) onStatusChange) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final wsUrl = Uri.parse("$_baseUrl/presence/?token=$token");

    try {
      _presenceChannel = WebSocketChannel.connect(wsUrl);
      _isConnectedPresence = true;

      _presenceChannel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          onStatusChange(decoded);
        },
        onDone: () => _isConnectedPresence = false,
        onError: (error) => _isConnectedPresence = false,
      );

      // Iniciar Heartbeat cada 30 segundos
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isConnectedPresence) {
          enviarHeartbeat();
        }
      });
    } catch (e) {
      _isConnectedPresence = false;
    }
  }

  void _intentarReconexionChat(int roomId, Function(Map<String, dynamic>) onMessage) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnectedChat) {
        conectarASala(roomId, onMessage);
      }
    });
  }

  void enviarMensaje(String contenido) {
    if (_isConnectedChat && _chatChannel != null) {
      _chatChannel!.sink.add(jsonEncode({
        'type': 'message',
        'content': contenido,
      }));
    }
  }

  void agregarMiembro(int userId) {
    if (_isConnectedChat && _chatChannel != null) {
      _chatChannel!.sink.add(jsonEncode({
        'type': 'add_member',
        'user_id': userId,
      }));
    }
  }

  void enviarHeartbeat() {
    if (_isConnectedPresence && _presenceChannel != null) {
      _presenceChannel!.sink.add(jsonEncode({
        'type': 'heartbeat',
      }));
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _chatChannel?.sink.close();
    _presenceChannel?.sink.close();
  }
}
