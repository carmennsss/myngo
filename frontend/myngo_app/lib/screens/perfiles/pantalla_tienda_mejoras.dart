import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../models/usuario.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_usuarios.dart';

// Widgets extraídos
import 'widgets_tienda/tienda_preview_section.dart';
import 'widgets_tienda/lista_mejoras_tab.dart';
import '../comunidades/pantalla_enviar_propuesta.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Tienda de mejoras visuales: Avatares, Marcos, Fondos y Estilos de post.
// Muestra una previsualización en vivo mientras el usuario navega por el catálogo.
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
        TabController(length: 4, vsync: this);
    _subTabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(PantallaTiendaMejoras oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subTabController.removeListener(_handleTabChange);
    _subTabController.dispose();
    super.dispose();
  }

  // Carga primero los datos del usuario y luego el catálogo de mejoras
  Future<void> _inicializarTienda() async {
    await _cargarDatosUsuario();
    if (widget.comunidad != null) {
      _tabIndex = 1;
    }
    await _cargarDatosTienda();
  }

  // Trae los datos del usuario logueado y pre-carga los valores de previsualización
  Future<void> _cargarDatosUsuario() async {
    final res = await ServicioUsuarios().obtenerDatosPropios();
    if (mounted && res.exito) {
      setState(() {
        _usuarioActual = res.datos;
        // Previsualizamos nuestro perfil
        _previewAvatar = _usuarioActual?.urlAvatar;
        _previewMarco = _usuarioActual?.marco;
        _previewFondo = _usuarioActual?.fondo;
        _previewFondoFeed = _usuarioActual?.fondoPerfil;
        _previewEstiloPost = _usuarioActual?.estiloPost;
      });
    }
  }

  // Notifica a la pantalla padre la categoría activa cuando cambia la pestaña
  void _handleTabChange() {
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

  // Descarga el catálogo global y las mejoras ya compradas por el usuario
  Future<void> _cargarDatosTienda() async {
    if (!mounted) return;
    setState(() => _cargandoTienda = true);

    try {
      final resCatalogo = await ServicioMejoras().obtenerMejorasGlobales();
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
    return Builder(
      builder: (context) {
        // Actualizamos listeners si es necesario
        _subTabController.removeListener(_handleTabChange);
        _subTabController.addListener(_handleTabChange);

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
                            _buildTab(tr('storeTypePostStyle'), tr),
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
              comunidad: widget.comunidad,
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
              // Preview del perfil — altura fija en móvil para no desbordar
              SizedBox(
                height: 260,
                child: Container(
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TiendaPreviewSection(
                      usuarioActual: _usuarioActual,
                      comunidad: widget.comunidad,
                      previewAvatar: _previewAvatar,
                      previewMarco: _previewMarco,
                      previewFondo: _previewFondo,
                      previewEstiloPost: _previewEstiloPost,
                    ),
                  ),
                ),
              ),
              // Sección de mejoras — siempre Expanded para llenar el resto de pantalla
              Expanded(child: shopSection),
            ],
          );


    return widget.esVistaIntegrada
        ? Container(
            constraints: BoxConstraints(
              // Aseguramos que tenga una altura razonable si está en un CustomScrollView
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


  // Barra de pestañas (Avatares / Marcos / Fondos / Estilos Post)
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


  // Cada pestaña pasa el tipo de mejora al ListaMejorasTab y gestiona la previsualización
  Widget _buildTab(String tipo, String Function(String) tr) {
    return ListaMejorasTab(
      tipo: tipo,
      usuarioActual: _usuarioActual,
      mejoras: _mejorasCatalogo,
      misMejoras: _misMejoras,
      onRefresh: () => _cargarDatosTienda(),
      modoGestion: _esModerador,
      comunidadId: widget.comunidad?.id,
      esModerador: _esModerador,
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


  PreferredSizeWidget _buildAppBar(dynamic tr) {
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
                           _esModerador; 

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

  bool get _esModerador {
    if (widget.comunidad == null) return false;
    return widget.comunidad!.miRol == 'Moderador' || widget.comunidad!.miRol == 'Administrador';
  }
}
