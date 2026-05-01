import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/configuracion.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_galeria.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../models/sala_chat.dart';
import '../../models/coleccion.dart';
import '../../providers/post_provider.dart';

import '../../widgets/dialogo_crear_post.dart';
import '../perfiles/pantalla_perfiles.dart';
import '../perfiles/pantalla_tienda_mejoras.dart';
import '../inicio/pantalla_inicio.dart';
import 'pantalla_admin_comunidad.dart';
import 'pantalla_enviar_propuesta.dart';

// Widgets extraídos
import 'widgets_detalle/header_detalle_comunidad.dart';
import 'widgets_detalle/seccion_posts_comunidad.dart';
import 'widgets_detalle/seccion_galeria_comunidad.dart';
import 'widgets_detalle/seccion_chat_comunidad.dart';
import 'widgets_detalle/preview_comunidad.dart';
import 'widgets_detalle/dialogos_comunidad.dart';

/// Pantalla principal de detalle de una comunidad.
///
/// Gestiona la visualización de posts, tienda, galería, chats y miembros,
/// adaptándose según si el usuario es miembro o no (modo preview).
class PantallaDetalleComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onMembershipChanged;
  final int initialIndex;

  const PantallaDetalleComunidad({
    super.key,
    required this.comunidad,
    this.esIntegrada = false,
    this.onBack,
    this.onMembershipChanged,
    this.initialIndex = 0,
  });

  @override
  State<PantallaDetalleComunidad> createState() =>
      _PantallaDetalleComunidadState();
}

class _PantallaDetalleComunidadState extends State<PantallaDetalleComunidad> {
  final _servicio = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  final _servicioGaleria = ServicioGaleria();

  bool _estaCargandoPeticion = false;
  bool _estaCargandoDatos = false;
  int? _miId;
  int _indiceSeccion = 0;
  String _miRol = 'Miembro';
  String _tipoMejoraSeleccionado = 'Avatar';

  List<Publicacion>? _publicaciones;
  List<SalaChat>? _salasChat;
  List<Coleccion>? _colecciones;
  Key _galeriaKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _indiceSeccion = widget.initialIndex;
    _inicializarDatos();
  }

  @override
  void didUpdateWidget(PantallaDetalleComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _indiceSeccion = 0;
      _publicaciones = null;
      _salasChat = null;
      _colecciones = null;
      _inicializarDatos();
    }
  }

  Future<void> _inicializarDatos() async {
    await _obtenerMiId();
    await _cargarDatosSeccion(_indiceSeccion);
    await _cargarColecciones();

    if (_miId != null) {
      final res = await _servicio.obtenerRolUsuarioEnComunidad(
          widget.comunidad.id, _miId!);
      if (res.exito && res.datos != null && mounted) {
        setState(() => _miRol = res.datos!);
      }
    }
  }

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  Future<void> _cargarColecciones() async {
    final res = await _servicioGaleria.obtenerColecciones(
        comunidadId: widget.comunidad.id);
    if (res.exito && res.datos != null && mounted) {
      setState(() => _colecciones = res.datos!);
    }
  }

  Future<void> _cargarDatosSeccion(int index) async {
    if (!mounted) return;
    setState(() {
      _estaCargandoDatos = true;
      if (index == 0) _publicaciones = null;
      if (index == 3) _salasChat = null;
    });

    try {
      if (index == 0) {
        final res = await _servicio.obtenerPublicacionesComunidad(widget.comunidad.id);
        if (res.exito && mounted) setState(() => _publicaciones = res.datos);
      } else if (index == 2) {
        setState(() => _galeriaKey = UniqueKey());
        await _cargarColecciones();
      } else if (index == 3) {
        final res = await _servicio.obtenerSalasChat(widget.comunidad.id);
        if (res.exito && mounted) setState(() => _salasChat = res.datos);
      }
    } finally {
      if (mounted) setState(() => _estaCargandoDatos = false);
    }
  }

  Future<void> _gestionarMembresia() async {
    setState(() => _estaCargandoPeticion = true);
    final respuesta = await _servicio.unirseAComunidad(widget.comunidad.id);

    if (mounted) {
      setState(() => _estaCargandoPeticion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito
              ? const Color(0xFF248EA6)
              : const Color(0xFFD95F43),
        ),
      );
      if (respuesta.exito) {
        if (respuesta.datos?['estado'] == 'ACEPTADO') {
          setState(() {
            widget.comunidad.esMiembro = true;
          });
          _cargarDatosSeccion(0);
          widget.onMembershipChanged?.call();
        } else if (respuesta.datos?['estado'] == 'SOLICITUD') {
          setState(() {
            widget.comunidad.esPendiente = true;
          });
          widget.onMembershipChanged?.call();
        }
      }
    }
  }

  // --- HELPERS DE COLOR Y ESTILO ---
  Color _colorPagina(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  bool _esAppClara(BuildContext context) =>
      _colorPagina(context).computeLuminance() > 0.5;
  Color _colorTextoPrincipal(BuildContext context) =>
      _esAppClara(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _colorTextoSecundario(BuildContext context) =>
      _esAppClara(context) ? Colors.grey.shade700 : Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;
    final esMiembro = widget.comunidad.esMiembro || esCreador;

    if (!esMiembro) {
      return PreviewComunidad(
        comunidad: widget.comunidad,
        miId: _miId,
        indiceSeccion: _indiceSeccion,
        publicaciones: _publicaciones,
        colecciones: _colecciones,
        estaCargandoDatos: _estaCargandoDatos,
        estaCargandoPeticion: _estaCargandoPeticion,
        onTabChanged: (idx) => setState(() {
          _indiceSeccion = idx;
          _cargarDatosSeccion(idx);
        }),
        onJoin: _gestionarMembresia,
        onBack: widget.onBack ?? () => Navigator.pop(context),
        backgroundFeed: _buildBackgroundFeed(),
        esAppClara: _esAppClara(context),
        colorTextoPrincipal: _colorTextoPrincipal(context),
        colorTextoSecundario: _colorTextoSecundario(context),
      );
    }

    final dashboard = Stack(
      children: [
        Positioned.fill(child: _buildBackgroundFeed()),
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                pinned: false,
                stretch: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: HeaderDetalleComunidad(
                    comunidad: widget.comunidad,
                    miId: _miId,
                    onCerrar: widget.onBack ?? () => Navigator.pop(context),
                    onComunidadActualizada: (c) => setState(() {}),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: _buildSubNav(context),
                ),
              ),
            ];
          },
          body: _buildBodyContent(),
        ),
        _buildFAB(),
      ],
    );

    return widget.esIntegrada
        ? Container(color: _colorPagina(context), child: dashboard)
        : Scaffold(backgroundColor: _colorPagina(context), body: dashboard);
  }

  Widget _buildBodyContent() {
    switch (_indiceSeccion) {
      case 0:
        return SeccionPostsComunidad(
          publicaciones: _publicaciones,
          estaCargando: _estaCargandoDatos,
          onRefresh: () => _cargarDatosSeccion(0),
          esAppClara: _esAppClara(context),
        );
      case 1:
        return _buildStore();
      case 2:
        return SeccionGaleriaComunidad(
          comunidad: widget.comunidad,
          colecciones: _colecciones,
          estaCargando: _estaCargandoDatos,
          onNuevaColeccion: () => _mostrarDialogoNuevaColeccion(context),
          galeriaKey: _galeriaKey,
        );
      case 3:
        return SeccionChatComunidad(
          comunidad: widget.comunidad,
          salasChat: _salasChat,
          estaCargando: _estaCargandoDatos,
          onCrearSala: () {},
          esAppClara: _esAppClara(context),
          colorTextoPrincipal: _colorTextoPrincipal(context),
          colorTextoSecundario: _colorTextoSecundario(context),
        );
      case 4:
        return const PantallaPerfiles();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSubNav(BuildContext context) {
    return Container(
      color: _colorPagina(context),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildNavItem(0, 'POSTS', Icons.grid_view_rounded),
          _buildNavItem(1, 'TIENDA', Icons.shopping_bag_rounded),
          _buildNavItem(2, 'GALERÍA', Icons.photo_library_rounded),
          _buildNavItem(3, 'CHATS', Icons.chat_bubble_rounded),
          _buildNavItem(4, 'MIEMBROS', Icons.people_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final activo = _indiceSeccion == index;
    final color = widget.comunidad.colorTema;
    return InkWell(
      onTap: () {
        setState(() => _indiceSeccion = index);
        _cargarDatosSeccion(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activo ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: activo ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: activo ? color : Colors.grey,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    if (_indiceSeccion == 0) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: FloatingActionButton.extended(
          onPressed: () => _mostrarDialogoNuevoPost(context),
          label: Text('Miau Post',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          icon:
              const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
          backgroundColor: widget.comunidad.colorTema,
        ),
      );
    }
    if (_indiceSeccion == 1) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: FloatingActionButton.extended(
          onPressed: () => _irAEnviarPropuesta(),
          label: Text('Sugerir $_tipoMejoraSeleccionado',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          icon: const Icon(Icons.palette_rounded, color: Colors.white),
          backgroundColor: widget.comunidad.colorTema,
        ),
      );
    }
    return const SizedBox();
  }

  // --- DIALOGOS Y OTROS WIDGETS AUXILIARES (KEPT FOR SIMPLICITY) ---

  void _mostrarDialogoNuevoPost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearPost(
        titulo: 'Nueva Publicación 🐾',
        onPublicar: (texto, imagenes, etiquetas) async {
          final provider = Provider.of<PostProvider>(context, listen: false);
          final exito = await provider.crearPost(
            comunidadId: widget.comunidad.id,
            texto: texto,
            imagenes: imagenes,
            etiquetas: etiquetas,
          );
          if (exito && mounted) {
            _cargarDatosSeccion(0);
            return true;
          }
          return false;
        },
      ),
    );
  }

  void _mostrarDialogoNuevaColeccion(BuildContext context) {
    DialogosComunidad.mostrarDialogoNuevaColeccion(
      context,
      comunidadId: widget.comunidad.id,
      onCreada: _cargarColecciones,
    );
  }

  Widget _buildStore() {
    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
    return PantallaTiendaMejoras(
      esVistaIntegrada: true,
      comunidad: widget.comunidad,
      onCategoryChanged: (tipo) =>
          setState(() => _tipoMejoraSeleccionado = tipo),
      onPuntosActualizados: (p) => inicioState?.actualizarPuntos(p),
    );
  }

  void _irAEnviarPropuesta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEnviarPropuesta(
          comunidad: widget.comunidad,
          tipoInicial: _tipoMejoraSeleccionado,
        ),
      ),
    );
  }

  Widget _buildBackgroundFeed() {
    final urlFondo = widget.comunidad.urlFondo;
    return Container(
      color: _colorPagina(context),
      child: (urlFondo != null && urlFondo.isNotEmpty)
          ? Opacity(
              opacity: _esAppClara(context) ? 0.4 : 0.2,
              child: CachedNetworkImage(imageUrl: urlFondo, fit: BoxFit.cover),
            )
          : null,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}
