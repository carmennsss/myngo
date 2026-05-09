import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/coleccion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/boton_tactil.dart';
import '../../galeria/pantalla_detalle_coleccion.dart';
import '../../../services/servicio_galeria.dart';
import '../../../utils/configuracion.dart';
import 'package:myngo_app/widgets/comunes/miniatura_video.dart';
import 'package:mime/mime.dart';
import 'dart:math' as math;

/// Widget que muestra las colecciones (carpetas) de un usuario en su perfil.
class SeccionColeccionesPerfil extends StatelessWidget {
  final List<Coleccion>? colecciones;
  final bool estaCargando;
  final bool esPropietario;
  final String? fuentePerfil;
  final VoidCallback onRefresh;

  const SeccionColeccionesPerfil({
    super.key,
    required this.colecciones,
    required this.estaCargando,
    this.esPropietario = true,
    this.fuentePerfil,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || colecciones == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    if (colecciones!.isEmpty) {
      return TranslationWidget(
        builder: (context, tr) => EstadoVacioCargando(
          icon: Icons.folder_open_rounded,
          message: tr('profileEmptyFolders'),
        ),
      );
    }

    final random = math.Random(42);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Un poco más grande que 4 para que se vean bien las fotos
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: colecciones!.length,
      itemBuilder: (context, index) {
        final col = colecciones![index];
        final rotacion = (random.nextDouble() - 0.5) * 0.08; 
        final coloresHex = [0xFF248EA6, 0xFFF28B50, 0xFFD95F43, 0xFF8338EC];
        final color = Color(coloresHex[index % coloresHex.length]);

        return BotonTactil(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PantallaDetalleColeccion(coleccion: col)),
            );
          },
          child: Transform.rotate(
            angle: rotacion,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Container(
                            color: color.withOpacity(0.05),
                            child: col.previsualizaciones.isEmpty
                                ? Center(
                                    child: Icon(
                                      col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_open_rounded,
                                      color: color.withOpacity(0.5),
                                      size: 32,
                                    ),
                                  )
                                : GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 1,
                                      mainAxisSpacing: 1,
                                    ),
                                    itemCount: col.previsualizaciones.length.clamp(0, 4),
                                    itemBuilder: (context, i) {
                                      String url = col.previsualizaciones[i];
                                      if (!url.startsWith('http')) {
                                        url = '${Configuracion.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
                                      }
                                      final esVideo = lookupMimeType(url)?.startsWith('video/') ?? false;

                                      if (esVideo) {
                                        return MiniaturaVideo(url: url, fit: BoxFit.cover);
                                      }

                                      return CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) => Container(color: Colors.white10),
                                        errorWidget: (c, u, e) => Container(color: color.withOpacity(0.1)),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              col.nombreColeccion.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.getFont(
                                fuentePerfil ?? 'Outfit',
                                color: const Color(0xFF4A4440),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (esPropietario)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: BotonTactil(
                        onTap: () => _confirmarCambioPrivacidad(context, col),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            col.esPrivada ? Icons.lock_rounded : Icons.public_rounded,
                            color: col.esPrivada ? const Color(0xFFD95F43) : const Color(0xFF248EA6),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarCambioPrivacidad(BuildContext context, Coleccion coleccion) {
    showDialog(
      context: context,
      builder: (ctx) => TranslationWidget(
        builder: (context, tr) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                coleccion.esPrivada ? Icons.public_rounded : Icons.lock_rounded,
                color: const Color(0xFFF28B50),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  coleccion.esPrivada ? tr('profileFolderMakePublicTitle') : tr('profileFolderMakePrivateTitle'),
                  style: GoogleFonts.getFont(fuentePerfil ?? 'Outfit', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            coleccion.esPrivada
                ? tr('profileFolderMakePublicDesc')
                : tr('profileFolderMakePrivateDesc'),
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('profileFolderCancel'), style: GoogleFonts.inter(color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final res = await ServicioGaleria().editarColeccion(
                    coleccion.id,
                    {'es_privada': !coleccion.esPrivada},
                  );
                  if (res.exito) {
                    onRefresh();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28B50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(tr('profileFolderConfirm'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
