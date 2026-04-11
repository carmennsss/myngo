import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comunidad.dart';
import '../../widgets/comunes/boton_tactil.dart';

class SidebarIzquierdo extends StatelessWidget {
  final bool estaLogueado;
  final List<Comunidad> comunidades;
  final Function(Comunidad) onComunidadSelected;

  const SidebarIzquierdo({
    super.key,
    required this.estaLogueado,
    required this.comunidades,
    required this.onComunidadSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarjetaSidebar(
          titulo: 'Mis Comunidades (${comunidades.length})',
          contenido: comunidades.isEmpty
           ? Text('Únete a una comunidad 🐾', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
           : Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: comunidades.map((c) => Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: _ComunidadAvatarSidebar(
                 comunidad: c,
                 onTap: () => onComunidadSelected(c)
               ),
             )).toList(),
           ),
        ),
        const SizedBox(height: 20),
        _TarjetaSidebar(
          titulo: 'Ranking Semanal',
          contenido: Column(
            children: [
              _RankingItem(puesto: 1, nombre: 'MichiFan', puntos: 1500),
              _RankingItem(puesto: 2, nombre: 'GatoExplorador', puntos: 1200),
              _RankingItem(puesto: 3, nombre: 'MiauMaster', puntos: 900),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (estaLogueado)
        _TarjetaSidebar(
          titulo: 'Mis Puntos y Rango',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Michi de Oro IV', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34), fontSize: 16)),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: 0.7, minHeight: 6, borderRadius: BorderRadius.all(Radius.circular(4)), backgroundColor: Color(0xFFF2D0BD), color: Color(0xFFC35E34)),
              const SizedBox(height: 6),
              Text('350 / 500 Puntos', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
          const SizedBox(height: 16),
          contenido,
        ],
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

class _RankingItem extends StatelessWidget {
  final int puesto;
  final String nombre;
  final int puntos;
  const _RankingItem({required this.puesto, required this.nombre, required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: const Color(0xFFC35E34).withOpacity(0.1), child: Text(puesto.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFFC35E34), fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(nombre, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4A4440)))),
          Text('$puntos pts', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
