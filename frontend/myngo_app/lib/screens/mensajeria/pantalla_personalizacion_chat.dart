import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../../models/sala_chat.dart';
import '../../services/servicio_mensajeria.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:myngo_app/l10n/app_localizations.dart';

// Painter eficiente para preview de patrones
class _PatternPreviewPainter extends CustomPainter {
  final String patternType;
  
  _PatternPreviewPainter({required this.patternType});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const spacing = 25.0;
    
    switch (patternType) {
      case 'dots':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        }
        break;
      case 'stars':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        }
        break;
      case 'triangles':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            _drawSmallTriangle(canvas, Offset(x, y), 4, paint);
          }
        }
        break;
      case 'waves':
        for (double y = 0; y < size.height; y += 15) {
          for (double x = 0; x <= size.width; x += 3) {
            final nextX = x + 3;
            if (nextX <= size.width) {
              canvas.drawLine(Offset(x, y), Offset(nextX, y + 2), paint..strokeWidth = 0.5);
            }
          }
        }
        break;
      case 'lines':
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint..strokeWidth = 0.5);
        }
        break;
    }
  }
  
  void _drawSmallTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx + size / 2, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy + size / 2);
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }
  
  @override
  bool shouldRepaint(_PatternPreviewPainter oldDelegate) => oldDelegate.patternType != patternType;
}

class PantallaPersonalizacionChat extends StatefulWidget {
  final SalaChat sala;

  const PantallaPersonalizacionChat({super.key, required this.sala});

  @override
  State<PantallaPersonalizacionChat> createState() => _PantallaPersonalizacionChatState();
}

class _PantallaPersonalizacionChatState extends State<PantallaPersonalizacionChat> {
  final _servicio = ServicioMensajeria();
  late String _nombre;
  late PersonalizacionChat _perso;
  String? _avatarUrl;
  bool _estaGuardando = false;
  bool _estaSubiendoImagen = false;

  final List<Color> _paletaColores = [
    const Color(0xFFF28B50), const Color(0xFFE91E63), const Color(0xFF9C27B0),
    const Color(0xFF673AB7), const Color(0xFF3F51B5), const Color(0xFF2196F3),
    const Color(0xFF03A9F4), const Color(0xFF00BCD4), const Color(0xFF009688),
    const Color(0xFF4CAF50), const Color(0xFF8BC34A), const Color(0xFFCDDC39),
    const Color(0xFFFFEB3B), const Color(0xFFFFC107), const Color(0xFFFF9800),
    const Color(0xFFFF5722), const Color(0xFF795548), const Color(0xFF9E9E9E),
    const Color(0xFF607D8B), const Color(0xFF000000),
  ];

  final List<Map<String, dynamic>> _gradientes = [
    {'id': 'sunset', 'name': 'Atardecer', 'colors': [Color(0xFFFF512F), Color(0xFFDD2476)]},
    {'id': 'ocean', 'name': 'Océano', 'colors': [Color(0xFF2193B0), Color(0xFF6DD5ED)]},
    {'id': 'forest', 'name': 'Bosque', 'colors': [Color(0xFF11998E), Color(0xFF38EF7D)]},
    {'id': 'purple', 'name': 'Galaxia', 'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)]},
    {'id': 'dark', 'name': 'Noche', 'colors': [Color(0xFF232526), Color(0xFF414345)]},
    {'id': 'peach', 'name': 'Melocotón', 'colors': [Color(0xFFED4264), Color(0xFFFFEDBC)]},
    {'id': 'lavender', 'name': 'Lavanda', 'colors': [Color(0xFFEECDA3), Color(0xFFEF629F)]},
  ];

  final List<Map<String, dynamic>> _patrones = [
    {'id': 'dots', 'name': 'Puntos', 'icon': Icons.blur_on},
    {'id': 'stars', 'name': 'Estrellas', 'icon': Icons.star_border},
    {'id': 'triangles', 'name': 'Geométrico', 'icon': Icons.change_history},
    {'id': 'waves', 'name': 'Ondas', 'icon': Icons.waves},
    {'id': 'lines', 'name': 'Líneas', 'icon': Icons.reorder},
  ];

  final List<Map<String, dynamic>> _estilosBurbuja = [
    {'id': 'solido', 'name': 'Sólido', 'desc': 'Clásico'},
    {'id': 'cristal', 'name': 'Cristal', 'desc': 'Cristalino'},
    {'id': 'neon', 'name': 'Neón', 'desc': 'Brillante'},
    {'id': 'amor', 'name': 'Amor', 'desc': 'Corazones'},
    {'id': 'vaquero', 'name': 'Vaquero', 'desc': 'Oeste'},
    {'id': 'bosque', 'name': 'Bosque', 'desc': 'Bosque'},
    {'id': 'cyber', 'name': 'Cyber', 'desc': 'Futuro'},
    {'id': 'kawaii', 'name': 'Kawaii', 'desc': 'Lindo'},
    {'id': 'aventura', 'name': 'Aventura', 'desc': 'Rol'},
  ];

  @override
  void initState() {
    super.initState();
    _nombre = widget.sala.nombre;
    _perso = widget.sala.personalizacion ?? PersonalizacionChat();
    _avatarUrl = widget.sala.avatarS3;
  }

  void _guardar() async {
    setState(() => _estaGuardando = true);
    final exito = await _servicio.actualizarSala(
      widget.sala.id,
      nombre: _nombre,
      personalizacion: _perso,
    );
    
    if (mounted) {
      setState(() => _estaGuardando = false);
      if (exito) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la configuración'))
        );
      }
    }
  }

  Future<void> _cambiarAvatar() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (imagen != null) {
      setState(() => _estaSubiendoImagen = true);
      final nuevaUrl = await _servicio.subirAvatarSala(widget.sala.id, imagen);
      
      if (mounted) {
        setState(() {
          _estaSubiendoImagen = false;
          if (nuevaUrl != null) {
            _avatarUrl = nuevaUrl;
          }
        });
        
        if (nuevaUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir la imagen'))
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatPersonalization, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_estaGuardando)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
          else
            TextButton(
              onPressed: _guardar,
              child: Text('GUARDAR', style: GoogleFonts.outfit(color: const Color(0xFFF28B50), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarPicker(),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 32),
            _buildSectionTitle('Identidad del Chat'),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _nombre,
              decoration: InputDecoration(
                labelText: 'Nombre del Chat',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              onChanged: (v) => setState(() => _nombre = v),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Colores de Burbujas'),
            const SizedBox(height: 16),
            _buildColorPicker('Mis mensajes', _perso.colorBurbujaMio, (hex) {
              setState(() => _perso = _copyPerso(colorBurbujaMio: hex));
            }),
            const SizedBox(height: 16),
            _buildColorPicker('Mensajes de otros', _perso.colorBurbujaOtro, (hex) {
              setState(() => _perso = PersonalizacionChat(
                colorFondo: _perso.colorFondo,
                colorBurbujaMio: _perso.colorBurbujaMio,
                colorBurbujaOtro: hex,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 32),
            _buildSectionTitle('Patrón y Estilo de Fondo'),
            const SizedBox(height: 16),
            _buildGradientPicker(),
            const SizedBox(height: 16),
            _buildPatternPicker(),
            const SizedBox(height: 32),
            _buildSectionTitle('Estilo de Burbujas'),
            const SizedBox(height: 16),
            _buildBubbleStylePicker(),
            const SizedBox(height: 24),
            _buildShapePicker(),
            const SizedBox(height: 24),
            _buildFontSizePicker(),
            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _perso = PersonalizacionChat());
                },
                icon: const Icon(Icons.refresh, color: Colors.red),
                label: const Text('Restablecer diseño por defecto', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gradiente de fondo', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _gradientes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _perso.gradienteFondo == null;
                return GestureDetector(
                  onTap: () => setState(() => _perso = _copyPerso(gradienteFondo: null)),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFFF28B50) : Colors.grey[300]!, width: 2),
                    ),
                    child: const Icon(Icons.block, color: Colors.grey),
                  ),
                );
              }
              
              final grad = _gradientes[index - 1];
              final isSelected = _perso.gradienteFondo == grad['id'];
              
              return GestureDetector(
                onTap: () => setState(() => _perso = _copyPerso(gradienteFondo: grad['id'])),
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad['colors']),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                    boxShadow: [if (isSelected) BoxShadow(color: (grad['colors'] as List<Color>)[0].withOpacity(0.5), blurRadius: 8)],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatternPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patrón geométrico', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _patrones.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _perso.patronFondo == null;
                return GestureDetector(
                  onTap: () => setState(() => _perso = _copyPerso(patronFondo: null)),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFFF28B50) : Colors.grey[300]!, width: 2),
                    ),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                );
              }
              
              final pat = _patrones[index - 1];
              final isSelected = _perso.patronFondo == pat['id'];
              
              return GestureDetector(
                onTap: () => setState(() => _perso = _copyPerso(patronFondo: pat['id'])),
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF28B50).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFFF28B50) : Colors.grey[300]!, width: 2),
                  ),
                  child: Icon(pat['icon'], color: isSelected ? const Color(0xFFF28B50) : Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleStylePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estilo visual de burbuja', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1, // Un poco más alto para la preview
          ),
          itemCount: _estilosBurbuja.length,
          itemBuilder: (context, index) {
            final estilo = _estilosBurbuja[index];
            final isSelected = _perso.estiloBurbuja == estilo['id'];
            
            return GestureDetector(
              onTap: () => setState(() => _perso = _copyPerso(estiloBurbuja: estilo['id'])),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF28B50).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFFF28B50) : Colors.grey[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Transform.scale(
                            scale: 0.8,
                            child: _buildMiniPreviewBurbuja(estilo['id']),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF28B50).withOpacity(0.1) : Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Column(
                        children: [
                          Text(estilo['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(estilo['desc'], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniPreviewBurbuja(String estiloId) {
    // Simular una pequeña burbuja para la preview de la tarjeta
    final color = const Color(0xFFF28B50);
    BoxDecoration deco;
    switch (estiloId) {
      case 'amor':
        deco = BoxDecoration(
          color: const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pinkAccent, width: 1.5),
        );
        break;
      case 'vaquero':
        deco = BoxDecoration(
          color: const Color(0xFFD7CCC8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF5D4037), width: 2),
        );
        break;
      case 'bosque':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        );
        break;
      case 'cyber':
        deco = BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: const Border(left: BorderSide(color: Color(0xFF00E5FF), width: 6)),
        );
        break;
      case 'kawaii':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        );
        break;
      case 'aventura':
        deco = BoxDecoration(
          color: const Color(0xFFF5E6CA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
        );
        break;
      default:
        deco = BoxDecoration(color: color, borderRadius: BorderRadius.circular(12));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 35,
          decoration: deco,
          child: const Center(child: Text('Abc', style: TextStyle(fontSize: 10, color: Colors.black))),
        ),
        _buildPreviewDecoracionMini(estiloId),
      ],
    );
  }

  Widget _buildPreviewDecoracionMini(String estiloId) {
    switch (estiloId) {
      case 'amor': return const Positioned(top: -8, right: -5, child: Text('💖', style: TextStyle(fontSize: 14)));
      case 'vaquero': return const Positioned(top: -12, left: 5, child: Text('🤠', style: TextStyle(fontSize: 16)));
      case 'bosque': return const Positioned(top: -8, left: -5, child: Text('🍃', style: TextStyle(fontSize: 12)));
      case 'kawaii': return const Positioned(bottom: -8, right: -5, child: Text('🎀', style: TextStyle(fontSize: 14)));
      case 'cyber': return Positioned(top: 4, right: 4, child: Container(width: 4, height: 4, color: const Color(0xFF00E5FF)));
      case 'aventura': return const Positioned(top: -10, right: -5, child: Text('📜', style: TextStyle(fontSize: 14)));
      default: return const SizedBox.shrink();
    }
  }

  PersonalizacionChat _copyPerso({
    String? colorFondo,
    String? colorBurbujaMio,
    String? colorBurbujaOtro,
    String? colorTextoMio,
    String? colorTextoOtro,
    String? colorNombreMio,
    String? colorNombreOtro,
    String? gradienteFondo,
    String? patronFondo,
    String? estiloBurbuja,
    String? formaBurbuja,
    int? fontSize,
  }) {
    return PersonalizacionChat(
      colorFondo: colorFondo ?? _perso.colorFondo,
      colorBurbujaMio: colorBurbujaMio ?? _perso.colorBurbujaMio,
      colorBurbujaOtro: colorBurbujaOtro ?? _perso.colorBurbujaOtro,
      colorTextoMio: colorTextoMio ?? _perso.colorTextoMio,
      colorTextoOtro: colorTextoOtro ?? _perso.colorTextoOtro,
      colorNombreMio: colorNombreMio ?? _perso.colorNombreMio,
      colorNombreOtro: colorNombreOtro ?? _perso.colorNombreOtro,
      gradienteFondo: gradienteFondo ?? _perso.gradienteFondo,
      patronFondo: patronFondo ?? _perso.patronFondo,
      imagenFondoS3: _perso.imagenFondoS3,
      formaBurbuja: formaBurbuja ?? _perso.formaBurbuja,
      estiloBurbuja: estiloBurbuja ?? _perso.estiloBurbuja,
      fontSize: fontSize ?? _perso.fontSize,
      tema: _perso.tema,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF28B50), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFF28B50).withOpacity(0.2), blurRadius: 15)
                  ],
                ),
                child: ClipOval(
                  child: _estaSubiendoImagen
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
                    : (_avatarUrl != null)
                      ? CachedNetworkImage(
                          imageUrl: _avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        )
                      : Container(
                          color: const Color(0xFFFBE9E0),
                          child: const Icon(Icons.group_outlined, size: 40, color: Color(0xFFF28B50)),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: BotonTactil(
                  onTap: _cambiarAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFF28B50), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.sala.esGrupal ? 'Cambiar foto del grupo' : 'Cambiar foto del chat',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final colorFondo = _colorFromHex(_perso.colorFondo) ?? Colors.white;
    final colorMio = _colorFromHex(_perso.colorBurbujaMio) ?? const Color(0xFFF28B50);
    final colorOtro = _colorFromHex(_perso.colorBurbujaOtro) ?? const Color(0xFFEEEEEE);
    final colorNombreMio = _colorFromHex(_perso.colorNombreMio) ?? const Color(0xFFF28B50);
    final colorNombreOtro = _colorFromHex(_perso.colorNombreOtro) ?? const Color(0xFF4A4440);
    
    final grad = _gradientes.firstWhere((g) => g['id'] == _perso.gradienteFondo, orElse: () => {});
    final List<Color>? gradColors = grad.isNotEmpty ? grad['colors'] as List<Color> : null;
    
    final borderRadius = _perso.formaBurbuja == 'redondeada' ? 20.0 : 4.0;
    
    // Obtener avatar del otro si es DM
    String? avatarOtro;
    if (!widget.sala.esGrupal) {
      final otroId = widget.sala.otroUsuarioId;
      try {
        final otro = widget.sala.participantes.firstWhere((p) => p.usuarioId == otroId);
        avatarOtro = otro.usuario?.urlAvatar;
      } catch (_) {}
    }

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: gradColors == null ? colorFondo : null,
        gradient: gradColors != null ? LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFBE9E0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          if (_perso.patronFondo != null)
            Opacity(
              opacity: 0.1,
              child: _buildPatternWidget(_perso.patronFondo!),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPreviewBadge(colorFondo),
                const Spacer(),
                _buildPreviewBurbuja(
                  'Amigo', 
                  '¡Oye! ¿Has visto los nuevos estilos? 🐾', 
                  colorOtro, 
                  colorNombreOtro, 
                  false, 
                  avatarOtro, 
                  borderRadius
                ),
                const SizedBox(height: 12),
                _buildPreviewBurbuja(
                  'Tú', 
                  '¡Sí! Se ven increíbles. Voy a probar este. ✨', 
                  colorMio, 
                  colorNombreMio, 
                  true, 
                  null, 
                  borderRadius
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternWidget(String id) {
    return CustomPaint(
      painter: _PatternPreviewPainter(patternType: id),
      child: Container(),
    );
  }

  Widget _buildPreviewBadge(Color fondo) {
    final isDark = fondo.computeLuminance() < 0.5 || _perso.gradienteFondo != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'VISTA PREVIA EN TIEMPO REAL', 
        style: GoogleFonts.outfit(
          fontSize: 9, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white : const Color(0xFFC35E34),
          letterSpacing: 1.0,
        )
      ),
    );
  }

  Widget _buildPreviewBurbuja(String nombre, String texto, Color color, Color colorNombre, bool esMio, String? avatar, double radius) {
    final estilo = _perso.estiloBurbuja;
    
    BoxDecoration deco;
    switch (estilo) {
      case 'cristal':
        deco = BoxDecoration(
          color: color.withOpacity(0.4),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        );
        break;
      case 'neon':
        deco = BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)],
        );
        break;
      case 'retro':
        deco = BoxDecoration(
          color: color,
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        );
        break;
      case 'bosque':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        );
        break;
      case 'cyber':
        deco = BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: _getBorderRadius(esMio, radius),
          border: const Border(
            top: BorderSide(color: Color(0xFF00E5FF), width: 2),
            bottom: BorderSide(color: Color(0xFF00E5FF), width: 2),
            left: BorderSide(color: Color(0xFF00E5FF), width: 8),
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 10)],
        );
        break;
      case 'kawaii':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10)],
        );
        break;
      case 'aventura':
        deco = BoxDecoration(
          color: const Color(0xFFF5E6CA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8D6E63), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(2, 2))],
        );
        break;
      default: // solido
        deco = BoxDecoration(
          color: color,
          borderRadius: _getBorderRadius(esMio, radius),
        );
    }

    final textColor = estilo == 'neon' ? color : (color.computeLuminance() > 0.5 ? Colors.black : Colors.white);

    return Row(
      mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!esMio && avatar != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatar)),
          ),
        Flexible(
          child: Column(
            crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: esMio ? 0 : 4, 
                  right: esMio ? 4 : 0, 
                  bottom: 2
                ),
                child: Text(nombre, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: colorNombre)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: deco,
                child: Text(
                  texto, 
                  style: GoogleFonts.inter(
                    color: textColor, 
                    fontSize: _perso.fontSize.toDouble() - 2,
                    fontWeight: (estilo == 'neon' || estilo == 'robot') ? FontWeight.bold : FontWeight.normal,
                  )
                ),
              ),
              _buildPreviewDecoracion(estilo, esMio),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewDecoracion(String estilo, bool esMio) {
    switch (estilo) {
      case 'amor':
        return Positioned(
          top: -12,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('💖', style: TextStyle(fontSize: 20)),
        );
      case 'vaquero':
        return Positioned(
          top: -18,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('🤠', style: TextStyle(fontSize: 22)),
        );
      case 'bosque':
        return Positioned(
          top: -15,
          left: esMio ? -10 : null,
          right: !esMio ? -10 : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🍃', style: TextStyle(fontSize: 18)),
              Text('🌸', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      case 'cyber':
        return Positioned(
          top: 5,
          right: esMio ? 5 : null,
          left: !esMio ? 5 : null,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
          ),
        );
      case 'kawaii':
        return Stack(
          children: [
            Positioned(top: -15, left: -5, child: const Text('✨', style: TextStyle(fontSize: 18))),
            Positioned(bottom: -10, right: -5, child: const Text('🎀', style: TextStyle(fontSize: 22))),
            Positioned(top: -5, right: 10, child: const Text('⭐', style: TextStyle(fontSize: 12))),
          ],
        );
      case 'aventura':
        return Positioned(
          top: -18,
          right: 0,
          child: const Text('📜', style: TextStyle(fontSize: 24)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  BorderRadius _getBorderRadius(bool esMio, double radius) {
    if (esMio) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: const Radius.circular(4),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
        bottomLeft: const Radius.circular(4),
      );
    }
  }

  Widget _buildColorPicker(String label, String? currentHex, Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _paletaColores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = _paletaColores[index];
              final hex = _colorToHex(color);
              final isSelected = currentHex == hex;
              
              return GestureDetector(
                onTap: () => onSelected(hex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 3),
                    boxShadow: [if (isSelected) BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShapePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forma de las burbujas', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildShapeOption('redondeada', 'Redondeadas', Icons.rounded_corner),
            const SizedBox(width: 12),
            _buildShapeOption('cuadrada', 'Cuadradas', Icons.crop_square),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeOption(String value, String label, IconData icon) {
    final isSelected = _perso.formaBurbuja == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _perso = _copyPerso(formaBurbuja: value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF28B50).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFF28B50) : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFF28B50) : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? const Color(0xFFF28B50) : Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tamaño de fuente', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: _perso.fontSize.toDouble(),
                min: 12,
                max: 24,
                divisions: 6,
                activeColor: const Color(0xFFF28B50),
                onChanged: (v) => setState(() => _perso = _copyPerso(fontSize: v.toInt())),
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 24)),
          ],
        ),
      ],
    );
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      debugPrint('Error parsing color $hex: $e');
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
