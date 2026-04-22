import 'package:flutter/material.dart';
import '../../widgets/galeria/masonry_grid_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/coleccion.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pantalla_detalle_coleccion.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';

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

  Future<void> _cargarColecciones() async {
    setState(() => _cargandoColecciones = true);
    final respuesta = await _servicioGaleria.obtenerColecciones(
      comunidadId: widget.comunidadId,
      usuarioId: widget.usuarioId,
    );
    if (respuesta.exito && respuesta.datos != null) {
      setState(() => _colecciones = respuesta.datos!);
    }
    setState(() => _cargandoColecciones = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.titulo.toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF248EA6),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'GALERÍA'),
            Tab(text: 'COLECCIONES'),
          ],
        ),
        actions: [
          if (_puedeCrearColeccion)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF248EA6)),
              onPressed: () {
                // TODO: Subir foto directamente a la galería
              },
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
          _buildColeccionesTab(),
        ],
      ),
      floatingActionButton: _puedeCrearColeccion
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF248EA6),
              child: const Icon(Icons.create_new_folder_outlined, color: Colors.white),
              onPressed: () => _mostrarDialogoCrearColeccion(),
            )
          : null,
    );
  }

  Widget _buildColeccionesTab() {
    if (_cargandoColecciones && _colecciones.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF248EA6)));
    }

    if (_colecciones.isEmpty) {
      return const EstadoVacioCargando(
        icon: Icons.folder_open_outlined,
        message: 'No hay colecciones creadas',
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
          return _buildCarpetaColeccion(coleccion);
        },
      ),
    );
  }

  Widget _buildCarpetaColeccion(Coleccion coleccion) {
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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              coleccion.esPrivada ? Icons.lock_outline : Icons.folder_rounded,
              color: const Color(0xFFF28B50),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              coleccion.nombreColeccion,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${coleccion.numeroImagenes} recursos',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCrearColeccion() {
    final TextEditingController _nombreCtrl = TextEditingController();
    bool _privada = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Nueva Colección', style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre de la carpeta',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('¿Privada?', style: GoogleFonts.outfit(color: Colors.white70)),
                value: _privada,
                activeColor: const Color(0xFF248EA6),
                onChanged: (v) => setDialogState(() => _privada = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF248EA6)),
              onPressed: () async {
                if (_nombreCtrl.text.isNotEmpty) {
                  final resp = await _servicioGaleria.crearColeccion(
                    nombre: _nombreCtrl.text,
                    esPrivada: _privada,
                    comunidadId: widget.comunidadId,
                  );
                  if (resp.exito) {
                    Navigator.pop(context);
                    _cargarColecciones();
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
