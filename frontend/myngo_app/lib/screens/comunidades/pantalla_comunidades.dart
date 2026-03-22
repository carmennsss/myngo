import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import 'widgets/tarjeta_comunidad.dart';
import 'widgets/formulario_creacion_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';
import '../perfiles/pantalla_perfil_usuario.dart';

class PantallaComunidades extends StatefulWidget {
  const PantallaComunidades({super.key});

  @override
  State<PantallaComunidades> createState() => _PantallaComunidadesState();
}

class _PantallaComunidadesState extends State<PantallaComunidades> {
  final _servicioComunidades = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  
  final _controladorBusqueda = TextEditingController();
  
  int _indicePestana = 0; // 0: Comunidades, 1: Perfiles
  
  List<Comunidad> _comunidades = [];
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
    
    if (_indicePestana == 0) {
      final respuesta = await _servicioComunidades.listarComunidades(busqueda: filtro);
      if (mounted) {
        setState(() {
          _comunidades = respuesta.datos ?? [];
          _estaCargando = false;
        });
      }
    } else {
      // Si aún no tenemos los usuarios, los bajamos todos de golpe
      if (_usuariosOriginales.isEmpty) {
        final respuesta = await _servicioUsuarios.listarUsuarios();
        if (respuesta.exito && mounted) {
          _usuariosOriginales = respuesta.datos ?? [];
        }
      }
      
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Explorar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pestañas (SubNav Ribbons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTab('Comunidades', 0, Icons.grid_view_rounded),
                const SizedBox(width: 12),
                _buildTab('Perfiles', 1, Icons.people_alt_rounded),
              ],
            ),
          ),
          
          // Barra de Búsqueda conectada al nuevo estilo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: TextField(
                controller: _controladorBusqueda,
                style: GoogleFonts.inter(color: Colors.white),
                onChanged: (valor) => _cargarDatos(filtro: valor),
                decoration: InputDecoration(
                  hintText: _indicePestana == 0 ? 'Buscar comunidades...' : 'Buscar creadores...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(Icons.search, color: Colors.grey, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _estaCargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
              : _indicePestana == 0 ? _buildGridComunidades() : _buildListaPerfiles(),
          ),
        ],
      ),
      floatingActionButton: _indicePestana == 0 ? FloatingActionButton.extended(
        onPressed: () async {
          final token = await _servicioUsuarios.obtenerToken();
          if (token == null) {
            if (mounted) Navigator.pushNamed(context, '/login');
            return;
          }
          if (mounted) _mostrarModalCreacion(context);
        },
        label: Text('Crear Comunidad', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFF28B50),
        elevation: 4,
      ) : null,
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final active = _indicePestana == index;
    return GestureDetector(
      onTap: () {
        if (!active) {
          setState(() {
            _indicePestana = index;
            _controladorBusqueda.clear();
          });
          _cargarDatos();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF28B50) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? const Color(0xFFF28B50) : const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label, 
              style: GoogleFonts.inter(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridComunidades() {
    if (_comunidades.isEmpty) {
      return Center(child: Text('No hay comunidades todavía.', style: GoogleFonts.inter(color: Colors.grey)));
    }
    
    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _cargarDatos(),
      child: GridView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _comunidades.length,
        itemBuilder: (context, index) => TarjetaComunidad(
          comunidad: _comunidades[index],
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PantallaDetalleComunidad(comunidad: _comunidades[index])),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListaPerfiles() {
    if (_usuariosFiltrados.isEmpty) {
      return Center(child: Text('No se encontraron perfiles.', style: GoogleFonts.inter(color: Colors.grey)));
    }

    return RefreshIndicator(
      color: const Color(0xFF248EA6), // Teal para usuarios
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () {
        _usuariosOriginales.clear(); // forzar recarga
        return _cargarDatos();
      },
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: _usuariosFiltrados.length,
        itemBuilder: (context, index) {
          final usuario = _usuariosFiltrados[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF248EA6).withOpacity(0.2),
                radius: 24,
                child: const Icon(Icons.person, color: Color(0xFF248EA6)),
              ),
              title: Text(
                usuario.nombreUsuario, 
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
              ),
              subtitle: Text(
                usuario.email,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFF29C50)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaPerfilUsuario(usuario: usuario),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalCreacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioCreacionComunidad(
        alConfirmar: () => _cargarDatos(),
      ),
    );
  }
}
