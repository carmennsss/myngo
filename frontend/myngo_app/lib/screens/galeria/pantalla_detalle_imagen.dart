import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import '../../models/imagen_galeria.dart';
import '../../services/servicio_galeria.dart';
import '../../services/servicio_comunidades.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../utils/gestor_descargas.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class PantallaDetalleImagen extends StatefulWidget {
  final ImagenGaleria imagen;

  const PantallaDetalleImagen({Key? key, required this.imagen}) : super(key: key);

  @override
  State<PantallaDetalleImagen> createState() => _PantallaDetalleImagenState();
}

class _PantallaDetalleImagenState extends State<PantallaDetalleImagen> {
  final ServicioGaleria _servicioGaleria = ServicioGaleria();
  final ServicioComunidades _servicioComunidades = ServicioComunidades();
  
  bool _cargandoMetadatos = true;
  Map<String, dynamic>? _metadatos;
  bool _estaUniendose = false;
  late bool _esMiembro;

  @override
  void initState() {
    super.initState();
    _esMiembro = widget.imagen.usuarioEsMiembro;
    _cargarDetalles();
  }

  Future<void> _descargarArchivo(dynamic tr) async {
    try {
      await GestorDescargas.descargar(widget.imagen.urlArchivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('moderationError'))),
        );
      }
    }
  }

  Future<void> _cargarDetalles() async {
    final res = await _servicioGaleria.obtenerDetalleImagenExtendido(widget.imagen.id);
    if (mounted && res.exito) {
      setState(() {
        _metadatos = res.datos;
        _cargandoMetadatos = false;
      });
    } else if (mounted) {
      setState(() => _cargandoMetadatos = false);
    }
  }

  Future<void> _unirseAComunidad() async {
    if (widget.imagen.comunidadId == null) return;
    
    setState(() => _estaUniendose = true);
    final res = await _servicioComunidades.unirseAComunidad(widget.imagen.comunidadId!);
    
    if (mounted) {
      setState(() {
        _estaUniendose = false;
        if (res.exito) _esMiembro = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje, style: GoogleFonts.outfit()),
          backgroundColor: res.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Visor de la imagen central interactiva de Zoom
            // Visor de contenido (Imagen o Vídeo)
            Center(
              child: widget.imagen.tipoArchivo == 'V'
                  ? _VideoDetalle(url: widget.imagen.urlArchivo)
                  : InteractiveViewer(
                      minScale: 0.1,
                      maxScale: 6.0,
                      child: CachedNetworkImage(
                        imageUrl: widget.imagen.urlArchivo,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50))),
                        errorWidget: (c, u, e) => const Center(child: Icon(Icons.error_outline, color: Colors.white24, size: 48)),
                      ),
                    ),
            ),
            
            // AppBar superpuesta transparente para volver
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                     IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                      tooltip: tr('collectionDownloadFile'),
                      onPressed: () => _descargarArchivo(tr),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            // Bottom Panel
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildPanelInformacion(tr),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPanelInformacion(dynamic tr) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Autor y Fecha
          GestureDetector(
            onTap: () {
              if (widget.imagen.propietarioNombre != null && widget.imagen.propietarioNombre!.isNotEmpty) {
                context.go('/explorar/perfiles/${widget.imagen.propietarioNombre}');
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF248EA6).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF248EA6), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.imagen.propietarioNombre ?? 'Desconocido'}',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(
                      tr('gallerySubidoEl', {'date': widget.imagen.fechaSubida.toLocal().toString().split(' ')[0]}),
                      style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                // Community Tag
                if (widget.imagen.comunidadNombre != null)
                  _buildCommunityTag(tr),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_cargandoMetadatos)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: LinearProgressIndicator(color: Color(0xFFF28B50), backgroundColor: Colors.white10),
            ))
          else ..._buildSeccionesMetadatos(tr),
        ],
      ),
    );
  }

  Widget _buildCommunityTag(dynamic tr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF28B50).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_rounded, color: Color(0xFFF28B50), size: 14),
          const SizedBox(width: 8),
          Text(
            widget.imagen.comunidadNombre!,
            style: GoogleFonts.outfit(color: const Color(0xFFF28B50), fontWeight: FontWeight.w900, fontSize: 12),
          ),
          if (!_esMiembro && widget.imagen.comunidadId != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _estaUniendose ? null : _unirseAComunidad,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF28B50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _estaUniendose 
                  ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr('communityJoin').toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSeccionesMetadatos(dynamic tr) {
    final List<Widget> widgets = [];
    
    // Post mapping
    if (_metadatos != null && _metadatos!['publicacion'] != null) {
      final pub = _metadatos!['publicacion'];
      widgets.add(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.article_rounded, color: Color(0xFFF28B50), size: 16),
                  const SizedBox(width: 8),
                  Text(tr('galleryLinkedPost'), style: GoogleFonts.outfit(color: const Color(0xFFF28B50), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 12),
              Text(pub['titulo'] ?? tr('notificationNoTitle'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              if (pub['contenido_texto'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  pub['contenido_texto'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Collections mapping
    if (_metadatos != null && _metadatos!['colecciones'] != null) {
      final List colList = _metadatos!['colecciones'];
      if (colList.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(tr('galleryInFolders'), style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ));
        widgets.add(const SizedBox(height: 12));
        widgets.add(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colList.map((c) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF248EA6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF248EA6).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c['privada'] == true ? Icons.lock_rounded : Icons.folder_rounded, color: const Color(0xFF248EA6), size: 16),
                      const SizedBox(width: 8),
                      Text(c['nombre'] ?? tr('galleryFolder'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _VideoDetalle extends StatefulWidget {
  final String url;
  const _VideoDetalle({required this.url});

  @override
  State<_VideoDetalle> createState() => _VideoDetalleState();
}

class _VideoDetalleState extends State<_VideoDetalle> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoController.value.aspectRatio,
            materialProgressColors: ChewieProgressColors(
              playedColor: const Color(0xFFF28B50),
              handleColor: const Color(0xFFF28B50),
              backgroundColor: Colors.white24,
              bufferedColor: Colors.white38,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
  }
}
