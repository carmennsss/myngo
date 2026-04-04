import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../models/sala_chat.dart';
import 'widgets/tarjeta_publicacion.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../models/coleccion.dart';
import '../galeria/pantalla_detalle_coleccion.dart';
import 'pantalla_admin_comunidad.dart';
import 'package:cached_network_image/cached_network_image.dart';


class PantallaDetalleComunidad extends StatefulWidget {
  final Comunidad comunidad;

  const PantallaDetalleComunidad({super.key, required this.comunidad});

  @override
  State<PantallaDetalleComunidad> createState() => _PantallaDetalleComunidadState();
}

class _PantallaDetalleComunidadState extends State<PantallaDetalleComunidad> {
  final _servicio = ServicioComunidades();
  final _servicioUsuarios = ServicioUsuarios();
  
  bool _estaCargandoPeticion = false;
  int? _miId;
  int _indiceSeccion = 0; 
  
  List<Publicacion> _publicaciones = [];
  List<SalaChat> _salasChat = [];
  bool _estaCargandoDatos = false;
  Key _galeriaKey = UniqueKey(); // Clave para forzar refresco

  @override
  void initState() {
    super.initState();
    _obtenerMiId();
    _cargarDatosSeccion(0);
    _cargarColecciones();
  }

  final _servicioGaleria = ServicioGaleria();
  List<Coleccion> _colecciones = [];

  Future<void> _cargarColecciones() async {
    final res = await _servicioGaleria.obtenerColecciones(comunidadId: widget.comunidad.id);
    if (res.exito && res.datos != null) {
      setState(() => _colecciones = res.datos!);
    }
  }

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  Future<void> _cargarDatosSeccion(int index) async {
    setState(() => _estaCargandoDatos = true);
    try {
      if (index == 0) {
        setState(() { _publicaciones = []; }); // Limpiamos para feedback visual
        final res = await _servicio.obtenerPublicaciones(widget.comunidad.id);
        if (res.exito && mounted) setState(() => _publicaciones = res.datos ?? []);
      } else if (index == 2) {
        setState(() { _galeriaKey = UniqueKey(); }); // Forzamos reconstrucción de la grilla
        await _cargarColecciones();
      } else if (index == 3) {
        final res = await _servicio.obtenerSalasChat(widget.comunidad.id);
        if (res.exito && mounted) setState(() => _salasChat = res.datos ?? []);
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
        } else if (respuesta.datos?['estado'] == 'SOLICITUD') {
          setState(() { widget.comunidad.esPendiente = true; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;
    final esMiembro = widget.comunidad.esMiembro || esCreador;

    if (!esMiembro) {
      return _buildPreview(context);
    }

    return _buildDashboard(context);
  }

  Widget _buildPreview(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const Divider(height: 48, thickness: 1, color: Color(0xFF2A2A2A)),
                  _buildAboutSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildJoinButton(),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(isDashboard: true),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SubNavDelegate(
              selectedIndex: _indiceSeccion,
              onTap: (index) {
                setState(() => _indiceSeccion = index);
                _cargarDatosSeccion(index);
              },
            ),
          ),
        ],
        body: Builder(
          builder: (context) {
            if (_indiceSeccion == 0) return _buildPostFeed();
            if (_indiceSeccion == 1) return _buildStore();
            if (_indiceSeccion == 2) return _buildGallery();
            if (_indiceSeccion == 3) return _buildChat();
            return const SizedBox(); // Fallback
          },
        ),
      ),
      floatingActionButton: _indiceSeccion == 0 ? FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoPost(context),
        label: Text('Miau Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        backgroundColor: const Color(0xFFF28B50),
      ) : null,
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
    final controlador = TextEditingController();
    final controladorEtiquetas = TextEditingController();
    XFile? imagenSeleccionada;
    
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
              Text('Nueva Publicación 🐾', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: controlador,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '¿Qué estás pensando, miau?',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 16),
              if (imagenSeleccionada != null)
                Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: kIsWeb ? NetworkImage(imagenSeleccionada!.path) as ImageProvider : NetworkImage(imagenSeleccionada!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    TextField(
                      controller: controladorEtiquetas,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Etiquetas (ej. arte, animales, juegos...)',
                        hintStyle: GoogleFonts.inter(color: Colors.grey),
                        prefixIcon: const Icon(Icons.sell_outlined, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (img != null) setModalState(() => imagenSeleccionada = img);
                    },
                    icon: const Icon(Icons.image_search_rounded, color: Color(0xFFF29C50)),
                  ),
                  const Spacer(),
                  Consumer<PostProvider>(
                    builder: (context, provider, child) => ElevatedButton(
                      onPressed: provider.state == PostState.loading ? null : () async {
                        final exito = await provider.crearPost(
                          comunidadId: widget.comunidad.id,
                          texto: controlador.text,
                          imagen: imagenSeleccionada,
                          etiquetas: controladorEtiquetas.text,
                        );
                        
                        if (exito && mounted) {
                          Navigator.pop(context);
                          _cargarDatosSeccion(0);
                        } else if (provider.state == PostState.moderationRejected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage), backgroundColor: const Color(0xFFD95F43)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF28B50), 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: provider.state == PostState.loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Publicar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
              leading: const Icon(Icons.security_rounded, color: Color(0xFFF29C50)),
              title: Text('Panel de Administración', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('Gestiona solicitudes y reportes', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              onTap: () { 
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaAdminComunidad(comunidad: widget.comunidad)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar({bool isDashboard = false}) {
    final esCreador = _miId != null && _miId == widget.comunidad.creadorId;

    return SliverAppBar(
      expandedHeight: isDashboard ? 200 : 250,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (isDashboard && esCreador)
          IconButton(
            icon: Badge(
              label: widget.comunidad.conteoPendienteAdmin > 0 
                ? Text(widget.comunidad.conteoPendienteAdmin.toString()) 
                : null,
              isLabelVisible: widget.comunidad.conteoPendienteAdmin > 0,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () => _mostrarAjustesComunidad(context),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: isDashboard ? Text(widget.comunidad.nombre, 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)) : null,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.comunidad.urlPortada.isEmpty
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF248EA6), Color(0xFFF29C50)],
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                      ),
                    ),
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
            if (isDashboard)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF121212), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.comunidad.nombre,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            _ChipPrivacidad(esPublica: widget.comunidad.esPublica),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Color(0xFFF29C50)),
            const SizedBox(width: 8),
            Text('Por ${widget.comunidad.creadorNombre}', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.star_rounded, color: Color(0xFFF29C50), size: 20),
            Text(
              ' ${widget.comunidad.ratingMedio.toStringAsFixed(1)}', 
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre esta comunidad 🐾', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          widget.comunidad.descripcion.isEmpty 
            ? 'Sin descripción todavía.' 
            : widget.comunidad.descripcion,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade400, height: 1.5),
        ),
        
        if (widget.comunidad.minRatingAcceso > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF29C50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF29C50).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFF29C50), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisito de Nivel 🐾',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          color: Colors.white, 
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Necesitas una media de ${widget.comunidad.minRatingAcceso.toStringAsFixed(1)} ⭐ para unirte.',
                        style: GoogleFonts.inter(
                          color: Colors.grey, 
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinButton() {
    if (_miId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF121212),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('INICIA SESIÓN PARA UNIRTE 🐾', 
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF121212),
      child: ElevatedButton(
        onPressed: _estaCargandoPeticion ? null : _gestionarMembresia,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF28B50),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _estaCargandoPeticion
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              widget.comunidad.esPendiente 
                ? 'SOLICITUD PENDIENTE 🐾' 
                : (widget.comunidad.esPublica ? 'UNIRSE AHORA ✨' : 'SOLICITAR ENTRAR 🐾'), 
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)
            ),
      ),
    );
  }

  int _indiceGaleria = 0; 

  Widget _buildPostFeed() {
    if (_estaCargandoDatos && _publicaciones.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    
    return RefreshIndicator(
      color: const Color(0xFFF28B50),
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _cargarDatosSeccion(0),
      child: _publicaciones.isEmpty 
        ? _buildEmptyState(Icons.feed_outlined, 'Aún no hay publicaciones')
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _publicaciones.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: TarjetaPublicacion(publicacion: _publicaciones[index]),
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
    if (_colecciones.isEmpty) {
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
      itemCount: _colecciones.length,
      itemBuilder: (context, index) {
        final col = _colecciones[index];
        final rotacion = (random.nextDouble() - 0.5) * 0.1;
        final coloresHex = [0xFF248EA6, 0xFFF28B50, 0xFFD95F43, 0xFF8338EC];
        final color = Color(coloresHex[index % coloresHex.length]);

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleColeccion(coleccion: col)));
          },
          child: Transform.rotate(
            angle: rotacion,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                        child: col.previsualizaciones.isEmpty
                            ? Center(child: Icon(col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_open_rounded, color: color, size: 24))
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                ),
                                itemCount: col.previsualizaciones.length,
                                itemBuilder: (context, i) => CachedNetworkImage(
                                  imageUrl: col.previsualizaciones[i],
                                  fit: BoxFit.cover,
                                  placeholder: (c,u) => Container(color: Colors.white10),
                                ),
                              ),
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

  Widget _buildMiniChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF28B50) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFFF28B50) : const Color(0xFF2A2A2A)),
        ),
        child: Text(label, style: GoogleFonts.inter(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildStore() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_bag_outlined, size: 80, color: const Color(0xFFF2D0BD).withOpacity(0.3)),
      const SizedBox(height: 16),
      Text('Próximamente: Tienda de Aspectos 🎨', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)),
    ]));
  }

  Widget _buildChat() {
    if (_estaCargandoDatos && _salasChat.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _salasChat.length + 2, 
      itemBuilder: (context, index) {
        if (index == 0) return _buildChatHeader();
        if (index == 1) return _buildGeneralChatTile();
        final sala = _salasChat[index - 2];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tag, color: Colors.grey),
          ),
          title: Text(sala.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(backgroundColor: Color(0xFFF28B50), child: Icon(Icons.forum_rounded, color: Colors.white, size: 20)),
        title: Text('Chat General ✨', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white)),
        subtitle: Text('¡Habla con toda la comunidad!', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
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
          Text('Salas de Chat', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

class _SubNavDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final Function(int) onTap;

  _SubNavDelegate({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121212),
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(0, Icons.grid_view_rounded, 'Muro'),
          _buildItem(1, Icons.shopping_bag_rounded, 'Tienda'),
          _buildItem(2, Icons.collections_rounded, 'Galería'),
          _buildItem(3, Icons.chat_bubble_rounded, 'Chats'),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final active = selectedIndex == index;
    final color = active ? const Color(0xFFF28B50) : Colors.grey;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        color: Colors.transparent, // expand tap area
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (active)
              Container(height: 3, width: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;
  @override
  double get minExtent => 70;
  @override
  bool shouldRebuild(covariant _SubNavDelegate oldDelegate) => oldDelegate.selectedIndex != selectedIndex;
}

class _ChipPrivacidad extends StatelessWidget {
  final bool esPublica;
  const _ChipPrivacidad({required this.esPublica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esPublica ? const Color(0xFF248EA6).withOpacity(0.15) : const Color(0xFFD95F43).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.visibility_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
          ),
          const SizedBox(width: 6),
          Text(
            esPublica ? 'Pública' : 'Privada',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: esPublica ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
            ),
          ),
        ],
      ),
    );
  }
}
