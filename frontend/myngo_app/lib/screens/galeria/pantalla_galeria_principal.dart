import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/coleccion.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pantalla_detalle_coleccion.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Pantalla de galería con dos pestañas: todas las fotos/vídeos (masonry) y las colecciones (carpetas).
// Sirve tanto para galería personal como para galería de comunidad.
class PantallaGaleriaPrincipal extends StatefulWidget {
  final int? comunidadId;
  final int? usuarioId;
  final String titulo;

  const PantallaGaleriaPrincipal({
    Key? key, 
    this.comunidadId, 
    this.usuarioId, 
    required this.titulo
  }) : super(key: key);

  @override
  _PantallaGaleriaPrincipalState createState() => _PantallaGaleriaPrincipalState();
}

class _PantallaGaleriaPrincipalState extends State<PantallaGaleriaPrincipal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _servicioGaleria = ServicioGaleria();

  List<Coleccion> _colecciones = [];
  bool _cargandoColecciones = false;
  int? _miId; // ID del usuario logueado

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarColecciones();
    _cargarMiId();
  }

  // Averigua el ID del usuario logueado para saber si puede crear colecciones
  Future<void> _cargarMiId() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) setState(() => _miId = id);
  }

  /// Puede crear colecciones si:
  /// - Es galería de comunidad (cualquier miembro puede crear)
  /// - O es su propia galería de perfil (usuarioId no especificado o es el suyo)
  bool get _puedeCrearColeccion {
    if (widget.comunidadId != null) return true;
    if (widget.usuarioId == null) return true; // galería propia sin userId explícito
    return _miId != null && _miId == widget.usuarioId;
  }

  // Carga las colecciones del usuario o la comunidad según los parámetros
  Future<void> _cargarColecciones() async {
    setState(() => _cargandoColecciones = true);
    final respuesta = await _servicioGaleria.obtenerColecciones(
      idComunidad: widget.comunidadId,
      idUsuario: widget.usuarioId,
    );
    if (respuesta.exito && respuesta.datos != null) {
      setState(() => _colecciones = respuesta.datos!);
    }
    setState(() => _cargandoColecciones = false);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
        backgroundColor: const Color(0xFFFEF5F1),
        appBar: AppBar(
          title: Text(
            widget.titulo.toUpperCase(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFFFEF5F1),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
          titleTextStyle: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFC35E34),
            labelColor: const Color(0xFFC35E34),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: tr('galleryTabsGallery')),
              Tab(text: tr('galleryTabsCollections')),
            ],
          ),
          actions: [
            if (_puedeCrearColeccion)
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFC35E34)),
                onSelected: (value) => _seleccionarYSubir(value == 'video', tr),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'image', child: Row(children: [const Icon(Icons.image_outlined, size: 20), const SizedBox(width: 8), Text(tr('galleryUploadImage'))])),
                  PopupMenuItem(value: 'video', child: Row(children: [const Icon(Icons.videocam_outlined, size: 20), const SizedBox(width: 8), Text(tr('galleryUploadVideo'))])),
                ],
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pestaña 1: Masonry Grid
            MasonryGridGaleria(
              comunidadId: widget.comunidadId,
              usuarioId: widget.usuarioId,
            ),
            
            // Pestaña 2: Colecciones
            _buildColeccionesTab(tr),
          ],
        ),
        floatingActionButton: _puedeCrearColeccion
            ? FloatingActionButton(
                backgroundColor: const Color(0xFFC35E34),
                elevation: 4,
                child: const Icon(Icons.create_new_folder_outlined, color: Colors.white),
                onPressed: () => _mostrarDialogoCrearColeccion(tr),
              )
            : null,
      );
    });
  }

  // Renderiza el grid de colecciones de la segunda pestaña
  Widget _buildColeccionesTab(dynamic tr) {
    if (_cargandoColecciones && _colecciones.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
    }

    if (_colecciones.isEmpty) {
      return EstadoVacioCargando(
        icon: Icons.folder_open_outlined,
        message: tr('galleryNoCollections'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _colecciones.length,
        itemBuilder: (context, index) {
          final coleccion = _colecciones[index];
          return _buildCarpetaColeccion(coleccion, tr);
        },
      ),
    );
  }

  // Tarjeta de carpeta con icono de candado si es privada
  Widget _buildCarpetaColeccion(Coleccion coleccion, dynamic tr) {
    return InkWell(
      onTap: () {
          Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaDetalleColeccion(coleccion: coleccion),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              coleccion.esPrivada ? Icons.lock_outline : Icons.folder_rounded,
              color: const Color(0xFFC35E34),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              coleccion.nombreColeccion,
              style: GoogleFonts.outfit(
                color: const Color(0xFF4A4440),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              tr('galleryResources', {'count': coleccion.numeroImagenes.toString()}),
              style: GoogleFonts.outfit(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para crear una nueva colección con nombre y opción de privacidad
  void _mostrarDialogoCrearColeccion(dynamic tr) {
    final TextEditingController _nombreCtrl = TextEditingController();
    bool _privada = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('galleryNewColeccion'), style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Color(0xFF4A4440)),
                decoration: InputDecoration(
                  labelText: tr('galleryFolderLabel'),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC35E34))),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(tr('galleryIsPrivate'), style: GoogleFonts.outfit(color: Colors.grey.shade700)),
                value: _privada,
                activeColor: const Color(0xFFC35E34),
                onChanged: (v) => setDialogState(() => _privada = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('commonCancel'), style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC35E34),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (_nombreCtrl.text.isNotEmpty) {
                  final resp = await _servicioGaleria.crearColeccion(
                    nombre: _nombreCtrl.text,
                    esPrivada: _privada,
                    idComunidad: widget.comunidadId,
                  );
                  if (resp.exito) {
                    Navigator.pop(context);
                    _cargarColecciones();
                  }
                }
              },
              child: Text(tr('commonCreate')),
            ),
          ],
        ),
      ),
    );
  }

  // Abre el selector del dispositivo para subir directamente a la galería
  Future<void> _seleccionarYSubir(bool esVideo, dynamic tr) async {
    final picker = ImagePicker();
    final pickedFile = esVideo 
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(esVideo ? tr('galleryUploadingVideo') : tr('galleryUploadingImage')), behavior: SnackBarBehavior.floating),
      );
      
      final res = await _servicioGaleria.subirImagenGaleria(
        pickedFile, 
        idComunidad: widget.comunidadId,
        esPublica: true
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.mensaje), 
            backgroundColor: res.exito ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (res.exito) {
          _tabController.animateTo(0); // Volver a la pestaña de galería
          // Se podría forzar un refresh del MasonryGridGaleria si fuera necesario
        }
      }
    }
  }
}
