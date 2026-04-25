import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../services/servicio_inicio.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/usuario.dart';
import 'tarjeta_post.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../comunes/estado_vacio_cargando.dart';

class FeedPublicaciones extends StatefulWidget {
  final Function(Comunidad)? onComunidadSelected;
  final Function(Usuario)? onProfileSelected;

  const FeedPublicaciones({super.key, this.onComunidadSelected, this.onProfileSelected});

  @override
  State<FeedPublicaciones> createState() => _FeedPublicacionesState();
}

class _FeedPublicacionesState extends State<FeedPublicaciones> {
  final _servicio = ServicioInicio();
  final _servicioComunidades = ServicioComunidades();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Publicacion>? _posts;
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _estaLogueado = false;
  bool _hayMasPosts = true;
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!_cargandoMas && !_cargando && _hayMasPosts) {
        _cargarMasPosts();
      }
    }
  }

  Future<void> _cargarPosts({String? busqueda}) async {
    setState(() {
      _cargando = true;
      _posts = null; // Reiniciamos a null según la nueva lógica
      _error = null;
    });
    final res = await _servicio.obtenerPostsInicio(etiquetas: busqueda, limit: 20, offset: 0);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _posts = res.datos ?? [];
          // Si recibimos menos del límite, es que no hay más
          _hayMasPosts = (res.datos?.length ?? 0) >= 20;
          // Ordenamos por relevancia (likes + comentarios)
          _posts!.sort((a, b) => (b.likesCount + b.comentariosCount).compareTo(a.likesCount + a.comentariosCount));
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  Future<void> _cargarMasPosts() async {
    if (_posts == null || !_hayMasPosts || _cargandoMas) return;
    
    setState(() => _cargandoMas = true);
    
    final res = await _servicio.obtenerPostsInicio(
      etiquetas: _searchController.text.isNotEmpty ? _searchController.text : null,
      limit: 20,
      offset: _posts!.length,
    );
    
    if (mounted) {
      setState(() {
        _cargandoMas = false;
        if (res.exito && res.datos != null) {
          final nuevos = res.datos!;
          if (nuevos.isEmpty) {
            _hayMasPosts = false;
          } else {
            // Evitar duplicados por si acaso
            for (var p in nuevos) {
              if (!_posts!.any((existente) => existente.id == p.id)) {
                _posts!.add(p);
              }
            }
            _hayMasPosts = nuevos.length >= 20;
            // No reordenamos todo para no saltar el scroll, solo las nuevas si acaso, 
            // pero el backend ya debería dar un orden consistente si no es random.
          }
        }
      });
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Miau-unido con éxito! 🐾', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF248EA6),
        behavior: SnackBarBehavior.floating,
      ));
      _cargarPosts();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje), backgroundColor: const Color(0xFFD95F43)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _cargarPosts(busqueda: _searchController.text.isNotEmpty ? _searchController.text : null),
        color: const Color(0xFFF29C50),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Galería', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onSubmitted: (valor) => _cargarPosts(busqueda: valor.isNotEmpty ? valor : null),
                    style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                    decoration: InputDecoration(
                      hintText: 'Busca en el universo Myngo... 🐾',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF29C50)),
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: (_cargando || _posts == null)
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF29C50)))
                  : (_error != null || _posts!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _error != null ? Icons.wifi_off_rounded : Icons.search_off_rounded,
                                size: 80,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  _error != null 
                                      ? (_error!.contains('Tiempo de espera') 
                                          ? '¡Miau! No hemos podido conectar a tiempo 😿\nRevisa tu conexión e inténtalo de nuevo.'
                                          : _error!)
                                      : 'Aún no hay publicaciones aquí 😿',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _cargarPosts(busqueda: _searchController.text.isNotEmpty ? _searchController.text : null),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('REINTENTAR'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF29C50),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                          : CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.all(16.0),
                                  sliver: SliverMasonryGrid.count(
                                    crossAxisCount: MediaQuery.of(context).size.width < 900 ? 2 : 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childCount: _posts!.length,
                                    itemBuilder: (context, index) {
                                      final post = _posts![index];
                                      return TarjetaPost(
                                        key: ValueKey('post_${post.id}'),
                                        post: post,
                                        onJoin: () => _unirseAComunidad(post.comunidadId, index),
                                        onComunidadSelected: widget.onComunidadSelected,
                                        onProfileSelected: widget.onProfileSelected,
                                        onEliminado: () {
                                          if (mounted) {
                                            setState(() {
                                              _posts!.removeWhere((p) => p.id == post.id);
                                            });
                                          }
                                        },
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
            ),
          ],
        ),
      ),
    );
  }
}
