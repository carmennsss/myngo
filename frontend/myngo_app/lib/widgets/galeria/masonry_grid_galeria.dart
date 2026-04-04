import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/galeria/pantalla_detalle_imagen.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/galeria/dialogo_selector_imagen.dart';
import '../comunes/menu_opciones_contenido.dart';


class MasonryGridGaleria extends StatefulWidget {
  final int? comunidadId;
  final int? usuarioId;
  final int? coleccionId;

  const MasonryGridGaleria({Key? key, this.comunidadId, this.usuarioId, this.coleccionId}) : super(key: key);

  @override
  _MasonryGridGaleriaState createState() => _MasonryGridGaleriaState();
}

class _MasonryGridGaleriaState extends State<MasonryGridGaleria> {
  final _servicioGaleria = ServicioGaleria();
  final _scrollController = ScrollController();
  
  List<ImagenGaleria> _items = [];
  bool _cargando = false;
  bool _subiendo = false;
  bool _hayMas = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _cargarMas();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_cargando && _hayMas) {
        _cargarMas();
      }
    }
  }

  Future<void> _cargarMas() async {
    if (_cargando) return;
    setState(() => _cargando = true);

    final respuesta = await _servicioGaleria.obtenerGaleria(
      comunidadId: widget.comunidadId,
      usuarioId: widget.usuarioId,
      coleccionId: widget.coleccionId,
      limit: _limit,
      offset: _offset,
    );

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        _items.addAll(respuesta.datos!);
        _offset += _limit;
        if (respuesta.datos!.length < _limit) {
          _hayMas = false;
        }
      });
    }
    setState(() => _cargando = false);
  }

  Future<void> _subirImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _subiendo = true);
      
      final res = await _servicioGaleria.subirImagenGaleria(
        pickedFile,
        comunidadId: widget.comunidadId,
      );

      if (res.exito && mounted) {
        // Si estamos en una colección, vincularla automáticamente
        final nuevaImagen = res.datos!;
        if (widget.coleccionId != null) {
          await _servicioGaleria.gestionarImagenEnColeccion(
            coleccionId: widget.coleccionId!, 
            imagenId: nuevaImagen.id, 
            agregar: true
          );
        }
        
        // Refrescar galería instantáneamente
        setState(() {
          _items.insert(0, nuevaImagen);
          _subiendo = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Imagen añadida con éxito! 🐾', style: GoogleFonts.outfit()), 
            backgroundColor: const Color(0xFF248EA6),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        setState(() => _subiendo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    
    if (_items.isEmpty && !_cargando) {
      contenido = Center(
        child: Text(
          'Aún no hay fotos aquí 🐾',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
        ),
      );
    } else {
      contenido = Padding(
        padding: const EdgeInsets.all(8.0),
        child: MasonryGridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: _items.length + (_hayMas ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Color(0xFF248EA6)),
                ),
              );
            }

            final item = _items[index];
            final double aspect = item.relacionAspecto > 0 ? item.relacionAspecto : (index % 3 == 0 ? 0.7 : 1.2);

            return _buildTile(item, aspect);
          },
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
            heroTag: 'fab_dual_masonry_${widget.coleccionId ?? widget.comunidadId ?? 'gen'}',
            backgroundColor: _subiendo ? Colors.grey : const Color(0xFF248EA6),
            onPressed: _subiendo ? null : () => _mostrarMenuOpciones(context),
            child: _subiendo 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.add, color: Colors.white, size: 28),
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
              title: Text(widget.coleccionId != null ? 'Subir Foto a esta Carpeta' : 'Subir Imagen Cruda', 
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(widget.coleccionId != null ? 'Captura nueva que irá directo aquí' : 'Directo a tu galería local o de comunidad', 
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _subirImagen();
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
                title: Text('Añadir de mi Galería', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Reaprovecha una foto que ya subiste', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirSelectorGaleriaMyngo(context);
                },
              )
            else
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF248EA6).withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF248EA6)),
                ),
                title: Text('Nueva Colección', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Organiza de forma pública o privada tus capturas', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
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

  Future<void> _abrirSelectorGaleriaMyngo(BuildContext context) async {
    final ImagenGaleria? seleccionada = await showModalBottomSheet<ImagenGaleria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DialogoSelectorImagen(),
    );

    if (seleccionada != null && widget.coleccionId != null) {
      final res = await _servicioGaleria.gestionarImagenEnColeccion(
        coleccionId: widget.coleccionId!, 
        imagenId: seleccionada.id, 
        agregar: true
      );

      if (res.exito && mounted) {
        setState(() {
          _items.insert(0, seleccionada);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Añadida a la colección!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF248EA6)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoNuevaColeccion(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nueva Colección', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: nombreCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nombre de la colección',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(esPrivada ? 'Privada' : 'Pública', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(esPrivada ? 'Solo tú la verás' : 'Cualquiera podrá verla', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
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
                      comunidadId: widget.comunidadId,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.exito ? 'Colección creada' : res.mensaje),
                        backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text('CREAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(ImagenGaleria item, double aspect) {
    return GestureDetector(
      onTap: () {
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
            CachedNetworkImage(
              imageUrl: item.urlArchivo,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            ),
            // Menu de opciones en la esquina superior derecha
            Positioned(
              top: 4,
              right: 4,
              child: MenuOpcionesContenido(
                tipoObjeto: 'IMAGEN',
                objetoId: item.id,
                autorId: item.propietarioId,
                comunidadId: item.comunidadId,
                creadorComunidadId: item.creadorComunidadId,
                onEliminado: () {
                  setState(() {
                    _items.remove(item);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
