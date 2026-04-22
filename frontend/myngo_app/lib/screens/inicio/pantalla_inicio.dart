import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_notificaciones.dart';
import '../comunidades/pantalla_comunidades.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../explorar/pantalla_explorar.dart';
import '../notificaciones/pantalla_notificaciones.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../comunidades/pantalla_admin_comunidad.dart';
import '../perfiles/pantalla_tienda_mejoras.dart';
import '../galeria/pantalla_mis_cosas.dart';
import '../../widgets/comunes/vista_requerir_login.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../services/servicio_inicio.dart';
import '../../models/publicacion.dart';
// Widgets de inicio
import '../../widgets/inicio/cabecera_pro.dart';
import '../../widgets/inicio/sidebar_izquierdo.dart';
import '../../widgets/inicio/feed_publicaciones.dart';
import '../../widgets/inicio/barra_contexto_comunidad.dart';

export '../../widgets/inicio/lateral_derecho.dart';

class PantallaInicio extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  const PantallaInicio({super.key, this.navigationShell});

  @override
  State<PantallaInicio> createState() => PantallaInicioState();
}

class PantallaInicioState extends State<PantallaInicio> {
  int _indiceSeleccionado = 0;
  bool _estaLogueado = false;
  String? _miNombre;
  String? _miAvatar;
  int? _miId;
  int? _puntos;
  int _notificacionesSinLeer = 0;
  List<Comunidad>? _misComunidades;
  bool _cargandoComunidades = false;
  bool _isSidebarOpen = true;
  List<Usuario>? _rankingUsuarios;
  bool _cargandoRanking = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final resDatos = await ServicioUsuarios().obtenerDatosPropios();
      if (resDatos.exito && resDatos.datos != null && mounted) {
        setState(() {
          _estaLogueado = true;
          _miNombre = resDatos.datos!.nombreUsuario;
          _miAvatar = resDatos.datos!.urlAvatar;
          _miId = resDatos.datos!.id;
          _puntos = resDatos.datos!.puntos;
        });
        _cargarComunidades();
        _cargarNotificacionesSinLeer();
      }
    }
    _cargarRanking();
  }

  Future<void> _cargarRanking() async {
    setState(() => _cargandoRanking = true);
    final res = await ServicioUsuarios().obtenerRanking();
    if (mounted) {
      setState(() {
        _rankingUsuarios = res.datos ?? [];
        _cargandoRanking = false;
      });
    }
  }

  Future<void> _cargarNotificacionesSinLeer() async {
    if (!_estaLogueado) return;
    final conteo = await ServicioNotificaciones().obtenerConteoNoLeidas();
    if (mounted) setState(() => _notificacionesSinLeer = conteo);
  }

  Future<void> _cargarComunidades() async {
    setState(() {
      _cargandoComunidades = true;
      _misComunidades = null; // Reiniciar a null según la nueva lógica
    });
    final res = await ServicioComunidades().listarComunidadesPropias();
    if (mounted) {
      setState(() {
        _misComunidades = res.datos ?? [];
        _cargandoComunidades = false;
      });
    }
  }

  void _alPulsarNav(int index) {
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
    } else {
      setState(() {
        _indiceSeleccionado = index;
      });
    }
  }

  void _seleccionarComunidad(Comunidad comunidad) {
    if ((widget.navigationShell?.currentIndex ?? _indiceSeleccionado) == 1) {
      context.go('/explorar/comunidades/${comunidad.id}', extra: comunidad);
    } else {
      context.go('/inicio/comunidades/${comunidad.id}', extra: comunidad);
    }
  }

  void seleccionarComunidad(Comunidad comunidad) => _seleccionarComunidad(comunidad);

  void _seleccionarUsuario(Usuario usuario) {
    if ((widget.navigationShell?.currentIndex ?? _indiceSeleccionado) == 1) {
      context.go('/explorar/perfiles/${usuario.id}', extra: usuario);
    } else {
      context.go('/inicio/perfiles/${usuario.id}', extra: usuario);
    }
  }

  void seleccionarUsuario(Usuario usuario) => _seleccionarUsuario(usuario);
  void cargarComunidades() => _cargarComunidades();
  void cargarNotificacionesSinLeer() => _cargarNotificacionesSinLeer();

  void actualizarPuntos(int nuevosPuntos) {
    if (mounted) setState(() => _puntos = nuevosPuntos);
  }


  void _reordenarComunidades(int oldIndex, int newIndex) {
    if (_misComunidades == null) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Comunidad item = _misComunidades!.removeAt(oldIndex);
      _misComunidades!.insert(newIndex, item);
    });
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isMobile && _estaLogueado ? _construirDrawerMobile() : null,
      body: Column(
        children: [
          CabeceraPro(
            estaLogueado: _estaLogueado,
            nombreUsuario: _miNombre,
            avatarUrl: _miAvatar,
            miId: _miId,
            indiceSeleccionado: widget.navigationShell?.currentIndex ?? _indiceSeleccionado,
            puntos: _puntos,
            notificacionesSinLeer: _notificacionesSinLeer,
            onNavSelected: _alPulsarNav,
            onProfileSelected: _seleccionarUsuario,
          ),
          Expanded(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        width: _isSidebarOpen ? 320.0 : 0.0,
                        height: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2B8A0), // Tono intermedio (terracota claro) para contrastar el navbar
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: 320.0,
                            child: Stack(
                              children: [
                                // Patrón para el fondo de TODA la barra
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.15,
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 30.0,
                                        crossAxisSpacing: 30.0,
                                      ),
                                      itemBuilder: (context, index) => Transform.rotate(
                                        angle: index % 2 == 0 ? 0.3 : -0.2,
                                        child: const Icon(Icons.pets_rounded, size: 40, color: Color(0xFFC35E34)),
                                      ),
                                    ),
                                  ),
                                ),
                                // El SidebarIzquierdo real y deslizable
                                Positioned.fill(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                    child: SidebarIzquierdo(
                                      estaLogueado: _estaLogueado == true,
                                      cargando: _cargandoComunidades == true,
                                      comunidades: _misComunidades,
                                      onComunidadSelected: _seleccionarComunidad,
                                      onReorder: _reordenarComunidades,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: EdgeInsets.zero,
                          child: (widget.navigationShell != null)
                                    ? widget.navigationShell!
                                    : const Center(child: Text('Error de Navegación 🐾', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                  ],
                ),
                if (!isMobile)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    left: _isSidebarOpen ? 320.0 : 0.0,
                    top: 24.0,
                    child: GestureDetector(
                      onTap: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                      child: Tooltip(
                        message: _isSidebarOpen ? 'Contraer menú' : 'Expandir menú',
                        child: Container(
                          height: 64.0,
                          width: 24.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2B8A0),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(2, 0))
                            ],
                          ),
                          child: Icon(
                            _isSidebarOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: const Color(0xFFC35E34),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDrawerMobile() {
    final currentIndex = widget.navigationShell?.currentIndex ?? _indiceSeleccionado;
    final colorPrincipal = const Color(0xFFC35E34);
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFC35E34), Color(0xFFE89A6A)]),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, color: Colors.white, size: 48),
                  const SizedBox(height: 10),
                  Text('MYNGO', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home_rounded, color: currentIndex == 0 ? colorPrincipal : Colors.grey),
            title: Text('Inicio', style: GoogleFonts.outfit(fontWeight: currentIndex == 0 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 0 ? colorPrincipal : Colors.black87)),
            onTap: () { Navigator.pop(context); _alPulsarNav(0); },
          ),
          ListTile(
            leading: Icon(Icons.explore_rounded, color: currentIndex == 1 ? colorPrincipal : Colors.grey),
            title: Text('Explorar', style: GoogleFonts.outfit(fontWeight: currentIndex == 1 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 1 ? colorPrincipal : Colors.black87)),
            onTap: () { Navigator.pop(context); _alPulsarNav(1); },
          ),
          ListTile(
            leading: Icon(Icons.storefront_rounded, color: currentIndex == 4 ? colorPrincipal : Colors.grey),
            title: Text('Tienda', style: GoogleFonts.outfit(fontWeight: currentIndex == 4 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 4 ? colorPrincipal : Colors.black87)),
            onTap: () { Navigator.pop(context); _alPulsarNav(4); },
          ),
          ListTile(
            leading: Icon(Icons.chat_bubble_rounded, color: currentIndex == 3 ? colorPrincipal : Colors.grey),
            title: Text('Chats', style: GoogleFonts.outfit(fontWeight: currentIndex == 3 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 3 ? colorPrincipal : Colors.black87)),
            onTap: () { Navigator.pop(context); _alPulsarNav(3); },
          ),
          ListTile(
            leading: Badge(
              label: _notificacionesSinLeer > 0 ? Text('$_notificacionesSinLeer') : null,
              isLabelVisible: _notificacionesSinLeer > 0,
              backgroundColor: const Color(0xFFD95F43),
              child: Icon(Icons.notifications_rounded, color: currentIndex == 2 ? colorPrincipal : Colors.grey),
            ),
            title: Text('Notificaciones', style: GoogleFonts.outfit(fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 2 ? colorPrincipal : Colors.black87)),
            onTap: () { Navigator.pop(context); _alPulsarNav(2); },
          ),
        ],
      ),
    );
  }
}
