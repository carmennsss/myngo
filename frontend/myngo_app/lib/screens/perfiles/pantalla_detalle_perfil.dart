import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../models/usuario.dart';
import '../../models/publicacion.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_mensajeria.dart';
import '../../utils/mejoras_notifier.dart';
import '../../providers/post_provider.dart';

import '../../widgets/dialogo_crear_post.dart';
import '../../widgets/selector_estrellas.dart';
import '../mensajeria/pantalla_chat.dart';

// Widgets extraídos
import 'widgets_detalle/header_detalle_perfil.dart';
import 'widgets_detalle/info_perfil.dart';
import 'widgets_detalle/seccion_posts_perfil.dart';
import 'widgets_detalle/seccion_guardados_perfil.dart';
import 'widgets_detalle/seccion_colecciones_perfil.dart';
import '../../services/servicio_galeria.dart';
import '../../models/coleccion.dart';

/// Pantalla que muestra los detalles del perfil de un usuario.
///
/// Implementa un diseño premium con cabecera dinámica, sistema de votación
/// y pestañas para publicaciones propias y guardadas.
class PantallaDetallePerfil extends StatefulWidget {
  final Usuario usuario;
  final int? comunidadIdContexto;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onPerfilActualizado;

  const PantallaDetallePerfil({
    super.key,
    required this.usuario,
    this.comunidadIdContexto,
    this.esIntegrada = false,
    this.onBack,
    this.onPerfilActualizado,
  });

  @override
  State<PantallaDetallePerfil> createState() => _PantallaDetallePerfilState();
}

class _PantallaDetallePerfilState extends State<PantallaDetallePerfil>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _tabActual = 0;

  int? _currentUserId;
  bool _isLoading = false;
  String? _estadoSeguimiento;
  List<Publicacion>? _publicaciones;
  bool _cargandoPublicaciones = true;

  List<Publicacion>? _publicacionesGuardadas;
  bool _cargandoGuardados = false;
  int? _filtroComunidadId;
  List<Map<String, dynamic>> _comunidadesFiltro = [];

  List<Coleccion>? _misColecciones;
  bool _cargandoColecciones = false;

  String? _biografiaLocal;
  String? _avatarLocal;
  String? _fondoLocal;
  String? _marcoLocal;
  double _ratingLocal = 0.0;

  bool _haVotadoHoy = false;
  int _totalVotosRecibidos = 0;
  int _segundosParaReinicio = 0;
  Timer? _timerReinicio;
  String? _rolEnComunidad;

  @override
  void initState() {
    super.initState();
    _biografiaLocal = widget.usuario.biografia;
    _avatarLocal = widget.usuario.urlAvatar;
    _fondoLocal = widget.usuario.fondo;
    _marcoLocal = widget.usuario.marco;
    _ratingLocal = widget.usuario.ratingActual;
    _estadoSeguimiento = widget.usuario.estadoSeguimiento;

    _inicializarDatos();
    mejoraEquipadaNotifier.addListener(_onMejoraEquipada);

    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.index != _tabActual) {
        setState(() => _tabActual = _tabController!.index);
        if (_tabActual == 1) {
          if (_publicacionesGuardadas == null) _cargarGuardados();
          if (_misColecciones == null) _cargarColecciones();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PantallaDetallePerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el usuario cambió (ej: clic en otro perfil desde el ranking)
    // reseteamos el estado y recargamos todo para el nuevo usuario.
    if (oldWidget.usuario.id != widget.usuario.id) {
      _biografiaLocal = widget.usuario.biografia;
      _avatarLocal = widget.usuario.urlAvatar;
      _fondoLocal = widget.usuario.fondo;
      _marcoLocal = widget.usuario.marco;
      _ratingLocal = widget.usuario.ratingActual;
      _estadoSeguimiento = widget.usuario.estadoSeguimiento;
      _publicaciones = null;
      _publicacionesGuardadas = null;
      _misColecciones = null;
      _cargandoPublicaciones = true;
      _rolEnComunidad = null;
      _haVotadoHoy = false;
      _timerReinicio?.cancel();
      _inicializarDatos();
    }
  }

  @override
  void dispose() {
    mejoraEquipadaNotifier.removeListener(_onMejoraEquipada);
    _timerReinicio?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) setState(() => _currentUserId = id);

    await Future.wait([
      _cargarEstadoVoto(),
      _cargarPublicaciones(),
      _cargarRolContextual(),
    ]);
  }

  void _onMejoraEquipada() {
    if (_currentUserId == widget.usuario.id) {
      _recargarUsuarioActualizado();
      _cargarPublicaciones();
    }
  }

  Future<void> _recargarUsuarioActualizado() async {
    final res = await ServicioUsuarios().obtenerDatosUsuario(widget.usuario.id);
    if (mounted && res.exito && res.datos != null) {
      final u = res.datos!;
      setState(() {
        _biografiaLocal = u.biografia;
        _avatarLocal = u.urlAvatar;
        _fondoLocal = u.fondo;
        _marcoLocal = u.marco;
        _ratingLocal = u.ratingActual;
      });
      widget.onPerfilActualizado?.call();
    }
  }

  Future<void> _cargarRolContextual() async {
    if (widget.comunidadIdContexto != null) {
      final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(
          widget.comunidadIdContexto!, widget.usuario.id);
      if (res.exito && mounted) setState(() => _rolEnComunidad = res.datos);
    }
  }

  Future<void> _cargarPublicaciones() async {
    setState(() => _cargandoPublicaciones = true);
    final res = await ServicioPerfiles()
        .obtenerPublicacionesPerfil(widget.usuario.perfilId);
    if (mounted) {
      setState(() {
        _publicaciones = res.exito ? res.datos : [];
        _cargandoPublicaciones = false;
      });
    }
  }

  Future<void> _cargarGuardados({int? comunidadId, bool force = false}) async {
    if (!force && _publicacionesGuardadas != null && comunidadId == _filtroComunidadId) return;
    setState(() => _cargandoGuardados = true);
    final res = await ServicioPerfiles()
        .obtenerPublicacionesGuardadas(comunidadId: comunidadId);
    if (mounted) {
      setState(() {
        _publicacionesGuardadas = res.exito ? res.datos : [];
        if (comunidadId == null && _filtroComunidadId == null) {
          _extraerComunidadesFiltro(_publicacionesGuardadas!);
        }
        _cargandoGuardados = false;
      });
    }
  }

  Future<void> _cargarColecciones({bool force = false}) async {
    if (!force && _misColecciones != null) return;
    setState(() => _cargandoColecciones = true);
    final res = await ServicioGaleria().obtenerColecciones(idUsuario: widget.usuario.id);
    if (mounted) {
      setState(() {
        _misColecciones = res.exito ? res.datos : [];
        _cargandoColecciones = false;
      });
    }
  }

  void _extraerComunidadesFiltro(List<Publicacion> posts) {
    final Map<int, String> uniqueComs = {};
    for (var p in posts) {
      if (p.comunidadId != 0) uniqueComs[p.comunidadId] = p.comunidadNombre;
    }
    _comunidadesFiltro = uniqueComs.entries
        .map((e) => {'id': e.key, 'nombre': e.value})
        .toList();
  }

  Future<void> _cargarEstadoVoto() async {
    if (_currentUserId == null) return;
    final res = await ServicioMejoras()
        .obtenerEstadoVoto(idReceptorUsuario: widget.usuario.id);
    if (mounted && res.exito) {
      final d = res.datos!;
      setState(() {
        _haVotadoHoy = d['ha_votado_hoy'];
        _totalVotosRecibidos = d['total_votos'];
        _segundosParaReinicio = d['segundos_hasta_medianoche'];
      });
      _iniciarContador();
    }
  }

  void _iniciarContador() {
    _timerReinicio?.cancel();
    _timerReinicio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _segundosParaReinicio > 0) {
        setState(() => _segundosParaReinicio--);
      } else {
        setState(() => _haVotadoHoy = false);
        timer.cancel();
      }
    });
  }

  String _formatearTiempo(int segundos) {
    int h = segundos ~/ 3600;
    int m = (segundos % 3600) ~/ 60;
    int s = segundos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _manejarSeguimiento() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);
    final res = await ServicioPerfiles()
        .enviarSolicitudSeguimiento(widget.usuario.nombreUsuario);
    if (mounted) {
      if (res.exito) setState(() => _estadoSeguimiento = res.datos);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _currentUserId == widget.usuario.id
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearPost,
              backgroundColor: const Color(0xFFF28B50),
              icon: const Icon(Icons.add_box_rounded, color: Colors.white),
              label: Text('Subir Post',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            HeaderDetallePerfil(
              usuario: widget.usuario,
              avatarLocal: _avatarLocal,
              fondoLocal: _fondoLocal,
              marcoLocal: _marcoLocal,
              currentUserId: _currentUserId,
              onEditarAvatar: _editarAvatar,
              onEditarPerfil: _irAInventario,
              onBack: widget.onBack ?? () => Navigator.pop(context),
              esIntegrada: widget.esIntegrada,
            ),
            SliverToBoxAdapter(
              child: InfoPerfil(
                usuario: widget.usuario,
                currentUserId: _currentUserId,
                biografiaLocal: _biografiaLocal,
                estadoSeguimiento: _estadoSeguimiento,
                isLoading: _isLoading,
                rolEnComunidad: _rolEnComunidad,
                ratingLocal: _ratingLocal,
                haVotadoHoy: _haVotadoHoy,
                tiempoParaReinicio: _formatearTiempo(_segundosParaReinicio),
                onManejarSeguimiento: _manejarSeguimiento,
                onMostrarVoto: _mostrarSelectorVoto,
                onEditarBio: _mostrarDialogoEditarBio,
                onChat: _iniciarChat,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabsDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  tabs: [
                    const Tab(text: 'Posts'),
                    Tab(text: _currentUserId == widget.usuario.id ? 'Favoritos' : 'Colecciones'),
                  ],
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  indicatorColor: const Color(0xFFF28B50),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            SeccionPostsPerfil(
              publicaciones: _publicaciones,
              estaCargando: _cargandoPublicaciones,
              onRefresh: _cargarPublicaciones,
            ),
            if (_currentUserId == widget.usuario.id)
              SeccionGuardadosPerfil(
                publicaciones: _publicacionesGuardadas,
                colecciones: _misColecciones,
                estaCargando: _cargandoGuardados,
                estaCargandoColecciones: _cargandoColecciones,
                comunidadesFiltro: _comunidadesFiltro,
                filtroComunidadId: _filtroComunidadId,
                onFiltroChanged: (id) {
                  setState(() => _filtroComunidadId = id);
                  _cargarGuardados(comunidadId: id);
                },
                onRefresh: () => _cargarGuardados(force: true),
                onRefreshColecciones: () => _cargarColecciones(force: true),
              )
            else
              SeccionColeccionesPerfil(
                colecciones: _misColecciones,
                estaCargando: _cargandoColecciones,
                onRefresh: _cargarColecciones,
                esPropietario: false,
              ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE ACCIÓN ---

  void _mostrarSelectorVoto() {
    if (_currentUserId == widget.usuario.id) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              _haVotadoHoy ? '¿Qué quieres hacer con tu voto?' : '¡Vota a este Michi!',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _haVotadoHoy ? 'Puedes cambiar tu puntuación o eliminar el voto.' : 'Dalle amor con tus estrellas 🐾',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SelectorEstrellas(
              onRatingChanged: (puntos) async {
                final res = await ServicioMejoras().votar(
                  idReceptorUsuario: widget.usuario.id,
                  cantidadEstrellas: puntos,
                );
                if (res.exito) {
                  _cargarEstadoVoto();
                  _recargarUsuarioActualizado();
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            if (_haVotadoHoy) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  final res = await ServicioMejoras().eliminarVoto(idReceptorUsuario: widget.usuario.id);
                  if (res.exito) {
                    setState(() {
                      _haVotadoHoy = false;
                    });
                    _cargarEstadoVoto();
                    _recargarUsuarioActualizado();
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                label: Text('Eliminar mi voto', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarBio() {
    final controller = TextEditingController(text: _biografiaLocal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Editar Biografía',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: GoogleFonts.inter(color: Colors.white70),
          decoration: InputDecoration(
            hintText: 'Cuéntanos algo sobre ti...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevaBio = controller.text;
              final res = await ServicioPerfiles().editarBiografia(
                textoBiografia: nuevaBio,
                perfilId: widget.usuario.perfilId,
              );
              if (res.exito) {
                setState(() => _biografiaLocal = nuevaBio);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF248EA6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Guardar',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editarAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final res = await ServicioPerfiles()
        .editarAvatarPerfil(imagen: img, perfilId: widget.usuario.perfilId);
    if (res.exito) _recargarUsuarioActualizado();
  }

  void _iniciarChat() async {
    final sala = await ServicioMensajeria().crearSalaPrivada(widget.usuario.id);
    if (sala != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PantallaChat(
                  salaId: sala['id'], nombreSala: widget.usuario.nombreUsuario, otroUsuarioId: widget.usuario.id)));
    }
  }

  void _mostrarDialogoCrearPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearPost(
        titulo: 'Nuevo Miau-Post',
        onPublicar: (txt, imgs, tags) async {
          final ok = await Provider.of<PostProvider>(context, listen: false)
              .crearPost(comunidadId: widget.comunidadIdContexto, texto: txt, imagenes: imgs, etiquetas: tags);
          if (ok) _cargarPublicaciones();
          return ok;
        },
      ),
    );
  }

  void _irAInventario() {
    context.push('/inventario');
  }
}

class _SliverTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabsDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabsDelegate oldDelegate) => false;
}
