import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../models/comunidad.dart';
import '../../../services/servicio_comunidades.dart';
import '../pantalla_admin_comunidad.dart';
import '../pantalla_personalizacion_comunidad.dart';
import '../../../utils/configuracion.dart';
import 'package:tolgee/tolgee.dart';
import '../../inicio/pantalla_inicio.dart';

import '../../../widgets/comunes/profile_preview.dart';

/// Widget que muestra la cabecera visual de una comunidad (portada, avatar y rol).
class HeaderDetalleComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int? miId;
  final VoidCallback onCerrar;
  final Function(Comunidad)? onComunidadActualizada;
  final String Function(String) tr;

  const HeaderDetalleComunidad({
    super.key,
    required this.comunidad,
    this.miId,
    required this.onCerrar,
    this.onComunidadActualizada,
    required this.tr,
  });

  @override
  State<HeaderDetalleComunidad> createState() => _HeaderDetalleComunidadState();
}

class _HeaderDetalleComunidadState extends State<HeaderDetalleComunidad> {
  String _miRol = 'Visitante';
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  @override
  void didUpdateWidget(HeaderDetalleComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id || oldWidget.miId != widget.miId) {
      _obtenerRol();
    }
  }

  Future<void> _obtenerRol() async {
    if (!mounted) return;
    setState(() => _cargandoRol = true);
    if (widget.miId == null) {
      if (mounted) setState(() {
        _miRol = 'Visitante';
        _cargandoRol = false;
      });
      return;
    }
    final res = await ServicioComunidades()
        .obtenerRolUsuarioEnComunidad(widget.comunidad.id, widget.miId!);
    if (mounted) {
      setState(() {
        String rolObtenido = res.datos ?? 'Visitante';
        // Sincronizamos el objeto comunidad con la realidad del servidor
        widget.comunidad.esMiembro = (rolObtenido != 'Visitante');
        
        // Normalizar: el backend devuelve 'Administrador' para el creador
        if (rolObtenido.toLowerCase() == 'administrador') rolObtenido = 'Creador';
        _miRol = rolObtenido;
        _cargandoRol = false;
      });
    }
  }

  void _confirmarSalida(BuildContext context) {
    // Función de seguridad para traducciones en caliente
    String safeTr(String key, String fallback) {
      try {
        return widget.tr(key);
      } catch (e) {
        print('DEBUG: Error en traducción "$key", usando fallback');
        return fallback;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(safeTr('communityLeaveTitle', 'Abandonar comunidad'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(safeTr('communityLeaveConfirm', '¿Estás seguro de que quieres dejar esta comunidad?'), style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(safeTr('commonCancel', 'Cancelar'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cerrar diálogo
              
              final comunidadId = widget.comunidad.id;
              print('UI DEBUG: Iniciando proceso para abandonar comunidad $comunidadId');
              
              // SALIDA INMEDIATA Y ABSOLUTA
              widget.onCerrar();
              if (context.mounted) {
                print('UI DEBUG: Forzando navegación a Inicio');
                try {
                  context.go('/inicio');
                } catch (e) {
                  print('UI DEBUG Error en navegación: $e');
                }
              }

              // Ejecutamos la baja en segundo plano
              ServicioComunidades().abandonarComunidad(comunidadId).then((res) {
                print('UI DEBUG: Respuesta recibida - Éxito: ${res.exito}');
                if (res.exito) {
                  // Intentamos refrescar el sidebar por múltiples vías
                  if (context.mounted) {
                    try {
                      // 1. Vía ancestro directo
                      context.findAncestorStateOfType<PantallaInicioState>()?.cargarComunidades();
                      // 2. Vía navegación (al volver a inicio se debería refrescar)
                      context.go('/inicio');
                    } catch (e) {
                      print('UI DEBUG Error en refresco: $e');
                      context.go('/inicio');
                    }
                  }
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(safeTr('communityLeaveSuccess', 'Has abandonado la comunidad')),
                  backgroundColor: const Color(0xFF248EA6),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(safeTr('communityLeaveAction', 'Abandonar'), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            top: 24,
            left: 24,
            child: _ActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Volver',
              onPressed: widget.onCerrar,
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
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
                            onComunidadActualizada: (nuevaComunidad) {
                              if (widget.onComunidadActualizada != null) {
                                widget.onComunidadActualizada!(nuevaComunidad);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
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
                ],
                if (!esCreador && widget.comunidad.esMiembro) ...[
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.exit_to_app_rounded,
                    tooltip: 'Abandonar Comunidad',
                    onPressed: () => _confirmarSalida(context),
                  ),
                ],
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
                          colorRol: colorRol,
                          fuente: widget.comunidad.fuenteComunidad),
                      if (widget.comunidad.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.comunidad.descripcion,
                          style: _getEstiloComunidad(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.3,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              )
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  String? _getAbsoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final base = Configuracion.baseUrl.endsWith('/') 
        ? Configuracion.baseUrl 
        : '${Configuracion.baseUrl}/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePreview(
      size: 100,
      avatarUrl: _getAbsoluteUrl(comunidad.urlAvatar ?? comunidad.urlPortada),
      marcoUrl: _getAbsoluteUrl(comunidad.urlMarco),
      nombreUsuario: null, // Ya se muestra abajo
      puntos: null,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String rolLabel;
  final IconData iconRol;
  final Color colorRol;
  final String? fuente;

  const _RoleBadge({
    required this.rolLabel,
    required this.iconRol,
    required this.colorRol,
    this.fuente,
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
            style: GoogleFonts.getFont(
              fuente ?? 'Outfit',
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
