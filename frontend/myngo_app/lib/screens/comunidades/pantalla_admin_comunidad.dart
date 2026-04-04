import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myngo_app/models/comunidad.dart';
import 'package:myngo_app/services/servicio_moderacion.dart';
import 'package:myngo_app/services/servicio_comunidades.dart';
import 'package:myngo_app/services/servicio_galeria.dart';
import 'package:myngo_app/screens/comunidades/pantalla_detalle_publicacion.dart';
import 'package:myngo_app/screens/galeria/pantalla_detalle_imagen.dart';
import 'package:myngo_app/models/imagen_galeria.dart';
import 'package:myngo_app/models/publicacion.dart';

class PantallaAdminComunidad extends StatefulWidget {
  final Comunidad comunidad;
  const PantallaAdminComunidad({super.key, required this.comunidad});

  @override
  State<PantallaAdminComunidad> createState() => _PantallaAdminComunidadState();
}

class _PantallaAdminComunidadState extends State<PantallaAdminComunidad> with SingleTickerProviderStateMixin {
  final _servicioModeracion = ServicioModeracion();
  final _servicioComunidades = ServicioComunidades();
  final _servicioGaleria = ServicioGaleria();
  TabController? _tabController;
  Map<String, dynamic>? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final res = await _servicioModeracion.obtenerDashboardAdmin(widget.comunidad.id);
    if (res.exito && mounted) {
      setState(() {
        _datos = res.datos;
        _cargando = false;
      });
    } else if (mounted) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Admin: ${widget.comunidad.nombre}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          indicatorColor: const Color(0xFFF28B50),
          tabs: const [
            Tab(text: 'Solicitudes', icon: Icon(Icons.person_add_rounded)),
            Tab(text: 'Reportes', icon: Icon(Icons.gavel_rounded)),
          ],
        ),
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildSolicitudesTab(),
              _buildReportesTab(),
            ],
          ),
    );
  }

  Widget _buildSolicitudesTab() {
    final dynamic rawSolicitudes = _datos != null ? _datos!['solicitudes_pendientes'] : null;
    final List solicitudes = (rawSolicitudes is List) ? rawSolicitudes : [];
    
    if (solicitudes.isEmpty) {
      return _buildEmptyState(Icons.people_outline, 'No hay solicitudes pendientes');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        final dynamic sol = solicitudes[index];
        if (sol == null || sol is! Map) return const SizedBox.shrink();
        
        final String nombre = sol['usuario_nombre']?.toString() ?? 'Usuario';
        final String fecha = sol['fecha']?.toString().split('T')[0] ?? 'Reciente';

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF248EA6), child: Icon(Icons.person, color: Colors.white)),
            title: Text(nombre, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Pidió unirse el $fecha', style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  onPressed: () => _responderPeticion(sol['id'], true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                  onPressed: () => _responderPeticion(sol['id'], false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportesTab() {
    final dynamic rawReportes = _datos != null ? _datos!['reportes_activos'] : null;
    final List reportes = (rawReportes is List) ? rawReportes : [];
    
    if (reportes.isEmpty) {
      return _buildEmptyState(Icons.check_circle_outline, 'No hay reportes activos 🐾');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        final dynamic rep = reportes[index];
        if (rep == null || rep is! Map) return const SizedBox.shrink();

        final String tipo = rep['tipo_objeto']?.toString() ?? 'CONTENIDO';
        final String informador = rep['informador_nombre']?.toString() ?? 'Anónimo';
        final String motivo = rep['motivo']?.toString() ?? 'Sin motivo';
        final String? comentario = rep['comentario']?.toString();

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(tipo, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text('Reportado por $informador', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Motivo: $motivo', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (comentario != null) ...[
                  const SizedBox(height: 4),
                  Text(comentario, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _resolverReporte(rep['id'], 'DESESTIMADO'), 
                      icon: const Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
                      tooltip: 'Cumple las normas',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => _mostrarDialogoBorrado(rep['objeto_id'], rep['tipo_objeto'], rep['id']), 
                      child: const Text('Borrar (Moderar)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _responderPeticion(int id, bool aceptar) async {
    final res = await _servicioComunidades.responderPeticion(id, aceptar);
    if (res.exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
      _cargarDatos();
    }
  }

  Future<void> _verContenido(int id, String tipo) async {
    if (tipo == 'POST') {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => PantallaDetallePublicacion(publicacionId: id),
      ));
    } else if (tipo == 'IMAGEN') {
      // Necesitamos el objeto ImagenGaleria completo para la pantalla de detalle
      // Lo construimos mínimamente o lo cargamos (idealmente cargar)
      setState(() => _cargando = true);
      final res = await _servicioGaleria.obtenerDetalleImagenExtendido(id);
      setState(() => _cargando = false);

      if (res.exito && res.datos != null && mounted) {
        // Mapeo manual rápido o mejora de modelo necesaria si no encaja
        // PantallaDetalleImagen usa ImagenGaleria.fromJson
        // res.datos suele traer el JSON del modelo ImagenGaleria si es el detalle
        final img = ImagenGaleria.fromJson(Map<String, dynamic>.from(res.datos!));
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => PantallaDetalleImagen(imagen: img),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar la imagen')));
      }
    }
  }

  void _mostrarDialogoBorrado(int id, String tipo, int reporteId) {
    final razonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Moderar Contenido', style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Introduce el motivo del borrado para notificar al autor:', 
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: razonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Incumple las normas de la comunidad',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _moderarContenido(id, tipo, reporteId, razonCtrl.text);
            }, 
            child: const Text('Confirmar Borrado'),
          ),
        ],
      ),
    );
  }

  Future<void> _moderarContenido(int id, String tipo, int reporteId, String razon) async {
    setState(() => _cargando = true);
    
    // 1. Borrar el contenido
    dynamic resBorrado;
    if (tipo == 'POST') {
      resBorrado = await _servicioComunidades.eliminarPublicacion(id, razon: razon);
    } else if (tipo == 'IMAGEN') {
      resBorrado = await _servicioGaleria.eliminarImagen(id, razon: razon);
    } else if (tipo == 'COMENTARIO') {
      resBorrado = await _servicioComunidades.eliminarComentario(id, razon: razon);
    }

    if (resBorrado?.exito == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contenido eliminado y reporte resuelto')));
        _cargarDatos();
      }
    } else {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al moderar: ${resBorrado?.mensaje}')));
      }
    }
  }

  Future<void> _resolverReporte(int reporteId, String estado) async {
    setState(() => _cargando = true);
    final res = await _servicioModeracion.resolverReporte(reporteId, estado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
      _cargarDatos();
    }
  }
}
