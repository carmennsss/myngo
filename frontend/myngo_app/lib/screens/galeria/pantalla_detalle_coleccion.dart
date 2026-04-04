import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/coleccion.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';

class PantallaDetalleColeccion extends StatelessWidget {
  final Coleccion coleccion;

  const PantallaDetalleColeccion({Key? key, required this.coleccion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coleccion.nombreColeccion.toUpperCase(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (coleccion.descripcion != null && coleccion.descripcion!.isNotEmpty)
              Text(
                coleccion.descripcion!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          Icon(
            coleccion.esPrivada ? Icons.lock_rounded : Icons.public_rounded,
            color: coleccion.esPrivada ? const Color(0xFFD95F43) : const Color(0xFF248EA6),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: MasonryGridGaleria(
        coleccionId: coleccion.id,
      ),
    );
  }
}
