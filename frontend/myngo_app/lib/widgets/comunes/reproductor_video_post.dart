import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Controlador global para asegurar que solo un vídeo se reproduzca a la vez.
class GlobalVideoManager {
  static VideoPlayerController? _activeController;

  static void pauseOther(VideoPlayerController newController) {
    if (_activeController != null && _activeController != newController) {
      _activeController!.pause();
    }
    _activeController = newController;
  }

  static void release(VideoPlayerController controller) {
    if (_activeController == controller) {
      _activeController = null;
    }
  }
}

class ReproductorVideoPost extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final bool loop;
  final bool muted;

  const ReproductorVideoPost({
    super.key,
    required this.url,
    this.autoPlay = true,
    this.loop = true,
    this.muted = true,
  });

  @override
  State<ReproductorVideoPost> createState() => _ReproductorVideoPostState();
}

class _ReproductorVideoPostState extends State<ReproductorVideoPost> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController.initialize();
      
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false, // Controlado por VisibilityDetector
        looping: widget.loop,
        aspectRatio: _videoController.value.aspectRatio,
        showControls: true,
        autoInitialize: true,
        allowedScreenSleep: false,
        placeholder: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        // Estilo personalizado
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFF28B50),
          handleColor: const Color(0xFFF28B50),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white30,
        ),
      );

      if (widget.muted) {
        await _videoController.setVolume(0);
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint("Error inicializando reproductor de vídeo: $e");
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    GlobalVideoManager.release(_videoController);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted || !_initialized || _error) return;

    final double visibleFraction = info.visibleFraction;
    
    if (visibleFraction > 0.6) { // Si más del 60% es visible
      if (widget.autoPlay && !_videoController.value.isPlaying) {
        GlobalVideoManager.pauseOther(_videoController);
        _videoController.play();
      }
    } else {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
              SizedBox(height: 8),
              Text('No se pudo cargar el vídeo', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50), strokeWidth: 2),
        ),
      );
    }

    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Container(
        color: Colors.black,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
