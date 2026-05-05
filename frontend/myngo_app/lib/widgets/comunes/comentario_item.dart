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
  final Function(Comentario)? onReply;
  final bool esRespuesta;

  const ComentarioItem({
    super.key,
    required this.comentario,
    this.highlightColor,
    this.textColor,
    this.subTextColor,
    this.onReply,
    this.esRespuesta = false,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: esRespuesta ? 48 : 16, 
            right: 16, 
            top: 12,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con Hover Card
              HoverProfileCard(
                nombre: comentario.autorNombre,
                avatarUrl: comentario.autorFoto,
                marcoUrl: comentario.autorMarco,
                fondoUrl: comentario.autorFondo,
                userId: comentario.autorId,
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  context.go('/inicio/perfiles/${comentario.autorNombre}');
                },
                child: SizedBox(
                  width: esRespuesta ? 32 : 44,
                  height: esRespuesta ? 32 : 44,
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
                        radius: esRespuesta ? 12 : 16,
                        backgroundColor: Colors.white,
                        child: comentario.autorFoto != null && comentario.autorFoto!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: comentario.autorFoto!,
                                  width: esRespuesta ? 24 : 32,
                                  height: esRespuesta ? 24 : 32,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                  errorWidget: (context, url, error) => _buildPlaceholder(comentario.autorNombre, esRespuesta),
                                ),
                              )
                            : _buildPlaceholder(comentario.autorNombre, esRespuesta),
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
                              fontSize: esRespuesta ? 13 : 14,
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
                            fontSize: esRespuesta ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Texto
                    Text(
                      comentario.contenido,
                      style: GoogleFonts.outfit(
                        fontSize: esRespuesta ? 13 : 14,
                        height: 1.3,
                        color: textColor,
                      ),
                    ),
                    if (!esRespuesta && onReply != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () => onReply!(comentario),
                          child: Text(
                            'Responder',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFF28B50),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Renderizar respuestas
        if (comentario.respuestas.isNotEmpty)
          ...comentario.respuestas.map((resp) => ComentarioItem(
            comentario: resp,
            textColor: textColor,
            subTextColor: subTextColor,
            esRespuesta: true,
          )),
      ],
    );
  }
  
  Widget _buildPlaceholder(String nombre, bool esRes) {
    return Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
      style: TextStyle(
        color: const Color(0xFFC35E34), 
        fontWeight: FontWeight.bold, 
        fontSize: esRes ? 10 : 12
      ),
    );
  }
}
