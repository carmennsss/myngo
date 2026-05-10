import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/usuario.dart';
import '../../services/servicio_usuarios.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../widgets/boton_idioma.dart';
import 'package:tolgee/tolgee.dart';
import '../../screens/perfiles/pantalla_detalle_perfil.dart' hide Scaffold;
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'package:myngo_app/utils/tr_helper.dart';


class CabeceraPro extends StatelessWidget {
  final bool estaLogueado;
  final String? nombreUsuario;
  final String? avatarUrl;
  final String? marcoUrl;
  final int? miId;
  final int indiceSeleccionado;
  final int? puntos;
  final int notificacionesSinLeer;
  final String estado;
  final int mensajesSinLeer;
  final ValueChanged<int> onNavSelected;
  final Function(Usuario)? onProfileSelected;
  final Function(String)? onStatusChanged;
  final VoidCallback? onRefreshProfile;

  const CabeceraPro({
    super.key,
    required this.estaLogueado,
    required this.nombreUsuario,
    required this.avatarUrl,
    this.marcoUrl,
    this.miId,
    required this.indiceSeleccionado,
    required this.puntos,
    required this.notificacionesSinLeer,
    this.estado = 'DESCONECTADO',
    this.mensajesSinLeer = 0,
    required this.onNavSelected,
    this.onProfileSelected,
    this.onStatusChanged,
    this.onRefreshProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 800;
        final isSmallMobile = screenWidth < 500;

        return Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFC35E34),
                const Color(0xFFD95F43).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC35E34).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isMobile && estaLogueado) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 4),
              ],
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: BotonTactil(
                  onTap: () => onNavSelected(0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_myngo.png',
                        height: isMobile ? 50 : 64,
                        width: isMobile ? 50 : 64,
                        fit: BoxFit.contain,
                      ),
                      if (!isSmallMobile) ...[
                        const SizedBox(width: 14),
                        Text(
                          tr('appTitle'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(color: Colors.black26, offset: const Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
              const Spacer(),
              if (estaLogueado && !isMobile) ...[
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircularNavItem(icon: Icons.explore_rounded, title: tr('navigationExplore'), isActive: indiceSeleccionado == 1, onTap: () => onNavSelected(1)),
                        const SizedBox(width: 8),
                        _CircularNavItem(icon: Icons.storefront_rounded, title: tr('navigationShop'), isActive: indiceSeleccionado == 4, onTap: () => onNavSelected(4)),
                        const SizedBox(width: 8),
                        _CircularNavItem(
                          icon: Icons.chat_bubble_rounded,
                          title: tr('navigationChats'),
                          isActive: indiceSeleccionado == 3,
                          onTap: () => onNavSelected(3),
                          badge: estaLogueado && mensajesSinLeer > 0 ? mensajesSinLeer.toString() : null,
                        ),
                        const SizedBox(width: 8),
                        _CircularNavItem(
                          icon: Icons.notifications_rounded,
                          title: tr('navigationNotifications'),
                          isActive: indiceSeleccionado == 2,
                          onTap: () => onNavSelected(2),
                          badge: estaLogueado && notificacionesSinLeer > 0 ? notificacionesSinLeer.toString() : null,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 24),
              ],
              const BotonIdioma(),
              const SizedBox(width: 8),
              _UserProfileHeader(
                name: nombreUsuario,
                avatarUrl: avatarUrl,
                marcoUrl: marcoUrl,
                estaLogueado: estaLogueado,
                miId: miId,
                estado: estado,
                onProfileSelected: onProfileSelected,
                onStatusChanged: onStatusChanged,
                onRefreshProfile: onRefreshProfile,
                puntos: puntos,
                isMobile: isMobile,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _CircularNavItem({required this.icon, required this.title, this.isActive = false, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFFC35E34), shape: BoxShape.circle),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: isActive ? FontWeight.w900 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _UserProfileHeader extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final String? marcoUrl;
  final bool estaLogueado;
  final int? miId;
  final int? puntos;
  final String estado;
  final Function(Usuario)? onProfileSelected;
  final Function(String)? onStatusChanged;
  final VoidCallback? onRefreshProfile;
  final bool isMobile;

  const _UserProfileHeader({
    this.name, 
    this.avatarUrl, 
    this.marcoUrl,
    required this.estaLogueado, 
    this.miId, 
    this.onProfileSelected, 
    this.onStatusChanged,
    this.onRefreshProfile,
    this.puntos,
    this.estado = 'DESCONECTADO',
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) => _buildContent(context, tr),
    );
  }

  Widget _buildContent(BuildContext context, dynamic tr) {
    if (!estaLogueado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: BotonTactil(
          onTap: () => context.go('/login'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(tr('authLoginButton').toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 70),
      color: Colors.white,
      elevation: 20,
      shadowColor: const Color(0xFFC35E34).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      onSelected: (value) async {
        if (value == 'perfil' && miId != null) {
          final res = await ServicioUsuarios().obtenerDatosUsuario(miId!);
          if (res.exito && res.datos != null && context.mounted) {
            if (onProfileSelected != null) {
              onProfileSelected!(res.datos!);
            } else {
              context.push('/inicio/perfiles/${res.datos!.id}', extra: res.datos);
            }
          }
        } else if (value == 'config') {
          await context.push('/configuracion');
          if (context.mounted && onRefreshProfile != null) {
            onRefreshProfile!();
          }
        } else if (value == 'logout') {
          await ServicioUsuarios().cerrarSesion();
          if (context.mounted) {
            context.read<ChatProvider>().limpiar();
            context.go('/login');
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'perfil', child: Row(children: [const Icon(Icons.person_rounded, color: Color(0xFFC35E34), size: 22), const SizedBox(width: 12), Text(tr('navigationProfile'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)))])),
        PopupMenuItem(value: 'config', child: Row(children: [const Icon(Icons.settings_suggest_rounded, color: Color(0xFFC35E34), size: 22), const SizedBox(width: 12), Text(tr('navigationSettings'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, color: Color(0xFFD95F43), size: 22), const SizedBox(width: 12), Text(tr('navigationLogout'), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFD95F43)))])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? DecorationImage(image: CachedNetworkImageProvider(avatarUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (avatarUrl == null || avatarUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.grey, size: 16) : null,
                  ),
                  if (marcoUrl != null && marcoUrl!.isNotEmpty)
                    Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: IgnorePointer(
                            child: CachedNetworkImage(
                              imageUrl: marcoUrl!,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getColorEstado(estado),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name ?? tr('commonDefaultUsername'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      const SizedBox(width: 6),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTapDown: (details) {
                            final position = details.globalPosition;
                            showMenu<String>(
                              context: context,
                              position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
                              color: Colors.white,
                              elevation: 10,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              items: [
                                PopupMenuItem(
                                  value: 'ACTIVO',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                                      const SizedBox(width: 8),
                                      Text(tr('statusActive'), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'OCUPADO',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, color: Colors.redAccent, size: 12),
                                      const SizedBox(width: 8),
                                      Text(tr('statusBusy'), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                                    ],
                                  ),
                                ),
                              ],
                            ).then((nuevoEstado) {
                              if (nuevoEstado != null && onStatusChanged != null) {
                                onStatusChanged!(nuevoEstado);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  estado == 'ACTIVO' ? tr('statusActive') : (estado == 'OCUPADO' ? tr('statusBusy') : tr('statusOffline')),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(tr('rankPoints', {'count': puntos?.toString() ?? '0'}), style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
            ],
            if (isMobile) ...[
              const SizedBox(width: 4),
              const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Colors.greenAccent;
      case 'OCUPADO':
        return Colors.redAccent;
      case 'DESCONECTADO':
      default:
        return Colors.grey.shade400;
    }
  }
}
