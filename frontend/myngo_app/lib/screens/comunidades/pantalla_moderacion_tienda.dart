import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/comunidad.dart';
import '../../models/peticion_mejora.dart';
import '../../services/servicio_mejoras.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';

class PantallaModeracionTienda extends StatefulWidget {
  final Comunidad comunidad;

  const PantallaModeracionTienda({super.key, required this.comunidad});

  @override
  State<PantallaModeracionTienda> createState() => _PantallaModeracionTiendaState();
}

class _PantallaModeracionTiendaState extends State<PantallaModeracionTienda> {
  final _servicio = ServicioMejoras();
  bool _cargando = true;
  List<PeticionMejora> _peticiones = [];

  @override
  void initState() {
    super.initState();
    _cargarPeticiones();
  }

  Future<void> _cargarPeticiones() async {
    setState(() => _cargando = true);
    final res = await _servicio.obtenerPeticionesModeracion(widget.comunidad.id);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito && res.datos != null) {
          _peticiones = (res.datos as List).map((e) => PeticionMejora.fromJson(e)).toList();
        }
      });
    }
  }

  Future<void> _moderar(PeticionMejora peticion, String estado, int precio) async {
    final res = await _servicio.moderarPeticion(peticion.id, estado, precio);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.mensaje), backgroundColor: res.exito ? Colors.green : Colors.red),
      );
      if (res.exito) _cargarPeticiones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      appBar: AppBar(
        title: Text('Moderación de Tienda', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
          : _peticiones.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _peticiones.length,
                  itemBuilder: (context, index) => _TarjetaModeracion(
                    peticion: _peticiones[index],
                    onAprobar: (precio) => _moderar(_peticiones[index], 'APROBADO', precio),
                    onRechazar: () => _moderar(_peticiones[index], 'RECHAZADO', 0),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const EstadoVacioCargando(
      icon: Icons.check_circle_outline_rounded,
      message: '¡Todo al día! No hay peticiones pendientes 🐾',
    );
  }
}

class _TarjetaModeracion extends StatelessWidget {
  final PeticionMejora peticion;
  final Function(int) onAprobar;
  final VoidCallback onRechazar;

  const _TarjetaModeracion({
    required this.peticion,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8D5C4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peticion.tipo.toUpperCase(),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF4A4440)),
                      ),
                      const SizedBox(height: 8),
                      Text('Enviado por: ${peticion.nombreUsuario}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (peticion.precioSugerido > 0)
                        Text('Precio sugerido: ${peticion.precioSugerido} pts', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(peticion.urlRecurso, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRechazar,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('RECHAZAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _mostrarDialogoPrecio(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('APROBAR Y PONER PRECIO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPrecio(BuildContext context) {
    final controller = TextEditingController(text: peticion.precioSugerido.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Precio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Indica el precio en puntos para este item:', style: GoogleFonts.outfit(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'puntos',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final precio = int.tryParse(controller.text) ?? 100;
              Navigator.pop(context);
              onAprobar(precio);
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }
}
