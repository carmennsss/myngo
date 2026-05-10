import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tolgee/tolgee.dart';
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';
import '../../screens/comunidades/pantalla_admin_comunidad.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class BarraContextoComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int? miId;
  final VoidCallback onCerrar;
  final Function(Comunidad)? onComunidadActualizada;

  const BarraContextoComunidad({
    super.key,
    required this.comunidad,
    this.miId,
    required this.onCerrar,
    this.onComunidadActualizada,
  });

  @override
  State<BarraContextoComunidad> createState() => _BarraContextoComunidadState();
}

class _BarraContextoComunidadState extends State<BarraContextoComunidad> {
  String _miRol = 'Miembro';
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  @override
  void didUpdateWidget(BarraContextoComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _obtenerRol();
    }
  }

  Future<void> _obtenerRol() async {
    setState(() => _cargandoRol = true);
    if (widget.miId == null) {
      setState(() => _cargandoRol = false);
      return;
    }
    final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(widget.comunidad.id, widget.miId!);
    if (mounted) {
      setState(() {
        _miRol = res.datos ?? 'Miembro';
        _cargandoRol = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final esCreador = widget.miId != null && widget.miId == widget.comunidad.creadorId;
        
        String rolLabel;
        if (esCreador) {
          rolLabel = tr('commonCreator');
        } else if (_miRol == 'Moderador') {
          rolLabel = tr('commonModerator');
        } else {
          rolLabel = tr('commonMember');
        }

        final iconRol = esCreador ? Icons.stars_rounded : (_miRol == 'Moderador' ? Icons.gavel_rounded : Icons.pets_rounded);
        final colorRol = esCreador ? Colors.amber : (_miRol == 'Moderador' ? const Color(0xFF248EA6) : const Color(0xFFC35E34));

        return SizedBox(
          height: 70,
          width: double.infinity,
          child: Stack(
            children: [
              if (widget.comunidad.urlPortada != null && widget.comunidad.urlPortada!.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.comunidad.urlPortada!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: widget.comunidad.colorTema),
                  ),
                )
              else
                Positioned.fill(child: Container(color: widget.comunidad.colorTema)),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: widget.onCerrar,
                      tooltip: tr('communityCloseView'),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.comunidad.nombre, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                        Row(
                          children: [
                            Icon(iconRol, size: 12, color: colorRol),
                            const SizedBox(width: 4),
                            Text(rolLabel.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (esCreador || _miRol == 'Moderador')
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                        onPressed: () async {
                          final actualizada = await Navigator.push<Comunidad>(
                            context,
                            MaterialPageRoute(builder: (context) => PantallaAdminComunidad(comunidad: widget.comunidad)),
                          );
                          if (actualizada != null && widget.onComunidadActualizada != null) {
                            widget.onComunidadActualizada!(actualizada);
                          }
                        },
                        tooltip: tr('communityManage'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
