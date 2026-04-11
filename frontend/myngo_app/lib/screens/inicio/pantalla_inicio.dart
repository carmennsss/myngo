import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_notificaciones.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../explorar/pantalla_explorar.dart';
import '../notificaciones/pantalla_notificaciones.dart';
import '../galeria/pantalla_mis_cosas.dart';
import '../../widgets/comunes/vista_requerir_login.dart';
// Widgets de inicio
import '../../widgets/inicio/cabecera_pro.dart';
import '../../widgets/inicio/sidebar_izquierdo.dart';
import '../../widgets/inicio/feed_publicaciones.dart';
import '../../widgets/inicio/barra_contexto_comunidad.dart';

export '../../widgets/inicio/lateral_derecho.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

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
  Comunidad? _comunidadSeleccionada;
  Usuario? _usuarioSeleccionado;

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

  void _alPulsarNav(int index) => setState(() {
    _indiceSeleccionado = index;
    _comunidadSeleccionada = null;
    _usuarioSeleccionado = null;
  });

  void _seleccionarComunidad(Comunidad comunidad) => setState(() {
    _comunidadSeleccionada = comunidad;
    _usuarioSeleccionado = null;
  });

  void seleccionarComunidad(Comunidad comunidad) => _seleccionarComunidad(comunidad);

  void _seleccionarUsuario(Usuario usuario) => setState(() {
    _usuarioSeleccionado = usuario;
    _comunidadSeleccionada = null;
  });

  void seleccionarUsuario(Usuario usuario) => _seleccionarUsuario(usuario);

  List<Widget> get _vistasCentrales => [
    FeedPublicaciones(onComunidadSelected: _seleccionarComunidad, onProfileSelected: _seleccionarUsuario),
    PantallaExplorar(onComunidadSelected: _seleccionarComunidad, onComunidadCreada: _cargarComunidades),
    PantallaNotificaciones(onNotificacionesLeidas: _cargarNotificacionesSinLeer),
    const Center(child: Text('Chat próximamente 💬', style: TextStyle(color: Colors.white))),
    PantallaMisCosas(usuarioId: _miId ?? 0),
  ];

  Widget _vistaProtegida(Widget original, String titulo) {
    if (_estaLogueado) return original;
    return VistaRequerirLogin(titulo: titulo);
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
            indiceSeleccionado: _indiceSeleccionado,
            puntos: _puntos,
            notificacionesSinLeer: _notificacionesSinLeer,
            onNavSelected: _alPulsarNav,
            onProfileSelected: _seleccionarUsuario,
          ),
          if (_comunidadSeleccionada != null)
            BarraContextoComunidad(
              comunidad: _comunidadSeleccionada!,
              miId: _miId,
              onCerrar: () => setState(() => _comunidadSeleccionada = null),
              onComunidadActualizada: (c) => setState(() => _comunidadSeleccionada = c),
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: SidebarIzquierdo(
                            estaLogueado: _estaLogueado,
                            comunidades: _misComunidades,
                            onComunidadSelected: _seleccionarComunidad,
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: (_comunidadSeleccionada != null || _usuarioSeleccionado != null)
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(horizontal: 24),
                        child: _comunidadSeleccionada != null
                            ? PantallaDetalleComunidad(
                                comunidad: _comunidadSeleccionada!,
                                esIntegrada: true,
                                onBack: () => setState(() => _comunidadSeleccionada = null),
                                onMembershipChanged: _cargarComunidades,
                              )
                            : _usuarioSeleccionado != null
                                ? PantallaDetallePerfil(
                                    usuario: _usuarioSeleccionado!,
                                    esIntegrada: true,
                                    onBack: () => setState(() => _usuarioSeleccionado = null),
                                    onPerfilActualizado: _inicializarDatos,
                                  )
                                : IndexedStack(
                                    index: _indiceSeleccionado,
                                    children: [
                                      _vistasCentrales[0],
                                      _vistasCentrales[1],
                                      _vistaProtegida(_vistasCentrales[2], 'Tus Notificaciones'),
                                      _vistaProtegida(_vistasCentrales[3], 'Tus Mensajes'),
                                      _vistaProtegida(_vistasCentrales[4], 'Tu Rincón Michi'),
                                    ],
                                  ),
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
