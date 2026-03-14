import 'package:flutter/material.dart';

/// Campo de texto personalizado con microinteracciones y Material 3
class CampoTextoPersonalizado extends StatefulWidget {
  final String etiqueta;
  final IconData icono;
  final TextEditingController controlador;
  final FocusNode nodoEnfoque;
  final bool esContrasena;
  final Function(String)? alCambiar;
  final ValueChanged<bool>? alCambiarVisibilidad;
  final TextInputType? tipoTeclado;
  final String? Function(String?)? validador;

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
  });

  @override
  State<CampoTextoPersonalizado> createState() => _CampoTextoPersonalizadoState();
}

class _CampoTextoPersonalizadoState extends State<CampoTextoPersonalizado> {
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        prefixIcon: Icon(widget.icono),
        suffixIcon: widget.esContrasena
            ? IconButton(
                icon: Icon(
                  _textoOculto ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _textoOculto = !_textoOculto;
                  });
                  if (widget.alCambiarVisibilidad != null) {
                    widget.alCambiarVisibilidad!(!_textoOculto);
                  }
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
