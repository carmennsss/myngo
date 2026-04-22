import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable Twitter/X style image grid for posts.
class GridImagenesPost extends StatelessWidget {
  final List<String> urls;
  final VoidCallback? onTap;

  const GridImagenesPost({
    super.key,
    required this.urls,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 800;
    final maxHeight = isMobile ? 290.0 : 510.0;

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: urls.length == 1 ? 1.8 : 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildGridStructure(urls),
          ),
        ),
      ),
    );
  }

  Widget _buildGridStructure(List<String> urls) {
    if (urls.length == 1) {
      return _GridImageItem(url: urls[0]);
    }

    if (urls.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _GridImageItem(url: urls[0])),
          const SizedBox(width: 2),
          Expanded(child: _GridImageItem(url: urls[1])),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _GridImageItem(url: urls[0])),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _GridImageItem(url: urls[1])),
                const SizedBox(height: 2),
                Expanded(child: _GridImageItem(url: urls[2])),
              ],
            ),
          ),
        ],
      );
    }

    // 4 or more images
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GridImageItem(url: urls[0])),
              const SizedBox(width: 2),
              Expanded(child: _GridImageItem(url: urls[1])),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GridImageItem(url: urls[2])),
              const SizedBox(width: 2),
              Expanded(
                child: urls.length > 4 
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        _GridImageItem(url: urls[3]),
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Text(
                              '+${urls.length - 3}', 
                              style: GoogleFonts.outfit(
                                color: Colors.white, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 24
                              )
                            ),
                          ),
                        ),
                      ],
                    )
                  : _GridImageItem(url: urls[3]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridImageItem extends StatelessWidget {
  final String url;
  const _GridImageItem({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200, 
        child: const Icon(Icons.broken_image_rounded, color: Colors.grey)
      ),
    );
  }
}
