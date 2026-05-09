import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../../../utils/estilo_post_helper.dart';
import 'package:myngo_app/widgets/comunes/miniatura_video.dart';
import 'seccion_colecciones_perfil.dart';
import '../../../models/coleccion.dart';

/// Widget que muestra las publicaciones guardadas y las colecciones del usuario.
class SeccionGuardadosPerfil extends StatefulWidget {
  final List<Publicacion>? publicaciones;
  final List<Coleccion>? colecciones;
  final bool estaCargando;
  final bool estaCargandoColecciones;
  final List<Map<String, dynamic>> comunidadesFiltro;
  final int? filtroComunidadId;
  final Function(int?) onFiltroChanged;
  final String? fuentePerfil;
  final String? colorTema;
  final VoidCallback onRefresh;
  final VoidCallback onRefreshColecciones;
  final Future<List<Publicacion>> Function(int) onLoadMore;

  const SeccionGuardadosPerfil({
    super.key,
    required this.publicaciones,
    required this.colecciones,
    required this.estaCargando,
    required this.estaCargandoColecciones,
    required this.comunidadesFiltro,
    this.filtroComunidadId,
    this.fuentePerfil,
    this.colorTema,
    required this.onFiltroChanged,
    required this.onRefresh,
    required this.onRefreshColecciones,
    required this.onLoadMore,
  });

  @override
  State<SeccionGuardadosPerfil> createState() => _SeccionGuardadosPerfilState();
}

class _SeccionGuardadosPerfilState extends State<SeccionGuardadosPerfil> {
  bool _mostrarCarpetas = false;
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
  void didUpdateWidget(covariant SeccionGuardadosPerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.publicaciones != oldWidget.publicaciones) {
      _posts = widget.publicaciones ?? [];
      _paginaActual = 1;
      _hayMasPosts = true;
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
    if (widget.estaCargando || widget.publicaciones == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    return Column(
      children: [
        _buildToggle(),
        if (!_mostrarCarpetas) _buildFilters(),
        Expanded(
          child: _mostrarCarpetas ? _buildCarpetas() : _buildPosts(),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'Publicaciones',
                selected: !_mostrarCarpetas,
                colorTema: widget.colorTema,
                onTap: () => setState(() => _mostrarCarpetas = false),
              ),
            ),
            Expanded(
              child: _ToggleButton(
                label: 'Carpetas',
                selected: _mostrarCarpetas,
                colorTema: widget.colorTema,
                onTap: () => setState(() => _mostrarCarpetas = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosts() {
    if (widget.publicaciones!.isEmpty) {
      return const EstadoVacioCargando(
        icon: Icons.bookmark_border_rounded,
        message: 'No tienes publicaciones guardadas en esta sección.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lógica de columnas consistente para evitar que los posts se vean "gigantes"
        int columnas = 2;
        if (constraints.maxWidth > 1200) {
          columnas = 4;
        } else if (constraints.maxWidth > 800) {
          columnas = 3;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
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
                  return _TarjetaPostGuardado(post: post, onUpdate: widget.onRefresh, fuentePerfil: widget.fuentePerfil, colorTema: widget.colorTema);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarpetas() {
    return SeccionColeccionesPerfil(
      colecciones: widget.colecciones,
      estaCargando: widget.estaCargandoColecciones,
      onRefresh: widget.onRefreshColecciones,
      esPropietario: true,
      fuentePerfil: widget.fuentePerfil,
    );
  }

  Widget _buildFilters() {
    if (widget.comunidadesFiltro.isEmpty) return const SizedBox();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Todos',
            selected: widget.filtroComunidadId == null,
            colorTema: widget.colorTema,
            onSelected: () => widget.onFiltroChanged(null),
          ),
          ...widget.comunidadesFiltro.map((c) => _FilterChip(
                label: c['nombre'],
                selected: widget.filtroComunidadId == c['id'],
                colorTema: widget.colorTema,
                onSelected: () => widget.onFiltroChanged(c['id']),
              )),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final String? colorTema;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    this.colorTema,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? (EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFFF28B50)) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}



class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? colorTema;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.colorTema,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white.withOpacity(0.05),
        selectedColor: (EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFF248EA6)).withOpacity(0.3),
        checkmarkColor: EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFF248EA6),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _TarjetaPostGuardado extends StatelessWidget {
  final Publicacion post;
  final VoidCallback onUpdate;
  final String? fuentePerfil;
  final String? colorTema;

  const _TarjetaPostGuardado({required this.post, required this.onUpdate, this.fuentePerfil, this.colorTema});

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
                    constraints: const BoxConstraints(minHeight: 120, maxHeight: 400),
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.03),
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
                  if (post.media.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: Colors.white,
                          size: 12,
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.pets_rounded, size: 8, color: EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFF248EA6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.comunidadNombre,
                              style: GoogleFonts.getFont(
                                  fuentePerfil ?? 'Outfit',
                                  fontSize: 9,
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
