import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/publicacion.dart';
import '../../widgets/comunes/grid_imagenes_post.dart';
import '../../widgets/comunes/acciones_y_comentarios_post.dart';
import '../../utils/estilo_post_helper.dart';
import '../../widgets/comunes/hover_profile_card.dart';

class PantallaDetallePost extends StatefulWidget {
  final Publicacion post;

  const PantallaDetallePost({super.key, required this.post});

  @override
  State<PantallaDetallePost> createState() => _PantallaDetallePostState();
}

class _PantallaDetallePostState extends State<PantallaDetallePost> {
  @override
  void initState() {
    super.initState();
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('h:mm a · d MMM. yyyy', 'es_ES').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final estilo = widget.post.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final colorTexto = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
    final colorSubtexto = esFondoClaro ? Colors.grey.shade600 : Colors.white70;
    final bgColor = estilo != null ? EstiloPostHelper.effectiveBgColor(estilo) : Colors.white;
    final Color colorComunidad = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorTexto),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publicación',
              style: GoogleFonts.outfit(
                color: colorTexto,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'en ${widget.post.comunidadNombre}',
              style: GoogleFonts.outfit(
                color: colorSubtexto,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: EstiloPostHelper.buildDecoracion(
          estilo,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HoverProfileCard(
                          nombre: widget.post.autorNombre,
                          avatarUrl: widget.post.autorFoto,
                          marcoUrl: widget.post.autorMarco,
                          fondoUrl: widget.post.autorFondo ?? widget.post.autorEstiloPost?['url_fondo'],
                          puntos: 0,
                          onTap: () => context.push('/inicio/perfiles/${widget.post.autorId}'),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (widget.post.autorMarco != null && widget.post.autorMarco!.isNotEmpty)
                                      Positioned.fill(
                                        child: CachedNetworkImage(
                                          imageUrl: widget.post.autorMarco!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                                        backgroundImage: widget.post.autorFoto != null
                                            ? CachedNetworkImageProvider(widget.post.autorFoto!)
                                            : null,
                                        child: widget.post.autorFoto == null 
                                            ? Text(widget.post.autorNombre.isNotEmpty ? widget.post.autorNombre[0].toUpperCase() : '?',
                                                style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 18))
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.post.autorNombre,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorTexto,
                                    ),
                                  ),
                                  Text(
                                    '@${widget.post.autorNombre.toLowerCase().replaceAll(' ', '')}',
                                    style: GoogleFonts.outfit(
                                      color: esFondoClaro ? colorComunidad : colorSubtexto,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.post.titulo.isNotEmpty) ...[
                          Text(
                            widget.post.titulo,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          widget.post.contenidoTexto,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            height: 1.4,
                            color: colorTexto,
                          ),
                        ),
                        if (widget.post.urlsImagenes.isNotEmpty || widget.post.urlImagen != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 500),
                              child: GridImagenesPost(
                                urls: widget.post.urlsImagenes.isNotEmpty ? widget.post.urlsImagenes : [widget.post.urlImagen!],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          _formatFecha(widget.post.fechaCreacion),
                          style: GoogleFonts.outfit(
                            color: colorSubtexto,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(height: 32),
                        const SizedBox(height: 16),
                        AccionesYComentariosPost(
                          post: widget.post,
                          colorTexto: colorTexto,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
