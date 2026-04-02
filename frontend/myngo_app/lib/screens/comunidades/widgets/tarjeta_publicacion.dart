import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/publicacion.dart';
import 'package:intl/intl.dart';

class TarjetaPublicacion extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback? alPresionar;
  
  const TarjetaPublicacion({super.key, required this.publicacion, this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (User Info) ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF248EA6).withOpacity(0.2), // Teal bg
                  radius: 20,
                  child: const Icon(Icons.person, color: Color(0xFF248EA6)), // Teal icon
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.autorNombre?.isNotEmpty == true ? publicacion.autorNombre! : 'Usuario ${publicacion.autorId}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'hace 2 h', // Placeholder temporal
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ── Content (Text) ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              publicacion.contenidoTexto?.isNotEmpty == true ? publicacion.contenidoTexto! : publicacion.titulo,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Content (Image if exists) ───────────────────────────
          if (publicacion.urlImagen != null && publicacion.urlImagen!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      publicacion.urlImagen!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: const Color(0xFF121212),
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),

          // ── Interaction Row ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildInteractionButton(Icons.favorite_rounded, '0', const Color(0xFFD95F43)), // Rust red
                const SizedBox(width: 24),
                _buildInteractionButton(Icons.chat_bubble_outline_rounded, '0', Colors.grey),
                const Spacer(),
                _buildInteractionButton(Icons.send_rounded, '', Colors.grey),
                const SizedBox(width: 16),
                _buildInteractionButton(Icons.bookmark_border_rounded, '', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            count,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
