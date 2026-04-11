import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/usuario.dart';
import 'pantalla_detalle_perfil.dart';
import '../inicio/pantalla_inicio.dart';
import '../../widgets/comunes/boton_tactil.dart';

class PantallaPerfiles extends StatefulWidget {
  const PantallaPerfiles({super.key});

  @override
  State<PantallaPerfiles> createState() => _PantallaPerfilesState();
}

class _PantallaPerfilesState extends State<PantallaPerfiles> {
  final _servicioUsuarios = ServicioUsuarios();
  final _controladorBusqueda = TextEditingController();
  
  List<Usuario> _usuariosOriginales = [];
  List<Usuario> _usuariosFiltrados = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos({String? filtro}) async {
    setState(() => _estaCargando = true);
    
    final respuesta = await _servicioUsuarios.listarUsuarios();
    if (respuesta.exito && mounted) {
      _usuariosOriginales = respuesta.datos ?? [];
      
      setState(() {
        if (filtro != null && filtro.isNotEmpty) {
          _usuariosFiltrados = _usuariosOriginales.where((u) => 
             u.nombreUsuario.toLowerCase().contains(filtro.toLowerCase()) ||
             u.email.toLowerCase().contains(filtro.toLowerCase())
          ).toList();
        } else {
          _usuariosFiltrados = List.from(_usuariosOriginales);
        }
        _estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Fijo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                Text(
                  'PERFILES',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A4440),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Barra de Búsqueda
                TextField(
                  controller: _controladorBusqueda,
                  onChanged: (valor) => _cargarDatos(filtro: valor),
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Busca a un michi...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFC35E34), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable
          Expanded(
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
                : _buildGridPerfiles(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPerfiles() {
    if (_usuariosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No encontramos perfiles...',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _cargarDatos(),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: _usuariosFiltrados.length,
        itemBuilder: (context, index) {
          final usuario = _usuariosFiltrados[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: usuario.urlAvatar != null ? NetworkImage(usuario.urlAvatar!) : null,
                child: usuario.urlAvatar == null ? const Icon(Icons.person) : null,
              ),
              title: Text(usuario.nombreUsuario, style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
              subtitle: Text(usuario.email, style: GoogleFonts.outfit(fontSize: 12)),
              onTap: () {
                final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                if (inicioState != null) {
                  inicioState.seleccionarUsuario(usuario);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => PantallaDetallePerfil(usuario: usuario)),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }
}
