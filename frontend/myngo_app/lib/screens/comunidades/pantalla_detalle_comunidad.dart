import 'package:flutter/material.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/respuesta_api.dart';
import '../../models/publicacion.dart';
import '../../models/imagen_galeria.dart';
import '../../models/sala_chat.dart';
import 'widgets/tarjeta_publicacion.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Pantalla que muestra los detalles de una comunidad específica.
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
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.redAccent,
        ),
      );
      if (respuesta.exito) {
        setState(() { widget.comunidad.esMiembro = true; });
        _cargarDatosSeccion(0);
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const Divider(height: 48, thickness: 1, color: Color(0xFFF1F3F9)),
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
      backgroundColor: const Color(0xFFF7F4FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(isDashboard: true),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SubNavDelegate(
              selectedIndex: _indiceSeccion,
              onTap: (index) => setState(() => _indiceSeccion = index),
            ),
          ),
        ],
        body: IndexedStack(
          index: _indiceSeccion,
          children: [
            _buildPostFeed(),
            _buildStore(),
            _buildGallery(),
            _buildChat(),
          ],
        ),
      ),
      floatingActionButton: _indiceSeccion == 0 ? FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoPost(context),
        label: const Text('Miau Post', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        backgroundColor: const Color(0xFF6C63FF),
      ) : null,
    );
  }

  void _mostrarDialogoNuevoPost(BuildContext context) {
    final controlador = TextEditingController();
    XFile? imagenSeleccionada;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nueva Publicación 🐾', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controlador,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '¿Qué estás pensando, miau?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              if (imagenSeleccionada != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: kIsWeb ? NetworkImage(imagenSeleccionada!.path) as ImageProvider : NetworkImage(imagenSeleccionada!.path), // En móvil XFile.path suele ser path local, pero para web/móvil cruzado mejor usar estrategias según plataforma. Simplificamos para que compile.
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (img != null) setModalState(() => imagenSeleccionada = img);
                    },
                    icon: const Icon(Icons.image_search_rounded, color: Color(0xFF6C63FF)),
                  ),
                  const Spacer(),
                  Consumer<PostProvider>(
                    builder: (context, provider, child) => ElevatedButton(
                      onPressed: provider.state == PostState.loading ? null : () async {
                        final exito = await provider.crearPost(
                          comunidadId: widget.comunidad.id,
                          texto: controlador.text,
                          imagen: imagenSeleccionada, // Pasamos XFile directamente
                        );
                        
                        if (exito && mounted) {
                          Navigator.pop(context);
                          _cargarDatosSeccion(0); // Recargar feed
                        } else if (provider.state == PostState.moderationRejected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage), backgroundColor: Colors.orange.shade800),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
                      child: provider.state == PostState.loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Publicar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar({bool isDashboard = false}) {
    return SliverAppBar(
      expandedHeight: isDashboard ? 200 : 250,
      pinned: true,
      backgroundColor: const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        title: isDashboard ? Text(widget.comunidad.nombre, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)) : null,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.comunidad.urlPortada.isEmpty
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
              : Image.network(
                  widget.comunidad.urlPortada, 
                  fit: BoxFit.cover,
                  headers: const {'Access-Control-Allow-Origin': '*'},
                ),
            if (isDashboard)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
              ),
            ),
            _ChipPrivacidad(esPublica: widget.comunidad.esPublica),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text('Por ${widget.comunidad.creadorNombre}', style: const TextStyle(color: Color(0xFF9094A6), fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            Text(' ${widget.comunidad.ratingMedio}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sobre esta comunidad 🐾', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        const SizedBox(height: 8),
        Text(
          widget.comunidad.descripcion.isEmpty 
            ? 'Sin descripción todavía.' 
            : widget.comunidad.descripcion,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: _estaCargandoPeticion ? null : _gestionarMembresia,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _estaCargandoPeticion
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(widget.comunidad.esPublica ? 'UNIRSE AHORA ✨' : 'SOLICITAR ENTRAR 🐾', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  int _indiceGaleria = 0; // 0: Muro, 1: Colecciones

  // --- SECCIONES DEL DASHBOARD ---

  Widget _buildPostFeed() {
    if (_estaCargandoDatos && _publicaciones.isEmpty) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: () => _cargarDatosSeccion(0),
      child: _publicaciones.isEmpty 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Aún no hay publicaciones', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _publicaciones.length,
            itemBuilder: (context, index) => TarjetaPublicacion(publicacion: _publicaciones[index]),
          ),
    );
  }

  Widget _buildGallery() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
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
    if (_estaCargandoDatos && _imagenesGaleria.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_imagenesGaleria.isEmpty) return _buildEmptyState(Icons.photo_library_outlined, 'No hay fotos todavía');

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
      itemCount: _imagenesGaleria.length,
      itemBuilder: (context, index) {
        final img = _imagenesGaleria[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
          clipBehavior: Clip.antiAlias,
          child: Image.network(img.urlS3, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildGalleryCollections() {
    return _buildEmptyState(Icons.folder_open_rounded, 'Crea tu primera colección 文件夹');
  }

  Widget _buildMiniChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6C63FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF6C63FF) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildStore() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.purple.shade100),
      const SizedBox(height: 16),
      const Text('Próximamente: Tienda de Aspectos 🎨', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)),
    ]));
  }

  Widget _buildChat() {
    if (_estaCargandoDatos && _salasChat.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salasChat.length + 2, // General + Salas + Header
      itemBuilder: (context, index) {
        if (index == 0) return _buildChatHeader();
        if (index == 1) return _buildGeneralChatTile();
        final sala = _salasChat[index - 2];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.tag, color: Colors.grey)),
          title: Text(sala.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildGeneralChatTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6C63FF).withOpacity(0.1), Colors.white]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFF6C63FF), child: Icon(Icons.forum_rounded, color: Colors.white, size: 18)),
        title: const Text('Chat General ✨', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6C63FF))),
        subtitle: const Text('¡Habla con toda la comunidad!'),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6C63FF)),
        onTap: () {},
      ),
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Salas de Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, size: 20), label: const Text('Crear Sala')),
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
      color: Colors.white,
      height: 60,
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
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? const Color(0xFF6C63FF) : Colors.grey, size: 24),
          Text(label, style: TextStyle(color: active ? const Color(0xFF6C63FF) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          if (active)
            Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: const Color(0xFF6C63FF)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
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
        color: esPublica ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.visibility_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            esPublica ? 'Pública' : 'Privada',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: esPublica ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
