import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/publicacion.dart';
import 'menu_opciones_contenido.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/usuario.dart';
import '../../screens/perfiles/pantalla_detalle_perfil.dart';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.shade700,
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (_navegandoAPerfil)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                                ),
                            ],
                          ),
                          Text(
                            fecha,
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
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
                      onEliminado: () {
                        Navigator.pop(context);
                        if (onEliminado != null) onEliminado!();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Imagen (si existe) ──
            if (tieneImagen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    publicacion.urlImagen!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFF1E1E1E),
                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48)),
                    ),
                  ),
                ),
              ),

            // ── Título ──
            if (publicacion.titulo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  publicacion.titulo,
                  style: GoogleFonts.inter(
                    color: Colors.white,
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
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

            // ── Stats: likes, comentarios ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text('${publicacion.likesCount}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text('${publicacion.comentariosCount}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 16),
                  if (publicacion.comunidadNombre.isNotEmpty && publicacion.comunidadNombre != 'General') ...[
                    const Icon(Icons.group_outlined, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(publicacion.comunidadNombre, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
