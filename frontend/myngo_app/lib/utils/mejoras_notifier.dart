/// Notificador global ligero para avisar a las pantallas de perfil
/// cuando el usuario equipa una mejora desde la tienda.
/// Patrón event-bus minimalista sin dependencias externas.
library mejoras_notifier;

import 'package:flutter/foundation.dart';

/// Incrementar este notificador para forzar recarga del perfil.
final mejoraEquipadaNotifier = ValueNotifier<int>(0);

void notificarMejoraEquipada() {
  mejoraEquipadaNotifier.value++;
}
