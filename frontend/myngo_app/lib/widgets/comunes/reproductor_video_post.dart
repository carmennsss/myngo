import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';


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
      VideoFormat? formatHint;

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        formatHint: formatHint,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      _videoController.addListener(() {
        if (_videoController.value.hasError && !_error) {
          if (mounted) setState(() => _error = true);
        }
      });

      await _videoController.initialize();
      
      if (!mounted) return;



      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: widget.loop,
        aspectRatio: _videoController.value.aspectRatio > 0 
            ? _videoController.value.aspectRatio 
            : 16 / 9,
        showControls: true,
        autoInitialize: true,
        allowedScreenSleep: false,
        errorBuilder: (context, errorMessage) {

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
                const SizedBox(height: 8),
                Text(errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() { _initialized = false; _error = false; });
                    _initializePlayer();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF28B50), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          );
        },
        placeholder: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50))),
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

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {

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
    
    if (visibleFraction > 0.6) {
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
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
              const SizedBox(height: 8),
              Text(
                'No se pudo cargar el vídeo\n${_videoController.value.errorDescription ?? "Error de formato o red"}', 
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() { _error = false; _initialized = false; });
                  _initializePlayer();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF28B50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.transparent,
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
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(

              width: 1000,
              height: 1000 / (_chewieController?.aspectRatio ?? _videoController.value.aspectRatio).clamp(0.1, 10.0),
              child: Chewie(controller: _chewieController!),
            ),
          ),
        ),
      ),
    );
  }
}
