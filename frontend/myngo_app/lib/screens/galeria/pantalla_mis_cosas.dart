import 'package:flutter/material.dart';
import '../../tolgee/translation_widget.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/servicio_galeria.dart';
import '../../models/imagen_galeria.dart';
import '../../models/coleccion.dart';
import '../../models/respuesta_api.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';
import 'dart:math' as math;
import 'pantalla_detalle_coleccion.dart';
import '../../widgets/comunes/boton_tactil.dart';

class PantallaMisCosas extends StatefulWidget {
  final int usuarioId;

  const PantallaMisCosas({super.key, required this.usuarioId});

  @override
  State<PantallaMisCosas> createState() => _PantallaMisCosasState();
}

class _PantallaMisCosasState extends State<PantallaMisCosas> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServicioGaleria _servicioGaleria = ServicioGaleria();

  bool _cargando = true;
  List<ImagenGaleria> _misImagenes = [];
  List<Coleccion> _misColecciones = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    
    final coleccionesF = _servicioGaleria.obtenerColecciones(idUsuario: widget.usuarioId);

    final resultados = await Future.wait([coleccionesF]);

    if (mounted) {
      setState(() {
        final resColecciones = resultados[0] as RespuestaApi<List<Coleccion>>;
        if (resColecciones.exito && resColecciones.datos != null) {
          _misColecciones = resColecciones.datos!;
        }
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

    return TranslationWidget(
      builder: (context, tr) {
        if (_cargando) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
        }

        return Container(
          color: const Color(0xFFFEF5F1),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFC35E34),
                  indicatorWeight: 4,
                  labelColor: const Color(0xFFC35E34),
                  unselectedLabelColor: Colors.grey.shade400,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    Tab(icon: const Icon(Icons.photo_library_rounded), text: tr('myStuffTabImages')),
                    Tab(icon: const Icon(Icons.folder_special_rounded), text: tr('myStuffTabCollections')),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMisImagenes(),
                    _buildMisColecciones(tr),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }


  Widget _buildMisImagenes() {
    return MasonryGridGaleria(usuarioId: widget.usuarioId);
  }

  Widget _buildMisColecciones(String Function(String) tr) {
    if (_misColecciones.isEmpty) {
      return _buildVistaVacia(tr('myStuffEmptyCollections'));
    }

    
    final random = math.Random(42); // Fijo para evitar parpadeos, varía entre índices

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _misColecciones.length,
      itemBuilder: (context, index) {
        final col = _misColecciones[index];
        final rotacion = (random.nextDouble() - 0.5) * 0.12; 
        final coloresHex = [0xFF248EA6, 0xFFF28B50, 0xFFD95F43, 0xFF8338EC];
        final color = Color(coloresHex[index % coloresHex.length]);

        return BotonTactil(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleColeccion(coleccion: col)));
          },
          child: Transform.rotate(
            angle: rotacion,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
                border: Border.all(color: color.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Container(
                        color: color.withValues(alpha: 0.1),
                        child: col.previsualizaciones.isEmpty
                            ? Center(child: Icon(col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_open_rounded, color: color, size: 24))
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                ),
                                itemCount: col.previsualizaciones.length,
                                itemBuilder: (context, i) => CachedNetworkImage(
                                  imageUrl: col.previsualizaciones[i],
                                  fit: BoxFit.cover,
                                  placeholder: (c,u) => Container(color: Colors.white10),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: Text(
                      col.nombreColeccion.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVistaVacia(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(mensaje, style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
