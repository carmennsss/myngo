import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../services/servicio_interaccion.dart';
import '../comunes/menu_opciones_contenido.dart';
import 'dialogo_detalle_post.dart';
import '../comunes/grid_imagenes_post.dart';
import '../../utils/estilo_post_helper.dart';

class TarjetaPost extends StatefulWidget {
  final Publicacion post;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;
  final VoidCallback? onJoin;
  final bool estaEnComunidad;
  final VoidCallback? onEliminado;

  const TarjetaPost({
    super.key,
    required this.post,
    this.onComunidadSelected,
    this.onProfileSelected,
    this.onJoin,
    this.estaEnComunidad = false,
    this.onEliminado,
  });

  @override
  State<TarjetaPost> createState() => _TarjetaPostState();
}

class _TarjetaPostState extends State<TarjetaPost> {
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  late bool _dioLike;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _dioLike = widget.post.usuarioDioLike;
    _likesCount = widget.post.likesCount;
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DialogoDetallePublicacion(post: widget.post),
    );
  }

  Future<void> _toggleLike() async {
    setState(() {
      _dioLike = !_dioLike;
      _likesCount += _dioLike ? 1 : -1;
      widget.post.usuarioDioLike = _dioLike;
      widget.post.likesCount = _likesCount;
    });

    final res = await _servicioInteraccion.toggleLike(widget.post.id);
    if (!res.exito && mounted) {
      setState(() {
        _dioLike = !_dioLike;
        _likesCount += _dioLike ? 1 : -1;
        widget.post.usuarioDioLike = _dioLike;
        widget.post.likesCount = _likesCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilo = widget.post.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final textColor = esFondoClaro ? const Color(0xFF4A4440) : Colors.white;
    final subTextColor = esFondoClaro ? Colors.black54 : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetalles(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: EstiloPostHelper.buildDecoracion(
            estilo,
            borderRadius: BorderRadius.circular(16),
            shadows: [
              BoxShadow(
                color: (EstiloPostHelper.parseHex(estilo?['borde']?.toString()) ?? const Color(0xFF4A4440)).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onComunidadSelected != null ? () => widget.onComunidadSelected!(Comunidad(
                    id: widget.post.comunidadId, 
                    nombre: widget.post.comunidadNombre, 
                    descripcion: '', 
                    creadorNombre: 'Sistema',
                    urlPortada: '',
                    esPublica: true, 
                    esVerificada: false,
                    esMiembro: false,
                    fechaCreacion: DateTime.now(), 
                    ratingMedio: 0.0,
                    creadorId: widget.post.creadorComunidadId ?? 0)) : null,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                    backgroundImage: widget.post.autorFoto != null
                        ? CachedNetworkImageProvider(widget.post.autorFoto!)
                        : null,
                    child: widget.post.autorFoto == null
                        ? Text(widget.post.autorNombre.isNotEmpty ? widget.post.autorNombre[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 16))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.post.comunidadNombre, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                                GestureDetector(
                                  onTap: () {
                                    if (widget.onProfileSelected != null) {
                                      widget.onProfileSelected!(Usuario(
                                        id: widget.post.autorId,
                                        perfilId: 0,
                                        nombreUsuario: widget.post.autorNombre,
                                        email: '',
                                        esVerificado: false,
                                        esPublico: true,
                                        ratingActual: 0.0,
                                        fechaRegistro: DateTime.now(),
                                      ));
                                    } else {
                                      context.go('/inicio/perfiles/${widget.post.autorId}');
                                    }
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '@${widget.post.autorNombre.toLowerCase().replaceAll(' ', '')}',
                                          style: TextStyle(color: esFondoClaro ? Theme.of(context).primaryColor : Colors.white70, fontWeight: FontWeight.w600),
                                        ),
                                        TextSpan(
                                          text: ' • ${widget.post.fechaCreacion.day}/${widget.post.fechaCreacion.month}',
                                          style: TextStyle(color: subTextColor),
                                        ),
                                      ],
                                    ),
                                    style: GoogleFonts.outfit(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MenuOpcionesContenido(
                            tipoObjeto: 'POST',
                            objetoId: widget.post.id,
                            autorId: widget.post.autorId,
                            comunidadId: widget.post.comunidadId,
                            onEliminado: widget.onEliminado,
                            tituloPreview: widget.post.titulo,
                            iconColor: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.post.titulo.isNotEmpty)
                        Text(widget.post.titulo, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                      if (widget.post.contenidoTexto.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(widget.post.contenidoTexto, style: GoogleFonts.outfit(color: subTextColor, fontSize: 15), maxLines: 4, overflow: TextOverflow.ellipsis),
                      ],
                      if (widget.post.urlsImagenes.isNotEmpty || (widget.post.urlImagen != null && widget.post.urlImagen!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GridImagenesPost(
                            urls: widget.post.urlsImagenes.isNotEmpty ? widget.post.urlsImagenes : [widget.post.urlImagen!],
                            onTap: () => _mostrarDetalles(context),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _IconoAccion(
                            icon: _dioLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _dioLike ? Colors.red : textColor.withOpacity(0.7),
                            label: '$_likesCount',
                            onTap: _toggleLike,
                            textColor: textColor,
                          ),
                          const SizedBox(width: 16),
                          _IconoAccion(
                            icon: Icons.chat_bubble_outline_rounded,
                            color: textColor.withOpacity(0.7),
                            label: '${widget.post.comentariosCount}',
                            onTap: () => _mostrarDetalles(context),
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconoAccion extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const _IconoAccion({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
