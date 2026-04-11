import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/notificacion.dart';
import '../comunidades/pantalla_detalle_publicacion.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../../widgets/comunes/boton_tactil.dart';
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
  final _servicioUsuarios = ServicioUsuarios();
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
    if (notif.nombreComunidad != null && notif.nombreComunidad!.isNotEmpty) {
      respuesta = await _servicioComunidades.responderPeticion(notif.referenciaId!, aceptar);
    } else {
      respuesta = await _servicioPerfiles.responderPeticion(notif.referenciaId!, aceptar);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje, style: GoogleFonts.outfit()),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      if (respuesta.exito) _cargarNotificaciones();
    }
  }

  void _navegarADetalle(Notificacion notif) async {
    if (notif.tipo == 'LIKE' || notif.tipo == 'COMENTARIO') {
      if (notif.referenciaId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaDetallePublicacion(publicacionId: notif.referenciaId),
          ),
        );
      }
    } else if (['VOTO', 'SEGUIMIENTO', 'PETICION_ACEPTADA', 'PETICION_SEGUIMIENTO'].contains(notif.tipo)) {
      if (notif.idGenerador != null) {
        final res = await _servicioUsuarios.obtenerDatosUsuario(notif.idGenerador!);
        if (mounted && res.exito && res.datos != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDetallePerfil(usuario: res.datos!),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1), // Peach Cream Universal
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Text(
              'NOTIFICACIONES',
              style: GoogleFonts.outfit(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4A4440), // Terracotta Grey
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
                : _notificaciones.isEmpty
                    ? _buildVistaVacia()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) => _TarjetaNotificacion(
                          notif: _notificaciones[index],
                          isLast: index == _notificaciones.length - 1,
                          onResponder: _responder,
                          onTap: _navegarADetalle,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                 BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Todo tranquilo por aquí!',
            style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve más tarde para ver tus avisos.', 
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14)
          ),
        ],
      ),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  final Notificacion notif;
  final bool isLast;
  final Function(Notificacion, bool) onResponder;
  final Function(Notificacion) onTap;

  const _TarjetaNotificacion({
    required this.notif,
    this.isLast = false,
    required this.onResponder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Solo mostrar botones si es una petición SIN responder (estado_peticion es null)
    bool esPeticionPendiente = (notif.tipo == 'PETICION_CO_ADMIN' || notif.tipo == 'PETICION_SEGUIMIENTO' || notif.tipo == 'PETICION_UNION') && 
                                (notif.estadoPeticion == null || notif.estadoPeticion!.isEmpty);
    final color = _getColorTipo(notif.tipo);
    final icon = _getIconoTipo(notif.tipo);

    return BotonTactil(
      onTap: () => onTap(notif),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.mensaje,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: notif.leida ? FontWeight.w500 : FontWeight.w800,
                          color: const Color(0xFF4A4440),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd MMM · HH:mm').format(notif.fechaNotificacion),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (!notif.leida)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC35E34), shape: BoxShape.circle)),
              ],
            ),
            if (esPeticionPendiente) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: BotonTactil(
                      onTap: () => onResponder(notif, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text('ACEPTAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonTactil(
                      onTap: () => onResponder(notif, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text('RECHAZAR', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo) {
      case 'LIKE': return Icons.favorite_rounded;
      case 'COMENTARIO': return Icons.chat_bubble_rounded;
      case 'PETICION_CO_ADMIN':
      case 'PETICION_UNION':
      case 'PETICION_SEGUIMIENTO': return Icons.group_add_rounded;
      case 'VOTO': return Icons.star_rounded;
      case 'PETICION_ACEPTADA': return Icons.check_circle_rounded;
      case 'PETICION_RECHAZADA': return Icons.error_outline_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'LIKE': return const Color(0xFFD95F43);
      case 'COMENTARIO': return const Color(0xFF248EA6);
      case 'PETICION_CO_ADMIN':
      case 'PETICION_UNION':
      case 'PETICION_SEGUIMIENTO': return const Color(0xFFC35E34);
      case 'VOTO': return Colors.amber;
      case 'PETICION_ACEPTADA': return const Color(0xFF248EA6);
      case 'PETICION_RECHAZADA': return const Color(0xFFD95F43);
      default: return const Color(0xFFF29C50);
    }
  }
}
