import 'dart:async';
import 'package:flutter/material.dart' hide Scaffold;
import 'package:flutter/material.dart' as material show Scaffold;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../models/usuario.dart';
import '../../models/publicacion.dart';
import '../../utils/estilo_post_helper.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_mensajeria.dart';
import '../../utils/mejoras_notifier.dart';
import '../../providers/post_provider.dart';
import '../../providers/chat_provider.dart';

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
import 'package:tolgee/tolgee.dart';

/// Pantalla que muestra los detalles del perfil de un usuario.
class PantallaDetallePerfil extends StatefulWidget {
  final dynamic idOrUsername;
  final Usuario? usuario;
  final int? comunidadIdContexto;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onPerfilActualizado;

  const PantallaDetallePerfil({
    super.key,
    this.idOrUsername,
    this.usuario,
    this.comunidadIdContexto,
    this.esIntegrada = false,
    this.onBack,
    this.onPerfilActualizado,
  }) : assert(idOrUsername != null || usuario != null, 'Debe proporcionarse id o usuario');

  @override
  State<PantallaDetallePerfil> createState() => _PantallaDetallePerfilState();
}

class _PantallaDetallePerfilState extends State<PantallaDetallePerfil>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Usuario? _usuario;
  int? _currentUserId;
  bool _isLoading = false;
  bool _cargandoPerfil = false;
  String? _estadoSeguimiento;
  List<Publicacion>? _publicaciones;
  bool _cargandoPublicaciones = true;
  final ScrollController _scrollController = ScrollController();

  List<Publicacion>? _publicacionesGuardadas;
  bool _cargandoGuardados = false;
  int? _filtroComunidadId;
  List<Map<String, dynamic>> _comunidadesFiltro = [];

  List<Coleccion>? _misColecciones;
  bool _cargandoColecciones = false;

  String? _biografiaLocal;
  String? _avatarLocal;
  String? _fondoLocal;
  String? _fondoPerfilLocal;
  String? _marcoLocal;
  double _ratingLocal = 0.0;

  bool _haVotadoHoy = false;
  int _miVotoHoy = 0;
  int _totalVotosRecibidos = 0;
  int _segundosParaReinicio = 0;
  Timer? _timerReinicio;
  String? _rolEnComunidad;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    if (_usuario == null && widget.idOrUsername != null) {
      _cargarPerfilInicial();
    } else if (_usuario != null) {
      _sincronizarEstadoLocal();
      _inicializarDatos();
    }

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
    
    mejoraEquipadaNotifier.addListener(_onMejoraEquipada);
  }

  void _sincronizarEstadoLocal() {
    if (_usuario == null) return;
    _biografiaLocal = _usuario!.biografia;
    _avatarLocal = _usuario!.urlAvatar;
    _fondoLocal = _usuario!.fondo;
    _fondoPerfilLocal = _usuario!.fondoPerfil;
    _marcoLocal = _usuario!.marco;
    _ratingLocal = _usuario!.ratingActual;
    _estadoSeguimiento = _usuario!.estadoSeguimiento;
  }

  Future<void> _cargarPerfilInicial() async {
    if (!mounted) return;
    setState(() => _cargandoPerfil = true);
    final res = await ServicioUsuarios().obtenerDatosUsuario(widget.idOrUsername!);
    if (mounted) {
      setState(() {
        _usuario = res.datos;
        _cargandoPerfil = false;
      });
      if (_usuario != null) {
        _sincronizarEstadoLocal();
        _inicializarDatos();
      }
    }
  }

  @override
  void didUpdateWidget(PantallaDetallePerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.idOrUsername ?? oldWidget.usuario?.id;
    final newId = widget.idOrUsername ?? widget.usuario?.id;
    if (oldId != newId) {
      _usuario = widget.usuario;
      if (_usuario == null && widget.idOrUsername != null) {
        _cargarPerfilInicial();
      } else if (_usuario != null) {
        _sincronizarEstadoLocal();
        _inicializarDatos();
      }
      _biografiaLocal = widget.usuario?.biografia;
      _avatarLocal = widget.usuario?.urlAvatar;
      _fondoLocal = widget.usuario?.fondo;
      _fondoPerfilLocal = widget.usuario?.fondoPerfil;
      _marcoLocal = widget.usuario?.marco;
      _ratingLocal = widget.usuario?.ratingActual ?? 0.0;
      _estadoSeguimiento = widget.usuario?.estadoSeguimiento;
      _publicaciones = null;
      _publicacionesGuardadas = null;
      _misColecciones = null;
      _cargandoPublicaciones = true;
      _rolEnComunidad = null;
      _haVotadoHoy = false;
      _miVotoHoy = 0;
      _timerReinicio?.cancel();
      _inicializarDatos();
    }
  }

  @override
  void dispose() {
    mejoraEquipadaNotifier.removeListener(_onMejoraEquipada);
    _timerReinicio?.cancel();
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) setState(() => _currentUserId = id);

    bool incompleto = _usuario != null && (_usuario!.biografia?.isEmpty ?? true) && _usuario!.ratingActual == 0.0;
    
    if (incompleto) {
      await _cargarPerfilInicial();
    }

    await Future.wait([
      _cargarEstadoVoto(),
      _cargarPublicaciones(),
      _cargarRolContextual(),
    ]);
  }

  void _onMejoraEquipada() {
    if (_usuario != null && _currentUserId == _usuario!.id) {
      _recargarUsuarioActualizado();
      _cargarPublicaciones();
    }
  }

  Future<void> _recargarUsuarioActualizado() async {
    if (_usuario == null) return;
    final res = await ServicioUsuarios().obtenerDatosUsuario(_usuario!.id);
    if (mounted && res.exito && res.datos != null) {
      final u = res.datos!;
      setState(() {
        _biografiaLocal = u.biografia;
        _avatarLocal = u.urlAvatar;
        _fondoLocal = u.fondo;
        _fondoPerfilLocal = u.fondoPerfil;
        _marcoLocal = u.marco;
        _ratingLocal = u.ratingActual;
      });
      widget.onPerfilActualizado?.call();
    }
  }

  Future<void> _cargarRolContextual() async {
    if (_usuario == null) return;
    if (widget.comunidadIdContexto != null) {
      final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(
          widget.comunidadIdContexto!, _usuario!.id);
      if (res.exito && mounted) setState(() => _rolEnComunidad = res.datos);
    }
  }

  Future<void> _cargarPublicaciones() async {
    if (_usuario == null) return;
    setState(() => _cargandoPublicaciones = true);
    final res = await ServicioPerfiles()
        .obtenerPublicacionesPerfil(_usuario!.perfilId);
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
    if (_usuario == null) return;
    setState(() => _cargandoColecciones = true);
    final res = await ServicioGaleria().obtenerColecciones(idUsuario: _usuario!.id);
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
    if (_currentUserId == null || _usuario == null) return;
    final res = await ServicioMejoras()
        .obtenerEstadoVoto(idReceptorUsuario: _usuario!.id);
    if (mounted && res.exito) {
      final d = res.datos!;
      setState(() {
        _haVotadoHoy = d['ha_votado_hoy'] ?? false;
        _miVotoHoy = d['estrellas'] ?? 0;
        _totalVotosRecibidos = d['total_votos'] ?? 0;
        _segundosParaReinicio = d['segundos_hasta_medianoche'] ?? 0;
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
    if (_currentUserId == null || _usuario == null) return;
    setState(() => _isLoading = true);
    final res = await ServicioPerfiles()
        .enviarSolicitudSeguimiento(_usuario!.nombreUsuario);
    if (mounted) {
      if (res.exito) setState(() => _estadoSeguimiento = res.datos);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TranslationWidget(
      builder: (context, tr) {
        if (_cargandoPerfil || _usuario == null) {
          final loading = material.Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFF28B50)),
                  if (_cargandoPerfil) ...[
                    const SizedBox(height: 16),
                    Text(tr('profileLoadingSubtitle'), style: GoogleFonts.inter(color: Colors.grey)),
                  ] else if (_usuario == null && !_cargandoPerfil) ...[
                    const SizedBox(height: 16),
                    Text('${tr('profileNotFoundTitle')} ${tr('profileNotFoundEmoji')}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: widget.onBack ?? () => Navigator.pop(context), child: Text(tr('commonBack')))
                  ]
                ],
              ),
            ),
          );
          return loading;
        }

        return material.Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _currentUserId == _usuario!.id
              ? FloatingActionButton.extended(
                  onPressed: _mostrarDialogoCrearPost,
                  backgroundColor: EstiloPostHelper.parseHex(_usuario?.colorTema) ?? const Color(0xFFF28B50),
                  icon: const Icon(Icons.add_box_rounded, color: Colors.white),
                  label: Text(tr('profileUploadPost'),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                )
              : null,
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: NestedScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    HeaderDetallePerfil(
                      usuario: _usuario!,
                      avatarLocal: _avatarLocal,
                      fondoLocal: _fondoPerfilLocal,
                      fondoPerfilLocal: _fondoLocal,
                      marcoLocal: _marcoLocal,
                      currentUserId: _currentUserId,
                      onEditarAvatar: _editarAvatar,
                      onEditarPerfil: _irAInventario,
                      onBack: widget.onBack ?? () => Navigator.pop(context),
                      esIntegrada: widget.esIntegrada,
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Theme.of(context).cardColor,
                        child: InfoPerfil(
                          usuario: _usuario!,
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
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabsDelegate(
                        tabBar: TabBar(
                          controller: _tabController,
                          tabs: [
                            const Tab(text: 'Posts'),
                            Tab(text: _currentUserId == _usuario!.id ? tr('profileTabsFavorites') : tr('profileTabsCollections')),
                          ],
                          labelStyle: GoogleFonts.getFont(_usuario!.fuentePerfil,
                              fontWeight: FontWeight.bold, fontSize: 16),
                          indicatorColor: EstiloPostHelper.parseHex(_usuario?.colorTema) ?? const Color(0xFFF28B50),
                        ),
                      ),
                    ),
                  ];
                },
                body: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    image: (_fondoPerfilLocal != null && _fondoPerfilLocal!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_fondoPerfilLocal!),
                            fit: BoxFit.cover,
                            opacity: 0.6,
                          )
                        : null,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SeccionPostsPerfil(
                        publicaciones: _publicaciones,
                        estaCargando: _cargandoPublicaciones,
                        fuentePerfil: _usuario?.fuentePerfil,
                        colorTema: _usuario?.colorTema,
                        onRefresh: _cargarPublicaciones,
                        onLoadMore: (pagina) async {
                          final res = await ServicioPerfiles().obtenerPublicacionesPerfil(_usuario!.perfilId, pagina: pagina);
                          return res.datos ?? [];
                        },
                      ),
                      if (_currentUserId == _usuario!.id)
                        SeccionGuardadosPerfil(
                          publicaciones: _publicacionesGuardadas,
                          colecciones: _misColecciones,
                          estaCargando: _cargandoGuardados,
                          estaCargandoColecciones: _cargandoColecciones,
                          comunidadesFiltro: _comunidadesFiltro,
                          filtroComunidadId: _filtroComunidadId,
                          fuentePerfil: _usuario?.fuentePerfil,
                          colorTema: _usuario?.colorTema,
                          onFiltroChanged: (id) {
                            setState(() => _filtroComunidadId = id);
                            _cargarGuardados(comunidadId: id);
                          },
                          onRefresh: () => _cargarGuardados(force: true),
                          onRefreshColecciones: () => _cargarColecciones(force: true),
                          onLoadMore: (pagina) async {
                            final res = await ServicioPerfiles().obtenerPublicacionesGuardadas(
                              comunidadId: _filtroComunidadId,
                              pagina: pagina,
                            );
                            return res.datos ?? [];
                          },
                        )
                      else
                        SeccionColeccionesPerfil(
                          colecciones: _misColecciones,
                          estaCargando: _cargandoColecciones,
                          onRefresh: () => _cargarColecciones(force: true),
                          esPropietario: false,
                          fuentePerfil: _usuario?.fuentePerfil,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarSelectorVoto() {
    if (_usuario == null || _currentUserId == _usuario!.id) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationWidget(
        builder: (context, tr) => Container(
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
                _haVotadoHoy ? tr('profileVoteTitleChange') : tr('profileVoteTitleNew'),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _haVotadoHoy ? tr('profileVoteDescChange') : tr('profileVoteDescNew'),
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SelectorEstrellas(
                initialRating: _miVotoHoy,
                onRatingChanged: (puntos) async {
                  final res = await ServicioMejoras().votar(
                    idReceptorUsuario: _usuario!.id,
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
                    final res = await ServicioMejoras().eliminarVoto(idReceptorUsuario: _usuario!.id);
                    if (res.exito) {
                      setState(() {
                        _haVotadoHoy = false;
                        _miVotoHoy = 0;
                      });
                      _cargarEstadoVoto();
                      _recargarUsuarioActualizado();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  label: Text(tr('profileVoteDelete'), style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEditarBio() {
    final controller = TextEditingController(text: _biografiaLocal);
    showDialog(
      context: context,
      builder: (ctx) => TranslationWidget(
        builder: (ctx, tr) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('profileEditBioTitle'),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: GoogleFonts.inter(color: Colors.white70),
            decoration: InputDecoration(
              hintText: tr('profileEditBioHint'),
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
              child: Text(tr('commonCancel'), style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevaBio = controller.text;
                final res = await ServicioPerfiles().editarBiografia(
                  textoBiografia: nuevaBio,
                  perfilId: _usuario!.perfilId,
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
              child: Text(tr('commonSave'),
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _editarAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    if (_usuario == null) return;
    final res = await ServicioPerfiles()
        .editarAvatarPerfil(imagen: img, perfilId: _usuario!.perfilId);
    if (res.exito) _recargarUsuarioActualizado();
  }

  void _iniciarChat() async {
    if (_usuario == null) return;
    final sala = await ServicioMensajeria().crearSala(idOtroUsuario: _usuario!.id);
    if (sala != null && mounted) {
      context.read<ChatProvider>().notificarNuevaSala();
      
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PantallaChat(
                  salaId: (sala['id'] as num).toInt(), nombreSala: _usuario!.nombreUsuario, otroUsuarioId: _usuario!.id)));
    }
  }

  void _mostrarDialogoCrearPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationWidget(
        builder: (context, translate) => DialogoCrearPost(
          titulo: translate('postNewTitle'),
          onPublicar: (txt, archivos, tags, {void Function(int, int)? alProgresar}) async {
            final ok = await Provider.of<PostProvider>(context, listen: false)
                .crearPost(comunidadId: widget.comunidadIdContexto, texto: txt, imagenes: archivos, etiquetas: tags);
            if (ok) _cargarPublicaciones();
            return ok;
          },
        ),
      ),
    );
  }

  void _irAInventario() {
    context.push('/inicio/inventario');
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
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabsDelegate oldDelegate) => false;
}
