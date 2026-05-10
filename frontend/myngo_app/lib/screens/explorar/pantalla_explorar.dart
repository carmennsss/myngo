import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';

import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../comunidades/widgets/tarjeta_comunidad.dart';
import '../comunidades/widgets/formulario_creacion_comunidad.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../inicio/pantalla_inicio.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Pantalla de descubrimiento de la app. Tiene dos pestañas: Comunidades y Perfiles.
// Incluye búsqueda con debounce, filtros por tags y estrellas, e infinite scroll.
class PantallaExplorar extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;
  final VoidCallback? onComunidadCreada;
  const PantallaExplorar({super.key, this.onComunidadSelected, this.onComunidadCreada});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
  final _servicioComunidades = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  
  final _controladorBusqueda = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int _indicePestana = 0; // 0: Comunidades, 1: Perfiles
  
  List<Comunidad> _comunidades = [];
  List<Usuario> _usuarios = [];
  Timer? _searchDebounce;
  
  bool _estaCargando = true;
  bool _estaCargandoMas = false;
  bool _hayMasComunidades = true;
  bool _hayMasUsuarios = true;
  int _paginaActualComunidades = 1;
  int _paginaActualUsuarios = 1;

  bool _hayMas = true;
  List<Usuario> _usuariosOriginales = [];
  List<Usuario> _usuariosFiltrados = [];
  final int _tamanoPagina = 20;
  
  // Filtros avanzados
  int? _filtroMinStars;
  List<String> _filtroTags = [];
  List<Map<String, dynamic>> _allTags = []; // Para el buscador de tags

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _scrollController.addListener(_alHacerScroll);
  }

  // Activa la carga de más resultados cuando el usuario llega al final de la lista
  void _alHacerScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!_estaCargando && !_estaCargandoMas) {
        if (_indicePestana == 0 && _hayMasComunidades) {
          _cargarMasComunidades();
        } else if (_indicePestana == 1 && _hayMasUsuarios) {
          _cargarMasUsuarios();
        }
      }
    }
  }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controladorBusqueda.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos({String? filtro}) async {
    setState(() {
      _estaCargando = true;
      _hayMas = true;
    });
    
    if (_indicePestana == 0) {
      _paginaActualComunidades = 1;
      final respuesta = await _servicioComunidades.listarComunidades(
        busqueda: filtro, 
        pagina: _paginaActualComunidades,
        minRating: _filtroMinStars,
        tags: (_filtroTags.isNotEmpty) ? _filtroTags : null,
      );
      if (mounted) {
        setState(() {
          _comunidades = respuesta.datos ?? [];
          _hayMasComunidades = (respuesta.datos?.length ?? 0) >= _tamanoPagina;
          _estaCargando = false;
        });
      }
    } else {
      _paginaActualUsuarios = 1;
      final respuesta = await _servicioUsuarios.listarUsuarios(
        pagina: _paginaActualUsuarios,
        busqueda: filtro,
      );
      if (mounted) {
        if (respuesta.exito) {
          _usuariosOriginales = respuesta.datos ?? [];
          _usuariosFiltrados = List.from(_usuariosOriginales);
          _hayMasUsuarios = (respuesta.datos?.length ?? 0) >= _tamanoPagina;
        }
        
        setState(() {
          _usuarios = _usuariosFiltrados;
          _hayMas = _hayMasUsuarios;
          _estaCargando = false;
        });
      }
    }
  }

  Future<void> _cargarMasComunidades() async {
    if (_estaCargandoMas || !_hayMasComunidades) return;
    setState(() => _estaCargandoMas = true);
    
    _paginaActualComunidades++;
    final res = await _servicioComunidades.listarComunidades(
      busqueda: (_controladorBusqueda.text != null && _controladorBusqueda.text.isNotEmpty) ? _controladorBusqueda.text : null,
      pagina: _paginaActualComunidades,
      minRating: _filtroMinStars,
      tags: (_filtroTags.isNotEmpty) ? _filtroTags : null,
    );
    
    if (mounted) {
      setState(() {
        _estaCargandoMas = false;
        if (res.exito && res.datos != null && res.datos!.isNotEmpty) {
          final nuevos = res.datos!;
          
          // Filtrar duplicados para evitar el bucle infinito si el backend no pagina correctamente
          final idsExistentes = _comunidades.map((c) => c.id).toSet();
          final realmenteNuevos = nuevos.where((c) => !idsExistentes.contains(c.id)).toList();
          
          if (realmenteNuevos.isEmpty) {
            _hayMasComunidades = false;
          } else {
            _comunidades.addAll(realmenteNuevos);
            _hayMasComunidades = nuevos.length >= _tamanoPagina;
          }
        } else {
          _hayMasComunidades = false;
        }
      });
    }
  }

  Future<void> _cargarMasUsuarios() async {
    if (_estaCargandoMas || !_hayMasUsuarios) return;
    setState(() => _estaCargandoMas = true);
    
    _paginaActualUsuarios++;
    final res = await _servicioUsuarios.listarUsuarios(
      pagina: _paginaActualUsuarios,
      busqueda: (_controladorBusqueda.text != null && _controladorBusqueda.text.isNotEmpty) ? _controladorBusqueda.text : null,
    );
    
    if (mounted) {
      setState(() {
        _estaCargandoMas = false;
        if (res.exito && res.datos != null && res.datos!.isNotEmpty) {
          final nuevos = res.datos!;
          
          // Filtrar duplicados
          final idsExistentes = _usuariosOriginales.map((u) => u.id).toSet();
          final realmenteNuevos = nuevos.where((u) => !idsExistentes.contains(u.id)).toList();
          
          if (realmenteNuevos.isEmpty) {
            _hayMasUsuarios = false;
            _hayMas = false;
          } else {
            _usuariosOriginales.addAll(realmenteNuevos);
            _hayMasUsuarios = nuevos.length >= _tamanoPagina;
            
            // Re-aplicar filtro si hay búsqueda activa
            final filtro = _controladorBusqueda.text ?? '';
            if (filtro.isNotEmpty) {
               _usuariosFiltrados = _usuariosOriginales.where((u) => 
                  (u.nombreUsuario ?? '').toLowerCase().contains(filtro.toLowerCase()) ||
                  (u.email ?? '').toLowerCase().contains(filtro.toLowerCase())
               ).toList();
            } else {
              _usuariosFiltrados = List.from(_usuariosOriginales);
            }
            _usuarios = _usuariosFiltrados;
            _hayMas = _hayMasUsuarios;
          }
        } else {
          _hayMasUsuarios = false;
          _hayMas = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
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
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                tr('exploreTitle'),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4A4440),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (_indicePestana == 0)
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
                          Row(
                            children: [
                              _buildPestana(tr('exploreTabCommunities'), 0),
                              const SizedBox(width: 24),
                              _buildPestana(tr('exploreTabProfiles'), 1),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controladorBusqueda,
                                  onChanged: (valor) {
                                    _searchDebounce?.cancel();
                                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                                      _cargarDatos(filtro: valor);
                                    });
                                  },
                                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: _indicePestana == 0 ? tr('exploreSearchCommunitiesHint') : tr('exploreSearchProfilesHint'),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFFC35E34), size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (_indicePestana == 0) ...[
                                const SizedBox(width: 8),
                                BotonTactil(
                                  onTap: () => _mostrarFiltrosAvanzados(tr),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (_filtroMinStars != null || _filtroTags.isNotEmpty) 
                                        ? const Color(0xFFC35E34) 
                                        : const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.tune_rounded, 
                                      color: (_filtroMinStars != null || _filtroTags.isNotEmpty) ? Colors.white : const Color(0xFFC35E34), 
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_estaCargando)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                    )
                  else if (_indicePestana == 0)
                    _buildSliverGridComunidades(tr)
                  else
                    _buildSliverGridPerfiles(tr),
                  
                  if (_estaCargandoMas)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        );
      }
    );
  }


  Widget _buildPestana(String texto, int index) {
    bool activa = _indicePestana == index;
    return BotonTactil(
      onTap: () {
        if (_indicePestana == index) return;
        setState(() {
          _indicePestana = index;
          _controladorBusqueda.clear();
          _cargarDatos();
        });
      },
      child: Column(
        children: [
          Text(
            texto,
            style: GoogleFonts.outfit(
              color: activa ? const Color(0xFFC35E34) : Colors.grey.shade500,
              fontWeight: activa ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (activa)
            Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 24, decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildSliverGridComunidades(String Function(String) tr) {
    if (_comunidades.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                tr('exploreEmptyCommunities'),
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return SliverPadding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isMobile ? width : 280,
          childAspectRatio: isMobile ? 1.4 : 0.82,
          crossAxisSpacing: isMobile ? 12 : 20,
          mainAxisSpacing: isMobile ? 12 : 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => TarjetaComunidad(
            comunidad: _comunidades[index],
            alPresionar: () {
              Future.delayed(Duration.zero, () {
                if (widget.onComunidadSelected != null) {
                  widget.onComunidadSelected!(_comunidades[index]);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetalleComunidad(
                    idOrName: _comunidades[index].nombre,
                    comunidad: _comunidades[index],
                    onMembershipChanged: () {
                      _cargarDatos();
                      widget.onComunidadCreada?.call();
                    },
                  )));
                }
              });
            },
          ),
          childCount: _comunidades.length,
        ),
      ),
    );
  }

  void _mostrarFiltrosAvanzados(String Function(String) tr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ModalFiltrosAvanzados(
        minStars: _filtroMinStars,
        selectedTags: _filtroTags,
        alAplicar: (stars, tags) {
          setState(() {
            _filtroMinStars = stars;
            _filtroTags = tags;
          });
          _cargarDatos(filtro: _controladorBusqueda.text);
        },
        tr: tr,
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

  Widget _buildSliverGridPerfiles(String Function(String) tr) {
    if (_usuarios.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                tr('exploreEmptyProfiles'),
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final usuario = _usuarios[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2), width: 2),
                    image: (usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(usuario.urlAvatar!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (usuario.urlAvatar == null || usuario.urlAvatar!.isEmpty) ? const Icon(Icons.person, color: Color(0xFFC35E34)) : null,
                ),
                title: Text(usuario.nombreUsuario, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
                subtitle: Text(usuario.email, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC35E34)),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                    if (inicioState != null) {
                      inicioState.seleccionarUsuario(usuario);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => PantallaDetallePerfil(
                          idOrUsername: usuario.nombreUsuario,
                          usuario: usuario,
                        )),
                      );
                    }
                  });
                },
              ),
            );
          },
          childCount: _usuarios.length,
        ),
      ),
    );
  }
}

class _ModalFiltrosAvanzados extends StatefulWidget {
  final int? minStars;
  final List<String> selectedTags;
  final Function(int?, List<String>) alAplicar;
  final String Function(String) tr;

  const _ModalFiltrosAvanzados({
    required this.minStars,
    required this.selectedTags,
    required this.alAplicar,
    required this.tr,
  });


  @override
  State<_ModalFiltrosAvanzados> createState() => _ModalFiltrosAvanzadosState();
}

class _ModalFiltrosAvanzadosState extends State<_ModalFiltrosAvanzados> {
  int? _tempStars;
  List<String> _tempTags = [];
  final _tagController = TextEditingController();
  final _servicio = ServicioComunidades();
  List<Map<String, dynamic>> _sugerenciasTags = [];

  @override
  void initState() {
    super.initState();
    _tempStars = widget.minStars;
    _tempTags = List<String>.from(widget.selectedTags ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.tr('exploreAdvancedFilters'),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A4440),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Reputación mínima (Estrellas)
            Text(
              widget.tr('exploreMinReputation'),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A4440),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int starValue = index + 1;
                bool isSelected = _tempStars != null && _tempStars! >= starValue;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      if (_tempStars == starValue) {
                        _tempStars = null;
                      } else {
                        _tempStars = starValue;
                      }
                    });
                  },
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? const Color(0xFFF28B50) : Colors.grey,
                    size: 36,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Etiquetas (Tags)
            Text(
              widget.tr('exploreTagsTitle'),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A4440),
              ),
            ),

            const SizedBox(height: 8),
            if (_tempTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 8,
                  children: _tempTags.map((tag) => Chip(
                    label: Text(tag, style: GoogleFonts.outfit(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _tempTags.remove(tag));
                    },
                    backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFFC35E34)),
                  )).toList(),
                ),
              ),
            TextField(
              controller: _tagController,
              onChanged: (val) async {
                if (val.length > 1) {
                  final res = await _servicio.buscarTags(query: val);
                  if (res.exito && mounted) {
                    setState(() => _sugerenciasTags = res.datos ?? []);
                  }
                } else {
                  setState(() => _sugerenciasTags = []);
                }
              },
              decoration: InputDecoration(
                hintText: widget.tr('exploreAddTagHint'),
                hintStyle: GoogleFonts.outfit(fontSize: 14),
                prefixIcon: const Icon(Icons.tag, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),

            ),
            if (_sugerenciasTags.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sugerenciasTags.length,
                  itemBuilder: (context, index) {
                    final tag = _sugerenciasTags[index]['nombre'];
                    return ListTile(
                      dense: true,
                      title: Text(tag, style: GoogleFonts.outfit(fontSize: 14)),
                      onTap: () {
                        if (!_tempTags.contains(tag)) {
                          setState(() {
                            _tempTags.add(tag);
                            _tagController.clear();
                            _sugerenciasTags = [];
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempStars = null;
                        _tempTags = [];
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.tr('exploreClearFilters'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),

                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.alAplicar(_tempStars, _tempTags);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC35E34),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.tr('exploreApplyFilters'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),

                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
