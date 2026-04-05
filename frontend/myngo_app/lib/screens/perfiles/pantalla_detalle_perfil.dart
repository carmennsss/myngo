import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/usuario.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_galeria.dart';
import '../../widgets/selector_estrellas.dart';
import '../../widgets/comunes/menu_opciones_contenido.dart';
import '../../widgets/comunes/detalle_publicacion_sheet.dart';
import '../galeria/pantalla_galeria_principal.dart';
import '../../models/publicacion.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/dialogo_crear_post.dart';

/// Pantalla que muestra los detalles del perfil de un usuario con diseño oscuro y sistema de votos.
class PantallaDetallePerfil extends StatefulWidget {
  final Usuario usuario;
  const PantallaDetallePerfil({super.key, required this.usuario});

  @override
  State<PantallaDetallePerfil> createState() => _PantallaDetallePerfilState();
}

class _PantallaDetallePerfilState extends State<PantallaDetallePerfil> {
  int? _currentUserId;
  bool _isLoading = false;
  String? _estadoSeguimiento;
  List<Publicacion> _publicaciones = [];
  bool _cargandoPublicaciones = true;
  // Campos locales que se actualizan sin recargar el widget completo
  String? _biografiaLocal;
  String? _avatarLocal;
  // Estado del Voto
  bool _haVotadoHoy = false;
  // ignore: unused_field
  int? _puntuacionHoy;
  int _totalVotosRecibidos = 0;
  int _segundosParaReinicio = 0;
  Timer? _timerReinicio;
  bool _mostrarPanelVoto = false;
  int _puntuacionTemporal = 0;

  @override
  void initState() {
    super.initState();
    _estadoSeguimiento = widget.usuario.estadoSeguimiento;
    _biografiaLocal = widget.usuario.biografia;
    _avatarLocal = widget.usuario.urlAvatar;
    _totalVotosRecibidos = 0; 
    _cargarUsuario();
    _cargarEstadoVoto();
    _cargarPublicaciones();
  }

  @override
  void dispose() {
    _timerReinicio?.cancel();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) {
      setState(() => _currentUserId = id);
    }
  }
  
  Future<void> _cargarEstadoVoto() async {
    if (_currentUserId == null) {
      await _cargarUsuario();
    }
    
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
    setState(() => _cargandoPublicaciones = true);
    final dynamic respuesta = await ServicioPerfiles().obtenerPublicacionesPerfil(widget.usuario.perfilId);
    if (mounted) {
      setState(() {
        if (respuesta.exito && respuesta.datos != null) {
          _publicaciones = respuesta.datos as List<Publicacion>;
        }
        _cargandoPublicaciones = false;
      });
    }
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

    // Regla de 10 votos
    final String ratingTexto = _totalVotosRecibidos >= 10 
        ? usuario.ratingActual.toStringAsFixed(1)
        : 'N/D';

    return Scaffold(
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _currentUserId == usuario.id ? _editarAvatar : null,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF248EA6), width: 3),
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
                                  color: Colors.white,
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
                      _ChipPrivacidad(esPublica: usuario.esPublico),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${usuario.numeroSeguidores}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text('Seguidores', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
                      const SizedBox(width: 20),
                      Text(
                        '${usuario.numeroSeguidos}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text('Siguiendo', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- BOTONES DE ACCIÓN (Seguimiento / Edición) ---
                  _construirSeccionAcciones(usuario),
                  const SizedBox(height: 16),
                  
                  // --- SECCIÓN DE VOTACIÓN (BOTÓN) ---
                  _construirBotonVotar(usuario, ratingTexto),
                  if (_mostrarPanelVoto && !_haVotadoHoy) ...[
                    const SizedBox(height: 12),
                    _construirPanelSeleccionVoto(usuario, ratingTexto),
                  ],
                  const SizedBox(height: 24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          icono: Icons.star_rounded,
                          color: const Color(0xFFF29C50),
                          valor: ratingTexto,
                          etiqueta: 'Media',
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
                        _StatColumn(
                          icono: Icons.calendar_today_rounded,
                          color: Colors.blueGrey,
                          valor: fecha,
                          etiqueta: 'Se unió',
                        ),
                        if (usuario.puntos != null) ...[
                          Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
                          _StatColumn(
                            icono: Icons.workspace_premium_rounded,
                            color: const Color(0xFFF28B50),
                            valor: usuario.puntos.toString(),
                            etiqueta: 'Puntos',
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
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!usuario.esPublico) 
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
                          color: _currentUserId == usuario.id ? const Color(0xFF1A1A1A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentUserId == usuario.id
                              ? Border.all(color: const Color(0xFF2A2A2A), style: BorderStyle.solid)
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
                                  color: (_biografiaLocal == null || _biografiaLocal!.isEmpty) ? Colors.grey.shade600 : Colors.grey.shade400,
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
          if (_cargandoPublicaciones)
            const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: Color(0xFFF28B50)),
              )),
            )
          else if (_publicaciones.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    'Aún no hay publicaciones',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160, // máximo 160px por celda
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final publicacion = _publicaciones[index];
                    final tieneImagen = publicacion.urlImagen != null && publicacion.urlImagen!.isNotEmpty;

                    Widget celda = ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: tieneImagen
                          ? Image.network(
                              publicacion.urlImagen!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1E1E1E),
                                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A2744), Color(0xFF0F1A33)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: const Color(0xFF248EA6).withOpacity(0.3), width: 0.8),
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 8, 4, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4, height: 4,
                                        decoration: const BoxDecoration(color: Color(0xFF248EA6), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          publicacion.titulo?.isNotEmpty == true ? publicacion.titulo! : 'Nota',
                                          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF248EA6), fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      publicacion.contenidoTexto,
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.85), height: 1.4),
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    );

                    // Celda con tap para ver detalle + menú de opciones superpuesto
                    return GestureDetector(
                      onTap: () => DetallePublicacionSheet.mostrar(
                        context,
                        publicacion: publicacion,
                        avatarUrl: _avatarLocal ?? widget.usuario.urlAvatar ?? '',
                        onEliminado: () => setState(() => _publicaciones.removeAt(index)),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          celda,
                          Positioned(
                            top: 2,
                            right: 2,
                            child: MenuOpcionesContenido(
                              tipoObjeto: 'POST',
                              objetoId: publicacion.id,
                              autorId: widget.usuario.id,
                              onEliminado: () => setState(() => _publicaciones.removeAt(index)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _publicaciones.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _construirSeccionAcciones(Usuario usuario) {
    // Si es mi propio perfil, muestro solo Mi Galería (la bio/foto se editan con tap directo)
    if (_currentUserId == usuario.id) {
      return SizedBox(
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función de chat próximamente 🐾')),
          );
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
      builder: (context) => DialogoCrearPost(
        titulo: 'Publicar en Perfil 🐾',
        onPublicar: (texto, imagen, etiquetas) async {
          if (texto.trim().isEmpty && imagen == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Añade texto o una imagen para publicar'))
            );
            return false;
          }
          final respuesta = await ServicioPerfiles().crearPostPerfil(
            texto: texto.trim().isEmpty ? ' ' : texto.trim(),
            imagen: imagen,
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

  const _StatColumn({
    required this.icono,
    required this.color,
    this.valor,
    this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          etiqueta ?? '',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
