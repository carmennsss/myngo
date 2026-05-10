import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/catalogo_mejoras.dart';
import '../../../models/usuario.dart';
import '../../../services/servicio_mejoras.dart';
import '../../../utils/mejoras_notifier.dart';
import '../../../utils/estilo_post_helper.dart';

/// Widget que muestra una pestaña del catálogo de mejoras filtrada por tipo.
class ListaMejorasTab extends StatefulWidget {
  final String tipo;
  final Usuario? usuarioActual;
  final List<CatalogoMejoras> mejoras;
  final List<dynamic> misMejoras;
  final VoidCallback onRefresh;
  final Function(int)? onPuntosActualizados;
  final Function(CatalogoMejoras) onPreviewRequested;

  const ListaMejorasTab({
    super.key,
    required this.tipo,
    this.usuarioActual,
    required this.mejoras,
    required this.misMejoras,
    required this.onRefresh,
    this.onPuntosActualizados,
    required this.onPreviewRequested,
  });

  @override
  State<ListaMejorasTab> createState() => _ListaMejorasTabState();
}

class _ListaMejorasTabState extends State<ListaMejorasTab> {
  final _servicioMejoras = ServicioMejoras();

  List<CatalogoMejoras> get _mejorasFiltradas {
    var filtradas = widget.mejoras
        .where((m) => m.tipo.toLowerCase() == widget.tipo.toLowerCase())
        .toList();
    filtradas = filtradas.where((m) => m.estaActivo).toList();
    return filtradas;
  }

  bool _tieneMejora(int mejoraId) {
    try {
      return widget.misMejoras
          .any((m) => m != null && m is Map && m['mejora'] == mejoraId);
    } catch (e) {
      return false;
    }
  }

  bool _tieneEquipada(int mejoraId) {
    try {
      return widget.misMejoras.any((m) =>
          m != null &&
          m is Map &&
          m['mejora'] == mejoraId &&
          m['esta_equipada'] == true);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _mejorasFiltradas;
    if (filtradas.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      primary: false,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final mejora = filtradas[index];
        return _MejoraCard(
          mejora: mejora,
          laTiene: _tieneMejora(mejora.id),
          estaEquipada: _tieneEquipada(mejora.id),
          usuarioActual: widget.usuarioActual,
          onPreview: () => widget.onPreviewRequested(mejora),
          onEquipar: () => _equipar(mejora),
          onComprar: () => _confirmarCompra(mejora),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final String tipoPlural = widget.tipo.toLowerCase() == 'avatar'
        ? 'avatares'
        : '${widget.tipo.toLowerCase()}s';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No hay $tipoPlural disponibles aún 🐾',
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _equipar(CatalogoMejoras mejora) async {
    // Equipación personal
    String? destino;
    if (mejora.tipo.toLowerCase() == 'fondo') {
      destino = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('¿Dónde quieres equipar este fondo? 🐾',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OpcionDestino(
                titulo: 'Banner del Perfil',
                descripcion: 'Se verá en la parte superior de tus posts y perfil.',
                icono: Icons.view_headline_rounded,
                onTap: () => Navigator.pop(ctx, 'banner'),
              ),
              const SizedBox(height: 12),
              _OpcionDestino(
                titulo: 'Fondo de Pantalla',
                descripcion: 'Cambia el fondo completo de tu feed personal.',
                icono: Icons.fullscreen_rounded,
                onTap: () => Navigator.pop(ctx, 'fondo_feed'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          ],
        ),
      );
      if (destino == null) return;
    }

    final res = await _servicioMejoras.equiparMejora(mejora.id, destino: destino);
    if (mounted) {
      if (res.exito) {
        notificarMejoraEquipada();
        widget.onRefresh();
        widget.onPuntosActualizados?.call(widget.usuarioActual?.puntos ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.mensaje),
            backgroundColor: const Color(0xFF248EA6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _confirmarCompra(CatalogoMejoras mejora) async {
    final int puntosActuales = widget.usuarioActual?.puntos ?? 0;
    final int puntosRestantes = puntosActuales - mejora.precioPuntos;

    if (puntosRestantes < 0) {
      _mostrarPuntosInsuficientes(mejora.precioPuntos, puntosActuales);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoCompra(
        mejora: mejora,
        puntosActuales: puntosActuales,
        puntosRestantes: puntosRestantes,
      ),
    );

    if (confirm == true) {
      final res = await _servicioMejoras.comprarMejora(mejora.id);
      if (mounted) {
        if (res.exito) {
          widget.onRefresh();
          if (res.datos is int) widget.onPuntosActualizados?.call(res.datos);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('¡Compra realizada! 🐾'),
              backgroundColor: Color(0xFF248EA6)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res.mensaje),
              backgroundColor: const Color(0xFFD95F43)));
        }
      }
    }
  }

  void _mostrarPuntosInsuficientes(int precio, int actual) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Puntos insuficientes 🐾',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
        content: Text('Necesitas $precio puntos, pero solo tienes $actual.',
            style: GoogleFonts.outfit(color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ENTENDIDO',
                style: GoogleFonts.outfit(
                    color: const Color(0xFFC35E34),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


}

class _MejoraCard extends StatelessWidget {
  final CatalogoMejoras mejora;
  final bool laTiene;
  final bool estaEquipada;
  final Usuario? usuarioActual;
  final VoidCallback onPreview;
  final VoidCallback onEquipar;
  final VoidCallback onComprar;

  const _MejoraCard({
    required this.mejora,
    required this.laTiene,
    required this.estaEquipada,
    this.usuarioActual,
    required this.onPreview,
    required this.onEquipar,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    final bool estaActivo = mejora.estaActivo;

    return GestureDetector(
      onTap: onPreview,
      child: Container(
        decoration: BoxDecoration(
          color: estaActivo ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8D5C4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC35E34).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagePreview(estaActivo),
                  if (estaEquipada) _buildEquippedIndicator(),
                  if (!estaActivo) _buildHiddenIndicator(),

                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool estaActivo) {
    Widget contenidoRecurso;
    
    final tipoUpper = mejora.tipo.toUpperCase();
    if (tipoUpper == 'ESTILO_POST' || tipoUpper == 'ESTILO POST') {
      contenidoRecurso = Container(
        decoration: EstiloPostHelper.buildDecoracion(
          mejora.datosExtra, 
          borderRadius: BorderRadius.zero,
          borderWidth: 4,
        ),
        child: Center(
          child: Icon(
            Icons.palette_rounded, 
            color: EstiloPostHelper.esFondoClaro(mejora.datosExtra) 
                ? Colors.black.withOpacity(0.1) 
                : Colors.white.withOpacity(0.2), 
            size: 40,
          ),
        ),
      );
    } else {
      contenidoRecurso = mejora.urlRecurso.isNotEmpty
          ? Image.network(
              mejora.urlRecurso.startsWith('http') 
                  ? mejora.urlRecurso 
                  : Uri.encodeFull(mejora.urlRecurso), 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
              ),
            )
          : const Icon(Icons.image_not_supported_rounded, size: 36);
    }

    // Si está activo (y no equipado): color normal. Si está inactivo: escala de grises.
    final Widget imagen = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: const Color(0xFFFBE9E0),
        child: contenidoRecurso,
      ),
    );

    if (estaActivo) {
      return imagen;
    }

    return ColorFiltered(
      // Escala de grises: mezcla saturación 0 con el color gris
      colorFilter: const ColorFilter.mode(Color(0xFF888888), BlendMode.saturation),
      child: Opacity(
        opacity: 0.55,
        child: imagen,
      ),
    );
  }

  Widget _buildEquippedIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration:
            const BoxDecoration(color: Color(0xFF248EA6), shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildHiddenIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.visibility_off_rounded, color: Colors.white),
        ),
      ),
    );
  }


  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (laTiene)
            _FooterButton(
              label: estaEquipada ? 'EQUIPADO' : 'EQUIPAR',
              color: estaEquipada ? Colors.grey : const Color(0xFF248EA6),
              onPressed: estaEquipada ? () {} : onEquipar,
            )
          else
            _FooterButton(
              label: '${mejora.precioPuntos} Pts',
              color: const Color(0xFFC35E34),
              onPressed: onComprar,
            ),
        ],
      ),
    );
  }
}



class _FooterButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FooterButton(
      {required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

class _DialogoCompra extends StatelessWidget {
  final CatalogoMejoras mejora;
  final int puntosActuales;
  final int puntosRestantes;

  const _DialogoCompra({
    required this.mejora,
    required this.puntosActuales,
    required this.puntosRestantes,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('¿Confirmar compra?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Coste: ${mejora.precioPuntos} puntos',
              style: GoogleFonts.outfit(
                  color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tus puntos: $puntosActuales → $puntosRestantes',
              style: GoogleFonts.outfit(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('COMPRAR')),
      ],
    );
  }
}

class _OpcionDestino extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final VoidCallback onTap;

  const _OpcionDestino({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFC35E34).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: const Color(0xFFC35E34), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF4A4440)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
