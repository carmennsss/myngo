import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comunidad.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../models/usuario.dart';

class SidebarIzquierdo extends StatelessWidget {
  final bool estaLogueado;
  final bool cargando;
  final List<Comunidad>? comunidades;
  final List<Usuario>? rankingUsuarios;
  final bool cargandoRanking;
  final int? misPuntos;
  final Function(Comunidad) onComunidadSelected;
  final Function(Usuario) onUsuarioSelected;
  final Function(int, int) onReorder;

  const SidebarIzquierdo({
    super.key,
    required this.estaLogueado,
    this.cargando = false,
    this.comunidades,
    this.rankingUsuarios,
    this.cargandoRanking = false,
    this.misPuntos,
    required this.onComunidadSelected,
    required this.onUsuarioSelected,
    required this.onReorder,
  });

  String _obtenerRango(int puntos) {
    if (puntos < 500) return 'Michi de Bronce';
    if (puntos < 1500) return 'Michi de Plata';
    if (puntos < 3000) return 'Michi de Oro';
    return 'Michi de Diamante';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarjetaSidebar(
          titulo: 'Mis Michi-Grupos',
          contenido: (cargando || comunidades == null) 
           ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 2)))
           : comunidades!.isEmpty 
             ? Text('Únete a una comunidad 🐾', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
             : Wrap(
               spacing: 12,
               runSpacing: 12,
               children: [
                 ...comunidades!.take(7).map((c) => _ComunidadAvatarCompacto(
                   comunidad: c, 
                   onTap: () => onComunidadSelected(c)
                 )),
                 if (comunidades!.length > 7)
                   _BotonVerMas(
                     total: comunidades!.length,
                     onTap: () => _mostrarDialogoComunidades(context, comunidades!, onComunidadSelected, onReorder),
                   ),
               ],
             ),
        ),
        const SizedBox(height: 12),
        _TarjetaSidebar(
          titulo: 'Ranking Semanal',
          contenido: (cargandoRanking || rankingUsuarios == null)
            ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 2)))
            : rankingUsuarios!.isEmpty
              ? Text('Aún no hay ranking 🐾', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
              : Column(
                  children: rankingUsuarios!.take(5).toList().asMap().entries.map((entry) {
                    int index = entry.key;
                    Usuario u = entry.value;
                    return _RankingItem(
                      puesto: index + 1, 
                      usuario: u,
                      onTap: () => onUsuarioSelected(u),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        if (estaLogueado)
        _TarjetaSidebar(
          titulo: 'Mis Puntos y Rango',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_obtenerRango(misPuntos ?? 0), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34), fontSize: 16)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (misPuntos ?? 0) / 5000.0, minHeight: 6, borderRadius: const BorderRadius.all(Radius.circular(4)), backgroundColor: const Color(0xFFF2D0BD), color: const Color(0xFFC35E34)),
              const SizedBox(height: 6),
              Text('${misPuntos ?? 0} / 5000 Puntos', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaSidebar extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  const _TarjetaSidebar({required this.titulo, required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF7F2),
            Color(0xFFFEECE3),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC35E34).withOpacity(0.06), 
            blurRadius: 24, 
            offset: const Offset(0, 10)
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decoración sutil de fondo (Patrón de patas)
            Positioned(
              right: -30,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.pets_rounded,
                  size: 150,
                  color: const Color(0xFFF2D0BD).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              left: -20,
              top: -10,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(
                  Icons.pets_rounded,
                  size: 80,
                  color: const Color(0xFFF2D0BD).withOpacity(0.15),
                ),
              ),
            ),
            // Contenido real
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC35E34).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC35E34)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          titulo, 
                          style: GoogleFonts.outfit(
                            fontSize: 16, 
                            fontWeight: FontWeight.w900, 
                            color: const Color(0xFF4A4440),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  contenido,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComunidadAvatarSidebar extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback onTap;
  const _ComunidadAvatarSidebar({required this.comunidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: comunidad.colorTema.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: comunidad.colorTema.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: comunidad.colorTema.withOpacity(0.3),
              backgroundImage: comunidad.urlPortada.isNotEmpty ? CachedNetworkImageProvider(comunidad.urlPortada) : null,
              child: comunidad.urlPortada.isEmpty ? Text(comunidad.nombre[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: comunidad.colorTema, fontSize: 14)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comunidad.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4A4440))),
                  const SizedBox(height: 4),
                  Text('${comunidad.miembrosCount} Miembros', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComunidadAvatarCompacto extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback onTap;
  const _ComunidadAvatarCompacto({required this.comunidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: comunidad.nombre,
      textStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4440),
        borderRadius: BorderRadius.circular(8),
      ),
      child: BotonTactil(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: comunidad.colorTema.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(color: comunidad.colorTema.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: comunidad.colorTema.withOpacity(0.1),
            backgroundImage: comunidad.urlPortada.isNotEmpty 
              ? CachedNetworkImageProvider(comunidad.urlPortada) 
              : null,
            child: comunidad.urlPortada.isEmpty 
              ? Text(comunidad.nombre[0].toUpperCase(), 
                  style: TextStyle(color: comunidad.colorTema, fontWeight: FontWeight.bold, fontSize: 16)) 
              : null,
          ),
        ),
      ),
    );
  }
}

class _BotonVerMas extends StatelessWidget {
  final int total;
  final VoidCallback onTap;
  const _BotonVerMas({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text('+${total - 7}', 
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey.shade600)),
        ),
      ),
    );
  }
}

void _mostrarDialogoComunidades(
    BuildContext context, 
    List<Comunidad> comunidades, 
    Function(Comunidad) onSelected,
    Function(int, int) onReorder) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      return StatefulBuilder(
        builder: (context, setDialogState) => Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 480,
                height: 650,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.15), blurRadius: 60, offset: const Offset(0, 20)),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  children: [
                    // Cabecera Premium
                    Container(
                      padding: const EdgeInsets.fromLTRB(32, 32, 24, 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF5F1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        border: Border(bottom: BorderSide(color: const Color(0xFFC35E34).withOpacity(0.05))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFF28B50), Color(0xFFC35E34)]),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: const Icon(Icons.sort_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Mis Michi-Grupos', 
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: const Color(0xFF4A4440), letterSpacing: -0.5)
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context), 
                                icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 28),
                                splashRadius: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.touch_app_rounded, color: Color(0xFF248EA6), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Mantén presionado y arrastra para reordenar tus favoritos 🐾', 
                                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lista Reordenable
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        itemCount: comunidades.length,
                        onReorder: (oldIndex, newIndex) {
                          setDialogState(() {
                            onReorder(oldIndex, newIndex);
                          });
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (BuildContext context, Widget? childBuilder) {
                                final animValue = Curves.easeInOut.transform(animation.value);
                                final elevation = lerpDouble(0, 20, animValue)!;
                                final scale = lerpDouble(1, 1.05, animValue)!;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.15 * animValue), blurRadius: elevation, offset: Offset(0, elevation / 2)),
                                      ],
                                    ),
                                    child: childBuilder,
                                  ),
                                );
                              },
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final c = comunidades[index];
                          return Container(
                            key: ValueKey('dialog_${c.id}'),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF2D0BD).withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                hoverColor: const Color(0xFFFEF5F1),
                                onTap: () {
                                  Navigator.pop(context);
                                  onSelected(c);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle, 
                                          border: Border.all(color: c.colorTema.withOpacity(0.3), width: 2)
                                        ),
                                        child: CircleAvatar(
                                          radius: 26,
                                          backgroundColor: c.colorTema.withOpacity(0.1),
                                          backgroundImage: (c.urlPortada != null && c.urlPortada!.isNotEmpty) 
                                            ? CachedNetworkImageProvider(c.urlPortada!) 
                                            : null,
                                          child: (c.urlPortada == null || c.urlPortada!.isEmpty) 
                                            ? Text(c.nombre[0].toUpperCase(), style: TextStyle(color: c.colorTema, fontWeight: FontWeight.bold, fontSize: 18)) 
                                            : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.nombre ?? 'Sin nombre', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF4A4440))),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.people_alt_rounded, size: 14, color: const Color(0xFF248EA6).withOpacity(0.7)),
                                                const SizedBox(width: 4),
                                                Text('${c.miembrosCount ?? 0} miembros', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.drag_handle_rounded, color: Color(0xFFF2D0BD), size: 28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  );
}

class _RankingItem extends StatelessWidget {
  final int puesto;
  final Usuario usuario;
  final VoidCallback onTap;
  const _RankingItem({required this.puesto, required this.usuario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                puesto.toString(), 
                style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFFC35E34), fontWeight: FontWeight.w900)
              ),
            ),
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                  backgroundImage: (usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(usuario.urlAvatar!)
                      : null,
                  child: (usuario.urlAvatar == null || usuario.urlAvatar!.isEmpty)
                      ? const Icon(Icons.person, size: 18, color: Color(0xFFC35E34))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getColorEstado(usuario.estado ?? 'DESCONECTADO'),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreUsuario, 
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4A4440)), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  Text(
                    usuario.estado == 'ACTIVO' ? 'Activo' : (usuario.estado == 'OCUPADO' ? 'Ocupado' : 'Desconectado'),
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE89A6A)),
                const SizedBox(width: 4),
                Text(usuario.ratingActual.toStringAsFixed(1), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
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
