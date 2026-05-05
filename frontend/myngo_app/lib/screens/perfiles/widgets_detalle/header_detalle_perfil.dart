import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/usuario.dart';
import '../../inicio/pantalla_inicio.dart';
import '../../../widgets/boton_idioma.dart';

/// Widget que muestra la cabecera visual de un perfil (fondo, avatar, marco y estado).
class HeaderDetallePerfil extends StatelessWidget {
  final Usuario usuario;
  final String? avatarLocal;
  final String? fondoLocal;
  final String? fondoPerfilLocal;
  final String? marcoLocal;
  final int? currentUserId;
  final VoidCallback? onEditarAvatar;
  final VoidCallback? onEditarPerfil;
  final VoidCallback? onBack;
  final bool esIntegrada;

  const HeaderDetallePerfil({
    super.key,
    required this.usuario,
    this.avatarLocal,
    this.fondoLocal,
    this.fondoPerfilLocal,
    this.marcoLocal,
    this.currentUserId,
    this.onEditarAvatar,
    this.onBack,
    this.onEditarPerfil,
    this.esIntegrada = false,
  });

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Colors.greenAccent;
      case 'OCUPADO':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final Color colorCard = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final Color colorGradTop =
        esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFF5EBE6);

    final String inicial = usuario.nombreUsuario.isNotEmpty
        ? usuario.nombreUsuario[0].toUpperCase()
        : '?';

    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      stretch: true,
      backgroundColor: colorCard,
      surfaceTintColor: Colors.transparent,
      leading: esIntegrada
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: onBack,
            )
          : null,
      actions: [
        if (currentUserId == usuario.id)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: Colors.white, size: 22),
              ),
              onPressed: onEditarPerfil,
              tooltip: 'Personalizar Perfil',
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo de pantalla (usa fondoPerfilLocal primero, luego fondoLocal como fallback)
            if (fondoPerfilLocal != null && fondoPerfilLocal!.isNotEmpty)
              Image.network(
                fondoPerfilLocal!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(color: colorGradTop),
              )
            else if (fondoLocal != null && fondoLocal!.isNotEmpty)
              Image.network(
                fondoLocal!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(color: colorGradTop),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorGradTop, colorGradTop.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Avatar centrado
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: currentUserId == usuario.id ? onEditarAvatar : null,
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. EL AVATAR (Capa inferior)
                          Container(
                            width: 110, // Reducido un poco para que el marco respire
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: (marcoLocal == null || marcoLocal!.isEmpty)
                                  ? Border.all(
                                      color: const Color(0xFF248EA6), width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: (avatarLocal != null && avatarLocal!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      avatarLocal!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.grey),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      inicial,
                                      style: const TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF248EA6),
                                      ),
                                    ),
                                  ),
                          ),

                          // 2. EL MARCO (Capa superior - Overlay)
                          if (marcoLocal != null && marcoLocal!.isNotEmpty)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Image.network(
                                  marcoLocal!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                          // 3. INDICADOR DE ESTADO
                          _StatusIndicator(
                            usuario: usuario,
                            currentUserId: currentUserId,
                            colorCard: colorCard,
                            getColorEstado: _getColorEstado,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (currentUserId == usuario.id)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onEditarAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF28B50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final Usuario usuario;
  final int? currentUserId;
  final Color colorCard;
  final Color Function(String) getColorEstado;

  const _StatusIndicator({
    required this.usuario,
    this.currentUserId,
    required this.colorCard,
    required this.getColorEstado,
  });

  @override
  Widget build(BuildContext context) {
    String displayEstado = usuario.estado ?? 'DESCONECTADO';
    try {
      final inicioState =
          context.findAncestorStateOfType<PantallaInicioState>();
      if (inicioState != null && inicioState.miId == usuario.id) {
        displayEstado = inicioState.miEstado;
      }
    } catch (_) {}

    return Positioned(
      bottom: 15,
      right: 15,
      child: MouseRegion(
        cursor: usuario.id == currentUserId
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: usuario.id == currentUserId
              ? (details) {
                  final position = details.globalPosition;
                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                        position.dx, position.dy, position.dx, position.dy),
                    color: Colors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    items: [
                      _buildMenuItem('ACTIVO', 'Activo', Colors.greenAccent),
                      _buildMenuItem('OCUPADO', 'Ocupado', Colors.redAccent),
                    ],
                  ).then((nuevoEstado) {
                    if (nuevoEstado != null) {
                      final inicioState =
                          context.findAncestorStateOfType<PantallaInicioState>();
                      inicioState?.cambiarEstado(nuevoEstado);
                    }
                  });
                }
              : null,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: getColorEstado(displayEstado),
              shape: BoxShape.circle,
              border: Border.all(color: colorCard, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4440))),
        ],
      ),
    );
  }
}
