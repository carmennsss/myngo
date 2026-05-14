import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tolgee/tolgee.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';
import '../../utils/configuracion.dart';
import '../../utils/extensiones_color.dart';
import 'widgets_detalle/seccion_posts_comunidad.dart';
import 'package:myngo_app/utils/tr_helper.dart';
import '../../utils/manejo_errores.dart';
import '../../utils/image_utils.dart';

// Editor visual avanzado de la identidad de una comunidad: avatar, portada, fondo global,
// colores del feed, patrones, fuente y etiquetas, con previsualización en tiempo real.
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
  late Color _colorTema;

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

  final List<String> _patronesDisponibles = [
    'puntos', 'puntos_grandes', 'lineas', 'diagonal_inversa', 'cuadricula', 
    'zigzag', 'diamantes', 'olas', 'triangulos', 'estrellas'
  ];


  final List<Color> _paletaColores = [
    Colors.white, const Color(0xFF141414), const Color(0xFF248EA6), 
    const Color(0xFFC35E34), const Color(0xFFF28B50), Colors.purple, 
    Colors.teal, Colors.indigo, Colors.blueGrey, Colors.pinkAccent
  ];

  final _controladorTag = TextEditingController();
  final List<String> _tagsSeleccionados = [];
  List<Map<String, dynamic>> _sugerenciasTags = [];
  bool _mostrandoSugerencias = false;

  // Autocompletado de tags mientras el admin escribe en el campo de etiquetas
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

  // Añade un tag limpio a la lista local (máximo 5)
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
    _colorTema = widget.comunidad.colorTema;
    _fuenteSeleccionada = widget.comunidad.fuenteComunidad ?? 'Inter';
    
    final config = widget.comunidad.fondoPostsConfig;
    if (config != null) {
      _tipoFondoPosts = config['tipo'] ?? 'solido';
      if (config['color1'] != null) {
        _colorPrimarioPosts = ColorExtension.fromHex(config['color1'].toString());
      }
      if (config['color2'] != null) {
        _colorSecundarioPosts = ColorExtension.fromHex(config['color2'].toString());
      }
      if (config['patron'] != null) {
        _patronSeleccionado = config['patron'];
      }
    } else {
      _colorPrimarioPosts = Colors.white;
    }

    // Cargar tags existentes
    if (widget.comunidad.tags.isNotEmpty) {
      for (var tag in widget.comunidad.tags) {
        if (tag is Map && tag.containsKey('nombre') && tag['nombre'] != null) {
          _tagsSeleccionados.add(tag['nombre'].toString());
        }
      }
    }
  }

  // Abre el picker de imágenes y asigna el archivo al slot correcto (avatar, portada o fondo)
  Future<void> _seleccionarImagen(String tipo) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    
    if (imagen != null) {
      XFile imagenFinal = imagen;
      if (tipo == 'avatar') {
        final recortada = await recortarImagenCirculo(imagen, context: context);
        if (recortada != null) imagenFinal = recortada;
      } else if (tipo == 'portada') {
        final recortada = await recortarImagenRectangular(imagen, context: context, aspectRatioX: 16, aspectRatioY: 9);
        if (recortada != null) imagenFinal = recortada;
      }
      setState(() {
        if (tipo == 'avatar') _avatarSeleccionado = imagenFinal;
        else if (tipo == 'portada') _portadaSeleccionada = imagenFinal;
        else if (tipo == 'fondo') _fondoGlobalSeleccionado = imagenFinal;
      });
    }
  }

  // Construye el fondoConfig y llama al servicio para persistir todos los cambios
  Future<void> _guardarCambios() async {
    setState(() => _estaGuardando = true);

    Map<String, dynamic> fondoConfig = {
      'tipo': _tipoFondoPosts,
      'color1': _colorPrimarioPosts.toHex(),
    };

    if (_tipoFondoPosts == 'gradiente') {
      fondoConfig['color2'] = _colorSecundarioPosts.toHex();
    } else if (_tipoFondoPosts == 'patron') {
      fondoConfig['patron'] = _patronSeleccionado;
    }

    final res = await _servicio.actualizarComunidad(
      widget.comunidad.id,
      colorTema: _colorTema.toHex(),
      avatar: _avatarSeleccionado,
      banner: _portadaSeleccionada,
      fondo: _fondoGlobalSeleccionado,
      fondoPostsConfig: fondoConfig,
      fuenteComunidad: _fuenteSeleccionada,
      tags: _tagsSeleccionados,
    );

    setState(() => _estaGuardando = false);

    if (mounted) {
      if (res.exito) {
        mostrarAviso(context, res.mensaje, esExito: true);
      } else {
        mostrarError(context, res.mensaje, mensajePersonalizado: res.mensaje);
      }

      if (res.exito && res.datos is Comunidad) {
        widget.onComunidadActualizada(res.datos as Comunidad);
      }
    }
  }

  // Paleta de colores predefinidos para seleccionar el color de fondo o tema
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
  // Área de subida de imagen con previsualización del archivo local o la URL remota
  Widget _buildImageUploader(String titulo, String subtitulo, String tipo, XFile? archivoLocal, String? urlRemota) {
    final String fullUrl = urlRemota != null && urlRemota.isNotEmpty
        ? (urlRemota.startsWith('http') ? urlRemota : '${Configuracion.baseUrl}${urlRemota.startsWith('/') ? '' : '/'}$urlRemota')
        : '';

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
                  : (fullUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(fullUrl), fit: BoxFit.cover)
                      : null),
            ),
            child: archivoLocal == null && fullUrl.isEmpty
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
                label: Text(tr('personalizeChangeBtn'), style: GoogleFonts.getFont(_fuenteSeleccionada)),
              ),
            ),
          )

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(tr('personalizeTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: _colorTema.withOpacity(0.8),
            elevation: 0,
            actions: [
              if (!_estaGuardando)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: _guardarCambios,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(tr('adminSave')), // Reuse adminSave or personalizeSaveBtn
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
    
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildPanelOpciones(tr),
                      ),
                    ),
    
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
                          color: Colors.grey.shade100,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: _buildSectionTitle(tr('personalizeRealTimePreview')),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: _buildLivePreviewLarge(tr),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                tr('personalizePreviewDesc'),
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
    
    
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(tr('personalizePreview')),
                    const SizedBox(height: 12),
                    _buildLivePreview(),
                    const SizedBox(height: 24),
                    _buildPanelOpciones(tr),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarCambios,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(tr('personalizeSaveBtn')),
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
    );
  }


  // Panel de opciones agrupadas: identidad visual, diseño del feed y detalles extras
  Widget _buildPanelOpciones(String Function(String) tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(tr('personalizeSectionVisual')),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            children: [
              _buildImageUploader(tr('personalizeAvatarTitle'), tr('personalizeAvatarDesc'), 'avatar', _avatarSeleccionado, widget.comunidad.urlAvatar),
              const Divider(height: 40, color: Colors.white10),
              _buildImageUploader(tr('personalizeBannerTitle'), tr('personalizeBannerDesc'), 'portada', _portadaSeleccionada, widget.comunidad.urlPortada),
              const Divider(height: 40, color: Colors.white10),
              _buildImageUploader(tr('personalizeGlobalBackgroundTitle'), tr('personalizeGlobalBackgroundDesc'), 'fondo', _fondoGlobalSeleccionado, widget.comunidad.urlFondo),
              const Divider(height: 40, color: Colors.white10),
              _buildConfigItem(
                icon: Icons.palette_rounded,
                title: tr('personalizeThemeColorTitle'),
                subtitle: tr('personalizeThemeColorDesc'),

                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorTema,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                  ),
                ),
                onTap: () => _mostrarSelectorColorAvanzado(tr),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        _buildSectionTitle(tr('personalizeSectionFeed')),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('personalizeBackgroundType'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTipoBoton(tr('personalizeTypeSolid'), 'solido', Icons.square_rounded),
                    const SizedBox(width: 8),
                    _buildTipoBoton(tr('personalizeTypeGradient'), 'gradiente', Icons.gradient_rounded),
                    const SizedBox(width: 8),
                    _buildTipoBoton(tr('personalizeTypePattern'), 'patron', Icons.texture_rounded),
                  ],
                ),
              ),

              
              const SizedBox(height: 24),
              _buildSelectorColor(
                _tipoFondoPosts == 'solido' ? tr('personalizeBackgroundColor') : tr('personalizePrimaryColor'),
                _colorPrimarioPosts,
                (c) => setState(() => _colorPrimarioPosts = c)
              ),
              
              if (_tipoFondoPosts != 'solido') ...[
                const SizedBox(height: 24),
                _buildSelectorColor(
                  _tipoFondoPosts == 'gradiente' ? tr('personalizeFinalColor') : tr('personalizePatternColor'),
                  _colorSecundarioPosts,
                  (c) => setState(() => _colorSecundarioPosts = c)
                ),
              ],

              
              if (_tipoFondoPosts == 'patron') ...[
                const SizedBox(height: 24),
                Text(tr('personalizeChoosePattern'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _patronesDisponibles.map((key) {
                    final seleccionada = _patronSeleccionado == key;
                    String label = key;
                    // Localize pattern names
                    if (key == 'puntos') label = tr('patternDots');
                    else if (key == 'puntos_grandes') label = tr('patternLargeDots');
                    else if (key == 'lineas') label = tr('patternDiagonal');
                    else if (key == 'diagonal_inversa') label = tr('patternReverseDiagonal');
                    else if (key == 'cuadricula') label = tr('patternGrid');
                    else if (key == 'zigzag') label = tr('patternZigZag');
                    else if (key == 'diamantes') label = tr('patternDiamonds');
                    else if (key == 'olas') label = tr('patternWaves');
                    else if (key == 'triangulos') label = tr('patternTriangles');
                    else if (key == 'estrellas') label = tr('patternStars');

                    return ChoiceChip(
                      label: Text(label),
                      selected: seleccionada,
                      onSelected: (val) => setState(() => _patronSeleccionado = key),


                      selectedColor: const Color(0xFFF28B50),
                      labelStyle: GoogleFonts.outfit(
                        color: seleccionada ? Colors.white : Colors.black87,
                        fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.black.withOpacity(0.05),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        _buildSectionTitle(tr('personalizeSectionExtras')),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('personalizeMainFont'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (_fuenteSeleccionada.isNotEmpty && _fuentesDisponibles.contains(_fuenteSeleccionada)) 
                    ? _fuenteSeleccionada 
                    : (_fuentesDisponibles.isNotEmpty ? _fuentesDisponibles.first : 'Inter'),
                dropdownColor: Colors.white,
                items: _fuentesDisponibles.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: GoogleFonts.getFont(f, color: Colors.black87)),
                )).toList(),
                onChanged: (val) => setState(() => _fuenteSeleccionada = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Text(tr('personalizeTagsLabel'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildTagInput(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildTipoBoton(String label, String value, IconData icon) {
    final seleccionado = _tipoFondoPosts == value;
    
    return GestureDetector(
      onTap: () => setState(() => _tipoFondoPosts = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFF28B50) : Colors.black.withOpacity(0.05),
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
                color: seleccionado ? Colors.white : Colors.black87,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildConfigItem({required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(
                color: _colorTema.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ), 
              child: Icon(icon, color: _colorTema, size: 22)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.getFont(_fuenteSeleccionada, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                  Text(subtitle, style: GoogleFonts.getFont(_fuenteSeleccionada, color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Previsualización completa estilo miniatura de la comunidad para pantallas anchas
  Widget _buildLivePreviewLarge(String Function(String) tr) {

    final String fullAvatarUrl = widget.comunidad.urlAvatar != null && widget.comunidad.urlAvatar!.isNotEmpty
        ? (widget.comunidad.urlAvatar!.startsWith('http') ? widget.comunidad.urlAvatar! : '${Configuracion.baseUrl}${widget.comunidad.urlAvatar!.startsWith('/') ? '' : '/'}${widget.comunidad.urlAvatar!}')
        : '';
    final String fullBannerUrl = widget.comunidad.urlPortada.isNotEmpty
        ? (widget.comunidad.urlPortada.startsWith('http') ? widget.comunidad.urlPortada : '${Configuracion.baseUrl}${widget.comunidad.urlPortada.startsWith('/') ? '' : '/'}${widget.comunidad.urlPortada}')
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, spreadRadius: -10)
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [

            Positioned.fill(child: _buildBackgroundPreview()),
            
            Column(
              children: [

                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: _portadaSeleccionada != null
                        ? (kIsWeb 
                            ? DecorationImage(image: NetworkImage(_portadaSeleccionada!.path), fit: BoxFit.cover)
                            : DecorationImage(image: FileImage(File(_portadaSeleccionada!.path)), fit: BoxFit.cover))
                        : (fullBannerUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(fullBannerUrl), fit: BoxFit.cover)
                            : null),
                    color: _colorTema.withOpacity(0.3),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      )
                    ),
                  ),
                ),
                

                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: _avatarSeleccionado != null
                                ? (kIsWeb 
                                    ? DecorationImage(image: NetworkImage(_avatarSeleccionado!.path), fit: BoxFit.cover)
                                    : DecorationImage(image: FileImage(File(_avatarSeleccionado!.path)), fit: BoxFit.cover))
                                : (fullAvatarUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(fullAvatarUrl), fit: BoxFit.cover)
                                    : null),
                            color: _colorTema,
                          ),
                          child: (_avatarSeleccionado == null && fullAvatarUrl.isEmpty)
                              ? const Icon(Icons.pets, color: Colors.white, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.comunidad.nombre,
                                style: GoogleFonts.getFont(_fuenteSeleccionada, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'comunidad/${widget.comunidad.nombre.toLowerCase().replaceAll(' ', '')}',
                                style: GoogleFonts.getFont(_fuenteSeleccionada, 
                                  fontSize: 12, 
                                  color: _colorTema,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildMockTab(tr('postsTab'), true),
                      _buildMockTab(tr('storeTab'), false),
                      _buildMockTab(tr('chatTab'), false),
                    ],
                  ),
                ),


                // Mock de Contenido (Posts)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => _buildMockPost(),
                  ),
                ),
              ],
            ),
            

            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _colorTema,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _colorTema.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_photo_alternate, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(tr('personalizePostBtn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pestaña de navegación simulada en la previsualización
  Widget _buildMockTab(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: active ? _colorTema : Colors.transparent, width: 2))
      ),
      child: Text(
        text,
        style: GoogleFonts.getFont(_fuenteSeleccionada, 
          fontSize: 13, 
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? _colorTema : Colors.black38,
        ),
      ),
    );
  }

  // Post ficticio para rellenar la previsualización del feed
  Widget _buildMockPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: _colorTema.withOpacity(0.2), child: Icon(Icons.person, size: 16, color: _colorTema)),
              const SizedBox(width: 10),
              Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(5))),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 8, width: 150, decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: _colorTema.withOpacity(0.5)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: _colorTema.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _colorTema.withOpacity(0.2), width: 1),
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
                    _buildMockPost(),
                    const SizedBox(height: 12),
                    _buildMockPost(),
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
      'color1': '#${_colorPrimarioPosts.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'color2': '#${_colorSecundarioPosts.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'patron': _patronSeleccionado,
    };
    return SeccionPostsComunidad.buildPostsBackgroundFromConfig(config, context);
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controladorTag,
          onChanged: _buscarSugerencias,
          onSubmitted: _anadirTag,
          style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: tr('personalizeTagsHint'),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFF28B50)),
          ),
        ),
        if (_mostrandoSugerencias)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: _sugerenciasTags.map((tag) => ListTile(
                title: Text(tag['nombre'], style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13)),
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
  void _mostrarSelectorColorAvanzado(String Function(String) tr) {
    final coloresPredefinidos = [
      '#C35E34', '#248EA6', '#F28B50', '#7A918D', 
      '#D95F43', '#4A4440', '#9BBAB7', '#E8D5C4',
      '#673AB7', '#E91E63', '#4CAF50', '#FFC107'
    ];

    Color colorTemporal = _colorTema;
    final hexController = TextEditingController(text: colorTemporal.toHex().replaceFirst('#', ''));

    showDialog(
      context: context,
          builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('${tr('personalizeThemeColorTitle')} 🎨', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vista previa
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorTemporal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '#${colorTemporal.toHex().replaceFirst('#', '')}',
                        style: TextStyle(
                          color: colorTemporal.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Colores rápidos
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr('personalizeQuickColors'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: coloresPredefinidos.map((hex) {
                      final color = ColorExtension.fromHex(hex);
                      final bool seleccionado = colorTemporal.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            colorTemporal = color;
                            hexController.text = color.toHex().replaceFirst('#', '');
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: seleccionado ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                              width: seleccionado ? 3 : 1,
                            ),
                            boxShadow: seleccionado ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12)),
                  const SizedBox(height: 16),
                  // Sliders personalizados
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr('personalizeFineTune'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  _buildHSLSliders(colorTemporal, (nuevoColor) {
                    setDialogState(() {
                      colorTemporal = nuevoColor;
                      hexController.text = nuevoColor.toHex().replaceFirst('#', '');
                    });
                  }, tr),
                  const SizedBox(height: 20),
                  // Input Hex
                  TextField(
                    controller: hexController,
                    maxLength: 6,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: tr('personalizeHexCode'),
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      prefixText: '#',
                      prefixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      counterText: '',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      if (val.length == 6) {
                        final c = ColorExtension.fromHex(val);
                        if (c != Colors.transparent && c.opacity > 0) {
                          setDialogState(() => colorTemporal = c);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('commonCancel').toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28B50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() => _colorTema = colorTemporal);
                Navigator.pop(context);
              },
              child: Text(tr('commonSave').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHSLSliders(Color color, ValueChanged<Color> onChanged, String Function(String) tr) {
    final hsl = HSLColor.fromColor(color);
    return Column(
      children: [
        _buildSimpleSlider(
          label: tr('commonHue'),
          value: hsl.hue,
          max: 360,
          onChanged: (v) => onChanged(hsl.withHue(v).toColor()),
          tr: tr,
        ),
        _buildSimpleSlider(
          label: tr('commonSaturation'),
          value: hsl.saturation,
          max: 1.0,
          onChanged: (v) => onChanged(hsl.withSaturation(v).toColor()),
          tr: tr,
        ),
        _buildSimpleSlider(
          label: tr('commonBrightness'),
          value: hsl.lightness,
          max: 1.0,
          onChanged: (v) => onChanged(hsl.withLightness(v).toColor()),
          tr: tr,
        ),
      ],
    );
  }

  Widget _buildSimpleSlider({required String label, required double value, required double max, required ValueChanged<double> onChanged, required String Function(String) tr}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11))),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: max,
              activeColor: const Color(0xFFF28B50),
              inactiveColor: Colors.white10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
