import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../../../utils/estilo_post_helper.dart';
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
  final VoidCallback onRefresh;
  final VoidCallback onRefreshColecciones;

  const SeccionGuardadosPerfil({
    super.key,
    required this.publicaciones,
    required this.colecciones,
    required this.estaCargando,
    required this.estaCargandoColecciones,
    required this.comunidadesFiltro,
    this.filtroComunidadId,
    required this.onFiltroChanged,
    required this.onRefresh,
    required this.onRefreshColecciones,
  });

  @override
  State<SeccionGuardadosPerfil> createState() => _SeccionGuardadosPerfilState();
}

class _SeccionGuardadosPerfilState extends State<SeccionGuardadosPerfil> {
  bool _mostrarCarpetas = false;

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
                onTap: () => setState(() => _mostrarCarpetas = false),
              ),
            ),
            Expanded(
              child: _ToggleButton(
                label: 'Carpetas',
                selected: _mostrarCarpetas,
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
    return MasonryGridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: widget.publicaciones!.length,
      itemBuilder: (context, index) {
        final post = widget.publicaciones![index];
        return _TarjetaPostGuardado(post: post, onUpdate: widget.onRefresh);
      },
    );
  }

  Widget _buildCarpetas() {
    return SeccionColeccionesPerfil(
      colecciones: widget.colecciones,
      estaCargando: widget.estaCargandoColecciones,
      onRefresh: widget.onRefreshColecciones,
      esPropietario: true,
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
            onSelected: () => widget.onFiltroChanged(null),
          ),
          ...widget.comunidadesFiltro.map((c) => _FilterChip(
                label: c['nombre'],
                selected: widget.filtroComunidadId == c['id'],
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
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF28B50) : Colors.transparent,
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
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
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
        selectedColor: const Color(0xFF248EA6).withOpacity(0.3),
        checkmarkColor: const Color(0xFF248EA6),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _TarjetaPostGuardado extends StatelessWidget {
  final Publicacion post;
  final VoidCallback onUpdate;

  const _TarjetaPostGuardado({required this.post, required this.onUpdate});

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
          borderRadius: BorderRadius.circular(12),
          borderWidth: 1.0,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.urlsImagenes.isNotEmpty)
              Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.03),
                    child: CachedNetworkImage(
                      imageUrl: post.urlsImagenes.first,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.black.withOpacity(0.05),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50))),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                  if (post.urlsImagenes.length > 1)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.contenidoTexto.isNotEmpty)
                    Text(
                      post.contenidoTexto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorTexto),
                    ),
                  if (post.comunidadNombre != 'General')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        post.comunidadNombre,
                        style: GoogleFonts.inter(
                            fontSize: 8,
                            color: const Color(0xFF248EA6),
                            fontWeight: FontWeight.bold),
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
