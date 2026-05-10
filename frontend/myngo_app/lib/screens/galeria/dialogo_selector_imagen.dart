import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_usuarios.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Bottom sheet que muestra la galería del usuario para que pueda
// seleccionar una imagen ya subida y meterla en una colección sin volver a subirla.
class DialogoSelectorImagen extends StatefulWidget {
  const DialogoSelectorImagen({Key? key}) : super(key: key);

  @override
  _DialogoSelectorImagenState createState() => _DialogoSelectorImagenState();
}

class _DialogoSelectorImagenState extends State<DialogoSelectorImagen> {
  final _servicioGaleria = ServicioGaleria();
  final _servicioUsuarios = ServicioUsuarios();
  List<ImagenGaleria> _items = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarGaleria();
  }

  // Pide las imágenes del usuario al servidor para mostrarlas en el grid
  Future<void> _cargarGaleria() async {
    // Obtenemos la galería general (pública)
    final res = await _servicioGaleria.obtenerGaleria();
    if (mounted && res.exito) {
      setState(() {
        _items = res.datos ?? [];
        _cargando = false;
      });
    } else if (mounted) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(
            'Selecciona una imagen de tu galería',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF248EA6)))
                : _items.isEmpty
                    ? Center(child: Text('No tienes imágenes aún 🐾', style: GoogleFonts.outfit(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final img = _items[index];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, img),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: img.urlArchivo,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: Colors.white10),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
