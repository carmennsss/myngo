import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/comentario.dart';
import 'hover_profile_card.dart';

class ComentarioItem extends StatelessWidget {
  final Comentario comentario;
  final Color? highlightColor;
  final Color? textColor;
  final Color? subTextColor;

  const ComentarioItem({
    super.key,
    required this.comentario,
    this.highlightColor,
    this.textColor,
    this.subTextColor,
  });

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar con Hover Card (Solo aquí)
          HoverProfileCard(
            nombre: comentario.autorNombre,
            avatarUrl: comentario.autorFoto,
            marcoUrl: comentario.autorMarco,
            fondoUrl: comentario.autorFondo,
            puntos: 0,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              context.go('/inicio/perfiles/${comentario.autorId}');
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (comentario.autorMarco != null && comentario.autorMarco!.isNotEmpty)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: comentario.autorMarco!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: highlightColor?.withOpacity(0.1) ?? const Color(0xFFC35E34).withOpacity(0.1),
                    backgroundImage: comentario.autorFoto != null
                        ? CachedNetworkImageProvider(comentario.autorFoto!)
                        : null,
                    child: comentario.autorFoto == null
                        ? Text(comentario.autorNombre.isNotEmpty ? comentario.autorNombre[0].toUpperCase() : '?',
                            style: TextStyle(color: highlightColor ?? const Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 12))
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: Nombre · Tiempo
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comentario.autorNombre,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${_formatFecha(comentario.fechaCreacion)}',
                      style: GoogleFonts.outfit(
                        color: subTextColor ?? Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Texto
                Text(
                  comentario.contenido,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
