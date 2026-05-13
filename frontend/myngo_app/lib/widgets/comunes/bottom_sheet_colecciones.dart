import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/coleccion.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_interaccion.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class BottomSheetColecciones extends StatefulWidget {
  final int? imagenId;
  final String? imagenUrl;
  final int? postId;
  final bool? estaGuardadoPost;

  const BottomSheetColecciones({
    super.key, 
    this.imagenId, 
    this.imagenUrl,
    this.postId,
    this.estaGuardadoPost,
  });

  @override
  State<BottomSheetColecciones> createState() => _BottomSheetColeccionesState();
}

class _BottomSheetColeccionesState extends State<BottomSheetColecciones> {
  final _servicioGaleria = ServicioGaleria();
  final _servicioComunidades = ServicioComunidades();
  List<Coleccion> _colecciones = [];
  bool _cargando = true;
  bool _guardando = false;
  bool _estaGuardadoPostLocal = false;

  @override
  void initState() {
    super.initState();
    _estaGuardadoPostLocal = widget.estaGuardadoPost ?? false;
    _cargarColecciones();
  }

  Future<void> _cargarColecciones() async {
    final res = await _servicioGaleria.obtenerColecciones();
    if (mounted) setState(() { _colecciones = res.datos ?? []; _cargando = false; });
  }

  Future<void> _agregarAColeccion(Coleccion coleccion) async {
    if (widget.imagenId == null) return;
    setState(() => _guardando = true);
    final res = await _servicioGaleria.gestionarImagenEnColeccion(idColeccion: coleccion.id, idImagen: widget.imagenId!, agregar: true);
    if (mounted) {
      setState(() => _guardando = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.exito ? tr('collectionSavedIn', {'name': coleccion.nombreColeccion}) : res.mensaje, style: GoogleFonts.outfit()),
        backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _toggleGuardarPost() async {
    if (widget.postId == null) return;
    setState(() => _guardando = true);
    final res = await ServicioInteraccion().alternarGuardado(widget.postId!);
    if (mounted) {
      if (res.exito) {
        setState(() {
          _estaGuardadoPostLocal = res.datos == 'added';
          _guardando = false;
        });
        Navigator.pop(context); // Cerramos tras la acción principal
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.mensaje, style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF248EA6),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.mensaje),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _mostrarCrearColeccion(BuildContext context, String Function(String, [Map<String, Object>?]) tr) {
    final ctrl = TextEditingController();
    bool esPrivada = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('collectionNew'), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: tr('collectionNameHint'),
                  hintStyle: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(esPrivada ? tr('commonPrivate') : tr('commonPublic'), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                value: esPrivada,
                activeColor: const Color(0xFF248EA6),
                onChanged: (v) => setDlg(() => esPrivada = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('commonCancel'), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                final res = await _servicioGaleria.crearColeccion(nombre: ctrl.text.trim(), esPrivada: esPrivada);
                if (res.exito && res.datos != null && mounted) {
                  Navigator.pop(ctx);
                  await _agregarAColeccion(res.datos!);
                } else if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje, style: GoogleFonts.outfit()), backgroundColor: Colors.red));
                }
              },
              child: Text(tr('collectionCreateAndSave'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 48, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, color: Color(0xFFF28B50), size: 22),
                    const SizedBox(width: 12),
                    Text(tr('postSaveTitle'), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54))),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
              const SizedBox(height: 8),
              if (_guardando)
                const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF248EA6)))
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // --- OPCIÓN DE GUARDAR EN PERFIL ---
                      if (widget.postId != null)
                        _ColeccionTile(
                          icono: _estaGuardadoPostLocal ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                          nombre: _estaGuardadoPostLocal ? tr('postRemoveFromProfile') : tr('postSaveToProfile'), 
                          subtitulo: _estaGuardadoPostLocal ? tr('postAlreadySaved') : tr('postAddToSaved'), 
                          iconColor: const Color(0xFFF28B50), 
                          onTap: _toggleGuardarPost
                        ),
                      
                      const SizedBox(height: 8),
                      Divider(color: Theme.of(context).colorScheme.outlineVariant, indent: 16, endIndent: 16),
                      const SizedBox(height: 8),

                      // --- OPCIONES DE COLECCIONES DE IMAGEN ---
                      if (widget.imagenId != null) ...[
                        _ColeccionTile(icono: Icons.create_new_folder_rounded, nombre: tr('collectionNewFolder'), subtitulo: tr('collectionNewFolderSub'), iconColor: const Color(0xFF248EA6), onTap: () => _mostrarCrearColeccion(context, tr)),
                        if (_cargando)
                          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Color(0xFF248EA6), strokeWidth: 2)))
                        else if (_colecciones.isEmpty)
                          Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(tr('collectionNoCollections'), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 14))))
                        else
                          ..._colecciones.map((col) => _ColeccionTile(
                            icono: col.esPrivada ? Icons.lock_outline_rounded : Icons.folder_rounded,
                            nombre: col.nombreColeccion,
                            subtitulo: tr('collectionImageCount', {'count': col.numeroImagenes, 'plural': col.numeroImagenes == 1 ? '' : 'es'}),
                            iconColor: const Color(0xFF248EA6),
                            onTap: () => _agregarAColeccion(col),
                          )),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icono, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitulo, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
          ],
        ),
      ),
    );
  }
}
