import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/usuario.dart';
import '../../services/servicio_usuarios.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../screens/perfiles/pantalla_detalle_perfil.dart';

/// Cabecera superior de la pantalla de inicio con logo, navegación y perfil de usuario.
class CabeceraPro extends StatelessWidget {
  final bool estaLogueado;
  final String? nombreUsuario;
  final String? avatarUrl;
  final int? miId;
  final int indiceSeleccionado;
  final int? puntos;
  final int notificacionesSinLeer;
  final ValueChanged<int> onNavSelected;
  final Function(Usuario)? onProfileSelected;

  const CabeceraPro({
    super.key,
    required this.estaLogueado,
    required this.nombreUsuario,
    required this.avatarUrl,
    this.miId,
    required this.indiceSeleccionado,
    required this.puntos,
    required this.notificacionesSinLeer,
    required this.onNavSelected,
    this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC35E34), Color(0xFFE89A6A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: BotonTactil(
              onTap: () => onNavSelected(0),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Colors.white, size: 34),
                  const SizedBox(width: 14),
                  Text('MYNGO', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (estaLogueado) ...[
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularNavItem(icon: Icons.explore_rounded, title: 'Explorar', isActive: indiceSeleccionado == 1, onTap: () => onNavSelected(1)),
                    const SizedBox(width: 12),
                    _CircularNavItem(icon: Icons.chat_bubble_rounded, title: 'Chats', isActive: indiceSeleccionado == 3, onTap: () => onNavSelected(3)),
                    const SizedBox(width: 12),
                    _CircularNavItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notificaciones',
                      isActive: indiceSeleccionado == 2,
                      onTap: () => onNavSelected(2),
                      badge: estaLogueado && notificacionesSinLeer > 0 ? notificacionesSinLeer.toString() : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
          _UserProfileHeader(
            name: nombreUsuario,
            avatarUrl: avatarUrl,
            estaLogueado: estaLogueado,
            miId: miId,
            onProfileSelected: onProfileSelected,
            puntos: puntos,
          ),
        ],
      ),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 22),
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
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: isActive ? FontWeight.w900 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _UserProfileHeader extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final bool estaLogueado;
  final int? miId;
  final int? puntos;
  final Function(Usuario)? onProfileSelected;

  const _UserProfileHeader({this.name, this.avatarUrl, required this.estaLogueado, this.miId, this.onProfileSelected, this.puntos});

  @override
  Widget build(BuildContext context) {
    if (!estaLogueado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: BotonTactil(
          onTap: () => Navigator.pushNamed(context, '/login'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('INICIAR SESIÓN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
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
              await Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetallePerfil(usuario: res.datos!)));
            }
          }
        } else if (value == 'config') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajustes próximamente 🐾')));
        } else if (value == 'logout') {
          await ServicioUsuarios().cerrarSesion();
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'perfil', child: Row(children: [const Icon(Icons.person_rounded, color: Color(0xFFC35E34), size: 22), const SizedBox(width: 12), Text('Mi Perfil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)))])),
        PopupMenuItem(value: 'config', child: Row(children: [const Icon(Icons.settings_suggest_rounded, color: Color(0xFFC35E34), size: 22), const SizedBox(width: 12), Text('Configuración', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, color: Color(0xFFD95F43), size: 22), const SizedBox(width: 12), Text('Cerrar Miau-Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFD95F43)))])),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
                image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: (avatarUrl == null || avatarUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Michi', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('${puntos ?? 0} Puntos', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
