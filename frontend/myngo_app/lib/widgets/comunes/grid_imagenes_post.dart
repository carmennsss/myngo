import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Reusable Twitter/X style media grid for posts (Images and Videos).
class GridImagenesPost extends StatefulWidget {
  final List<Map<String, String>> media;
  final VoidCallback? onTap;

  const GridImagenesPost({
    super.key,
    required this.media,
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
    if (widget.media.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 800;
    final maxHeight = isMobile ? 220.0 : 340.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.black.withOpacity(0.03),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            children: [
              if (widget.media.length == 1)
                _GridMediaItem(
                  url: widget.media[0]['url']!, 
                  tipo: widget.media[0]['tipo'] ?? 'I'
                )
              else
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.media.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _GridMediaItem(
                    url: widget.media[index]['url']!, 
                    tipo: widget.media[index]['tipo'] ?? 'I'
                  ),
                ),
              
              if (widget.media.length > 1) ...[
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
                      '${_currentPage + 1}/${widget.media.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.media.length,
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
                  if (_currentPage < widget.media.length - 1)
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

class _GridMediaItem extends StatefulWidget {
  final String url;
  final String tipo;
  const _GridMediaItem({required this.url, required this.tipo});

  @override
  State<_GridMediaItem> createState() => _GridMediaItemState();
}

class _GridMediaItemState extends State<_GridMediaItem> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.tipo == 'V') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: false,
              looping: false,
              aspectRatio: _videoController!.value.aspectRatio,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, errorMessage) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      Text('Error: $errorMessage', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                );
              },
            );
          });
        }
      }).catchError((error) {
        debugPrint("Error inicializando video: $error");
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tipo == 'V') {
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      SizedBox(height: 12),
                      Icon(Icons.videocam_rounded, color: Colors.white54, size: 32),
                    ],
                  ),
            
            // Overlay de carga/error
            if (_videoController != null && _videoController!.value.hasError)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo cargar el vídeo',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Indicador de vídeo (si no está reproduciendo)
            if (_chewieController != null && 
                _chewieController!.videoPlayerController.value.isInitialized &&
                !_chewieController!.videoPlayerController.value.isPlaying)
              IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              debugPrint("Error cargando fondo de imagen ($url): $error");
              return const SizedBox.shrink();
            },
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50)),
          ),
          errorWidget: (context, url, error) {
            debugPrint("Error cargando imagen principal ($url): $error");
            return Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar imagen',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
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
