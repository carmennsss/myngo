import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _estaGuardando = false;

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

  Widget _buildPreview() {
    final colorMio = _colorFromHex(_perso.colorBurbujaMio) ?? const Color(0xFFF28B50);
    final colorOtro = _colorFromHex(_perso.colorBurbujaOtro) ?? const Color(0xFFEEEEEE);
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
        color: Colors.white,
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
              color: const Color(0xFFFBE9E0).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'VISTA PREVIA EN TIEMPO REAL', 
              style: GoogleFonts.outfit(
                fontSize: 9, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFFC35E34),
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
                child: Container(
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
                      color: const Color(0xFF4A4440), 
                      fontSize: _perso.fontSize.toDouble(),
                    )
                  ),
                ),
              ),
              const SizedBox(width: 40), // Espacio para que no ocupe todo
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
                child: Container(
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
                      color: Colors.white, 
                      fontSize: _perso.fontSize.toDouble(),
                      fontWeight: FontWeight.w500,
                    )
                  ),
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
