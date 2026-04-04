import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';

class PantallaDetalleImagen extends StatefulWidget {
  final ImagenGaleria imagen;

  const PantallaDetalleImagen({Key? key, required this.imagen}) : super(key: key);

  @override
  State<PantallaDetalleImagen> createState() => _PantallaDetalleImagenState();
}

class _PantallaDetalleImagenState extends State<PantallaDetalleImagen> {
  final ServicioGaleria _servicioGaleria = ServicioGaleria();
  bool _cargandoMetadatos = true;
  Map<String, dynamic>? _metadatos;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    final res = await _servicioGaleria.obtenerDetalleImagenExtendido(widget.imagen.id);
    if (mounted && res.exito) {
      setState(() {
        _metadatos = res.datos;
        _cargandoMetadatos = false;
      });
    } else if (mounted) {
      setState(() => _cargandoMetadatos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Visor de la imagen central interactiva de Zoom
          Center(
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.imagen.urlArchivo,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (c, u) => const CircularProgressIndicator(color: Color(0xFF248EA6)),
              ),
            ),
          ),
          
          // AppBar superpuesta transparente para volver
          Positioned(
            top: 0, left: 0, right: 0,
            child: AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),
          
          // Bottom Sheet de información superpuesta en la parte inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildPanelInformacion(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelInformacion() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.black45, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '@${widget.imagen.propietarioNombre ?? 'Desconocido'}',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Text(
                widget.imagen.fechaSubida.toLocal().toString().split(' ')[0],
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (_cargandoMetadatos)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(color: Color(0xFF248EA6)),
            )
          else ..._buildSeccionesMetadatos(),
        ],
      ),
    );
  }

  List<Widget> _buildSeccionesMetadatos() {
    final List<Widget> widgets = [];
    
    // Post mapping
    if (_metadatos != null && _metadatos!['publicacion'] != null) {
      final pub = _metadatos!['publicacion'];
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Miau Post Vinculado', style: GoogleFonts.inter(color: const Color(0xFFF28B50), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(pub['titulo'] ?? 'Post sin título', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              if (pub['contenido_texto'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  pub['contenido_texto'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Collections mapping
    if (_metadatos != null && _metadatos!['colecciones'] != null) {
      final List colList = _metadatos!['colecciones'];
      if (colList.isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(Text('En carpetas:', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)));
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colList.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF248EA6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF248EA6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c['privada'] == true ? Icons.lock : Icons.folder, color: const Color(0xFF248EA6), size: 14),
                    const SizedBox(width: 6),
                    Text(c['nombre'] ?? 'Carpeta', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }
    }

    return widgets;
  }
}
