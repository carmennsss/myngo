import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/coleccion.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_usuarios.dart';

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
      coleccionId: _coleccion.id,
      limit: 30,
      offset: _offset,
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

  Future<void> _quitarImagen(ImagenGaleria imagen) async {
    setState(() => _procesando = true);
    final res = await _servicio.gestionarImagenEnColeccion(
      coleccionId: _coleccion.id,
      imagenId: imagen.id,
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
            res.exito ? 'Imagen quitada de la colección 🐾' : res.mensaje,
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarColeccion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar colección?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Se borrará "${_coleccion.nombreColeccion}" y todo su contenido (las imágenes no se eliminan, solo se desvinculan).',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _procesando = true);
    final res = await _servicio.eliminarColeccion(coleccionId: _coleccion.id);
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

  void _mostrarMenuImagen(BuildContext context, ImagenGaleria imagen) {
    if (!_puedeEditar) return; // Sin permiso: no mostrar menú
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.orangeAccent),
              title: Text(
                'Quitar de esta colección',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _quitarImagen(imagen);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _coleccion.nombreColeccion.toUpperCase(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_coleccion.descripcion != null && _coleccion.descripcion!.isNotEmpty)
              Text(
                _coleccion.descripcion!,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          Icon(
            _coleccion.esPrivada ? Icons.lock_rounded : Icons.public_rounded,
            color: _coleccion.esPrivada ? const Color(0xFFD95F43) : const Color(0xFF248EA6),
          ),
          const SizedBox(width: 8),
          // Menú de opciones: solo visible si el usuario tiene permiso
          if (_puedeEditar)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'eliminar') _confirmarEliminarColeccion();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Eliminar colección',
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF248EA6)))
          : _imagenes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Esta colección está vacía',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Añade imágenes desde la galería de inicio',
                        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
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
                              child: CircularProgressIndicator(color: Color(0xFF248EA6), strokeWidth: 2),
                            ),
                          );
                        }
                        final imagen = _imagenes[index];
                        return GestureDetector(
                          onLongPress: _puedeEditar ? () => _mostrarMenuImagen(context, imagen) : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imagen.urlArchivo,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: const Color(0xFF2A2A2A)),
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFF1E1E1E),
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                ),
                              ),
                              // Indicador de menú solo si puede editar
                              if (_puedeEditar)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _mostrarMenuImagen(context, imagen),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 16),
                                    ),
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
                          child: CircularProgressIndicator(color: Color(0xFF248EA6)),
                        ),
                      ),
                  ],
                ),
    );
  }
}
