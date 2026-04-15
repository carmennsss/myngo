import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/comunidad.dart';
import '../../services/servicio_mejoras.dart';

class PantallaEnviarPropuesta extends StatefulWidget {
  final Comunidad comunidad;
  final String? tipoInicial;
  
  const PantallaEnviarPropuesta({super.key, required this.comunidad, this.tipoInicial});

  @override
  State<PantallaEnviarPropuesta> createState() => _PantallaEnviarPropuestaState();
}

class _PantallaEnviarPropuestaState extends State<PantallaEnviarPropuesta> {
  final _precioController = TextEditingController(text: '0');
  late String _tipoSeleccionado;
  File? _imagenSeleccionada;
  Uint8List? _webImageBytes;
  bool _enviando = false;
  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.tipoInicial ?? 'Avatar';
    // Normalizar para que coincida con _tipos (Capitalización)
    if (_tipoSeleccionado.toLowerCase() == 'avatar') _tipoSeleccionado = 'Avatar';
    if (_tipoSeleccionado.toLowerCase() == 'marco') _tipoSeleccionado = 'Marco';
    if (_tipoSeleccionado.toLowerCase() == 'fondo') _tipoSeleccionado = 'Fondo';
  }

  final List<String> _tipos = ['Avatar', 'Marco', 'Fondo'];

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imagenSeleccionada = File(pickedFile.path);
        });
      } else {
        setState(() => _imagenSeleccionada = File(pickedFile.path));
      }
    }
  }

  Future<void> _enviar() async {
    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen')),
      );
      return;
    }

    setState(() => _enviando = true);
    
    final res = await ServicioMejoras().enviarPeticionMejora(
      comunidadId: widget.comunidad.id,
      tipo: _tipoSeleccionado,
      filePath: _imagenSeleccionada!.path,
      bytes: _webImageBytes,
      precioSugerido: int.tryParse(_precioController.text) ?? 0,
    );

    if (mounted) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje),
          backgroundColor: res.exito ? Colors.green : Colors.red,
        ),
      );
      if (res.exito) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      appBar: AppBar(
        title: Text('Sugerir para ${widget.comunidad.nombre}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Comparte tu creatividad con la comunidad. Tu diseño será revisado por los administradores antes de aparecer en la tienda.',
              style: GoogleFonts.outfit(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _enviando ? null : _seleccionarImagen,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8D5C4)),
                ),
                child: _imagenSeleccionada == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 48, color: widget.comunidad.colorTema),
                          const SizedBox(height: 8),
                          Text('Seleccionar diseño', style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: kIsWeb 
                          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                          : Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildTextField('Precio sugerido (opcional)', _precioController, Icons.monetization_on_outlined, isNumber: true),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.comunidad.colorTema,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _enviando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Enviar Propuesta', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: widget.comunidad.colorTema),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tipoSeleccionado,
          isExpanded: true,
          items: _tipos.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (val) => setState(() => _tipoSeleccionado = val!),
        ),
      ),
    );
  }
}
