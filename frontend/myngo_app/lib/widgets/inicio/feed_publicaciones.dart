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

  Future<void> _cargarPosts({String? busqueda}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await _servicio.obtenerPostsInicio(etiquetas: busqueda);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _posts = res.datos ?? [];
          _posts.sort((a, b) => (b.likesCount + b.comentariosCount).compareTo(a.likesCount + a.comentariosCount));
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  Future<void> _cargarMasPosts() async {
    if (_posts.length >= 50) return;
    setState(() => _cargandoMas = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _cargandoMas = false);
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
        child: Scrollbar(
          controller: _scrollController,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
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
              ),
              if (_cargando)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF29C50))),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error ?? 'Ocurrió un error', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _cargarPosts(busqueda: _searchController.text.isNotEmpty ? _searchController.text : null),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('REINTENTAR'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Aún no hay publicaciones aquí 😿', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: SliverMasonryGrid.extent(
                    maxCrossAxisExtent: 260, // Hacemos las publicaciones más pequeñas, como en Pinterest
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return TarjetaPost(
                        key: ValueKey('post_${post.id}'),
                        post: post,
                        onJoin: () => _unirseAComunidad(post.comunidadId, index),
                        onComunidadSelected: widget.onComunidadSelected,
                        onProfileSelected: widget.onProfileSelected,
                        onEliminado: () {
                          if (mounted) {
                            setState(() {
                              _posts.removeWhere((p) => p.id == post.id);
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
      ),
    );
  }
}
