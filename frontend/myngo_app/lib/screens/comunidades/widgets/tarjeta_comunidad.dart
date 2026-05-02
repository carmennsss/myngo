import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';
import '../../../widgets/comunes/boton_tactil.dart';
import '../../../utils/configuracion.dart';

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
    [Color(0xFFC35E34), Color(0xFFA6452E)],
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = _paletas[comunidad.id % _paletas.length];
    final tieneImagen = comunidad.urlPortada.isNotEmpty;

    return BotonTactil(
      onTap: alPresionar,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A4440).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portada
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  tieneImagen
                      ? Image.network(
                          comunidad.urlPortada.startsWith('http') 
                              ? comunidad.urlPortada 
                              : Uri.encodeFull('${Configuracion.baseUrl}${comunidad.urlPortada.startsWith('/') ? '' : '/'}${comunidad.urlPortada}'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _GradientePlaceholder(paleta: paleta),
                        )
                      : _GradientePlaceholder(paleta: paleta),

                  // Badge Privacidad
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        comunidad.esPublica ? Icons.public_rounded : Icons.lock_outline_rounded,
                        size: 16,
                        color: comunidad.esPublica ? const Color(0xFF248EA6) : const Color(0xFFC35E34),
                      ),
                    ),
                  ),

                  // Gradiente inferior suave
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comunidad.nombre.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A4440),
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              '${comunidad.miembrosCount}',
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: comunidad.esMiembro ? const Color(0xFF248EA6).withOpacity(0.1) : const Color(0xFFC35E34),
                            borderRadius: BorderRadius.circular(12),
                            border: comunidad.esMiembro ? Border.all(color: const Color(0xFF248EA6).withOpacity(0.2)) : null,
                          ),
                          child: Text(
                            comunidad.esMiembro ? 'ENTRAR 🐾' : 'UNIRSE ✨',
                            style: GoogleFonts.outfit(
                              color: comunidad.esMiembro ? const Color(0xFF248EA6) : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        child: Icon(Icons.pets_rounded, color: Colors.white.withOpacity(0.3), size: 40),
      ),
    );
  }
}
