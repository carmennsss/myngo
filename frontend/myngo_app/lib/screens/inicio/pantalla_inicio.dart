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
import '../comunidades/widgets/tarjeta_publicacion.dart';

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
  List<Comunidad> _misComunidades = [];

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
  }

  Future<void> _cargarNotificacionesSinLeer() async {
    if (!_estaLogueado) return;
    final conteo = await ServicioNotificaciones().obtenerConteoNoLeidas();
    if (mounted) setState(() => _notificacionesSinLeer = conteo);
  }

  Future<void> _cargarComunidades() async {
    final res = await ServicioComunidades().listarComunidadesPropias();
    if (res.exito && mounted) setState(() => _misComunidades = res.datos ?? []);
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
    context.go('/inicio/comunidades/${comunidad.id}', extra: comunidad);
  }

  void seleccionarComunidad(Comunidad comunidad) => _seleccionarComunidad(comunidad);

  void _seleccionarUsuario(Usuario usuario) {
    context.go('/inicio/perfiles/${usuario.id}', extra: usuario);
  }

  void seleccionarUsuario(Usuario usuario) => _seleccionarUsuario(usuario);
  void cargarComunidades() => _cargarComunidades();
  void cargarNotificacionesSinLeer() => _cargarNotificacionesSinLeer();


  void _reordenarComunidades(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Comunidad item = _misComunidades.removeAt(oldIndex);
      _misComunidades.insert(newIndex, item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile)
                      Container(
                        width: 320,
                        height: double.infinity,
                        color: const Color(0xFFFBE9E0),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: SidebarIzquierdo(
                              estaLogueado: _estaLogueado,
                              comunidades: _misComunidades,
                              onComunidadSelected: _seleccionarComunidad,
                              onReorder: _reordenarComunidades,
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
                );
              },
              ),
            ),
        ],
      ),
    );
  }
}
