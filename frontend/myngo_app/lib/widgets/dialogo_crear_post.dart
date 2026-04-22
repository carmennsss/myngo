import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DialogoCrearPost extends StatefulWidget {
  final String titulo;
  final Future<bool> Function(String texto, List<XFile>? imagenes, String etiquetas) onPublicar;

  const DialogoCrearPost({
    super.key,
    required this.titulo,
    required this.onPublicar,
  });

  @override
  State<DialogoCrearPost> createState() => _DialogoCrearPostState();
}

class _DialogoCrearPostState extends State<DialogoCrearPost> {
  final _controladorTexto = TextEditingController();
  final _controladorEtiquetas = TextEditingController();
  List<XFile> _imagenesSeleccionadas = [];
  bool _estaCargando = false;

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
          if (_imagenesSeleccionadas.isNotEmpty)
            Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imagenesSeleccionadas.map((img) {
                    return Stack(
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: kIsWeb 
                                  ? NetworkImage(img.path) as ImageProvider
                                  : FileImage(File(img.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _imagenesSeleccionadas.remove(img);
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
                  if (_imagenesSeleccionadas.length >= 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Máximo 4 imágenes')),
                    );
                    return;
                  }
                  final imgs = await ImagePicker().pickMultiImage();
                  if (imgs.isNotEmpty) {
                    setState(() {
                      _imagenesSeleccionadas.addAll(imgs);
                      if (_imagenesSeleccionadas.length > 4) {
                        _imagenesSeleccionadas = _imagenesSeleccionadas.sublist(0, 4);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Se ha limitado a 4 imágenes')),
                        );
                      }
                    });
                  }
                },
                icon: const Icon(Icons.image_search_rounded, color: Color(0xFFF29C50)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _estaCargando ? null : () async {
                  setState(() => _estaCargando = true);
                  final exitoso = await widget.onPublicar(
                    _controladorTexto.text,
                    _imagenesSeleccionadas,
                    _controladorEtiquetas.text,
                  );
                  if (mounted) {
                    if (exitoso) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _estaCargando = false);
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
                  : Text('Publicar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
