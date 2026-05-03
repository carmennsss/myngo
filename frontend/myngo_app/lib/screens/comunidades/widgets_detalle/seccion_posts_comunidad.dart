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
  final String? fuente;
  final Map<String, dynamic>? backgroundConfig;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  const SeccionPostsComunidad({
    super.key,
    required this.publicaciones,
    required this.estaCargando,
    required this.onRefresh,
    required this.esAppClara,
    this.comoSliver = false,
    this.fuente,
    this.backgroundConfig,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || publicaciones == null) {
      final loading = const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFFF28B50)),
          ));
      return comoSliver ? SliverToBoxAdapter(child: SizedBox(height: 200, child: loading)) : loading;
    }

    if (publicaciones!.isEmpty) {
      final empty = const EstadoVacioCargando(
        icon: Icons.feed_outlined,
        message: 'Aún no hay publicaciones',
      );
      return comoSliver ? SliverToBoxAdapter(child: SizedBox(height: 200, child: empty)) : empty;
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

    final mainContent = RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (hasMore && !isLoadingMore && 
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
            onLoadMore?.call();
          }
          return false;
        },
        child: ListView.builder(
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          itemCount: publicaciones!.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == publicaciones!.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
              );
            }
            return _buildPostItem(publicaciones![index]);
          },
        ),
      ),
    );

    if (backgroundConfig == null) return mainContent;

    return Stack(
      children: [
        Positioned.fill(child: _buildBackground(context)),
        mainContent,
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    // Importamos la lógica de renderizado desde PantallaDetalleComunidad
    // o la duplicamos por ahora si es necesario para evitar dependencias circulares
    // En un sistema real esto iría en un Widget reutilizable 'FondoPersonalizado'
    return _buildPostsBackgroundFromConfig(backgroundConfig, context);
  }

  static Widget _buildPostsBackgroundFromConfig(Map<String, dynamic>? config, BuildContext context) {
    if (config == null) return const SizedBox.shrink();

    final esClaro = Theme.of(context).brightness == Brightness.light;
    final tipo = config['tipo'] ?? 'solido';
    final color1Hex = config['color1']?.toString() ?? (esClaro ? '#FFFFFF' : '#121212');
    final color2Hex = config['color2']?.toString();
    final patron = config['patron']?.toString() ?? 'puntos';

    final color1 = _parseHex(color1Hex);
    final color2 = _parseHex(color2Hex) ?? color1.withOpacity(0.8);

    if (tipo == 'gradiente') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    if (tipo == 'patron') {
      return Container(
        color: color1,
        child: CustomPaint(
          painter: _PatronPainter(
            tipo: patron,
            color: (color1.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.05),
          ),
          child: Container(),
        ),
      );
    }

    return Container(color: color1);
  }

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.white;
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return Colors.white;
    }
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
            fuente: fuente,
          ),
        ),
      ),
    );
  }
}

class _PatronPainter extends CustomPainter {
  final String tipo;
  final Color color;

  _PatronPainter({required this.tipo, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (tipo == 'puntos') {
      for (double x = 0; x < size.width; x += 20) {
        for (double y = 0; y < size.height; y += 20) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    } else if (tipo == 'lineas') {
      for (double x = -size.height; x < size.width; x += 25) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      }
    } else if (tipo == 'cuadricula') {
      for (double x = 0; x < size.width; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
