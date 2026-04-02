import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../models/imagen_galeria.dart';
import '../../models/sala_chat.dart';
import 'widgets/tarjeta_publicacion.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  List<ImagenGaleria> _imagenesGaleria = [];
  List<SalaChat> _salasChat = [];
  bool _estaCargandoDatos = false;

  @override
  void initState() {
    super.initState();
    _obtenerMiId();
    _cargarDatosSeccion(0);
  }

  Future<void> _obtenerMiId() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  Future<void> _cargarDatosSeccion(int index) async {
    setState(() => _estaCargandoDatos = true);
    try {
      if (index == 0) {
        final res = await _servicio.obtenerPublicaciones(widget.comunidad.id);
        if (res.exito) _publicaciones = res.datos ?? [];
      } else if (index == 2) {
        final res = await _servicio.obtenerGaleria(widget.comunidad.id);
        if (res.exito) _imagenesGaleria = res.datos ?? [];
      } else if (index == 3) {
        final res = await _servicio.obtenerSalasChat(widget.comunidad.id);
        if (res.exito) _salasChat = res.datos ?? [];
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
              leading: const Icon(Icons.group_add_rounded, color: Color(0xFFF29C50)),
              title: Text('Gestionar Peticiones', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded, color: Color(0xFFF29C50)),
              title: Text('Moderación', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              onTap: () { Navigator.pop(context); },
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
            icon: const Icon(Icons.settings, color: Colors.white),
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
            Text(' ${widget.comunidad.ratingMedio.toStringAsFixed(1)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
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
          : Text(widget.comunidad.esPublica ? 'UNIRSE AHORA ✨' : 'SOLICITAR ENTRAR 🐾', 
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              _buildMiniChip('Muro', _indiceGaleria == 0, () => setState(() => _indiceGaleria = 0)),
              const SizedBox(width: 12),
              _buildMiniChip('Colecciones', _indiceGaleria == 1, () => setState(() => _indiceGaleria = 1)),
            ],
          ),
        ),
        Expanded(
          child: _indiceGaleria == 0 ? _buildGalleryWall() : _buildGalleryCollections(),
        ),
      ],
    );
  }

  Widget _buildGalleryWall() {
    if (_estaCargandoDatos && _imagenesGaleria.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    if (_imagenesGaleria.isEmpty) return _buildEmptyState(Icons.photo_library_outlined, 'No hay fotos todavía');

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
      itemCount: _imagenesGaleria.length,
      itemBuilder: (context, index) {
        final img = _imagenesGaleria[index];
        final url = img.urlS3.startsWith('http') ? img.urlS3 : 'http://127.0.0.1:8000${img.urlS3}';
        return Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A2A))),
          clipBehavior: Clip.antiAlias,
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildGalleryCollections() {
    return _buildEmptyState(Icons.folder_open_rounded, 'Crea tu primera colección');
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
