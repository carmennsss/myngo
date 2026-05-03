import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';
import 'widgets_detalle/seccion_posts_comunidad.dart';

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

  final Map<String, String> _nombresPatrones = {
    'puntos': 'Puntos',
    'puntos_grandes': 'Puntos Grandes',
    'lineas': 'Diagonal',
    'diagonal_inversa': 'Diagonal Inv.',
    'cuadricula': 'Cuadrícula',
    'zigzag': 'Zig-Zag',
    'diamantes': 'Diamantes',
    'olas': 'Ondas',
    'triangulos': 'Triángulos',
    'estrellas': 'Estrellas',
  };

  final List<Color> _paletaColores = [
    Colors.white, const Color(0xFF141414), const Color(0xFF248EA6), 
    const Color(0xFFC35E34), const Color(0xFFF28B50), Colors.purple, 
    Colors.teal, Colors.indigo, Colors.blueGrey, Colors.pinkAccent
  ];

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
      _colorPrimarioPosts = Colors.white;
    }

    for (var tag in widget.comunidad.tags) {
      _tagsSeleccionados.add(tag['nombre']);
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
      tags: _tagsSeleccionados,
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
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)
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
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
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
        title: Text('Personalizar Comunidad 🐾', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: widget.comunidad.colorTema.withOpacity(0.8),
        elevation: 0,
        actions: [
          if (!_estaGuardando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('GUARDAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28B50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool esPantallaAncha = constraints.maxWidth > 850;
          
          if (_estaGuardando) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
          }

          if (esPantallaAncha) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel de opciones (Izquierda)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildPanelOpciones(esOscuro),
                  ),
                ),
                // Live Preview (Derecha - Sticky)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
                      color: esOscuro ? Colors.black26 : Colors.grey.shade100,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildSectionTitle('VISTA PREVIA EN TIEMPO REAL'),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: _buildLivePreviewLarge(esOscuro),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Los cambios se reflejan al instante. Pulsa 'Guardar' para aplicar permanentemente.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Móvil
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('VISTA PREVIA'),
                const SizedBox(height: 12),
                _buildLivePreview(esOscuro),
                const SizedBox(height: 24),
                _buildPanelOpciones(esOscuro),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _guardarCambios,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('GUARDAR CAMBIOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28B50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanelOpciones(bool esOscuro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('IDENTIDAD VISUAL'),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            children: [
              _buildImageUploader('Avatar', 'Icono circular de la comunidad', 'avatar', _avatarSeleccionado, widget.comunidad.urlAvatar),
              const Divider(height: 40, color: Colors.white10),
              _buildImageUploader('Portada / Banner', 'Imagen horizontal superior', 'portada', _portadaSeleccionada, widget.comunidad.urlPortada),
              const Divider(height: 40, color: Colors.white10),
              _buildImageUploader('Fondo Global', 'Fondo de la aplicación en esta comunidad', 'fondo', _fondoGlobalSeleccionado, widget.comunidad.urlFondo),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        _buildSectionTitle('DISEÑO DEL FEED'),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de fondo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: esOscuro ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTipoBoton('Sólido', 'solido', Icons.square_rounded),
                    const SizedBox(width: 8),
                    _buildTipoBoton('Gradiente', 'gradiente', Icons.gradient_rounded),
                    const SizedBox(width: 8),
                    _buildTipoBoton('Patrón', 'patron', Icons.texture_rounded),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSelectorColor(
                _tipoFondoPosts == 'solido' ? 'Color de fondo' : 'Color primario',
                _colorPrimarioPosts,
                (c) => setState(() => _colorPrimarioPosts = c)
              ),
              
              if (_tipoFondoPosts != 'solido') ...[
                const SizedBox(height: 24),
                _buildSelectorColor(
                  _tipoFondoPosts == 'gradiente' ? 'Color final' : 'Color del patrón',
                  _colorSecundarioPosts,
                  (c) => setState(() => _colorSecundarioPosts = c)
                ),
              ],
              
              if (_tipoFondoPosts == 'patron') ...[
                const SizedBox(height: 24),
                Text('Elegir patrón', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: esOscuro ? Colors.white70 : Colors.black87)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _nombresPatrones.entries.map((entry) {
                    final seleccionada = _patronSeleccionado == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: seleccionada,
                      onSelected: (val) => setState(() => _patronSeleccionado = entry.key),
                      selectedColor: const Color(0xFFF28B50),
                      labelStyle: GoogleFonts.outfit(
                        color: seleccionada ? Colors.white : (esOscuro ? Colors.white70 : Colors.black87),
                        fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        _buildSectionTitle('DETALLES EXTRAS'),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fuente principal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: esOscuro ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _fuentesDisponibles.contains(_fuenteSeleccionada) ? _fuenteSeleccionada : _fuentesDisponibles.first,
                dropdownColor: esOscuro ? const Color(0xFF1A1A1A) : Colors.white,
                items: _fuentesDisponibles.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: GoogleFonts.getFont(f, color: esOscuro ? Colors.white : Colors.black87)),
                )).toList(),
                onChanged: (val) => setState(() => _fuenteSeleccionada = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Text('Etiquetas (max. 5)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: esOscuro ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 12),
              _buildTagInput(esOscuro),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipoBoton(String label, String value, IconData icon) {
    final seleccionado = _tipoFondoPosts == value;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _tipoFondoPosts = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFF28B50) : (esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: seleccionado ? Colors.white24 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: seleccionado ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: seleccionado ? Colors.white : (esOscuro ? Colors.white70 : Colors.black87),
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFF28B50),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildLivePreviewLarge(bool esOscuro) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Fondo real
          Positioned.fill(child: _buildBackgroundPreview()),
          
          // Feed centrado
          Positioned.fill(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                color: Colors.black.withOpacity(0.05),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildMockPost(400),
                    const SizedBox(height: 16),
                    _buildMockPost(400),
                    const SizedBox(height: 16),
                    _buildMockPost(400),
                    const SizedBox(height: 16),
                    _buildMockPost(400),
                  ],
                ),
              ),
            ),
          ),
          
          // Overlay info
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF28B50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE PREVIEW',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(bool esOscuro) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.2), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundPreview()),
          Positioned.fill(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMockPost(260),
                    const SizedBox(height: 12),
                    _buildMockPost(260),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPreview() {
    final Map<String, dynamic> config = {
      'tipo': _tipoFondoPosts,
      'color1': '#${_colorPrimarioPosts.value.toRadixString(16).substring(2).toUpperCase()}',
      'color2': '#${_colorSecundarioPosts.value.toRadixString(16).substring(2).toUpperCase()}',
      'patron': _patronSeleccionado,
    };
    return SeccionPostsComunidad.buildPostsBackgroundFromConfig(config, context);
  }

  Widget _buildMockPost(double width) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5))),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(width: width * 0.7, height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildTagInput(bool esOscuro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controladorTag,
          onChanged: _buscarSugerencias,
          onSubmitted: _anadirTag,
          style: GoogleFonts.outfit(color: esOscuro ? Colors.white : Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ej: juegos, arte, música...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFF28B50)),
          ),
        ),
        if (_mostrandoSugerencias)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: _sugerenciasTags.map((tag) => ListTile(
                title: Text(tag['nombre'], style: GoogleFonts.outfit(color: esOscuro ? Colors.white : Colors.black87, fontSize: 13)),
                onTap: () => _anadirTag(tag['nombre']),
                dense: true,
              )).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tagsSeleccionados.map((tag) => Chip(
            label: Text(tag, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFC35E34),
            deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
            onDeleted: () => setState(() => _tagsSeleccionados.remove(tag)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          )).toList(),
        ),
      ],
    );
  }
}
