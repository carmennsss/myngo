import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../comunidades/widgets/tarjeta_comunidad.dart';
import '../comunidades/widgets/formulario_creacion_comunidad.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../inicio/pantalla_inicio.dart';
import '../../widgets/comunes/boton_tactil.dart';

class PantallaExplorar extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;
  final VoidCallback? onComunidadCreada;
  const PantallaExplorar({super.key, this.onComunidadSelected, this.onComunidadCreada});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
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
      backgroundColor: const Color(0xFFFEF5F1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header y Pestañas - Fijo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título y Botón
                Row(
                  children: [
                    Text(
                      'EXPLORAR MUNDOS',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A4440),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (_indicePestana == 0)
                      BotonTactil(
                        onTap: () => _mostrarModalCreacion(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Pestañas
                Row(
                  children: [
                    _buildPestana('COMUNIDADES', 0),
                    const SizedBox(width: 24),
                    _buildPestana('PERFILES', 1),
                  ],
                ),
                const SizedBox(height: 12),

                // Barra de Búsqueda
                TextField(
                  controller: _controladorBusqueda,
                  onChanged: (valor) => _cargarDatos(filtro: valor),
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _indicePestana == 0 ? 'Busca una comunidad...' : 'Busca a un michi...',
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _estaCargando
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
                  : _indicePestana == 0
                      ? _buildGridComunidades()
                      : _buildGridPerfiles(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestana(String texto, int index) {
    bool activa = _indicePestana == index;
    return BotonTactil(
      onTap: () {
        setState(() {
          _indicePestana = index;
          _controladorBusqueda.clear();
          _cargarDatos();
        });
      },
      child: Column(
        children: [
          Text(
            texto,
            style: GoogleFonts.outfit(
              color: activa ? const Color(0xFFC35E34) : Colors.grey.shade500,
              fontWeight: activa ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (activa)
            Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 24, decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildGridComunidades() {
    if (_comunidades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No encontramos nada...',
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
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          childAspectRatio: 0.82,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _comunidades.length,
        itemBuilder: (context, index) => TarjetaComunidad(
          comunidad: _comunidades[index],
          alPresionar: () {
            if (widget.onComunidadSelected != null) {
              widget.onComunidadSelected!(_comunidades[index]);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetalleComunidad(
                comunidad: _comunidades[index],
                onMembershipChanged: () {
                  _cargarDatos();
                  widget.onComunidadCreada?.call();
                },
              )));
            }
          },
        ),
      ),
    );
  }

  void _mostrarModalCreacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioCreacionComunidad(
        alConfirmar: () {
          _cargarDatos();
          widget.onComunidadCreada?.call();
        },
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
}
