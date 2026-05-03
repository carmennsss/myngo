import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de campo de texto altamente personalizado con soporte para microinteracciones.
/// 
/// Incluye soporte para enmascaramiento de contraseñas, validación reactiva
/// y estilos siguiendo las líneas de diseño de Material 3.
class CampoTextoPersonalizado extends StatefulWidget {
  /// Texto de sugerencia que aparece sobre el campo.
  final String etiqueta;

  /// Icono descriptivo que se muestra al inicio del campo.
  final IconData icono;

  /// Controlador para gestionar el valor del texto.
  final TextEditingController controlador;

  /// Nodo de enfoque para gestionar el estado de atención del widget.
  final FocusNode nodoEnfoque;

  /// Indica si el campo es para una contraseña (oculta el texto).
  final bool esContrasena;

  /// Callback opcional que se dispara al cambiar el texto.
  final Function(String)? alCambiar;

  /// Callback que se dispara al alternar la visibilidad de la contraseña.
  final ValueChanged<bool>? alCambiarVisibilidad;

  /// Tipo de entrada de teclado (ej. email, número).
  final TextInputType? tipoTeclado;

  /// Función opcional para validar el contenido del campo.
  final String? Function(String?)? validador;

  /// Máximo número de líneas (para áreas de texto).
  final int? maxLineas;

  /// Mínimo número de líneas.
  final int? minLineas;

  /// Sugerencias de autocompletado para el sistema (ej. email, password).
  final Iterable<String>? autofillHints;

  const CampoTextoPersonalizado({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.controlador,
    required this.nodoEnfoque,
    this.esContrasena = false,
    this.alCambiar,
    this.alCambiarVisibilidad,
    this.tipoTeclado,
    this.validador,
    this.maxLineas = 1,
    this.minLineas,
    this.autofillHints,
  });

  @override
  State<CampoTextoPersonalizado> createState() => _CampoTextoPersonalizadoState();
}

class _CampoTextoPersonalizadoState extends State<CampoTextoPersonalizado> {
  /// Controla internamente si el texto está oculto o visible.
  bool _textoOculto = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      focusNode: widget.nodoEnfoque,
      obscureText: widget.esContrasena ? _textoOculto : false,
      onChanged: widget.alCambiar,
      keyboardType: widget.tipoTeclado,
      validator: widget.validador,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLineas,
      minLines: widget.minLineas,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 16),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        labelStyle: GoogleFonts.outfit(
          color: widget.nodoEnfoque.hasFocus 
            ? const Color(0xFFC35E34) 
            : const Color(0xFF4A4440).withOpacity(0.5), 
          fontSize: 14
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(
            widget.icono, 
            color: widget.nodoEnfoque.hasFocus 
              ? const Color(0xFFC35E34) 
              : const Color(0xFFC35E34).withOpacity(0.4), 
            size: 22
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: widget.esContrasena
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    _textoOculto ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFFC35E34).withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _textoOculto = !_textoOculto;
                    });
                    if (widget.alCambiarVisibilidad != null) {
                      widget.alCambiarVisibilidad!(!_textoOculto);
                    }
                  },
                ),
              )
            : null,
      ),
    );
  }
}
