import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';
import '../../../widgets/campo_texto_personalizado.dart';

import '../../../widgets/boton_carga.dart';
import '../../../services/servicio_comunidades.dart';
import '../../../models/comunidad.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myngo_app/utils/tr_helper.dart';

/// Modal para la creación de nuevas comunidades.
class FormularioCreacionComunidad extends StatefulWidget {
  final VoidCallback alConfirmar;

  const FormularioCreacionComunidad({super.key, required this.alConfirmar});

  @override
  State<FormularioCreacionComunidad> createState() => _FormularioCreacionComunidadState();
}

class _FormularioCreacionComunidadState extends State<FormularioCreacionComunidad> {
  final _llaveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _nodoNombre = FocusNode();
  final _nodoDescripcion = FocusNode();
  
  bool _esPublica = true;
  double _minRating = 0.0;
  XFile? _imagenSeleccionada;
  final _estaCargando = ValueNotifier<bool>(false);
  final _servicio = ServicioComunidades();
  final _picker = ImagePicker();

  final _controladorTag = TextEditingController();
  final List<String> _tagsSeleccionados = [];
  List<Map<String, dynamic>> _sugerenciasTags = [];
  bool _mostrandoSugerencias = false;

  Future<void> _buscarSugerencias(String query) async {
    if (query.isEmpty) {
      setState(() {
        _sugerenciasTags = [];
        _mostrandoSugerencias = false;
      });
      return;
    }
    final respuesta = await _servicio.buscarTags(query: query);
    if (respuesta.exito && mounted) {
      setState(() {
        _sugerenciasTags = respuesta.datos ?? [];
        _mostrandoSugerencias = _sugerenciasTags.isNotEmpty;
      });
    }
  }

  void _anadirTag(String nombre) {
    final limpio = nombre.trim().toLowerCase();
    if (limpio.isNotEmpty && !_tagsSeleccionados.contains(limpio) && _tagsSeleccionados.length < 5) {
      setState(() {
        _tagsSeleccionados.add(limpio);
        _controladorTag.clear();
        _mostrandoSugerencias = false;
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
      });
    }
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDescripcion.dispose();
    _nodoNombre.dispose();
    _nodoDescripcion.dispose();
    _estaCargando.dispose();
    super.dispose();
  }

  Future<void> _crearComunidad() async {
    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      
      final nuevaComunidad = Comunidad(
        id: 0,
        nombre: _controladorNombre.text.trim(),
        descripcion: _controladorDescripcion.text.trim(),
        creadorNombre: '',
        urlPortada: '',
        esPublica: _esPublica,
        esVerificada: false,
        esMiembro: true,
        ratingMedio: 0.0,
        minRatingAcceso: _minRating,
        fechaCreacion: DateTime.now(),
      );

      final respuesta = await _servicio.crearComunidad(
        nuevaComunidad, 
        imagenPortada: _imagenSeleccionada,
        tags: _tagsSeleccionados,
      );
      _estaCargando.value = false;

      if (mounted) {
        if (respuesta.exito) {
          Navigator.pop(context, true);
          widget.alConfirmar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('communityCreatedSuccess')), backgroundColor: Colors.green),
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(respuesta.mensaje), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: _llaveFormulario,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('communityCreateTitle'),
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
    
                  // Selector de Imagen
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                        image: _imagenSeleccionada != null
                            ? DecorationImage(
                                image: kIsWeb 
                                  ? NetworkImage(_imagenSeleccionada!.path) as ImageProvider
                                  : FileImage(File(_imagenSeleccionada!.path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagenSeleccionada == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFFF28B50)),
                                const SizedBox(height: 8),
                                Text(tr('communityCreateAddBanner'), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  CampoTextoPersonalizado(
                    etiqueta: tr('communityCreateNameLabel'),
                    icono: Icons.groups_outlined,
                    controlador: _controladorNombre,
                    nodoEnfoque: _nodoNombre,
                    validador: (v) => (v == null || v.isEmpty) ? tr('communityCreateNameHint') : null,
                  ),
                  const SizedBox(height: 16),
                  
                  CampoTextoPersonalizado(
                    etiqueta: tr('communityCreateDescLabel'),
                    icono: Icons.description_outlined,
                    controlador: _controladorDescripcion,
                    nodoEnfoque: _nodoDescripcion,
                    maxLineas: 5,
                    minLineas: 3,
                  ),
                  const SizedBox(height: 16),
                  
    
                  Text(
                    tr('communityCreateTagsLabel'),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controladorTag,
                    onChanged: _buscarSugerencias,
                    onSubmitted: _anadirTag,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: tr('communityCreateTagsHint'),
                      hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFF28B50), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                    ),
                  ),
                  if (_mostrandoSugerencias)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _sugerenciasTags.map((tag) => ListTile(
                          title: Text(tag['nombre'], style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                          onTap: () => _anadirTag(tag['nombre']),
                          dense: true,
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tagsSeleccionados.map((tag) => Chip(
                      label: Text(tag, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white)),
                      backgroundColor: const Color(0xFFC35E34),
                      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                      onDeleted: () => setState(() => _tagsSeleccionados.remove(tag)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _esPublica ? const Color(0xFF248EA6).withOpacity(0.3) : const Color(0xFFD95F43).withOpacity(0.3)),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _esPublica ? tr('communityCreatePublicTitle') : tr('communityCreatePrivateTitle'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      subtitle: Text(
                        _esPublica ? tr('communityCreatePublicDesc') : tr('communityCreatePrivateDesc'),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Icon(
                        _esPublica ? Icons.pets_rounded : Icons.lock_person_rounded,
                        color: _esPublica ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
                      ),
                      value: _esPublica,
                      onChanged: (v) => setState(() => _esPublica = v),
                      activeColor: const Color(0xFF248EA6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
    
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  tr('communityCreateMinRank'),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            Text(
                              _minRating == 0 ? tr('communityCreateMinRankNone') : '${_minRating.toStringAsFixed(1)} ⭐',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, 
                                color: _minRating == 0 ? Colors.grey : Colors.amber,
                                fontSize: 14
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFF28B50),
                            inactiveTrackColor: const Color(0xFF1E1E1E),
                            thumbColor: const Color(0xFFF28B50),
                            overlayColor: const Color(0xFFF28B50).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _minRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            label: _minRating.toStringAsFixed(1),
                            onChanged: (v) => setState(() => _minRating = v),
                          ),
                        ),
                        Text(
                          tr('communityCreateMinRankDesc'),
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  BotonCarga(
                    alPresionar: _crearComunidad,
                    notificadorCargando: _estaCargando,
                    texto: tr('communityCreateButton'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

}
