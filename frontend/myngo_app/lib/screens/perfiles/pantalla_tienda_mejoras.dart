import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../models/usuario.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_usuarios.dart';

// Widgets extraídos
import 'widgets_tienda/tienda_preview_section.dart';
import 'widgets_tienda/lista_mejoras_tab.dart';

// Tienda de mejoras visuales: Avatares, Marcos, Fondos y Estilos de post.
// Muestra una previsualización en vivo mientras el usuario navega por el catálogo.
class PantallaTiendaMejoras extends StatefulWidget {
  final bool esVistaIntegrada;
  final Function(String)? onCategoryChanged;
  final Function(int)? onPuntosActualizados;

  const PantallaTiendaMejoras({
    super.key,
    this.esVistaIntegrada = false,
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
      final tipos = ['Avatar', 'Marco', 'Fondo', 'Estilo Post'];
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
                        _buildTab('Estilo Post'),
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
            appBar: _buildAppBar(),
            body: content,
          );
  }

  // Barra de pestañas (Avatares / Marcos / Fondos / Estilos Post)
  Widget _buildTabBar() {
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
          const Tab(text: 'Avatares'),
          const Tab(text: 'Marcos'),
          const Tab(text: 'Fondos'),
          const Tab(text: 'Estilos Post'),
        ],
      ),
    );
  }

  // Cada pestaña pasa el tipo de mejora al ListaMejorasTab y gestiona la previsualización
  Widget _buildTab(String tipo) {
    return ListaMejorasTab(
      tipo: tipo,
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
          if (tipo == 'Fondo') {
            _previewFondo = item.urlRecurso;
            _previewFondoFeed = item.urlRecurso;
          }
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
        'Tienda de Mejoras',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
      ),
      centerTitle: true,
    );
  }
}
