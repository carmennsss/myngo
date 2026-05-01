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

  const SeccionPostsComunidad({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    required this.onRefresh,
    required this.esAppClara,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || publicaciones == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: publicaciones!.isEmpty
          ? const EstadoVacioCargando(
              icon: Icons.feed_outlined,
              message: 'Aún no hay publicaciones',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              itemCount: publicaciones!.length,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: TarjetaPost(
                      post: publicaciones![index],
                      onJoin: () {}, // Ya está en la comunidad
                      onEliminado: onRefresh,
                      estaEnComunidad: true,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
