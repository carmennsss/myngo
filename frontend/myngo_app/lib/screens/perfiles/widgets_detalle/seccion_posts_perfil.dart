import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../../../utils/estilo_post_helper.dart';

/// Widget que muestra la grilla de publicaciones de un usuario.
class SeccionPostsPerfil extends StatelessWidget {
  final List<Publicacion>? publicaciones;
  final bool estaCargando;
  final bool esPrivado;
  final VoidCallback onRefresh;

  const SeccionPostsPerfil({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    this.esPrivado = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (esPrivado) {
      return const EstadoVacioCargando(
        icon: Icons.lock_rounded,
        message: 'Esta cuenta es privada.\nSigue al usuario para ver sus miau-posts.',
      );
    }

    if (estaCargando || publicaciones == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    if (publicaciones!.isEmpty) {
      return const EstadoVacioCargando(
        icon: Icons.grid_view_rounded,
        message: 'Aún no hay publicaciones compartidas.',
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: publicaciones!.length,
      itemBuilder: (context, index) {
        final post = publicaciones![index];
        return _TarjetaPostPerfil(post: post, onUpdate: onRefresh);
      },
    );
  }
}

class _TarjetaPostPerfil extends StatelessWidget {
  final Publicacion post;
  final VoidCallback onUpdate;

  const _TarjetaPostPerfil({required this.post, required this.onUpdate});

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
                    constraints: const BoxConstraints(maxHeight: 200),
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
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.contenidoTexto.isNotEmpty)
                    Text(
                      post.contenidoTexto,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorTexto,
                      ),
                    ),
                  if (post.comunidadNombre != 'General')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        post.comunidadNombre,
                        style: GoogleFonts.inter(
                            fontSize: 9,
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
