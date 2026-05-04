import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/sala_chat.dart';
import '../../services/servicio_mensajeria.dart';
import '../../widgets/comunes/boton_tactil.dart';

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
    const Color(0xFFF28B50), // Naranja Myngo
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF9C27B0), // Morado
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Azul
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Verde
    const Color(0xFFCDDC39), // Lima
    const Color(0xFFFFEB3B), // Amarillo
    const Color(0xFFFF9800), // Naranja
    const Color(0xFF795548), // Marrón
    const Color(0xFF9E9E9E), // Gris
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF000000), // Negro
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
        title: Text('Personalizar Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              setState(() => _perso = PersonalizacionChat(
                colorFondo: _perso.colorFondo,
                colorBurbujaMio: hex,
                colorBurbujaOtro: _perso.colorBurbujaOtro,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 16),
            _buildColorPicker('Mensajes de otros', _perso.colorBurbujaOtro, (hex) {
              setState(() => _perso = PersonalizacionChat(
                colorFondo: _perso.colorFondo,
                colorBurbujaMio: _perso.colorBurbujaMio,
                colorBurbujaOtro: hex,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                colorNombreMio: _perso.colorNombreMio,
                colorNombreOtro: _perso.colorNombreOtro,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 32),
            _buildSectionTitle('Colores de Nombres'),
            const SizedBox(height: 16),
            _buildColorPicker('Mi nombre', _perso.colorNombreMio, (hex) {
              setState(() => _perso = PersonalizacionChat(
                colorFondo: _perso.colorFondo,
                colorBurbujaMio: _perso.colorBurbujaMio,
                colorBurbujaOtro: _perso.colorBurbujaOtro,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                colorNombreMio: hex,
                colorNombreOtro: _perso.colorNombreOtro,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 16),
            _buildColorPicker('Nombres de otros', _perso.colorNombreOtro, (hex) {
              setState(() => _perso = PersonalizacionChat(
                colorFondo: _perso.colorFondo,
                colorBurbujaMio: _perso.colorBurbujaMio,
                colorBurbujaOtro: _perso.colorBurbujaOtro,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                colorNombreMio: _perso.colorNombreMio,
                colorNombreOtro: hex,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 32),
            _buildSectionTitle('Fondo del Chat'),
            const SizedBox(height: 16),
            _buildColorPicker('Color de fondo', _perso.colorFondo, (hex) {
              setState(() => _perso = PersonalizacionChat(
                colorFondo: hex,
                colorBurbujaMio: _perso.colorBurbujaMio,
                colorBurbujaOtro: _perso.colorBurbujaOtro,
                colorTextoMio: _perso.colorTextoMio,
                colorTextoOtro: _perso.colorTextoOtro,
                colorNombreMio: _perso.colorNombreMio,
                colorNombreOtro: _perso.colorNombreOtro,
                formaBurbuja: _perso.formaBurbuja,
                fontSize: _perso.fontSize,
                tema: _perso.tema,
              ));
            }),
            const SizedBox(height: 32),
            _buildSectionTitle('Apariencia Visual'),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFBE9E0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC35E34).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (colorFondo.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'VISTA PREVIA EN TIEMPO REAL', 
              style: GoogleFonts.outfit(
                fontSize: 9, 
                fontWeight: FontWeight.w900, 
                color: colorFondo.computeLuminance() > 0.5 ? const Color(0xFFC35E34) : Colors.white,
                letterSpacing: 1.0,
              )
            ),
          ),
          const SizedBox(height: 24),
          // Burbuja del otro
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.sala.esGrupal)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: avatarOtro != null ? NetworkImage(avatarOtro) : null,
                    backgroundColor: Colors.grey[200],
                    child: avatarOtro == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
                  ),
                ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        'Amigo', 
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: colorNombreOtro)
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorOtro,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                          bottomRight: Radius.circular(borderRadius),
                          bottomLeft: const Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        '¡Oye! ¿Has visto los nuevos estilos? 🐾', 
                        style: GoogleFonts.inter(
                          color: colorOtro.computeLuminance() > 0.5 ? const Color(0xFF4A4440) : Colors.white, 
                          fontSize: _perso.fontSize.toDouble(),
                        )
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          // Burbuja mía
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 40),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: Text(
                        'Tú', 
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: colorNombreMio)
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorMio,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                          bottomLeft: Radius.circular(borderRadius),
                          bottomRight: const Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        '¡Sí! Se ven increíbles. Voy a probar este. ✨', 
                        style: GoogleFonts.inter(
                          color: colorMio.computeLuminance() > 0.5 ? Colors.black : Colors.white, 
                          fontSize: _perso.fontSize.toDouble(),
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        onTap: () {
          setState(() => _perso = PersonalizacionChat(
            colorFondo: _perso.colorFondo,
            colorBurbujaMio: _perso.colorBurbujaMio,
            colorBurbujaOtro: _perso.colorBurbujaOtro,
            colorTextoMio: _perso.colorTextoMio,
            colorTextoOtro: _perso.colorTextoOtro,
            colorNombreMio: _perso.colorNombreMio,
            colorNombreOtro: _perso.colorNombreOtro,
            formaBurbuja: value,
            fontSize: _perso.fontSize,
            tema: _perso.tema,
          ));
        },
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
                onChanged: (v) {
                  setState(() => _perso = PersonalizacionChat(
                    colorFondo: _perso.colorFondo,
                    colorBurbujaMio: _perso.colorBurbujaMio,
                    colorBurbujaOtro: _perso.colorBurbujaOtro,
                    colorTextoMio: _perso.colorTextoMio,
                    colorTextoOtro: _perso.colorTextoOtro,
                    colorNombreMio: _perso.colorNombreMio,
                    colorNombreOtro: _perso.colorNombreOtro,
                    formaBurbuja: _perso.formaBurbuja,
                    fontSize: v.toInt(),
                    tema: _perso.tema,
                  ));
                },
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
