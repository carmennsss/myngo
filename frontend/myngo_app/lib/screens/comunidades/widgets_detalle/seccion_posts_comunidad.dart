import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/publicacion.dart';
import '../../../widgets/inicio/tarjeta_post.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';

/// Widget que muestra el feed de publicaciones de una comunidad.
class SeccionPostsComunidad extends StatelessWidget {
  final List<Publicacion>? publicaciones;
  final bool estaCargando;
  final Future<void> Function() onRefresh;
  final bool esAppClara;
  final bool comoSliver;

  const SeccionPostsComunidad({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    required this.onRefresh,
    required this.esAppClara,
    this.comoSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || publicaciones == null) {
      final loading = const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFFF28B50)),
          ));
      return comoSliver ? SliverFillRemaining(child: loading) : loading;
    }

    if (publicaciones!.isEmpty) {
      final empty = const EstadoVacioCargando(
        icon: Icons.feed_outlined,
        message: 'Aún no hay publicaciones',
      );
      return comoSliver ? SliverFillRemaining(child: empty) : empty;
    }

    if (comoSliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPostItem(publicaciones![index]),
            childCount: publicaciones!.length,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        itemCount: publicaciones!.length,
        itemBuilder: (context, index) => _buildPostItem(publicaciones![index]),
      ),
    );
  }

  Widget _buildPostItem(Publicacion post) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: TarjetaPost(
            post: post,
            onJoin: () {}, 
            onEliminado: onRefresh,
            estaEnComunidad: true,
          ),
        ),
      ),
    );
  }
}
