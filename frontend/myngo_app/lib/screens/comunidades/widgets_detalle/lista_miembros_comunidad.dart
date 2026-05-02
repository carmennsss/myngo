import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/comunidad.dart';
import '../../../services/servicio_comunidades.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/comunes/boton_tactil.dart';
import '../../perfiles/pantalla_detalle_perfil.dart';
import '../../../models/usuario.dart';

class ListaMiembrosComunidad extends StatefulWidget {
  final Comunidad comunidad;

  const ListaMiembrosComunidad({super.key, required this.comunidad});

  @override
  State<ListaMiembrosComunidad> createState() => _ListaMiembrosComunidadState();
}

class _ListaMiembrosComunidadState extends State<ListaMiembrosComunidad> {
  final _servicio = ServicioComunidades();
  List<Map<String, dynamic>> _miembros = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
  }

  Future<void> _cargarMiembros() async {
    setState(() => _estaCargando = true);
    final res = await _servicio.obtenerMiembrosComunidad(widget.comunidad.id);
    if (mounted) {
      setState(() {
        _miembros = res.datos ?? [];
        _estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
    }

    if (_miembros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No hay miembros en esta comunidad 🐾', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMiembros,
      color: const Color(0xFFC35E34),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _miembros.length,
        itemBuilder: (context, index) {
          final m = _miembros[index];
          final userId = m['usuario_id'];
          final nombre = m['usuario_nombre'] ?? 'Michi';
          final avatar = m['usuario_avatar'];
          final rol = m['rol'] ?? 'Miembro';
          
          return Consumer<ChatProvider>(
            builder: (context, chatProv, _) {
              final estaOnline = chatProv.isUsuarioOnline(userId);
              
              return BotonTactil(
                onTap: () {
                  // Navegar al perfil del usuario
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (c) => PantallaDetallePerfil(
                        usuario: Usuario(
                          id: userId,
                          perfilId: m['perfil_id'] ?? 0,
                          nombreUsuario: nombre,
                          urlAvatar: avatar,
                          email: '',
                          biografia: '',
                          ratingActual: 0,
                          fechaRegistro: DateTime.now(),
                          esVerificado: false,
                          esPublico: true,
                          estado: estaOnline ? 'ACTIVO' : 'DESCONECTADO',
                        )
                      )
                    )
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                            child: avatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: estaOnline ? Colors.green : Colors.grey.shade400,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF4A4440)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getColorRol(rol).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rol.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _getColorRol(rol),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
      case 'creador':
        return const Color(0xFFD95F43);
      case 'moderador':
        return const Color(0xFF248EA6);
      default:
        return Colors.grey.shade600;
    }
  }
}
