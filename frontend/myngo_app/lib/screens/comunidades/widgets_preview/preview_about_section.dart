import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';

class PreviewAboutSection extends StatelessWidget {
  final Comunidad comunidad;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;
  final Color bgColor;

  const PreviewAboutSection({
    super.key,
    required this.comunidad,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esAppClara ? Colors.black.withValues(alpha: 0.03) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esAppClara ? Colors.black12 : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: bgColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sobre esta comunidad',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorTextoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comunidad.descripcion.isEmpty
                ? 'Un espacio misterioso! Aún no hay descripción para esta comunidad.'
                : comunidad.descripcion,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: colorTextoSecundario,
              height: 1.6,
            ),
          ),
          if (comunidad.minRatingAcceso > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF29C50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF29C50).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFFF29C50), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requisito de Nivel 🐾',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: colorTextoPrincipal,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Necesitas una media de ${comunidad.minRatingAcceso.toStringAsFixed(1)} ⭐ para unirte a este selecto grupo.',
                          style: GoogleFonts.inter(
                            color: colorTextoSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
