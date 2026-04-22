import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstadoVacioCargando extends StatefulWidget {
  final IconData icon;
  final String message;
  final Duration delay;
  final Color baseColor;

  const EstadoVacioCargando({
    super.key,
    required this.icon,
    required this.message,
    this.delay = const Duration(milliseconds: 600),
    this.baseColor = const Color(0xFFF28B50), // Color naranja Myngo por defecto
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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
