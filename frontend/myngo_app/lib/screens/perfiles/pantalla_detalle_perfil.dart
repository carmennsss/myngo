import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/usuario.dart';
import '../../models/perfil.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_galeria.dart';
import '../../widgets/selector_estrellas.dart';
import '../../widgets/comunes/menu_opciones_contenido.dart';
import '../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../inicio/pantalla_inicio.dart';
import '../galeria/pantalla_galeria_principal.dart';
import '../../models/publicacion.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/dialogo_crear_post.dart';
import '../../services/servicio_comunidades.dart';
import 'pantalla_tienda_mejoras.dart';
import 'pantalla_personalizar_perfil.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';
import '../../utils/mejoras_notifier.dart';
import '../../utils/estilo_post_helper.dart';
import '../mensajeria/pantalla_chat.dart';
import '../../services/servicio_chat.dart';

/// Pantalla que muestra los detalles del perfil de un usuario con diseño oscuro y sistema de votos.
class PantallaDetallePerfil extends StatefulWidget {
  final Usuario usuario;
  final int? comunidadIdContexto;
  final bool esIntegrada;
  final VoidCallback? onBack;
  final VoidCallback? onPerfilActualizado;

  const PantallaDetallePerfil({
    super.key, 
    required this.usuario, 
    this.comunidadIdContexto,
    this.esIntegrada = false,
    this.onBack,
    this.onPerfilActualizado,
  });

  @override
  State<PantallaDetallePerfil> createState() => _PantallaDetallePerfilState();
}

class _PantallaDetallePerfilState extends State<PantallaDetallePerfil> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _tabActual = 0;

  int? _currentUserId;
  bool _isLoading = false;
  String? _estadoSeguimiento;
  List<Publicacion>? _publicaciones;
  bool _cargandoPublicaciones = true;

  // Estado para Guardados
  List<Publicacion>? _publicacionesGuardadas;
  bool _cargandoGuardados = false;
  int? _filtroComunidadId;
  List<Map<String, dynamic>> _comunidadesFiltro = [];
  // Campos locales que se actualizan sin recargar el widget completo
  String? _biografiaLocal;
  String? _avatarLocal;
  String? _fondoLocal;
  String? _marcoLocal;
  // Estado del Voto
  bool _haVotadoHoy = false;
  // ignore: unused_field
  int? _puntuacionHoy;
  int _totalVotosRecibidos = 0;
  int _segundosParaReinicio = 0;
  Timer? _timerReinicio;
  bool _mostrarPanelVoto = false;
  int _puntuacionTemporal = 0;
  String? _rolEnComunidad;
  double _ratingLocal = 0.0; // Local state for Point 7

  @override
  void initState() {
    super.initState();
    _estadoSeguimiento = widget.usuario.estadoSeguimiento;
    _biografiaLocal = widget.usuario.biografia;
    _avatarLocal = widget.usuario.urlAvatar;
    _fondoLocal = widget.usuario.fondo;
    _marcoLocal = widget.usuario.marco;
    _ratingLocal = widget.usuario.ratingActual;
    _cargarUsuario();
    _cargarEstadoVoto();
    _cargarPublicaciones();
    _cargarRolContextual();
    
    // Escuchar cambios de mejoras equipadas desde la tienda
    mejoraEquipadaNotifier.addListener(_onMejoraEquipada);
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.index != _tabActual) {
        setState(() => _tabActual = _tabController!.index);
        if (_tabActual == 1) {
          _cargarGuardados();
        }
      }
    });
  }

  void _onMejoraEquipada() {
    // Solo recargamos si es el perfil propio
    if (_currentUserId == widget.usuario.id) {
      _recargarUsuarioActualizado(); // Recarga avatar, marco, fondo, etc.
      _cargarPublicaciones();         // Recarga posts para mostrar el nuevo estilo
    }
  }

  @override
  void didUpdateWidget(PantallaDetallePerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usuario.id != oldWidget.usuario.id) {
      _estadoSeguimiento = widget.usuario.estadoSeguimiento;
      _biografiaLocal = widget.usuario.biografia;
      _avatarLocal = widget.usuario.urlAvatar;
      _fondoLocal = widget.usuario.fondo;
      _marcoLocal = widget.usuario.marco;
      _ratingLocal = widget.usuario.ratingActual;
      _totalVotosRecibidos = 0;
      _haVotadoHoy = false;
      _mostrarPanelVoto = false;
      _puntuacionTemporal = 0;
      _timerReinicio?.cancel();
      
      _cargarEstadoVoto();
      _cargarPublicaciones();
      _cargarRolContextual();
    }
  }

  Future<void> _cargarRolContextual() async {
    if (widget.comunidadIdContexto != null) {
      final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(
        widget.comunidadIdContexto!, 
        widget.usuario.id
      );
      if (res.exito && mounted) {
        setState(() => _rolEnComunidad = res.datos);
      }
    }
  }

  @override
  void dispose() {
    mejoraEquipadaNotifier.removeListener(_onMejoraEquipada);
    _timerReinicio?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) {
      setState(() => _currentUserId = id);
    }
  }

  Future<void> _recargarUsuarioActualizado() async {
    final respuesta = await ServicioUsuarios().obtenerDatosUsuario(widget.usuario.id);
    if (mounted && respuesta.exito && respuesta.datos != null) {
      final u = respuesta.datos!;
      setState(() {
        _biografiaLocal = u.biografia;
        _avatarLocal = u.urlAvatar;
        _fondoLocal = u.fondo;
        _marcoLocal = u.marco;
        _ratingLocal = u.ratingActual;
      });
      widget.onPerfilActualizado?.call();
    }
  }
  
  Future<void> _cargarEstadoVoto() async {
    if (_currentUserId == null) {
      await _cargarUsuario();
    }
    
    // Si no hay sesión iniciada, no intentamos cargar el estado del voto
    if (_currentUserId == null) return;
    
    final respuesta = await ServicioMejoras().obtenerEstadoVoto(
      receptorUsuarioId: widget.usuario.id,
    );

    if (mounted && respuesta.exito) {
      final datos = respuesta.datos!;
      setState(() {
        _haVotadoHoy = datos['ha_votado_hoy'];
        _puntuacionHoy = datos['puntuacion_actual'];
        _totalVotosRecibidos = datos['total_votos'];
        _segundosParaReinicio = datos['segundos_hasta_medianoche'];
      });
      _iniciarContador();
    }
  }
  Future<void> _cargarPublicaciones() async {
    setState(() {
      _cargandoPublicaciones = true;
      _publicaciones = null; // Reiniciar a null para forzar estado de carga puro
    });
    final dynamic respuesta = await ServicioPerfiles().obtenerPublicacionesPerfil(widget.usuario.perfilId);
    if (mounted) {
      setState(() {
        if (respuesta.exito && respuesta.datos != null) {
          _publicaciones = respuesta.datos as List<Publicacion>;
        } else {
          _publicaciones = []; // Si falla o no hay datos, lista vacía
        }
        _cargandoPublicaciones = false;
      });
    }
  }

  Future<void> _cargarGuardados({int? comunidadId}) async {
    setState(() {
      _cargandoGuardados = true;
      _publicacionesGuardadas = null; // Reiniciar a null
      if (comunidadId == null && _filtroComunidadId == null) {
        _comunidadesFiltro = [];
      }
    });

    final res = await ServicioPerfiles().obtenerPublicacionesGuardadas(comunidadId: comunidadId);
    
    if (mounted) {
      setState(() {
        if (res.exito && res.datos != null) {
          _publicacionesGuardadas = res.datos as List<Publicacion>;
          if (comunidadId == null && _filtroComunidadId == null) {
             _extraerComunidadesFiltro(_publicacionesGuardadas!);
          }
        } else {
          _publicacionesGuardadas = [];
        }
        _cargandoGuardados = false;
      });
    }
  }

  void _extraerComunidadesFiltro(List<Publicacion> posts) {
    final Map<int, String> uniqueComs = {};
    for (var p in posts) {
      if (p.comunidadId != 0) {
        uniqueComs[p.comunidadId] = p.comunidadNombre;
      }
    }
    _comunidadesFiltro = uniqueComs.entries
        .map((e) => {'id': e.key, 'nombre': e.value})
        .toList();
  }

  Future<void> _mostrarDialogoEditarBiografia() async {
    final controller = TextEditingController(text: _biografiaLocal ?? '');
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar Biografía', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 300,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Cuéntanos algo sobre ti...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF121212),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF28B50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Guardar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (resultado != null && mounted) {
      final respuesta = await ServicioPerfiles().editarBiografia(biografia: resultado,perfilId:widget.usuario.perfilId );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.red,
        ));
        if (respuesta.exito) setState(() => _biografiaLocal = resultado);
      }
    }
  }

  Future<void> _editarAvatar() async {
    final imagen = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imagen == null || !mounted) return;
    final respuesta = await ServicioPerfiles().editarAvatarPerfil(imagen: imagen,perfilId: widget.usuario.perfilId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(respuesta.mensaje),
        backgroundColor: respuesta.exito ? Colors.green : Colors.red,
      ));
      if (respuesta.exito && respuesta.datos != null) {
        setState(() => _avatarLocal = respuesta.datos);
        _recargarUsuarioActualizado();
      }
    }
  }
  void _iniciarContador() {
    _timerReinicio?.cancel();
    if (_segundosParaReinicio > 0) {
      _timerReinicio = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_segundosParaReinicio > 0) {
              _segundosParaReinicio--;
            } else {
              _haVotadoHoy = false;
              timer.cancel();
            }
          });
        }
      });
    }
  }

  String _formatearTiempo(int segundos) {
    int h = segundos ~/ 3600;
    int m = (segundos % 3600) ~/ 60;
    int s = segundos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final respuesta = await ServicioPerfiles().enviarSolicitud(widget.usuario.nombreUsuario);
    
    if (mounted) {
      if (respuesta.exito) {
        setState(() {
          _estadoSeguimiento = respuesta.datos; 
        });
      }
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _manejarPulsacionBoton() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para poder seguir a otros usuarios 🐾'),
          backgroundColor: Color(0xFFF28B50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_estadoSeguimiento == 'ACEPTADO' || _estadoSeguimiento == 'SOLICITUD') {
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('¿Estás seguro?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            _estadoSeguimiento == 'ACEPTADO' 
              ? '¿Quieres dejar de seguir a @${widget.usuario.nombreUsuario}?' 
              : '¿Quieres cancelar la solicitud enviada a @${widget.usuario.nombreUsuario}?',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Desenlace', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    await _enviarSolicitud();
  }


  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    final inicial = usuario.nombreUsuario.isNotEmpty 
        ? usuario.nombreUsuario[0].toUpperCase() 
        : '?';

    final String fecha = DateFormat('dd MMM yyyy').format(usuario.fechaRegistro);
    final String ratingTexto = _ratingLocal.toStringAsFixed(1);

    // Theme-aware colors
    final colorScheme = Theme.of(context).colorScheme;
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final Color colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final Color colorTextoP = esOscuro ? Colors.white : const Color(0xFF2D2D2D);
    final Color colorTextoS = esOscuro ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color colorCard = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final Color colorBorder = esOscuro ? const Color(0xFF2A2A2A) : Colors.black12;
    final Color colorGradTop = esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFF5EBE6);
    final Color colorGradBot = esOscuro ? const Color(0xFF121212) : colorFondo;

    return Scaffold(
      backgroundColor: colorFondo,
      floatingActionButton: _currentUserId == usuario.id
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearPost,
              backgroundColor: const Color(0xFFF28B50),
              icon: const Icon(Icons.add_box_rounded, size: 20, color: Colors.white),
              label: Text(
                'Subir Post',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 500,
                pinned: true,
                stretch: true,
                backgroundColor: colorGradBot,
                surfaceTintColor: Colors.transparent,
                leading: widget.esIntegrada ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: widget.onBack,
                ) : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: (_fondoLocal != null && _fondoLocal!.isNotEmpty)
                        ? BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(_fondoLocal!),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          )
                        : BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorGradTop.withOpacity(0.5), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                child: Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _currentUserId == usuario.id ? _editarAvatar : null,
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Marco detrás (capa inferior)
                              if (_marcoLocal != null && _marcoLocal!.isNotEmpty)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Image.network(_marcoLocal!, fit: BoxFit.contain),
                                  ),
                                ),
                              // 2. Avatar encima (capa superior)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: (_marcoLocal == null || _marcoLocal!.isEmpty) 
                                      ? Border.all(color: const Color(0xFF248EA6), width: 3)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  image: (_avatarLocal != null && _avatarLocal!.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(_avatarLocal!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (_avatarLocal == null || _avatarLocal!.isEmpty)
                                    ? Center(
                                        child: Text(
                                          inicial,
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF248EA6),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_currentUserId == usuario.id)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _editarAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF28B50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '@${usuario.nombreUsuario}',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: colorTextoP,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (usuario.esVerificado) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded, size: 22, color: Color(0xFF248EA6)),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (_currentUserId == usuario.id)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Color(0xFFC35E34), size: 18),
                                onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PantallaPersonalizarPerfil()),
                                    ).then((_) {
                                      _recargarUsuarioActualizado();
                                    });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          _ChipPrivacidad(esPublica: usuario.esPublico),
                        ],
                      ),
                    ],
                  ),
                  if (_rolEnComunidad != null && _rolEnComunidad != 'Visitante' && _rolEnComunidad != 'Miembro')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_rolEnComunidad == 'Administrador' || _rolEnComunidad == 'Creador') 
                              ? Colors.amber.withOpacity(0.1) 
                              : const Color(0xFF248EA6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_rolEnComunidad == 'Administrador' || _rolEnComunidad == 'Creador') 
                                ? Colors.amber.withOpacity(0.4) 
                                : const Color(0xFF248EA6).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (_rolEnComunidad == 'Administrador' || _rolEnComunidad == 'Creador') 
                                  ? Icons.stars_rounded 
                                  : Icons.gavel_rounded, 
                              color: (_rolEnComunidad == 'Administrador' || _rolEnComunidad == 'Creador') 
                                  ? Colors.amber.shade700 
                                  : const Color(0xFF248EA6), 
                              size: 14
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (_rolEnComunidad == 'Administrador' || _rolEnComunidad == 'Creador') ? 'CREADOR' : 'MODERADOR',
                              style: GoogleFonts.outfit(
                                color: colorTextoP,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${usuario.numeroSeguidores}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorTextoP),
                      ),
                      const SizedBox(width: 4),
                      Text('Seguidores', style: GoogleFonts.inter(color: colorTextoS, fontSize: 14)),
                      const SizedBox(width: 20),
                      Text(
                        '${usuario.numeroSeguidos}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorTextoP),
                      ),
                      const SizedBox(width: 4),
                      Text('Siguiendo', style: GoogleFonts.inter(color: colorTextoS, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- BOTONES DE ACCIÓN (Seguimiento / Edición) ---
                  _construirSeccionAcciones(usuario),
                  const SizedBox(height: 16),
                  
                  // --- SECCIÓN DE VOTACIÓN (BOTÓN) ---
                  if (_currentUserId != usuario.id) ...[
                    _construirBotonVotar(usuario, ratingTexto),
                    if (_mostrarPanelVoto && !_haVotadoHoy) ...[
                      const SizedBox(height: 12),
                      _construirPanelSeleccionVoto(usuario, ratingTexto),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: colorCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          icono: Icons.star_rounded,
                          color: const Color(0xFFF29C50),
                          valor: ratingTexto,
                          etiqueta: 'Media',
                          colorTexto: colorTextoP,
                          colorSecundario: colorTextoS,
                        ),
                        Container(width: 1, height: 40, color: colorBorder),
                        _StatColumn(
                          icono: Icons.calendar_today_rounded,
                          color: Colors.blueGrey,
                          valor: fecha,
                          etiqueta: 'Se unió',
                          colorTexto: colorTextoP,
                          colorSecundario: colorTextoS,
                        ),
                        if (usuario.puntos != null) ...[
                          Container(width: 1, height: 40, color: colorBorder),
                          _StatColumn(
                            icono: Icons.workspace_premium_rounded,
                            color: const Color(0xFFF28B50),
                            valor: usuario.puntos.toString(),
                            etiqueta: 'Puntos',
                            colorTexto: colorTextoP,
                            colorSecundario: colorTextoS,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  Text(
                    'Sobre Mí',
                    style: GoogleFonts.inter(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: colorTextoP,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!usuario.esPublico && usuario.id != _currentUserId && _estadoSeguimiento != 'ACEPTADO') 
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF2A2A2A)),
                            const SizedBox(height: 12),
                            Text(
                              'Esta cuenta es privada',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sigue a este usuario para ver sus fotos y su biografía',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _currentUserId == usuario.id ? _mostrarDialogoEditarBiografia : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _currentUserId == usuario.id ? colorCard : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentUserId == usuario.id
                              ? Border.all(color: colorBorder)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                (_biografiaLocal == null || _biografiaLocal!.isEmpty)
                                  ? (_currentUserId == usuario.id ? 'Toca para añadir tu biografía 🐾' : 'Este usuario aún no ha escrito su biografía.')
                                  : _biografiaLocal!,
                                style: GoogleFonts.inter(
                                  fontSize: 15, 
                                  color: (_biografiaLocal == null || _biografiaLocal!.isEmpty) ? colorTextoS : colorTextoP,
                                  height: 1.6
                                ),
                              ),
                            ),
                            if (_currentUserId == usuario.id)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0, top: 2),
                                child: Icon(Icons.edit_rounded, size: 16, color: Color(0xFF248EA6)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // ── TABS (Solo para dueño) ──
          if (_currentUserId == usuario.id)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: const Color(0xFF248EA6),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF248EA6).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.grid_view_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Publicaciones'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.bookmark_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Guardados'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_tabActual == 0 && (usuario.id == _currentUserId || usuario.esPublico || _estadoSeguimiento == 'ACEPTADO')) ...[
            // ── VISTA PUBLICACIONES ──
            if (_cargandoPublicaciones || _publicaciones == null)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFFF28B50)),
                )),
              )
            else if (_publicaciones!.isEmpty)
              const SliverToBoxAdapter(
                child: EstadoVacioCargando(
                  icon: Icons.feed_outlined,
                  message: 'Aún no hay publicaciones',
                ),
              )
            else
              _buildPublicacionesGrid(_publicaciones!),
          ] else if (_tabActual == 1 && (usuario.id == _currentUserId || usuario.esPublico || _estadoSeguimiento == 'ACEPTADO')) ...[
            // ── VISTA GUARDADOS ──
            
            // Filtros de comunidad
            if (_comunidadesFiltro.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comunidadesFiltro.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Todos', style: GoogleFonts.outfit(fontSize: 12)),
                            selected: _filtroComunidadId == null,
                            onSelected: (v) {
                              setState(() => _filtroComunidadId = null);
                              _cargarGuardados();
                            },
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                            selectedColor: const Color(0xFF248EA6),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(color: _filtroComunidadId == null ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey.shade700)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          ),
                        );
                      }
                      final com = _comunidadesFiltro[index - 1];
                      final isSelected = _filtroComunidadId == com['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(com['nombre'], style: GoogleFonts.outfit(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (v) {
                            setState(() => _filtroComunidadId = v ? com['id'] : null);
                            _cargarGuardados(comunidadId: _filtroComunidadId);
                          },
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                          selectedColor: const Color(0xFF248EA6),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey.shade700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_cargandoGuardados || _publicacionesGuardadas == null)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFF248EA6)),
                )),
              )
            else if (_publicacionesGuardadas!.isEmpty)
              const SliverToBoxAdapter(
                child: EstadoVacioCargando(
                  icon: Icons.bookmark_border_rounded,
                  message: 'No tienes contenido guardado aún',
                ),
              )
            else
              _buildPublicacionesGrid(_publicacionesGuardadas!),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirSeccionAcciones(Usuario usuario) {
    // Si es mi propio perfil, muestro solo Mi Galería (la bio/foto se editan con tap directo)
    if (_currentUserId == usuario.id) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaGaleriaPrincipal(
                      usuarioId: usuario.id,
                      titulo: 'Mi Galería',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.collections_rounded, size: 18, color: Colors.white),
              label: Text(
                'Mi Galería',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF248EA6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaTiendaMejoras(
                      onPuntosActualizados: (p) => inicioState?.actualizarPuntos(p),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.store_rounded, size: 18, color: Colors.white),
              label: Text(
                'Tienda de Mejoras',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28B50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    // Si es el perfil de otro, muestro Seguir, Galería y Mensaje
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _construirBotonSeguimiento(usuario)),
            const SizedBox(width: 12),
            Expanded(child: _construirBotonMensaje(usuario)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
                      Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaGaleriaPrincipal(
                      usuarioId: usuario.id,
                      titulo: 'Galería de @${usuario.nombreUsuario}',
                    ),
                  ),
                );
            },
            icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.white),
            label: Text(
              'Miau Galería 🐾',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              side: const BorderSide(color: Color(0xFF2A2A2A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirBotonSeguimiento(Usuario usuario) {
    String texto;
    IconData icono;
    Color colorFondo;
    Color colorTexto = Colors.white;

    if (_estadoSeguimiento == 'ACEPTADO') {
      texto = 'Siguiendo';
      icono = Icons.person_remove_rounded;
      colorFondo = const Color(0xFF1E1E1E);
      colorTexto = Colors.white;
    } else if (_estadoSeguimiento == 'SOLICITUD') {
      texto = 'Pendiente';
      icono = Icons.cancel_rounded;
      colorFondo = const Color(0xFF1E1E1E);
      colorTexto = Colors.grey;
    } else {
      texto = usuario.esPublico ? 'Seguir' : 'Solicitar';
      icono = usuario.esPublico ? Icons.person_add_alt_1_rounded : Icons.lock_person_rounded;
      colorFondo = const Color(0xFFF28B50);
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _manejarPulsacionBoton,
        icon: Icon(icono, size: 18, color: colorTexto),
        label: Text(
          texto,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: colorTexto),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: (_estadoSeguimiento != null) ? const BorderSide(color: Color(0xFF2A2A2A)) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _construirBotonMensaje(Usuario usuario) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          // Mostrar indicador mientras se crea/busca la sala
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Iniciando chat... 🐾'),
              duration: Duration(seconds: 1),
            ),
          );
          final sala = await ServicioChat.crearSalaPrivada(usuario.id);
          if (sala != null && mounted) {
            // Navegar a través del router → activa la pestaña "Chats"
            context.go(
              '/mensajes/sala/${sala['id']}',
              extra: {
                'nombre': 'Chat con @${usuario.nombreUsuario}',
                'sala': sala,
              },
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo iniciar el chat. ¿Hay conexión al servidor?'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
        label: Text(
          'Mensaje',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _construirBotonVotar(Usuario usuario, String ratingActual) {
    if (!usuario.esPublico && _estadoSeguimiento != 'ACEPTADO' && _currentUserId != usuario.id) {
      final bool esAppClara = Theme.of(context).scaffoldBackgroundColor == const Color(0xFFFEF5F1);
      final Color colorTextoS = esAppClara ? Colors.grey.shade700 : Colors.grey.shade400;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: esAppClara ? Colors.black.withValues(alpha: 0.05) : const Color(0xFF2A2A2A).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, color: colorTextoS, size: 20),
            const SizedBox(width: 12),
            Text('Solo los seguidores pueden votar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorTextoS)),
          ],
        ),
      );
    }

    if (_haVotadoHoy) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF29C50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF29C50).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFF29C50), size: 20),
            const SizedBox(width: 12),
            Text(
              'Voto registrado: ${_formatearTiempo(_segundosParaReinicio)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF29C50),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_currentUserId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inicia sesión para puntuar a este usuario ⭐'),
                backgroundColor: Color(0xFF248EA6),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          setState(() {
            _mostrarPanelVoto = !_mostrarPanelVoto;
          });
        },
        icon: Icon(_mostrarPanelVoto ? Icons.close : Icons.star_rounded, color: Colors.white),
        label: Text(
          _mostrarPanelVoto ? 'Cancelar Voto' : 'Puntuar a @${usuario.nombreUsuario}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _mostrarPanelVoto ? const Color(0xFF1E1E1E) : const Color(0xFF248EA6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: _mostrarPanelVoto ? const BorderSide(color: Color(0xFF2A2A2A)) : BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _construirPanelSeleccionVoto(Usuario usuario, String ratingActual) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Media de @${usuario.nombreUsuario}: $ratingActual',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SelectorEstrellas(
            initialRating: _puntuacionTemporal,
            onRatingChanged: (nuevaPuntuacion) {
              setState(() {
                _puntuacionTemporal = nuevaPuntuacion;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _puntuacionTemporal == 0 ? null : () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final respuesta = await ServicioMejoras().votar(
                  receptorUsuarioId: usuario.id,
                  estrellas: _puntuacionTemporal,
                );
                
                if (respuesta.exito) {
                  setState(() {
                    _mostrarPanelVoto = false;
                    // Task 7: Actualización del rating local si se devuelve nueva_media
                    if (respuesta.datos != null) {
                      _ratingLocal = (respuesta.datos as num).toDouble();
                    }
                  });
                  _cargarEstadoVoto(); 
                }

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(respuesta.mensaje),
                    backgroundColor: respuesta.exito ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF248EA6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Enviar Voto',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => DialogoCrearPost(
        titulo: 'Publicar en Perfil 🐾',
        onPublicar: (texto, imagenes, etiquetas) async {
          if (texto.trim().isEmpty && (imagenes == null || imagenes.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Añade texto o imágenes para publicar'))
            );
            return false;
          }
          final respuesta = await ServicioPerfiles().crearPostPerfil(
            texto: texto.trim().isEmpty ? ' ' : texto.trim(),
            imagenes: imagenes,
            etiquetas: etiquetas,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(respuesta.mensaje),
                backgroundColor: respuesta.exito ? Colors.green : Colors.red,
              )
            );
            if (respuesta.exito) {
              _cargarPublicaciones();
              return true;
            }
          }
          return false;
        },
      ),
    );
  }

  Widget _buildPublicacionesGrid(List<Publicacion> posts) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      sliver: SliverMasonryGrid.extent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childCount: posts.length,
        itemBuilder: (context, index) {
          final publicacion = posts[index];
          final tieneImagen = publicacion.urlImagen != null && publicacion.urlImagen!.isNotEmpty;
          final estilo = publicacion.autorEstiloPost;
          final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
          final colorTexto = esFondoClaro ? Colors.black87 : Colors.white;

          Widget celda = tieneImagen
              ? AspectRatio(
                  aspectRatio: publicacion.relacionAspecto > 0 ? publicacion.relacionAspecto : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      publicacion.urlImagen!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: EstiloPostHelper.buildDecoracion(
                    estilo,
                    borderRadius: BorderRadius.circular(12),
                    borderWidth: 1.0,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF248EA6), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              publicacion.titulo.isNotEmpty ? publicacion.titulo : 'Nota',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF248EA6), fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        publicacion.contenidoTexto,
                        style: GoogleFonts.inter(
                          fontSize: 13, 
                          color: colorTexto.withOpacity(0.9), 
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );

          return GestureDetector(
            onTap: () => DetallePublicacionSheet.mostrar(
              context,
              publicacion: publicacion,
              avatarUrl: publicacion.autorFoto ?? '',
              onEliminado: _cargarPublicaciones, // Actualiza la página si se borra
              onProfileSelected: (u) {
                final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                if (inicioState != null) {
                  inicioState.seleccionarUsuario(u);
                }
              },
            ),
            child: celda,
          );
        },
      ),
    );
  }
}

class _ChipPrivacidad extends StatelessWidget {
  final bool esPublica;
  const _ChipPrivacidad({required this.esPublica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esPublica ? const Color(0xFF248EA6).withOpacity(0.1) : const Color(0xFFF29C50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.visibility_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? const Color(0xFF248EA6) : const Color(0xFFF29C50),
          ),
          const SizedBox(width: 6),
          Text(
            esPublica ? 'Público' : 'Privado',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: esPublica ? const Color(0xFF248EA6) : const Color(0xFFF29C50),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String? valor;
  final String? etiqueta;
  final Color? colorTexto;
  final Color? colorSecundario;

  const _StatColumn({
    required this.icono,
    required this.color,
    this.valor,
    this.etiqueta,
    this.colorTexto,
    this.colorSecundario,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textColor = colorTexto ?? (esOscuro ? Colors.white : const Color(0xFF2D2D2D));
    final subColor = colorSecundario ?? (esOscuro ? Colors.grey.shade400 : Colors.grey.shade600);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              valor ?? '0',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          etiqueta ?? '',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: subColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
