import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/mensaje_chat.dart';

/// Widget para mostrar una cuadrícula de archivos seleccionados antes de enviar.
class MediaPreviewGrid extends StatelessWidget {
  final List<XFile> files;
  final Function(int) onRemove;

  const MediaPreviewGrid({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      height: files.length > 2 ? 200 : 120,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: files.length > 2 ? 2 : 1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isVideo = file.name.toLowerCase().endsWith('.mp4') || 
                          file.name.toLowerCase().endsWith('.mov') ||
                          file.name.toLowerCase().endsWith('.webm');

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: isVideo
                      ? const Center(child: Icon(Icons.videocam, color: Colors.blue))
                      : kIsWeb
                          ? Image.network(file.path, fit: BoxFit.cover)
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget para mostrar la cuadrícula de medios dentro de una burbuja de chat.
class ChatMediaGrid extends StatelessWidget {
  final List<ChatAttachment> attachments;
  final bool esMio;

  const ChatMediaGrid({
    super.key,
    required this.attachments,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final count = attachments.length;
    
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: count > 1 ? _buildCarousel(context) : _buildItem(context, attachments[0]),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              return _buildItem(context, attachments[index], height: 250);
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${attachments.length} fotos • Desliza',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildItem(BuildContext context, ChatAttachment att, {double? height}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatMediaLightbox(
              attachments: attachments,
              initialIndex: attachments.indexOf(att),
            ),
          ),
        );
      },
      child: SizedBox(
        height: height ?? 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (att.url.isEmpty)
              Container(
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              )
            else
              CachedNetworkImage(
                imageUrl: att.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            if (att.isVideo)
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de visualización a pantalla completa (Lightbox).
class ChatMediaLightbox extends StatefulWidget {
  final List<ChatAttachment> attachments;
  final int initialIndex;

  const ChatMediaLightbox({
    super.key,
    required this.attachments,
    required this.initialIndex,
  });

  @override
  State<ChatMediaLightbox> createState() => _ChatMediaLightboxState();
}

class _ChatMediaLightboxState extends State<ChatMediaLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.attachments.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final att = widget.attachments[index];
          if (att.url.isEmpty) {
            return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64));
          }
          if (att.isVideo) {
            return ChatVideoPlayer(url: att.url);
          } else {
            return InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: att.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Reproductor de vídeo para el chat.
class ChatVideoPlayer extends StatefulWidget {
  final String url;

  const ChatVideoPlayer({super.key, required this.url});

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.url.isEmpty) return;
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_chewieController!.videoPlayerController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController!);
  }
}
