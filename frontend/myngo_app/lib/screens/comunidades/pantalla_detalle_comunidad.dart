import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../models/sala_chat.dart';
import '../../widgets/inicio/tarjeta_post.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../models/coleccion.dart';
import '../galeria/pantalla_detalle_coleccion.dart';
import 'pantalla_admin_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../perfiles/pantalla_perfiles.dart';
import 'pantalla_enviar_propuesta.dart';
import '../perfiles/pantalla_tienda_mejoras.dart';
import '../inicio/pantalla_inicio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/dialogo_crear_post.dart';
import '../perfiles/pantalla_tienda_mejoras.dart';
import 'widgets_preview/preview_header.dart';
import 'widgets_preview/preview_about_section.dart';
import 'widgets_preview/community_join_button.dart';
import 'pantalla_enviar_propuesta.dart';
import '../../widgets/inicio/tarjeta_post.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';

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
  State<PantallaDetalleComunidad> createState() => _PantallaDetalleComunidadState();
}

class _PantallaDetalleComunidadState extends State<PantallaDetalleComunidad> {
  final _servicio = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  
  bool _estaCargandoPeticion = false;
  int? _miId;
  int _indiceSeccion = 0; 
  String _miRol = 'Miembro';
  String _tipoMejoraSeleccionado = 'Avatar';
  
  Color get _bgColor => widget.comunidad.colorTema;

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  void _cargarDatos() {
    _cargarDatosSeccion(_indiceSeccion);
  }

  Color _colorPagina(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  bool _esAppClara(BuildContext context) => _colorPagina(context).computeLuminance() > 0.5;
  
  Color _colorTextoPrincipal(BuildContext context) => _esAppClara(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _colorTextoSecundario(BuildContext context) => _esAppClara(context) ? Colors.grey.shade700 : Colors.grey.shade400;

  List<Publicacion>? _publicaciones;
  List<SalaChat>? _salasChat;
  bool _estaCargandoDatos = false;
  Key _galeriaKey = UniqueKey(); // Clave para forzar refresco

  @override
  void initState() {
    super.initState();
    _indiceSeccion = widget.initialIndex;
    _inicializarDatos();
    _cargarColecciones();
  }

  @override
  void didUpdateWidget(PantallaDetalleComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _indiceSeccion = 0; // Opcional: resetear al primer tab (Posts)
      _indiceGaleria = 0;
      _publicaciones = null;
      _salasChat = null;
      _colecciones = null;
      _miRol = 'Miembro';
      _inicializarDatos();
      _cargarColecciones();
    }
  }

  Future<void> _inicializarDatos() async {
    await _obtenerMiId();
    if (_miId != null) {
      final res = await _servicio.obtenerRolUsuarioEnComunidad(widget.comunidad.id, _miId!);
      if (res.exito && res.datos != null) {
        setState(() => _miRol = res.datos!);
      }
    }
    _cargarDatosSeccion(_indiceSeccion);
  }

  final _servicioGaleria = ServicioGaleria();
  List<Coleccion>? _colecciones;

  Future<void> _cargarColecciones() async {
    final res = await _servicioGaleria.obtenerColecciones(comunidadId: widget.comunidad.id);
    if (res.exito && res.datos != null) {
      setState(() => _colecciones = res.datos!);
    }
  }

  Future<void> _cargarDatosSeccion(int index) async {
    setState(() { _estaCargandoDatos = true; if (index == 0) _publicaciones = null; if (index == 3) _salasChat = null; });
    try {
      if (index == 0) {
        setState(() { _publicaciones = null; }); // Limpiamos para feedback visual
        final res = await _servicio.obtenerPublicaciones(widget.comunidad.id);
        if (res.exito && mounted) setState(() => _publicaciones = res.datos ?? []);
      } else if (index == 2) {
        setState(() { _galeriaKey = UniqueKey(); }); // Forzamos reconstrucción de la grilla
        await _cargarColecciones();
      } else if (index == 3) {
        final res = await _servicio.obtenerSalasChat(widget.comunidad.id);
        if (res.exito && mounted) {
          setState(() => _salasChat = res.datos ?? []);
        }
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
          content: Text(respuesta.mensaje, style: GoogleFonts.inter()),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
        ),
      );
      if (respuesta.exito) {
        if (respuesta.datos?['estado'] == 'ACEPTADO') {
          setState(() { widget.comunidad.esMiembro = true; });
          _cargarDatosSeccion(0);
          // Notificar que se unió a la comunidad
          widget.onMembershipChanged?.call();
        } else if (respuesta.datos?['estado'] == 'SOLICITUD') {
          setState(() { widget.comunidad.esPendiente = true; });
          // Notificar que envió solicitud
          widget.onMembershipChanged?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;
    final esMiembro = widget.comunidad.esMiembro || esCreador;

    if (!esMiembro) {
      final previewContent = Stack(
        children: [
          Positioned.fill(child: _buildBackgroundFeed()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _buildPreview(context),
            ),
          ),
        ],
      );
      return widget.esIntegrada ? previewContent : Scaffold(backgroundColor: _colorPagina(context), body: previewContent);
    }

    final dashboardContent = Stack(
      children: [
        Positioned.fill(child: _buildBackgroundFeed()),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: _buildDashboard(context),
          ),
        ),
      ],
    );

    if (widget.esIntegrada) {
      return Container(
        color: _colorPagina(context),
        child: dashboardContent,
      );
    }

    return Scaffold(
      backgroundColor: _colorPagina(context),
      body: dashboardContent,
    );
  }

  Widget _buildPreview(BuildContext context) {
    final esPublica = widget.comunidad.esPublica;
    
    if (esPublica) {
      return Stack(
        children: [
          Positioned.fill(child: _buildBackgroundFeed()),
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 500,
                  pinned: false,
                  stretch: true,
                  backgroundColor: _colorPagina(context),
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    background: _BarraContextoComunidad(
                      comunidad: widget.comunidad,
                      miId: _miId,
                      onCerrar: widget.onBack ?? () => Navigator.pop(context),
                      onComunidadActualizada: (c) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 60,
                    maxHeight: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorPagina(context),
                        border: Border(
                          bottom: BorderSide(
                            color: widget.comunidad.colorTema.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildPreviewNavItem(0, 'POSTS', Icons.grid_view_rounded),
                          _buildPreviewNavItem(2, 'GALERÍA', Icons.photo_library_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _indiceSeccion == 0 ? _buildPreviewPostFeed() : _buildPreviewGallery(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: PreviewAboutSection(
                      comunidad: widget.comunidad,
                      esAppClara: _esAppClara(context),
                      colorTextoPrincipal: _colorTextoPrincipal(context),
                      colorTextoSecundario: _colorTextoSecundario(context),
                      bgColor: _bgColor,
                    ),
                  ),
                  CommunityJoinButton(
                    comunidad: widget.comunidad,
                    miId: _miId,
                    estaCargandoPeticion: _estaCargandoPeticion,
                    onLogin: () => Navigator.pushNamed(context, '/login'),
                    onJoin: _gestionarMembresia,
                    isPreview: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Para comunidades privadas, mantener la vista anterior
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(context, isPreview: true),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreviewHeader(
                  comunidad: widget.comunidad,
                  esAppClara: _esAppClara(context),
                  colorTextoPrincipal: _colorTextoPrincipal(context),
                  colorTextoSecundario: _colorTextoSecundario(context),
                ),
                Divider(
                  height: 48,
                  thickness: 1,
                  color: _colorPagina(context).computeLuminance() > 0.5
                      ? Colors.black12
                      : const Color(0xFF2A2A2A),
                ),
                PreviewAboutSection(
                  comunidad: widget.comunidad,
                  esAppClara: _esAppClara(context),
                  colorTextoPrincipal: _colorTextoPrincipal(context),
                  colorTextoSecundario: _colorTextoSecundario(context),
                  bgColor: _bgColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: CommunityJoinButton(
            comunidad: widget.comunidad,
            miId: _miId,
            estaCargandoPeticion: _estaCargandoPeticion,
            onLogin: () => Navigator.pushNamed(context, '/login'),
            onJoin: _gestionarMembresia,
            isPreview: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 500,
                pinned: false,
                stretch: true,
                backgroundColor: _colorPagina(context),
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: _BarraContextoComunidad(
                    comunidad: widget.comunidad,
                    miId: _miId,
                    onCerrar: widget.onBack ?? () => Navigator.pop(context),
                    onComunidadActualizada: (c) {
                      setState(() {}); // Forzar recarga si cambia
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorPagina(context),
                      border: Border(
                        bottom: BorderSide(color: widget.comunidad.colorTema.withOpacity(0.2), width: 2),
                      ),
                    ),
                    child: _buildSubNav(context),
                  ),
                ),
              ),
            ];
          },
          body: _buildBodyContent(),
        ),
        if (_indiceSeccion == 0)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoNuevoPost(context),
              label: Text('Miau Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              backgroundColor: widget.comunidad.colorTema,
            ),
          ),
        if (_indiceSeccion == 1)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () => _irAEnviarPropuesta(),
              label: Text('Sugerir $_tipoMejoraSeleccionado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              icon: const Icon(Icons.palette_rounded, color: Colors.white),
              backgroundColor: widget.comunidad.colorTema,
            ),
          ),
      ],
    );
  }

  Widget _buildBodyContent() {
    if (_indiceSeccion == 0) return _buildPostFeed();
    if (_indiceSeccion == 1) return _buildStore();
    if (_indiceSeccion == 2) return _buildGallery();
    if (_indiceSeccion == 3) return _buildChat();
    if (_indiceSeccion == 4) return _buildMembers();
    return const SizedBox();
  }

  Widget _buildMembers() {
    return const PantallaPerfiles();
  }

  Widget _buildCompactHeader(BuildContext context) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;
    final rolLabel = esCreador ? 'Creador' : _miRol;
    final iconRol = esCreador ? Icons.stars_rounded : (rolLabel == 'Moderador' ? Icons.gavel_rounded : Icons.pets_rounded);
    final colorRol = esCreador ? Colors.amber : (rolLabel == 'Moderador' ? const Color(0xFF248EA6) : const Color(0xFFC35E34));
    final portadaUrl = widget.comunidad.urlPortada?.trim();

    return Container(
      height: 140,
      width: double.infinity,
      child: Stack(
        children: [
          // Fondo con Blur
          if (portadaUrl != null && portadaUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: portadaUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: widget.comunidad.colorTema),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.esIntegrada) ...[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 12),
                      child: IconButton(
                        onPressed: widget.onBack,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
                // Avatar pequeño
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    image: portadaUrl != null && portadaUrl.isNotEmpty
                        ? DecorationImage(image: CachedNetworkImageProvider(portadaUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: portadaUrl == null || portadaUrl.isEmpty ? const Icon(Icons.groups_rounded, color: Colors.white, size: 30) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comunidad.nombre,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [const Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorRol.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorRol.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconRol, color: colorRol, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              rolLabel.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón Opciones
                IconButton(
                  onPressed: () => _mostrarMenuOpciones(context),
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubNav(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildNavItem(0, 'POSTS', Icons.grid_view_rounded),
        _buildNavItem(1, 'TIENDA', Icons.shopping_bag_rounded),
        _buildNavItem(2, 'GALERÍA', Icons.photo_library_rounded),
        _buildNavItem(3, 'CHATS', Icons.chat_bubble_rounded),
        _buildNavItem(4, 'MIEMBROS', Icons.people_alt_rounded),
      ],
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
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(top: 24, bottom: 48, left: 16, right: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF28B50).withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFF28B50)),
              ),
              title: Text('Subir Imagen Cruda', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Directo a la galería de la comunidad', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Subiendo...', style: GoogleFonts.outfit())));
                  final res = await _servicioGaleria.subirImagenGaleria(pickedFile, comunidadId: widget.comunidad.id);
                  if (res.exito && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('¡Imagen subida! ✨'), backgroundColor: Colors.green));
                    // Forzamos el refresco de la sección de galería
                    setState(() {
                      _indiceGaleria = 0; // Aseguramos que estamos en la pestaña correcta
                    });
                    _cargarDatosSeccion(2);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF248EA6).withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF248EA6)),
              ),
              title: Text('Nueva Colección', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Clasifica de forma pública o privada tus capturas', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoNuevaColeccion(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevaColeccion(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool esPrivada = false;
    bool cargando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Crear Colección', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: nombreCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nombre de la colección',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Descripción (opcional)',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(esPrivada ? 'Privada' : 'Pública', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(esPrivada ? 'Solo tú podrás ver esta colección' : 'Cualquiera podrá ver esta colección', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                value: esPrivada,
                activeColor: const Color(0xFF248EA6),
                onChanged: (val) => setModalState(() => esPrivada = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cargando ? null : () async {
                    if (nombreCtrl.text.isEmpty) return;
                    setModalState(() => cargando = true);
                    final res = await _servicioGaleria.crearColeccion(
                      nombre: nombreCtrl.text,
                      descripcion: descCtrl.text,
                      esPrivada: esPrivada,
                      comunidadId: widget.comunidad.id,
                    );
                    
                    if (mounted) {
                      setModalState(() => cargando = false);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.mensaje), backgroundColor: res.exito ? Colors.green : Colors.red),
                      );
                      if (res.exito) {
                        _cargarColecciones(); // Recargamos para que aparezca
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF248EA6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: cargando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Crear Colección', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        onPublicar: (texto, imagenes, etiquetas) async {
          final provider = Provider.of<PostProvider>(context, listen: false);
          final exito = await provider.crearPost(
            comunidadId: widget.comunidad.id,
            texto: texto,
            imagenes: imagenes,
            etiquetas: etiquetas,
          );
          
          if (!mounted) return false;

          if (exito) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Publicación creada exitosamente! 🐾'), backgroundColor: Color(0xFF248EA6)),
            );
            _cargarDatosSeccion(0);
            return true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage.isNotEmpty ? provider.errorMessage : 'Error al subir la publicación'), backgroundColor: const Color(0xFFD95F43)),
            );
            return false;
          }
        },
      ),
    );
  }

  void _mostrarAjustesComunidad(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajustes de Comunidad', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFFF29C50)),
              title: Text('Editar Información', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: Badge(
                label: (widget.comunidad.conteoPendienteAdmin) > 0 ? Text(widget.comunidad.conteoPendienteAdmin.toString()) : null,
                isLabelVisible: (widget.comunidad.conteoPendienteAdmin) > 0,
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.security_rounded, color: Color(0xFFF29C50)),
              ),
              title: Text('Panel de Administración', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('Gestiona solicitudes y reportes', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              onTap: () async { 
                Navigator.pop(context);
                final resultado = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => PantallaAdminComunidad(comunidad: widget.comunidad))
                );
                if (resultado != null && resultado is Comunidad && mounted) {
                  setState(() {
                    // Actualizamos los campos necesarios de la instancia local
                    // En Dart los objetos se pasan por referencia, pero si el resultado es una nueva instancia
                    // (como suele ser tras el fromJson del servicio), actualizamos para disparar el re-build
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, {bool isDashboard = false, bool isPreview = false}) {
    final esAdministrador = widget.comunidad.miRol == 'Administrador';
    final esModerador = widget.comunidad.miRol == 'Moderador';
    final puedeAdministrar = esAdministrador || esModerador;

    return SliverAppBar(
      expandedHeight: isDashboard ? 260 : 280,
      pinned: !isPreview, // No fijar en modo preview para evitar duplicación
      stretch: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: _colorTextoPrincipal(context)),
      leading: (widget.esIntegrada && !isPreview) ? IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
        onPressed: widget.onBack,
        tooltip: 'Cerrar comunidad',
      ) : null,
      actions: [
        if (isDashboard && puedeAdministrar)
          IconButton(
            icon: Badge(
              label: (widget.comunidad.conteoPendienteAdmin) > 0 
                ? Text(widget.comunidad.conteoPendienteAdmin.toString()) 
                : null,
              isLabelVisible: (widget.comunidad.conteoPendienteAdmin) > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () => _mostrarAjustesComunidad(context),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: isDashboard ? Text(widget.comunidad.nombre, 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: _colorTextoPrincipal(context))) : null,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.comunidad.urlPortada.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_bgColor, _bgColor.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
              : Image.network(
                  widget.comunidad.urlPortada.startsWith('http') ? widget.comunidad.urlPortada : 'http://127.0.0.1:8000${widget.comunidad.urlPortada}',
                  fit: BoxFit.cover,
                  headers: const {'Access-Control-Allow-Origin': '*'},
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_bgColor, Colors.black87],
                      ),
                    ),
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                  ),
                ),
            // Gradiente suave para que los botones superiores sean legibles si es necesario, 
            // pero muy sutil para no ensuciar la imagen
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBarDecorativa({required bool izquierda}) {
    final colorPrimario = widget.comunidad.colorTema;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _esAppClara(context) ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: GridView.builder(
                itemCount: 40,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 30,
                  crossAxisSpacing: 30,
                ),
                itemBuilder: (context, index) => Transform.rotate(
                  angle: index % 2 == 0 ? 0.3 : -0.2,
                  child: const Icon(Icons.pets, size: 24),
                ),
              ),
            ),
          ),
          Positioned(
            top: izquierda ? 100 : -150,
            left: izquierda ? -150 : null,
            right: !izquierda ? -150 : null,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrimario.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(color: colorPrimario.withOpacity(0.08), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          Center(
            child: RotatedBox(
              quarterTurns: izquierda ? 3 : 1,
              child: Text(
                widget.comunidad.nombre.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: colorPrimario.withOpacity(0.03),
                  letterSpacing: 20,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundFeed() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) return const SizedBox.shrink();
        
        final colorBorde = _esAppClara(context) ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.06);
        final colorFeed = _esAppClara(context) ? Colors.white : const Color(0xFF141414);
        
        return Row(
          children: [
            Expanded(child: _buildSideBarDecorativa(izquierda: true)),
            Container(
              width: 728,
              decoration: BoxDecoration(
                color: colorFeed,
                border: Border(
                  left: BorderSide(color: colorBorde, width: 1.5),
                  right: BorderSide(color: colorBorde, width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, spreadRadius: 5)
                ]
              ),
            ),
            Expanded(child: _buildSideBarDecorativa(izquierda: false)),
          ],
        );
      },
    );
  }

  int _indiceGaleria = 0; 

  Widget _buildPostFeed() {
    if (_estaCargandoDatos || _publicaciones == null) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    
    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: _esAppClara(context) ? Colors.white : const Color(0xFF1E1E1E),
      onRefresh: () => _cargarDatosSeccion(0),
      child: _publicaciones!.isEmpty 
        ? _buildEmptyState(Icons.feed_outlined, 'Aún no hay publicaciones')
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: _publicaciones!.length,
            itemBuilder: (context, index) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TarjetaPost(
                    post: _publicaciones![index],
                    onJoin: () {}, // Ya está en la comunidad
                    onEliminado: () => _cargarDatosSeccion(0),
                    estaEnComunidad: true,
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildGallery() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Row(
            children: [
              _buildMiniChip('Miau Galería 🐾', _indiceGaleria == 0, () => setState(() => _indiceGaleria = 0)),
              const SizedBox(width: 12),
              _buildMiniChip('Colecciones', _indiceGaleria == 1, () => setState(() => _indiceGaleria = 1)),
              const Spacer(),
              if (_indiceGaleria == 1)
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFF28B50)),
                  onPressed: () => _mostrarDialogoNuevaColeccion(context),
                ),
            ],
          ),
        ),
        Expanded(
          child: _indiceGaleria == 0 
            ? MasonryGridGaleria(key: _galeriaKey, comunidadId: widget.comunidad.id) 
            : _buildGalleryCollections(),
        ),
      ],
    );
  }



  Widget _buildGalleryCollections() {
    if (_estaCargandoDatos || _colecciones == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }
    if (_colecciones == null || _colecciones!.isEmpty) {
      return _buildEmptyState(Icons.folder_open_rounded, 'No hay carpetas creadas');
    }

    final random = math.Random(1337);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _colecciones!.length,
      itemBuilder: (context, index) {
        final col = _colecciones![index];
        final rotacion = (random.nextDouble() - 0.5) * 0.1;
        final coloresHex = [0xFF248EA6, 0xFFF28B50, 0xFFD95F43, 0xFF8338EC];
        final color = Color(coloresHex[index % coloresHex.length]);

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleColeccion(
              coleccion: col,
              puedeEditarComunidad: widget.comunidad.miRol == 'Administrador' || widget.comunidad.miRol == 'Moderador',
            )));
          },
          child: Transform.rotate(
            angle: rotacion,
            child: Container(
              decoration: BoxDecoration(
                color: _esAppClara(context) ? Colors.white : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(2, 2)),
                ],
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Container(
                        color: color.withValues(alpha: 0.1),
                        child: (col.previsualizaciones is List && col.previsualizaciones.isNotEmpty)
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: col.previsualizaciones.length > 4 ? 4 : col.previsualizaciones.length,
                                itemBuilder: (context, i) {
                                  final String? url = col.previsualizaciones[i]?.toString();
                                  if (url == null || url.isEmpty) return Container(color: Colors.white10);
                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white10),
                                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 10),
                                  );
                                },
                              )
                            : Center(child: Icon(col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_open_rounded, color: color, size: 24)),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      col.nombreColeccion.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewPostFeed() {
    if (_estaCargandoDatos || _publicaciones == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF28B50)),
      );
    }
    
    if (_publicaciones!.isEmpty) {
      return SizedBox(height: 300, child: _buildEmptyState(Icons.feed_outlined, 'Aún no hay publicaciones'));
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: _publicaciones!.length,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Inicia sesión para ver los detalles 👉', style: GoogleFonts.inter()),
                  backgroundColor: const Color(0xFF248EA6),
                  duration: const Duration(seconds: 3),
                ),
              ),
              child: Opacity(
                opacity: 0.7,
                child: TarjetaPost(
                  post: _publicaciones![index],
                  onJoin: () {}, // Ya está en la comunidad
                ),
              ),
            ),
          ),
        ), // ConstrainedBox
      ), // Center
    ); // ListView.builder
  }
  Widget _buildPreviewGallery() {
    if (_estaCargandoDatos || _colecciones == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF28B50)),
      );
    }
    
    if (_colecciones == null || _colecciones!.isEmpty) {
      return _buildEmptyState(Icons.photo_library_rounded, 'Aún no hay contenido en la galería');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _colecciones!.length,
      itemBuilder: (context, index) {
        final col = _colecciones![index];
        final color = widget.comunidad.colorTema;
        return InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inicia sesión para acceder a la galería 🔐', style: GoogleFonts.inter()),
              backgroundColor: const Color(0xFF248EA6),
              duration: const Duration(seconds: 3),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    color: color.withValues(alpha: 0.1),
                    child: (col.previsualizaciones is List && col.previsualizaciones.isNotEmpty)
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: col.previsualizaciones.length > 4 ? 4 : col.previsualizaciones.length,
                            itemBuilder: (context, i) {
                              final String? url = col.previsualizaciones[i]?.toString();
                              if (url == null || url.isEmpty) return Container(color: Colors.white10);
                              return CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => const Icon(Icons.error, size: 10),
                              );
                            },
                          )
                        : Center(child: Icon(col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_open_rounded, color: color, size: 24)),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  col.nombreColeccion.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewNavItem(int index, String label, IconData icon) {
    final activo = _indiceSeccion == index;
    final color = widget.comunidad.colorTema;
    return InkWell(
      onTap: () => setState(() => _indiceSeccion = index),
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
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF28B50) : (_esAppClara(context) ? Colors.black.withValues(alpha: 0.05) : const Color(0xFF1E1E1E)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFFF28B50) : (_esAppClara(context) ? Colors.black12 : const Color(0xFF2A2A2A))),
        ),
        child: Text(label, style: GoogleFonts.inter(color: active ? Colors.white : _colorTextoSecundario(context), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return EstadoVacioCargando(icon: icon, message: message);
  }

  Widget _buildStore() {
    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
    return PantallaTiendaMejoras(
      esVistaIntegrada: true, 
      comunidad: widget.comunidad,
      onCategoryChanged: (tipo) {
        setState(() => _tipoMejoraSeleccionado = tipo);
      },
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

  Widget _buildChat() {
    if (_estaCargandoDatos || _salasChat == null) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: (_salasChat?.length ?? 0) + 2, 
      itemBuilder: (context, index) {
        if (index == 0) return _buildChatHeader();
        if (index == 1) return _buildGeneralChatTile();
        final sala = _salasChat![index - 2];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _esAppClara(context) ? Colors.black.withValues(alpha: 0.05) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tag, color: Colors.grey),
          ),
          title: Text(sala.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _colorTextoPrincipal(context))),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildGeneralChatTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _esAppClara(context) ? Colors.black.withValues(alpha: 0.02) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(backgroundColor: Color(0xFFF28B50), child: Icon(Icons.forum_rounded, color: Colors.white, size: 20)),
        title: Text('Chat General ✨', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _colorTextoPrincipal(context))),
        subtitle: Text('¡Habla con toda la comunidad!', style: GoogleFonts.inter(color: _colorTextoSecundario(context), fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFF28B50)),
        onTap: () {},
      ),
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Salas de Chat', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
          TextButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF248EA6)), 
            label: Text('Crear Sala', style: GoogleFonts.inter(color: const Color(0xFF248EA6), fontWeight: FontWeight.bold))
          ),
        ],
      ),
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
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// --- BARRA DE CONTEXTO DE COMUNIDAD ---
class _BarraContextoComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int? miId;
  final VoidCallback onCerrar;
  final Function(Comunidad)? onComunidadActualizada;

  const _BarraContextoComunidad({
    required this.comunidad,
    this.miId,
    required this.onCerrar,
    this.onComunidadActualizada,
  });

  @override
  State<_BarraContextoComunidad> createState() => _BarraContextoComunidadState();
}

class _BarraContextoComunidadState extends State<_BarraContextoComunidad> {
  String _miRol = 'Miembro';
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  @override
  void didUpdateWidget(_BarraContextoComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _obtenerRol();
    }
  }

  Future<void> _obtenerRol() async {
    setState(() => _cargandoRol = true);
    if (widget.miId == null) {
      if (mounted) setState(() => _cargandoRol = false);
      return;
    }
    final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(widget.comunidad.id, widget.miId!);
    if (mounted) {
      setState(() {
        _miRol = res.datos ?? 'Miembro';
        _cargandoRol = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador = widget.miId != null && widget.miId == widget.comunidad.creadorId;
    final rolLabel = esCreador ? 'Creador' : _miRol;
    final iconRol = esCreador ? Icons.stars_rounded : (rolLabel == 'Moderador' ? Icons.gavel_rounded : Icons.pets_rounded);
    final colorRol = esCreador ? Colors.amber : (rolLabel == 'Moderador' ? const Color(0xFF248EA6) : const Color(0xFFC35E34));

    return SizedBox(
      width: double.infinity,
      height: 500,
      child: Stack(
        children: [
          // Fondo con imagen
          if (widget.comunidad.urlPortada != null && widget.comunidad.urlPortada!.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.comunidad.urlPortada!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: widget.comunidad.colorTema),
              ),
            )
          else
            Positioned.fill(child: Container(color: widget.comunidad.colorTema)),
          
          // Degradado oscuro para que resalte el texto y botones
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // Botones superiores (Cerrar y Administrar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: widget.onCerrar,
                    tooltip: 'Cerrar vista de comunidad',
                  ),
                ),
                if (esCreador || _miRol == 'Moderador')
                  Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                      onPressed: () async {
                        final actualizada = await Navigator.push<Comunidad>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaAdminComunidad(comunidad: widget.comunidad),
                          ),
                        );
                        if (actualizada != null && widget.onComunidadActualizada != null) {
                          widget.onComunidadActualizada!(actualizada);
                        }
                      },
                      tooltip: 'Administrar Comunidad',
                    ),
                  ),
              ],
            ),
          ),

          // Contenido central (Avatar + Título)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar redondo
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.comunidad.colorTema, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)],
                    image: (widget.comunidad.urlPortada != null && widget.comunidad.urlPortada!.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(widget.comunidad.urlPortada!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (widget.comunidad.urlPortada == null || widget.comunidad.urlPortada!.isEmpty)
                      ? const Icon(Icons.groups_rounded, color: Colors.white, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  widget.comunidad.nombre,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Etiqueta de Rol abajo a la izquierda
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorRol.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconRol, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    rolLabel.toUpperCase(),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
