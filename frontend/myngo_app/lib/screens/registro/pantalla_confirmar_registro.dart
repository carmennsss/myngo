import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tolgee/tolgee.dart';
import '../../services/servicio_usuarios.dart';
import '../../utils/tr_helper.dart';

class PantallaConfirmarRegistro extends StatefulWidget {
  final String token;
  const PantallaConfirmarRegistro({super.key, required this.token});

  @override
  State<PantallaConfirmarRegistro> createState() => _PantallaConfirmarRegistroState();
}

class _PantallaConfirmarRegistroState extends State<PantallaConfirmarRegistro> {
  final _servicio = ServicioUsuarios();
  bool _procesando = true;
  bool _exito = false;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _confirmar();
  }

  Future<void> _confirmar() async {
    final res = await _servicio.confirmarRegistro(widget.token);
    if (mounted) {
      setState(() {
        _procesando = false;
        _exito = res.exito;
        _mensaje = res.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrWidget(
      builder: (context, tr) {
        return Scaffold(
          backgroundColor: const Color(0xFFFEF5F1),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_procesando) ...[
                    const CircularProgressIndicator(color: Color(0xFFC35E34)),
                    const SizedBox(height: 24),
                    Text(
                      'Activando tu cuenta...',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Icon(
                      _exito ? Icons.check_circle_rounded : Icons.error_rounded,
                      size: 80,
                      color: _exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _exito ? '¡Bienvenido a Myngo! 🐾' : 'Ups... algo ha fallado',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A4440),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mensaje,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC35E34),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_exito ? 'INICIAR SESIÓN' : 'VOLVER AL LOGIN'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
