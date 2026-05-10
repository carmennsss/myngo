import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



// Campo de texto con estilo propio de Myngo (borde, icono, validación).
// Lo reutilizamos en los formularios de login, registro y edición de perfil.
class CampoTextoPersonalizado extends StatefulWidget {
  // El texto que flota encima del campo (etiqueta)
  final String etiqueta;

  // Icono a la izquierda para dar contexto visual
  final IconData icono;

  // Controlador para leer y escribir el valor del campo
  final TextEditingController controlador;

  // Para saber si el campo tiene el foco y cambiar colores
  final FocusNode nodoEnfoque;

  // Si es true, oculta el texto con asteriscos y muestra el botón del ojo
  final bool esContrasena;

  // Qué hacer cuando el usuario escribe algo
  final Function(String)? alCambiar;

  // Para notificar al padre cuando se activa/desactiva ver la contraseña
  final ValueChanged<bool>? alCambiarVisibilidad;

  // Tipo de teclado que aparece (email, numérico, etc.)
  final TextInputType? tipoTeclado;

  // Validador para mostrar mensajes de error bajo el campo
  final String? Function(String?)? validador;

  // Cuántas líneas puede crecer (para bio o comentarios largos)
  final int? maxLineas;

  // Altura mínima del campo
  final int? minLineas;

  // Hints para que el móvil sugiera el email guardado o la contraseña
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
  // Estado local: si la contraseña está visible o no
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
