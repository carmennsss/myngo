import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolgee/tolgee.dart';
import '../../models/comunidad.dart';
import '../../models/publicacion.dart';
import '../../services/servicio_inicio.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/usuario.dart';
import 'tarjeta_post.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:myngo_app/utils/tr_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_notifier.dart';
import '../toast_service.dart';

enum FeedMode { social, gallery }

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
  
  FeedMode _mode = FeedMode.social;
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
      _posts = null;
      _error = null;
    });

    final res = _mode == FeedMode.social
        ? await _servicio.obtenerFeedSocial(etiquetas: busqueda, limit: 20, offset: 0)
        : await _servicio.obtenerPostsInicio(etiquetas: busqueda, limit: 20, offset: 0);

    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _posts = res.datos ?? [];
          _hayMasPosts = (res.datos?.length ?? 0) >= 20;
          
          if (_mode == FeedMode.gallery) {
            _posts!.sort((a, b) => (b.likesCount + b.comentariosCount).compareTo(a.likesCount + a.comentariosCount));
          } else {
            _posts!.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          }
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  Future<void> _cargarMasPosts() async {
    if (_posts == null || !_hayMasPosts || _cargandoMas) return;
    
    setState(() => _cargandoMas = true);
    
    final res = _mode == FeedMode.social
        ? await _servicio.obtenerFeedSocial(
            etiquetas: _searchController.text.isNotEmpty ? _searchController.text : null,
            limit: 20,
            offset: _posts!.length,
          )
        : await _servicio.obtenerPostsInicio(
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
            for (var p in nuevos) {
              if (!_posts!.any((existente) => existente.id == p.id)) {
                _posts!.add(p);
              }
            }
            _hayMasPosts = nuevos.length >= 20;
          }
        }
      });
    }
  }

  Future<void> _unirseAComunidad(int comunidadId, int index, dynamic tr) async {
    if (!_estaLogueado) {
      ToastService.showWarning(context, tr('communityJoinNeedLogin'));
      return;
    }

    final res = await _servicioComunidades.unirseAComunidad(comunidadId);
    if (res.exito && mounted) {
      ToastService.showInfo(context, tr('communityJoinedMsg'));
      _cargarPosts();
    } else if (mounted) {
      ToastService.showError(context, res.mensaje);
    }
  }

  Widget _buildTabs(dynamic tr) {
    return Row(
      children: [
        _buildTabItem(tr('feedSocialTab'), FeedMode.social),
        const SizedBox(width: 24),
        _buildTabItem(tr('communityTabsGallery'), FeedMode.gallery),
      ],
    );
  }

  Widget _buildTabItem(String label, FeedMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () {
        if (_mode != mode) {
          setState(() {
            _mode = mode;
            _posts = null;
            if (mode == FeedMode.social) {
              _searchController.clear();
            }
          });
          _cargarPosts(busqueda: mode == FeedMode.gallery && _searchController.text.isNotEmpty 
              ? _searchController.text 
              : null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: active ? FontWeight.w900 : FontWeight.w500,
              color: active ? const Color(0xFF4A4440) : Colors.grey,
            ),
          ),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF29C50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleNotifier>();
    return TrWidget(
      builder: (context, tr) {
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PatronFondo(),
                ),
              ),
              RefreshIndicator(
                onRefresh: () => _cargarPosts(busqueda: _searchController.text.isNotEmpty ? _searchController.text : null),
                color: const Color(0xFFF29C50),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTabs(tr),
                            ],
                          ),
                          if (_mode == FeedMode.gallery) ...[
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (valor) => _cargarPosts(busqueda: valor.isNotEmpty ? valor : null),
                                style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                                decoration: InputDecoration(
                                  hintText: tr('messageSearchHint'),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF29C50)),
                                  fillColor: const Color(0xFFF5F5F5),
                                  filled: true,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                                  ? tr('errorNetworkConnection')
                                                  : _error!)
                                              : tr('noGatosMessage'),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                                        ),
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => _cargarPosts(busqueda: _searchController.text.isNotEmpty ? _searchController.text : null),
                                          icon: const Icon(Icons.refresh_rounded),
                                          label: Text(tr('commonRetry')),
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
                                        if (_mode == FeedMode.gallery)
                                          SliverPadding(
                                            padding: const EdgeInsets.all(16.0),
                                            sliver: SliverMasonryGrid.count(
                                              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : (MediaQuery.of(context).size.width < 900 ? 2 : 4),
                                              mainAxisSpacing: 12,
                                              crossAxisSpacing: 12,
                                              childCount: _posts!.length,
                                              itemBuilder: (context, index) {
                                                final post = _posts![index];
                                                return TarjetaPost(
                                                  key: ValueKey('post_grid_${post.id}'),
                                                  post: post,
                                                  contextoVisual: 'galeria',
                                              onJoin: () => _unirseAComunidad(post.comunidadId, index, tr),
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
                                          )
                                        else
                                          SliverPadding(
                                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                                            sliver: SliverList(
                                              delegate: SliverChildBuilderDelegate(
                                                (context, index) {
                                                  final post = _posts![index];
                                                  return Align(
                                                    alignment: Alignment.topCenter,
                                                    child: ConstrainedBox(
                                                      constraints: const BoxConstraints(maxWidth: 650),
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(bottom: 12),
                                                        child: TarjetaPost(
                                                          key: ValueKey('post_list_${post.id}'),
                                                          post: post,
                                                          onJoin: () => _unirseAComunidad(post.comunidadId, index, tr),
                                                          onComunidadSelected: widget.onComunidadSelected,
                                                          onProfileSelected: widget.onProfileSelected,
                                                          onEliminado: () {
                                                            if (mounted) {
                                                              setState(() {
                                                                _posts!.removeWhere((p) => p.id == post.id);
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                childCount: _posts!.length,
                                              ),
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
            ],
          ),
        );
      },
    );
  }
}

class PatronFondo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF29C50).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const spacing = 100.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final offset = (y / spacing).floor() % 2 == 0 ? 0.0 : spacing / 2;
        _drawPaw(canvas, Offset(x + offset, y), paint);
      }
    }
  }

  void _drawPaw(Canvas canvas, Offset center, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 20, height: 16),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawCircle(center.translate(-12, -10), 5, paint);
    canvas.drawCircle(center.translate(-4, -15), 5, paint);
    canvas.drawCircle(center.translate(4, -15), 5, paint);
    canvas.drawCircle(center.translate(12, -10), 5, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
