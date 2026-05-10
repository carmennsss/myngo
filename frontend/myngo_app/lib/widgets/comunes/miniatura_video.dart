import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';


// Miniatura estática de un vídeo para mostrar en grids o listas.
// Carga el primer fotograma del vídeo solo cuando el widget entra en pantalla,
// para no gastar red ni batería con vídeos que el usuario no ve.
class MiniaturaVideo extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const MiniaturaVideo({
    super.key, 
    required this.url, 
    this.fit = BoxFit.cover
  });

  @override
  State<MiniaturaVideo> createState() => _MiniaturaVideoState();
}

class _MiniaturaVideoState extends State<MiniaturaVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _init() async {
    if (_initialized || _cargando || _error) return;

    
    setState(() => _cargando = true);
    
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _controller!.initialize();
      // Nos aseguramos de estar en el segundo 0 o un poco más adelante para evitar frames negros
      await _controller!.seekTo(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _initialized = true;
          _cargando = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _error = true;
          _cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('thumb_${widget.url}'),
      onVisibilityChanged: (info) {
        // Solo inicializar si es visible (al menos un 5%)
        if (info.visibleFraction > 0.05 && !_initialized && !_cargando && !_error) {
          _init();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // El vídeo como fondo (estático, sin play)
            if (_initialized && _controller != null)
              SizedBox.expand(
                child: ClipRect(
                  child: FittedBox(
                    fit: widget.fit,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              ),
            
            // Capa de oscurecimiento suave si está inicializado
            if (_initialized)
              Container(color: Colors.black26),

            // Icono de play distintivo
            const Icon(
              Icons.play_circle_fill_rounded, 
              color: Colors.white, 
              size: 40,
              shadows: [
                Shadow(color: Colors.black45, blurRadius: 10),
              ],
            ),

            if (_cargando)
              const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50))),
            
            if (_error)
              const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 32),
          ],
        ),
      ),
    );
  }
}
