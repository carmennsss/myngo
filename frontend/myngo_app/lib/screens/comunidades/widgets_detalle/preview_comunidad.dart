import 'package:flutter/material.dart';
import '../../../models/comunidad.dart';
import '../../../models/publicacion.dart';
import '../../../models/coleccion.dart';
import './header_detalle_comunidad.dart';
import './seccion_posts_comunidad.dart';
import '../widgets_preview/preview_about_section.dart';
import '../widgets_preview/community_join_button.dart';
import '../widgets_preview/preview_header.dart';

/// Vista para usuarios que no son miembros de la comunidad.
/// Muestra información básica y contenido público limitado.
class PreviewComunidad extends StatelessWidget {
  final Comunidad comunidad;
  final int? miId;
  final int indiceSeccion;
  final List<Publicacion>? publicaciones;
  final List<Coleccion>? colecciones;
  final bool estaCargandoDatos;
  final bool estaCargandoPeticion;
  final Function(int) onTabChanged;
  final VoidCallback onJoin;
  final VoidCallback onBack;
  final Widget backgroundFeed;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;

  const PreviewComunidad({
    super.key,
    required this.comunidad,
    required this.miId,
    required this.indiceSeccion,
    required this.publicaciones,
    required this.colecciones,
    required this.estaCargandoDatos,
    required this.estaCargandoPeticion,
    required this.onTabChanged,
    required this.onJoin,
    required this.onBack,
    required this.backgroundFeed,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
  });

  @override
  Widget build(BuildContext context) {
    if (comunidad.esPublica) {
      return Stack(
        children: [
          Positioned.fill(child: backgroundFeed),
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: false,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: HeaderDetalleComunidad(
                      comunidad: comunidad,
                      miId: miId,
                      onCerrar: onBack,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PersistentTabDelegate(
                    child: _buildPreviewTabs(context),
                  ),
                ),
              ];
            },
            body: SingleChildScrollView(
              child: Column(
                children: [
                  indiceSeccion == 0
                      ? SeccionPostsComunidad(
                          publicaciones: publicaciones,
                          estaCargando: estaCargandoDatos,
                          onRefresh: () async {}, // No refresh in preview
                          esAppClara: esAppClara,
                        )
                      : _buildPreviewGallery(context),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: PreviewAboutSection(
                      comunidad: comunidad,
                      esAppClara: esAppClara,
                      colorTextoPrincipal: colorTextoPrincipal,
                      colorTextoSecundario: colorTextoSecundario,
                      bgColor: comunidad.colorTema,
                    ),
                  ),
                  CommunityJoinButton(
                    comunidad: comunidad,
                    miId: miId,
                    estaCargandoPeticion: estaCargandoPeticion,
                    onLogin: () => Navigator.pushNamed(context, '/login'),
                    onJoin: onJoin,
                    isPreview: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Comunidades privadas
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: HeaderDetalleComunidad(
              comunidad: comunidad,
              miId: miId,
              onCerrar: onBack,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                PreviewHeader(
                  comunidad: comunidad,
                  esAppClara: esAppClara,
                  colorTextoPrincipal: colorTextoPrincipal,
                  colorTextoSecundario: colorTextoSecundario,
                ),
                const Divider(height: 48),
                PreviewAboutSection(
                  comunidad: comunidad,
                  esAppClara: esAppClara,
                  colorTextoPrincipal: colorTextoPrincipal,
                  colorTextoSecundario: colorTextoSecundario,
                  bgColor: comunidad.colorTema,
                ),
                CommunityJoinButton(
                  comunidad: comunidad,
                  miId: miId,
                  estaCargandoPeticion: estaCargandoPeticion,
                  onLogin: () => Navigator.pushNamed(context, '/login'),
                  onJoin: onJoin,
                  isPreview: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: comunidad.colorTema.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'POSTS', Icons.grid_view_rounded),
          _buildTabItem(2, 'GALERÍA', Icons.photo_library_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final activo = indiceSeccion == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activo ? comunidad.colorTema : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: activo ? comunidad.colorTema : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: activo ? comunidad.colorTema : Colors.grey,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewGallery(BuildContext context) {
    // Implementación simplificada o reutilización parcial de SeccionGaleria
    return const Center(child: Text('Galería Pública'));
  }
}

class _PersistentTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PersistentTabDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
