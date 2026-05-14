import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';

/// Servicio encargado de la gestión de alertas locales en el dispositivo móvil.
///
/// Se utiliza principalmente para emitir notificaciones visuales y sonoras
/// cuando la aplicación está en segundo plano, facilitando la navegación rápida al chat.
class ServicioNotificacionesLocales {
  // El motor que lanza las notificaciones en el teléfono
  static final FlutterLocalNotificationsPlugin _pluginNotificaciones = FlutterLocalNotificationsPlugin();

  // Saber si ya lo hemos arrancado o no
  static bool _estaInicializado = false;

  // Prepara los canales de Android e iOS para que el móvil nos deje sonar y vibrar
  static Future<void> inicializar() async {
    if (_estaInicializado) return;

    const inicializacionAndroid = AndroidInitializationSettings('myngo_icon');

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

  // Hace sonar el móvil y muestra un aviso arriba cuando llega un mensaje nuevo.
  // El 'payload' guarda la sala para que al tocar la notificación te meta directo al chat.
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
