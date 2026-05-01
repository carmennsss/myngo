import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../models/usuario.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../comunidades/pantalla_enviar_propuesta.dart';
import '../inicio/pantalla_inicio.dart';

// Widgets extraídos
import 'widgets_tienda/tienda_preview_section.dart';
import 'widgets_tienda/lista_mejoras_tab.dart';

/// Pantalla de tienda de mejoras visuales (Avatares, Marcos, Fondos, Estilos).
///
/// Permite previsualizar y comprar mejoras tanto globales como exclusivas de comunidad.
class PantallaTiendaMejoras extends StatefulWidget {
  final bool esVistaIntegrada;
  final Comunidad? comunidad;
  final Function(String)? onCategoryChanged;
  final Function(int)? onPuntosActualizados;

  const PantallaTiendaMejoras({
    super.key,
    this.esVistaIntegrada = false,
    this.comunidad,
    this.onCategoryChanged,
    this.onPuntosActualizados,
  });

  @override
  State<PantallaTiendaMejoras> createState() => _PantallaTiendaMejorasState();
}

class _PantallaTiendaMejorasState extends State<PantallaTiendaMejoras>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  int _tabIndex = 0; // 0: Global, 1: Comunidad
  bool _esModerador = false;
  bool _modoGestion = false;

  Usuario? _usuarioActual;
  String? _previewAvatar;
  String? _previewMarco;
  String? _previewFondo;
  Map<String, dynamic>? _previewEstiloPost;

  List<CatalogoMejoras> _mejorasCatalogo = [];
  List<dynamic> _misMejoras = [];
  bool _cargandoTienda = true;
  String? _errorTienda;

  @override
  void initState() {
    super.initState();
    _inicializarTienda();
    _subTabController =
        TabController(length: widget.comunidad == null ? 4 : 3, vsync: this);
    _subTabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _subTabController.removeListener(_handleTabChange);
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _inicializarTienda() async {
    await _cargarDatosUsuario();
    await _cargarDatosTienda();
    if (widget.comunidad != null) {
      _tabIndex = 1;
      await _checkRol();
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final res = await ServicioUsuarios().obtenerDatosPropios();
    if (mounted && res.exito) {
      setState(() {
        _usuarioActual = res.datos;
        _previewAvatar = _usuarioActual?.urlAvatar;
        _previewMarco = _usuarioActual?.marco;
        _previewFondo = _usuarioActual?.fondo;
        _previewEstiloPost = _usuarioActual?.estiloPost;
      });
    }
  }

  Future<void> _checkRol() async {
    final userId = await ServicioUsuarios().obtenerIdUsuario();
    if (userId != null && widget.comunidad != null) {
      final res = await ServicioComunidades()
          .obtenerRolUsuarioEnComunidad(widget.comunidad!.id, userId);
      if (mounted && res.exito) {
        setState(() {
          _esModerador =
              res.datos == 'Administrador' || res.datos == 'Moderador';
          if (_esModerador) _modoGestion = true;
        });
      }
    }
  }

  void _handleTabChange() {
    if (!_subTabController.indexIsChanging) {
      final tipos = ['Avatar', 'Marco', 'Fondo', 'Estilo Post'];
      if (_subTabController.index < tipos.length) {
        widget.onCategoryChanged?.call(tipos[_subTabController.index]);
      }
    }
  }

  Future<void> _cargarDatosTienda() async {
    if (!mounted) return;
    setState(() => _cargandoTienda = true);

    try {
      final resCatalogo = widget.comunidad != null
          ? await ServicioMejoras().obtenerMejorasComunidad(widget.comunidad!.id)
          : await ServicioMejoras().obtenerMejorasGlobales();

      final resMisMejoras = await ServicioMejoras().obtenerMisMejoras();

      if (mounted) {
        setState(() {
          _cargandoTienda = false;
          _mejorasCatalogo = resCatalogo.datos ?? [];
          _errorTienda = resCatalogo.exito ? null : resCatalogo.mensaje;
          _misMejoras = resMisMejoras.datos ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoTienda = false;
          _errorTienda = 'Error de conexión 😿';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esAncho = MediaQuery.of(context).size.width > 1000;

    final shopSection = Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _cargandoTienda
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC35E34)))
              : _errorTienda != null
                  ? Center(
                      child: Text(_errorTienda!,
                          style: GoogleFonts.outfit(color: Colors.grey)))
                  : TabBarView(
                      controller: _subTabController,
                      children: [
                        _buildTab('Avatar'),
                        _buildTab('Marco'),
                        _buildTab('Fondo'),
                        if (widget.comunidad == null) _buildTab('Estilo Post'),
                      ],
                    ),
        ),
      ],
    );

    final previewSection = Container(
      color: Colors.white.withOpacity(0.5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: TiendaPreviewSection(
          usuarioActual: _usuarioActual,
          previewAvatar: _previewAvatar,
          previewMarco: _previewMarco,
          previewFondo: _previewFondo,
          previewEstiloPost: _previewEstiloPost,
        ),
      ),
    );

    final content = esAncho
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: shopSection),
              const VerticalDivider(width: 1, color: Color(0xFFE8D5C4)),
              Expanded(flex: 2, child: previewSection),
            ],
          )
        : Column(
            children: [
              TiendaPreviewSection(
                usuarioActual: _usuarioActual,
                previewAvatar: _previewAvatar,
                previewMarco: _previewMarco,
                previewFondo: _previewFondo,
                previewEstiloPost: _previewEstiloPost,
              ),
              Expanded(child: shopSection),
            ],
          );

    return widget.esVistaIntegrada
        ? Container(color: const Color(0xFFFEF5F1), child: content)
        : Scaffold(
            backgroundColor: const Color(0xFFFEF5F1),
            appBar: _buildAppBar(),
            body: content,
            floatingActionButton: _buildFAB(),
          );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D0BD).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        isScrollable: widget.comunidad == null,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        controller: _subTabController,
        labelColor: const Color(0xFFC35E34),
        tabs: [
          const Tab(text: 'Avatares'),
          const Tab(text: 'Marcos'),
          const Tab(text: 'Fondos'),
          if (widget.comunidad == null) const Tab(text: 'Estilos Post'),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildTab(String tipo) {
    return ListaMejorasTab(
      tipo: tipo,
      comunidadId: widget.comunidad?.id,
      esModerador: _esModerador,
      modoGestion: _modoGestion,
      usuarioActual: _usuarioActual,
      mejoras: _mejorasCatalogo,
      misMejoras: _misMejoras,
      onRefresh: _cargarDatosTienda,
      onPuntosActualizados: (p) {
        widget.onPuntosActualizados?.call(p);
        _cargarDatosUsuario();
      },
      onPreviewRequested: (item) {
        setState(() {
          if (tipo == 'Avatar') _previewAvatar = item.urlRecurso;
          if (tipo == 'Marco') _previewMarco = item.urlRecurso;
          if (tipo == 'Fondo') _previewFondo = item.urlRecurso;
          if (tipo == 'Estilo Post') _previewEstiloPost = item.datosExtra;
        });
=======
  void _irAEnviarPropuesta() {
    if (widget.comunidad == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEnviarPropuesta(comunidad: widget.comunidad!),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_usuarioActual == null) return const SizedBox.shrink();
    final bool esAncho = MediaQuery.of(context).size.width > 1000;

    String? fondoFiltro = _previewFondo;
    String? avatarFiltro = _previewAvatar;
    String? marcoFiltro = _previewMarco;
    String nombreAMostrar = _usuarioActual?.nombreUsuario ?? 'Usuario';

    if (widget.comunidad != null) {
      if (_previewFondo == _usuarioActual?.fondo) {
        fondoFiltro = widget.comunidad!.urlPortada.isNotEmpty ? widget.comunidad!.urlPortada : null;
      }
      if (_previewAvatar == _usuarioActual?.urlAvatar) {
        avatarFiltro = widget.comunidad!.urlPortada.isNotEmpty ? widget.comunidad!.urlPortada : null;
      }
      if (_previewMarco == _usuarioActual?.marco) {
        marcoFiltro = null;
      }
      nombreAMostrar = widget.comunidad!.nombre;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: esAncho ? 40 : 24, vertical: 16),
      child: Column(
        children: [
          ProfilePreview(
            fondoUrl: fondoFiltro,
            avatarUrl: avatarFiltro,
            marcoUrl: marcoFiltro,
            nombreUsuario: nombreAMostrar,
            puntos: _usuarioActual?.puntos ?? 0,
          ),
          if (widget.comunidad == null) ...[
            const SizedBox(height: 20),
            // Mock Post
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.article_rounded, color: Colors.grey, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ASÍ SE VERÁ TU POST',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PostPreview(
                  estilo: _previewEstiloPost,
                  avatarUrl: _previewAvatar,
                  marcoUrl: _previewMarco,
                  nombreUsuario: _usuarioActual?.nombreUsuario ?? 'Usuario',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ListaMejorasTab extends StatefulWidget {
  final String tipo;
  final int? comunidadId;
  final bool esModerador;
  final bool modoGestion;
  final Usuario? usuarioActual;
  final List<CatalogoMejoras> mejoras;
  final List<dynamic> misMejoras;
  final VoidCallback onRefresh;
  final Function(int)? onPuntosActualizados;
  final Function(CatalogoMejoras) onPreviewRequested;

  const _ListaMejorasTab({
    required this.tipo,
    this.comunidadId,
    this.esModerador = false,
    this.modoGestion = false,
    this.usuarioActual,
    required this.mejoras,
    required this.misMejoras,
    required this.onRefresh,
    this.onPuntosActualizados,
    required this.onPreviewRequested,
  });

  @override
  State<_ListaMejorasTab> createState() => _ListaMejorasTabState();
}

class _ListaMejorasTabState extends State<_ListaMejorasTab> {
  final ServicioMejoras _servicioMejoras = ServicioMejoras();

  List<CatalogoMejoras> get _mejorasFiltradas {
    var filtradas = widget.mejoras.where((m) => m.tipo.toLowerCase() == widget.tipo.toLowerCase()).toList();
    if (!widget.modoGestion) {
      filtradas = filtradas.where((m) => m.estaActivo).toList();
    }
    return filtradas;
  }

  bool _tieneMejora(int mejoraId) {
    try {
      return widget.misMejoras.any((m) => m != null && m is Map && m['mejora'] == mejoraId);
    } catch (e) {
      return false;
    }
  }

  bool _tieneEquipada(int mejoraId) {
    try {
      return widget.misMejoras.any((m) => m != null && m is Map && m['mejora'] == mejoraId && m['esta_equipada'] == true);
    } catch (e) {
      return false;
    }
  }

  Future<void> _equipar(CatalogoMejoras mejora) async {
    final res = await _servicioMejoras.equiparMejora(mejora.id);
    if (mounted) {
      if (res.exito) {
        notificarMejoraEquipada(); // Notifica al perfil que debe recargarse
        widget.onRefresh();
        widget.onPuntosActualizados?.call(widget.usuarioActual?.puntos ?? 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmarCompra(CatalogoMejoras mejora) async {
    final int puntosActuales = widget.usuarioActual?.puntos ?? 0;
    final int puntosRestantes = puntosActuales - mejora.precioPuntos;

    if (puntosRestantes < 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Puntos insuficientes 🐾', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text('Necesitas ${mejora.precioPuntos} puntos, pero solo tienes $puntosActuales.', style: GoogleFonts.outfit()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ENTENDIDO', style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Confirmar compra?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estás a punto de adquirir este diseño:', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF5F1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.pets_rounded, color: Color(0xFFC35E34), size: 20),
                  const SizedBox(width: 12),
                  Text('${mejora.precioPuntos} puntos', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFFC35E34))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tus puntos:', style: GoogleFonts.outfit(fontSize: 14)),
                Text('$puntosActuales', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quedarás con:', style: GoogleFonts.outfit(fontSize: 14)),
                Text('$puntosRestantes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC35E34),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('COMPRAR AHORA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _servicioMejoras.comprarMejora(mejora.id);
      if (mounted) {
        if (res.exito) {
          widget.onRefresh();
          if (res.datos != null && res.datos is int) {
            widget.onPuntosActualizados?.call(res.datos as int);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Compra realizada! 🐾'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _mejorasFiltradas;
    if (filtradas.isEmpty) {
      final String tipoPlural = widget.tipo.toLowerCase() == 'avatar' ? 'avatares' : '${widget.tipo.toLowerCase()}s';
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

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final mejora = filtradas[index];
        final bool estaActivo = mejora.estaActivo;
        final bool laTiene = _tieneMejora(mejora.id);
        final bool estaEquipada = _tieneEquipada(mejora.id);
        
        Widget card = GestureDetector(
          onTap: () => widget.onPreviewRequested(mejora),
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
                      ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          (estaActivo && !estaEquipada)
                            ? [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0] // Normal
                            : [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0] // Grayscale
                        ),
                        child: Opacity(
                          opacity: estaActivo ? 1.0 : 0.6,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Container(
                              color: const Color(0xFFFBE9E0),
                              child: (mejora.tipo == 'Estilo Post' && mejora.datosExtra != null)
                                  ? _buildMiniEstiloPreview(mejora.datosExtra!)
                                  : (mejora.urlRecurso.isNotEmpty
                                      ? Image.network(
                                          mejora.urlRecurso,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade300, size: 36),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300, size: 36),
                                        )),
                            ),
                          ),
                        ),
                      ),
                      if (estaEquipada)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          ),
                        ),

                    if (!estaActivo)
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'OCULTO',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Opacity(
                  opacity: estaActivo ? 1.0 : 0.7,
                  child: Column(
                    children: [
                      Text(
                        mejora.tipo,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A4440),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mejora.nombreCreador != null)
                        Text(
                          'por ${mejora.nombreCreador}',
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      if (estaActivo)
                        _buildActionButton(mejora, laTiene, estaEquipada)
                      else
                        const Text('Ítem desactivado', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));

        if (widget.esModerador && widget.modoGestion) {
          return Stack(
            children: [
              card,
              Positioned(
                top: 4,
                right: 4,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: estaActivo,
                    activeColor: const Color(0xFFC35E34),
                    onChanged: (val) => _toggleActivo(mejora, val),
                  ),
                ),
              ),
              Positioned(
                bottom: 80, // Subido un poco para no tapar el botn
                right: 8,
                child: BotonTactil(
                  onTap: () => _mostrarDialogoPrecio(mejora),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFFC35E34), size: 16),
                  ),
                ),
              ),
            ],
          );
        }

        return card;
>>>>>>> Stashed changes
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFEF5F1),
      elevation: 0,
      title: Text(
        widget.comunidad != null
            ? 'Tienda: ${widget.comunidad!.nombre}'
            : 'Tienda de Mejoras',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
      ),
      centerTitle: true,
    );
  }

  Widget? _buildFAB() {
    if (widget.comunidad == null) return null;
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) =>
                  PantallaEnviarPropuesta(comunidad: widget.comunidad!))),
      label: const Text('Sugerir Diseño'),
      icon: const Icon(Icons.add_photo_alternate_rounded),
      backgroundColor: widget.comunidad!.colorTema,
    );
  }
}
