import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tolgee/tolgee.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/galeria/pantalla_detalle_imagen.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/galeria/dialogo_selector_imagen.dart';
import '../comunes/menu_opciones_contenido.dart';
import '../comunes/estado_vacio_cargando.dart';
import 'dart:ui' as ui;
import 'package:myngo_app/utils/tr_helper.dart';

class MasonryGridGaleria extends StatefulWidget {
  final int? comunidadId;
  final int? usuarioId;
  final int? coleccionId;
  final bool esMiembro;

  const MasonryGridGaleria({
    Key? key,
    this.comunidadId,
    this.usuarioId,
    this.coleccionId,
    this.esMiembro = true,
  }) : super(key: key);

  @override
  _MasonryGridGaleriaState createState() => _MasonryGridGaleriaState();
}

class _MasonryGridGaleriaState extends State<MasonryGridGaleria> {
  final _servicioGaleria = ServicioGaleria();
  
  List<ImagenGaleria>? _items;
  bool _cargando = false;
  bool _subiendo = false;
  bool _hayMas = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _cargarMas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarMas() async {
    if (_cargando) return;
    if (!mounted) return;
    setState(() {
      _cargando = true;
      if (_offset == 0) _items = null; // Reiniciar a null solo en la carga inicial
    });

    final respuesta = await _servicioGaleria.obtenerGaleria(
      idComunidad: widget.comunidadId,
      idUsuario: widget.usuarioId,
      idColeccion: widget.coleccionId,
      limite: _limit,
      desplazamiento: _offset,
    );

    if (respuesta.exito && respuesta.datos != null && mounted) {
      setState(() {
        if (_items == null) {
          _items = respuesta.datos!;
        } else {
          _items!.addAll(respuesta.datos!);
        }
        _offset += _limit;
        if (respuesta.datos!.length < _limit) {
          _hayMas = false;
        }
      });
    } else if (mounted && _items == null) {
      // Si la carga inicial falla, inicializar como lista vacía para mostrar el estado correspondiente
      setState(() => _items = []);
    }
    if (!mounted) return;
    setState(() => _cargando = false);
  }

  Future<void> _seleccionarYSubir(bool esVideo, dynamic tr) async {
    final picker = ImagePicker();
    final pickedFile = esVideo 
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _subiendo = true);
      
      final res = await _servicioGaleria.subirImagenGaleria(
        pickedFile,
        idComunidad: widget.comunidadId,
      );

      if (res.exito && mounted) {
        // Si estamos en una colección, vincularla automáticamente
        final nuevaImagen = res.datos!;
        if (widget.coleccionId != null) {
          await _servicioGaleria.gestionarImagenEnColeccion(
            idColeccion: widget.coleccionId!, 
            idImagen: nuevaImagen.id, 
            agregar: true
          );
        }
        
        // Refrescar galería instantáneamente
        setState(() {
          _items ??= [];
          _items!.insert(0, nuevaImagen);
          _subiendo = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevaImagen.tipoArchivo == 'V' ? tr('galleryVideoAdded') : tr('galleryImageAdded'), style: GoogleFonts.outfit()), 
            backgroundColor: const Color(0xFF248EA6),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        if (!mounted) return;
        setState(() => _subiendo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        Widget contenido;
        
        if (_items == null && _cargando) {
          contenido = const Center(
            child: CircularProgressIndicator(color: Color(0xFF248EA6)),
          );
        } else if (_items == null || _items!.isEmpty) {
          contenido = EstadoVacioCargando(
            icon: Icons.photo_library_rounded,
            message: tr('galleryNoImages'),
          );
        } else {
          contenido = Padding(
            padding: const EdgeInsets.all(8.0),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                  if (!_cargando && _hayMas) {
                    _cargarMas();
                  }
                }
                return false;
              },
              child: MasonryGridView.builder(
                gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: _items!.length + (_hayMas ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _items!.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(color: Color(0xFF248EA6)),
                      ),
                    );
                  }

                  final item = _items![index];
                  final double aspect = item.relacionAspecto > 0 ? item.relacionAspecto : (index % 3 == 0 ? 0.7 : 1.2);

                  return _buildTile(item, aspect);
                },
              ),
            ),
          );
        }

        return Stack(
          children: [
            contenido,
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'fab_dual_masonry_${widget.coleccionId ?? widget.comunidadId ?? widget.usuarioId ?? 'gen'}_${identityHashCode(this)}',
                backgroundColor: _subiendo ? Colors.grey : const Color(0xFF248EA6),
                onPressed: (_subiendo || !widget.esMiembro) ? null : () => _mostrarMenuOpciones(context, tr),
                child: _subiendo 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(widget.esMiembro ? Icons.add : Icons.lock_outline_rounded, color: Colors.white, size: 28),
              ),
            ),
            if (_subiendo)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF248EA6)),
                ),
              ),
          ],
        );
      },
    );
  }

  void _mostrarMenuOpciones(BuildContext context, dynamic tr) {
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
              title: Text(widget.coleccionId != null ? tr('galleryUploadPhotoToFolder') : tr('galleryUploadRawPhoto'), 
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(widget.coleccionId != null ? tr('galleryUploadPhotoToFolderDesc') : tr('galleryUploadRawPhotoDesc'), 
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _seleccionarYSubir(false, tr);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFC35E34).withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFFC35E34)),
              ),
              title: Text(widget.coleccionId != null ? tr('galleryUploadVideoToFolder') : tr('galleryUploadRawVideo'), 
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(tr('galleryUploadVideoDesc'), 
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _seleccionarYSubir(true, tr);
              },
            ),
            const SizedBox(height: 12),
            if (widget.coleccionId != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF248EA6).withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF248EA6)),
                ),
                title: Text(tr('galleryAddFromGallery'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(tr('galleryAddFromGalleryDesc'), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirSelectorGaleriaMyngo(context, tr);
                },
              )
            else
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF248EA6).withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF248EA6)),
                ),
                title: Text(tr('galleryNewCollection'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(tr('galleryNewCollectionDesc'), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoNuevaColeccion(context, tr);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirSelectorGaleriaMyngo(BuildContext context, dynamic tr) async {
    final ImagenGaleria? seleccionada = await showModalBottomSheet<ImagenGaleria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DialogoSelectorImagen(),
    );

    if (seleccionada != null && widget.coleccionId != null) {
      final res = await _servicioGaleria.gestionarImagenEnColeccion(
        idColeccion: widget.coleccionId!, 
        idImagen: seleccionada.id, 
        agregar: true
      );

      if (res.exito && mounted) {
        setState(() {
          _items ??= <ImagenGaleria>[];
          _items!.insert(0, seleccionada);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('galleryAddedToCollectionMsg'), style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF248EA6)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoNuevaColeccion(BuildContext context, dynamic tr) {
    final nombreCtrl = TextEditingController();
    bool esPrivada = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(tr('galleryNewCollection'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: nombreCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: tr('galleryCollectionNameHint'),
                  hintStyle: GoogleFonts.outfit(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(esPrivada ? tr('commonPrivate') : tr('commonPublic'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(esPrivada ? tr('galleryCollectionPrivateDesc') : tr('galleryCollectionPublicDesc'), style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                value: esPrivada,
                activeColor: const Color(0xFF248EA6),
                onChanged: (val) => setModalState(() => esPrivada = val),
              ),
              const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty) return;
                    // Llamada al servicio
                    final res = await _servicioGaleria.crearColeccion(
                      nombre: nombreCtrl.text,
                      esPrivada: esPrivada,
                      idComunidad: widget.comunidadId,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.exito ? tr('galleryCollectionCreatedMsg') : res.mensaje),
                        backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(tr('commonCreate').toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTile(ImagenGaleria item, double aspect) {
    return GestureDetector(
      onTap: !widget.esMiembro ? null : () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => PantallaDetalleImagen(imagen: item)
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E1E),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Imagen con blur si no es miembro
            if (!widget.esMiembro)
              ImageFiltered(
                imageFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8), 
                  child: _buildInnerTileContent(item, aspect),
                ),
              )
            else
              _buildInnerTileContent(item, aspect),

            // Menu de opciones en la esquina superior derecha (Solo miembros)
            if (widget.esMiembro)
              Positioned(
                top: 2,
                right: 2,
                child: MenuOpcionesContenido(
                  tipoObjeto: 'IMAGEN',
                  objetoId: item.id,
                  autorId: item.propietarioId,
                  comunidadId: item.comunidadId,
                  creadorComunidadId: item.creadorComunidadId,
                  onEliminado: () {
                    setState(() {
                      _items?.remove(item);
                    });
                  },
                ),
              ),
            // Botón de descarga rápida (Solo miembros)
            if (widget.esMiembro)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(item.urlArchivo);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            
            // Candado central si no es miembro
            if (!widget.esMiembro)
              const Positioned.fill(
                child: Center(
                  child: Icon(Icons.lock_rounded, color: Colors.white, size: 32),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerTileContent(ImagenGaleria item, double aspect) {
    if (item.tipoArchivo == 'V') {
      return AspectRatio(
        aspectRatio: aspect,
        child: Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: item.urlArchivo,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          height: 150,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
