import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/comunidad.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_inicio.dart';
import '../perfiles/pantalla_perfiles.dart';
import '../comunidades/pantalla_comunidades.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../notificaciones/pantalla_notificaciones.dart';
import '../galeria/pantalla_mis_cosas.dart';
import '../perfiles/pantalla_detalle_perfil.dart';

// --- MAIN SCREEN ---
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  bool _estaLogueado = false;
  int? _miId;
  String? _miNombre;
  String? _miAvatar;
  List<Comunidad> _misComunidades = [];
  bool _cargandoInicial = true;
  int _indiceSeleccionado = 0;
  // ignore: unused_field
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final servicioUsuarios = ServicioUsuarios();
    
    // Eliminada la destrucción agresiva de sesión para no romper Web al recargar (F5)

    final token = await servicioUsuarios.obtenerToken();
    if (token != null) {
      _estaLogueado = true;
      _miId = await servicioUsuarios.obtenerIdUsuario();
      _miNombre = await servicioUsuarios.obtenerNombreUsuario();
      // Cargar datos completos para obtener el avatar
      if (_miId != null) {
        final resPerfil = await servicioUsuarios.obtenerDatosUsuario(_miId!);
        if (resPerfil.exito && resPerfil.datos != null) {
          _miAvatar = resPerfil.datos!.urlAvatar;
        }
      }
      final resComunidades = await ServicioComunidades().listarComunidadesPropias();
      if (resComunidades.exito) {
        _misComunidades = resComunidades.datos ?? [];
      }
      _notifCount = await ServicioNotificaciones().obtenerConteoNoLeidas();
    }
    if (mounted) {
      setState(() {
        _cargandoInicial = false;
      });
    }
  }

  void _alPulsarNav(int index) {
      // Proteger notificaciones, mensajes y mis cosas si no está logueado
      if ((index >= 2 && index <= 4) && !_estaLogueado) {
          Navigator.pushNamed(context, '/login');
          return;
      }
      setState(() { _indiceSeleccionado = index; });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212), 
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
      );
    }

    final List<Widget> vistasCentrales = [
      const FeedGaleria(),
      const PantallaComunidades(), // Explorar Comunidades
      const PantallaNotificaciones(), // Notificaciones
      const Center(child: Text('Mensajes Privados', style: TextStyle(color: Colors.white, fontSize: 24))), // Mensajes
      PantallaMisCosas(usuarioId: _miId ?? 0), // Mis Cosas
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Row(
            children: [
              // 20% Sidebar Derecho (Oculto en móvil)
              if (!isMobile)
                SizedBox(
                  width: 250,
                  child: SidebarIzquierdo(
                    estaLogueado: _estaLogueado,
                    comunidades: _misComunidades,
                    indiceSeleccionado: _indiceSeleccionado,
                    onNavSelected: _alPulsarNav,
                  ),
                ),

              // 55% Feed Central
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    TopBar(estaLogueado: _estaLogueado, nombreUsuario: _miNombre, miId: _miId, avatarUrl: _miAvatar, onReturnFromProfile: _inicializarDatos,),
                    Expanded(
                      child: IndexedStack(
                        index: _indiceSeleccionado,
                        children: vistasCentrales,
                      ),
                    ),
                  ],
                ),
              ),

              // 25% Lateral Derecho (Oculto en pantallas medianas/pequeñas)
              if (constraints.maxWidth > 1100 && _indiceSeleccionado == 0)
                const SizedBox(
                  width: 320, 
                  child: LateralDerecho(),
                ),
            ],
          );
        },
      ),
    );
  }
}

// --- SIDEBAR IZQUIERDO ---
class SidebarIzquierdo extends StatelessWidget {
  final bool estaLogueado;
  final List<Comunidad> comunidades;
  final int indiceSeleccionado;
  final ValueChanged<int> onNavSelected;

  const SidebarIzquierdo({
    super.key,
    required this.estaLogueado,
    required this.comunidades,
    required this.indiceSeleccionado,
    required this.onNavSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              'MYNGO',
              style: GoogleFonts.inter(
                color: const Color(0xFF248EA6), // Teal para el Logo MYNGO
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _NavItem(icon: Icons.home_filled, title: 'Inicio', isActive: indiceSeleccionado == 0, onTap: () => onNavSelected(0)),
          _NavItem(icon: Icons.explore_rounded, title: 'Explorar', isActive: indiceSeleccionado == 1, onTap: () => onNavSelected(1)),
          _NavItem(icon: Icons.notifications_rounded, title: 'Notificaciones', isActive: indiceSeleccionado == 2, onTap: () => onNavSelected(2)),
          _NavItem(icon: Icons.mail_rounded, title: 'Mensajes', isActive: indiceSeleccionado == 3, onTap: () => onNavSelected(3)),
          _NavItem(icon: Icons.folder_special_rounded, title: 'Mis Cosas', isActive: indiceSeleccionado == 4, onTap: () => onNavSelected(4)),
          
          if (estaLogueado) ...[
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'MIS COMUNIDADES',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: comunidades.isEmpty 
               ? Center(child: Text('Nada por aquí 🐾', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)))
               : ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: comunidades.length,
                itemBuilder: (context, index) {
                  final c = comunidades[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PantallaDetalleComunidad(comunidad: c)),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: _ComunidadItem(
                      name: c.nombre.isNotEmpty ? c.nombre : 'Comunidad', 
                      imageUrl: c.urlPortada.isNotEmpty ? c.urlPortada : 'https://picsum.photos/100', 
                      level: c.ratingMedio.toStringAsFixed(1),
                      pendingCount: c.conteoPendienteAdmin,
                    ),
                  );
                },
              ),
            ),
          ] else const Spacer(),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.title, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFF28B50) : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComunidadItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String level;
  final int pendingCount;

  const _ComunidadItem({
    required this.name, 
    required this.imageUrl, 
    required this.level,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF248EA6).withOpacity(0.1),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF28B50),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    level,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        pendingCount > 99 ? '99+' : pendingCount.toString(),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar en Myngo...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(Icons.search, color: Colors.grey, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Perfil de usuario / Login states
          if (estaLogueado)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) async {
                    if (value == 'perfil' && miId != null) {
                       // Mostrar un loader simple o navegar tras petición
                       final res = await ServicioUsuarios().obtenerDatosUsuario(miId!);
                       if (res.exito && res.datos != null && context.mounted) {
                          await Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaDetallePerfil(usuario: res.datos!)));
                          if (onReturnFromProfile != null) onReturnFromProfile!();
                       }
                    } else if (value == 'configuracion') {
                      // Placeholder
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pantalla de configuración próximamente 🛠️'))
                        );
                      }
                    } else if (value == 'logout') {
                      await ServicioUsuarios().cerrarSesion();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'perfil',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text('Mi Perfil', style: GoogleFonts.inter(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'configuracion',
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text('Configuración', style: GoogleFonts.inter(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Color(0xFFF28B50), size: 20),
                          const SizedBox(width: 12),
                          Text('Cerrar Sesión', style: GoogleFonts.inter(color: const Color(0xFFF28B50))),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      if (nombreUsuario != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            nombreUsuario ?? 'Usuario',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF248EA6).withOpacity(0.3),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) => Text(
                                  (nombreUsuario ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF248EA6), fontWeight: FontWeight.bold),
                                ),
                              )
                            : Text(
                                (nombreUsuario ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF248EA6), fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
               children: [
                   TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Text('Iniciar Sesión', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/registro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF28B50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ),
                      child: Text('Regístrate', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))
                   ),
               ]
            )
        ],
      ),
    );
  }
}

// --- FEED CENTRAL (GALERÍA PINTEREST) ---
class FeedGaleria extends StatefulWidget {
  const FeedGaleria({super.key});

  @override
  State<FeedGaleria> createState() => _FeedGaleriaState();
}

class _FeedGaleriaState extends State<FeedGaleria> {
  final _servicio = ServicioInicio();
  final TextEditingController _searchController = TextEditingController();
  List<ImagenGaleria> _imagenes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarGaleria();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarGaleria() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    // ¡AQUÍ PASAMOS EL PARÁMETRO AL SERVICIO!
    final res = await _servicio.obtenerGaleriaInicio(query: _searchController.text);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _imagenes = res.datos ?? [];
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error ?? 'Ocurrió un error inesperado', style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _cargarGaleria,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF28B50)),
              label: Text('Reintentar', style: GoogleFonts.inter(color: const Color(0xFFF28B50))),
            ),
          ],
        ),
      );
    }


    return RefreshIndicator(
      onRefresh: _cargarGaleria,
      color: const Color(0xFFF28B50),
      backgroundColor: const Color(0xFF1E1E1E),
      child: CustomScrollView(
        slivers: [
          // ¡NUEVA BARRA DE BÚSQUEDA!
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: TextField(
                controller: _searchController,
                onSubmitted: (texto) {
                  _cargarGaleria(); // Se vuelve a cargar al pulsar "Enter"
                },
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por etiquetas (ej. arte, paisaje...)',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _cargarGaleria();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFF28B50)),
                  ),
                ),
              ),
            ),
          ),
          if (_imagenes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Aún no hay imágenes para mostrar.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Busca otra etiqueta o sigue comunidades para ver contenido.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: _imagenes.length,
              itemBuilder: (context, index) {
                final imagen = _imagenes[index];
                // Altura variable para dar el efecto Pinterest, o basada en relación de aspecto si está disponible.
                double aspectRatio = imagen.relacionAspecto > 0 ? imagen.relacionAspecto : 1.0;
                // Limitamos la relación de aspecto extrema para que no haya imágenes larguísimas
                aspectRatio = aspectRatio.clamp(0.5, 2.0);

                return Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imagen.urlArchivo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1E1E1E),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1E1E1E),
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    // Efecto hover (Capa opcional si quieres estilo Pinterest real)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          hoverColor: Colors.black.withOpacity(0.2),
                          onTap: () {
                            // TODO: Abrir imagen en grande o ver post
                          },
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
}

// --- LATERAL DERECHO ---
class LateralDerecho extends StatelessWidget {
  const LateralDerecho({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ranking
          Text('RANKING SEMANAL', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Column(
              children: [
                _RankingItem(pos: 1, name: 'Arte Digital', points: '12K pt'),
                _RankingItem(pos: 2, name: 'Fotografía', points: '9.5K pt'),
                _RankingItem(pos: 3, name: 'Desarrollo Web', points: '8.2K pt', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Galería
          Text('GALERÍA POPULAR', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              physics: const ClampingScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(6, (index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: 'https://picsum.photos/id/${10 + index}/200',
                    fit: BoxFit.cover,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int pos;
  final String name;
  final String points;
  final bool isLast;

  const _RankingItem({required this.pos, required this.name, required this.points, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isFirst = pos == 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        children: [
          Text(
            '#$pos', 
            style: GoogleFonts.inter(
              color: isFirst ? const Color(0xFFF28B50) : Colors.grey, 
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Text(points, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
