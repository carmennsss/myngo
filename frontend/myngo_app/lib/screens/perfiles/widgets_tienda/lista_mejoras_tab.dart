import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/catalogo_mejoras.dart';
import '../../../models/usuario.dart';
import '../../../services/servicio_mejoras.dart';
import '../../../utils/mejoras_notifier.dart';
import '../../../utils/estilo_post_helper.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Widget que muestra una pestaña del catálogo de mejoras filtrada por tipo.
class ListaMejorasTab extends StatefulWidget {
  final String tipo;
  final Usuario? usuarioActual;
  final List<CatalogoMejoras> mejoras;
  final List<dynamic> misMejoras;
  final bool modoGestion;
  final int? comunidadId;
  final bool esModerador;
  final VoidCallback onRefresh;
  final Function(int)? onPuntosActualizados;
  final Function(CatalogoMejoras) onPreviewRequested;

  const ListaMejorasTab({
    super.key,
    required this.tipo,
    this.usuarioActual,
    required this.mejoras,
    required this.misMejoras,
    this.modoGestion = false,
    this.comunidadId,
    this.esModerador = false,
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
    var filtradas = widget.mejoras.where((m) {
      final t1 = m.tipo.toLowerCase().replaceAll('_', ' ');
      final t2 = widget.tipo.toLowerCase().replaceAll('_', ' ');
      return t1 == t2;
    }).toList();
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
    return Builder(
      builder: (context) {
        if (filtradas.isEmpty) {
          return _buildEmptyState(tr);
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
              modoGestion: widget.modoGestion,
              usuarioActual: widget.usuarioActual,
              onPreview: () => widget.onPreviewRequested(mejora),
              onEquipar: () => _equipar(mejora, tr),
              onComprar: () => _confirmarCompra(mejora, tr),
              onToggleVisibilidad: () => _toggleVisibilidad(mejora),
              onEditPrice: (p) => _editarPrecio(mejora, p),
            );
          },
        );
      },
    );
  }

  String _getTipoPluralTraducido(Function tr) {
    final t = widget.tipo.toLowerCase();
    if (t == 'avatar') return tr('storeAvatars');
    if (t == 'marco') return tr('storeFrames');
    if (t == 'fondo') return tr('storeBackgrounds');
    if (t.contains('estilo')) return tr('storePostStyles');
    return t;
  }

  Widget _buildEmptyState(Function tr) {
    final String tipoPlural = _getTipoPluralTraducido(tr);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            tr('storeEmptyState', {'tipo': tipoPlural}),
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _equipar(CatalogoMejoras mejora, Function tr) async {
    String? modoEquipacion = 'personal';

    // Si es una tienda de comunidad y el usuario es moderador/admin, preguntamos destino
    if (widget.comunidadId != null && widget.esModerador) {
      modoEquipacion = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('storeEquipWhere'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OpcionDestino(
                titulo: tr('storeInProfile'),
                descripcion: tr('storeInProfileDesc'),
                icono: Icons.person_rounded,
                onTap: () => Navigator.pop(ctx, 'personal'),
              ),
              const SizedBox(height: 12),
              _OpcionDestino(
                titulo: tr('storeInCommunity'),
                descripcion: tr('storeInCommunityDesc'),
                icono: Icons.groups_rounded,
                onTap: () => Navigator.pop(ctx, 'comunidad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          ],
        ),
      );
      if (modoEquipacion == null) return;
    }

    if (modoEquipacion == 'comunidad') {
      final res = await _servicioMejoras.equiparMejoraComunidad(mejora.id, widget.comunidadId!);
      if (mounted) {
        if (res.exito) {
          widget.onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: const Color(0xFF248EA6)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: Colors.redAccent),
          );
        }
      }
      return;
    }

    // Lógica original para equipación personal
    String? destino;
    if (mejora.tipo.toLowerCase() == 'fondo') {
      destino = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('storeEquipBgWhere'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OpcionDestino(
                titulo: tr('storeBanner'),
                descripcion: tr('storeBannerDesc'),
                icono: Icons.view_headline_rounded,
                onTap: () => Navigator.pop(ctx, 'banner'),
              ),
              const SizedBox(height: 12),
              _OpcionDestino(
                titulo: tr('storeWallpaper'),
                descripcion: tr('storeWallpaperDesc'),
                icono: Icons.fullscreen_rounded,
                onTap: () => Navigator.pop(ctx, 'fondo_feed'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
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

  Future<void> _confirmarCompra(CatalogoMejoras mejora, Function tr) async {
    final int puntosActuales = widget.usuarioActual?.puntos ?? 0;
    final int puntosRestantes = puntosActuales - mejora.precioPuntos;

    if (puntosRestantes < 0) {
      _mostrarPuntosInsuficientes(mejora.precioPuntos, puntosActuales, tr);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoCompra(
        mejora: mejora,
        puntosActuales: puntosActuales,
        puntosRestantes: puntosRestantes,
        tr: tr,
      ),
    );

    if (confirm == true) {
      final res = await _servicioMejoras.comprarMejora(mejora.id);
      if (mounted) {
        if (res.exito) {
          widget.onRefresh();
          if (res.datos is int) widget.onPuntosActualizados?.call(res.datos);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('storePurchaseSuccess')),
              backgroundColor: const Color(0xFF248EA6)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res.mensaje),
              backgroundColor: const Color(0xFFD95F43)));
        }
      }
    }
  }

  void _mostrarPuntosInsuficientes(int precio, int actual, Function tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('storeInsufficientPoints'),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
        content: Text(tr('storeInsufficientPointsDesc', {'precio': precio.toString(), 'actual': actual.toString()}),
            style: GoogleFonts.outfit(color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('understand'),
                style: GoogleFonts.outfit(
                    color: const Color(0xFFC35E34),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVisibilidad(CatalogoMejoras mejora) async {
    if (widget.comunidadId == null) return;
    
    final res = await _servicioMejoras.actualizarArticuloCatalogo(
      widget.comunidadId!, 
      mejora.id,
      estaActivo: !mejora.estaActivo,
    );
    
    if (mounted) {
      if (res.exito) {
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
      }
    }
  }

  Future<void> _editarPrecio(CatalogoMejoras mejora, int precioActual) async {
    if (widget.comunidadId == null) return;

    final controller = TextEditingController(text: precioActual.toString());
    
    final nuevoPrecioStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('storeEditPrice'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr('storePriceLabel')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(tr('save')),
          ),
        ],
      ),
    );

    if (nuevoPrecioStr != null && nuevoPrecioStr.isNotEmpty) {
      final nuevoPrecio = int.tryParse(nuevoPrecioStr);
      if (nuevoPrecio != null) {
        final res = await _servicioMejoras.actualizarArticuloCatalogo(
          widget.comunidadId!, 
          mejora.id,
          precioFinal: nuevoPrecio,
        );
        if (mounted) {
          if (res.exito) {
            widget.onRefresh();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
          }
        }
      }
    }
  }
}

class _MejoraCard extends StatelessWidget {
  final CatalogoMejoras mejora;
  final bool laTiene;
  final bool estaEquipada;
  final bool modoGestion;
  final Usuario? usuarioActual;
  final VoidCallback onPreview;
  final VoidCallback onEquipar;
  final VoidCallback onComprar;
  final VoidCallback onToggleVisibilidad;
  final Function(int) onEditPrice;

  const _MejoraCard({
    required this.mejora,
    required this.laTiene,
    required this.estaEquipada,
    this.modoGestion = false,
    this.usuarioActual,
    required this.onPreview,
    required this.onEquipar,
    required this.onComprar,
    required this.onToggleVisibilidad,
    required this.onEditPrice,
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
                  if (modoGestion) _buildModeratorActions(),
                ],
              ),
            ),
            _buildFooter(context),
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

  Widget _buildModeratorActions() {
    return Positioned(
      top: 4,
      left: 4,
      child: Row(
        children: [
          _ActionButton(
            icon: mejora.estaActivo ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: mejora.estaActivo ? Colors.green : Colors.red,
            onTap: onToggleVisibilidad,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.edit_rounded,
            color: Colors.blue,
            onTap: () async {
              // Dialogo rápido para editar precio
              onEditPrice(mejora.precioPuntos);
            },
          ),
        ],
      ),
    );
  }
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (laTiene)
            _FooterButton(
              label: estaEquipada ? tr('storeEquipped') : tr('profileEquip'),
              color: estaEquipada ? Colors.grey : const Color(0xFF248EA6),
              onPressed: estaEquipada ? () {} : onEquipar,
            )
          else
            _FooterButton(
              label: '${mejora.precioPuntos} ${tr('points')}',
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
  final Function tr;

  const _DialogoCompra({
    required this.mejora,
    required this.puntosActuales,
    required this.puntosRestantes,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(tr('storeConfirmPurchase'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('storeCost', {'precio': mejora.precioPuntos.toString()}),
              style: GoogleFonts.outfit(
                  color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('storeYourPoints', {'actual': puntosActuales.toString(), 'restantes': puntosRestantes.toString()}),
              style: GoogleFonts.outfit(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'))),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('storeBuy'))),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.9), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
