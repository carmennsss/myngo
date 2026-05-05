import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comunidad.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../models/usuario.dart';
import 'package:tolgee/tolgee.dart';

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
  final bool embeddedInDrawer;

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
    this.embeddedInDrawer = false,
  });

  String _obtenerRango(int puntos, dynamic tr) {
    if (puntos < 500) return tr('rankMichiBronze');
    if (puntos < 1500) return tr('rankMichiSilver');
    if (puntos < 3000) return tr('rankMichiGold');
    return tr('rankMichiDiamond');
  }

  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TarjetaSidebar(
              titulo: tr('myGatosTitle'),
              contenido: (cargando || comunidades == null) 
               ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 2)))
               : comunidades!.isEmpty 
                 ? Text(tr('emptyStateCommunitiesList'), style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
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
              titulo: tr('communityRanking').contains('Aún') ? 'Ranking' : tr('communityRanking'),
              contenido: (cargandoRanking || rankingUsuarios == null)
                ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 2)))
                : rankingUsuarios!.isEmpty
                  ? Text(tr('emptyStateRanking'), style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
                  : Column(
                      children: rankingUsuarios!.take(3).toList().asMap().entries.map((entry) {
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
              titulo: 'Michi-Progreso',
              contenido: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_obtenerRango(misPuntos ?? 0, tr), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34), fontSize: 16)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: (misPuntos ?? 0) / 5000.0, minHeight: 6, borderRadius: const BorderRadius.all(Radius.circular(4)), backgroundColor: const Color(0xFFF2D0BD), color: const Color(0xFFC35E34)),
                  const SizedBox(height: 6),
                  Text(tr('rankPoints', {'count': misPuntos?.toString() ?? '0'}), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        );

        if (embeddedInDrawer) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: content,
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE2B8A0),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 30.0,
                      crossAxisSpacing: 30.0,
                    ),
                    itemBuilder: (context, index) => Transform.rotate(
                      angle: index % 2 == 0 ? 0.3 : -0.2,
                      child: const Icon(Icons.pets_rounded, size: 40, color: Color(0xFFC35E34)),
                    ),
                  ),
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
                    thumbVisibility: WidgetStateProperty.all(false),
                    trackVisibility: WidgetStateProperty.all(false),
                  ),
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoComunidades(BuildContext context, List<Comunidad> comunidades, Function(Comunidad) onSelected, Function(int, int) onReorder) {
    showDialog(
      context: context,
      builder: (context) => TranslationWidget(
        builder: (context, tr) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('myGatosTitle'), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFC35E34))),
                const SizedBox(height: 8),
                Text(tr('myGatosHint'), style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 400,
                  child: ReorderableListView(
                    onReorder: onReorder,
                    children: comunidades.map((c) => ListTile(
                      key: ValueKey(c.id),
                      leading: CircleAvatar(backgroundImage: NetworkImage(c.urlPortada)),
                      title: Text(c.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                      onTap: () {
                        onSelected(c);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('commonClose'))),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFC35E34), letterSpacing: 1.2)),
          const SizedBox(height: 16),
          contenido,
        ],
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
    return BotonTactil(
      onTap: onTap,
      child: Tooltip(
        message: comunidad.nombre,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2), width: 2),
            image: DecorationImage(image: NetworkImage(comunidad.urlPortada), fit: BoxFit.cover),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: const Color(0xFFC35E34).withOpacity(0.1), shape: BoxShape.circle),
        child: Center(child: Text('+${total - 7}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34)))),
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int puesto;
  final Usuario usuario;
  final VoidCallback onTap;

  const _RankingItem({required this.puesto, required this.usuario, required this.onTap});

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Colors.greenAccent;
      case 'OCUPADO':
        return Colors.redAccent;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: BotonTactil(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: puesto == 1 ? const Color(0xFFFFD700) : (puesto == 2 ? const Color(0xFFC0C0C0) : (puesto == 3 ? const Color(0xFFCD7F32) : Colors.transparent)),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(puesto.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: puesto <= 3 ? Colors.white : Colors.grey))),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 16, 
                    backgroundImage: NetworkImage(
                      (usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty) 
                        ? usuario.urlAvatar! 
                        : 'https://i.pravatar.cc/150'
                    )
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getColorEstado(usuario.estado ?? 'DESCONECTADO'),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
                    Text(usuario.nombreUsuario, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF4A4440))),
                    Text(
                      usuario.estado == 'ACTIVO' ? tr('statusActive') : (usuario.estado == 'OCUPADO' ? tr('statusBusy') : tr('statusOffline')),
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
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
      ),
    );
  }
}
