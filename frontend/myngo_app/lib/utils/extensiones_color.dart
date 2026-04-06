import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Devuelve el color en formato Hexadecimal con el prefijo #
  String toHex() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
