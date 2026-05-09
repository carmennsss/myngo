import 'package:flutter/material.dart';
import '../services/servicio_mensajeria.dart';
import '../services/servicio_notificaciones_locales.dart';

class ChatProvider extends ChangeNotifier {
  final ServicioMensajeria _servicioChat = ServicioMensajeria();
  
  int? _userId;
  int _totalNoLeidos = 0;
  Map<int, int> _noLeidosPorSala = {};
  int? _salaActivaId;
  Map<int, String> _estadosUsuarios = {};
  List<Map<String, dynamic>> _salas = [];

  int? get userId => _userId;
  int get totalNoLeidos => _totalNoLeidos;
  int? get salaActivaId => _salaActivaId;
  List<Map<String, dynamic>> get salas => _salas;

  void setUserId(int? id) {
    _userId = id;
    notifyListeners();
  }

  /// Limpia todo el estado del provider (usado al cerrar sesión).
  void limpiar() {
    _userId = null;
    _totalNoLeidos = 0;
    _noLeidosPorSala = {};
    _salaActivaId = null;
    _estadosUsuarios = {};
    _salas = [];
    notifyListeners();
  }

  String getEstadoUsuario(int userId) => _estadosUsuarios[userId] ?? 'DESCONECTADO';
  bool isUsuarioOnline(int userId) => getEstadoUsuario(userId) != 'DESCONECTADO';

  void setUsuariosOnline(List<int> ids) {
    for (final id in ids) {
      _estadosUsuarios[id] = 'ACTIVO';
    }
    notifyListeners();
  }

  void actualizarEstadoUsuario(int userId, String status) {
    _estadosUsuarios[userId] = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _servicioChat.dispose();
    super.dispose();
  }

  int noLeidosEnSala(int salaId) => _noLeidosPorSala[salaId] ?? 0;

  /// Establece la sala que el usuario está viendo actualmente.
  void setSalaActiva(int? salaId) {
    _salaActivaId = salaId;
    if (salaId != null) {
      _limpiarNoLeidosSala(salaId);
      // Notificamos al servidor que hemos leído los mensajes
      _servicioChat.marcarMensajesComoLeidos(salaId);
    }
    notifyListeners();
  }

  /// Carga inicial de conteos desde la API REST.
  Future<void> cargarConteosIniciales() async {
    final data = await ServicioMensajeria().obtenerConteoMensajesNoLeidos();
    _totalNoLeidos = (data['total'] as num?)?.toInt() ?? 0;
    
    final porSala = data['por_sala'] as List<dynamic>? ?? [];
    _noLeidosPorSala = {
      for (var item in porSala)
        (item['sala_id'] as num).toInt(): (item['count'] as num).toInt()
    };
    
    notifyListeners();
  }

  /// Carga la lista completa de salas de chat.
  Future<void> cargarSalas() async {
    try {
      final salas = await _servicioChat.obtenerSalasChat();
      _salas = salas;
      notifyListeners();
    } catch (e) {
      debugPrint('Error en ChatProvider.cargarSalas: $e');
    }
  }

  /// Procesa una notificación de nuevo mensaje recibida por WebSocket.
  void procesarNuevaNotificacion(Map<String, dynamic> data) {
    final salaId = (data['sala_id'] as num).toInt();
    
    // Si el usuario está en la sala, no incrementamos el contador ni mostramos push
    if (_salaActivaId == salaId) return;

    _noLeidosPorSala[salaId] = (_noLeidosPorSala[salaId] ?? 0) + 1;
    _totalNoLeidos++;
    
    // Mostrar notificación local
    ServicioNotificacionesLocales.mostrarNotificacionMensaje(
      id: salaId, // Usamos el salaId como ID de notificación para agrupar/actualizar
      titulo: data['sender_username'] ?? 'Nuevo mensaje',
      cuerpo: data['preview'] ?? '',
      payload: salaId.toString(),
    );

    notifyListeners();
  }

  /// Marca una sala como leída localmente.
  void _limpiarNoLeidosSala(int salaId) {
    if (_noLeidosPorSala.containsKey(salaId)) {
      _totalNoLeidos -= _noLeidosPorSala[salaId]!;
      _noLeidosPorSala[salaId] = 0;
      if (_totalNoLeidos < 0) _totalNoLeidos = 0;
    }
  }

  int _refrescoSalasTrigger = 0;
  int get refrescoSalasTrigger => _refrescoSalasTrigger;

  /// Incrementa el trigger para que las pantallas que listan chats se actualicen.
  void notificarNuevaSala() {
    _refrescoSalasTrigger++;
    notifyListeners();
  }

  /// Elimina una sala de la lista local y limpia sus datos.
  void eliminarSalaDeLista(int salaId) {
    _salas.removeWhere((s) => s['id'] == salaId);
    final noLeidos = _noLeidosPorSala.remove(salaId) ?? 0;
    _totalNoLeidos -= noLeidos;
    if (_totalNoLeidos < 0) _totalNoLeidos = 0;
    notifyListeners();
  }

  /// Incrementa el total (usado si llega una notificación genérica).
  void incrementarTotal() {
    _totalNoLeidos++;
    notifyListeners();
  }
}
