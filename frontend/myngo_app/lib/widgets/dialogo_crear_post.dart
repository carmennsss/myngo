import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';

class DialogoCrearPost extends StatefulWidget {
  final String titulo;
  final String? initialTexto;
  final String? initialEtiquetas;
  final Future<bool> Function(String texto, List<XFile>? archivos, String etiquetas) onPublicar;

  const DialogoCrearPost({
    super.key,
    required this.titulo,
    this.initialTexto,
    this.initialEtiquetas,
    required this.onPublicar,
  });

  @override
  State<DialogoCrearPost> createState() => _DialogoCrearPostState();
}

class _DialogoCrearPostState extends State<DialogoCrearPost> {
  late final TextEditingController _controladorTexto;
  late final TextEditingController _controladorEtiquetas;
  List<XFile> _archivosSeleccionados = [];
  bool _estaCargando = false;

  @override
  void initState() {
    super.initState();
    _controladorTexto = TextEditingController(text: widget.initialTexto);
    _controladorEtiquetas = TextEditingController(text: widget.initialEtiquetas);
  }

  Future<void> _validarYAgregarArchivo(XFile archivo) async {
    final bytes = await archivo.length();
    final mb = bytes / (1024 * 1024);
    
    if (mb > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El archivo ${archivo.name} es demasiado grande (${mb.toStringAsFixed(1)} MB). El límite es 100 MB.'),
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
          const SnackBar(content: Text('Máximo 4 archivos por post')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          TextField(
            controller: _controladorTexto,
            maxLines: 4,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: '¿Qué estás pensando, miau?',
              hintStyle: GoogleFonts.inter(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 16),
          if (_archivosSeleccionados.isNotEmpty)
            Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _archivosSeleccionados.map((file) {
                    final esVideo = file.name.toLowerCase().endsWith('.mp4') || 
                                   file.name.toLowerCase().endsWith('.mov') ||
                                   file.name.toLowerCase().endsWith('.avi');
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
                          child: esVideo ? const Center(child: Icon(Icons.videocam_rounded, color: Colors.white, size: 40)) : null,
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
                const SizedBox(height: 16),
                TextField(
                  controller: _controladorEtiquetas,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Etiquetas (ej. arte, animales, juegos...)',
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
                tooltip: 'Subir imágenes',
                icon: const Icon(Icons.image_search_rounded, color: Color(0xFFF29C50)),
              ),
              IconButton(
                onPressed: () async {
                  final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    await _validarYAgregarArchivo(video);
                  }
                },
                tooltip: 'Subir vídeo',
                icon: const Icon(Icons.videocam_outlined, color: Color(0xFFF29C50)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _estaCargando ? null : () async {
                  setState(() => _estaCargando = true);
                  final exitoso = await widget.onPublicar(
                    _controladorTexto.text,
                    _archivosSeleccionados,
                    _controladorEtiquetas.text,
                  );
                  if (mounted) {
                    if (exitoso) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _estaCargando = false);
                      final error = Provider.of<PostProvider>(context, listen: false).errorMessage ?? 'Error al publicar';
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.initialTexto != null ? 'Guardar Cambios' : 'Publicar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
