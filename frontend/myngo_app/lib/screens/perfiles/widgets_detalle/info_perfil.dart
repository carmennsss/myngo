import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/estilo_post_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tolgee/tolgee.dart';
import '../pantalla_personalizar_perfil.dart';
import '../../../models/usuario.dart';
import '../../../providers/chat_provider.dart';
import '../../inicio/pantalla_inicio.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Widget que muestra la información textual y acciones de un perfil.
class InfoPerfil extends StatelessWidget {
  final Usuario usuario;
  final int? currentUserId;
  final String? biografiaLocal;
  final String? estadoSeguimiento;
  final bool isLoading;
  final String? rolEnComunidad;
  final double ratingLocal;
  final bool haVotadoHoy;
  final String tiempoParaReinicio;
  final VoidCallback onManejarSeguimiento;
  final VoidCallback onMostrarVoto;
  final VoidCallback onEditarBio;
  final VoidCallback onChat;

  const InfoPerfil({
    super.key,
    required this.usuario,
    this.currentUserId,
    this.biografiaLocal,
    this.estadoSeguimiento,
    required this.isLoading,
    this.rolEnComunidad,
    required this.ratingLocal,
    required this.haVotadoHoy,
    required this.tiempoParaReinicio,
    required this.onManejarSeguimiento,
    required this.onMostrarVoto,
    required this.onEditarBio,
    required this.onChat,
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
    final Color colorTextoP = esOscuro ? Colors.white : const Color(0xFF2D2D2D);
    final Color colorTextoS =
        esOscuro ? Colors.grey.shade400 : Colors.grey.shade600;

    final String fecha =
        DateFormat('dd MMM yyyy').format(usuario.fechaRegistro);
    
    final Color themeColor = EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6);
    final String fontFamily = usuario.fuentePerfil;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameRow(colorTextoP),
          const SizedBox(height: 4),
          _buildStatusLabel(context),
          if (rolEnComunidad != null) _buildRoleBadge(colorTextoP),
          const SizedBox(height: 16),
          _buildBioSection(colorTextoP, colorTextoS),
          const SizedBox(height: 20),
          _buildStatsRow(colorTextoS, fecha),
          const SizedBox(height: 24),
          _buildActionButtons(context, themeColor),
        ],
      ),
    );
  }

  Widget _buildNameRow(Color colorTextoP) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '@${usuario.nombreUsuario}',
            style: GoogleFonts.getFont(
              usuario.fuentePerfil,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: colorTextoP,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (usuario.esVerificado) ...[
          const SizedBox(width: 8),
          Icon(Icons.verified_rounded, size: 22, color: EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)),
        ],
      ],
    );
  }

  Widget _buildStatusLabel(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProv, _) {
        String displayEstado = chatProv.getEstadoUsuario(usuario.id);
        

        try {
          final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
          if (inicioState != null && inicioState.miId == usuario.id) {
            displayEstado = inicioState.miEstado;
          }
        } catch (_) {}

        final color = _getColorEstado(displayEstado);
        final bool esPropio = currentUserId == usuario.id;

        return Builder(builder: (context) {
        return Builder(
            builder: (statusContext) {
              return GestureDetector(
                onTapDown: esPropio
                    ? (details) {
                        final RenderBox box = statusContext.findRenderObject() as RenderBox;
                        final RenderBox overlay = Overlay.of(statusContext).context.findRenderObject() as RenderBox;
                        final RelativeRect position = RelativeRect.fromRect(
                          Rect.fromPoints(
                            box.localToGlobal(Offset.zero, ancestor: overlay),
                            box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
                          ),
                          Offset.zero & overlay.size,
                        );

                        showMenu<String>(
                          context: statusContext,
                          position: position,
                          color: Colors.white,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          items: [
                            _buildStatusMenuItem('ACTIVO', tr('statusActive'), Colors.greenAccent),
                            _buildStatusMenuItem('OCUPADO', tr('statusBusy'), Colors.redAccent),
                          ],
                        ).then((nuevoEstado) {
                          if (nuevoEstado != null) {
                            final inicioState =
                                statusContext.findAncestorStateOfType<PantallaInicioState>();
                            inicioState?.cambiarEstado(nuevoEstado);
                          }
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayEstado == 'ACTIVO'
                            ? tr('statusActive')
                            : (displayEstado == 'OCUPADO' ? tr('statusBusy') : tr('statusOffline')),
                        style: GoogleFonts.getFont(
                          usuario.fuentePerfil,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      if (esPropio) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(
      String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.getFont(
                  usuario.fuentePerfil,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4440))),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(Color colorTextoP) {
    final Color themeColor = EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: themeColor, size: 14),
          const SizedBox(width: 6),
          Text(
            rolEnComunidad!.toUpperCase(),
            style: GoogleFonts.getFont(
              usuario.fuentePerfil,
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(Color colorTextoP, Color colorTextoS) {
    final bool esPropio = currentUserId != null && currentUserId == usuario.id;
    
    return TranslationWidget(
      builder: (context, tr) => GestureDetector(
        onTap: esPropio ? onEditarBio : null,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (biografiaLocal == null || biografiaLocal!.isEmpty) ? tr('profileBioEmpty') : biografiaLocal!,
              style: GoogleFonts.getFont(
                usuario.fuentePerfil,
                fontSize: 16,
                height: 1.5,
                color: colorTextoP.withOpacity(0.9),
              ),
            ),
            if (esPropio)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 16, color: colorTextoS),
                    const SizedBox(width: 4),
                    Text(
                      tr('profileBioTapToEdit'),
                      style: GoogleFonts.getFont(usuario.fuentePerfil, fontSize: 11, color: colorTextoS, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Color colorTextoS, String fecha) {
    return TranslationWidget(
      builder: (context, tr) => Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: colorTextoS),
          const SizedBox(width: 6),
          Text(
            tr('profileJoined', {'date': fecha}),
            style: GoogleFonts.getFont(usuario.fuentePerfil, fontSize: 13, color: colorTextoS),
          ),
        ],
      ),
    );
  }  Widget _buildActionButtons(BuildContext context, Color themeColor) {
    if (currentUserId == null) return const SizedBox.shrink();
    final bool esPropio = currentUserId == usuario.id;
    if (esPropio) return const SizedBox.shrink();

    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final Color surface = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final Color border = esOscuro ? Colors.white12 : Colors.black12;

    return Row(
      children: [

        TranslationWidget(
          builder: (context, tr) => _SmallButton(
            label: _getFollowText(tr),
            icon: estadoSeguimiento == 'ACEPTADO'
                ? Icons.check_rounded
                : (estadoSeguimiento == 'SOLICITUD'
                    ? Icons.hourglass_top_rounded
                    : Icons.person_add_rounded),
            color: estadoSeguimiento == 'ACEPTADO'
                ? Colors.grey.shade600
                : (estadoSeguimiento == 'SOLICITUD'
                    ? Colors.grey.shade500
                    : themeColor),
            isLoading: isLoading,
            onPressed: onManejarSeguimiento,
            fuentePerfil: usuario.fuentePerfil,
          ),
        ),
        const SizedBox(width: 8),

        _CircularAction(icon: Icons.chat_bubble_outline_rounded, onPressed: onChat),
        const SizedBox(width: 8),

        GestureDetector(
          onTap: onMostrarVoto,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: haVotadoHoy
                  ? (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)).withOpacity(0.1)
                  : (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)).withOpacity(haVotadoHoy ? 0.4 : 0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  haVotadoHoy ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: haVotadoHoy ? (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)) : Colors.white,
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ratingLocal.toStringAsFixed(1),
                      style: GoogleFonts.getFont(
                        usuario.fuentePerfil,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: haVotadoHoy ? (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)) : Colors.white,
                        height: 1.0,
                      ),
                    ),
                    if (haVotadoHoy && tiempoParaReinicio.isNotEmpty)
                      Text(
                        tiempoParaReinicio,
                        style: GoogleFonts.getFont(
                          usuario.fuentePerfil,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)).withOpacity(0.7),
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                TranslationWidget(
                  builder: (context, tr) => Text(
                    haVotadoHoy ? tr('profileVoteEdit') : tr('profileVoteNew'),
                    style: GoogleFonts.getFont(
                      usuario.fuentePerfil,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: haVotadoHoy ? (EstiloPostHelper.parseHex(usuario.colorTema) ?? const Color(0xFF248EA6)) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _getFollowGradient() {
    if (estadoSeguimiento == 'ACEPTADO') {
      return LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade700]);
    }
    if (estadoSeguimiento == 'SOLICITUD') {
      return LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade600]);
    }
    return const LinearGradient(
      colors: [Color(0xFFF28B50), Color(0xFFF29C50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getFollowText(dynamic tr) {
    if (estadoSeguimiento == 'ACEPTADO') return tr('profileFollowFollowing');
    if (estadoSeguimiento == 'SOLICITUD') return tr('profileFollowPending');
    if (!usuario.esPublico) return tr('profileFollowRequest');
    return tr('profileFollowFollow');
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? fuentePerfil;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
    this.fuentePerfil,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isLoading
              ? [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))]
              : [
                  Icon(icon, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.getFont(
                      fuentePerfil ?? 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? fuentePerfil;

  const _ActionButton({
    required this.label,
    required this.gradient,
    required this.isLoading,
    required this.onPressed,
    this.fuentePerfil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    label,
                    style: GoogleFonts.getFont(
                      fuentePerfil ?? 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircularAction({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: esOscuro ? Colors.white12 : Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Icon(icon, color: esOscuro ? Colors.white : Colors.black87, size: 18),
        ),
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  final double rating;
  final bool haVotado;
  final VoidCallback onPressed;

  const _RateBadge({
    required this.rating,
    required this.haVotado,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final Color colorP = const Color(0xFF248EA6);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: haVotado
            ? (esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
            : colorP.withOpacity(0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: haVotado
              ? (esOscuro ? Colors.white12 : Colors.black12)
              : colorP.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded,
                  color: haVotado ? Colors.grey : colorP,
                  size: 20),
              const SizedBox(width: 6),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: haVotado ? Colors.grey : (esOscuro ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
