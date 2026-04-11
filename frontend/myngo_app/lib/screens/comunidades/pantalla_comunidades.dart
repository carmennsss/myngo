import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/comunidad.dart';
import 'widgets/tarjeta_comunidad.dart';
import 'widgets/formulario_creacion_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';
import '../../widgets/comunes/boton_tactil.dart';

class PantallaComunidades extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;
  final VoidCallback? onComunidadCreada;
  const PantallaComunidades({super.key, this.onComunidadSelected, this.onComunidadCreada});

  @override
  State<PantallaComunidades> createState() => _PantallaComunidadesState();
}

class _PantallaComunidadesState extends State<PantallaComunidades> {
  final _servicioComunidades = ServicioComunidades();
  final _controladorBusqueda = TextEditingController();
  
  List<Comunidad> _comunidades = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos({String? filtro}) async {
    setState(() => _estaCargando = true);
    
    final respuesta = await _servicioComunidades.listarComunidades(busqueda: filtro);
    if (mounted) {
      setState(() {
        _comunidades = respuesta.datos ?? [];
        _estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Fijo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título y Botón
                Row(
                  children: [
                    Text(
                      'COMUNIDADES',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A4440),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    BotonTactil(
                      onTap: () => _mostrarModalCreacion(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barra de Búsqueda
                TextField(
                  controller: _controladorBusqueda,
                  onChanged: (valor) => _cargarDatos(filtro: valor),
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Busca una comunidad...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFC35E34), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable
          Expanded(
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
                : _buildGridComunidades(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridComunidades() {
    if (_comunidades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No encontramos nada...',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _cargarDatos(),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          childAspectRatio: 0.82,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _comunidades.length,
        itemBuilder: (context, index) => TarjetaComunidad(
          comunidad: _comunidades[index],
          alPresionar: () {
            if (widget.onComunidadSelected != null) {
              widget.onComunidadSelected!(_comunidades[index]);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetalleComunidad(
                comunidad: _comunidades[index],
                onMembershipChanged: () {
                  _cargarDatos();
                  widget.onComunidadCreada?.call();
                },
              )));
            }
          },
        ),
      ),
    );
  }

  void _mostrarModalCreacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioCreacionComunidad(
        alConfirmar: () {
          _cargarDatos();
          widget.onComunidadCreada?.call();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }
}
