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
  final bool tieneFondoGlobal;

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
    this.tieneFondoGlobal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || publicaciones == null) {
      const loading = Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFFF28B50)),
          ));
      return comoSliver ? const SliverToBoxAdapter(child: SizedBox(height: 200, child: loading)) : loading;
    }

    if (publicaciones!.isEmpty) {
      Color? textColor;
      if (backgroundConfig != null) {
        // Color basado en el fondo configurado del feed
        final color1Hex = backgroundConfig!['color1']?.toString() ?? (esAppClara ? '#FFFFFF' : '#121212');
        final color1 = _parseHex(color1Hex);
        textColor = color1.computeLuminance() > 0.5 ? const Color(0xFF4A4440) : Colors.white.withOpacity(0.9);
      } else if (tieneFondoGlobal) {
        // Hay imagen de fondo de comunidad: texto blanco con sombra implícita
        textColor = Colors.white.withOpacity(0.9);
      } else {
        // Sin fondo: adaptar al tema (claro = oscuro, oscuro = blanco)
        textColor = esAppClara ? const Color(0xFF4A4440) : Colors.white.withOpacity(0.8);
      }

      final empty = EstadoVacioCargando(
        icon: Icons.feed_outlined,
        message: 'Aún no hay publicaciones',
        textColor: textColor,
      );
      
      if (comoSliver) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: empty),
        );
      }
      return Center(child: empty);
    }

    // Contrucción de los slivers directamente si es comoSliver
    if (comoSliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == publicaciones!.length) {
                return hasMore 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                    )
                  : const SizedBox.shrink();
              }
              return _buildPostItem(publicaciones![index]);
            },
            childCount: publicaciones!.length + (hasMore ? 1 : 0),
          ),
        ),
      );
    }

    // Versión no-sliver (usada en previews o vistas simples)
    final mainList = ListView.builder(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(), 
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
    );

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
        child: mainList,
      ),
    );

    if (backgroundConfig == null) return mainContent;

    return Stack(
      children: [
        Positioned.fill(child: buildPostsBackgroundFromConfig(backgroundConfig, context)),
        mainContent,
      ],
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
            fuente: fuente,
          ),
        ),
      ),
    );
  }

  static Widget buildPostsBackgroundFromConfig(Map<String, dynamic>? config, BuildContext context) {
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
            color: (color1.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.15),
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
}

class _PatronPainter extends CustomPainter {
  final String tipo;
  final Color color;

  _PatronPainter({required this.tipo, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    if (tipo == 'puntos') {
      for (double x = 0; x < size.width; x += 25) {
        for (double y = 0; y < size.height; y += 25) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
        }
      }
    } else if (tipo == 'lineas') {
      for (double x = -size.height; x < size.width; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      }
    } else if (tipo == 'diagonal_inversa') {
      for (double x = 0; x < size.width + size.height; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
      }
    } else if (tipo == 'cuadricula') {
      for (double x = 0; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (tipo == 'zigzag') {
      final p = Path();
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double y = 0; y < size.height + step; y += step) {
        p.moveTo(0, y);
        for (double x = 0; x < size.width + step; x += step) {
          p.lineTo(x + step / 2, y + step / 2);
          p.lineTo(x + step, y);
        }
      }
      canvas.drawPath(p, paint);
    } else if (tipo == 'diamantes') {
      const step = 50.0;
      paint.style = PaintingStyle.stroke;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          final p = Path()
            ..moveTo(x, y - step / 2)
            ..lineTo(x + step / 2, y)
            ..lineTo(x, y + step / 2)
            ..lineTo(x - step / 2, y)
            ..close();
          canvas.drawPath(p, paint);
        }
      }
    } else if (tipo == 'olas') {
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double y = 0; y < size.height + step; y += step) {
        final p = Path()..moveTo(0, y);
        for (double x = 0; x < size.width + step; x += step) {
          p.quadraticBezierTo(x + step / 4, y - step / 4, x + step / 2, y);
          p.quadraticBezierTo(x + 3 * step / 4, y + step / 4, x + step, y);
        }
        canvas.drawPath(p, paint);
      }
    } else if (tipo == 'triangulos') {
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          final p = Path()
            ..moveTo(x, y - 10)
            ..lineTo(x + 10, y + 10)
            ..lineTo(x - 10, y + 10)
            ..close();
          canvas.drawPath(p, paint);
        }
      }
    } else if (tipo == 'puntos_grandes') {
      for (double x = 0; x < size.width; x += 50) {
        for (double y = 0; y < size.height; y += 50) {
          canvas.drawCircle(Offset(x, y), 4.0, paint);
        }
      }
    } else if (tipo == 'estrellas') {
      const step = 60.0;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), paint);
          canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
