import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_perfiles.dart';
import '../../models/notificacion.dart';
import 'package:intl/intl.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  final _servicioNotificaciones = ServicioNotificaciones();
  final _servicioComunidades = ServicioComunidades();
  final _servicioPerfiles = ServicioPerfiles();
  List<Notificacion> _notificaciones = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    final respuesta = await _servicioNotificaciones.listarNotificaciones();
    if (mounted) {
      setState(() {
        _notificaciones = respuesta.datos ?? [];
        _estaCargando = false;
      });
      
      // Si hay notificaciones no leídas, las marcamos en el servidor (esto quitará el punto rojo)
      final tieneNoLeidas = _notificaciones.any((n) => !n.leida);
      
      if (tieneNoLeidas) {
        await _servicioNotificaciones.marcarTodasLeidas();
        if (mounted) {
          setState(() {
            _notificaciones = _notificaciones.map((n) => n.copyWith(leida: true)).toList();
          });
        }
      }
    }
  }

  Future<void> _responder(Notificacion notif, bool aceptar) async {
    if (notif.referenciaId == null) return;
    
    dynamic respuesta;
    // Si la notificación pertenece a una comunidad
    if (notif.nombreComunidad != null && notif.nombreComunidad!.isNotEmpty) {
      respuesta = await _servicioComunidades.responderPeticion(notif.referenciaId!, aceptar);
    } else {
      // Si la notificación es sobre el seguimiento de un usuario
      respuesta = await _servicioPerfiles.responderPeticion(notif.referenciaId!, aceptar);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje, style: GoogleFonts.inter()),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
        ),
      );
      if (respuesta.exito) _cargarNotificaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Notificaciones 🔔', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
          : _notificaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFF28B50),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: _cargarNotificaciones,
                  child: ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) => _TarjetaNotificacion(
                      notificacion: _notificaciones[index],
                      alResponder: (aceptar) => _responder(_notificaciones[index], aceptar),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Todo tranquilo por aquí...',
            style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text('Vuelve más tarde para ver tus avisos.', style: GoogleFonts.inter(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  final Notificacion notificacion;
  final Function(bool) alResponder;

  const _TarjetaNotificacion({required this.notificacion, required this.alResponder});

  @override
  Widget build(BuildContext context) {
    // Mostramos botones si es una petición Y sigue en estado SOLICITUD en la base de datos
    final bool esPeticion = notificacion.tipo == 'PETICION_UNION' && notificacion.estadoPeticion == 'SOLICITUD';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notificacion.leida ? const Color(0xFF2A2A2A) : const Color(0xFFF28B50).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.mensaje,
                      style: GoogleFonts.inter(
                        fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(notificacion.fechaNotificacion),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (esPeticion) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => alResponder(false),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFF2D0BD)), // Peach for decline
                  child: Text('Rechazar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => alResponder(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28B50), // Vibrant orange for accept
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Aceptar 🐾', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    
    switch (notificacion.tipo) {
      case 'PETICION_UNION':
        icon = Icons.person_add_rounded;
        color = const Color(0xFFF29C50); // Orange/Yellowish
        break;
      case 'PETICION_ACEPTADA':
        icon = Icons.celebration_rounded;
        color = const Color(0xFF248EA6); // Teal
        break;
      case 'PETICION_RECHAZADA':
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFD95F43); // Rust
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
