import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';

class PreviewHeader extends StatelessWidget {
  final Comunidad comunidad;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;

  const PreviewHeader({
    super.key,
    required this.comunidad,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
  });

  TextStyle _getSafeFont(String? font, {double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing}) {
    final f = font ?? 'Outfit';
    try {
      return GoogleFonts.getFont(f, fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
    } catch (e) {
      return GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                comunidad.nombre,
                style: _getSafeFont(
                  comunidad.fuenteComunidad,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorTextoPrincipal,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            _ChipPrivacidad(
              esPublica: comunidad.esPublica,
              fuente: comunidad.fuenteComunidad,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: comunidad.colorTema.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: comunidad.colorTema.withValues(
                    alpha: esAppClara ? 0.3 : 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 14, color: comunidad.colorTema),
                  const SizedBox(width: 6),
                  Text(
                    'Por ${comunidad.creadorNombre}',
                    style: _getSafeFont(
                      comunidad.fuenteComunidad,
                      color: colorTextoPrincipal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: esAppClara
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt_rounded,
                      color: colorTextoSecundario, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${comunidad.miembrosCount} Miembros',
                    style: _getSafeFont(
                      comunidad.fuenteComunidad,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorTextoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF29C50), size: 22),
                const SizedBox(width: 4),
                Text(
                  comunidad.ratingMedio.toStringAsFixed(1),
                  style: _getSafeFont(
                    comunidad.fuenteComunidad,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: colorTextoPrincipal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipPrivacidad extends StatelessWidget {
  final bool esPublica;
  final String? fuente;

  const _ChipPrivacidad({required this.esPublica, this.fuente});

  TextStyle _getSafeFont(String? font, {double? fontSize, FontWeight? fontWeight, Color? color}) {
    final f = font ?? 'Inter';
    try {
      return GoogleFonts.getFont(f, fontSize: fontSize, fontWeight: fontWeight, color: color);
    } catch (e) {
      return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: esPublica
            ? const Color(0xFF248EA6).withValues(alpha: 0.15)
            : const Color(0xFFF28B50).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esPublica
              ? const Color(0xFF248EA6).withValues(alpha: 0.4)
              : const Color(0xFFF28B50).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.public_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? const Color(0xFF248EA6) : const Color(0xFFF28B50),
          ),
          const SizedBox(width: 6),
            Text(
              esPublica ? 'Pública' : 'Privada',
              style: _getSafeFont(
                fuente,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
