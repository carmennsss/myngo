import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/publicacion.dart';
import '../../models/comunidad.dart';
import '../../models/coleccion.dart';
import '../../models/usuario.dart';
import '../../services/servicio_galeria.dart';
import 'dialogo_detalle_post.dart';

/// Tarjeta de publicación del feed de inicio con botón de añadir a colección.
class TarjetaPost extends StatefulWidget {
  final Publicacion post;
  final VoidCallback onJoin;
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;

  const TarjetaPost({super.key, required this.post, required this.onJoin, this.onComunidadSelected, this.onProfileSelected});

  @override
  State<TarjetaPost> createState() => _TarjetaPostState();
}

class _TarjetaPostState extends State<TarjetaPost> {
  bool _estaLogueado = false;
  bool _imagenFallo = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _estaLogueado = prefs.getString('auth_token') != null);
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DialogoDetallePublicacion(
        post: widget.post, 
        onComunidadSelected: widget.onComunidadSelected,
        onProfileSelected: widget.onProfileSelected,
      ),
    );
  }

  void _mostrarMenuColecciones(BuildContext context) {
    if (!_estaLogueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inicia sesión para guardar en colecciones 🐾', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFC35E34),
          action: SnackBarAction(label: 'ENTRAR', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/login')),
        ),
      );
      return;
    }

    if (widget.post.imagenId == null || widget.post.urlImagen == null || widget.post.urlImagen!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Esta publicación no tiene imagen para guardar', style: GoogleFonts.outfit()), backgroundColor: Colors.grey.shade700),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetColecciones(imagenId: widget.post.imagenId!, imagenUrl: widget.post.urlImagen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                    child: Text(widget.post.comunidadNombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.comunidadNombre, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('Senderismo y Aventura', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.post.urlImagen != null && !_imagenFallo)
              GestureDetector(
                onTap: () => _mostrarDetalles(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: CachedNetworkImage(
                          imageUrl: widget.post.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFFFEF5F1)),
                          errorWidget: (_, __, ___) {
                            // Colapsar el hueco: eliminar el bloque de imagen completo
                            Future.microtask(() {
                              if (mounted) setState(() => _imagenFallo = true);
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => _mostrarMenuColecciones(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFFC35E34)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.titulo, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
                  if (widget.post.contenidoTexto.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.post.contenidoTexto, style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: const Color(0xFFC35E34).withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(widget.post.likesCount.toString(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(widget.post.comentariosCount.toString(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// BOTTOM SHEET: Selector de colección para guardar imagen
// ------------------------------------------------------------------

class BottomSheetColecciones extends StatefulWidget {
  final int imagenId;
  final String? imagenUrl;

  const BottomSheetColecciones({super.key, required this.imagenId, this.imagenUrl});

  @override
  State<BottomSheetColecciones> createState() => _BottomSheetColeccionesState();
}

class _BottomSheetColeccionesState extends State<BottomSheetColecciones> {
  final _servicio = ServicioGaleria();
  List<Coleccion> _colecciones = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarColecciones();
  }

  Future<void> _cargarColecciones() async {
    final res = await _servicio.obtenerColecciones();
    if (mounted) setState(() { _colecciones = res.datos ?? []; _cargando = false; });
  }

  Future<void> _agregarAColeccion(Coleccion coleccion) async {
    setState(() => _guardando = true);
    final res = await _servicio.gestionarImagenEnColeccion(coleccionId: coleccion.id, imagenId: widget.imagenId, agregar: true);
    if (mounted) {
      setState(() => _guardando = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.exito ? '¡Guardado en "${coleccion.nombreColeccion}"! 🐾' : res.mensaje, style: GoogleFonts.outfit()),
        backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _mostrarCrearColeccion(BuildContext context) {
    final ctrl = TextEditingController();
    bool esPrivada = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Nueva Colección', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nombre de la colección',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(esPrivada ? 'Privada' : 'Pública', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                value: esPrivada,
                activeColor: const Color(0xFF248EA6),
                onChanged: (v) => setDlg(() => esPrivada = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                final res = await _servicio.crearColeccion(nombre: ctrl.text.trim(), esPrivada: esPrivada);
                if (res.exito && res.datos != null && mounted) {
                  Navigator.pop(ctx);
                  await _agregarAColeccion(res.datos!);
                } else if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red));
                }
              },
              child: Text('CREAR Y GUARDAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.collections_bookmark_rounded, color: Color(0xFFF28B50), size: 22),
                const SizedBox(width: 12),
                Text('Guardar en colección', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white54)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          if (_guardando)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF248EA6)))
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _ColeccionTile(icono: Icons.create_new_folder_rounded, nombre: 'Nueva colección', subtitulo: 'Crea una carpeta nueva', iconColor: const Color(0xFFF28B50), onTap: () => _mostrarCrearColeccion(context)),
                  if (_cargando)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Color(0xFF248EA6), strokeWidth: 2)))
                  else if (_colecciones.isEmpty)
                    Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Aún no tienes colecciones', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14))))
                  else
                    ..._colecciones.map((col) => _ColeccionTile(
                      icono: col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_rounded,
                      nombre: col.nombreColeccion,
                      subtitulo: '${col.numeroImagenes} imagen${col.numeroImagenes == 1 ? '' : 'es'}',
                      iconColor: const Color(0xFF248EA6),
                      onTap: () => _agregarAColeccion(col),
                    )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ColeccionTile extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final String subtitulo;
  final Color iconColor;
  final VoidCallback onTap;

  const _ColeccionTile({required this.icono, required this.nombre, required this.subtitulo, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icono, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitulo, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
