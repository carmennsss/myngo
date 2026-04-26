import 'package:flutter/material.dart';
import '../services/servicio_chat.dart';
import '../services/servicio_notificaciones_locales.dart';

class ChatProvider extends ChangeNotifier {
  final ServicioChat _servicioChat = ServicioChat();
  
  int _totalNoLeidos = 0;
  Map<int, int> _noLeidosPorSala = {};
  int? _salaActivaId;

  int get totalNoLeidos => _totalNoLeidos;
  int? get salaActivaId => _salaActivaId;

  int noLeidosEnSala(int salaId) => _noLeidosPorSala[salaId] ?? 0;

  /// Establece la sala que el usuario está viendo actualmente.
  void setSalaActiva(int? salaId) {
    _salaActivaId = salaId;
    if (salaId != null) {
      _limpiarNoLeidosSala(salaId);
    }
    notifyListeners();
  }

  /// Carga inicial de conteos desde la API REST.
  Future<void> cargarConteosIniciales() async {
    final data = await ServicioChat.obtenerConteoNoLeidos();
    _totalNoLeidos = (data['total'] as num?)?.toInt() ?? 0;
    
    final porSala = data['por_sala'] as List<dynamic>? ?? [];
    _noLeidosPorSala = {
      for (var item in porSala)
        (item['sala_id'] as num).toInt(): (item['count'] as num).toInt()
    };
    
    notifyListeners();
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

  /// Incrementa el total (usado si llega una notificación genérica).
  void incrementarTotal() {
    _totalNoLeidos++;
    notifyListeners();
  }
}
