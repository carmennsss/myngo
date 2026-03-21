import 'package:flutter/material.dart';
import '../../../models/comunidad.dart';

/// Tarjeta compacta y divertida para mostrar una comunidad.
class TarjetaComunidad extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback alPresionar;

  const TarjetaComunidad({
    super.key,
    required this.comunidad,
    required this.alPresionar,
  });

  static const List<List<Color>> _paletas = [
    [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
    [Color(0xFFFBC2EB), Color(0xFFA6C1EE)],
    [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
    [Color(0xFFFFD1FF), Color(0xFFFAD0C4)],
    [Color(0xFFFDEB71), Color(0xFFF8D800)],
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = _paletas[comunidad.id % _paletas.length];
    final tieneImagen = comunidad.urlPortada.isNotEmpty;

    return GestureDetector(
      onTap: alPresionar,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Portada ──────────────────────────────────
                  Expanded(
                    flex: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen o gradiente de fondo
                        tieneImagen
                            ? Image.network(
                                comunidad.urlPortada,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _GradientePlaceholder(paleta: paleta),
                              )
                            : _GradientePlaceholder(paleta: paleta),

                        // Degradado oscuro en la parte inferior para el texto
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Badge privacidad arriba-derecha
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              comunidad.esPublica
                                  ? Icons.public_rounded
                                  : Icons.lock_rounded,
                              size: 12,
                              color: comunidad.esPublica
                                  ? const Color(0xFF6C63FF)
                                  : Colors.orange,
                            ),
                          ),
                        ),

                        // Rating abajo-izquierda
                        if (comunidad.ratingMedio > 0)
                          Positioned(
                            bottom: 6,
                            left: 8,
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${comunidad.ratingMedio}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(blurRadius: 2)],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Nombre y creador ──────────────────────────
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            comunidad.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF2D3142),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🐾 ${comunidad.creadorNombre}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9094A6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (comunidad.esMiembro || (comunidad.creadorId != null && comunidad.creadorId == comunidad.id)) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9B8BFC), Color(0xFF6C63FF)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientePlaceholder extends StatelessWidget {
  final List<Color> paleta;
  const _GradientePlaceholder({required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: paleta,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          size: 36,
          color: Colors.white.withOpacity(0.55),
        ),
      ),
    );
  }
}
