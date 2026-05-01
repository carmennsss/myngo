import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final estilo = post.autorEstiloPost;
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final textColor = esFondoClaro ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DetallePublicacionSheet(
            publicacion: post,
            avatarUrl: post.autorFoto ?? '',
            onEliminado: onUpdate,
          ),
        );
      },
      child: Container(
        decoration: EstiloPostHelper.buildDecoracion(
          estilo,
          borderRadius: BorderRadius.circular(16),
          borderWidth: 1.5,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.urlsImagenes.isNotEmpty || post.urlImagen != null)
              Image.network(
                post.urlsImagenes.isNotEmpty ? post.urlsImagenes.first : post.urlImagen!,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.contenidoTexto,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: Color(0xFFF28B50), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        post.comunidadNombre,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: const Color(0xFF248EA6),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
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
