import 'package:flutter/material.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/respuesta_api.dart';

/// Pantalla que muestra los detalles de una comunidad específica.
class PantallaDetalleComunidad extends StatefulWidget {
  final Comunidad comunidad;

  const PantallaDetalleComunidad({super.key, required this.comunidad});

  @override
  State<PantallaDetalleComunidad> createState() => _PantallaDetalleComunidadState();
}

class _PantallaDetalleComunidadState extends State<PantallaDetalleComunidad> {
  final _servicio = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  bool _estaCargandoPeticion = false;
  int? _miId;
  String? _estadoMembresia; // PENDIENTE, ACEPTADO, RECHAZADO, null

  @override
  void initState() {
    super.initState();
    _obtenerMiId();
  }

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) {
      setState(() {
        _miId = id;
      });
    }
  }

  Future<void> _gestionarMembresia() async {
    setState(() => _estaCargandoPeticion = true);
    final respuesta = await _servicio.unirseAComunidad(widget.comunidad.id);
    
    if (mounted) {
      setState(() {
        _estaCargandoPeticion = false;
        if (respuesta.exito) {
          _estadoMembresia = respuesta.datos?['estado'];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header con imagen o gradiente
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.comunidad.urlPortada.isEmpty
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.pets_rounded, size: 80, color: Colors.white),
                    ),
                  )
                : Image.network(
                    widget.comunidad.urlPortada, 
                    fit: BoxFit.cover,
                    headers: const {
                      'Access-Control-Allow-Origin': '*',
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y Chip de Privacidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.comunidad.nombre,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      _ChipPrivacidad(esPublica: widget.comunidad.esPublica),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila de Info (Creador, Rating)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                        child: const Icon(Icons.person, size: 16, color: Color(0xFF6C63FF)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Por ${widget.comunidad.creadorNombre}${esCreador ? " (Tú)" : ""}',
                        style: const TextStyle(color: Color(0xFF9094A6), fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      Text(
                        ' ${widget.comunidad.ratingMedio}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 48, thickness: 1, color: Color(0xFFF1F3F9)),
                  
                  // Descripción
                  const Text(
                    'Sobre esta comunidad 🐾',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.comunidad.descripcion.isEmpty 
                      ? 'Sin descripción todavía. ¡Únete y sé el primero en saludar!' 
                      : widget.comunidad.descripcion,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 100), // Espacio para el botón inferior
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (esCreador || _estadoMembresia == 'ACEPTADO')
        ? null // No mostramos el botón si ya es miembro o creador
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_estaCargandoPeticion || _estadoMembresia == 'PENDIENTE') ? null : _gestionarMembresia,
              style: ElevatedButton.styleFrom(
                backgroundColor: _estadoMembresia == 'PENDIENTE' ? Colors.grey : const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _estaCargandoPeticion
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _estadoMembresia == 'PENDIENTE' 
                      ? 'SOLICITUD PENDIENTE 🐾' 
                      : widget.comunidad.esPublica ? 'UNIRSE AHORA ✨' : 'SOLICITAR ENTRAR 🐾',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
            ),
          ),
    );
  }
}

class _ChipPrivacidad extends StatelessWidget {
  final bool esPublica;
  const _ChipPrivacidad({required this.esPublica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esPublica ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.visibility_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            esPublica ? 'Pública' : 'Privada',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: esPublica ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
