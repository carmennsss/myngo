import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/usuario.dart';
import '../../inicio/pantalla_inicio.dart';

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
          _buildActionButtons(context),
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
            style: GoogleFonts.inter(
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
          const Icon(Icons.verified_rounded, size: 22, color: Color(0xFF248EA6)),
        ],
      ],
    );
  }

  Widget _buildStatusLabel(BuildContext context) {
    String displayEstado = usuario.estado ?? 'DESCONECTADO';
    try {
      final inicioState =
          context.findAncestorStateOfType<PantallaInicioState>();
      if (inicioState != null && inicioState.miId == usuario.id) {
        displayEstado = inicioState.miEstado;
      }
    } catch (_) {}

    final color = _getColorEstado(displayEstado);
    final bool esPropio = currentUserId == usuario.id;

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
                      _buildStatusMenuItem('ACTIVO', 'Activo', Colors.greenAccent),
                      _buildStatusMenuItem('OCUPADO', 'Ocupado', Colors.redAccent),
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
                      ? 'Activo'
                      : (displayEstado == 'OCUPADO' ? 'Ocupado' : 'Desconectado'),
                  style: GoogleFonts.inter(
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
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4440))),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(Color colorTextoP) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF248EA6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF248EA6).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFF248EA6), size: 14),
          const SizedBox(width: 6),
          Text(
            rolEnComunidad!.toUpperCase(),
            style: GoogleFonts.outfit(
              color: const Color(0xFF248EA6),
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
    
    return GestureDetector(
      onTap: esPropio ? onEditarBio : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (biografiaLocal == null || biografiaLocal!.isEmpty) ? 'Sin biografía' : biografiaLocal!,
            style: GoogleFonts.inter(
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
                    'Toca para editar biografía',
                    style: GoogleFonts.inter(fontSize: 11, color: colorTextoS, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Color colorTextoS, String fecha) {
    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: colorTextoS),
        const SizedBox(width: 6),
        Text(
          'Se unió en $fecha',
          style: GoogleFonts.inter(fontSize: 13, color: colorTextoS),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (currentUserId == null) {
      return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final bool esPropio = currentUserId == usuario.id;

    return Row(
      children: [
        if (!esPropio) ...[
          _ActionButton(
            label: _getFollowText(),
            color: _getFollowColor(),
            isLoading: isLoading,
            onPressed: onManejarSeguimiento,
          ),
          const SizedBox(width: 12),
          _CircularAction(icon: Icons.chat_bubble_outline, onPressed: onChat),
          const SizedBox(width: 12),
          _ActionButton(
            label: haVotadoHoy ? tiempoParaReinicio : 'Votar',
            color: haVotadoHoy ? Colors.grey.shade600 : const Color(0xFF248EA6),
            isLoading: false,
            onPressed: haVotadoHoy ? () {} : onMostrarVoto,
          ),
          const SizedBox(width: 12),
        ],
        _RateButton(
          rating: ratingLocal,
          haVotado: haVotadoHoy,
          tiempoRestante: tiempoParaReinicio,
          onPressed: onMostrarVoto,
        ),
      ],
    );
  }

  String _getFollowText() {
    if (estadoSeguimiento == 'ACEPTADO') return 'Siguiendo';
    if (estadoSeguimiento == 'SOLICITUD') return 'Pendiente';
    return 'Seguir';
  }

  Color _getFollowColor() {
    if (estadoSeguimiento == 'ACEPTADO') return Colors.grey.shade800;
    if (estadoSeguimiento == 'SOLICITUD') return Colors.grey.shade700;
    return const Color(0xFFF28B50);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(
              label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: Colors.white),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final double rating;
  final bool haVotado;
  final String tiempoRestante;
  final VoidCallback onPressed;

  const _RateButton({
    required this.rating,
    required this.haVotado,
    required this.tiempoRestante,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: haVotado
              ? Colors.grey.withOpacity(0.1)
              : const Color(0xFF248EA6).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: haVotado
                  ? Colors.grey.withOpacity(0.3)
                  : const Color(0xFF248EA6).withOpacity(0.4),
              width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: haVotado ? Colors.grey : const Color(0xFF248EA6),
                    size: 20),
                const SizedBox(width: 6),
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: haVotado ? Colors.grey : Colors.white,
                  ),
                ),
              ],
            ),
            if (haVotado)
              Text(
                tiempoRestante,
                style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
