import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/publicacion.dart';
import 'package:myngo_app/widgets/comunes/menu_opciones_contenido.dart';
import 'package:myngo_app/services/servicio_interaccion.dart';
import '../pantalla_detalle_publicacion.dart';

class TarjetaPublicacion extends StatefulWidget {
  final Publicacion publicacion;
  final VoidCallback? alPresionar;
  final VoidCallback? onEliminado;
  final bool mostrarOpciones;
  
  const TarjetaPublicacion({
    super.key, 
    required this.publicacion, 
    this.alPresionar,
    this.onEliminado,
    this.onLikeToggle,
    this.mostrarOpciones = true,
  });

  final Function(bool liked, int likesCount)? onLikeToggle;

  @override
  State<TarjetaPublicacion> createState() => _TarjetaPublicacionState();
}

class _TarjetaPublicacionState extends State<TarjetaPublicacion> {
  final _servicioInteraccion = ServicioInteraccion();
  bool _liked = false;
  int _likesCount = 0;
  int _comentariosCount = 0;

  @override
  void initState() {
    super.initState();
    _liked = widget.publicacion.usuarioDioLike;
    _likesCount = widget.publicacion.likesCount;
    _comentariosCount = widget.publicacion.comentariosCount;
  }

  Future<void> _toggleLike() async {
    setState(() {
      if (_liked) {
        _likesCount--;
      } else {
        _likesCount++;
      }
      _liked = !_liked;
    });

    if (widget.onLikeToggle != null) {
      widget.onLikeToggle!(_liked, _likesCount);
    }

    final res = await _servicioInteraccion.toggleLike(widget.publicacion.id);
    if (!res.exito && mounted) {
      // Revertir si falla
      setState(() {
        if (_liked) {
          _likesCount--;
        } else {
          _likesCount++;
        }
        _liked = !_liked;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
    }
  }

  void _irADetalle() async {
    final updatedPub = widget.publicacion.copyWith(
      usuarioDioLike: _liked,
      likesCount: _likesCount,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaDetallePublicacion(publicacion: updatedPub),
      ),
    );

    if (result is Publicacion && mounted) {
      setState(() {
        _liked = result.usuarioDioLike;
        _likesCount = result.likesCount;
        _comentariosCount = result.comentariosCount;
      });
    } else if (result == true && mounted) {
      // Si solo devolvió true, quizás queremos refrescar toda la tarjeta o la lista
      if (widget.alPresionar != null) widget.alPresionar!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: InkWell(
        onTap: _irADetalle,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF248EA6).withOpacity(0.2),
                  radius: 20,
                  child: const Icon(Icons.person, color: Color(0xFF248EA6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.publicacion.autorNombre.isNotEmpty ? widget.publicacion.autorNombre : 'Usuario ${widget.publicacion.autorId}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Reciente 🐾', 
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.mostrarOpciones)
                  MenuOpcionesContenido(
                    tipoObjeto: 'POST',
                    objetoId: widget.publicacion.id,
                    autorId: widget.publicacion.autorId,
                    comunidadId: widget.publicacion.comunidadId,
                    creadorComunidadId: widget.publicacion.creadorComunidadId,
                    onEliminado: () {
                      if (widget.onEliminado != null) widget.onEliminado!();
                      if (widget.alPresionar != null) widget.alPresionar!();
                    },
                  ),
              ],
            ),
          ),

          // Texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.publicacion.contenidoTexto.isNotEmpty ? widget.publicacion.contenidoTexto : widget.publicacion.titulo,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Imagen
          if (widget.publicacion.urlImagen != null && widget.publicacion.urlImagen!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.publicacion.urlImagen!,
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

          // Interacciones
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildInteractionButton(
                  _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                  _likesCount.toString(), 
                  _liked ? const Color(0xFFF28B50) : Colors.grey,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 24),
                _buildInteractionButton(
                  Icons.chat_bubble_outline_rounded, 
                  _comentariosCount.toString(), 
                  Colors.grey,
                  onTap: _irADetalle,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (count != '0' || icon == Icons.chat_bubble_outline_rounded) ...[
              const SizedBox(width: 8),
              Text(
                count,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
