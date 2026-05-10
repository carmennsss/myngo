import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../services/servicio_mejoras.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';


// Listado de los artículos aprobados en la tienda de la comunidad.
// Los administradores pueden activar/desactivar items y ajustar sus precios desde aquí.
class PantallaGestionCatalogo extends StatefulWidget {
  final Comunidad comunidad;

  const PantallaGestionCatalogo({super.key, required this.comunidad});

  @override
  State<PantallaGestionCatalogo> createState() => _PantallaGestionCatalogoState();
}

class _PantallaGestionCatalogoState extends State<PantallaGestionCatalogo> {
  final _servicio = ServicioMejoras();
  bool _cargando = true;
  List<CatalogoMejoras> _items = [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  // Descarga los artículos del catálogo de la comunidad
  Future<void> _cargarCatalogo() async {
    setState(() => _cargando = true);
    final res = await _servicio.obtenerCatalogoGestion(widget.comunidad.id);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito && res.datos != null) {
          _items = res.datos!;
        }
      });
    }
  }

  // Activa/desactiva un artículo o le cambia el precio
  Future<void> _actualizarItem(CatalogoMejoras item, {bool? estaActivo, int? precio}) async {
    final res = await _servicio.actualizarArticuloCatalogo(
      widget.comunidad.id, 
      item.id, 
      estaActivo: estaActivo, 
      precioFinal: precio
    );
    if (mounted) {
      if (res.exito) {
        _cargarCatalogo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          appBar: AppBar(
            title: Text(tr('catalogManagementTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
          ),
          body: _cargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
              : _items.isEmpty
                  ? _buildEmptyState(tr)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _items.length,
                      itemBuilder: (context, index) => _TarjetaGestionItem(
                        item: _items[index],
                        onToggle: (val) => _actualizarItem(_items[index], estaActivo: val),
                        onEditPrecio: () => _mostrarDialogoPrecio(context, _items[index], tr),
                        tr: tr,
                      ),
                    ),
        );
      }
    );
  }

  Widget _buildEmptyState(String Function(String) tr) {
    return EstadoVacioCargando(
      icon: Icons.inventory_2_outlined,
      message: tr('catalogManagementEmpty'),
    );
  }

  // Diálogo sencillo para introducir un nuevo precio (mínimo 100 puntos)
  void _mostrarDialogoPrecio(BuildContext context, CatalogoMejoras item, String Function(String) tr) {
    final controller = TextEditingController(text: item.precioPuntos.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('catalogManagementEditPrice'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('catalogManagementAdjustPrice'), style: GoogleFonts.outfit(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: tr('storeModerationPointsSuffix'),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                helperText: tr('catalogManagementMinPoints'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('commonCancel'))),
          ElevatedButton(
            onPressed: () {
              final precio = int.tryParse(controller.text);
              if (precio != null && precio >= 100) {
                Navigator.pop(context);
                _actualizarItem(item, precio: precio);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('catalogManagementErrorMinPrice'))),
                );
              }
            },
            child: Text(tr('adminSave')),
          ),
        ],
      ),
    );
  }
}

// Tarjeta de un artículo del catálogo con toggle de activación y botón de editar precio
class _TarjetaGestionItem extends StatelessWidget {
  final CatalogoMejoras item;
  final Function(bool) onToggle;
  final VoidCallback onEditPrecio;
  final String Function(String) tr;

  const _TarjetaGestionItem({
    required this.item,
    required this.onToggle,
    required this.onEditPrecio,
    required this.tr,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.estaActivo ? const Color(0xFFE8D5C4) : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFFFBE9E0),
                child: item.urlRecurso.isNotEmpty
                    ? Image.network(item.urlRecurso, fit: BoxFit.cover)
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            title: Text(
              item.tipo.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, 
                fontSize: 14, 
                color: item.estaActivo ? const Color(0xFF4A4440) : Colors.grey
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC35E34), size: 14),
                    const SizedBox(width: 4),
                    Text('${item.precioPuntos} pts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34))),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: item.estaActivo,
              activeColor: const Color(0xFFC35E34),
              onChanged: onToggle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!item.estaActivo)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(tr('catalogManagementInactive'), style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                OutlinedButton.icon(
                  onPressed: onEditPrecio,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text(tr('catalogManagementChangePriceBtn')),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC35E34),
                    side: const BorderSide(color: Color(0xFFC35E34)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
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
