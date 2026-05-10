import 'package:flutter/material.dart';


class DecoracionesBurbuja extends StatelessWidget {
  final String estilo; // El nombre del tema del chat
  final bool esMio;    // Para saber en qué lado de la burbuja poner la decoración

  const DecoracionesBurbuja({
    super.key,
    required this.estilo,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    switch (estilo) {
      case 'amor':
        return Positioned(
          top: -12,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('💖', style: TextStyle(fontSize: 20)),
        );
      case 'vaquero':
        return Positioned(
          top: -18,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('🤠', style: TextStyle(fontSize: 22)),
        );
      case 'bosque':
        return Positioned(
          top: -15,
          left: esMio ? -10 : null,
          right: !esMio ? -10 : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🍃', style: TextStyle(fontSize: 18)),
              Text('🌸', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      case 'cyber':
        return Positioned(
          top: 5,
          right: esMio ? 5 : null,
          left: !esMio ? 5 : null,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
          ),
        );
      case 'kawaii':
        return Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -15, left: -5, child: const Text('✨', style: TextStyle(fontSize: 18))),
              Positioned(bottom: -10, right: -5, child: const Text('🎀', style: TextStyle(fontSize: 22))),
              Positioned(top: -5, right: 10, child: const Text('⭐', style: TextStyle(fontSize: 12))),
            ],
          ),
        );
      case 'aventura':
        return Positioned(
          top: -18,
          right: 0,
          child: const Text('📜', style: TextStyle(fontSize: 24)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
