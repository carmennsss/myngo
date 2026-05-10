import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../../../utils/estilo_post_helper.dart';
import 'package:myngo_app/widgets/comunes/miniatura_video.dart';

/// Widget que muestra la grilla de publicaciones de un usuario.
class SeccionPostsPerfil extends StatefulWidget {
  final List<Publicacion>? publicaciones;
  final bool estaCargando;
  final bool esPrivado;
  final String? fuentePerfil;
  final String? colorTema;
  final VoidCallback onRefresh;
  final Future<List<Publicacion>> Function(int) onLoadMore;

  const SeccionPostsPerfil({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    this.esPrivado = false,
    this.fuentePerfil,
    this.colorTema,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  State<SeccionPostsPerfil> createState() => _SeccionPostsPerfilState();
}

class _SeccionPostsPerfilState extends State<SeccionPostsPerfil> {
  bool _estaCargandoMas = false;
  bool _hayMasPosts = true;
  int _paginaActual = 1;
  late List<Publicacion> _posts;

  @override
  void initState() {
    super.initState();
    _posts = widget.publicaciones ?? [];
  }

  @override
  void didUpdateWidget(covariant SeccionPostsPerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.publicaciones != oldWidget.publicaciones) {
      _limpiarYAsignarPosts(widget.publicaciones ?? []);
      _paginaActual = 1;
      _hayMasPosts = true;
    }
  }

  void _limpiarYAsignarPosts(List<Publicacion> source) {
    final ids = <int>{};
    _posts = [];
    for (var p in source) {
      if (ids.add(p.id)) {
        _posts.add(p);
      }
    }
  }


  Future<void> _cargarMasPosts() async {
    setState(() => _estaCargandoMas = true);
    _paginaActual++;
    try {
      final nuevos = await widget.onLoadMore(_paginaActual);
      if (mounted) {
        setState(() {
          _estaCargandoMas = false;
          if (nuevos.isEmpty) {
            _hayMasPosts = false;
          } else {
            final idsExistentes = _posts.map((p) => p.id).toSet();
            for (var n in nuevos) {
              if (idsExistentes.add(n.id)) {
                _posts.add(n);
              }
            }
          }
        });
      }
    } catch (e) {
      setState(() => _estaCargandoMas = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.esPrivado) {
      return const EstadoVacioCargando(
        icon: Icons.lock_rounded,
        message: 'Esta cuenta es privada.\nSigue al usuario para ver sus miau-posts.',
      );
    }

    if (widget.estaCargando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    if (_posts.isEmpty) {
      return const EstadoVacioCargando(
        icon: Icons.grid_view_rounded,
        message: 'Aún no hay publicaciones compartidas.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Columnas adaptadas para evitar que los posts se vean demasiado grandes
        int columnas = 2;
        if (constraints.maxWidth > 1200) {
          columnas = 4;
        } else if (constraints.maxWidth > 800) {
          columnas = 3;
        }
        
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400), // Aumentamos un poco el límite para pantallas ultra-anchas
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 400) {
                    if (!widget.estaCargando && !_estaCargandoMas && _hayMasPosts) {
                      _cargarMasPosts();
                    }
                  }
                }
                return false;
              },
              child: MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                crossAxisCount: columnas,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                itemCount: _posts.length + (_estaCargandoMas ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
                  }
                  final post = _posts[index];
                  return _TarjetaPostPerfil(post: post, onUpdate: widget.onRefresh, fuentePerfil: widget.fuentePerfil, colorTema: widget.colorTema);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaPostPerfil extends StatelessWidget {
  final Publicacion post;
  final VoidCallback onUpdate;
  final String? fuentePerfil;
  final String? colorTema;

  const _TarjetaPostPerfil({required this.post, required this.onUpdate, this.fuentePerfil, this.colorTema});

  @override
  Widget build(BuildContext context) {
    final esFondoClaro = EstiloPostHelper.esFondoClaro(post.autorEstiloPost);
    final colorTexto = esFondoClaro ? Colors.black87 : Colors.white.withOpacity(0.9);

    return GestureDetector(
      onTap: () {
        DetallePublicacionSheet.mostrar(
          context,
          publicacion: post,
          avatarUrl: post.autorFoto ?? '',
          onEliminado: onUpdate,
          fuente: fuentePerfil,
        );
      },
      child: Container(
        decoration: EstiloPostHelper.buildDecoracion(
          post.autorEstiloPost,
          borderRadius: BorderRadius.circular(24),
          borderWidth: 1.2,
        ).copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.media.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 120, maxHeight: 280),
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.03),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: post.media.first['tipo'] == 'V'
                          ? MiniaturaVideo(url: post.media.first['url'] ?? '')
                          : CachedNetworkImage(
                              imageUrl: post.media.first['url'] ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: Colors.black.withOpacity(0.05),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50))),
                              ),
                              errorWidget: (context, url, error) => const SizedBox(
                                height: 120,
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey)
                              ),
                            ),
                    ),
                  ),
                  if (post.media.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.contenidoTexto.isNotEmpty)
                    Text(
                      post.contenidoTexto,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.getFont(
                        fuentePerfil ?? 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorTexto,
                        height: 1.4,
                      ),
                    ),
                  if (post.comunidadNombre != 'General')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.pets_rounded, size: 10, color: EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFF248EA6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.comunidadNombre,
                              style: GoogleFonts.getFont(
                                  fuentePerfil ?? 'Outfit',
                                  fontSize: 10,
                                  color: EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFF248EA6),
                                  fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
