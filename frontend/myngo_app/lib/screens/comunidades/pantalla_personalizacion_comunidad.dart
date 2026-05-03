import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';

class PantallaPersonalizacionComunidad extends StatefulWidget {
  final Comunidad comunidad;
  final Function(Comunidad) onComunidadActualizada;

  const PantallaPersonalizacionComunidad({
    super.key,
    required this.comunidad,
    required this.onComunidadActualizada,
  });

  @override
  State<PantallaPersonalizacionComunidad> createState() => _PantallaPersonalizacionComunidadState();
}

class _PantallaPersonalizacionComunidadState extends State<PantallaPersonalizacionComunidad> {
  final _servicio = ServicioComunidades();
  bool _estaGuardando = false;

  XFile? _avatarSeleccionado;
  XFile? _portadaSeleccionada;
  XFile? _fondoGlobalSeleccionado;

  String _tipoFondoPosts = 'solido'; // solido, gradiente, patron
  Color _colorPrimarioPosts = Colors.white;
  Color _colorSecundarioPosts = Colors.grey.shade200;
  String _patronSeleccionado = 'puntos'; // puntos, lineas, cuadricula

  String _fuenteSeleccionada = 'Inter';

  final List<String> _fuentesDisponibles = [
    'Inter', 'Outfit', 'Roboto', 'Montserrat', 'Poppins', 'Lato', 'Oswald', 'Playfair Display'
  ];

  final List<Color> _paletaColores = [
    Colors.white, const Color(0xFF141414), const Color(0xFF248EA6), 
    const Color(0xFFC35E34), const Color(0xFFF28B50), Colors.purple, 
    Colors.teal, Colors.indigo, Colors.blueGrey, Colors.pinkAccent
  ];

  @override
  void initState() {
    super.initState();
    _fuenteSeleccionada = widget.comunidad.fuenteComunidad ?? 'Inter';
    
    final config = widget.comunidad.fondoPostsConfig;
    if (config != null) {
      _tipoFondoPosts = config['tipo'] ?? 'solido';
      if (config['color1'] != null) {
        _colorPrimarioPosts = Color(int.parse(config['color1'].toString().replaceFirst('#', '0xFF')));
      }
      if (config['color2'] != null) {
        _colorSecundarioPosts = Color(int.parse(config['color2'].toString().replaceFirst('#', '0xFF')));
      }
      if (config['patron'] != null) {
        _patronSeleccionado = config['patron'];
      }
    } else {
      // Default to theme-aware if no config
      _colorPrimarioPosts = Colors.white; // We will handle dark mode adaptivity in the UI renderer
    }
  }

  Future<void> _seleccionarImagen(String tipo) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    
    if (imagen != null) {
      setState(() {
        if (tipo == 'avatar') _avatarSeleccionado = imagen;
        else if (tipo == 'portada') _portadaSeleccionada = imagen;
        else if (tipo == 'fondo') _fondoGlobalSeleccionado = imagen;
      });
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _estaGuardando = true);

    Map<String, dynamic> fondoConfig = {
      'tipo': _tipoFondoPosts,
      'color1': '#${_colorPrimarioPosts.value.toRadixString(16).substring(2).toUpperCase()}',
    };

    if (_tipoFondoPosts == 'gradiente') {
      fondoConfig['color2'] = '#${_colorSecundarioPosts.value.toRadixString(16).substring(2).toUpperCase()}';
    } else if (_tipoFondoPosts == 'patron') {
      fondoConfig['patron'] = _patronSeleccionado;
    }

    final res = await _servicio.actualizarComunidad(
      widget.comunidad.id,
      avatar: _avatarSeleccionado,
      banner: _portadaSeleccionada,
      fondo: _fondoGlobalSeleccionado,
      fondoPostsConfig: fondoConfig,
      fuenteComunidad: _fuenteSeleccionada,
    );

    setState(() => _estaGuardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.mensaje),
        backgroundColor: res.exito ? const Color(0xFF248EA6) : Colors.red,
      ));

      if (res.exito && res.datos is Comunidad) {
        widget.onComunidadActualizada(res.datos as Comunidad);
        Navigator.pop(context);
      }
    }
  }

  Widget _buildSelectorColor(String titulo, Color colorActual, ValueChanged<Color> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: GoogleFonts.getFont(_fuenteSeleccionada, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paletaColores.map((color) => GestureDetector(
            onTap: () => onChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorActual.value == color.value ? const Color(0xFFF28B50) : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, spreadRadius: 1)
                ]
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildImageUploader(String titulo, String subtitulo, String tipo, XFile? archivoLocal, String? urlRemota) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitulo, style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _seleccionarImagen(tipo),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
              image: archivoLocal != null
                  ? (kIsWeb 
                      ? DecorationImage(image: NetworkImage(archivoLocal.path), fit: BoxFit.cover)
                      : DecorationImage(image: FileImage(File(archivoLocal.path)), fit: BoxFit.cover))
                  : (urlRemota != null && urlRemota.isNotEmpty
                      ? DecorationImage(image: NetworkImage(urlRemota), fit: BoxFit.cover)
                      : null),
            ),
            child: archivoLocal == null && (urlRemota == null || urlRemota.isEmpty)
                ? const Center(child: Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey))
                : null,
          ),
        ),
        if (archivoLocal != null || (urlRemota != null && urlRemota.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _seleccionarImagen(tipo),
                icon: const Icon(Icons.edit, size: 16),
                label: Text('Cambiar', style: GoogleFonts.getFont(_fuenteSeleccionada)),
              ),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Personalizar Comunidad', style: GoogleFonts.getFont(_fuenteSeleccionada, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _estaGuardando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. Tipografía
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipografía Global', style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _fuenteSeleccionada,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: esOscuro ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        ),
                        items: _fuentesDisponibles.map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: GoogleFonts.getFont(f)),
                        )).toList(),
                        onChanged: (v) => setState(() => _fuenteSeleccionada = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Imágenes de la Comunidad
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Identidad Visual', style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildImageUploader('Avatar', 'La imagen de perfil de la comunidad (1:1)', 'avatar', _avatarSeleccionado, widget.comunidad.urlAvatar),
                      const Divider(height: 48),
                      _buildImageUploader('Banner de Cabecera', 'Aparece en la parte superior (16:9)', 'portada', _portadaSeleccionada, widget.comunidad.urlPortada),
                      const Divider(height: 48),
                      _buildImageUploader('Fondo Global', 'Imagen que se muestra a los lados en pantallas grandes', 'fondo', _fondoGlobalSeleccionado, widget.comunidad.urlFondo),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Fondo de Posts
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fondo del Feed (Posts)', style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'solido', label: Text('Sólido')),
                          ButtonSegment(value: 'gradiente', label: Text('Gradiente')),
                          ButtonSegment(value: 'patron', label: Text('Patrón')),
                        ],
                        selected: {_tipoFondoPosts},
                        onSelectionChanged: (s) => setState(() => _tipoFondoPosts = s.first),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFFF28B50);
                            return Colors.transparent;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return Colors.white;
                            return esOscuro ? Colors.white : Colors.black;
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSelectorColor('Color Principal', _colorPrimarioPosts, (c) => setState(() => _colorPrimarioPosts = c)),
                      
                      if (_tipoFondoPosts == 'gradiente') ...[
                        const SizedBox(height: 24),
                        _buildSelectorColor('Color Secundario', _colorSecundarioPosts, (c) => setState(() => _colorSecundarioPosts = c)),
                      ],
                      
                      if (_tipoFondoPosts == 'patron') ...[
                        const SizedBox(height: 24),
                        Text('Seleccionar Patrón', style: GoogleFonts.getFont(_fuenteSeleccionada, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: ['puntos', 'lineas', 'cuadricula'].map((patron) => ChoiceChip(
                            label: Text(patron.toUpperCase()),
                            selected: _patronSeleccionado == patron,
                            selectedColor: const Color(0xFFF28B50),
                            labelStyle: TextStyle(color: _patronSeleccionado == patron ? Colors.white : (esOscuro ? Colors.white : Colors.black)),
                            onSelected: (s) { if (s) setState(() => _patronSeleccionado = patron); },
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Botón Guardar
                ElevatedButton(
                  onPressed: _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF248EA6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: const Color(0xFF248EA6).withValues(alpha: 0.5),
                  ),
                  child: Text('Guardar Personalización', style: GoogleFonts.getFont(_fuenteSeleccionada, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
