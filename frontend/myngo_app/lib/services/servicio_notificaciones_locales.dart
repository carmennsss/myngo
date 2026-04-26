import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../router.dart';
import 'package:go_router/go_router.dart';

class ServicioNotificacionesLocales {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializa el plugin de notificaciones.
  static Future<void> inicializar() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          final salaId = int.tryParse(payload);
          if (salaId != null) {
            // Navegar a la sala de chat
            rootNavigatorKey.currentContext?.go('/mensajes/sala/$salaId');
          }
        }
      },
    );

    _initialized = true;
  }

  /// Muestra una notificación de mensaje.
  static Future<void> mostrarNotificacionMensaje({
    required int id,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de nuevos mensajes en el chat',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: 'com.myngo.chat_group',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'chat_messages',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      titulo,
      cuerpo,
      platformDetails,
      payload: payload,
    );
  }
}
