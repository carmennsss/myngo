import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_mejoras.dart';
import '../../utils/mejoras_notifier.dart';
import '../../utils/estilo_post_helper.dart';
import '../../widgets/comunes/post_preview.dart';
import '../../widgets/comunes/profile_preview.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_perfiles.dart';
import 'package:image_picker/image_picker.dart';

class PantallaPersonalizarPerfil extends StatefulWidget {
  const PantallaPersonalizarPerfil({super.key});

  @override
  State<PantallaPersonalizarPerfil> createState() => _PantallaPersonalizarPerfilState();
}

class _PantallaPersonalizarPerfilState extends State<PantallaPersonalizarPerfil> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServicioMejoras _servicioMejoras = ServicioMejoras();
  
  bool _isLoading = true;
  List<dynamic> _misMejoras = [];
  String? _errorMensaje;
  
  dynamic _previewAvatar;
  String? _previewMarco;
  dynamic _previewFondo;
  dynamic _previewFondoPerfil;
  Map<String, dynamic>? _previewEstilo;
  String _nombreUsuario = 'Usuario';
  int _puntos = 0;
  int? _perfilId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarMisMejoras();
  }

  Future<void> _cargarMisMejoras() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final respuesta = await _servicioMejoras.obtenerMisMejoras();
    final datosUser = await ServicioUsuarios().obtenerDatosPropios();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (respuesta.exito && respuesta.datos != null) {
          _misMejoras = respuesta.datos is Iterable ? List<dynamic>.from(respuesta.datos!) : [];
          
          // Inicializar previsualización con lo que ya está equipado
          if (datosUser.exito && datosUser.datos != null) {
            final u = datosUser.datos!;
            _nombreUsuario = u.nombreUsuario;
            _puntos = u.puntos ?? 0;
            _previewAvatar = u.urlAvatar;
            _previewMarco = u.marco;
            _previewFondo = u.fondo; // Banner
            _previewFondoPerfil = u.fondoPerfil; // Feed
            _previewEstilo = u.estiloPost;
            _perfilId = u.perfilId;
          }
        } else {
          _errorMensaje = respuesta.mensaje;
        }
      });
    }
  }

  // --- MÉTODOS DE ACCIÓN ---

  Future<void> _subirImagenPersonalizada(String tipo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (tipo == 'banner') {
          _previewFondo = pickedFile; // Guardamos el XFile para subirlo luego
        } else if (tipo == 'fondo_feed') {
          _previewFondoPerfil = pickedFile;
        } else if (tipo == 'avatar') {
          _previewAvatar = pickedFile;
        }
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_perfilId == null) return;
    
    setState(() => _isLoading = true);
    
    final res = await ServicioUsuarios().actualizarPerfil(
      perfilId: _perfilId!,
      estiloPost: _previewEstilo,
      imagenAvatar: _previewAvatar,
      imagenFondo: _previewFondo,
      imagenFondoPerfil: _previewFondoPerfil,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.exito ? '¡Perfil personalizado con éxito! ✨' : res.mensaje),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
      if (res.exito) {
        _cargarMisMejoras(); // Recargar para limpiar estados de XFile
      }
    }
  }

  void _actualizarAtributoEstilo(String clave, dynamic valor) {
    setState(() {
      _previewEstilo ??= {};
      _previewEstilo![clave] = valor;
    });
  }

  ImageProvider? _buildImageProvider(dynamic source) {
    if (source == null) return null;
    if (source is String && source.isNotEmpty) return NetworkImage(source);
    if (source is XFile) {
      if (kIsWeb) return NetworkImage(source.path);
      return FileImage(File(source.path));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool tieneCambios = _previewAvatar is XFile || _previewFondo is XFile || _previewFondoPerfil is XFile || _previewEstilo != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Premium
              _buildHeader(context),
              
              // Área de Vista Previa con Glassmorphism
              _buildPreviewArea(context),

              // Selector de Categorías (Tabs)
              _buildCategorySelector(),

              // Contenido de la Categoría
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInventoryGrid('Avatar'),
                    _buildInventoryGrid('Marco'),
                    _buildInventoryGrid('Fondo'),
                    _buildEstiloPostPanel(),
                  ],
                ),
              ),
            ],
          ),
          
          // Botón Flotante de Guardar (Solo si hay cambios)
          if (tieneCambios)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: _buildSaveButton(),
              ),
            ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A4440), size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Personalizar Perfil',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A4440),
            ),
          ),
          const Spacer(),
          _buildPuntosBadge(),
        ],
      ),
    );
  }

  Widget _buildPuntosBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2D0BD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_rounded, color: Color(0xFFC35E34), size: 14),
          const SizedBox(width: 6),
          Text(
            '$_puntos',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    final imageProvider = _buildImageProvider(_previewFondoPerfil);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        image: imageProvider != null ? DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.lighten)
        ) : null,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildPreviewHeader(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool esAncho = constraints.maxWidth > 500;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: _buildProfilePreviewWrapper(),
                    ),
                  ),
                  if (esAncho) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildPostPreviewWrapper(),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePreviewWrapper() {
    // Manejar XFile para la previsualización local
    final avatar = _previewAvatar is XFile ? null : _previewAvatar as String?;
    final fondo = _previewFondo is XFile ? null : _previewFondo as String?;

    return Stack(
      children: [
        ProfilePreview(
          fondoUrl: fondo,
          avatarUrl: avatar,
          marcoUrl: _previewMarco,
          nombreUsuario: _nombreUsuario,
          puntos: _puntos,
        ),
        if (_previewAvatar is XFile || _previewFondo is XFile)
          const Positioned(
            top: 10,
            right: 10,
            child: Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
          ),
      ],
    );
  }

  Widget _buildPostPreviewWrapper() {
    final avatar = _previewAvatar is XFile ? null : _previewAvatar as String?;
    return PostPreview(
      estilo: _previewEstilo,
      avatarUrl: avatar,
      marcoUrl: _previewMarco,
      nombreUsuario: _nombreUsuario,
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D0BD).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        labelColor: const Color(0xFFC35E34),
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Avatares'),
          Tab(text: 'Marcos'),
          Tab(text: 'Fondos'),
          Tab(text: 'Estilo Post'),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(String tipo) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final filtradas = _misMejoras.where((m) => m['mejora_detalles'] != null && m['mejora_detalles']['tipo'].toString().toLowerCase() == tipo.toLowerCase()).toList();

    return Column(
      children: [
        if (tipo == 'Fondo') 
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildCustomUploadCard('Fondo personalizado', 'Sube tu propia imagen para el banner o el feed', Icons.add_photo_alternate_rounded, () => _mostrarDialogoSobreFondoPersonalizado()),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: filtradas.length,
            itemBuilder: (context, index) {
              final item = filtradas[index];
              final detalles = item['mejora_detalles'];
              final estaEquipada = item['esta_equipada'] == true;
              
              return _InventoryItemCard(
                detalles: detalles,
                estaEquipada: estaEquipada,
                onTap: () => _actualizarPreview(tipo, detalles),
                onEquipar: () => _equiparMejora(detalles['id'], tipo, detalles['url_recurso']),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomUploadCard(String titulo, String subtitulo, IconData icono, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF2D0BD).withOpacity(0.5)),
          gradient: LinearGradient(colors: [Colors.white, const Color(0xFFFEF5F1)]),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFC35E34).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icono, color: const Color(0xFFC35E34), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF4A4440))),
                  Text(subtitulo, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoSobreFondoPersonalizado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Imagen Personalizada 🎨', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Elige dónde quieres aplicar tu propia imagen:', style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.view_day_rounded, color: Color(0xFFC35E34)),
              title: const Text('Banner de Cabecera'),
              onTap: () { Navigator.pop(context); _subirImagenPersonalizada('banner'); },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF248EA6)),
              title: const Text('Fondo de Perfil (Feed)'),
              onTap: () { Navigator.pop(context); _subirImagenPersonalizada('fondo_feed'); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEstiloPostPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Colores y Borde', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildColorPickerRow('Fondo', 'fondo', ['#FFFFFF', '#FBE9E0', '#E0F2F1', '#F3E5F5', '#E3F2FD', '#121212']),
          const SizedBox(height: 16),
          _buildColorPickerRow('Borde', 'borde', ['#C35E34', '#248EA6', '#9B59B6', '#2ECC71', '#F1C40F', '#000000']),
          
          const SizedBox(height: 24),
          Text('Tipografía', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildFontSelector(),
          
          const SizedBox(height: 24),
          _buildInventoryGridSection('Estilo Post', 'Tus estilos comprados'),
        ],
      ),
    );
  }

  Widget _buildColorPickerRow(String label, String clave, List<String> hexColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hexColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = EstiloPostHelper.parseHex(hexColors[index])!;
              final isSelected = _previewEstilo?[clave] == hexColors[index];
              return GestureDetector(
                onTap: () => _actualizarAtributoEstilo(clave, hexColors[index]),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? const Color(0xFFC35E34) : Colors.grey.shade300, width: isSelected ? 3 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.3), blurRadius: 8)] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontSelector() {
    final fuentes = ['Outfit', 'Roboto', 'Inter', 'Lobster', 'Dancing Script', 'Indie Flower'];
    final fuenteActual = _previewEstilo?['fuente'] ?? 'Outfit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fuentes.contains(fuenteActual) ? fuenteActual : 'Outfit',
          isExpanded: true,
          icon: const Icon(Icons.font_download_rounded, color: Color(0xFFC35E34)),
          items: fuentes.map((f) => DropdownMenuItem(
            value: f,
            child: Text(f, style: GoogleFonts.getFont(f, color: const Color(0xFF4A4440))),
          )).toList(),
          onChanged: (val) => _actualizarAtributoEstilo('fuente', val),
        ),
      ),
    );
  }

  Widget _buildInventoryGridSection(String tipo, String titulo) {
    final filtradas = _misMejoras.where((m) => m['mejora_detalles'] != null && m['mejora_detalles']['tipo'].toString().toLowerCase() == tipo.toLowerCase()).toList();
    if (filtradas.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
          itemCount: filtradas.length,
          itemBuilder: (context, index) {
            final item = filtradas[index];
            return _InventoryItemCard(
              detalles: item['mejora_detalles'],
              estaEquipada: item['esta_equipada'] == true,
              onTap: () => _actualizarPreview(tipo, item['mejora_detalles']),
              onEquipar: () => _equiparMejora(item['mejora_detalles']['id'], tipo, item['mejora_detalles']['url_recurso']),
              compacto: true,
            );
          },
        ),
      ],
    );
  }

  void _actualizarPreview(String tipo, dynamic detalles) {
    setState(() {
      final t = tipo.toLowerCase();
      if (t == 'avatar') {
        _previewAvatar = detalles['url_recurso'];
      } else if (t == 'marco') {
        _previewMarco = detalles['url_recurso'];
      } else if (t == 'fondo') {
        _previewFondo = detalles['url_recurso']; // Banner
      } else if (t == 'fondo_perfil' || t == 'banner') {
        _previewFondoPerfil = detalles['url_recurso']; // Feed
      } else if (t.contains('estilo')) {
        _previewEstilo = detalles['datos_extra'];
      }
    });
  }

  Widget _buildPreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'VISTA PREVIA',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _equiparMejora(int mejoraId, String? tipo, String? url) async {
    // Para mantener compatibilidad, seguimos usando el servicio de equipar
    // pero también actualizamos la previsualización local
    final respuesta = await ServicioMejoras().equiparMejora(mejoraId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
      if (respuesta.exito) {
        _actualizarPreview(tipo ?? 'Avatar', {'url_recurso': url});
        _cargarMisMejoras();
        notificarMejoraEquipada();
      }
    }
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _guardarCambios,
      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      label: Text('GUARDAR ESTILO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF248EA6),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 8,
        shadowColor: const Color(0xFF248EA6).withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final dynamic detalles;
  final bool estaEquipada;
  final VoidCallback onTap;
  final VoidCallback onEquipar;
  final bool compacto;

  const _InventoryItemCard({required this.detalles, required this.estaEquipada, required this.onTap, required this.onEquipar, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final String? url = detalles['url_recurso'];
    final bool esEstilo = detalles['tipo'].toString().toLowerCase().contains('estilo');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: estaEquipada ? const Color(0xFF248EA6) : Colors.grey.shade200, width: estaEquipada ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  color: const Color(0xFFFBE9E0),
                  child: esEstilo 
                    ? _buildMiniEstilo(detalles['datos_extra'])
                    : (url != null && url.isNotEmpty ? Image.network(url, fit: BoxFit.cover) : const Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
                ),
              ),
            ),
            if (!compacto)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  detalles['nombre'] ?? detalles['tipo'],
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniEstilo(Map<String, dynamic>? datos) {
    if (datos == null) return const Icon(Icons.palette_rounded);
    return Container(
      decoration: EstiloPostHelper.buildDecoracion(datos, borderRadius: BorderRadius.circular(0)),
      child: Center(child: Icon(Icons.auto_awesome_rounded, color: EstiloPostHelper.esFondoClaro(datos) ? Colors.black26 : Colors.white24, size: 20)),
    );
  }
}

