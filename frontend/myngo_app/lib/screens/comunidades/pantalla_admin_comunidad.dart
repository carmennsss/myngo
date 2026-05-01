import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myngo_app/utils/extensiones_color.dart';
import 'package:myngo_app/models/comunidad.dart';
import 'package:myngo_app/services/servicio_moderacion.dart';
import 'package:myngo_app/services/servicio_comunidades.dart';
import 'package:myngo_app/services/servicio_galeria.dart';
import 'package:myngo_app/screens/comunidades/pantalla_detalle_publicacion.dart';
import 'package:myngo_app/screens/galeria/pantalla_detalle_imagen.dart';
import 'package:myngo_app/models/imagen_galeria.dart';
import 'package:myngo_app/models/publicacion.dart';
import 'pantalla_moderacion_tienda.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';

class PantallaAdminComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int initialTab;
  const PantallaAdminComunidad({super.key, required this.comunidad, this.initialTab = 0});

  @override
  State<PantallaAdminComunidad> createState() => _PantallaAdminComunidadState();
}

class _PantallaAdminComunidadState extends State<PantallaAdminComunidad> with SingleTickerProviderStateMixin {
  final _servicioModeracion = ServicioModeracion();
  final _servicioComunidades = ServicioComunidades();
  final _servicioGaleria = ServicioGaleria();
  TabController? _tabController;
  Map<String, dynamic>? _datos;
  bool _cargando = true;

  // Controladores para Ajustes
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  String? _colorSeleccionado;
  XFile? _nuevoBanner;
  bool _tiendaHabilitada = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    _nombreCtrl = TextEditingController(text: widget.comunidad.nombre);
    _descCtrl = TextEditingController(text: widget.comunidad.descripcion);
    _colorSeleccionado = widget.comunidad.colorTema.toHex();
    _tiendaHabilitada = widget.comunidad.tiendaHabilitada;
    _cargarDatos();
  }

  Future<void> _cargarDatos({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    final res = await _servicioComunidades.obtenerDashboardAdmin(widget.comunidad.id);
    if (res.exito && mounted) {
      setState(() {
        _datos = res.datos;
        _cargando = false;
      });
    } else if (mounted) {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Gestión: ${widget.comunidad.nombre}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelColor: Colors.grey.shade400,
          labelColor: const Color(0xFFC35E34),
          indicatorColor: const Color(0xFFC35E34),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Solicitudes', icon: Icon(Icons.person_add_rounded)),
            Tab(text: 'Miembros', icon: Icon(Icons.people_rounded)),
            Tab(text: 'Reportes', icon: Icon(Icons.gavel_rounded)),
            Tab(text: 'Tienda', icon: Icon(Icons.shopping_bag_rounded)),
            Tab(text: 'Ajustes', icon: Icon(Icons.settings_rounded)),
          ],
        ),
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildSolicitudesTab(),
              _buildMiembrosTab(),
              _buildReportesTab(),
              PantallaModeracionTienda(comunidad: widget.comunidad),
              _buildAjustesTab(),
            ],
          ),
    );
  }

  Widget _buildSolicitudesTab() {
    final dynamic rawSolicitudes = _datos != null ? _datos!['solicitudes_pendientes'] : null;
    final List solicitudes = (rawSolicitudes is List) ? rawSolicitudes : [];
    
    if (solicitudes.isEmpty) return _buildEmptyState(Icons.person_search_rounded, 'No hay michis esperando');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        final sol = solicitudes[index];
        return _TarjetaGestion(
          nombre: sol['usuario_nombre'],
          subtitulo: 'Pidió unirse el ${sol['fecha'].toString().split('T')[0]}',
          avatarUrl: sol['usuario_avatar'],
          acciones: [
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF248EA6), size: 28), 
              onPressed: () => _responderPeticion(sol['id'], true)
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Color(0xFFD95F43), size: 28), 
              onPressed: () => _responderPeticion(sol['id'], false)
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiembrosTab() {
    final dynamic rawMiembros = _datos != null ? _datos!['miembros'] : null;
    final List miembros = (rawMiembros is List) ? rawMiembros : [];
    
    if (miembros.isEmpty) return _buildEmptyState(Icons.people_outline, 'No hay miembros? Qué raro');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: miembros.length,
      itemBuilder: (context, index) {
        final m = miembros[index];
        final bool esAdmin = m['rol'] == 'Administrador';
        
        return _TarjetaGestion(
          nombre: m['usuario_nombre'],
          subtitulo: 'Rol: ${m['rol']}',
          avatarUrl: m['usuario_avatar'],
          acciones: esAdmin ? [
             const Icon(Icons.stars_rounded, color: Colors.amber, size: 24)
          ] : [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade600),
              surfaceTintColor: Colors.white,
              color: Colors.white,
              onSelected: (rol) => _cambiarRol(m['id'], rol),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Moderador', child: Text('🛡️ Hacer Moderador')),
                const PopupMenuItem(value: 'Miembro', child: Text('🐾 Hacer Miembro')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'Expulsar', child: Text('🚫 Expulsar', style: TextStyle(color: Color(0xFFD95F43)))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportesTab() {
    final dynamic rawReportes = _datos != null ? _datos!['reportes_activos'] : null;
    final List reportes = (rawReportes is List) ? rawReportes : [];
    
    if (reportes.isEmpty) return _buildEmptyState(Icons.verified_user_rounded, 'Todo en orden por aquí ✨');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        final rep = reportes[index];
        return Card(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFD95F43).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(rep['tipo_objeto'] ?? 'CONTENIDO', style: const TextStyle(color: Color(0xFFD95F43), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                    const Spacer(),
                    Text('Por ${rep['informador_nombre']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(rep['motivo'] ?? 'Sin motivo', style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.bold, fontSize: 18)),
                if (rep['comentario'] != null) Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(rep['comentario'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _resolverReporte(rep['id'], 'DESESTIMADO'), 
                      style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                      child: const Text('IGNORAR')
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD95F43),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      onPressed: () => _mostrarDialogoBorrado(rep['objeto_id'], rep['tipo_objeto'], rep['id']),
                      label: const Text('BORRAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPERS ---

  Future<void> _responderPeticion(int id, bool aceptar) async {
    final res = await _servicioComunidades.responderPeticionAcceso(id, aceptar);
    if (res.exito) {
      _cargarDatos(silencioso: true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.mensaje, style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF248EA6),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _cambiarRol(int miembroId, String rol) async {
    if (rol == 'Expulsar') return; 
    final res = await _servicioComunidades.gestionarRolMiembro(miembroId, rol);
    if (res.exito) {
      _cargarDatos(silencioso: true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Rol actualizado con éxito! 🐾', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF248EA6),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _resolverReporte(int id, String estado) async {
    final res = await _servicioModeracion.resolverReporte(id, estado);
    if (res.exito) _cargarDatos(silencioso: true);
  }

  void _mostrarDialogoBorrado(int id, String tipo, int reporteId) {
    final razonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Moderar Contenido', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
        content: TextField(
          controller: razonCtrl,
          decoration: InputDecoration(
            hintText: 'Motivo del borrado...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD95F43),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () {
              Navigator.pop(context);
              _moderarContenido(id, tipo, reporteId, razonCtrl.text);
            },
            child: const Text('Borrar Contenido'),
          ),
        ],
      ),
    );
  }

  Future<void> _moderarContenido(int id, String tipo, int reporteId, String razon) async {
    dynamic resBorrado;
    if (tipo == 'POST') resBorrado = await _servicioComunidades.eliminarPublicacionModeracion(id, razon: razon);
    else if (tipo == 'IMAGEN') resBorrado = await _servicioGaleria.eliminarImagen(id, razon: razon);
    else if (tipo == 'COMENTARIO') resBorrado = await _servicioComunidades.eliminarComentarioModeracion(id, razon: razon);

    if (resBorrado?.exito == true) {
       _cargarDatos(silencioso: true);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Contenido eliminado con éxito', style: GoogleFonts.outfit()),
         backgroundColor: const Color(0xFF248EA6),
         behavior: SnackBarBehavior.floating,
       ));
    }
  }

  Widget _buildAjustesTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSeccionHeader('Identidad Visual'),
        const SizedBox(height: 16),
        _buildConfigItem(
          icon: Icons.palette_rounded,
          title: 'Color del Tema',
          subtitle: 'Personaliza el color principal de tu comunidad',
          trailing: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _colorSeleccionado != null ? Color(int.parse(_colorSeleccionado!.replaceFirst('#', '0xFF'))) : widget.comunidad.colorTema,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
            ),
          ),
          onTap: _mostrarSelectorColor,
        ),
        const SizedBox(height: 12),
        _buildConfigItem(
          icon: Icons.image_rounded,
          title: 'Imagen de Portada',
          subtitle: _nuevoBanner != null ? '¡Imagen seleccionada! 🐾' : 'Cambia el banner que ven todos los michis',
          onTap: () async {
            final picker = ImagePicker();
            final imagen = await picker.pickImage(source: ImageSource.gallery);
            if (imagen != null) {
              setState(() => _nuevoBanner = imagen);
            }
          },
        ),
        const SizedBox(height: 32),
        _buildSeccionHeader('Datos Generales'),
        const SizedBox(height: 16),
        _buildEditableField('Nombre de la Comunidad', _nombreCtrl, Icons.title_rounded),
        const SizedBox(height: 16),
        _buildEditableField('Descripción (Miau-Biografía)', _descCtrl, Icons.description_rounded, maxLines: 3),
        const SizedBox(height: 32),
        _buildSeccionHeader('Funcionalidades'),
        const SizedBox(height: 16),
        _buildConfigItem(
          icon: Icons.store_rounded,
          title: 'Tienda de la Comunidad',
          subtitle: _tiendaHabilitada ? 'La tienda está activada 🛍️' : 'Activa la tienda para recibir diseños',
          trailing: Switch(
            value: _tiendaHabilitada,
            activeColor: const Color(0xFFC35E34),
            onChanged: (val) => setState(() => _tiendaHabilitada = val),
          ),
          onTap: () => setState(() => _tiendaHabilitada = !_tiendaHabilitada),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC35E34),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
          ),
          onPressed: _guardarAjustes,
          child: Text('GUARDAR CAMBIOS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _mostrarSelectorColor() {
    final colores = [
      '#C35E34', '#248EA6', '#F28B50', '#7A918D', 
      '#D95F43', '#4A4440', '#9BBAB7', '#E8D5C4'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecciona un color', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: colores.map((c) => GestureDetector(
              onTap: () {
                setState(() => _colorSeleccionado = c);
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(color: _colorSeleccionado == c ? Colors.black : Colors.transparent, width: 2),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarAjustes() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardando cambios... 🐾')));
    
    final res = await _servicioComunidades.actualizarComunidad(
      widget.comunidad.id,
      nombre: _nombreCtrl.text,
      descripcion: _descCtrl.text,
      colorTema: _colorSeleccionado,
      tiendaHabilitada: _tiendaHabilitada,
      banner: _nuevoBanner,
    );

    if (mounted) {
      if (res.exito && res.datos != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Ajustes actualizados! ✨'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, res.datos); // Devuelve la comunidad actualizada
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${res.mensaje}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _buildSeccionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
    );
  }

  Widget _buildConfigItem({required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFC35E34).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFFC35E34), size: 22)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return EstadoVacioCargando(icon: icon, message: msg);
  }
}

class _TarjetaGestion extends StatelessWidget {
  final String nombre;
  final String subtitulo;
  final String? avatarUrl;
  final List<Widget> acciones;

  const _TarjetaGestion({required this.nombre, required this.subtitulo, this.avatarUrl, required this.acciones});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2), width: 2)
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? CachedNetworkImageProvider(avatarUrl!) : null,
              child: avatarUrl == null ? Icon(Icons.pets_rounded, color: Colors.grey.shade400) : null,
            ),
          ),
          title: Text(nombre, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitulo, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: acciones),
        ),
      ),
    );
  }
}
