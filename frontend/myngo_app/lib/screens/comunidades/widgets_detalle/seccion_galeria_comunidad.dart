import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';

import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/comunidad.dart';
import '../../../models/coleccion.dart';
import '../../../widgets/galeria/masonry_grid_galeria.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../galeria/pantalla_detalle_coleccion.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Widget que gestiona la vista de galería y colecciones de una comunidad.
class SeccionGaleriaComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final List<Coleccion>? colecciones;
  final bool estaCargando;
  final VoidCallback onNuevaColeccion;
  final Key galeriaKey;
  final bool comoSliver;
  final bool esMiembro;

  const SeccionGaleriaComunidad({
    super.key,
    required this.comunidad,
    required this.colecciones,
    required this.estaCargando,
    required this.onNuevaColeccion,
    required this.galeriaKey,
    this.comoSliver = false,
    this.esMiembro = true,
  });

  @override
  State<SeccionGaleriaComunidad> createState() => _SeccionGaleriaComunidadState();
}

class _SeccionGaleriaComunidadState extends State<SeccionGaleriaComunidad> {
  int _indiceGaleria = 0;

  bool _esAppClara(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor.computeLuminance() > 0.5;

  Color _colorTextoSecundario(BuildContext context) =>
      _esAppClara(context) ? Colors.grey.shade700 : Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget.comoSliver) {
          return SliverFillRemaining(
            child: _buildContenido(tr),
          );
        }
        return _buildContenido(tr);
      }
    );
  }


  Widget _buildContenido(String Function(String, [Map<String, dynamic>?]) tr) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Row(
            children: [
              _buildMiniChip(tr('galleryMiau'), _indiceGaleria == 0,
                  () => setState(() => _indiceGaleria = 0)),
              const SizedBox(width: 12),
              _buildMiniChip(tr('galleryCollections'), _indiceGaleria == 1,
                  () => setState(() => _indiceGaleria = 1)),
              const Spacer(),
              if (_indiceGaleria == 1)
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined,
                      color: Color(0xFFF28B50)),
                  onPressed: widget.onNuevaColeccion,
                ),
            ],
          ),
        ),
        Expanded(
          child: _indiceGaleria == 0
              ? MasonryGridGaleria(
                  key: widget.galeriaKey,
                  comunidadId: widget.comunidad.id,
                  esMiembro: widget.esMiembro,
                )
              : _buildGalleryCollections(tr),
        ),
      ],
    );
  }


  Widget _buildGalleryCollections(String Function(String, [Map<String, dynamic>?]) tr) {
    if (widget.estaCargando || widget.colecciones == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }
    if (widget.colecciones!.isEmpty) {
      return EstadoVacioCargando(
        icon: Icons.folder_open_rounded,
        message: tr('galleryNoCollections'),
      );
    }


    final random = math.Random(1337);

    return GridView.builder(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: widget.colecciones!.length,
      itemBuilder: (context, index) {
        final col = widget.colecciones![index];
        final rotacion = (random.nextDouble() - 0.5) * 0.1;
        final coloresHex = [0xFF248EA6, 0xFFF28B50, 0xFFD95F43, 0xFF8338EC];
        final color = Color(coloresHex[index % coloresHex.length]);

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: color.withOpacity(0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PantallaDetalleColeccion(
                  coleccion: col,
                  puedeEditarComunidad: widget.comunidad.miRol == 'Administrador' ||
                      widget.comunidad.miRol == 'Moderador',
                ),
              ),
            );
          },
          child: Transform.rotate(
            angle: rotacion,
            child: _TarjetaColeccion(col: col, color: color),
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFF28B50)
              : (_esAppClara(context)
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFF28B50)
                : (_esAppClara(context)
                    ? Colors.black12
                    : const Color(0xFF2A2A2A)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: active ? Colors.white : _colorTextoSecundario(context),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TarjetaColeccion extends StatelessWidget {
  final Coleccion col;
  final Color color;

  const _TarjetaColeccion({required this.col, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 2)),
        ],
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                color: color.withOpacity(0.1),
                child: (col.previsualizaciones.isNotEmpty)
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: col.previsualizaciones.length > 4
                            ? 4
                            : col.previsualizaciones.length,
                        itemBuilder: (context, i) {
                          final String? url =
                              col.previsualizaciones[i]?.toString();
                          if (url == null || url.isEmpty) {
                            return Container(color: Theme.of(context).colorScheme.surfaceVariant);
                          }
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Theme.of(context).colorScheme.surfaceVariant),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 10),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          col.esPrivada
                              ? Icons.lock_outline_rounded
                              : Icons.folder_open_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              col.nombreColeccion.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
