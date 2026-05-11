import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import 'package:tolgee/tolgee.dart';
import '../providers/post_provider.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class DialogoCrearPost extends StatefulWidget {
  final String titulo;
  final String? initialTitulo;
  final String? initialTexto;
  final String? initialEtiquetas;
  final Future<bool> Function(String titulo, String texto, List<XFile>? archivos, String etiquetas, {void Function(int, int)? alProgresar}) onPublicar;

  const DialogoCrearPost({
    super.key,
    required this.titulo,
    this.initialTitulo,
    this.initialTexto,
    this.initialEtiquetas,
    required this.onPublicar,
  });

  @override
  State<DialogoCrearPost> createState() => _DialogoCrearPostState();
}

class _DialogoCrearPostState extends State<DialogoCrearPost> {
  late final TextEditingController _controladorTitulo;
  late final TextEditingController _controladorTexto;
  late final TextEditingController _controladorEtiquetas;
  List<XFile> _archivosSeleccionados = [];
  bool _estaCargando = false;
  double _progresoSubida = 0;

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController(text: widget.initialTitulo);
    _controladorTexto = TextEditingController(text: widget.initialTexto);
    _controladorEtiquetas = TextEditingController(text: widget.initialEtiquetas);
    _controladorTexto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorTexto.dispose();
    _controladorEtiquetas.dispose();
    super.dispose();
  }

  Future<void> _validarYAgregarArchivo(XFile archivo) async {
    final bytes = await archivo.length();
    final mb = bytes / (1024 * 1024);
    
    if (mb > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('postFileTooLarge', {
              'name': archivo.name,
              'size': mb.toStringAsFixed(1),
              'limit': '100'
            })),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() {
      if (_archivosSeleccionados.length < 4) {
        _archivosSeleccionados.add(archivo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('postMaxFilesError'))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, 
            left: 24, right: 24, top: 24
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.titulo, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _controladorTitulo,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: tr('postTitleHint'),
                          hintStyle: GoogleFonts.inter(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controladorTexto,
                        maxLines: 4,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: tr('postHint'),
                          hintStyle: GoogleFonts.inter(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_archivosSeleccionados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _archivosSeleccionados.map((file) {
                              final mimeType = lookupMimeType(file.name) ?? (file.path.contains('video') ? 'video/mp4' : 'image/jpeg');
                              final esVideo = mimeType.startsWith('video/');
                              return Stack(
                                children: [
                                  Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                      image: esVideo ? null : DecorationImage(
                                        image: kIsWeb 
                                            ? NetworkImage(file.path) as ImageProvider
                                            : FileImage(File(file.path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: esVideo ? _VideoPreview(file: file) : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _archivosSeleccionados.remove(file);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      TextField(
                        controller: _controladorEtiquetas,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: tr('tagsHint'),
                          hintStyle: GoogleFonts.inter(color: Colors.grey),
                          prefixIcon: const Icon(Icons.sell_outlined, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final imgs = await ImagePicker().pickMultiImage();
                      if (imgs.isNotEmpty) {
                        for (var img in imgs) {
                          await _validarYAgregarArchivo(img);
                        }
                      }
                    },
                    tooltip: tr('uploadImagesTooltip'),
                    icon: const Icon(Icons.image_search_rounded, color: Color(0xFFF29C50)),
                  ),
                  IconButton(
                    onPressed: () async {
                      final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                      if (video != null) {
                        await _validarYAgregarArchivo(video);
                      }
                    },
                    tooltip: tr('uploadVideoTooltip'),
                    icon: const Icon(Icons.videocam_outlined, color: Color(0xFFF29C50)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_estaCargando || _controladorTexto.text.trim().isEmpty && _archivosSeleccionados.isEmpty) ? null : () async {
                      setState(() {
                        _estaCargando = true;
                        _progresoSubida = 0;
                      });
                      final exitoso = await widget.onPublicar(
                        _controladorTitulo.text,
                        _controladorTexto.text,
                        _archivosSeleccionados,
                        _controladorEtiquetas.text,
                        alProgresar: (enviado, total) {
                          if (total > 0) {
                            setState(() {
                              _progresoSubida = enviado / total;
                            });
                          }
                        },
                      );
                      if (mounted) {
                        if (exitoso) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _estaCargando = false);
                          final error = Provider.of<PostProvider>(context, listen: false).errorMessage ?? tr('errorActionFailed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28B50), 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _estaCargando 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: _progresoSubida > 0 ? _progresoSubida : null,
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_progresoSubida * 100).toInt()}%',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(widget.initialTexto != null ? tr('commonSaveChanges') : tr('commonPublish'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final XFile file;
  const _VideoPreview({required this.file});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb 
        ? VideoPlayerController.networkUrl(Uri.parse(widget.file.path))
        : VideoPlayerController.file(File(widget.file.path));
    
    _controller.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
