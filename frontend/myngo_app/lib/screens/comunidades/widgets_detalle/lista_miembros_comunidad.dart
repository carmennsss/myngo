import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../utils/configuracion.dart';
import '../../../models/comunidad.dart';
import '../../../services/servicio_comunidades.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/comunes/boton_tactil.dart';
import '../../perfiles/pantalla_detalle_perfil.dart';
import '../../../models/usuario.dart';

class ListaMiembrosComunidad extends StatefulWidget {
  final Comunidad comunidad;

  final bool comoSliver;

  const ListaMiembrosComunidad({
    super.key, 
    required this.comunidad,
    this.comoSliver = false,
  });

  @override
  State<ListaMiembrosComunidad> createState() => _ListaMiembrosComunidadState();
}

class _ListaMiembrosComunidadState extends State<ListaMiembrosComunidad> {
  final _servicio = ServicioComunidades();
  List<Map<String, dynamic>> _miembros = [];
  bool _estaCargando = true;
  bool _estaCargandoMas = false;
  bool _hayMasMiembros = true;
  int _paginaActual = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    _scrollController.addListener(_alHacerScroll);
  }

  void _alHacerScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!_estaCargando && !_estaCargandoMas && _hayMasMiembros) {
        _cargarMasMiembros();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarMiembros() async {
    setState(() => _estaCargando = true);
    _paginaActual = 1;
    final res = await _servicio.obtenerMiembrosComunidad(widget.comunidad.id, pagina: _paginaActual);
    if (mounted) {
      setState(() {
        _miembros = res.datos ?? [];
        _hayMasMiembros = (res.datos?.length ?? 0) >= 20;
        _estaCargando = false;
      });
    }
  }

  Future<void> _cargarMasMiembros() async {
    if (_estaCargandoMas || !_hayMasMiembros) return;
    setState(() => _estaCargandoMas = true);
    
    _paginaActual++;
    final res = await _servicio.obtenerMiembrosComunidad(widget.comunidad.id, pagina: _paginaActual);
    
    if (mounted) {
      setState(() {
        _estaCargandoMas = false;
        if (res.exito && res.datos != null) {
          final nuevos = res.datos!;
          _miembros.addAll(nuevos);
          _hayMasMiembros = nuevos.length >= 20;
        } else {
          _hayMasMiembros = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      final loading = const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
      return widget.comoSliver ? SliverFillRemaining(child: loading) : loading;
    }

    if (_miembros.isEmpty) {
      final empty = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No hay miembros en esta comunidad 🐾', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
      return widget.comoSliver ? SliverFillRemaining(child: empty) : empty;
    }

    if (widget.comoSliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMemberItem(context, index),
            childCount: _miembros.length + (_estaCargandoMas ? 1 : 0),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMiembros,
      color: const Color(0xFFC35E34),
      child: ListView.builder(
        controller: _scrollController,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _miembros.length + (_estaCargandoMas ? 1 : 0),
        itemBuilder: (context, index) => _buildMemberItem(context, index),
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, int index) {
    if (index == _miembros.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
      );
    }
    final m = _miembros[index];
    final userId = m['usuario_id'] ?? m['usuario'];
    final nombre = m['usuario_nombre'] ?? 'Michi';
    final avatar = m['usuario_avatar'];
    final rol = _normalizarRol(m['rol'] ?? 'Miembro');
    
    return Consumer<ChatProvider>(
      builder: (context, chatProv, _) {
        final estaOnline = chatProv.isUsuarioOnline(userId);
        
        return BotonTactil(
          onTap: () {
            // Navegar al perfil del usuario
            if (userId != null) {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (c) => PantallaDetallePerfil(
                    usuario: Usuario(
                      id: userId,
                      perfilId: m['perfil_id'] ?? 0,
                      nombreUsuario: nombre,
                      urlAvatar: avatar,
                      email: '',
                      biografia: '',
                      ratingActual: 0.0,
                      fechaRegistro: DateTime.now(),
                      esVerificado: false,
                      esPublico: true,
                      estado: estaOnline ? 'ACTIVO' : 'DESCONECTADO',
                    )
                  )
                )
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Builder(
                      builder: (context) {
                        String? urlAvatar = avatar;
                        if (urlAvatar != null && urlAvatar.isNotEmpty) {
                          if (!urlAvatar.startsWith('http')) {
                            urlAvatar = '${Configuracion.baseUrl}${urlAvatar.startsWith('/') ? '' : '/'}$urlAvatar';
                          }
                        }
                        // Si no hay avatar, mostrar placeholder directamente
                        if (urlAvatar == null || urlAvatar.isEmpty) {
                          return CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: urlAvatar,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 26,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) => CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: estaOnline ? Colors.green : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF4A4440)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getColorRol(rol).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rol.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _getColorRol(rol),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        'Miembro desde ${DateFormat('dd/MM/yyyy').format(DateTime.parse(m['fecha_union'] ?? DateTime.now().toIso8601String()))}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
              ],
            ),
          ),
        );
      },
    );
  }

  String _normalizarRol(String rol) {
    // El backend devuelve 'Administrador' para el creador, lo normalizamos
    if (rol.toLowerCase() == 'administrador') return 'Creador';
    return rol;
  }

  Color _getColorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
      case 'creador':
        return const Color(0xFFD95F43);
      case 'moderador':
        return const Color(0xFF248EA6);
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildPlaceholderAvatar(String nombre) {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(String nombre) {
    return Text(
      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
      style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}
