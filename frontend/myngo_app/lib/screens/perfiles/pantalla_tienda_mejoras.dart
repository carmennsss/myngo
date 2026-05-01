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

      final resMisMejoras = await ServicioMejoras().obtenerInventarioUsuario();

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
