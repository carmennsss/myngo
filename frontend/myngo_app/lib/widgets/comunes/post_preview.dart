import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/estilo_post_helper.dart';

class PostPreview extends StatelessWidget {
  final Map<String, dynamic>? estilo;
  final String? avatarUrl;
  final String? marcoUrl;
  final String nombreUsuario;

  const PostPreview({
    super.key,
    this.estilo,
    this.avatarUrl,
    this.marcoUrl,
    this.nombreUsuario = 'Usuario',
  });

  @override
  Widget build(BuildContext context) {
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final colorTexto = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
    final colorSubtexto = esFondoClaro ? Colors.grey.shade600 : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EstiloPostHelper.buildDecoracion(
        estilo,
        borderRadius: BorderRadius.circular(20),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Marco (detrás)
                    if (marcoUrl != null && marcoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(marcoUrl!, fit: BoxFit.contain),
                      ),
                    // 2. Avatar (encima)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                            : null,
                        color: Colors.grey.shade300,
                      ),
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? Center(child: Text(nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi nuevo estilo ✨',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colorTexto, fontSize: 14),
                  ),
                  Text(
                    '@$nombreUsuario',
                    style: GoogleFonts.outfit(color: colorSubtexto, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¡Mira cómo queda mi perfil con estas mejoras! ¿Te gusta el nuevo diseño? 🐾',
            style: GoogleFonts.outfit(color: colorTexto, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 18, color: colorSubtexto),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: colorSubtexto),
              const Spacer(),
              Icon(Icons.bookmark_border_rounded, size: 18, color: colorSubtexto),
            ],
          ),
        ],
      ),
    );
  }
}
