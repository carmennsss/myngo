import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../../../utils/estilo_post_helper.dart';

/// Widget que muestra las publicaciones guardadas por el usuario con filtros.
class SeccionGuardadosPerfil extends StatelessWidget {
  final List<Publicacion>? publicaciones;
  final bool estaCargando;
  final List<Map<String, dynamic>> comunidadesFiltro;
  final int? filtroComunidadId;
  final Function(int?) onFiltroChanged;
  final VoidCallback onRefresh;

  const SeccionGuardadosPerfil({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    required this.comunidadesFiltro,
    this.filtroComunidadId,
    required this.onFiltroChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || publicaciones == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: publicaciones!.isEmpty
              ? const EstadoVacioCargando(
                  icon: Icons.bookmark_border_rounded,
                  message: 'No tienes publicaciones guardadas en esta sección.',
                )
              : MasonryGridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: publicaciones!.length,
                  itemBuilder: (context, index) {
                    final post = publicaciones![index];
                    return _TarjetaPostGuardado(post: post, onUpdate: onRefresh);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    if (comunidadesFiltro.isEmpty) return const SizedBox();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Todos',
            selected: filtroComunidadId == null,
            onSelected: () => onFiltroChanged(null),
          ),
          ...comunidadesFiltro.map((c) => _FilterChip(
                label: c['nombre'],
                selected: filtroComunidadId == c['id'],
                onSelected: () => onFiltroChanged(c['id']),
              )),
        ],
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
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white.withOpacity(0.05),
        selectedColor: const Color(0xFF248EA6).withOpacity(0.3),
        checkmarkColor: const Color(0xFF248EA6),
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
    final style = EstiloPostHelper.getEstilo(post.estiloId);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DetallePublicacionSheet(
            publicacion: post,
            onInteraction: onUpdate,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: style.backgroundColor ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: style.borderColor ?? Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (post.imagenes.isNotEmpty)
              Image.network(post.imagenes.first, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.contenido,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: style.textColor ?? Colors.white.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
