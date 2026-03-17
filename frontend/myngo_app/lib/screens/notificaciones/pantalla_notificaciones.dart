import 'package:flutter/material.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_comunidades.dart';
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
      
      // Si hay notificaciones no leídas, las marcamos todas como leídas en el servidor
      if (_notificaciones.any((n) => !n.leida)) {
        await _servicioNotificaciones.marcarTodasLeidas();
        // Opcional: Actualizar el estado local para que el estilo cambie visualmente de inmediato
        if (mounted) {
          setState(() {
            _notificaciones = _notificaciones.map((n) => n.copyWith(leida: true)).toList();
          });
        }
      }
    }
  }

  Future<void> _responder(int? peticionId, bool aceptar) async {
    if (peticionId == null) return;
    
    final respuesta = await _servicioComunidades.responderPeticion(peticionId, aceptar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.redAccent,
        ),
      );
      if (respuesta.exito) _cargarNotificaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('Notificaciones 🔔', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _notificaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarNotificaciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) => _TarjetaNotificacion(
                      notificacion: _notificaciones[index],
                      alResponder: (aceptar) => _responder(_notificaciones[index].referenciaId, aceptar),
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
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Todo tranquilo por aquí...',
            style: TextStyle(color: Color(0xFF9094A6), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text('Vuelve más tarde para ver tus avisos.', style: TextStyle(color: Colors.grey)),
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
    // Solo mostramos botones si es una petición pendiente Y no ha sido leída (procesada)
    final bool esPeticion = notificacion.tipo == 'PETICION_UNION' && !notificacion.leida;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notificacion.leida ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(notificacion.leida ? 0.02 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
                        color: const Color(0xFF2D3142),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(notificacion.fechaNotificacion),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (esPeticion) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => alResponder(false),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => alResponder(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Aceptar 🐾'),
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
        color = const Color(0xFF6C63FF);
        break;
      case 'PETICION_ACEPTADA':
        icon = Icons.celebration_rounded;
        color = Colors.green;
        break;
      case 'PETICION_RECHAZADA':
        icon = Icons.error_outline_rounded;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
