import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';

// Tarjeta con diseño Dark y paleta dinámica para comunidades
class TarjetaComunidad extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback alPresionar;

  const TarjetaComunidad({
    super.key,
    required this.comunidad,
    required this.alPresionar,
  });

  static const List<List<Color>> _paletas = [
    [Color(0xFF248EA6), Color(0xFF1A6B7D)],
    [Color(0xFFF29C50), Color(0xFFC77A38)],
    [Color(0xFFF28B50), Color(0xFFC46A36)],
    [Color(0xFFD95F43), Color(0xFFA6452E)],
    [Color(0xFF248EA6), Color(0xFFD95F43)],
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
              color: const Color(0xFF1E1E1E), // Fondo oscuro para la tarjeta
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)), 
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
                        // Imagen o gradiente
                        tieneImagen
                            ? Image.network(
                                comunidad.urlPortada.startsWith('http') ? comunidad.urlPortada : 'http://127.0.0.1:8000${comunidad.urlPortada}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _GradientePlaceholder(paleta: paleta),
                              )
                            : _GradientePlaceholder(paleta: paleta),

                        // Degradado oscuro para fundirse con la zona de texto
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
                                  const Color(0xFF1E1E1E).withOpacity(0.9), // Matching card background
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Badge privacidad
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212).withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              comunidad.esPublica
                                  ? Icons.public_rounded
                                  : Icons.lock_rounded,
                              size: 14,
                              color: comunidad.esPublica
                                  ? const Color(0xFF248EA6) // Teal
                                  : const Color(0xFFD95F43), // Rust
                            ),
                          ),
                        ),

                        // Rating
                        if (comunidad.ratingMedio > 0)
                          Positioned(
                            bottom: 6,
                            left: 8,
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF29C50), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  comunidad.ratingMedio.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Nombre y Creador ──────────────────────────
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: const Color(0xFF1E1E1E),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            comunidad.nombre,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🐾 ${comunidad.creadorNombre}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          if (comunidad.esMiembro || (comunidad.creadorId != null && comunidad.creadorId == comunidad.id)) ...[
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF28B50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ENTRAR',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                  ],
                                ),
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
          size: 40,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
