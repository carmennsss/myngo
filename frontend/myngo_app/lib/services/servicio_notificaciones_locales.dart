import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';

/// Servicio encargado de la gestión de alertas locales en el dispositivo móvil.
///
/// Se utiliza principalmente para emitir notificaciones visuales y sonoras
/// cuando la aplicación está en segundo plano, facilitando la navegación rápida al chat.
class ServicioNotificacionesLocales {
  /// Plugin central para la gestión de notificaciones.
  static final FlutterLocalNotificationsPlugin _pluginNotificaciones = FlutterLocalNotificationsPlugin();

  /// Estado de inicialización del servicio.
  static bool _estaInicializado = false;

  /// Configura el sistema de notificaciones locales y define el comportamiento al pulsarlas.
  static Future<void> inicializar() async {
    if (_estaInicializado) return;

    const inicializacionAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const inicializacionIos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const configuracionGlobal = InitializationSettings(
      android: inicializacionAndroid,
      iOS: inicializacionIos,
    );

    await _pluginNotificaciones.initialize(
      configuracionGlobal,
      onDidReceiveNotificationResponse: (NotificationResponse respuesta) {
        final datosCarga = respuesta.payload;
        if (datosCarga != null) {
          final salaId = int.tryParse(datosCarga);
          if (salaId != null) {
            // Navegación inmediata a la sala de chat origen del mensaje
            rootNavigatorKey.currentContext?.go('/mensajes/sala/$salaId');
          }
        }
      },
    );

    _estaInicializado = true;
  }

  /// Emite una notificación de nuevo mensaje en el sistema operativo.
  ///
  /// [id] Identificador único para evitar solapamientos.
  /// [titulo] Encabezado de la notificación (nombre del remitente o sala).
  /// [cuerpo] Contenido textual del mensaje recibido.
  /// [payload] Datos opcionales (ID de sala) para la acción de redirección.
  static Future<void> mostrarNotificacionMensaje({
    required int id,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    const detallesAndroid = AndroidNotificationDetails(
      'chat_messages',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de nuevos mensajes recibidos',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: 'com.myngo.chat_group',
    );

    const detallesIos = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'chat_messages',
    );

    const detallesPlataforma = NotificationDetails(
      android: detallesAndroid,
      iOS: detallesIos,
    );

    await _pluginNotificaciones.show(
      id,
      titulo,
      cuerpo,
      detallesPlataforma,
      payload: payload,
    );
  }
}
