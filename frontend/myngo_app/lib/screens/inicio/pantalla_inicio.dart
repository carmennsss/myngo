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
import '../../services/servicio_mensajeria.dart';
import '../../providers/chat_provider.dart';
import '../../utils/mejoras_notifier.dart';
import 'package:provider/provider.dart';
import 'package:tolgee/tolgee.dart';
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
import '../../models/publicacion.dart';
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
  final ServicioMensajeria _servicioChat = ServicioMensajeria();
  int _indiceSeleccionado = 0;
  bool _estaLogueado = false;
  String? _miNombre;
  String? _miAvatar;
  String? _miMarco;
  String _miEstado = 'DESCONECTADO';
  int? get miId => _miId;
  String? get miNombre => _miNombre;
  String get miEstado => _miEstado;

  int? _miId;
  int? _miPerfilId;
  int? _puntos;
  List<int> _ordenGuardado = [];
  int _notificacionesSinLeer = 0;
  final ServicioMensajeria _servicioNotifChat = ServicioMensajeria();
  List<Comunidad>? _misComunidades;
  bool _cargandoComunidades = false;
  bool _isSidebarOpen = true;
  List<Usuario>? _rankingUsuarios;
  bool _cargandoRanking = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    mejoraEquipadaNotifier.addListener(_inicializarDatos);
  }

  @override
  void dispose() {
    mejoraEquipadaNotifier.removeListener(_inicializarDatos);
    _servicioChat.dispose();
    _servicioNotifChat.dispose();
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final ordenLocalString = prefs.getString('orden_comunidades_local');
    if (ordenLocalString != null && ordenLocalString.isNotEmpty) {
      try {
        _ordenGuardado = ordenLocalString.split(',').map((e) => int.parse(e)).toList();
      } catch (_) {}
    }

    if (token != null) {
      if (mounted) setState(() => _estaLogueado = true);
      
      final resDatos = await ServicioUsuarios().obtenerDatosPropios();
      if (resDatos.exito && resDatos.datos != null && mounted) {
        setState(() {
          _estaLogueado = true;
          _miNombre = resDatos.datos!.nombreUsuario;
          _miAvatar = resDatos.datos!.urlAvatar;
          _miMarco = resDatos.datos!.marco;
          _miId = resDatos.datos!.id;
          _miPerfilId = resDatos.datos!.perfilId;
          _puntos = resDatos.datos!.puntos;
          _miEstado = resDatos.datos!.estado ?? 'DESCONECTADO';
          
          context.read<ChatProvider>().setUserId(_miId);
          
          if (resDatos.datos!.ordenComunidades.isNotEmpty) {
            _ordenGuardado = resDatos.datos!.ordenComunidades;
            prefs.setString('orden_comunidades_local', _ordenGuardado.join(','));
          }
        });

        _cargarChatsRecientes();
        
        _servicioChat.conectarPresencia((datos) {
          if (!mounted) return;
          final type = datos['type'];
          
          if (type == 'status_change') {
            final userId = datos['user_id'];
            final newStatus = datos['status'];
            if (userId == _miId) {
              setState(() => _miEstado = newStatus);
            }
            context.read<ChatProvider>().actualizarEstadoUsuario(userId, newStatus);
            if (_rankingUsuarios != null) {
              final index = _rankingUsuarios!.indexWhere((u) => u.id == userId);
              if (index != -1) {
                setState(() {
                  _rankingUsuarios![index].estado = newStatus;
                });
              }
            }
          } 
          else if (type == 'presence_connection_established') {
            setState(() {
              _miEstado = datos['status'];
              if (_rankingUsuarios != null && _miId != null) {
                final index = _rankingUsuarios!.indexWhere((u) => u.id == _miId);
                if (index != -1) {
                  _rankingUsuarios![index].estado = _miEstado;
                }
              }
            });
            if (datos['online_users'] != null) {
              context.read<ChatProvider>().setUsuariosOnline(
                (datos['online_users'] as List).map((id) => (id as num).toInt()).toList()
              );
            }
          }
        });

        _cargarComunidades();
        _cargarNotificacionesSinLeer();
        
        final chatProvider = context.read<ChatProvider>();
        chatProvider.cargarConteosIniciales();
        _conectarNotificacionesChat(chatProvider);
      } else if (!resDatos.exito && resDatos.mensaje.contains('401') && mounted) {
        setState(() => _estaLogueado = false);
        await prefs.remove('auth_token');
        await prefs.remove('usuario_id');
      }
    }
    _cargarRanking();
  }

  void cambiarEstado(String nuevoEstado) {
    _servicioChat.cambiarEstadoDisponibilidad(nuevoEstado);
  }

  Future<void> _cargarRanking() async {
    final res = await ServicioUsuarios().obtenerRanking();
    if (mounted) {
      setState(() {
        _rankingUsuarios = res.datos ?? [];
        _cargandoRanking = false;
        if (_rankingUsuarios != null && _miId != null) {
          final index = _rankingUsuarios!.indexWhere((u) => u.id == _miId);
          if (index != -1) {
            _rankingUsuarios![index].estado = _miEstado;
          }
        }
      });
    }
  }

  Future<void> _cargarNotificacionesSinLeer() async {
    if (!_estaLogueado) return;
    final conteo = await ServicioNotificaciones().obtenerConteoNoLeidas();
    if (mounted) setState(() => _notificacionesSinLeer = conteo);
  }

  void _conectarNotificacionesChat(ChatProvider chatProvider) {
    _servicioNotifChat.conectarNotificacionesPersonales((data) {
      if (!mounted) return;
      final type = data['type'];
      
      if (type == 'new_message_notification') {
        chatProvider.procesarNuevaNotificacion(data);
        if (chatProvider.salaActivaId != (data['sala_id'] as num).toInt()) {
          _mostrarToastMensaje(data);
        }
      } else if (type == 'new_chat_notification') {
        chatProvider.notificarNuevaSala();
      } else if (type == 'generic_notification') {
        _cargarNotificacionesSinLeer();
        _mostrarToastNotificacion(data);
      }
    });
  }

  void _mostrarToastNotificacion(Map<String, dynamic> data) {
    final mensaje = data['mensaje'] ?? 'Nueva notificación';
    
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastMensaje(
        sender: 'Myngo',
        preview: mensaje,
        avatar: null, // Podríamos poner un icono de campana
        onTap: () {
          entry.remove();
          _alPulsarNav(2); // Ir a la pestaña de notificaciones
        },
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _mostrarToastMensaje(Map<String, dynamic> data) {
    final salaId = data['sala_id'];
    final sender = data['sender_username'] ?? 'Alguien';
    final preview = data['preview'] ?? '';
    final salaName = data['sala_nombre'] ?? 'Chat';
    final avatar = data['sender_avatar'];

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastMensaje(
        sender: sender,
        preview: preview,
        avatar: avatar,
        onTap: () {
          entry.remove();
          context.go('/mensajes/sala/$salaId',
              extra: {'nombre': salaName});
        },
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _cargarComunidades() async {
    if (!mounted) return;
    setState(() {
      _cargandoComunidades = true;
      _misComunidades = null;
    });
    
    final res = await ServicioComunidades().listarComunidadesPropias();
    
    if (mounted) {
      setState(() {
        List<Comunidad> lista = res.datos ?? [];
        
        if (_ordenGuardado.isNotEmpty) {
          final Map<int, Comunidad> mapaComunidades = {
            for (var c in lista) c.id: c
          };
          
          List<Comunidad> listaOrdenada = [];
          for (var id in _ordenGuardado) {
            if (mapaComunidades.containsKey(id)) {
              listaOrdenada.add(mapaComunidades.remove(id)!);
            }
          }
          listaOrdenada.addAll(mapaComunidades.values);
          lista = listaOrdenada;
        }
        
        _misComunidades = lista;
        _cargandoComunidades = false;
      });
    }
  }

  void _cargarChatsRecientes() {
    if (_estaLogueado) {
      context.read<ChatProvider>().cargarSalas();
    }
  }

  void _alPulsarNav(int index) {
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: true,
      );
    } else {
      setState(() {
        _indiceSeleccionado = index;
      });
    }
  }

  void _seleccionarComunidad(Comunidad comunidad) {
    if ((widget.navigationShell?.currentIndex ?? _indiceSeleccionado) == 1) {
      context.go('/explorar/comunidades/${comunidad.nombre}', extra: comunidad);
    } else {
      context.go('/inicio/comunidades/${comunidad.nombre}', extra: comunidad);
    }
  }

  void seleccionarComunidad(Comunidad comunidad) => _seleccionarComunidad(comunidad);

  void _seleccionarUsuario(Usuario usuario) {
    if ((widget.navigationShell?.currentIndex ?? _indiceSeleccionado) == 1) {
      context.go('/explorar/perfiles/${usuario.nombreUsuario}', extra: usuario);
    } else {
      context.go('/inicio/perfiles/${usuario.nombreUsuario}', extra: usuario);
    }
  }

  void seleccionarUsuario(Usuario usuario) => _seleccionarUsuario(usuario);
  void cargarComunidades() => _cargarComunidades();
  void cargarNotificacionesSinLeer() => _cargarNotificacionesSinLeer();

  void actualizarPuntos(int nuevosPuntos) {
    if (mounted) setState(() => _puntos = nuevosPuntos);
  }

  void _reordenarComunidades(int oldIndex, int newIndex) async {
    if (_misComunidades == null) return;
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Comunidad item = _misComunidades!.removeAt(oldIndex);
      _misComunidades!.insert(newIndex, item);
      _ordenGuardado = _misComunidades!.map((c) => c.id).toList();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orden_comunidades_local', _ordenGuardado.join(','));

    if (_miPerfilId != null) {
      try {
        await ServicioUsuarios().actualizarOrdenComunidades(_miPerfilId!, _ordenGuardado);
      } catch (e) {
        debugPrint('Error guardando orden en servidor: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: isMobile && _estaLogueado ? _construirDrawerMobile(tr) : null,
          body: Column(
            children: [
              CabeceraPro(
                estaLogueado: _estaLogueado,
                nombreUsuario: _miNombre,
                avatarUrl: _miAvatar,
                marcoUrl: _miMarco,
                miId: _miId,
                estado: _miEstado,
                indiceSeleccionado: widget.navigationShell?.currentIndex ?? _indiceSeleccionado,
                puntos: _puntos,
                notificacionesSinLeer: _notificacionesSinLeer,
                mensajesSinLeer: context.watch<ChatProvider>().totalNoLeidos,
                onNavSelected: _alPulsarNav,
                onProfileSelected: _seleccionarUsuario,
                onStatusChanged: cambiarEstado,
                onRefreshProfile: _inicializarDatos,
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
                            child: SidebarIzquierdo(
                              estaLogueado: _estaLogueado == true,
                              tr: tr,
                              cargando: _cargandoComunidades == true,
                              comunidades: _misComunidades,
                              rankingUsuarios: _rankingUsuarios,
                              cargandoRanking: _cargandoRanking == true,
                              onComunidadSelected: _seleccionarComunidad,
                              onUsuarioSelected: _seleccionarUsuario,
                              onReorder: _reordenarComunidades,
                              misPuntos: _puntos,
                            ),
                          ),
                        Expanded(
                          flex: 5,
                          child: (widget.navigationShell != null)
                              ? widget.navigationShell!
                              : const Center(child: Text('Error de Navegación 🐾', style: TextStyle(color: Colors.white))),
                        ),
                      ],
                    ),
                    if (!isMobile)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        left: _isSidebarOpen ? 308.0 : -12.0,
                        top: 24.0, 
                        child: GestureDetector(
                          onTap: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                          child: Tooltip(
                            message: _isSidebarOpen ? 'Cerrar sidebar' : 'Mostrar sidebar',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 24.0,
                              width: 24.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)
                                ],
                                border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2), width: 1),
                              ),
                              child: Icon(
                                _isSidebarOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                                color: const Color(0xFFC35E34),
                                size: 18,
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
      },
    );
  }

  Widget _construirDrawerMobile(dynamic tr) {
    final currentIndex = widget.navigationShell?.currentIndex ?? _indiceSeleccionado;
    final colorPrincipal = const Color(0xFFC35E34);
    
    return Drawer(
      child: Container(
        color: const Color(0xFFFEF5F1),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC35E34), Color(0xFFE89A6A)]
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pets, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('MYNGO', 
                      style: GoogleFonts.outfit(
                        color: Colors.white, 
                        fontSize: 24, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 2
                      )
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.home_rounded, color: currentIndex == 0 ? colorPrincipal : Colors.grey),
              title: Text(tr('navigationHome'), style: GoogleFonts.outfit(fontWeight: currentIndex == 0 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 0 ? colorPrincipal : Colors.black87)),
              onTap: () { Navigator.pop(context); _alPulsarNav(0); },
            ),
            ListTile(
              leading: Icon(Icons.explore_rounded, color: currentIndex == 1 ? colorPrincipal : Colors.grey),
              title: Text(tr('navigationExplore'), style: GoogleFonts.outfit(fontWeight: currentIndex == 1 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 1 ? colorPrincipal : Colors.black87)),
              onTap: () { Navigator.pop(context); _alPulsarNav(1); },
            ),
            ListTile(
              leading: Icon(Icons.storefront_rounded, color: currentIndex == 4 ? colorPrincipal : Colors.grey),
              title: Text(tr('navigationShop'), style: GoogleFonts.outfit(fontWeight: currentIndex == 4 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 4 ? colorPrincipal : Colors.black87)),
              onTap: () { Navigator.pop(context); _alPulsarNav(4); },
            ),
            ListTile(
              leading: Badge(
                label: Text(context.watch<ChatProvider>().totalNoLeidos.toString()),
                isLabelVisible: _estaLogueado && context.watch<ChatProvider>().totalNoLeidos > 0,
                backgroundColor: const Color(0xFFC35E34),
                child: Icon(Icons.chat_bubble_rounded, color: currentIndex == 3 ? colorPrincipal : Colors.grey),
              ),
              title: Text(tr('navigationChats'), style: GoogleFonts.outfit(fontWeight: currentIndex == 3 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 3 ? colorPrincipal : Colors.black87)),
              onTap: () { Navigator.pop(context); _alPulsarNav(3); },
            ),
            ListTile(
              leading: Badge(
                label: Text(_notificacionesSinLeer.toString()),
                isLabelVisible: _estaLogueado && _notificacionesSinLeer > 0,
                backgroundColor: const Color(0xFFC35E34),
                child: Icon(Icons.notifications_rounded, color: currentIndex == 2 ? colorPrincipal : Colors.grey),
              ),
              title: Text(tr('navigationNotifications'), style: GoogleFonts.outfit(fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.w500, color: currentIndex == 2 ? colorPrincipal : Colors.black87)),
              onTap: () { Navigator.pop(context); _alPulsarNav(2); },
            ),
            const Divider(height: 32, indent: 20, endIndent: 20),
            SidebarIzquierdo(
              estaLogueado: _estaLogueado == true,
              tr: tr,
              cargando: _cargandoComunidades == true,
              comunidades: _misComunidades,
              rankingUsuarios: _rankingUsuarios,
              cargandoRanking: _cargandoRanking == true,
              onComunidadSelected: (c) {
                Navigator.pop(context);
                _seleccionarComunidad(c);
              },
              onUsuarioSelected: (u) {
                Navigator.pop(context);
                _seleccionarUsuario(u);
              },
              onReorder: _reordenarComunidades,
              misPuntos: _puntos,
              embeddedInDrawer: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ToastMensaje extends StatefulWidget {
  final String sender;
  final String preview;
  final String? avatar;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ToastMensaje({
    required this.sender,
    required this.preview,
    this.avatar,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_ToastMensaje> createState() => _ToastMensajeState();
}

class _ToastMensajeState extends State<_ToastMensaje>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                elevation: 20,
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC35E34).withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2), width: 2),
                            color: const Color(0xFFF5EBE6),
                          ),
                          child: ClipOval(
                            child: widget.avatar != null
                                ? Image.network(
                                    widget.avatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        widget.sender.isNotEmpty ? widget.sender[0].toUpperCase() : '?',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFC35E34),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Center(
                                    child: Text(
                                      widget.sender.isNotEmpty ? widget.sender[0].toUpperCase() : '?',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC35E34),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '@${widget.sender}',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFC35E34),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'ahora',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.preview,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF4A4440),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onDismiss,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.close_rounded, color: Colors.grey.shade300, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
