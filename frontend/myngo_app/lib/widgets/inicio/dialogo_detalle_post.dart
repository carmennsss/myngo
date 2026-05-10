import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../comunes/grid_imagenes_post.dart';
import '../comunes/acciones_y_comentarios_post.dart';
import '../comunes/menu_opciones_contenido.dart';
import '../../utils/estilo_post_helper.dart';
import '../comunes/hover_profile_card.dart';
import '../dialogo_crear_post.dart';
import '../../services/servicio_comunidades.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class DialogoDetallePublicacion extends StatefulWidget {
  final Publicacion post;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;
  final bool esMiembro;
  final String? contextoVisual;
  final String? fuente;

  const DialogoDetallePublicacion({
    super.key,
    required this.post,
    this.onComunidadSelected,
    this.onProfileSelected,
    this.esMiembro = true,
    this.contextoVisual,
    this.fuente,
  });

  @override
  State<DialogoDetallePublicacion> createState() => _DialogoDetallePublicacionState();
}

class _DialogoDetallePublicacionState extends State<DialogoDetallePublicacion> {
  @override
  void initState() {
    super.initState();
  }

  String _formatRelativeDate(DateTime fecha, String Function(String, [Map<String, Object>?]) tr) {
    try {
      final now = DateTime.now();
      final diff = now.difference(fecha);

      if (diff.inMinutes < 1) return tr('timeJustNow');
      if (diff.inMinutes < 60) return '${diff.inMinutes}${tr('timeMinutes')}';
      if (diff.inHours < 24) return '${diff.inHours}${tr('timeHours')}';
      if (diff.inDays < 7) return '${diff.inDays}${tr('timeDays')}';
      
      // Para fechas más antiguas, usamos el formato estándar
      return DateFormat('d MMM').format(fecha);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final estilo = widget.post.autorEstiloPost;
        final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
        final colorTexto = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
        final colorSubtexto = esFondoClaro ? Colors.grey.shade600 : Colors.white70;
    

    final fuenteEfectiva = widget.fuente ?? EstiloPostHelper.getFontFamily(estilo);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: EstiloPostHelper.buildDecoracion(
                estilo,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              tr('postTitleLabel'),
                              style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: colorTexto),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.go('/inicio/comunidades/${widget.post.comunidadId}');
                              },
                              label: Text(tr('communityView'), style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontSize: 12, color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)),
                              icon: const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFC35E34)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (widget.esMiembro)
                              MenuOpcionesContenido(
                                tipoObjeto: 'POST',
                                objetoId: widget.post.id,
                                autorId: widget.post.autorId,
                                comunidadId: widget.post.comunidadId,
                                onEditado: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => DialogoCrearPost(
                                      titulo: tr('postEditTitle'),
                                      initialTexto: widget.post.contenidoTexto,
                                      onPublicar: (texto, imagenes, etiquetas, {void Function(int, int)? alProgresar}) async {
                                        final res = await ServicioComunidades().actualizarPublicacion(
                                          idPublicacion: widget.post.id,
                                          texto: texto,
                                        );
                                        if (res.exito) {
                                          setState(() {
                                            widget.post.contenidoTexto = texto;
                                          });
                                          return true;
                                        }
                                        return false;
                                      },
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Avatar con Hover Card (Solo aquí)
                                    HoverProfileCard(
                                      nombre: widget.post.autorNombre,
                                      avatarUrl: widget.post.autorFoto,
                                      marcoUrl: widget.post.autorMarco,
                                      fondoUrl: widget.post.autorFondo ?? widget.post.autorEstiloPost?['url_fondo'],
                                      estado: widget.post.autorEstado ?? 'DESCONECTADO',
                                      userId: widget.post.autorId,
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.go('/inicio/perfiles/${widget.post.autorNombre}');
                                      },
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
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
                                                radius: 18,
                                                backgroundColor: Colors.white,
                                                child: widget.post.autorFoto != null && widget.post.autorFoto!.isNotEmpty
                                                    ? ClipOval(
                                                        child: CachedNetworkImage(
                                                          imageUrl: widget.post.autorFoto!,
                                                          width: 36,
                                                          height: 36,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
                                                        ),
                                                      )
                                                    : Text(
                                                        widget.post.autorNombre.isNotEmpty ? widget.post.autorNombre[0].toUpperCase() : '?',
                                                        style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 14),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.post.autorNombre,
                                            style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontWeight: FontWeight.bold, color: colorTexto, fontSize: 15),
                                          ),
                                          Text(
                                            '@${widget.post.autorNombre.toLowerCase().replaceAll(' ', '')} · ${_formatRelativeDate(widget.post.fechaCreacion, tr)}',
                                            style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: colorSubtexto, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (widget.post.titulo.isNotEmpty) ...[
                                  Text(
                                    widget.post.titulo,
                                    style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: colorTexto),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  widget.post.contenidoTexto,
                                  style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontSize: 16, height: 1.4, color: colorTexto),
                                ),
                                if (widget.post.media.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 400),
                                      child: GridImagenesPost(
                                        media: widget.post.media,
                                        mostrarDescarga: widget.post.usuarioEsMiembro,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                AccionesYComentariosPost(
                                  post: widget.post,
                                  colorTexto: colorTexto,
                                  esMiembro: widget.post.usuarioEsMiembro,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            Icon(icon, color: color, size: 20),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: GoogleFonts.outfit(color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
