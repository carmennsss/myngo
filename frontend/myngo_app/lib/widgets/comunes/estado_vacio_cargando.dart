import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Pantalla de espera inteligente: primero muestra un spinner durante un breve delay
// y luego, si no hay datos, muestra el icono y mensaje de "lista vacía".
// El delay evita que el estado vacío parpadee cuando los datos llegan rápido.
class EstadoVacioCargando extends StatefulWidget {
  final IconData icon;     // El icono del estado vacío (ej. un gato durmiendo)
  final String message;    // Mensaje explicativo para el usuario
  final Duration delay;    // Cuánto tiempo mostramos el spinner antes de rendernos
  final Color baseColor;   // Color del spinner y del icono
  final Color? textColor;  // Color del texto del mensaje

  const EstadoVacioCargando({
    super.key,
    required this.icon,
    required this.message,
    this.delay = const Duration(milliseconds: 600),
    this.baseColor = const Color(0xFFF28B50),
    this.textColor,
  });

  @override
  State<EstadoVacioCargando> createState() => _EstadoVacioCargandoState();
}

class _EstadoVacioCargandoState extends State<EstadoVacioCargando> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: widget.baseColor),
        ),
      );
    }
    
    final finalTextColor = widget.textColor ?? Colors.grey;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 64, color: finalTextColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: finalTextColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
