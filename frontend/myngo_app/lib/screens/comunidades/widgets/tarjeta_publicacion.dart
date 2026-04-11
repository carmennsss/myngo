import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/publicacion.dart';
import 'package:myngo_app/widgets/comunes/menu_opciones_contenido.dart';
import 'package:myngo_app/services/servicio_interaccion.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';
import 'package:myngo_app/widgets/comunes/boton_tactil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pantalla_detalle_publicacion.dart';
import '../../perfiles/pantalla_detalle_perfil.dart';

class TarjetaPublicacion extends StatefulWidget {
  final Publicacion publicacion;
  final VoidCallback? alPresionar;
  final VoidCallback? onEliminado;
  final bool mostrarOpciones;
  final Function(bool liked, int likesCount)? onLikeToggle;
  final int? comunidadId;
  
  const TarjetaPublicacion({
    super.key, 
    required this.publicacion, 
    this.alPresionar,
    this.onEliminado,
    this.onLikeToggle,
    this.mostrarOpciones = true,
    this.comunidadId,
  });

  @override
  State<TarjetaPublicacion> createState() => _TarjetaPublicacionState();
}

class _TarjetaPublicacionState extends State<TarjetaPublicacion> {
  final _servicioInteraccion = ServicioInteraccion();
  final _servicioUsuarios = ServicioUsuarios();
  bool _liked = false;
  int _likesCount = 0;
  int _comentariosCount = 0;
  bool _estaLogueado = false;
  bool _navegandoAPerfil = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.publicacion.usuarioDioLike;
    _likesCount = widget.publicacion.likesCount;
    _comentariosCount = widget.publicacion.comentariosCount;
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _estaLogueado = prefs.getString('auth_token') != null;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (!_estaLogueado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Vaya! Debes iniciar miau-sesión para dar like 🐾', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFC35E34),
        duration: const Duration(seconds: 4),
      ));
      return;
    }

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
      if (widget.alPresionar != null) widget.alPresionar!();
    }
  }

  void _mostrarImagenFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: 'img_${widget.publicacion.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A4440).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  BotonTactil(
                    onTap: () async {
                      if (_navegandoAPerfil) return;
                      setState(() => _navegandoAPerfil = true);
                      final res = await _servicioUsuarios.obtenerDatosUsuario(widget.publicacion.autorId);
                      if (mounted) {
                        setState(() => _navegandoAPerfil = false);
                        if (res.exito && res.datos != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PantallaDetallePerfil(
                                usuario: res.datos!,
                                comunidadIdContexto: widget.comunidadId,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                          radius: 20,
                          child: Text(
                            widget.publicacion.autorNombre.isNotEmpty ? widget.publicacion.autorNombre[0].toUpperCase() : '?',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.publicacion.autorNombre.isNotEmpty ? widget.publicacion.autorNombre : 'Usuario ${widget.publicacion.autorId}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4A4440),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Publicado recientemente 🐾', 
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
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

            // Texto contenido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                widget.publicacion.contenidoTexto.isNotEmpty ? widget.publicacion.contenidoTexto : widget.publicacion.titulo,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF4A4440),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Imagen principal
            if (widget.publicacion.urlImagen != null && widget.publicacion.urlImagen!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: () => _mostrarImagenFullscreen(context, widget.publicacion.urlImagen!),
                  child: Hero(
                    tag: 'img_${widget.publicacion.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.network(
                            widget.publicacion.urlImagen!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: const Color(0xFFFEF5F1),
                              child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            // Acciones/Interacciones
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  _buildBotonInteraccion(
                    icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                    count: _likesCount.toString(), 
                    activeColor: const Color(0xFFC35E34),
                    isActive: _liked,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 20),
                  _buildBotonInteraccion(
                    icon: Icons.chat_bubble_outline_rounded, 
                    count: _comentariosCount.toString(), 
                    activeColor: const Color(0xFF248EA6),
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

  Widget _buildBotonInteraccion({
    required IconData icon, 
    required String count, 
    required Color activeColor,
    bool isActive = false, 
    VoidCallback? onTap
  }) {
    return BotonTactil(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isActive ? activeColor : Colors.grey.shade700),
            if (count != '0') ...[
              const SizedBox(width: 8),
              Text(
                count,
                style: GoogleFonts.outfit(
                  color: isActive ? activeColor : Colors.grey.shade700,
                  fontWeight: FontWeight.w900,
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
