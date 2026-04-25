import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/publicacion.dart';
import 'menu_opciones_contenido.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/usuario.dart';
import '../../screens/perfiles/pantalla_detalle_perfil.dart';
import 'grid_imagenes_post.dart';
import 'acciones_y_comentarios_post.dart';
import '../../utils/estilo_post_helper.dart';


/// Bottom sheet estilo Instagram que muestra el detalle completo de un post.
class DetallePublicacionSheet extends StatefulWidget {
  final Publicacion publicacion;
  final String avatarUrl;
  final VoidCallback? onEliminado;
  final Function(Usuario)? onProfileSelected;

  const DetallePublicacionSheet({
    super.key,
    required this.publicacion,
    required this.avatarUrl,
    this.onEliminado,
    this.onProfileSelected,
  });

  static void mostrar(
    BuildContext context, {
    required Publicacion publicacion,
    required String avatarUrl,
    VoidCallback? onEliminado,
    Function(Usuario)? onProfileSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetallePublicacionSheet(
        publicacion: publicacion,
        avatarUrl: avatarUrl,
        onEliminado: onEliminado,
        onProfileSelected: onProfileSelected,
      ),
    );
  }

  @override
  State<DetallePublicacionSheet> createState() => _DetallePublicacionSheetState();
}

class _DetallePublicacionSheetState extends State<DetallePublicacionSheet> {
  bool _navegandoAPerfil = false;

  void _irAPerfil(BuildContext context) async {
    if (_navegandoAPerfil) return;
    setState(() => _navegandoAPerfil = true);
    
    final res = await ServicioUsuarios().obtenerDatosUsuario(widget.publicacion.autorId);
    
    if (mounted) {
      setState(() => _navegandoAPerfil = false);
      if (res.exito && res.datos != null) {
        Navigator.pop(context); // Cerrar bottom sheet
        if (widget.onProfileSelected != null) {
          widget.onProfileSelected!(res.datos!);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDetallePerfil(
                usuario: res.datos!,
                comunidadIdContexto: widget.publicacion.comunidadId,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicacion = widget.publicacion;
    final avatarUrl = widget.avatarUrl;
    final onEliminado = widget.onEliminado;
    final tieneImagen = publicacion.urlImagen != null && publicacion.urlImagen!.isNotEmpty;
    final fecha = DateFormat('dd MMM yyyy · HH:mm').format(publicacion.fechaCreacion.toLocal());

    final estilo = publicacion.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final colorTexto = esFondoClaro ? Colors.black87 : Colors.white;
    final colorSubtexto = esFondoClaro ? Colors.black54 : Colors.grey;

    // Color efectivo de fondo para el Scaffold (no puede ser gradiente, usamos el color promedio)
    final bgColor = estilo != null ? EstiloPostHelper.effectiveBgColor(estilo) : const Color(0xFF121212);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: EstiloPostHelper.buildDecoracion(
          estilo,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          borderWidth: 2,
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // ── Handle drag ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorSubtexto.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Cabecera: avatar + nombre + menú ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => _irAPerfil(context),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF248EA6).withOpacity(0.3),
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              publicacion.autorNombre.isNotEmpty ? publicacion.autorNombre[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF248EA6), fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${publicacion.autorNombre}',
                                style: GoogleFonts.inter(
                                  color: colorTexto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (_navegandoAPerfil)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: colorSubtexto)),
                                ),
                            ],
                          ),
                          Text(
                            fecha,
                            style: GoogleFonts.inter(color: colorSubtexto, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    MenuOpcionesContenido(
                      tipoObjeto: 'POST',
                      objetoId: publicacion.id,
                      autorId: publicacion.autorId,
                      comunidadId: publicacion.comunidadId,
                      creadorComunidadId: publicacion.creadorComunidadId,
                      iconColor: colorTexto,
                      onEliminado: () {
                        Navigator.pop(context);
                        if (onEliminado != null) onEliminado!();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Imagen / Rejilla (si existe) ──
            if (publicacion.urlsImagenes.isNotEmpty || tieneImagen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridImagenesPost(
                  urls: publicacion.urlsImagenes.isNotEmpty ? publicacion.urlsImagenes : [publicacion.urlImagen!],
                ),
              ),

            // ── Título ──
            if (publicacion.titulo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  publicacion.titulo,
                  style: GoogleFonts.inter(
                    color: colorTexto,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

            // ── Contenido texto ──
            if (publicacion.contenidoTexto.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, publicacion.titulo.isEmpty ? 16 : 8, 16, 16),
                child: Text(
                  publicacion.contenidoTexto,
                  style: GoogleFonts.inter(
                    color: colorTexto.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

            // ── Comunidad Badge ──
            if (publicacion.comunidadNombre.isNotEmpty && publicacion.comunidadNombre != 'General')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: colorSubtexto, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      publicacion.comunidadNombre,
                      style: GoogleFonts.inter(color: colorSubtexto, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // ── Stats: likes, comentarios interactivos ──
            AccionesYComentariosPost(
              post: publicacion,
              colorTexto: colorTexto,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
