import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Devuelve el color en formato Hexadecimal con el prefijo #
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Crea un objeto Color a partir de una cadena Hexadecimal de forma segura
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    String hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) {
      buffer.write('FF');
      buffer.write(hex);
    } else if (hex.length == 8) {
      buffer.write(hex);
    } else {
      return Colors.transparent;
    }
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }
}
