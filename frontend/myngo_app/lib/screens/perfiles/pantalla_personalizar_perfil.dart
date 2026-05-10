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
import 'package:myngo_app/utils/tr_helper.dart';

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
  String _previewColorTema = '#C35E34';
  String _previewFuentePerfil = 'Outfit';

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
            _previewColorTema = u.colorTema;
            _previewFuentePerfil = u.fuentePerfil;
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
      colorTema: _previewColorTema,
      fuentePerfil: _previewFuentePerfil,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.exito ? tr('customProfileSuccess') : res.mensaje),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
      if (res.exito) {
        _cargarMisMejoras(); // Recargar para limpiar estados de XFile
        notificarMejoraEquipada(); // Notificar para que Detalle Perfil se recargue
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
    final bool tieneCambios = _previewAvatar is XFile || 
                            _previewFondo is XFile || 
                            _previewFondoPerfil is XFile || 
                            _previewEstilo != null ||
                            (_perfilId != null && (_previewColorTema != '#C35E34' || _previewFuentePerfil != 'Outfit')); 
                            // Simplificado, idealmente comparar con valores iniciales

    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Premium
                _buildHeader(context, tr),
                
                // Área de Vista Previa con Glassmorphism
                _buildPreviewArea(context, tr),
  
                // Selector de Categorías (Tabs)
                _buildCategorySelector(tr),
  
                // Contenido de la Categoría
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInventoryGrid('Avatar', tr),
                      _buildInventoryGrid('Marco', tr),
                      _buildInventoryGrid('Fondo', tr),
                      _buildPersonalizacionPanel(),
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
                  child: _buildSaveButton(tr),
                ),
              ),
            
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 5)),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, Function tr) {
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
            tr('customProfileTitle'),
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

  Widget _buildPreviewArea(BuildContext context, Function tr) {
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
          _buildPreviewHeader(tr),
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
          colorTema: _previewColorTema,
          fuentePerfil: _previewFuentePerfil,
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

  Widget _buildCategorySelector(Function tr) {
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
        tabs: [
          Tab(text: tr('customProfileTabAvatars')),
          Tab(text: tr('customProfileTabFrames')),
          Tab(text: tr('customProfileTabBackgrounds')),
          Tab(text: tr('customProfileTabThemeStyle')),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(String tipo, Function tr) {
    // Eliminado el CircularProgressIndicator redundante de aquí
    final filtradas = _misMejoras.where((m) => m['mejora_detalles'] != null && m['mejora_detalles']['tipo'].toString().toLowerCase() == tipo.toLowerCase()).toList();

    return Column(
      children: [
        if (tipo == 'Fondo') 
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildCustomUploadCard(tr('customProfileCustomBgTitle'), tr('customProfileCustomBgSubtitle'), Icons.add_photo_alternate_rounded, () => _mostrarDialogoSobreFondoPersonalizado()),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
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
                onDesequipar: () => _desequiparMejora(detalles['id'], tipo),
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
            Text(tr('customProfileDialogImageTitle'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('customProfileDialogImageDesc'), style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.view_day_rounded, color: Color(0xFFC35E34)),
              title: Text(tr('customProfileDialogBanner')),
              onTap: () { Navigator.pop(context); _subirImagenPersonalizada('banner'); },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF248EA6)),
              title: Text(tr('customProfileDialogFeed')),
              onTap: () { Navigator.pop(context); _subirImagenPersonalizada('fondo_feed'); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizacionPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Tema (Nuevo)
          _buildThemeSection(),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          
          Text(tr('customProfileSectionPostStyle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF4A4440))),
          const SizedBox(height: 8),
          Text(tr('customProfileSectionPostStyleDesc'), style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          
          Text(tr('customProfileSectionColorsBorder'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildColorPickerRow(tr('customProfileColorLabelBg'), 'fondo', ['#FFFFFF', '#FBE9E0', '#E0F2F1', '#F3E5F5', '#E3F2FD', '#121212']),
          const SizedBox(height: 16),
          _buildColorPickerRow(tr('customProfileColorLabelBorder'), 'borde', ['#C35E34', '#248EA6', '#9B59B6', '#2ECC71', '#F1C40F', '#000000']),
          
          const SizedBox(height: 24),
          _buildInventoryGridSection('Estilo Post', tr('customProfileThemePurchasedStyles')),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final List<String> coloresTema = ['#C35E34', '#248EA6', '#9B59B6', '#2ECC71', '#F1C40F', '#E74C3C', '#34495E'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('customProfileSectionTheme'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF4A4440))),
        const SizedBox(height: 8),
        Text(tr('customProfileSectionThemeDesc'), style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 20),
        
        Text(tr('customProfileThemeMainColor'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: coloresTema.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == coloresTema.length) {
                // Botón de reset
                final isDefault = _previewColorTema == '#C35E34';
                return GestureDetector(
                  onTap: () => setState(() => _previewColorTema = '#C35E34'),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDefault ? Colors.grey : Colors.transparent, width: 2),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 20),
                  ),
                );
              }
              final colorHex = coloresTema[index];
              final color = EstiloPostHelper.parseHex(colorHex)!;
              final isSelected = _previewColorTema == colorHex;
              
              return GestureDetector(
                onTap: () => setState(() => _previewColorTema = colorHex),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        Text(tr('customProfileThemeProfileFont'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildFontSelector(isPost: false),
      ],
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
            itemCount: hexColors.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == hexColors.length) {
                // Botón de desequipar
                return GestureDetector(
                  onTap: () => _actualizarAtributoEstilo(clave, null),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                  ),
                );
              }
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

  Widget _buildFontSelector({required bool isPost}) {
    final fuentes = ['Outfit', 'Roboto', 'Inter', 'Lobster', 'Dancing Script', 'Indie Flower'];
    final fuenteActual = isPost ? (_previewEstilo?['fuente'] ?? 'Outfit') : _previewFuentePerfil;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fuentes.contains(fuenteActual) ? fuenteActual : 'Outfit',
          isExpanded: true,
          icon: Icon(Icons.font_download_rounded, color: isPost ? const Color(0xFFC35E34) : EstiloPostHelper.parseHex(_previewColorTema)),
          items: ['Outfit', ...fuentes.where((f) => f != 'Outfit')].map((f) => DropdownMenuItem(
            value: f,
            child: Text(f == 'Outfit' ? '$f (${tr('customProfileDefault')})' : f, style: GoogleFonts.getFont(f, color: const Color(0xFF4A4440))),
          )).toList(),
          onChanged: (val) {
            if (isPost) {
              _actualizarAtributoEstilo('fuente', val);
            } else {
              setState(() {
                _previewFuentePerfil = val ?? 'Outfit';
                // La fuente del perfil ahora también afecta a los posts
                _actualizarAtributoEstilo('fuente', val);
              });
            }
          },
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
        Builder(
          builder: (context) {
            return GridView.builder(
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
                onDesequipar: () => _desequiparMejora(item['mejora_detalles']['id'], tipo),
                compacto: true,
              );
            },
          );
        }),
      ],
    );
  }

  void _actualizarPreview(String tipo, dynamic detalles, {String? destino}) {
    setState(() {
      final t = tipo.toLowerCase();
      if (t == 'avatar') {
        _previewAvatar = detalles['url_recurso'];
      } else if (t == 'marco') {
        _previewMarco = detalles['url_recurso'];
      } else if (t == 'fondo') {
        if (destino == 'fondo_feed') {
          _previewFondoPerfil = detalles['url_recurso'];
        } else {
          _previewFondo = detalles['url_recurso']; // Banner por defecto
        }
      } else if (t == 'fondo_perfil' || t == 'banner') {
        _previewFondoPerfil = detalles['url_recurso']; // Feed
      } else if (t.contains('estilo')) {
        _previewEstilo = detalles['datos_extra'];
      }
    });
  }

  Widget _buildPreviewHeader(Function tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          tr('customProfilePreview'),
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
    String? destino;
    
    // Si es un fondo, preguntar dónde equiparlo
    if (tipo?.toLowerCase() == 'fondo') {
      destino = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('customProfileEquipBgTitle'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(tr('customProfileEquipBgDesc'), style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.view_day_rounded, color: Color(0xFFC35E34)),
                title: Text(tr('customProfileDialogBanner')),
                onTap: () => Navigator.pop(context, 'banner'),
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF248EA6)),
                title: Text(tr('customProfileDialogFeed')),
                onTap: () => Navigator.pop(context, 'fondo_feed'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      
      if (destino == null) return; // Usuario canceló
    }

    setState(() => _isLoading = true);
    final respuesta = await ServicioMejoras().equiparMejora(mejoraId, destino: destino);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
      if (respuesta.exito) {
        _actualizarPreview(tipo ?? 'Avatar', {'url_recurso': url}, destino: destino);
        _cargarMisMejoras();
        notificarMejoraEquipada();
      }
    }
  }

  Future<void> _desequiparMejora(int mejoraId, String? tipo) async {
    setState(() => _isLoading = true);
    final respuesta = await ServicioMejoras().equiparMejora(mejoraId); // El backend hace toggle
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.exito ? tr('profileUnequipSuccess') : respuesta.mensaje),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
      if (respuesta.exito) {
        // Limpiar preview local según el tipo
        setState(() {
          final t = tipo?.toLowerCase() ?? '';
          if (t == 'avatar') _previewAvatar = null;
          else if (t == 'marco') _previewMarco = null;
          else if (t == 'fondo') { _previewFondo = null; _previewFondoPerfil = null; }
          else if (t.contains('estilo')) _previewEstilo = null;
        });
        _cargarMisMejoras();
        notificarMejoraEquipada();
      }
    }
  }

  Widget _buildSaveButton(Function tr) {
    return Container(
      width: 280,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFC35E34),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _guardarCambios,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('customProfileSaveButton'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        tr('customProfileSaveButtonDesc'),
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final dynamic detalles;
  final bool estaEquipada;
  final VoidCallback onTap;
  final VoidCallback onEquipar;
  final VoidCallback onDesequipar;
  final bool compacto;

  const _InventoryItemCard({required this.detalles, required this.estaEquipada, required this.onTap, required this.onEquipar, required this.onDesequipar, this.compacto = false});

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
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: estaEquipada ? onDesequipar : onEquipar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: estaEquipada ? Colors.grey.shade200 : const Color(0xFFC35E34),
                  foregroundColor: estaEquipada ? const Color(0xFF4A4440) : Colors.white,
                  elevation: estaEquipada ? 0 : 2,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Builder(
                  builder: (context) {
                    return Text(
                      estaEquipada ? tr('profileUnequip') : tr('profileEquip'),
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900),
                    );
                  }
                ),
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

