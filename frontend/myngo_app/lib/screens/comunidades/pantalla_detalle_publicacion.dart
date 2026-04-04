import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/publicacion.dart';
import '../../services/servicio_comunidades.dart';
import 'widgets/tarjeta_publicacion.dart';

class PantallaDetallePublicacion extends StatefulWidget {
  final int? publicacionId;
  final Publicacion? publicacion;

  const PantallaDetallePublicacion({
    Key? key, 
    this.publicacionId, 
    this.publicacion
  }) : super(key: key);

  @override
  State<PantallaDetallePublicacion> createState() => _PantallaDetallePublicacionState();
}

class _PantallaDetallePublicacionState extends State<PantallaDetallePublicacion> {
  final _servicio = ServicioComunidades();
  Publicacion? _pub;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.publicacion != null) {
      _pub = widget.publicacion;
    } else {
      _cargarPublicacion();
    }
  }

  Future<void> _cargarPublicacion() async {
    if (widget.publicacionId == null) return;
    
    setState(() {
      _cargando = true;
      _error = null;
    });

    final res = await _servicio.obtenerPublicacion(widget.publicacionId!);
    
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _pub = res.datos;
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Detalle de Miau-Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContenido(),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF248EA6)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarPublicacion,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6)),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_pub == null) return const Center(child: Text('No se encontró la publicación', style: TextStyle(color: Colors.white70)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TarjetaPublicacion(
            publicacion: _pub!,
            onEliminado: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 24),
          _buildInfoAdicional(),
        ],
      ),
    );
  }

  Widget _buildInfoAdicional() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFF28B50), size: 18),
              const SizedBox(width: 8),
              Text('Vista de Moderación 🐾', 
                style: GoogleFonts.outfit(color: const Color(0xFFF28B50), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, 'Publicado el', _pub!.fechaCreacion.toLocal().toString().split('.')[0]),
          _buildInfoRow(Icons.tag, 'ID de Contenido', '#${_pub!.id}'),
          _buildInfoRow(Icons.groups_rounded, 'Comunidad ID', '#${_pub!.comunidadId}'),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Text(
            'Si eres administrador de la comunidad, puedes borrar este contenido directamente desde el menú de opciones del post.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(titulo, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(valor, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
