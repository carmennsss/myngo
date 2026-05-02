import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/servicio_comunidades.dart';
import 'services/servicio_usuarios.dart';

import 'screens/login/pantalla_login.dart';
import 'screens/registro/pantalla_registro.dart';
import 'screens/recuperar_contrasena/pantalla_recuperar_contrasena.dart';
import 'screens/inicio/pantalla_inicio.dart';
import 'screens/comunidades/pantalla_detalle_comunidad.dart';
import 'screens/comunidades/pantalla_detalle_post.dart';
import 'screens/perfiles/pantalla_detalle_perfil.dart';
import 'screens/perfiles/pantalla_personalizar_perfil.dart';

// Components inside the Shell
import 'widgets/inicio/feed_publicaciones.dart';
import 'screens/explorar/pantalla_explorar.dart';
import 'screens/notificaciones/pantalla_notificaciones.dart';
import 'screens/perfiles/pantalla_tienda_mejoras.dart';
import 'screens/mensajeria/pantalla_lista_chats.dart';
import 'screens/mensajeria/pantalla_chat.dart';
import 'widgets/comunes/vista_requerir_login.dart';
import 'models/comunidad.dart';
import 'models/usuario.dart';
import 'models/publicacion.dart';

class ProtectedRoute extends StatefulWidget {
  final Widget child;
  final String title;
  const ProtectedRoute({super.key, required this.child, required this.title});

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  bool? _isLogged;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _isLogged = prefs.getString('auth_token') != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLogged == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
    }
    if (!_isLogged!) return VistaRequerirLogin(titulo: widget.title);
    return widget.child;
  }
}

// Data loaders for Deep Linking
class _ComunidadLoader extends StatefulWidget {
  final int id;
  final Comunidad? extra;
  final VoidCallback onBack;
  const _ComunidadLoader(this.id, this.extra, {required this.onBack});

  @override
  State<_ComunidadLoader> createState() => _ComunidadLoaderState();
}

class _ComunidadLoaderState extends State<_ComunidadLoader> {
  late Future<RespuestaBackend<Comunidad>> _future;

  @override
  void initState() {
    super.initState();
    _future = ServicioComunidades().obtenerComunidad(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extra != null) {
      return PantallaDetalleComunidad(comunidad: widget.extra!, esIntegrada: true, onBack: widget.onBack);
    }
    return FutureBuilder<RespuestaBackend<Comunidad>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFEF5F1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
          );
        }
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetalleComunidad(comunidad: snapshot.data!.datos!, esIntegrada: true, onBack: widget.onBack);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Comunidad no encontrada 😿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: widget.onBack, child: const Text('Volver'))
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PerfilLoader extends StatefulWidget {
  final int id;
  final Usuario? extra;
  final VoidCallback onBack;
  const _PerfilLoader(this.id, this.extra, {required this.onBack});

  @override
  State<_PerfilLoader> createState() => _PerfilLoaderState();
}

class _PerfilLoaderState extends State<_PerfilLoader> {
  late Future<RespuestaBackend<Usuario>> _future;

  @override
  void initState() {
    super.initState();
    _future = ServicioUsuarios().obtenerDatosUsuario(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extra != null) {
      return PantallaDetallePerfil(usuario: widget.extra!, esIntegrada: true, onBack: widget.onBack);
    }
    return FutureBuilder<RespuestaBackend<Usuario>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFEF5F1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
          );
        }
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetallePerfil(usuario: snapshot.data!.datos!, esIntegrada: true, onBack: widget.onBack);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Usuario no encontrado 😿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: widget.onBack, child: const Text('Volver'))
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostLoader extends StatefulWidget {
  final int postId;
  final int comunidadId;
  final Publicacion? extra;
  final VoidCallback? onBack;

  const _PostLoader({required this.postId, required this.comunidadId, this.extra, this.onBack});

  @override
  State<_PostLoader> createState() => _PostLoaderState();
}

class _PostLoaderState extends State<_PostLoader> {
  late Future<RespuestaBackend<Publicacion>> _future;

  @override
  void initState() {
    super.initState();
    _future = ServicioComunidades().obtenerDetallePublicacion(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extra != null) {
      return PantallaDetallePost(post: widget.extra!, onBack: widget.onBack);
    }
    return FutureBuilder<RespuestaBackend<Publicacion>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFEF5F1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
          );
        }
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetallePost(post: snapshot.data!.datos!, onBack: widget.onBack);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Publicación no encontrada 😿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (widget.onBack != null)
                  ElevatedButton(onPressed: widget.onBack, child: const Text('Volver'))
              ],
            ),
          ),
        );
      },
    );
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKeyFeed = GlobalKey<NavigatorState>(debugLabel: 'shellFeed');
final GlobalKey<NavigatorState> _shellNavigatorKeyExplorar = GlobalKey<NavigatorState>(debugLabel: 'shellExplorar');
final GlobalKey<NavigatorState> _shellNavigatorKeyNotificaciones = GlobalKey<NavigatorState>(debugLabel: 'shellNotificaciones');
final GlobalKey<NavigatorState> _shellNavigatorKeyMensajes = GlobalKey<NavigatorState>(debugLabel: 'shellMensajes');
final GlobalKey<NavigatorState> _shellNavigatorKeyTienda = GlobalKey<NavigatorState>(debugLabel: 'shellTienda');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const PantallaLogin(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const PantallaRegistro(),
    ),
    GoRoute(
      path: '/recuperar_contrasena',
      builder: (context, state) => const PantallaRecuperarContrasena(),
    ),
    GoRoute(
      path: '/inventario',
      builder: (context, state) => const ProtectedRoute(
        title: 'Mi Inventario',
        child: PantallaPersonalizarPerfil(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return PantallaInicio(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyFeed,
          routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) {
                return FeedPublicaciones(
                  onComunidadSelected: (c) => context.go('/inicio/comunidades/${c.id}', extra: c),
                  onProfileSelected: (u) => context.go('/inicio/perfiles/${u.id}', extra: u),
                );
              },
              routes: [
                GoRoute(
                  path: 'comunidades/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return _ComunidadLoader(id, state.extra as Comunidad?, onBack: () => context.go('/inicio'));
                  },
                ),
                GoRoute(
                  path: 'comunidades/:id/post/:postId',
                  builder: (context, state) {
                    final comunidadId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    final postId = int.tryParse(state.pathParameters['postId'] ?? '') ?? 0;
                    return _PostLoader(
                      postId: postId,
                      comunidadId: comunidadId,
                      extra: state.extra as Publicacion?,
                      onBack: () => context.go('/inicio/comunidades/$comunidadId'),
                    );
                  },
                ),
                GoRoute(
                  path: 'perfiles/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return _PerfilLoader(id, state.extra as Usuario?, onBack: () => context.go('/inicio'));
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyExplorar,
          routes: [
            GoRoute(
              path: '/explorar',
              builder: (context, state) {
                return PantallaExplorar(
                  onComunidadSelected: (c) =>
                      context.go('/explorar/comunidades/${c.id}', extra: c),
                  onComunidadCreada: () {
                    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                    inicioState?.cargarComunidades();
                  },
                );
              },
              routes: [
                GoRoute(
                  path: 'comunidades/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return _ComunidadLoader(id, state.extra as Comunidad?, onBack: () => context.go('/explorar'));
                  },
                ),
                GoRoute(
                  path: 'comunidades/:id/post/:postId',
                  builder: (context, state) {
                    final comunidadId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    final postId = int.tryParse(state.pathParameters['postId'] ?? '') ?? 0;
                    return _PostLoader(
                      postId: postId,
                      comunidadId: comunidadId,
                      extra: state.extra as Publicacion?,
                      onBack: () => context.go('/explorar/comunidades/$comunidadId'),
                    );
                  },
                ),
                GoRoute(
                  path: 'perfiles/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return _PerfilLoader(id, state.extra as Usuario?, onBack: () => context.go('/explorar'));
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyNotificaciones,
          routes: [
            GoRoute(
              path: '/notificaciones',
              builder: (context, state) {
                return ProtectedRoute(
                  title: 'Tus Notificaciones',
                  child: PantallaNotificaciones(
                    onNotificacionesLeidas: () {
                      final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                      inicioState?.cargarNotificacionesSinLeer();
                    },
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyMensajes,
          routes: [
            GoRoute(
              path: '/mensajes',
              builder: (context, state) {
                return const ProtectedRoute(
                  title: 'Tus Chats',
                  child: PantallaListaChats(),
                );
              },
              routes: [
                GoRoute(
                  path: 'sala/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    final extra = state.extra as Map<String, dynamic>?;
                    final nombre = extra?['nombre'] as String? ?? 'Chat';
                    final salaMap = extra?['sala'] as Map<String, dynamic>?;
                    final otroId = salaMap?['_otro_usuario_id'] as int?;
                    return PantallaChat(
                      salaId: id,
                      nombreSala: nombre,
                      otroUsuarioId: otroId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyTienda,
          routes: [
            GoRoute(
              path: '/tienda',
              builder: (context, state) {
                return ProtectedRoute(
                  title: 'Tu Rincón Michi',
                  child: PantallaTiendaMejoras(
                    esVistaIntegrada: true,
                    onPuntosActualizados: (puntos) {
                      final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                      inicioState?.actualizarPuntos(puntos);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
