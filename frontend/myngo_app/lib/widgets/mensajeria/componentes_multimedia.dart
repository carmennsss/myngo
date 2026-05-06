import 'dart:io';
import 'package:flutter/material.dart';
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
      constraints: const BoxConstraints(maxWidth: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildGrid(context, count),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, int count) {
    if (count == 1) {
      return _buildItem(context, attachments[0]);
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildItem(context, attachments[0])),
          const SizedBox(width: 2),
          Expanded(child: _buildItem(context, attachments[1])),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(child: _buildItem(context, attachments[0])),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                _buildItem(context, attachments[1], height: 100),
                const SizedBox(height: 2),
                _buildItem(context, attachments[2], height: 100),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildItem(context, attachments[0], height: 100)),
              const SizedBox(width: 2),
              Expanded(child: _buildItem(context, attachments[1], height: 100)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _buildItem(context, attachments[2], height: 100)),
              const SizedBox(width: 2),
              Expanded(child: _buildItem(context, attachments[3], height: 100)),
            ],
          ),
        ],
      );
    }
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
          if (att.isVideo) {
            return ChatVideoPlayer(url: att.url);
          } else {
            return InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: att.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
