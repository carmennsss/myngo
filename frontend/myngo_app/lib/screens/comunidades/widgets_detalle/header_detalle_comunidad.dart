import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/comunidad.dart';
import '../../../services/servicio_comunidades.dart';
import '../pantalla_admin_comunidad.dart';
import '../pantalla_personalizacion_comunidad.dart';
import '../../../utils/configuracion.dart';

/// Widget que muestra la cabecera visual de una comunidad (portada, avatar y rol).
class HeaderDetalleComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int? miId;
  final VoidCallback onCerrar;
  final Function(Comunidad)? onComunidadActualizada;

  const HeaderDetalleComunidad({
    super.key,
    required this.comunidad,
    this.miId,
    required this.onCerrar,
    this.onComunidadActualizada,
  });

  @override
  State<HeaderDetalleComunidad> createState() => _HeaderDetalleComunidadState();
}

class _HeaderDetalleComunidadState extends State<HeaderDetalleComunidad> {
  String _miRol = 'Miembro';
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  @override
  void didUpdateWidget(HeaderDetalleComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _obtenerRol();
    }
  }

  Future<void> _obtenerRol() async {
    if (!mounted) return;
    setState(() => _cargandoRol = true);
    if (widget.miId == null) {
      if (mounted) setState(() => _cargandoRol = false);
      return;
    }
    final res = await ServicioComunidades()
        .obtenerRolUsuarioEnComunidad(widget.comunidad.id, widget.miId!);
    if (mounted) {
      setState(() {
        _miRol = res.datos ?? 'Miembro';
        _cargandoRol = false;
      });
    }
  }

  TextStyle _getEstiloComunidad({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    final fuente = widget.comunidad.fuenteComunidad ?? 'Outfit';
    try {
      return GoogleFonts.getFont(
        fuente,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    } catch (e) {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador =
        widget.miId != null && widget.miId == widget.comunidad.creadorId;
    final rolLabel = esCreador ? 'Creador' : _miRol;
    final iconRol = esCreador
        ? Icons.stars_rounded
        : (rolLabel == 'Moderador'
            ? Icons.gavel_rounded
            : Icons.pets_rounded);
    final colorRol = esCreador
        ? Colors.amber
        : (rolLabel == 'Moderador'
            ? const Color(0xFF248EA6)
            : const Color(0xFFC35E34));

    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Stack(
        children: [
          // Fondo con imagen de portada
          if (widget.comunidad.urlPortada.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.comunidad.urlPortada.startsWith('http') 
                    ? widget.comunidad.urlPortada 
                    : Uri.encodeFull('${Configuracion.baseUrl}${widget.comunidad.urlPortada.startsWith('/') ? '' : '/'}${widget.comunidad.urlPortada}'),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Container(color: widget.comunidad.colorTema),
              ),
            )
          else
            Positioned.fill(child: Container(color: widget.comunidad.colorTema)),

          // Degradado para legibilidad
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Botones de acción (Personalizar, Ajustes, Cerrar)
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (esCreador || _miRol == 'Moderador') ...[
                  _ActionButton(
                    icon: Icons.palette_rounded,
                    tooltip: 'Personalización Visual',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaPersonalizacionComunidad(
                            comunidad: widget.comunidad,
                            onComunidadActualizada: () {
                              if (widget.onComunidadActualizada != null) {
                                widget.onComunidadActualizada!(widget.comunidad);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.settings_rounded,
                    tooltip: 'Administrar Comunidad',
                    onPressed: () async {
                      final actualizada = await Navigator.push<Comunidad>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PantallaAdminComunidad(comunidad: widget.comunidad),
                        ),
                      );
                      if (actualizada != null &&
                          widget.onComunidadActualizada != null) {
                        widget.onComunidadActualizada!(actualizada);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Cerrar vista',
                  onPressed: widget.onCerrar,
                ),
              ],
            ),
          ),

          // Información de la comunidad (Avatar, Nombre, Rol)
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CommunityAvatar(comunidad: widget.comunidad),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.comunidad.nombre,
                        style: _getEstiloComunidad(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          shadows: const [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 2))
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(
                          rolLabel: rolLabel,
                          iconRol: iconRol,
                          colorRol: colorRol),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  final Comunidad comunidad;

  const _CommunityAvatar({required this.comunidad});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comunidad.urlAvatar;
    final portadaUrl = comunidad.urlPortada;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)
        ],
        image: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  avatarUrl.startsWith('http') ? avatarUrl : Uri.encodeFull('${Configuracion.baseUrl}${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl'),
                ),
                fit: BoxFit.cover,
              )
            : (portadaUrl.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      portadaUrl.startsWith('http') ? portadaUrl : Uri.encodeFull('${Configuracion.baseUrl}${portadaUrl.startsWith('/') ? '' : '/'}$portadaUrl'),
                    ),
                    fit: BoxFit.cover,
                  )
                : null),
      ),
      child: (avatarUrl == null || avatarUrl.isEmpty) && portadaUrl.isEmpty
          ? const Icon(Icons.groups_rounded, color: Colors.white, size: 40)
          : null,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String rolLabel;
  final IconData iconRol;
  final Color colorRol;

  const _RoleBadge({
    required this.rolLabel,
    required this.iconRol,
    required this.colorRol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorRol.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconRol, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            rolLabel.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
