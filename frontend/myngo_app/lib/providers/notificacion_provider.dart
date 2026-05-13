import 'package:flutter/foundation.dart';

/// Tabs de la pantalla de notificaciones.
enum NotifTab { interacciones, solicitudes, sistema }

/// Provider global para el estado del badge de notificaciones.
///
/// Desglosa el conteo por tab para que al leer un tab específico solo
/// disminuya el número de ese tab, sin afectar a los demás.
class NotificacionProvider extends ChangeNotifier {
  final Map<NotifTab, int> _sinLeerPorTab = {
    NotifTab.interacciones: 0,
    NotifTab.solicitudes: 0,
    NotifTab.sistema: 0,
  };

  /// Total de notificaciones no leídas en todos los tabs.
  int get totalSinLeer =>
      _sinLeerPorTab.values.fold(0, (a, b) => a + b);

  /// Devuelve el conteo sin leer del tab especificado.
  int sinLeerDeTab(NotifTab tab) => _sinLeerPorTab[tab] ?? 0;

  // ─── Mapping tipos de notificación → tab ────────────────────────────

  static const _interacciones = {
    'LIKE', 'COMENTARIO', 'VOTO', 'SEGUIMIENTO', 'PETICION_ACEPTADA', 'PETICION_RECHAZADA',
  };
  static const _solicitudes = {
    'PETICION_UNION', 'PETICION_CO_ADMIN', 'PETICION_SEGUIMIENTO', 'NUEVO_REPORTE',
  };

  /// Clasifica un tipo de notificación en su tab correspondiente.
  static NotifTab tabParaTipo(String tipo) {
    if (_interacciones.contains(tipo)) return NotifTab.interacciones;
    if (_solicitudes.contains(tipo)) return NotifTab.solicitudes;
    return NotifTab.sistema;
  }

  /// Devuelve los tipos de notificación asociados a un tab.
  static List<String> tiposDeTab(NotifTab tab) {
    switch (tab) {
      case NotifTab.interacciones:
        return _interacciones.toList();
      case NotifTab.solicitudes:
        return _solicitudes.toList();
      case NotifTab.sistema:
        return ['ROL_ACTUALIZADO', 'CONTENIDO_BORRADO', 'CONTENIDO_REPORTADO', 'SISTEMA'];
    }
  }

  // ─── Mutaciones ─────────────────────────────────────────────────────

  /// Llamar cuando llega una notificación nueva por WebSocket.
  /// Incrementa el badge del tab correspondiente inmediatamente.
  void alRecibirNotificacion(String tipo) {
    final tab = tabParaTipo(tipo);
    _sinLeerPorTab[tab] = (_sinLeerPorTab[tab] ?? 0) + 1;
    notifyListeners();
  }

  /// Llamar cuando el usuario entra en un tab y se marcan sus notificaciones como leídas.
  /// El badge de ese tab baja a 0; los demás tabs no se ven afectados.
  void alLeerTab(NotifTab tab) {
    if ((_sinLeerPorTab[tab] ?? 0) > 0) {
      _sinLeerPorTab[tab] = 0;
      notifyListeners();
    }
  }

  /// Inicializar el conteo desde el backend al arrancar la app.
  /// El total se asigna al tab "sistema" como fallback hasta que el usuario
  /// abra la pantalla de notificaciones, que redistribuirá por tab.
  void inicializarDesdeConteo(int total) {
    if (total <= 0) return;
    // Distribuimos en sistema para que el badge sea visible de inmediato.
    // Se sincronizará correctamente cuando PantallaNotificaciones cargue.
    _sinLeerPorTab[NotifTab.sistema] = total;
    notifyListeners();
  }

  /// Reinicia todos los conteos a 0 (ej. al cerrar sesión).
  void reset() {
    _sinLeerPorTab.updateAll((_, __) => 0);
    notifyListeners();
  }
}
