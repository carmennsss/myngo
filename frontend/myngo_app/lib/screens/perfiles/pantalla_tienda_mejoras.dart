import 'package:flutter/material.dart';
import '../../tolgee/translation_widget.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../models/usuario.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../comunidades/pantalla_enviar_propuesta.dart';

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
  String? _previewFondoFeed;
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
        TabController(length: widget.comunidad != null ? 3 : 4, vsync: this);
    _subTabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(PantallaTiendaMejoras oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad?.id != widget.comunidad?.id) {
      _subTabController.removeListener(_handleTabChange);
      _subTabController.dispose();
      _subTabController = TabController(length: widget.comunidad != null ? 3 : 4, vsync: this);
      _subTabController.addListener(_handleTabChange);
      _inicializarTienda();
    }
  }

  @override
  void dispose() {
    _subTabController.removeListener(_handleTabChange);
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _inicializarTienda() async {
    await _cargarDatosUsuario();
    if (widget.comunidad != null) {
      _tabIndex = 1;
      await _checkRol();
    }
    await _cargarDatosTienda();
  }

  Future<void> _cargarDatosUsuario() async {
    final res = await ServicioUsuarios().obtenerDatosPropios();
    if (mounted && res.exito) {
      setState(() {
        _usuarioActual = res.datos;
        
        if (widget.comunidad != null) {
          // Si es tienda de comunidad, previsualizamos la comunidad por defecto
          _previewAvatar = widget.comunidad!.urlAvatar;
          _previewFondo = widget.comunidad!.urlFondo ?? widget.comunidad!.urlPortada;
          _previewMarco = null; // Las comunidades no suelen tener marco por defecto
          _previewEstiloPost = widget.comunidad!.fondoPostsConfig;
        } else {
          // Si es tienda personal, previsualizamos nuestro perfil
          _previewAvatar = _usuarioActual?.urlAvatar;
          _previewMarco = _usuarioActual?.marco;
          _previewFondo = _usuarioActual?.fondo;
          _previewFondoFeed = _usuarioActual?.fondoPerfil;
          _previewEstiloPost = _usuarioActual?.estiloPost;
        }
      });
    }
  }

  void _handleTabChange(String Function(String) tr) {
    if (!_subTabController.indexIsChanging) {
      final tipos = [
        tr('storeTypeAvatar'),
        tr('storeTypeFrame'),
        tr('storeTypeBackground'),
        tr('storeTypePostStyle')
      ];
      if (_subTabController.index < tipos.length) {
        widget.onCategoryChanged?.call(tipos[_subTabController.index]);
      }
    }
  }

  Future<void> _cargarDatosTienda(String Function(String) tr) async {
    if (!mounted) return;
    setState(() => _cargandoTienda = true);

    try {
      final resCatalogo = widget.comunidad != null
          ? (_esModerador 
              ? await ServicioMejoras().obtenerCatalogoGestion(widget.comunidad!.id)
              : await ServicioMejoras().obtenerMejorasComunidad(widget.comunidad!.id))
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
          _errorTienda = tr('storeErrorConnection');
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) {
        // Actualizamos listeners si es necesario
        _subTabController.removeListener(() => _handleTabChange(tr));
        _subTabController.addListener(() => _handleTabChange(tr));

        final bool esAncho = MediaQuery.of(context).size.width > 1000;

        final shopSection = Column(
          children: [
            _buildTabBar(tr),
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
                            _buildTab(tr('storeTypeAvatar'), tr),
                            _buildTab(tr('storeTypeFrame'), tr),
                            _buildTab(tr('storeTypeBackground'), tr),
                            if (widget.comunidad == null) _buildTab(tr('storeTypePostStyle'), tr),
                          ],
                        ),
            ),
          ],
        );

        final previewSection = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            image: (_previewFondoFeed != null && _previewFondoFeed!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(_previewFondoFeed!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.6),
                      BlendMode.lighten,
                    ),
                  )
                : null,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: TiendaPreviewSection(
              usuarioActual: _usuarioActual,
              previewAvatar: _previewAvatar,
              previewMarco: _previewMarco,
              previewFondo: _previewFondo,
              previewEstiloPost: _previewEstiloPost,
              comunidad: widget.comunidad,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: (_previewFondoFeed != null && _previewFondoFeed!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(_previewFondoFeed!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.white.withOpacity(0.6),
                                BlendMode.lighten,
                              ),
                            )
                          : null,
                    ),
                    child: TiendaPreviewSection(
                      usuarioActual: _usuarioActual,
                      previewAvatar: _previewAvatar,
                      previewMarco: _previewMarco,
                      previewFondo: _previewFondo,
                      previewEstiloPost: _previewEstiloPost,
                      comunidad: widget.comunidad,
                    ),
                  ),
                  widget.esVistaIntegrada 
                    ? SizedBox(height: 500, child: shopSection) 
                    : Expanded(child: shopSection),
                ],
              );

        return widget.esVistaIntegrada
            ? Container(
                constraints: BoxConstraints(
                  minHeight: 400,
                  maxHeight: esAncho ? 800 : 1200, 
                ),
                color: const Color(0xFFFEF5F1), 
                child: content
              )
            : Scaffold(
                backgroundColor: const Color(0xFFFEF5F1),
                appBar: _buildAppBar(tr),
                body: content,
                floatingActionButton: _buildFAB(tr),
              );
      }
    );
  }


  Widget _buildTabBar(String Function(String) tr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D0BD).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        controller: _subTabController,
        labelColor: const Color(0xFFC35E34),
        tabs: [
          Tab(text: tr('storeTabAvatars')),
          Tab(text: tr('storeTabFrames')),
          Tab(text: tr('storeTabBackgrounds')),
          if (widget.comunidad == null) Tab(text: tr('storeTabPostStyles')),
        ],
      ),
    );
  }


  Widget _buildTab(String tipo, String Function(String) tr) {
    return ListaMejorasTab(
      tipo: tipo,
      comunidadId: widget.comunidad?.id,
      esModerador: _esModerador,
      modoGestion: _modoGestion,
      usuarioActual: _usuarioActual,
      mejoras: _mejorasCatalogo,
      misMejoras: _misMejoras,
      onRefresh: () => _cargarDatosTienda(tr),
      onPuntosActualizados: (p) {
        widget.onPuntosActualizados?.call(p);
        _cargarDatosUsuario();
      },
      onPreviewRequested: (item) {
        setState(() {
          if (tipo == tr('storeTypeAvatar')) _previewAvatar = item.urlRecurso;
          if (tipo == tr('storeTypeFrame')) _previewMarco = item.urlRecurso;
          if (tipo == tr('storeTypeBackground')) {
            _previewFondo = item.urlRecurso;
            _previewFondoFeed = item.urlRecurso;
          }
          if (tipo == tr('storeTypePostStyle')) _previewEstiloPost = item.datosExtra;
        });
      },
    );
  }


  PreferredSizeWidget _buildAppBar(String Function(String, [Map<String, String>?]) tr) {
    return AppBar(
      backgroundColor: const Color(0xFFFEF5F1),
      elevation: 0,
      title: Text(
        widget.comunidad != null
            ? tr('storeCommunityTitle', {'name': widget.comunidad!.nombre})
            : tr('storePersonalTitle'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
      ),
      centerTitle: true,
    );
  }


  Widget? _buildFAB(String Function(String) tr) {
    if (widget.comunidad == null) return null;
    
    // Si eres la creadora (por ID) o tienes rol de Administrador, tienes control total
    final bool esCreador = (_usuarioActual != null && _usuarioActual!.id == widget.comunidad!.creadorId) ||
                           widget.comunidad!.miRol == 'Administrador' ||
                           _esModerador; // Si es moderador/admin en esta vista, le damos el botón de gestión

    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) =>
                  PantallaEnviarPropuesta(comunidad: widget.comunidad!))),
      label: Text(esCreador ? tr('storeAddImprovedBtn') : tr('storeSuggestDesignBtn')),
      icon: Icon(esCreador ? Icons.add_to_photos_rounded : Icons.add_photo_alternate_rounded),
      backgroundColor: widget.comunidad!.colorTema,
    );
  }

}
