import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myngo_app/services/servicio_comunidades.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';

import 'package:myngo_app/screens/login/pantalla_login.dart';
import 'package:myngo_app/screens/registro/pantalla_registro.dart';
import 'package:myngo_app/screens/recuperar_contrasena/pantalla_recuperar_contrasena.dart';
import 'package:myngo_app/screens/inicio/pantalla_inicio.dart';
import 'package:myngo_app/screens/comunidades/pantalla_detalle_comunidad.dart';
import 'package:myngo_app/screens/comunidades/pantalla_detalle_post.dart';
import 'package:myngo_app/screens/perfiles/pantalla_detalle_perfil.dart';
import 'package:myngo_app/screens/perfiles/pantalla_personalizar_perfil.dart';

// Components inside the Shell
import 'package:myngo_app/widgets/inicio/feed_publicaciones.dart';
import 'package:myngo_app/screens/explorar/pantalla_explorar.dart';
import 'package:myngo_app/screens/notificaciones/pantalla_notificaciones.dart';
import 'package:myngo_app/screens/perfiles/pantalla_tienda_mejoras.dart';
import 'package:myngo_app/screens/mensajeria/pantalla_lista_chats.dart';
import 'package:myngo_app/screens/mensajeria/pantalla_chat.dart';
import 'package:myngo_app/widgets/comunes/vista_requerir_login.dart';
import 'package:myngo_app/models/comunidad.dart';
import 'package:myngo_app/models/usuario.dart';
import 'package:myngo_app/models/publicacion.dart';

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
                  onComunidadSelected: (c) => context.go('/inicio/comunidades/${c.nombre}', extra: c),
                  onProfileSelected: (u) => context.go('/inicio/perfiles/${u.nombreUsuario}', extra: u),
                );
              },
              routes: [
                GoRoute(
                  path: 'comunidades/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return PantallaDetalleComunidad(
                      key: ValueKey('init-com-$id'),
                      idOrName: id,
                      comunidad: state.extra as Comunidad?,
                      esIntegrada: true,
                      onBack: () => context.go('/inicio'),
                    );
                  },
                ),
                GoRoute(
                  path: 'comunidades/:id/post/:postId',
                  builder: (context, state) {
                    final postId = int.tryParse(state.pathParameters['postId'] ?? '') ?? 0;
                    return PantallaDetallePost(
                      key: ValueKey('init-post-$postId'),
                      id: postId,
                      post: state.extra as Publicacion?,
                      onBack: () {
                        final id = state.pathParameters['id'];
                        context.go('/inicio/comunidades/$id');
                      },
                    );
                  },
                ),
                GoRoute(
                  path: 'perfiles/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return PantallaDetallePerfil(
                      key: ValueKey('init-perf-$id'),
                      idOrUsername: id,
                      usuario: state.extra as Usuario?,
                      esIntegrada: true,
                      onBack: () => context.go('/inicio'),
                    );
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
                      context.go('/explorar/comunidades/${c.nombre}', extra: c),
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
                    final id = state.pathParameters['id'] ?? '';
                    return PantallaDetalleComunidad(
                      key: ValueKey('expl-com-$id'),
                      idOrName: id,
                      comunidad: state.extra as Comunidad?,
                      esIntegrada: true,
                      onBack: () => context.go('/explorar'),
                    );
                  },
                ),
                GoRoute(
                  path: 'comunidades/:id/post/:postId',
                  builder: (context, state) {
                    final postId = int.tryParse(state.pathParameters['postId'] ?? '') ?? 0;
                    return PantallaDetallePost(
                      key: ValueKey('expl-post-$postId'),
                      id: postId,
                      post: state.extra as Publicacion?,
                      onBack: () {
                        final id = state.pathParameters['id'];
                        context.go('/explorar/comunidades/$id');
                      },
                    );
                  },
                ),
                GoRoute(
                  path: 'perfiles/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return PantallaDetallePerfil(
                      key: ValueKey('expl-perf-$id'),
                      idOrUsername: id,
                      usuario: state.extra as Usuario?,
                      esIntegrada: true,
                      onBack: () => context.go('/explorar'),
                    );
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
                    final comunidadId = extra?['comunidad_id'] as int?;
                    return PantallaChat(
                      salaId: id,
                      nombreSala: nombre,
                      otroUsuarioId: otroId,
                      comunidadId: comunidadId,
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
