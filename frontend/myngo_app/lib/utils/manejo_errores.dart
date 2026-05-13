/// Utilidad centralizada para manejar errores de forma amigable.
///
/// - [getFriendlyError] convierte cualquier excepción técnica en un string
///   comprensible para el usuario (sin jerga de red ni stack traces).
/// - [mostrarError] decide si mostrar un SnackBar (errores leves) o un
///   AlertDialog (errores bloqueantes) y registra el error completo en log.
library manejo_errores;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

/// Traduce una excepción técnica en un mensaje legible para el usuario.
///
/// Los errores técnicos completos se siguen escribiendo a [debugPrint];
/// esta función sólo devuelve el texto que puede mostrarse en la UI.
String getFriendlyError(Object error) {
  if (error is dio.DioException) {
    switch (error.type) {
      case dio.DioExceptionType.connectionTimeout:
      case dio.DioExceptionType.sendTimeout:
      case dio.DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Comprueba tu internet.';
      case dio.DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor. Revisa tu conexión.';
      case dio.DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesión expirada. Por favor, entra de nuevo.';
        if (code == 403) return 'No tienes permiso para hacer esto.';
        if (code == 404) return 'No se encontró el recurso solicitado.';
        if (code != null && code >= 500) return 'Error en el servidor. Inténtalo más tarde.';
        return 'Respuesta inesperada del servidor ($code).';
      default:
        return 'Error de red. Inténtalo de nuevo.';
    }
  }

  if (error is SocketException) {
    return 'Sin conexión. Comprueba tu internet e inténtalo de nuevo.';
  }
  if (error is TimeoutException) {
    return 'La conexión tardó demasiado. Inténtalo de nuevo.';
  }
  if (error is FormatException) {
    return 'Algo salió mal. Por favor inténtalo de nuevo.';
  }

  final msg = error.toString().toLowerCase();

  if (msg.contains('401') || msg.contains('unauthorized')) {
    return 'Tu sesión ha expirado. Por favor inicia sesión de nuevo.';
  }
  if (msg.contains('403') || msg.contains('forbidden')) {
    return 'No tienes permiso para realizar esta acción.';
  }
  if (msg.contains('404') || msg.contains('not found')) {
    return 'No encontramos lo que buscabas.';
  }
  if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
    return 'Error en el servidor. Inténtalo más tarde.';
  }
  if (msg.contains('connection refused') || msg.contains('network')) {
    return 'Sin conexión. Comprueba tu internet e inténtalo de nuevo.';
  }

  return 'Algo salió mal. Por favor inténtalo de nuevo.';
}

/// Muestra el error al usuario y registra el detalle técnico en el log.
///
/// - [bloqueante] = false (por defecto) → SnackBar en la parte inferior.
/// - [bloqueante] = true → AlertDialog modal con botón de cerrar y,
///   opcionalmente, un botón de [onReintentar].
void mostrarError(
  BuildContext context,
  Object error, {
  bool bloqueante = false,
  VoidCallback? onReintentar,
  String? mensajePersonalizado,
}) {
  // Siempre loguear el error técnico completo (nunca llegará al usuario)
  debugPrint('[ERROR] ${error.toString()}');

  final mensaje = mensajePersonalizado ?? getFriendlyError(error);

  if (!context.mounted) return;

  if (bloqueante) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Ha ocurrido un error'),
        content: Text(mensaje),
        actions: [
          if (onReintentar != null)
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                onReintentar();
              },
              child: const Text('Reintentar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Muestra un mensaje informativo o de éxito al usuario.
///
/// Se usa para feedback positivo (ej. "Imagen subida") o avisos neutros.
void mostrarAviso(
  BuildContext context,
  String mensaje, {
  bool esExito = false,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: esExito ? Colors.green : const Color(0xFF4A4440),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}
