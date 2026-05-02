import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/coleccion.dart';
import '../../../widgets/comunes/estado_vacio_cargando.dart';
import '../../../widgets/comunes/boton_tactil.dart';
import '../../galeria/pantalla_detalle_coleccion.dart';
import '../../../services/servicio_galeria.dart';
import 'dart:math' as math;

/// Widget que muestra las colecciones (carpetas) de un usuario en su perfil.
class SeccionColeccionesPerfil extends StatelessWidget {
  final List<Coleccion>? colecciones;
  final bool estaCargando;
  final bool esPropietario;
  final VoidCallback onRefresh;

  const SeccionColeccionesPerfil({
    super.key,
    required this.colecciones,
    required this.estaCargando,
    this.esPropietario = true,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || colecciones == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    if (colecciones!.isEmpty) {
      return const EstadoVacioCargando(
        icon: Icons.folder_open_rounded,
        message: 'No hay carpetas o colecciones creadas aún.',
      );
    }

    final random = math.Random(42);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.15), width: 2),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          child: Container(
                            color: color.withOpacity(0.05),
                            child: col.previsualizaciones.isEmpty
                                ? Center(
                                    child: Icon(
                                      Icons.folder_rounded,
                                      color: color.withOpacity(0.5),
                                      size: 32,
                                    ),
                                  )
                                : GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 1,
                                      mainAxisSpacing: 1,
                                    ),
                                    itemCount: col.previsualizaciones.length.clamp(0, 4),
                                    itemBuilder: (context, i) => CachedNetworkImage(
                                      imageUrl: col.previsualizaciones[i],
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(color: Colors.white10),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              col.nombreColeccion,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF4A4440),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${col.imagenesIds.length} elementos',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (esPropietario)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: BotonTactil(
                        onTap: () => _confirmarCambioPrivacidad(context, col),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            col.esPrivada ? Icons.lock_rounded : Icons.visibility_rounded,
                            color: col.esPrivada ? const Color(0xFFD95F43) : const Color(0xFF248EA6),
                            size: 14,
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
      builder: (ctx) => AlertDialog(
        title: Text(
          coleccion.esPrivada ? '¿Hacer pública?' : '¿Hacer privada?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          coleccion.esPrivada
              ? 'Cualquier usuario podrá ver el contenido de esta carpeta.'
              : 'Solo tú podrás ver el contenido de esta carpeta.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirmar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
