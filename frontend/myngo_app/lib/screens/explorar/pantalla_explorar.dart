import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<Usuario> _usuariosOriginales = [];
  List<Usuario> _usuariosFiltrados = [];
  
  bool _estaCargando = true;
  bool _estaCargandoMas = false;
  bool _hayMasComunidades = true;
  bool _hayMasUsuarios = true;
  int _paginaActualComunidades = 1;
  int _paginaActualUsuarios = 1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _scrollController.addListener(_alHacerScroll);
  }

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
    _controladorBusqueda.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos({String? filtro}) async {
    setState(() => _estaCargando = true);
    
    if (_indicePestana == 0) {
      _paginaActualComunidades = 1;
      final respuesta = await _servicioComunidades.listarComunidades(busqueda: filtro, pagina: _paginaActualComunidades);
      if (mounted) {
        setState(() {
          _comunidades = respuesta.datos ?? [];
          _hayMasComunidades = (respuesta.datos?.length ?? 0) >= 20;
          _estaCargando = false;
        });
      }
    } else {
      _paginaActualUsuarios = 1;
      final respuesta = await _servicioUsuarios.listarUsuarios(pagina: _paginaActualUsuarios);
      if (respuesta.exito && mounted) {
        _usuariosOriginales = respuesta.datos ?? [];
        _hayMasUsuarios = (respuesta.datos?.length ?? 0) >= 20;
      }
      
      if (mounted) {
        setState(() {
          if (filtro != null && filtro.isNotEmpty) {
            _usuariosFiltrados = _usuariosOriginales.where((u) => 
               u.nombreUsuario.toLowerCase().contains(filtro.toLowerCase()) ||
               u.email.toLowerCase().contains(filtro.toLowerCase())
            ).toList();
          } else {
            _usuariosFiltrados = List.from(_usuariosOriginales);
          }
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
      busqueda: _controladorBusqueda.text.isNotEmpty ? _controladorBusqueda.text : null,
      pagina: _paginaActualComunidades
    );
    
    if (mounted) {
      setState(() {
        _estaCargandoMas = false;
        if (res.exito && res.datos != null) {
          final nuevos = res.datos!;
          _comunidades.addAll(nuevos);
          _hayMasComunidades = nuevos.length >= 20;
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
    final res = await _servicioUsuarios.listarUsuarios(pagina: _paginaActualUsuarios);
    
    if (mounted) {
      setState(() {
        _estaCargandoMas = false;
        if (res.exito && res.datos != null) {
          final nuevos = res.datos!;
          _usuariosOriginales.addAll(nuevos);
          _hayMasUsuarios = nuevos.length >= 20;
          
          // Re-aplicar filtro si hay búsqueda activa
          final filtro = _controladorBusqueda.text;
          if (filtro.isNotEmpty) {
             _usuariosFiltrados = _usuariosOriginales.where((u) => 
                u.nombreUsuario.toLowerCase().contains(filtro.toLowerCase()) ||
                u.email.toLowerCase().contains(filtro.toLowerCase())
             ).toList();
          } else {
            _usuariosFiltrados = List.from(_usuariosOriginales);
          }
        } else {
          _hayMasUsuarios = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 8), // Más compacto
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título y Botón
                      Row(
                        children: [
                          Text(
                            'EXPLORAR MUNDOS',
                            style: GoogleFonts.outfit(
                              fontSize: 18, // Reducido de 24
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
                      
                      // Pestañas
                      Row(
                        children: [
                          _buildPestana('COMUNIDADES', 0),
                          const SizedBox(width: 24),
                          _buildPestana('PERFILES', 1),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Barra de Búsqueda
                      TextField(
                        controller: _controladorBusqueda,
                        onChanged: (valor) => _cargarDatos(filtro: valor),
                        style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _indicePestana == 0 ? 'Busca una comunidad...' : 'Busca a un michi...',
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
              ),
              
              if (_estaCargando)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                )
              else if (_indicePestana == 0)
                _buildSliverGridComunidades()
              else
                _buildSliverGridPerfiles(),
              
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

  Widget _buildPestana(String texto, int index) {
    bool activa = _indicePestana == index;
    return BotonTactil(
      onTap: () {
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

  Widget _buildSliverGridComunidades() {
    if (_comunidades.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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

  Widget _buildSliverGridPerfiles() {
    if (_usuariosFiltrados.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'No encontramos perfiles...',
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
            final usuario = _usuariosFiltrados[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: usuario.urlAvatar != null ? NetworkImage(usuario.urlAvatar!) : null,
                  child: usuario.urlAvatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(usuario.nombreUsuario, style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                subtitle: Text(usuario.email, style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                    if (inicioState != null) {
                      inicioState.seleccionarUsuario(usuario);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => PantallaDetallePerfil(usuario: usuario)),
                      );
                    }
                  });
                },
              ),
            );
          },
          childCount: _usuariosFiltrados.length,
        ),
      ),
    );
  }
}
