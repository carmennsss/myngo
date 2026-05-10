import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tolgee/tolgee.dart';

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
import '../../services/servicio_mensajeria.dart';
import '../../widgets/mensajeria/dialogo_crear_sala.dart';
import '../../models/usuario.dart';


// Widgets extraídos
import 'widgets_detalle/header_detalle_comunidad.dart';
import 'widgets_detalle/seccion_posts_comunidad.dart';
import 'widgets_detalle/seccion_galeria_comunidad.dart';
import 'widgets_detalle/seccion_chat_comunidad.dart';
import 'widgets_detalle/lista_miembros_comunidad.dart';
import 'widgets_detalle/preview_comunidad.dart';
import 'widgets_detalle/dialogos_comunidad.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Pantalla principal de detalle de una comunidad.
class PantallaDetalleComunidad extends StatefulWidget {
  final dynamic idOrName;
  final Comunidad? comunidad;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onMembershipChanged;
  final int initialIndex;

  const PantallaDetalleComunidad({
    super.key,
    this.idOrName,
    this.comunidad,
    this.esIntegrada = false,
    this.onBack,
    this.onMembershipChanged,
    this.initialIndex = 0,
  }) : assert(idOrName != null || comunidad != null, 'Debe proporcionarse id o comunidad');

  @override
  State<PantallaDetalleComunidad> createState() =>
      _PantallaDetalleComunidadState();
}

class _PantallaDetalleComunidadState extends State<PantallaDetalleComunidad> {
  final _servicio = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  final _servicioGaleria = ServicioGaleria();

  Comunidad? _comunidad;
  bool _estaCargandoPeticion = false;
  bool _estaCargandoDatos = false;
  bool _estaCargandoComunidad = false;
  
  // Paginación
  int _paginaActual = 1;
  bool _hayMasPosts = true;
  bool _cargandoMasPosts = false;
  int? _miId;
  int _indiceSeccion = 0;
  String _miRol = 'Visitor'; // Key for communityVisitor
  String _tipoMejoraSeleccionado = 'Avatar'; // Key for commonAvatar



  List<Publicacion>? _publicaciones;
  List<SalaChat>? _salasChat;
  List<Coleccion>? _colecciones;
  Key _galeriaKey = UniqueKey();
  
  Widget? _cachedBackground;

  @override
  void initState() {
    super.initState();
    _comunidad = widget.comunidad;
    _indiceSeccion = widget.initialIndex;
    
    // Si no hay comunidad, o la que hay parece incompleta (viene de TarjetaPost
    // con solo id y nombre), cargamos los datos completos desde la API
    final comunidadIncompleta = _comunidad != null && 
        (_comunidad!.urlPortada.isEmpty && _comunidad!.creadorNombre == 'Sistema');
    
    if (_comunidad == null && widget.idOrName != null) {
      _cargarComunidadInicial();
    } else if (comunidadIncompleta) {
      _cargarComunidadInicial(idOverride: _comunidad!.id);
    } else {
      _inicializarDatos();
    }
  }

  Future<void> _cargarComunidadInicial({dynamic idOverride}) async {
    if (!mounted) return;
    setState(() => _estaCargandoComunidad = true);
    final idACargar = idOverride ?? widget.idOrName!;
    try {
      final res = await _servicio.obtenerComunidad(idACargar);
      if (mounted) {
        if (res.exito && res.datos != null) {
          setState(() {
            _comunidad = res.datos;
            _estaCargandoComunidad = false;
          });
          await _inicializarDatos();
        } else {
          setState(() {
            if (idOverride == null) _comunidad = null;
            _estaCargandoComunidad = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (idOverride == null) _comunidad = null;
          _estaCargandoComunidad = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(PantallaDetalleComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.idOrName ?? oldWidget.comunidad?.id;
    final newId = widget.idOrName ?? widget.comunidad?.id;
    if (oldId != newId) {
      _indiceSeccion = 0;
      _publicaciones = null;
      _salasChat = null;
      _colecciones = null;
      _cachedBackground = null;
      _inicializarDatos();
    }
  }

  Future<void> _inicializarDatos() async {
    await _obtenerMiId();
    await _cargarDatosSeccion(_indiceSeccion);
    await _cargarColecciones();

    if (_comunidad == null || _miId == null) return;
    
    try {
      final res = await _servicio.obtenerRolUsuarioEnComunidad(
            _comunidad!.id, _miId!);
      if (res.exito && res.datos != null && mounted) {
        setState(() => _miRol = res.datos!);
      }
    } catch (e) {
      debugPrint('[PantallaDetalleComunidad] Error obteniendo rol: $e');
    }
  }

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  Future<void> _cargarMasPosts() async {
    if (_comunidad == null || _cargandoMasPosts || !_hayMasPosts) return;
    
    setState(() => _cargandoMasPosts = true);
    final siguientePagina = _paginaActual + 1;
    
    final res = await _servicio.obtenerPublicacionesComunidad(_comunidad!.id, pagina: siguientePagina);
    
    if (mounted) {
      setState(() {
        if (res.exito && res.datos != null && res.datos!.isNotEmpty) {
          _publicaciones!.addAll(res.datos!);
          _paginaActual = siguientePagina;
          _hayMasPosts = res.datos!.length >= 20;
        } else {
          _hayMasPosts = false;
        }
        _cargandoMasPosts = false;
      });
    }
  }

  Future<void> _cargarColecciones() async {
    if (_comunidad == null) return;
    final res = await _servicioGaleria.obtenerColecciones(
        idComunidad: _comunidad!.id);
    if (mounted) setState(() => _colecciones = res.datos ?? []);
  }

  Future<void> _cargarDatosSeccion(int index) async {
    if (_comunidad == null) return;
    _paginaActual = 1;
    _hayMasPosts = true;
    
    if (index == 0) {
      setState(() => _estaCargandoDatos = true);
      final res = await _servicio.obtenerPublicacionesComunidad(_comunidad!.id, pagina: _paginaActual);
      if (mounted) {
        setState(() {
          _publicaciones = res.datos ?? [];
          _hayMasPosts = (res.datos?.length ?? 0) >= 20;
          _estaCargandoDatos = false;
        });
      }
    } else if (index == 2) {
        setState(() {
          _estaCargandoDatos = true;
          _galeriaKey = UniqueKey();
        });
        await _cargarColecciones();
        if (mounted) setState(() => _estaCargandoDatos = false);
    } else if (index == 3) {
        setState(() => _estaCargandoDatos = true);
        final res = await _servicio.obtenerSalasChat(_comunidad!.id);
        if (mounted) {
          setState(() {
            _salasChat = res.datos ?? [];
            _estaCargandoDatos = false;
          });
        }
    }
  }

  Future<void> _gestionarMembresia() async {
    if (_comunidad == null) return;
    setState(() => _estaCargandoPeticion = true);
    final respuesta = await _servicio.unirseAComunidad(_comunidad!.id);

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
            _comunidad!.esMiembro = true;
          });
          _cargarDatosSeccion(0);
          widget.onMembershipChanged?.call();
        } else if (respuesta.datos?['estado'] == 'SOLICITUD') {
          setState(() {
            _comunidad!.esPendiente = true;
          });
          widget.onMembershipChanged?.call();
        }
      }
    }
  }

  Color _colorPagina(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  bool _esAppClara(BuildContext context) => _colorPagina(context).computeLuminance() > 0.5;
  Color _colorTextoPrincipal(BuildContext context) => _esAppClara(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _colorTextoSecundario(BuildContext context) => _esAppClara(context) ? Colors.grey.shade700 : Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    if (_estaCargandoComunidad || _comunidad == null) {
      return TranslationWidget(
      builder: (context, tr) => Scaffold(
        backgroundColor: _colorPagina(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFC35E34)),
              if (_estaCargandoComunidad) ...[
                const SizedBox(height: 16),
                Text(tr('communityLoading'), style: GoogleFonts.outfit(color: _colorTextoSecundario(context))),
              ] else if (_comunidad == null && !_estaCargandoComunidad) ...[
                const SizedBox(height: 16),
                Text(tr('communityNotFound'), style: GoogleFonts.outfit(color: _colorTextoSecundario(context), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: widget.onBack ?? () => Navigator.pop(context), child: Text(tr('commonBack')))
              ]
            ],
          ),
        ),
      ),
    );
    }

    final esCreador = _miId != null && _miId == _comunidad!.creadorId;
    final esMiembro = _comunidad!.esMiembro || esCreador;
    _cachedBackground ??= _buildGlobalBackground();

    if (!esMiembro) {
      return TranslationWidget(
        builder: (context, tr) => PreviewComunidad(
          comunidad: _comunidad!,
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
          backgroundFeed: _cachedBackground!,
          esAppClara: _esAppClara(context),
          colorTextoPrincipal: _colorTextoPrincipal(context),
          colorTextoSecundario: _colorTextoSecundario(context),
          tr: tr,
        ),
      );
    }

    return TranslationWidget(
      builder: (context, tr) => Scaffold(
        backgroundColor: _colorPagina(context),
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: false,
                    floating: false,
                    snap: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: HeaderDetalleComunidad(
                      comunidad: _comunidad!,
                      miId: _miId,
                      onCerrar: widget.onBack ?? () => Navigator.pop(context),
                      onComunidadActualizada: (c) {
                        setState(() {
                          _comunidad = c;
                          _cachedBackground = null;
                        });
                      },
                      tr: tr,
                    ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      minHeight: 70,
                      maxHeight: 70,
                      child: Material(
                        elevation: 2,
                        color: _colorPagina(context),
                        shadowColor: Colors.black.withOpacity(0.12),
                        child: _buildSubNav(context),
                      ),
                    ),
                  ),
                ];
              },
              body: Stack(
                children: [
                  // El fondo solo se pinta en el área del body, nunca en la cabecera
                  Positioned.fill(child: _buildPersonalizedFeedBackground()),
                  CustomScrollView(
                    slivers: [
                      _buildSliverContent(),
                    ],
                  ),
                ],
              ),
            ),
            _buildFAB(),
          ],
        ),
      ),
    );
  }

  /// Construye el fondo personalizado solo para la parte central del feed
  Widget _buildPersonalizedFeedBackground() {
    // 1. El fondo global (imagen que cubre TODO el viewport)
    final globalBg = _buildGlobalBackground();
    
    // Si no estamos en la sección de posts, mostramos solo el fondo global
    if (_indiceSeccion != 0) return globalBg;
    
    // 2. Para posts, el fondo global + el contenedor central con su propio diseño
    final config = _comunidad?.fondoPostsConfig;
    // Si no hay configuración de fondo para posts, devolvemos el global
    if (config == null) return globalBg;

    return Stack(
      children: [
        globalBg,
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900), // Un poco más ancho para web
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: _buildBackgroundFeed(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverContent() {
    switch (_indiceSeccion) {
      case 0:
        return SeccionPostsComunidad(
          publicaciones: _publicaciones,
          estaCargando: _estaCargandoDatos,
          onRefresh: () => _cargarDatosSeccion(0),
          onLoadMore: _cargarMasPosts,
          hasMore: _hayMasPosts,
          isLoadingMore: _cargandoMasPosts,
          esAppClara: _esAppClara(context),
          fuente: _comunidad?.fuenteComunidad,
          backgroundConfig: _comunidad?.fondoPostsConfig,
          tieneFondoGlobal: _comunidad?.urlFondo != null && _comunidad!.urlFondo!.isNotEmpty,
          comoSliver: true,
          esMiembro: _comunidad!.esMiembro || (_miId != null && _miId == _comunidad!.creadorId),
        );
      case 1:
        return SliverFillRemaining(hasScrollBody: true, child: _buildStore());
      case 2:
        return SeccionGaleriaComunidad(
          comunidad: _comunidad!,
          colecciones: _colecciones,
          estaCargando: _estaCargandoDatos,
          onNuevaColeccion: () => _mostrarDialogoNuevaColeccion(context),
          galeriaKey: _galeriaKey,
          comoSliver: true,
          esMiembro: _comunidad!.esMiembro || (_miId != null && _miId == _comunidad!.creadorId),
        );
      case 3:
        return SeccionChatComunidad(
          comunidad: _comunidad!,
          salasChat: _salasChat,
          estaCargando: _estaCargandoDatos,
          onCrearSala: () => _mostrarDialogoCrearSalaComunidad(context),
          onRefresh: () => _cargarDatosSeccion(3),
          esAppClara: _esAppClara(context),
          colorTextoPrincipal: _colorTextoPrincipal(context),
          colorTextoSecundario: _colorTextoSecundario(context),
          comoSliver: true,
        );
      case 4:
        return ListaMiembrosComunidad(
          comunidad: _comunidad!,
          comoSliver: true,
        );
      default:
        return const SliverToBoxAdapter(child: SizedBox());
    }
  }

  Widget _buildSubNav(BuildContext context) {
    final comunidad = _comunidad!;
    final rawAvatar = comunidad.urlAvatar ?? '';
    final avatarUrl = rawAvatar.isNotEmpty
        ? (rawAvatar.startsWith('http')
            ? rawAvatar
            : '${Configuracion.baseUrl}${rawAvatar.startsWith('/') ? '' : '/'}$rawAvatar')
        : null;

    return Row(
      children: [
        // Tabs — scrollables a la izquierda
        Expanded(
          child: TranslationWidget(
            builder: (context, tr) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(0, tr('communityTabPosts'), Icons.grid_view_rounded),
                _buildNavItem(1, tr('communityTabStore'), Icons.shopping_bag_rounded),
                _buildNavItem(2, tr('communityTabGallery'), Icons.photo_library_rounded),
                _buildNavItem(3, tr('communityTabChats'), Icons.chat_bubble_rounded),
                _buildNavItem(4, tr('communityTabMembers'), Icons.people_alt_rounded),
              ],
            ),
          ),
        ),
        // Identidad de la comunidad — fija a la derecha
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1,
                height: 28,
                color: Colors.grey.withOpacity(0.25),
                margin: const EdgeInsets.only(right: 12),
              ),
              if (avatarUrl != null)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildAvatarFallback(comunidad),
                  ),
                )
              else
                _buildAvatarFallback(comunidad),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  comunidad.nombre,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _colorTextoPrincipal(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(Comunidad comunidad) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: comunidad.colorTema.withOpacity(0.15),
      child: Text(
        comunidad.nombre.isNotEmpty ? comunidad.nombre[0].toUpperCase() : '🐾',
        style: GoogleFonts.outfit(
          color: comunidad.colorTema,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }


  Widget _buildNavItem(int index, String label, IconData icon) {
    if (_comunidad == null) return const SizedBox.shrink();
    
    final activo = _indiceSeccion == index;
    final color = _comunidad?.colorTema ?? const Color(0xFFC35E34);
    
    return InkWell(
      onTap: () {
        if (!mounted) return;
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
      final esCreador = _miId != null && _miId == _comunidad!.creadorId;
      return Positioned(
        bottom: 24,
        right: 24,
        child: TranslationWidget(
          builder: (context, tr) => FloatingActionButton.extended(
            onPressed: () => _mostrarDialogoNuevoPost(context),
            label: Text(
              esCreador ? 'Subir' : 'Sugerir',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
            backgroundColor: _comunidad!.colorTema,
          ),
        ),
      );
    }
    if (_indiceSeccion == 1) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: TranslationWidget(
          builder: (context, tr) => FloatingActionButton.extended(
            onPressed: () => _irAEnviarPropuesta(),
            label: Text(tr('communityFabSuggest', {'type': tr(_tipoMejoraSeleccionado == 'Avatar' ? 'commonAvatar' : (_tipoMejoraSeleccionado == 'Marco' ? 'commonFrame' : 'commonBackground'))}),
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),

            icon: const Icon(Icons.palette_rounded, color: Colors.white),
            backgroundColor: _comunidad!.colorTema,
          ),
        ),
      );
    }
    if (_indiceSeccion == 3) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: TranslationWidget(
          builder: (context, tr) => FloatingActionButton.extended(
            onPressed: () => _mostrarDialogoCrearSalaComunidad(context),
            label: Text(tr('communityFabNewRoom'),
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            backgroundColor: _comunidad!.colorTema,
          ),
        ),
      );
    }
    return const SizedBox();
  }

  void _mostrarDialogoCrearSalaComunidad(BuildContext context) async {
    final res = await _servicio.obtenerMiembrosComunidad(_comunidad!.id);
    if (!res.exito || !mounted) return;
    final potenciales = (res.datos as List)
        .where((m) => m['usuario_id'] != _miId)
        .map((m) => Usuario.fromJson({
          'id': m['usuario_id'],
          'nombre_usuario': m['usuario_nombre'],
          'url_avatar': m['usuario_avatar'],
          'perfil_id': m['perfil_id'],
        }))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearSala(
        titulo: tr('newRoomIn', {'community': _comunidad!.nombre}),

        potencialesParticipantes: potenciales,
        esDeComunidad: true,
        alCrear: (nombre, esPublica, miembrosIds) async {
          final servMensajeria = ServicioMensajeria();
          final nuevaSala = await servMensajeria.crearSala(
            nombre: nombre,
            esGrupal: true,
            esPublica: esPublica,
            miembrosIds: miembrosIds,
            comunidadId: _comunidad!.id,
          );
          if (nuevaSala != null && mounted) {
            _cargarDatosSeccion(3);
            Navigator.pop(context); // Cierre seguro tras éxito
          } else if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo crear la sala 🐾'))
            );
          }
        },
      ),
    );
  }

  void _mostrarDialogoNuevoPost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearPost(
        titulo: tr('postNewPublicationTitle'),

        onPublicar: (texto, imagenes, etiquetas, {void Function(int, int)? alProgresar}) async {
          final provider = Provider.of<PostProvider>(context, listen: false);
          final exito = await provider.crearPost(
            comunidadId: _comunidad!.id,
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
      idComunidad: _comunidad!.id,
      onCreada: _cargarColecciones,
    );
  }

  Widget _buildStore() {
    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
    return PantallaTiendaMejoras(
      esVistaIntegrada: true,
      comunidad: _comunidad,
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
          comunidad: _comunidad!,
          tipoInicial: _tipoMejoraSeleccionado,
        ),
      ),
    );
  }

  Widget _buildGlobalBackground() {
    if (_comunidad == null) return Container();
    final urlFondo = _comunidad!.urlFondo;
    final esClaro = _esAppClara(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _colorPagina(context),
      child: (urlFondo != null && urlFondo.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: urlFondo.startsWith('http') 
                  ? urlFondo 
                  : Uri.encodeFull('${Configuracion.baseUrl}${urlFondo.startsWith('/') ? '' : '/'}$urlFondo'), 
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: Colors.white.withOpacity(esClaro ? 0.7 : 0.4),
              colorBlendMode: BlendMode.modulate,
              errorWidget: (context, url, error) => const SizedBox(),
            )
          : null,
    );
  }

  Widget _buildBackgroundFeed() {
    return _buildPostsBackgroundFromConfig(_comunidad?.fondoPostsConfig, context);
  }

  static Widget _buildPostsBackgroundFromConfig(Map<String, dynamic>? config, BuildContext context) {
    if (config == null) return const SizedBox.shrink();
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final tipo = config['tipo'] ?? 'solido';
    final color1Hex = config['color1']?.toString() ?? (esClaro ? '#FFFFFF' : '#121212');
    final color2Hex = config['color2']?.toString();
    final patron = config['patron']?.toString() ?? 'puntos';
    final color1 = _PantallaDetalleComunidadState._parseHex(color1Hex);
    final color2 = _PantallaDetalleComunidadState._parseHex(color2Hex) ?? color1.withOpacity(0.8);

    if (tipo == 'gradiente') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
    if (tipo == 'patron') {
      return Container(
        color: color1,
        child: CustomPaint(
          painter: _PatronPainter(
            tipo: patron,
            color: (color1.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.12),
          ),
          child: Container(),
        ),
      );
    }
    return Container(color: color1);
  }

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.white;
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }
}

class _PatronPainter extends CustomPainter {
  final String tipo;
  final Color color;

  _PatronPainter({required this.tipo, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    if (tipo == 'puntos') {
      for (double x = 0; x < size.width; x += 25) {
        for (double y = 0; y < size.height; y += 25) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
        }
      }
    } else if (tipo == 'lineas') {
      for (double x = -size.height; x < size.width; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      }
    } else if (tipo == 'diagonal_inversa') {
      for (double x = 0; x < size.width + size.height; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
      }
    } else if (tipo == 'cuadricula') {
      for (double x = 0; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (tipo == 'zigzag') {
      final p = Path();
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double y = 0; y < size.height + step; y += step) {
        p.moveTo(0, y);
        for (double x = 0; x < size.width + step; x += step) {
          p.lineTo(x + step / 2, y + step / 2);
          p.lineTo(x + step, y);
        }
      }
      canvas.drawPath(p, paint);
    } else if (tipo == 'diamantes') {
      const step = 50.0;
      paint.style = PaintingStyle.stroke;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          final p = Path()
            ..moveTo(x, y - step / 2)
            ..lineTo(x + step / 2, y)
            ..lineTo(x, y + step / 2)
            ..lineTo(x - step / 2, y)
            ..close();
          canvas.drawPath(p, paint);
        }
      }
    } else if (tipo == 'olas') {
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double y = 0; y < size.height + step; y += step) {
        final p = Path()..moveTo(0, y);
        for (double x = 0; x < size.width + step; x += step) {
          p.quadraticBezierTo(x + step / 4, y - step / 4, x + step / 2, y);
          p.quadraticBezierTo(x + 3 * step / 4, y + step / 4, x + step, y);
        }
        canvas.drawPath(p, paint);
      }
    } else if (tipo == 'triangulos') {
      const step = 40.0;
      paint.style = PaintingStyle.stroke;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          final p = Path()
            ..moveTo(x, y - 10)
            ..lineTo(x + 10, y + 10)
            ..lineTo(x - 10, y + 10)
            ..close();
          canvas.drawPath(p, paint);
        }
      }
    } else if (tipo == 'puntos_grandes') {
      for (double x = 0; x < size.width; x += 50) {
        for (double y = 0; y < size.height; y += 50) {
          canvas.drawCircle(Offset(x, y), 4.0, paint);
        }
      }
    } else if (tipo == 'estrellas') {
      const step = 60.0;
      paint.style = PaintingStyle.stroke;
      for (double x = 0; x < size.width + step; x += step) {
        for (double y = 0; y < size.height + step; y += step) {
          canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), paint);
          canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
