import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/comunidad.dart';
import '../../models/usuario.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_inicio.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_notificaciones.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../comunidades/pantalla_admin_comunidad.dart';
import '../comunidades/pantalla_comunidades.dart';
import '../notificaciones/pantalla_notificaciones.dart';
import '../galeria/pantalla_mis_cosas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/publicacion.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../../widgets/comunes/vista_requerir_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indiceSeleccionado = 0;
  bool _estaLogueado = false;
  String? _miNombre;
  String? _miAvatar;
  int? _miId;
  List<Comunidad> _misComunidades = [];
  Comunidad? _comunidadSeleccionada;
  Usuario? _usuarioSeleccionado;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      final resDatos = await ServicioUsuarios().obtenerDatosPropios();
      if (resDatos.exito && resDatos.datos != null) {
        if (mounted) {
          setState(() {
            _estaLogueado = true;
            _miNombre = resDatos.datos!.nombreUsuario;
            _miAvatar = resDatos.datos!.urlAvatar;
            _miId = resDatos.datos!.id;
          });
          _cargarComunidades();
        }
      }
    }
  }

  Future<void> _cargarComunidades() async {
    final res = await ServicioComunidades().listarComunidadesPropias();
    if (res.exito && mounted) {
      setState(() {
        _misComunidades = res.datos ?? [];
      });
    }
  }

  void _alPulsarNav(int index) {
    setState(() {
      _indiceSeleccionado = index;
      _comunidadSeleccionada = null; // Volver al feed/explorar al pulsar nav
      _usuarioSeleccionado = null;
    });
  }

  void _seleccionarComunidad(Comunidad comunidad) {
    setState(() {
      _comunidadSeleccionada = comunidad;
      _usuarioSeleccionado = null;
    });
  }

  void _seleccionarUsuario(Usuario usuario) {
    setState(() {
      _usuarioSeleccionado = usuario;
      _comunidadSeleccionada = null;
    });
  }

  List<Widget> get vistasCentrales => [
    FeedPublicaciones(onComunidadSelected: _seleccionarComunidad),
    PantallaComunidades(onComunidadSelected: _seleccionarComunidad), // Explorar
    const PantallaNotificaciones(),
    const Center(child: Text('Chat próximamente 💬', style: TextStyle(color: Colors.white))),
    PantallaMisCosas(usuarioId: _miId ?? 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _CabeceraPro(
            estaLogueado: _estaLogueado,
            nombreUsuario: _miNombre,
            avatarUrl: _miAvatar,
            miId: _miId,
            indiceSeleccionado: _indiceSeleccionado,
            onNavSelected: _alPulsarNav,
            onProfileSelected: _seleccionarUsuario,
          ),
          if (_comunidadSeleccionada != null)
            _BarraContextoComunidad(
              comunidad: _comunidadSeleccionada!,
              miId: _miId,
              onCerrar: () => setState(() => _comunidadSeleccionada = null),
              onComunidadActualizada: (comunidadActualizada) {
                setState(() => _comunidadSeleccionada = comunidadActualizada);
              },
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile)
                      Container(
                        width: 320,
                        height: double.infinity,
                        color: const Color(0xFFFBE9E0), // Fondo lateral diferenciado para que se note
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: SidebarIzquierdo(
                            estaLogueado: _estaLogueado,
                            comunidades: _misComunidades,
                            onComunidadSelected: _seleccionarComunidad,
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: (_comunidadSeleccionada != null || _usuarioSeleccionado != null) ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                        child: _comunidadSeleccionada != null 
                         ? PantallaDetalleComunidad(
                             comunidad: _comunidadSeleccionada!,
                             esIntegrada: true,
                             onBack: () => setState(() => _comunidadSeleccionada = null),
                           )
                         : _usuarioSeleccionado != null
                         ? PantallaDetallePerfil(
                             usuario: _usuarioSeleccionado!,
                             esIntegrada: true,
                             onBack: () => setState(() => _usuarioSeleccionado = null),
                             onPerfilActualizado: () => _inicializarDatos(),
                           )
                         : IndexedStack(
                           index: _indiceSeleccionado,
                           children: [
                             vistasCentrales[0], // Inicio (Público)
                             vistasCentrales[1], // Explorar (Público)
                             _vistaProtegida(vistasCentrales[2], 'Tus Notificaciones'),
                             _vistaProtegida(vistasCentrales[3], 'Tus Mensajes'),
                             _vistaProtegida(vistasCentrales[4], 'Tu Rincón Michi'),
                           ],
                         ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaProtegida(Widget original, String titulo) {
    if (_estaLogueado) return original;
    return VistaRequerirLogin(titulo: titulo);
  }
}

// --- SIDEBAR IZQUIERDO ---
class SidebarIzquierdo extends StatelessWidget {
  final bool estaLogueado;
  final List<Comunidad> comunidades;
  final Function(Comunidad) onComunidadSelected;

  const SidebarIzquierdo({
    super.key,
    required this.estaLogueado,
    required this.comunidades,
    required this.onComunidadSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarjetaSidebar(
          titulo: 'Mis Comunidades (${comunidades.length})',
          contenido: comunidades.isEmpty 
           ? Text('Únete a una comunidad 🐾', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500))
           : Wrap(
             spacing: 8,
             runSpacing: 8,
             children: comunidades.take(6).map((c) => _ComunidadAvatar(
               comunidad: c, 
               onTap: () => onComunidadSelected(c)
             )).toList(),
           ),
        ),
        const SizedBox(height: 20),
        _TarjetaSidebar(
          titulo: 'Ranking Semanal',
          contenido: Column(
            children: [
              _RankingItem(puesto: 1, nombre: 'MichiFan', puntos: 1500),
              _RankingItem(puesto: 2, nombre: 'GatoExplorador', puntos: 1200),
              _RankingItem(puesto: 3, nombre: 'MiauMaster', puntos: 900),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (estaLogueado)
        _TarjetaSidebar(
          titulo: 'Mis Puntos y Rango',
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Michi de Oro IV', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFC35E34), fontSize: 16)),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: 0.7, minHeight: 6, borderRadius: BorderRadius.all(Radius.circular(4)), backgroundColor: Color(0xFFF2D0BD), color: Color(0xFFC35E34)),
              const SizedBox(height: 6),
              Text('350 / 500 Puntos', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaSidebar extends StatelessWidget {
  final String titulo;
  final Widget contenido;

  const _TarjetaSidebar({required this.titulo, required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
          const SizedBox(height: 16),
          contenido,
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.title, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFF28B50);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.grey.shade400, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : Colors.grey.shade400,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComunidadItem extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback onTap;

  const _ComunidadItem({required this.comunidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String name = comunidad.nombre.isNotEmpty ? comunidad.nombre : 'Comunidad';
    final String imageUrl = comunidad.urlPortada.isNotEmpty ? comunidad.urlPortada : 'https://picsum.photos/100';
    final String level = comunidad.ratingMedio.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF28B50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                      ),
                      child: Text(level, style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TOP BAR ---
class TopBar extends StatelessWidget {
  final bool estaLogueado;
  final String? nombreUsuario;
  final int? miId;
  final String? avatarUrl;
  final VoidCallback? onReturnFromProfile;
  
  const TopBar({super.key, required this.estaLogueado, this.nombreUsuario, this.miId, this.avatarUrl, this.onReturnFromProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Busca comunidades o amigos... 🔍',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          if (estaLogueado)
            Row(
              children: [
                IconButton(
                  onPressed: () {}, 
                  icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFF28B50), size: 28),
                  tooltip: 'Crear publicación',
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 56),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32), 
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  onSelected: (value) async {
                    if (value == 'perfil' && miId != null) {
                       final res = await ServicioUsuarios().obtenerDatosUsuario(miId!);
                       if (res.exito && res.datos != null && context.mounted) {
                          await Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetallePerfil(usuario: res.datos!)));
                          if (onReturnFromProfile != null) onReturnFromProfile!();
                       }
                    } else if (value == 'logout') {
                      await ServicioUsuarios().cerrarSesion();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'perfil', child: Row(children: [const Icon(Icons.person_rounded, color: Colors.white, size: 20), const SizedBox(width: 14), Text('Mi Perfil', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600))])),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, color: Color(0xFFD95F43), size: 20), const SizedBox(width: 14), Text('Cerrar Miau-Sesión', style: GoogleFonts.outfit(color: Color(0xFFD95F43), fontWeight: FontWeight.bold))])),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(28)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFFF28B50).withOpacity(0.2),
                          child: ClipOval(child: avatarUrl != null && avatarUrl!.isNotEmpty ? Image.network(avatarUrl!, fit: BoxFit.cover, width: 38, height: 38, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey)) : const Icon(Icons.person, color: Colors.grey)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: Text('Entrar', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/registro'), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28B50), 
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ), 
                  child: Text('Unirse 🐾', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900))
                ),
              ],
            )
        ],
      ),
    );
  }
}

// --- FEED CENTRAL (PUBLICACIONES MASONRY) ---
class FeedPublicaciones extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;

  const FeedPublicaciones({super.key, this.onComunidadSelected});

  @override
  State<FeedPublicaciones> createState() => _FeedPublicacionesState();
}

class _FeedPublicacionesState extends State<FeedPublicaciones> {
  final _servicio = ServicioInicio();
  final _servicioComunidades = ServicioComunidades();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Publicacion> _posts = [];
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _estaLogueado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _cargarPosts();
    _scrollController.addListener(_alHacerScroll);
  }
  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _estaLogueado = prefs.getString('auth_token') != null;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_cargandoMas && !_cargando) {
        _cargarMasPosts();
      }
    }
  }

  Future<void> _cargarPosts() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await _servicio.obtenerPostsInicio(query: _searchController.text);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _posts = res.datos ?? [];
          // Asegurar orden por popularidad
          _posts.sort((a, b) => (b.likesCount + b.comentariosCount).compareTo(a.likesCount + a.comentariosCount));
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  Future<void> _cargarMasPosts() async {
    // Simulación de carga infinita (el backend actual devuelve lista completa, pero preparamos la UI)
    if (_posts.length >= 50) return; // Límite artificial para demo

    setState(() => _cargandoMas = true);
    await Future.delayed(const Duration(seconds: 1)); // Simular latencia
    
    // En una app real, aquí llamaríamos a obtenerPostsInicio con un offset/page
    if (mounted) {
      setState(() => _cargandoMas = false);
    }
  }

  Future<void> _unirseAComunidad(int comunidadId, int index) async {
    if (!_estaLogueado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Vaya! Debes iniciar miau-sesión para unirte 🐾', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFC35E34),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ENTRAR',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ));
      return;
    }

    final res = await _servicioComunidades.unirseAComunidad(comunidadId);
    if (res.exito && mounted) {
      setState(() {
        _posts[index] = _posts[index].copyWith(likesCount: _posts[index].likesCount); 
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Miau-unido con éxito! 🐾', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF248EA6),
        behavior: SnackBarBehavior.floating,
      ));
      _cargarPosts(); // Reload to update states
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje), backgroundColor: const Color(0xFFD95F43)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF29C50)));
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error ?? 'Ocurrió un error', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarPosts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPosts,
      color: const Color(0xFFF29C50),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Galería de Comunidades', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
                  const SizedBox(height: 12),
                  Text('Descubre los rincones más michis hoy ✨', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _cargarPosts(),
                style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                decoration: InputDecoration(
                  hintText: 'Busca en el universo Myngo... 🐾',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF29C50)),
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          if (_posts.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('No hay posts activos 😿', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(28.0),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: MediaQuery.of(context).size.width < 900 ? 2 : 4,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childCount: _posts.length,
                itemBuilder: (context, index) {
                  return _TarjetaPost(
                    post: _posts[index], 
                    onJoin: () => _unirseAComunidad(_posts[index].comunidadId, index),
                    onComunidadSelected: widget.onComunidadSelected,
                  );
                },
              ),
            ),
          if (_cargandoMas)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: Color(0xFFF29C50)))),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _CabeceraPro extends StatelessWidget {
  final bool estaLogueado;
  final String? nombreUsuario;
  final String? avatarUrl;
  final int? miId;
  final int indiceSeleccionado;
  final ValueChanged<int> onNavSelected;
  final Function(Usuario)? onProfileSelected;

  const _CabeceraPro({required this.estaLogueado, required this.nombreUsuario, required this.avatarUrl, this.miId, required this.indiceSeleccionado, required this.onNavSelected, this.onProfileSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC35E34), Color(0xFFE89A6A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          BotonTactil(
            onTap: () => onNavSelected(0),
            child: Row(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Text(
                  'MYNGO',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (estaLogueado) ...[
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularNavItem(icon: Icons.explore_rounded, title: 'Explorar', isActive: indiceSeleccionado == 1, onTap: () => onNavSelected(1)),
                    const SizedBox(width: 12),
                    _CircularNavItem(icon: Icons.chat_bubble_rounded, title: 'Chats', isActive: indiceSeleccionado == 3, onTap: () => onNavSelected(3)),
                    const SizedBox(width: 12),
                    _CircularNavItem(icon: Icons.notifications_rounded, title: 'Notificaciones', isActive: indiceSeleccionado == 2, onTap: () => onNavSelected(2), badge: estaLogueado ? '1' : null),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
          _UserProfileHeader(name: nombreUsuario, avatarUrl: avatarUrl, estaLogueado: estaLogueado, miId: miId, onProfileSelected: onProfileSelected),
        ],
      ),
    );
  }
}

class _CircularNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _CircularNavItem({required this.icon, required this.title, this.isActive = false, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFFC35E34), shape: BoxShape.circle),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: isActive ? FontWeight.w900 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _UserProfileHeader extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final bool estaLogueado;
  final int? miId;
  final Function(Usuario)? onProfileSelected;

  const _UserProfileHeader({this.name, this.avatarUrl, required this.estaLogueado, this.miId, this.onProfileSelected});

  @override
  Widget build(BuildContext context) {
    if (!estaLogueado) {
      return BotonTactil(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('INICIAR SESIÓN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 70),
      color: Colors.white,
      elevation: 20,
      shadowColor: const Color(0xFFC35E34).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      onSelected: (value) async {
          if (value == 'perfil' && miId != null) {
            final res = await ServicioUsuarios().obtenerDatosUsuario(miId!);
            if (res.exito && res.datos != null && context.mounted) {
              if (onProfileSelected != null) {
                onProfileSelected!(res.datos!);
              } else {
                await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (c) => PantallaDetallePerfil(
                    usuario: res.datos!,
                    // No callback here, but we can return true and refetch
                  ))
                );
                // When we return from full screen pop, let's refresh just in case:
                if (onProfileSelected != null) {
                   // actually if onProfileSelected is null, we are NOT inline, we're likely calling from Cabecera directly. Wait, if we are in PantallaInicio, onProfileSelected IS NOT NULL! So this branch only runs when Cabecera is used outside (which there aren't any right now).
                }
              }
            }
          } else if (value == 'config') {
          // TODO: Pantalla de ajustes
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajustes próximamente 🐾')));
        } else if (value == 'logout') {
          await ServicioUsuarios().cerrarSesion();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'perfil',
          child: Row(
            children: [
              const Icon(Icons.person_rounded, color: Color(0xFFC35E34), size: 22),
              const SizedBox(width: 12),
              Text('Mi Perfil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'config',
          child: Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: Color(0xFFC35E34), size: 22),
              const SizedBox(width: 12),
              Text('Configuración', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFD95F43), size: 22),
              const SizedBox(width: 12),
              Text('Cerrar Miau-Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFD95F43))),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
                image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Michi', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('350 Puntos', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}


class _BannerAnuncios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Eliminado a petición del usuario
  }
}

class _ComunidadAvatar extends StatelessWidget {
  final Comunidad comunidad;
  final VoidCallback onTap;
  const _ComunidadAvatar({required this.comunidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
        backgroundImage: comunidad.urlPortada.isNotEmpty ? CachedNetworkImageProvider(comunidad.urlPortada) : null,
        child: comunidad.urlPortada.isEmpty ? Text(comunidad.nombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC35E34))) : null,
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int puesto;
  final String nombre;
  final int puntos;

  const _RankingItem({required this.puesto, required this.nombre, required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: const Color(0xFFC35E34).withOpacity(0.1), child: Text(puesto.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFFC35E34), fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(nombre, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4A4440)))),
          Text('$puntos pts', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _TarjetaPost extends StatelessWidget {
  final Publicacion post;
  final VoidCallback onJoin;
  final Function(Comunidad)? onComunidadSelected;

  const _TarjetaPost({required this.post, required this.onJoin, this.onComunidadSelected});

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
                  CircleAvatar(radius: 16, backgroundColor: const Color(0xFFC35E34).withOpacity(0.1), child: Text(post.comunidadNombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.comunidadNombre, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('Senderismo y Aventura', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onJoin, icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFFC35E34))),
                ],
              ),
            ),
            if (post.urlImagen != null)
              CachedNetworkImage(
                imageUrl: post.urlImagen!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 200, color: const Color(0xFFFEF5F1)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.titulo, style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
                  if (post.contenidoTexto.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.contenidoTexto,
                      style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: const Color(0xFFC35E34).withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(post.likesCount.toString(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(post.comentariosCount.toString(), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await ServicioComunidades().obtenerComunidad(post.comunidadId);
                        if (res.exito && res.datos != null && context.mounted) {
                          if (onComunidadSelected != null) {
                            onComunidadSelected!(res.datos!);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaDetalleComunidad(comunidad: res.datos!),
                              ),
                            );
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No pudimos cargar la comunidad miau 🐾')),
                          );
                        }
                      }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC35E34).withOpacity(0.1),
                        foregroundColor: const Color(0xFFC35E34),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Ver en Comunidad', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- LATERAL DERECHO ---
class LateralDerecho extends StatelessWidget {
  const LateralDerecho({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF2D0BD).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF29C50).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF248EA6).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF248EA6), size: 20),
              ),
              const SizedBox(width: 12),
              Text('MIAU-SUGERENCIAS', style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: ServicioComunidades().listarComunidadesPopulares(), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF29C50))));
              
              final sugeridas = snapshot.data?.datos?.take(4).toList() ?? [];
              if (sugeridas.isEmpty) return Text('Explora para ver más 🐾', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13));

              return Column(
                children: sugeridas.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF29C50).withOpacity(0.1), child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFF29C50), fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(child: Text('c/${c.nombre}', style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF248EA6), const Color(0xFF248EA6).withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: const Color(0xFF248EA6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Text('¿TIENES UN MICHI?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16)),
                const SizedBox(height: 10),
                Text('¡Crea tu propia comunidad y presume de mascota!', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF248EA6),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('EMPEZAR YA', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- BARRA DE CONTEXTO DE COMUNIDAD ---
class _BarraContextoComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final int? miId;
  final VoidCallback onCerrar;
  final Function(Comunidad)? onComunidadActualizada;

  const _BarraContextoComunidad({
    required this.comunidad,
    this.miId,
    required this.onCerrar,
    this.onComunidadActualizada,
  });

  @override
  State<_BarraContextoComunidad> createState() => _BarraContextoComunidadState();
}

class _BarraContextoComunidadState extends State<_BarraContextoComunidad> {
  String _miRol = 'Miembro';
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  @override
  void didUpdateWidget(_BarraContextoComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidad.id != widget.comunidad.id) {
      _obtenerRol();
    }
  }

  Future<void> _obtenerRol() async {
    setState(() => _cargandoRol = true);
    if (widget.miId == null) {
      setState(() => _cargandoRol = false);
      return;
    }
    final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(widget.comunidad.id, widget.miId!);
    if (mounted) {
      setState(() {
        _miRol = res.datos ?? 'Miembro';
        _cargandoRol = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCreador = widget.miId != null && widget.miId == widget.comunidad.creadorId;
    final rolLabel = esCreador ? 'Creador' : _miRol;
    final iconRol = esCreador ? Icons.stars_rounded : (rolLabel == 'Moderador' ? Icons.gavel_rounded : Icons.pets_rounded);
    final colorRol = esCreador ? Colors.amber : (rolLabel == 'Moderador' ? const Color(0xFF248EA6) : const Color(0xFFC35E34));

    return Container(
      height: 70,
      width: double.infinity,
      child: Stack(
        children: [
          // Fondo con imagen y Blur
          if (widget.comunidad.urlPortada != null && widget.comunidad.urlPortada!.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.comunidad.urlPortada!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: widget.comunidad.colorTema),
              ),
            )
          else
            Positioned.fill(child: Container(color: widget.comunidad.colorTema)),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: widget.onCerrar,
                  tooltip: 'Cerrar vista de comunidad',
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comunidad.nombre,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(iconRol, size: 12, color: colorRol),
                        const SizedBox(width: 4),
                        Text(
                          rolLabel.toUpperCase(),
                          style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (esCreador || _miRol == 'Moderador')
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                    onPressed: () async {
                      final actualizada = await Navigator.push<Comunidad>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaAdminComunidad(comunidad: widget.comunidad),
                        ),
                      );
                      if (actualizada != null && widget.onComunidadActualizada != null) {
                        widget.onComunidadActualizada!(actualizada);
                      }
                    },
                    tooltip: 'Administrar Comunidad',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
