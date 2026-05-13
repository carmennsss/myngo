import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/comunidad.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_usuarios.dart';
import 'package:myngo_app/utils/tr_helper.dart';
import '../../widgets/toast_service.dart';

// Formulario para que un miembro proponga (o el creador añada directamente)
// una nueva mejora visual a la tienda de la comunidad.
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
    

    final String initial = widget.tipoInicial ?? 'Avatar';
    if (_tipos.contains(initial)) {
      _tipoSeleccionado = initial;
    } else {

      if (initial.toLowerCase() == 'avatar') _tipoSeleccionado = 'Avatar';
      else if (initial.toLowerCase() == 'marco') _tipoSeleccionado = 'Marco';
      else if (initial.toLowerCase() == 'fondo') _tipoSeleccionado = 'Fondo';
      else _tipoSeleccionado = 'Avatar';
    }
  }

  final List<String> _tipos = ['Avatar', 'Marco', 'Fondo'];

  // Abre la galería del dispositivo y guarda el archivo seleccionado
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

  // Valida que haya imagen y envía la propuesta o la añade directamente si es el creador
  Future<void> _enviar() async {
    if (_imagenSeleccionada == null) {
      ToastService.showInfo(context, tr('proposalSelectImageError'));
      return;
    }


    setState(() => _enviando = true);
    
    final res = await ServicioMejoras().enviarPropuestaMejora(
      idComunidad: widget.comunidad.id,
      tipoArticulo: _tipoSeleccionado,
      rutaArchivo: _imagenSeleccionada!.path,
      bytesWeb: _webImageBytes,
      precioSugerido: int.tryParse(_precioController.text) ?? 0,
    );

    if (mounted) {
      setState(() => _enviando = false);
      if (res.exito) {
        ToastService.showSuccess(context, res.mensaje);
      } else {
        ToastService.showError(context, res.mensaje);
      }
      if (res.exito) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<int?>(
      future: ServicioUsuarios().obtenerIdUsuario(),
      builder: (context, snapshot) {
        return Builder(
      builder: (context) {
            final bool esCreador = snapshot.data != null && snapshot.data == widget.comunidad.creadorId;
            
            return Scaffold(
              backgroundColor: const Color(0xFFFEF5F1),
              appBar: AppBar(
                title: Text(
                  esCreador 
                    ? tr('proposalAddTitle', {'name': widget.comunidad.nombre}) 
                    : tr('proposalSuggestTitle', {'name': widget.comunidad.nombre}), 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)
                ),
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
                      esCreador 
                        ? tr('proposalCreatorDesc')
                        : tr('proposalMemberDesc'),
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
                                  Text(tr('proposalSelectDesign'), style: GoogleFonts.outfit(color: Colors.grey)),
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
                    _buildDropdown(tr),
                    const SizedBox(height: 16),
                    _buildTextField(
                      esCreador ? tr('proposalPriceLabel') : tr('proposalSuggestedPriceLabel'), 
                      _precioController, 
                      Icons.monetization_on_outlined, 
                      isNumber: true
                    ),
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
                          : Text(
                              esCreador ? tr('proposalAddBtn') : tr('proposalSuggestBtn'), 
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                    ),
                  ],
                ),
              ),
            );
          }
        );

      }
    );
  }

  // Campo de texto genérico con estilo coherente al resto del formulario
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

  // Selector de tipo de mejora (Avatar / Marco / Fondo)
  Widget _buildDropdown(String Function(String) tr) {
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
          items: _tipos.map((type) {
            String label = type;
            if (type == 'Avatar') label = tr('commonAvatar');
            else if (type == 'Marco') label = tr('commonFrame');
            else if (type == 'Fondo') label = tr('commonBackground');
            return DropdownMenuItem(value: type, child: Text(label));
          }).toList(),
          onChanged: (val) => setState(() => _tipoSeleccionado = val!),
        ),
      ),
    );
  }

}
