import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/coleccion.dart';
import '../../models/usuario.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_interaccion.dart';
import '../../services/servicio_usuarios.dart';
import '../comunes/menu_opciones_contenido.dart';
import 'dialogo_detalle_post.dart';
import '../comunes/grid_imagenes_post.dart';
import '../comunes/bottom_sheet_colecciones.dart';
import '../../utils/estilo_post_helper.dart';

/// Tarjeta de publicación del feed de inicio.
class TarjetaPost extends StatefulWidget {
  final Publicacion post;
  final VoidCallback onJoin;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;
  final VoidCallback? onEliminado;
  final bool estaEnComunidad;

  const TarjetaPost({
    super.key, 
    required this.post, 
    required this.onJoin, 
    this.onComunidadSelected, 
    this.onProfileSelected,
    this.onEliminado,
    this.estaEnComunidad = false,
  });

  @override
  State<TarjetaPost> createState() => _TarjetaPostState();
}

class _TarjetaPostState extends State<TarjetaPost> {
  bool _estaLogueado = false;
  bool _estaGuardadoLocal = false;
  late bool _dioLike;
  late int _likesCount;
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();

  @override
  void initState() {
    super.initState();
    _estaGuardadoLocal = widget.post.usuarioGuardoPost;
    _dioLike = widget.post.usuarioDioLike;
    _likesCount = widget.post.likesCount;
    _checkLogin();
  }

  @override
  void didUpdateWidget(TarjetaPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.usuarioGuardoPost != widget.post.usuarioGuardoPost) {
      _estaGuardadoLocal = widget.post.usuarioGuardoPost;
    }
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _estaLogueado = prefs.getString('auth_token') != null);
  }

  Future<void> _toggleLike() async {
    final token = await _servicioUsuarios.obtenerToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inicia sesión para dar like 🐾', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFC35E34),
          ),
        );
      }
      return;
    }
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
    }
  }

  void _mostrarDetalles(BuildContext context) {
    if (widget.estaEnComunidad) {
      context.go('/inicio/comunidades/${widget.post.comunidadId}/post/${widget.post.id}', extra: widget.post);
    } else {
      showDialog(
        context: context,
        builder: (context) => DialogoDetallePublicacion(
          post: widget.post,
          onComunidadSelected: widget.onComunidadSelected,
          onProfileSelected: widget.onProfileSelected,
        ),
      );
    }
  }

  void _mostrarMenuGuardado() async {
    if (!_estaLogueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inicia sesión para guardar contenido 🐾', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFC35E34),
          action: SnackBarAction(label: 'ENTRAR', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/login')),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetColecciones(
        postId: widget.post.id,
        estaGuardadoPost: _estaGuardadoLocal,
        imagenId: widget.post.imagenId,
        imagenUrl: widget.post.urlImagen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estilo = widget.post.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final textColor = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
    final subTextColor = esFondoClaro ? Colors.grey.shade600 : Colors.white70;
    final actionColor = esFondoClaro ? Colors.grey.shade600 : Colors.white60;

    return Material(
      color: Colors.transparent,
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
                                Text.rich(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(Icons.chat_bubble_outline_rounded, widget.post.comentariosCount.toString(), actionColor, () => _mostrarDetalles(context)),
                          _buildActionButton(
                            _dioLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            _likesCount.toString(),
                            _dioLike ? const Color(0xFFE0245E) : actionColor,
                            _toggleLike,
                          ),
                          _buildActionButton(
                            _estaGuardadoLocal ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                            '', 
                            _estaGuardadoLocal ? const Color(0xFFF28B50) : actionColor, 
                            _mostrarMenuGuardado
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

  Widget _buildActionButton(IconData icon, String text, Color actionColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: actionColor),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(text, style: GoogleFonts.outfit(fontSize: 13, color: actionColor, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}
