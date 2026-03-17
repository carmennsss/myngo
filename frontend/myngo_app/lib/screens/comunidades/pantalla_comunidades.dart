import 'package:flutter/material.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/comunidad.dart';
import '../../models/respuesta_api.dart';
import 'widgets/tarjeta_comunidad.dart';
import 'widgets/formulario_creacion_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';

class PantallaComunidades extends StatefulWidget {
  const PantallaComunidades({super.key});

  @override
  State<PantallaComunidades> createState() => _PantallaComunidadesState();
}

class _PantallaComunidadesState extends State<PantallaComunidades> {
  final _servicio = ServicioComunidades();
  final _controladorBusqueda = TextEditingController();
  List<Comunidad> _comunidades = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarComunidades();
  }

  Future<void> _cargarComunidades({String? filtro}) async {
    setState(() => _estaCargando = true);
    final respuesta = await _servicio.listarComunidades(busqueda: filtro);
    if (respuesta.exito) {
      setState(() {
        _comunidades = respuesta.datos ?? [];
        _estaCargando = false;
      });
    } else {
      setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Comunidades', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _controladorBusqueda,
              onChanged: (valor) => _cargarComunidades(filtro: valor),
              decoration: InputDecoration(
                hintText: 'Buscar comunidades...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Grid estilo Pinterest (Simulado con 2 columnas)
          Expanded(
            child: _estaCargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _comunidades.isEmpty
                ? const Center(child: Text('No hay comunidades todavía.'))
                : RefreshIndicator(
                    onRefresh: () => _cargarComunidades(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _comunidades.length,
                      itemBuilder: (context, index) => TarjetaComunidad(
                        comunidad: _comunidades[index],
                        alPresionar: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PantallaDetalleComunidad(
                                comunidad: _comunidades[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarModalCreacion(context),
        label: const Text('Crear Nueva Comunidad'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _mostrarModalCreacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioCreacionComunidad(
        alConfirmar: () => _cargarComunidades(),
      ),
    );
  }
}
