import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable Twitter/X style image grid for posts.
class GridImagenesPost extends StatefulWidget {
  final List<String> urls;
  final VoidCallback? onTap;

  const GridImagenesPost({
    super.key,
    required this.urls,
    this.onTap,
  });

  @override
  State<GridImagenesPost> createState() => _GridImagenesPostState();
}

class _GridImagenesPostState extends State<GridImagenesPost> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 800;
    // Reducimos las alturas máximas para que no ocupen toda la pantalla en el feed
    final maxHeight = isMobile ? 220.0 : 340.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.black.withOpacity(0.03),
        child: AspectRatio(
          aspectRatio: 1.5, // Más horizontal para que la imagen se vea completa y ocupe menos vertical
          child: Stack(
            children: [
              if (widget.urls.length == 1)
                _GridImageItem(url: widget.urls[0])
              else
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.urls.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _GridImageItem(url: widget.urls[index]),
                ),
              
              // El indicador de página e indicadores visuales
              if (widget.urls.length > 1) ...[
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${widget.urls.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Puntos indicadores inferiores
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.urls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentPage == index ? 12 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPage == index
                              ? const Color(0xFFF28B50)
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),

                // Flechas de navegación (solo Desktop para facilitar el uso)
                if (!isMobile) ...[
                  if (_currentPage > 0)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _BotonNavegacion(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage < widget.urls.length - 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _BotonNavegacion(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridImageItem extends StatelessWidget {
  final String url;
  const _GridImageItem({required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo desenfocado para las zonas vacías (efecto premium)
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        // Imagen principal completa
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain, // Se ve completa sin cortes
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50)),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade900,
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _BotonNavegacion extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BotonNavegacion({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

