import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/publicacion.dart';
import '../../models/comentario.dart';
import '../../services/servicio_interaccion.dart';
import '../../services/servicio_usuarios.dart';
import '../../widgets/inicio/dialogo_detalle_post.dart';
import '../../widgets/comunes/comentario_item.dart';
import '../../widgets/comunes/grid_imagenes_post.dart';

class PantallaDetallePost extends StatefulWidget {
  final Publicacion post;

  const PantallaDetallePost({super.key, required this.post});

  @override
  State<PantallaDetallePost> createState() => _PantallaDetallePostState();
}

class _PantallaDetallePostState extends State<PantallaDetallePost> {
  final TextEditingController _comentarioController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();
  
  List<Comentario> _comentarios = [];
  bool _cargandoComentarios = true;
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

  String _formatFecha(DateTime fecha) {
    return DateFormat('h:mm a · d MMM. yyyy', 'es_ES').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final Color colorComunidad = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publicación',
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'en ${widget.post.comunidadNombre}',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
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
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '@${widget.post.autorNombre.toLowerCase().replaceAll(' ', '')}',
                                  style: GoogleFonts.outfit(
                                    color: colorComunidad,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz),
                            onPressed: () {}, 
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.post.titulo.isNotEmpty) ...[
                        Text(
                          widget.post.titulo,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        widget.post.contenidoTexto,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      if (widget.post.urlsImagenes.isNotEmpty || widget.post.urlImagen != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 500),
                            child: GridImagenesPost(
                              urls: widget.post.urlsImagenes.isNotEmpty ? widget.post.urlsImagenes : [widget.post.urlImagen!],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        _formatFecha(widget.post.fechaCreacion),
                        style: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 32),
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
                            onTap: () {},
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
                const Divider(height: 1),
                if (_cargandoComentarios)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ))
                else if (_comentarios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('Sin comentarios todavía', style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comentarios.length,
                    itemBuilder: (context, index) => ComentarioItem(comentario: _comentarios[index]),
                  ),
              ],
            ),
          ),
          _buildInputResponder(),
        ],
      ),
    );
  }

  Widget _buildInputResponder() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 8, 
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 18, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _comentarioController,
              decoration: InputDecoration(
                hintText: 'Postea tu respuesta',
                hintStyle: GoogleFonts.outfit(fontSize: 14),
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          if (_enviandoComentario)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton(
              onPressed: _enviandoComentario ? null : _enviarComentario,
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
            Icon(icon, color: color, size: 22),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
