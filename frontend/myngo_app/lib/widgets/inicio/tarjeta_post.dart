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
import '../comunes/hover_profile_card.dart';
import '../comunes/bottom_sheet_colecciones.dart';
import '../dialogo_crear_post.dart';
import '../../utils/estilo_post_helper.dart';
import '../../services/servicio_comunidades.dart';

class TarjetaPost extends StatefulWidget {
  final Publicacion post;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;
  final VoidCallback? onJoin;
  final bool estaEnComunidad;
  final VoidCallback? onEliminado;
  final String? fuente;

  const TarjetaPost({
    super.key,
    required this.post,
    this.onComunidadSelected,
    this.onProfileSelected,
    this.onJoin,
    this.estaEnComunidad = false,
    this.onEliminado,
    this.fuente,
  });

  @override
  State<TarjetaPost> createState() => _TarjetaPostState();
}

class _TarjetaPostState extends State<TarjetaPost> {
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  late bool _dioLike;
  late int _likesCount;
  late bool _estaGuardado;

  @override
  void initState() {
    super.initState();
    _dioLike = widget.post.usuarioDioLike;
    _likesCount = widget.post.likesCount;
    _estaGuardado = widget.post.usuarioGuardoPost;
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DialogoDetallePublicacion(post: widget.post),
    ).then((_) {
      if (mounted) {
        setState(() {
          _dioLike = widget.post.usuarioDioLike;
          _likesCount = widget.post.likesCount;
          _estaGuardado = widget.post.usuarioGuardoPost;
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    setState(() {
      _dioLike = !_dioLike;
      _likesCount += _dioLike ? 1 : -1;
      widget.post.usuarioDioLike = _dioLike;
      widget.post.likesCount = _likesCount;
    });

    final res = await _servicioInteraccion.alternarMeGusta(widget.post.id);
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

  Future<void> _toggleGuardado() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetColecciones(
        postId: widget.post.id,
        estaGuardadoPost: _estaGuardado,
        imagenId: widget.post.imagenId,
        imagenUrl: widget.post.urlImagen,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _estaGuardado = widget.post.usuarioGuardoPost;
        });
      }
    });
  }

  void _mostrarDialogoEdicion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearPost(
        titulo: 'Editar Miau-post 🐾',
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
                HoverProfileCard(
                  nombre: widget.post.autorNombre,
                  avatarUrl: widget.post.autorFoto,
                  marcoUrl: widget.post.autorMarco,
                  fondoUrl: widget.post.autorFondo,
                  puntos: 0,
                  estado: widget.post.autorEstado ?? 'DESCONECTADO',
                  userId: widget.post.autorId,
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
                        urlAvatar: widget.post.autorFoto,
                        marco: widget.post.autorMarco,
                        fondo: widget.post.autorFondo,
                      ));
                    } else {
                      context.go('/inicio/perfiles/${widget.post.autorNombre}');
                    }
                  },
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Avatar (Debajo)
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: (widget.post.autorFoto != null && widget.post.autorFoto!.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.post.autorFoto!,
                                    fit: BoxFit.cover,
                                    width: 30,
                                    height: 30,
                                    errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey, size: 18),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    widget.post.autorNombre.isNotEmpty ? widget.post.autorNombre[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                        ),
                        // 2. Marco (Encima)
                        if (widget.post.autorMarco != null && widget.post.autorMarco!.isNotEmpty)
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: widget.post.autorMarco!,
                              fit: BoxFit.contain,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
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
                                  child: Text(widget.post.comunidadNombre, style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                                ),
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
                      context.go('/inicio/perfiles/${widget.post.autorNombre}');
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
                                    style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', fontSize: 13),
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
                            onEditado: _mostrarDialogoEdicion,
                            tituloPreview: widget.post.titulo,
                            iconColor: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.post.titulo.isNotEmpty)
                        Text(widget.post.titulo, style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: textColor, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                      if (widget.post.contenidoTexto.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.post.contenidoTexto,
                          style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: subTextColor, fontSize: 15),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.post.contenidoTexto.length > 100)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Leer más...',
                              style: GoogleFonts.getFont(widget.fuente ?? 'Outfit',
                                color: esFondoClaro ? const Color(0xFFC35E34) : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                      if (widget.post.media.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GridImagenesPost(
                            media: widget.post.media,
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
                            fuente: widget.fuente,
                          ),
                          const SizedBox(width: 16),
                          _IconoAccion(
                            icon: Icons.chat_bubble_outline_rounded,
                            color: textColor.withOpacity(0.7),
                            label: '${widget.post.comentariosCount}',
                            onTap: () => _mostrarDetalles(context),
                            textColor: textColor,
                            fuente: widget.fuente,
                          ),
                          const Spacer(),
                          _IconoAccion(
                            icon: _estaGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: _estaGuardado ? const Color(0xFF248EA6) : textColor.withOpacity(0.7),
                            label: '',
                            onTap: _toggleGuardado,
                            textColor: textColor,
                            fuente: widget.fuente,
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

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Colors.greenAccent;
      case 'OCUPADO':
        return Colors.redAccent;
      case 'DESCONECTADO':
      default:
        return Colors.grey.shade400;
    }
  }
}

class _IconoAccion extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final String? fuente;

  const _IconoAccion({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.textColor,
    this.fuente,
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
            Text(label, style: GoogleFonts.getFont(fuente ?? 'Outfit', color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
