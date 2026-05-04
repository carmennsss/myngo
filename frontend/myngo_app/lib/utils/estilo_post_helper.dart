import 'package:flutter/material.dart';

/// Helper centralizado para parsear y renderizar estilos de post.
/// Soporta color sólido (campo 'fondo') y degradados (campos 'fondo_inicio'/'fondo_fin').
class EstiloPostHelper {
  /// Parsea un hex string (con o sin prefijo alpha) a Color. Devuelve null si falla.
  static Color? parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      if (h.length != 8) return null;
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return null;
    }
  }

  /// Devuelve un BoxDecoration completo con color/degradado y borde según el mapa de estilo.
  static BoxDecoration buildDecoracion(
    Map<String, dynamic>? estilo, {
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    List<BoxShadow>? shadows,
    double borderWidth = 2.5,
  }) {
    Color bgColor = Colors.white;
    Color? bgColorFin;
    Color? borderColor;

    if (estilo != null) {
      // Soporte para color sólido y degradado
      final inicioHex = estilo['fondo_inicio']?.toString() ?? estilo['fondo']?.toString();
      final finHex = estilo['fondo_fin']?.toString();
      final bordeHex = estilo['borde']?.toString();

      bgColor = parseHex(inicioHex) ?? Colors.white;
      bgColorFin = parseHex(finHex);
      borderColor = parseHex(bordeHex);
      
      // Si el color parseado es negro puro pero no hay otros datos, 
      // probablemente sea un error de casteo o dato vacío.
      if (bgColor == Colors.black && bgColorFin == null && estilo.length <= 1) {
        bgColor = Colors.white;
      }
    }

    final tieneGradiente = bgColorFin != null;

    return BoxDecoration(
      color: tieneGradiente ? null : bgColor,
      gradient: tieneGradiente
          ? LinearGradient(
              colors: [bgColor, bgColorFin!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: borderRadius,
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: shadows,
    );
  }

  /// Devuelve el color efectivo del fondo (promedio para degradados) para cálculos de luminancia.
  static Color effectiveBgColor(Map<String, dynamic>? estilo) {
    if (estilo == null) return Colors.white;
    final inicioHex = estilo['fondo_inicio']?.toString() ?? estilo['fondo']?.toString();
    final finHex = estilo['fondo_fin']?.toString();

    final inicio = parseHex(inicioHex) ?? Colors.white;
    final fin = parseHex(finHex);
    if (fin != null) {
      return Color.lerp(inicio, fin, 0.5)!;
    }
    return inicio;
  }

  /// true = fondo claro → usar texto oscuro. false = fondo oscuro → usar texto blanco.
  static bool esFondoClaro(Map<String, dynamic>? estilo) {
    return effectiveBgColor(estilo).computeLuminance() > 0.5;
  }
}
