library manejo_errores;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import '../widgets/toast_service.dart';

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

void mostrarError(
  BuildContext context,
  Object error, {
  bool bloqueante = false,
  VoidCallback? onReintentar,
  String? mensajePersonalizado,
}) {
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
    ToastService.showError(context, mensaje);
  }
}

void mostrarAviso(
  BuildContext context,
  String mensaje, {
  bool esExito = false,
}) {
  if (!context.mounted) return;

  if (esExito) {
    ToastService.showSuccess(context, mensaje);
  } else {
    ToastService.showInfo(context, mensaje);
  }
}
