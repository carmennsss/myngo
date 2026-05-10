import 'package:flutter/material.dart' hide Scaffold;
import 'package:flutter/material.dart' as material show Scaffold;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/publicacion.dart';
import '../../services/servicio_comunidades.dart';
import '../../widgets/comunes/grid_imagenes_post.dart';
import '../../widgets/comunes/acciones_y_comentarios_post.dart';
import '../../utils/estilo_post_helper.dart';
import '../../widgets/comunes/hover_profile_card.dart';

class PantallaDetallePost extends StatefulWidget {
  final int? id;
  final Publicacion? post;
  final VoidCallback? onBack;

  const PantallaDetallePost({super.key, this.id, this.post, this.onBack})
      : assert(id != null || post != null, 'Debe proporcionarse id o post');

  @override
  State<PantallaDetallePost> createState() => _PantallaDetallePostState();
}

class _PantallaDetallePostState extends State<PantallaDetallePost> {
  Publicacion? _post;
  bool _estaCargandoPost = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null && widget.id != null) {
      _cargarPostInicial();
    }
  }

  @override
  void didUpdateWidget(PantallaDetallePost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.id ?? oldWidget.post?.id;
    final newId = widget.id ?? widget.post?.id;
    if (oldId != newId) {
      _post = widget.post;
      if (_post == null && widget.id != null) {
        _cargarPostInicial();
      }
    }
  }

  Future<void> _cargarPostInicial() async {
    if (!mounted) return;
    super.setState(() => _estaCargandoPost = true);
    final res = await ServicioComunidades().obtenerDetallePublicacion(widget.id!);
    if (mounted) {
      super.setState(() {
        _post = res.datos;
        _estaCargandoPost = false;
      });
    }
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('h:mm a · d MMM. yyyy', 'es_ES').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargandoPost || _post == null) {
      return material.Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: widget.onBack ?? () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFC35E34)),
              if (_estaCargandoPost) ...[
                const SizedBox(height: 16),
                const Text('Cargando publicación...'),
              ] else if (_post == null && !_estaCargandoPost) ...[
                const SizedBox(height: 16),
                const Text('Publicación no encontrada 😿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: widget.onBack ?? () => context.pop(), child: const Text('Volver'))
              ]
            ],
          ),
        ),
      );
    }

    final estilo = _post!.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final colorTexto = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
    final colorSubtexto = esFondoClaro ? Colors.grey.shade600 : Colors.white70;
    final bgColor = estilo != null ? EstiloPostHelper.effectiveBgColor(estilo) : Colors.white;
    final Color colorComunidad = Theme.of(context).primaryColor;

    return material.Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorTexto),
          onPressed: widget.onBack ?? () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publicación',
              style: GoogleFonts.outfit(
                color: colorTexto,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _post!.comunidadId > 0 ? 'en ${_post!.comunidadNombre}' : 'Publicación personal',
              style: GoogleFonts.outfit(
                color: colorSubtexto,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: EstiloPostHelper.buildDecoracion(
          estilo,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HoverProfileCard(
                          nombre: _post!.autorNombre,
                          avatarUrl: _post!.autorFoto,
                          marcoUrl: _post!.autorMarco,
                          fondoUrl: _post!.autorFondo ?? _post!.autorEstiloPost?['url_fondo'],
                          puntos: 0,
                          onTap: () => context.push('/inicio/perfiles/${_post!.autorId}'),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_post!.autorMarco != null && _post!.autorMarco!.isNotEmpty)
                                      Positioned.fill(
                                        child: CachedNetworkImage(
                                          imageUrl: _post!.autorMarco!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                                        backgroundImage: (_post!.autorFoto != null && _post!.autorFoto!.isNotEmpty)
                                            ? CachedNetworkImageProvider(_post!.autorFoto!)
                                            : null,
                                        child: (_post!.autorFoto == null || _post!.autorFoto!.isEmpty)
                                            ? Text(_post!.autorNombre.isNotEmpty ? _post!.autorNombre[0].toUpperCase() : '?',
                                                style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 18))
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _post!.autorNombre,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorTexto,
                                    ),
                                  ),
                                  Text(
                                    '@${_post!.autorNombre.toLowerCase().replaceAll(' ', '')}',
                                    style: GoogleFonts.outfit(
                                      color: esFondoClaro ? colorComunidad : colorSubtexto,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_post!.titulo.isNotEmpty) ...[
                          Text(
                            _post!.titulo,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          _post!.contenidoTexto,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            height: 1.4,
                            color: colorTexto,
                          ),
                        ),
                        if (_post!.media.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 500),
                              child: GridImagenesPost(
                                media: _post!.media,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          _formatFecha(_post!.fechaCreacion),
                          style: GoogleFonts.outfit(
                            color: colorSubtexto,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(height: 32),
                        const SizedBox(height: 16),
                        AccionesYComentariosPost(
                          post: _post!,
                          colorTexto: colorTexto,
                        ),
                      ],
                    ),
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
