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
class _ComunidadLoader extends StatelessWidget {
  final int id;
  final Comunidad? extra;
  final VoidCallback onBack;
  const _ComunidadLoader(this.id, this.extra, {required this.onBack});

  @override
  Widget build(BuildContext context) {
    if (extra != null) {
      return PantallaDetalleComunidad(comunidad: extra!, esIntegrada: true, onBack: onBack);
    }
    return FutureBuilder(
      future: ServicioComunidades().obtenerComunidad(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetalleComunidad(comunidad: snapshot.data!.datos!, esIntegrada: true, onBack: onBack);
        }
        return const Center(child: Text('Comunidad no encontrada 😿'));
      },
    );
  }
}

class _PerfilLoader extends StatelessWidget {
  final int id;
  final Usuario? extra;
  final VoidCallback onBack;
  const _PerfilLoader(this.id, this.extra, {required this.onBack});

  @override
  Widget build(BuildContext context) {
    if (extra != null) {
      return PantallaDetallePerfil(usuario: extra!, esIntegrada: true, onBack: onBack);
    }
    return FutureBuilder(
      future: ServicioUsuarios().obtenerDatosUsuario(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetallePerfil(usuario: snapshot.data!.datos!, esIntegrada: true, onBack: onBack);
        }
        return const Center(child: Text('Usuario no encontrado 😿'));
      },
    );
  }
}

class _PostLoader extends StatelessWidget {
  final int postId;
  final int comunidadId;
  final Publicacion? extra;
  final VoidCallback? onBack;

  const _PostLoader({required this.postId, required this.comunidadId, this.extra, this.onBack});

  @override
  Widget build(BuildContext context) {
    if (extra != null) {
      return PantallaDetallePost(post: extra!, onBack: onBack);
    }
    return FutureBuilder(
      future: ServicioComunidades().obtenerDetallePublicacion(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFEF5F1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
          );
        }
        if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
          return PantallaDetallePost(post: snapshot.data!.datos!, onBack: onBack);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Publicación no encontrada 😿')),
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
                    return PantallaChat(
                      salaId: id,
                      nombreSala: nombre,
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
