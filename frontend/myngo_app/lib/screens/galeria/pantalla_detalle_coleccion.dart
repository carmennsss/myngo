import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/coleccion.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/publicacion.dart';
import 'package:image_picker/image_picker.dart';
import 'pantalla_detalle_imagen.dart';
import '../../utils/gestor_descargas.dart';
import 'package:myngo_app/widgets/comunes/miniatura_video.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class PantallaDetalleColeccion extends StatefulWidget {
  final Coleccion coleccion;
  /// Para colecciones de comunidad el padre indica si el usuario tiene rol de gestor.
  /// Para colecciones de perfil se ignora este paramámetro (se compara con el userId local).
  final bool puedeEditarComunidad;

  const PantallaDetalleColeccion({
    Key? key,
    required this.coleccion,
    this.puedeEditarComunidad = false,
  }) : super(key: key);

  @override
  State<PantallaDetalleColeccion> createState() => _PantallaDetalleColeccionState();
}

class _PantallaDetalleColeccionState extends State<PantallaDetalleColeccion> {
  final _servicio = ServicioGaleria();
  List<ImagenGaleria> _imagenes = [];
  bool _cargando = true;
  bool _procesando = false;
  late Coleccion _coleccion;
  int _offset = 0;
  bool _hayMas = true;
  bool _puedeEditar = false;

  @override
  void initState() {
    super.initState();
    _coleccion = widget.coleccion;
    _cargarImagenes();
    _determinarPermiso();
  }

  Future<void> _determinarPermiso() async {
    if (_coleccion.comunidadId != null) {
      // Colección de comunidad: el padre ya sabe el rol
      if (mounted) setState(() => _puedeEditar = widget.puedeEditarComunidad);
    } else {
      // Colección de perfil: solo el dueño puede editar
      final miId = await ServicioUsuarios().obtenerIdUsuario();
      if (mounted) setState(() => _puedeEditar = miId != null && miId == _coleccion.usuarioId);
    }
  }

  Future<void> _cargarImagenes() async {
    if (_cargando && _offset > 0) return;
    setState(() => _cargando = true);
    final res = await _servicio.obtenerGaleria(
      idColeccion: _coleccion.id,
      limite: 30,
      desplazamiento: _offset,
    );
    if (mounted) {
      setState(() {
        if (res.exito && res.datos != null) {
          if (_offset == 0) _imagenes = res.datos!;
          else _imagenes.addAll(res.datos!);
          _hayMas = res.datos!.length >= 30;
          _offset += res.datos!.length;
        }
        _cargando = false;
      });
    }
  }

  Future<void> _quitarImagen(ImagenGaleria imagen, dynamic tr) async {
    setState(() => _procesando = true);
    final res = await _servicio.gestionarImagenEnColeccion(
      idColeccion: _coleccion.id,
      idImagen: imagen.id,
      agregar: false,
    );
    if (mounted) {
      setState(() {
        _procesando = false;
        if (res.exito) {
          _imagenes.removeWhere((i) => i.id == imagen.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.exito ? tr('collectionImageRemoved') : res.mensaje,
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cambiarPrivacidad() async {
    if (!_puedeEditar) return;
    setState(() => _procesando = true);
    final nuevaPrivacidad = !_coleccion.esPrivada;
    final res = await _servicio.editarColeccion(
      _coleccion.id,
      {'es_privada': nuevaPrivacidad},
    );
    if (mounted) {
      setState(() {
        _procesando = false;
        if (res.exito) {
          _coleccion.esPrivada = nuevaPrivacidad;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.exito ? tr('collectionPrivacyUpdated') : res.mensaje),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
        ),
      );
    }
  }

  Future<void> _editarNombre() async {
    final controller = TextEditingController(text: _coleccion.nombreColeccion);
    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('collectionRenameTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: tr('collectionRenameHint')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('commonCancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC35E34)),
            child: Text(tr('commonSave'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (nuevoNombre != null && nuevoNombre.isNotEmpty && nuevoNombre != _coleccion.nombreColeccion) {
      setState(() => _procesando = true);
      final res = await _servicio.editarColeccion(
        _coleccion.id,
        {'nombre_coleccion': nuevoNombre},
      );
      if (mounted) {
        setState(() {
          _procesando = false;
          if (res.exito) {
            _coleccion.nombreColeccion = nuevoNombre;
          }
        });
      }
    }
  }

  Future<void> _confirmarEliminarColeccion(dynamic tr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          tr('collectionDeleteWarning'),
          style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900),
        ),
        content: Text(
          tr('collectionDeleteBody', {'name': _coleccion.nombreColeccion}),
          style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('commonCancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('commonDelete'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _procesando = true);
    final res = await _servicio.eliminarColeccion(idColeccion: _coleccion.id);
    if (mounted) {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje, style: GoogleFonts.outfit()),
          backgroundColor: res.exito ? Colors.green.shade700 : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (res.exito) Navigator.pop(context, true); // devuelve true para que la galería refresque
    }
  }

  Future<void> _subirDesdeGaleria(dynamic tr) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _procesando = true);
    
    // Subir a la galería general de la comunidad (o perfil)
    final resSubida = await _servicio.subirImagenGaleria(
      image,
      idComunidad: _coleccion.comunidadId,
      esPublica: !_coleccion.esPrivada,
    );

    if (mounted) {
      if (resSubida.exito && resSubida.datos != null) {
        // Vincular a esta colección específica
        final resVinculo = await _servicio.gestionarImagenEnColeccion(
          idColeccion: _coleccion.id,
          idImagen: resSubida.datos!.id,
          agregar: true,
        );
        
        if (mounted) {
          setState(() {
            _procesando = false;
            if (resVinculo.exito) {
              _imagenes.insert(0, resSubida.datos!);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resVinculo.mensaje, style: GoogleFonts.outfit()),
              backgroundColor: resVinculo.exito ? const Color(0xFF248EA6) : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resSubida.mensaje, style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _elegirDePostsComunidad(dynamic tr) async {
    if (_coleccion.comunidadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('collectionCommunityOnly'), style: GoogleFonts.outfit())),
      );
      return;
    }

    // Mostrar diálogo de selección
    final imagenId = await showDialog<int>(
      context: context,
      builder: (ctx) => _DialogoSelectorImagenPost(comunidadId: _coleccion.comunidadId!),
    );

    if (imagenId != null && mounted) {
      setState(() => _procesando = true);
      final res = await _servicio.gestionarImagenEnColeccion(
        idColeccion: _coleccion.id,
        idImagen: imagenId,
        agregar: true,
      );
      
      if (mounted) {
        setState(() => _procesando = false);
        if (res.exito) {
          _offset = 0; // Reiniciar para ver la nueva imagen
          _cargarImagenes();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.mensaje, style: GoogleFonts.outfit()),
            backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarSelectorOrigenImagen(dynamic tr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            shrinkWrap: true,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Center(child: Text(tr('collectionAddTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440)))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF248EA6)),
                title: Text(tr('collectionUploadLocal'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _subirDesdeGaleria(tr);
                },
              ),
              if (_coleccion.comunidadId != null)
                ListTile(
                  leading: const Icon(Icons.feed_rounded, color: Color(0xFFC35E34)),
                  title: Text(tr('collectionChooseFromPosts'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _elegirDePostsComunidad(tr);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMenuImagen(BuildContext context, ImagenGaleria imagen, dynamic tr) {
    if (!_puedeEditar) return; // Sin permiso: no mostrar menú
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Color(0xFF248EA6)),
                title: Text(
                  tr('collectionDownloadFile'),
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await GestorDescargas.descargar(imagen.urlArchivo);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('moderationError'))),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.orangeAccent),
                title: Text(
                  tr('collectionRemoveFromCollection'),
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _quitarImagen(imagen, tr);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrWidget(
      builder: (context, tr) => Scaffold(
        backgroundColor: const Color(0xFFFEF5F1),
        floatingActionButton: _puedeEditar ? FloatingActionButton(
          heroTag: 'fab_detalle_col_${_coleccion.id}',
          onPressed: () => _mostrarSelectorOrigenImagen(tr),
          backgroundColor: const Color(0xFFC35E34),
          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        ) : null,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
          title: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _coleccion.nombreColeccion.toUpperCase(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF4A4440)),
                    ),
                    if (_coleccion.descripcion != null && _coleccion.descripcion!.isNotEmpty)
                      Text(
                        _coleccion.descripcion!,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                ],
              ),
            ),
            if (_puedeEditar)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                onPressed: _editarNombre,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFEF5F1),
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            GestureDetector(
            onTap: _puedeEditar ? _cambiarPrivacidad : null,
            child: MouseRegion(
              cursor: _puedeEditar ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: Tooltip(
                message: _puedeEditar ? tr('collectionTapToChangePrivacy') : (_coleccion.esPrivada ? tr('collectionPrivateLabel') : tr('collectionPublicLabel')),
                child: Icon(
                    _coleccion.esPrivada ? Icons.lock_rounded : Icons.public_rounded,
                    color: _coleccion.esPrivada ? const Color(0xFFC35E34) : const Color(0xFF248EA6),
                  ),
              ),
            ),
          ),
            const SizedBox(width: 8),
            // Menú de opciones: solo visible si el usuario tiene permiso
            if (_puedeEditar)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A4440)),
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'eliminar') _confirmarEliminarColeccion(tr);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          tr('collectionDeleteWarning').split('?')[0],
                          style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _cargando && _imagenes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
            : _imagenes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, color: Colors.grey.withOpacity(0.2), size: 64),
                        const SizedBox(height: 16),
                        Text(
                          tr('collectionEmpty'),
                          style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('collectionAddHint'),
                          style: GoogleFonts.outfit(color: Colors.grey.shade300, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _imagenes.length + (_hayMas ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _imagenes.length) {
                            _cargarImagenes();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 2),
                              ),
                            );
                          }
                          final imagen = _imagenes[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaDetalleImagen(imagen: imagen),
                                ),
                              );
                            },
                            onLongPress: _puedeEditar ? () => _mostrarMenuImagen(context, imagen, tr) : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imagen.tipoArchivo == 'V'
                                      ? MiniaturaVideo(url: imagen.urlArchivo)
                                      : CachedNetworkImage(
                                          imageUrl: imagen.urlArchivo,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: Colors.white),
                                          errorWidget: (_, __, ___) => Container(
                                            color: Colors.white,
                                            child: const Icon(Icons.broken_image_outlined, 
                                                color: Colors.grey),
                                          ),
                                        ),
                                ),
                                // Indicador de menú solo si puede editar
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await GestorDescargas.descargar(imagen.urlArchivo);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(tr('moderationError'))),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.download_rounded, 
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (_puedeEditar)
                                        GestureDetector(
                                          onTap: () => _mostrarMenuImagen(context, imagen, tr),
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.more_vert_rounded, 
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (_procesando)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFC35E34)),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

// --- DIÁLOGO PARA SELECCIONAR IMAGEN DE UN POST ---
class _DialogoSelectorImagenPost extends StatefulWidget {
  final int comunidadId;
  const _DialogoSelectorImagenPost({required this.comunidadId});

  @override
  State<_DialogoSelectorImagenPost> createState() => _DialogoSelectorImagenPostState();
}

class _DialogoSelectorImagenPostState extends State<_DialogoSelectorImagenPost> {
  final _servicioComunidades = ServicioComunidades();
  List<Publicacion> _posts = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPosts();
  }

  Future<void> _cargarPosts() async {
    final res = await _servicioComunidades.obtenerPublicacionesComunidad(widget.comunidadId);
    if (mounted) {
      setState(() {
        // Filtrar solo posts que tengan al menos una imagen con ID
        _posts = (res.datos ?? []).where((p) => p.imagenesIds.isNotEmpty || p.imagenId != null).toList();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(tr('collectionChooseFromPosts'), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
      content: SizedBox(
        width: 400,
        height: 500,
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
            : _posts.isEmpty
                ? Center(child: Text(tr('collectionNoPostsWithImages'), textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (ctx, index) {
                      final post = _posts[index];
                      // Recopilar todas las imágenes del post
                      final List<Map<String, dynamic>> imagenes = [];
                      if (post.imagenId != null && post.urlImagen != null) {
                        imagenes.add({'id': post.imagenId, 'url': post.urlImagen});
                      }
                      for (int i = 0; i < post.imagenesIds.length; i++) {
                        if (i < post.urlsImagenes.length) {
                          imagenes.add({'id': post.imagenesIds[i], 'url': post.urlsImagenes[i]});
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(post.titulo.isEmpty ? tr('collectionPostBy', {'name': post.autorNombre}) : post.titulo, 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700)),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: imagenes.length,
                            itemBuilder: (context, i) {
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, imagenes[i]['id']),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: imagenes[i]['url'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 24),
                        ],
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('commonCancel'), style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      ],
    );
  }
}
