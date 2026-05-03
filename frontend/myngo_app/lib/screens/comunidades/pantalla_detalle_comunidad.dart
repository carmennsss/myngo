import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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

/// Pantalla principal de detalle de una comunidad.
class PantallaDetalleComunidad extends StatefulWidget {
  final int? id;
  final Comunidad? comunidad;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onMembershipChanged;
  final int initialIndex;

  const PantallaDetalleComunidad({
    super.key,
    this.id,
    this.comunidad,
    this.esIntegrada = false,
    this.onBack,
    this.onMembershipChanged,
    this.initialIndex = 0,
  }) : assert(id != null || comunidad != null, 'Debe proporcionarse id o comunidad');

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
  String _miRol = 'Visitante';
  String _tipoMejoraSeleccionado = 'Avatar';

  List<Publicacion>? _publicaciones;
  List<SalaChat>? _salasChat;
  List<Coleccion>? _colecciones;
  Key _galeriaKey = UniqueKey();
  
  // Cache del fondo para evitar recrearlo y causar parpadeos o lentitud
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
    
    if (_comunidad == null && widget.id != null) {
      _cargarComunidadInicial();
    } else if (comunidadIncompleta) {
      _cargarComunidadInicial(idOverride: _comunidad!.id);
    } else {
      _inicializarDatos();
    }
  }

  Future<void> _cargarComunidadInicial({int? idOverride}) async {
    if (!mounted) return;
    setState(() => _estaCargandoComunidad = true);
    final idACargar = idOverride ?? widget.id!;
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
    if (oldWidget.comunidad?.id != widget.comunidad?.id) {
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
    // Siempre asignamos para no dejar estado null indefinidamente
    if (mounted) setState(() => _colecciones = res.datos ?? []);
  }

  Future<void> _cargarDatosSeccion(int index) async {
    if (_comunidad == null) return;
    
    // Reset pagination when switching sections or refreshing
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
        setState(() => _galeriaKey = UniqueKey());
        await _cargarColecciones();
    } else if (index == 3) {
        final res = await _servicio.obtenerSalasChat(_comunidad!.id);
        if (mounted) setState(() => _salasChat = res.datos ?? []);
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
      final loading = Scaffold(
        backgroundColor: _colorPagina(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFC35E34)),
              if (_estaCargandoComunidad) ...[
                const SizedBox(height: 16),
                Text('Cargando comunidad...', style: GoogleFonts.outfit(color: _colorTextoSecundario(context))),
              ] else if (_comunidad == null && !_estaCargandoComunidad) ...[
                const SizedBox(height: 16),
                Text('Comunidad no encontrada 😿', style: GoogleFonts.outfit(color: _colorTextoSecundario(context), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: widget.onBack ?? () => Navigator.pop(context), child: const Text('Volver'))
              ]
            ],
          ),
        ),
      );
      return widget.esIntegrada ? loading : loading;
    }

    final esCreador = _miId != null && _miId == _comunidad!.creadorId;
    final esMiembro = _comunidad!.esMiembro || esCreador;
    
    _cachedBackground ??= _buildGlobalBackground();

    if (!esMiembro) {
      return PreviewComunidad(
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
      );
    }

    final dashboard = Stack(
      children: [
        Positioned.fill(child: _cachedBackground!),
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                pinned: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
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
          onLoadMore: _cargarMasPosts,
          hasMore: _hayMasPosts,
          isLoadingMore: _cargandoMasPosts,
          esAppClara: _esAppClara(context),
          fuente: _comunidad?.fuenteComunidad,
          backgroundConfig: _comunidad?.fondoPostsConfig,
        );
      case 1:
        return _buildStore();
      case 2:
        return SeccionGaleriaComunidad(
          comunidad: _comunidad!,
          colecciones: _colecciones,
          estaCargando: _estaCargandoDatos,
          onNuevaColeccion: () => _mostrarDialogoNuevaColeccion(context),
          galeriaKey: _galeriaKey,
        );
      case 3:
        return SeccionChatComunidad(
          comunidad: _comunidad!,
          salasChat: _salasChat,
          estaCargando: _estaCargandoDatos,
          onCrearSala: () => _mostrarDialogoCrearSalaComunidad(context),
          esAppClara: _esAppClara(context),
          colorTextoPrincipal: _colorTextoPrincipal(context),
          colorTextoSecundario: _colorTextoSecundario(context),
        );
      case 4:
        return ListaMiembrosComunidad(comunidad: _comunidad!);
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
    final color = _comunidad!.colorTema;
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
          backgroundColor: _comunidad!.colorTema,
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
          backgroundColor: _comunidad!.colorTema,
        ),
      );
    }
    if (_indiceSeccion == 3) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: FloatingActionButton.extended(
          onPressed: () => _mostrarDialogoCrearSalaComunidad(context),
          label: Text('Nueva Sala',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          backgroundColor: _comunidad!.colorTema,
        ),
      );
    }
    return const SizedBox();
  }

  void _mostrarDialogoCrearSalaComunidad(BuildContext context) async {
    // Obtener miembros de la comunidad
    final res = await _servicio.obtenerMiembrosComunidad(_comunidad!.id);
    if (!res.exito || !mounted) return;

    // Convertir datos de miembros a objetos Usuario para el diálogo
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
        titulo: 'Nueva Sala en ${_comunidad!.nombre} 🐾',
        potencialesParticipantes: potenciales,
        alCrear: (nombre, esPublica, miembrosIds) async {
          Navigator.pop(context); // Cerrar diálogo
          
          final servMensajeria = ServicioMensajeria();
          final nuevaSala = await servMensajeria.crearSala(
            nombre: nombre,
            esGrupal: true,
            esPublica: esPublica,
            miembrosIds: miembrosIds,
            comunidadId: _comunidad!.id,
          );

          if (nuevaSala != null && mounted) {
            _cargarDatosSeccion(3); // Recargar salas
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
        titulo: 'Nueva Publicación 🐾',
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
    
    // 1. Si hay una imagen de fondo global, prima
    if (urlFondo != null && urlFondo.isNotEmpty) {
      return Container(
        color: _colorPagina(context),
        child: Opacity(
          opacity: esClaro ? 0.4 : 0.2,
          child: CachedNetworkImage(
            imageUrl: urlFondo.startsWith('http') 
                ? urlFondo 
                : Uri.encodeFull('${Configuracion.baseUrl}${urlFondo.startsWith('/') ? '' : '/'}$urlFondo'), 
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const SizedBox(),
          ),
        ),
      );
    }

    return Container(color: _colorPagina(context));
  }

  Widget _buildBackgroundFeed() {
    // Este método ahora solo se usa si queremos renderizarlo en algún sitio específico
    // Pero lo mantendremos por compatibilidad o lo moveremos a un helper
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
            color: (color1.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.05),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (tipo == 'puntos') {
      for (double x = 0; x < size.width; x += 20) {
        for (double y = 0; y < size.height; y += 20) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    } else if (tipo == 'lineas') {
      for (double x = -size.height; x < size.width; x += 25) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      }
    } else if (tipo == 'cuadricula') {
      for (double x = 0; x < size.width; x += 30) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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
