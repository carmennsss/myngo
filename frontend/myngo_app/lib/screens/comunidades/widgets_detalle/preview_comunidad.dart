import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/comunidad.dart';
import '../../../models/publicacion.dart';
import '../../../models/coleccion.dart';
import './header_detalle_comunidad.dart';
import './seccion_posts_comunidad.dart';
import '../widgets_preview/preview_about_section.dart';
import '../widgets_preview/community_join_button.dart';
import '../widgets_preview/preview_header.dart';
import '../../../widgets/galeria/masonry_grid_galeria.dart';

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
    final urlFondo = comunidad.urlFondo;
    
    final content = Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Cabecera Principal (Expandible)
            SliverAppBar(
              expandedHeight: 180,
              pinned: false,
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

            // Selector de Pestañas (Sticky)
            SliverAppBar(
              pinned: true,
              toolbarHeight: 60,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: _buildPreviewTabs(context),
            ),

            // Contenido según pestaña
            if (indiceSeccion == 0)
              SeccionPostsComunidad(
                key: ValueKey('posts_${publicaciones?.length}'),
                publicaciones: publicaciones,
                estaCargando: estaCargandoDatos,
                onRefresh: () async {},
                esAppClara: esAppClara,
                comoSliver: true,
              )
            else
              SliverToBoxAdapter(child: _buildPreviewGallery(context)),

            // Espacio al final para que la tarjeta flotante no tape el último post
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),

        // Pie de página flotante con botón de unión (Sticky)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Te gusta lo que ves?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorTextoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 12),
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
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: esAppClara ? Colors.white : const Color(0xFF121212),
        image: (urlFondo != null && urlFondo.isNotEmpty)
            ? DecorationImage(
                image: CachedNetworkImageProvider(urlFondo),
                fit: BoxFit.cover,
                opacity: 0.15,
              )
            : null,
      ),
      child: content,
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
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: activo ? comunidad.colorTema.withOpacity(0.05) : Colors.transparent,
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
    return SizedBox(
      height: 600, // Altura fija para el preview
      child: MasonryGridGaleria(
        comunidadId: comunidad.id,
        esMiembro: false,
      ),
    );
  }
}
