import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/comunidad.dart';
import '../models/publicacion.dart';
import '../services/servicio_usuarios.dart';
import '../services/servicio_comunidades.dart';
import '../services/servicio_notificaciones.dart';
import 'comunidades/pantalla_comunidades.dart';
import 'comunidades/pantalla_detalle_comunidad.dart';
import 'notificaciones/pantalla_notificaciones.dart';
import 'perfiles/pantalla_perfil_usuario.dart';

// --- MAIN SCREEN ---
class PantallaPrincipalRedesign extends StatefulWidget {
  const PantallaPrincipalRedesign({super.key});

  @override
  State<PantallaPrincipalRedesign> createState() => _PantallaPrincipalRedesignState();
}

class _PantallaPrincipalRedesignState extends State<PantallaPrincipalRedesign> {
  bool _estaLogueado = false;
  int? _miId;
  String? _miNombre;
  List<Comunidad> _misComunidades = [];
  bool _cargandoInicial = true;
  int _indiceSeleccionado = 0;
  int _notifCount = 0;
  static bool _sesionComprobada = false; 

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final recordarme = prefs.containsKey('recordar_email');
    
    final servicioUsuarios = ServicioUsuarios();
    
    // Si no marcó recordarme, no debe persistir la sesión al lanzar la app (cold boot)
    if (!_sesionComprobada && !recordarme) {
      await servicioUsuarios.cerrarSesion();
    }
    _sesionComprobada = true;

    final token = await servicioUsuarios.obtenerToken();
    if (token != null) {
      _estaLogueado = true;
      _miId = await servicioUsuarios.obtenerIdUsuario();
      _miNombre = await servicioUsuarios.obtenerNombreUsuario();
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
      // Proteger notificaciones y mensajes si no está logueado
      if ((index == 2 || index == 3) && !_estaLogueado) {
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
      const FeedCentral(),
      const PantallaComunidades(), // Explorar Comunidades
      const PantallaNotificaciones(), // Notificaciones
      const Center(child: Text('Mensajes Privados', style: TextStyle(color: Colors.white, fontSize: 24))), // Mensajes
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
                    TopBar(estaLogueado: _estaLogueado, nombreUsuario: _miNombre, miId: _miId),
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
                      name: c.nombre, 
                      imageUrl: c.urlPortada.isNotEmpty ? c.urlPortada : 'https://picsum.photos/100', 
                      level: c.ratingMedio.toStringAsFixed(1)
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

  const _ComunidadItem({required this.name, required this.imageUrl, required this.level});

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
  
  const TopBar({super.key, required this.estaLogueado, this.nombreUsuario, this.miId});

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
                          Navigator.push(context, MaterialPageRoute(builder: (c) => PantallaPerfilUsuario(usuario: res.datos!)));
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
                            nombreUsuario!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF1E1E1E),
                        child: ClipOval(
                          child: Image(
                            image: NetworkImage('https://picsum.photos/103'),
                            fit: BoxFit.cover,
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

// --- FEED CENTRAL ---
class FeedCentral extends StatefulWidget {
  const FeedCentral({super.key});

  @override
  State<FeedCentral> createState() => _FeedCentralState();
}

class _FeedCentralState extends State<FeedCentral> {
  List<Publicacion> _posts = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFeed();
  }

  Future<void> _cargarFeed() async {
    final res = await ServicioComunidades().obtenerPublicacionesGlobales();
    if (mounted) {
      setState(() {
        _posts = res.datos ?? [];
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    
    if (_posts.isEmpty) return Center(child: Text('Nadie ha publicado en comunidades públicas todavía.', style: GoogleFonts.inter(color: Colors.grey)));

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: _posts.map((p) {
          // Extraemos URI completa (Asumiendo que podría llegar ruta relativa del backend)
          List<String> imgs = [];
          if (p.urlArchivoS3.isNotEmpty) {
            imgs.add(p.urlArchivoS3.startsWith('http') ? p.urlArchivoS3 : 'http://127.0.0.1:8000${p.urlArchivoS3}');
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _FeedCard(
              userName: p.autorNombre.isNotEmpty ? p.autorNombre : 'Usuario ${p.autorId}',
              userImage: 'https://picsum.photos/104',
              timeAgo: 'Reciente',
              content: p.contenidoTexto.isNotEmpty ? p.contenidoTexto : p.titulo,
              images: imgs,
              likes: 0, 
              comments: 0,
              communityName: p.comunidadNombre,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String userName;
  final String userImage;
  final String timeAgo;
  final String content;
  final List<String> images;
  final int likes;
  final int comments;

  final String communityName;

  const _FeedCard({
    required this.userName,
    required this.userImage,
    required this.timeAgo,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.communityName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1E1E1E),
                child: ClipOval(
                  child: Image.network(
                    userImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('$timeAgo • $communityName', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido de texto
          if (content.isNotEmpty) ...[
             Text(content, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.5)),
             const SizedBox(height: 16),
          ],
          // Imágenes (Grid mosaico simplificado)
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImageGrid(),
            ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 16),
          // Interacciones
          Row(
            children: [
              _InteractionButton(icon: Icons.favorite_border_rounded, label: likes.toString(), isActive: likes > 0),
              const SizedBox(width: 24),
              _InteractionButton(icon: Icons.chat_bubble_outline_rounded, label: comments.toString()),
              const Spacer(),
              const _InteractionButton(icon: Icons.share_rounded, label: 'Compartir'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (images.length == 1) {
      return Image.network(
        images[0],
        fit: BoxFit.cover,
        width: double.infinity,
        height: 250,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          color: const Color(0xFF121212),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: Image.network(images[0], fit: BoxFit.cover, height: 200, errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF121212), child: const Center(child: Icon(Icons.broken_image))))),
          const SizedBox(width: 8),
          Expanded(child: Image.network(images[1], fit: BoxFit.cover, height: 200, errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF121212), child: const Center(child: Icon(Icons.broken_image))))),
        ],
      );
    } else {
      // 3 o más (Estilo mosaico 2x2)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: images.length > 4 ? 4 : images.length,
        itemBuilder: (context, index) {
          if (index == 3 && images.length > 4) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF121212),
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${images.length - 4}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }
          return Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF121212),
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          );
        },
      );
    }
  }
}

class _InteractionButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isActive;

  const _InteractionButton({required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFF28B50) : Colors.grey;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
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
