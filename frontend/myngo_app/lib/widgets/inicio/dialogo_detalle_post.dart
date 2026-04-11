import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../screens/perfiles/pantalla_detalle_perfil.dart';
import '../../screens/comunidades/pantalla_detalle_comunidad.dart';

/// Diálogo modal que muestra el detalle completo de una publicación del feed.
class DialogoDetallePublicacion extends StatefulWidget {
  final Publicacion post;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;

  const DialogoDetallePublicacion({super.key, required this.post, this.onComunidadSelected, this.onProfileSelected});

  @override
  State<DialogoDetallePublicacion> createState() => _DialogoDetallePublicacionState();
}

class _DialogoDetallePublicacionState extends State<DialogoDetallePublicacion> {
  bool _cargando = false;

  Future<void> _irAComunidadOPerfil() async {
    setState(() => _cargando = true);
    try {
      if (widget.post.comunidadId != null && widget.post.comunidadId != 0) {
        final res = await ServicioComunidades().obtenerComunidad(widget.post.comunidadId);
        if (res.exito && res.datos != null && mounted) {
          Navigator.pop(context);
          if (widget.onComunidadSelected != null) {
            widget.onComunidadSelected!(res.datos!);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleComunidad(comunidad: res.datos!)));
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos cargar la comunidad 🐾')));
        }
      } else {
        final res = await ServicioUsuarios().obtenerDatosUsuario(widget.post.autorId);
        if (res.exito && res.datos != null && mounted) {
          Navigator.pop(context);
          if (widget.onProfileSelected != null) {
            widget.onProfileSelected!(res.datos!);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetallePerfil(usuario: res.datos!)));
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos cargar el perfil 🐾')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.post.urlImagen != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                child: Container(
                  height: 220,
                  color: const Color(0xFF1A1A1A),
                  child: Image.network(
                    widget.post.urlImagen!,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50), strokeWidth: 2)),
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 48)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                        child: Text(widget.post.comunidadNombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.comunidadNombre, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 14)),
                            Text(widget.post.autorNombre ?? '', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.post.titulo, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 20, height: 1.3)),
                  if (widget.post.contenidoTexto.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(widget.post.contenidoTexto, style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 15, height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: const Color(0xFFC35E34).withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(widget.post.likesCount.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                      const SizedBox(width: 20),
                      Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(widget.post.comentariosCount.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFC35E34))),
                          child: Text('Cerrar', style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _irAComunidadOPerfil,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC35E34), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _cargando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : Text(
                                  widget.post.comunidadId != null && widget.post.comunidadId != 0 ? 'Ver Comunidad' : 'Ver Perfil',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
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
