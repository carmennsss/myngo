import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';

import '../../services/servicio_comunidades.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import 'widgets/tarjeta_comunidad.dart';
import 'widgets/formulario_creacion_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:myngo_app/utils/tr_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_notifier.dart';

// Pantalla de listado de comunidades con buscador, filtros por tags y grid responsivo.
// Permite crear nuevas comunidades desde el botón "+" del header.
import '../../services/servicio_mensajeria.dart';

class PantallaComunidades extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onUsuarioSelected;
  final VoidCallback? onComunidadCreada;
  const PantallaComunidades({super.key, this.onComunidadSelected, this.onUsuarioSelected, this.onComunidadCreada});

  @override
  State<PantallaComunidades> createState() => _PantallaComunidadesState();
}

class _PantallaComunidadesState extends State<PantallaComunidades> {
  final _servicioComunidades = ServicioComunidades();
  final _servicioMensajeria = ServicioMensajeria();
  final _controladorBusqueda = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Comunidad> _comunidades = [];
  List<Map<String, dynamic>> _tagsPopulares = [];
  final List<String> _tagsSeleccionados = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarTags();
    _conectarWebSockets();
  }

  void _conectarWebSockets() {
    _servicioMensajeria.conectarAGlobal((evento) {
      if (evento['type'] == 'comunidad_creada') {
        final data = evento['data'];
        if (data != null && mounted) {
          setState(() {
            final nuevaComunidad = Comunidad.fromJson(data);
            // Evitar duplicados
            if (!_comunidades.any((c) => c.id == nuevaComunidad.id)) {
              _comunidades.insert(0, nuevaComunidad);
            }
          });
        }
      }
    });
  }

  // Carga los tags más populares para mostrarlos como filtros rápidos
  Future<void> _cargarTags() async {
    final respuesta = await _servicioComunidades.buscarTags(popular: true);
    if (respuesta.exito && mounted) {
      setState(() => _tagsPopulares = respuesta.datos ?? []);
    }
  }

  // Trae comunidades filtradas por texto y tags seleccionados
  Future<void> _cargarDatos({String? filtro}) async {
    setState(() => _estaCargando = true);
    
    final respuesta = await _servicioComunidades.listarComunidades(
      busqueda: filtro,
      tags: _tagsSeleccionados.isNotEmpty ? _tagsSeleccionados : null,
    );
    if (mounted) {
      setState(() {
        _comunidades = respuesta.datos ?? [];
        _estaCargando = false;
      });
    }
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    _scrollController.dispose();
    _servicioMensajeria.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        context.watch<LocaleNotifier>();
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          body: RefreshIndicator(
            color: const Color(0xFFF28B50),
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => _cargarDatos(filtro: _controladorBusqueda.text),
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Título y Botón
                          Row(
                            children: [
                              Text(
                                tr('communityTitle'),
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
                              hintText: tr('communitySearchHint'),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFFC35E34), size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                            ),
                          ),
                          const SizedBox(height: 12),
    
                          // Filtros por Tags
                          if (_tagsPopulares.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tagsPopulares.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final tag = _tagsPopulares[index];
                                  final slug = tag['slug'] as String;
                                  final estaSeleccionado = _tagsSeleccionados.contains(slug);
                                  return FilterChip(
                                    label: Text(
                                      tag['nombre'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: estaSeleccionado ? Colors.white : const Color(0xFF4A4440),
                                        fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: estaSeleccionado,
                                    onSelected: (seleccionado) {
                                      setState(() {
                                        if (seleccionado) {
                                          _tagsSeleccionados.add(slug);
                                        } else {
                                          _tagsSeleccionados.remove(slug);
                                        }
                                      });
                                      _cargarDatos(filtro: _controladorBusqueda.text);
                                    },
                                    selectedColor: const Color(0xFFC35E34),
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: estaSeleccionado ? const Color(0xFFC35E34) : const Color(0xFFE0E0E0),
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
                  if (_estaCargando)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                    )
                  else
                    _buildSliverGridComunidades(tr),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSliverGridComunidades(String Function(String, [Map<String, dynamic>?]) tr) {
    if (_comunidades.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                tr('emptyStateSearchNoResults'),
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          childAspectRatio: 0.82,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => TarjetaComunidad(
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
          childCount: _comunidades.length,
        ),
      ),
    );
  }

  // Bottom sheet del formulario de creación de comunidad
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
}
