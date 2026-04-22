import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../models/comentario.dart';
import '../../services/servicio_interaccion.dart';
import '../../services/servicio_usuarios.dart';
import '../comunes/comentario_item.dart';
import '../comunes/grid_imagenes_post.dart';

class DialogoDetallePublicacion extends StatefulWidget {
  final Publicacion post;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;

  const DialogoDetallePublicacion({
    super.key,
    required this.post,
    this.onComunidadSelected,
    this.onProfileSelected,
  });

  @override
  State<DialogoDetallePublicacion> createState() => _DialogoDetallePublicacionState();
}

class _DialogoDetallePublicacionState extends State<DialogoDetallePublicacion> {
  final TextEditingController _comentarioController = TextEditingController();
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();
  
  List<Comentario> _comentarios = [];
  bool _cargandoComentarios = true;
  bool _mostrandoInputComentario = false;
  bool _enviandoComentario = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _userId = await _servicioUsuarios.obtenerIdUsuario();
    await _cargarComentarios();
  }

  Future<void> _cargarComentarios() async {
    if (!mounted) return;
    setState(() => _cargandoComentarios = true);
    final respuesta = await _servicioInteraccion.obtenerComentarios(widget.post.id);
    if (respuesta.exito) {
      if (mounted) {
        setState(() {
          _comentarios = respuesta.datos ?? [];
          _cargandoComentarios = false;
        });
      }
    } else {
      if (mounted) setState(() => _cargandoComentarios = false);
    }
  }

  Future<void> _enviarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    setState(() => _enviandoComentario = true);
    final respuesta = await _servicioInteraccion.crearComentario(
      widget.post.id,
      _comentarioController.text.trim(),
    );

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        _comentarios.insert(0, respuesta.datos!);
        _comentarioController.clear();
        _mostrandoInputComentario = false;
        _enviandoComentario = false;
      });
    } else {
      setState(() => _enviandoComentario = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(respuesta.mensaje)),
        );
      }
    }
  }

  String _formatRelativeDate(DateTime fecha) {
    try {
      final now = DateTime.now();
      final diff = now.difference(fecha);

      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('d MMM', 'es_ES').format(fecha);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                        'Publicación',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/inicio/comunidades/${widget.post.comunidadId}');
                        },
                        label: Text('Ver comunidad', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)),
                        icon: const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFC35E34)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: widget.post.autorFoto != null
                                    ? CachedNetworkImageProvider(widget.post.autorFoto!)
                                    : null,
                                child: widget.post.autorFoto == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.post.autorNombre,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '@${widget.post.autorNombre.toLowerCase().replaceAll(' ', '')} · ${_formatRelativeDate(widget.post.fechaCreacion)}',
                                      style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
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
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            widget.post.contenidoTexto,
                            style: GoogleFonts.outfit(fontSize: 16, height: 1.4),
                          ),
                          if (widget.post.urlsImagenes.isNotEmpty || widget.post.urlImagen != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 400),
                                child: GridImagenesPost(
                                  urls: widget.post.urlsImagenes.isNotEmpty ? widget.post.urlsImagenes : [widget.post.urlImagen!],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ActionIcon(
                                icon: widget.post.usuarioDioLike ? Icons.favorite : Icons.favorite_border,
                                color: widget.post.usuarioDioLike ? Colors.red : Colors.grey.shade600,
                                label: widget.post.likesCount.toString(),
                                onTap: () {}, 
                              ),
                              _ActionIcon(
                                icon: Icons.chat_bubble_outline,
                                color: Colors.grey.shade600,
                                label: widget.post.comentariosCount.toString(),
                                onTap: () {
                                  if (_userId != null) {
                                    setState(() => _mostrandoInputComentario = !_mostrandoInputComentario);
                                  }
                                },
                              ),
                              _ActionIcon(
                                icon: widget.post.usuarioGuardoPost ? Icons.bookmark : Icons.bookmark_border,
                                color: widget.post.usuarioGuardoPost ? Colors.orange : Colors.grey.shade600,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_mostrandoInputComentario)
                      _buildInputComentario(),
                    const Divider(height: 1),
                    if (_cargandoComentarios)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_comentarios.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Sin comentarios todavía',
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comentarios.length,
                        itemBuilder: (context, index) => ComentarioItem(
                          comentario: _comentarios[index],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputComentario() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _comentarioController,
              decoration: InputDecoration(
                hintText: 'Escribe tu respuesta...',
                hintStyle: GoogleFonts.outfit(fontSize: 14),
                isDense: true,
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
            ),
          ),
          _enviandoComentario
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: _enviarComentario,
                  child: Text(
                    'Responder',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34)),
                  ),
                ),
        ],
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
