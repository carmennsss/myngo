import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tolgee/tolgee.dart';
import '../../services/servicio_usuarios.dart';
import '../../utils/tr_helper.dart';
import '../../widgets/toast_service.dart';

class PantallaConfirmarRecuperacion extends StatefulWidget {
  final String token;
  const PantallaConfirmarRecuperacion({super.key, required this.token});

  @override
  State<PantallaConfirmarRecuperacion> createState() => _PantallaConfirmarRecuperacionState();
}

class _PantallaConfirmarRecuperacionState extends State<PantallaConfirmarRecuperacion> {
  final _servicio = ServicioUsuarios();
  bool _procesando = true;
  bool _exito = false;
  String _mensaje = '';
  String? _nuevaPassword;

  @override
  void initState() {
    super.initState();
    _confirmar();
  }

  Future<void> _confirmar() async {
    final res = await _servicio.confirmarRecuperacion(widget.token);
    if (mounted) {
      setState(() {
        _procesando = false;
        _exito = res.exito;
        _mensaje = res.mensaje;
        _nuevaPassword = res.datos;
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
                      'Restableciendo contraseña...',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Icon(
                      _exito ? Icons.lock_open_rounded : Icons.error_rounded,
                      size: 80,
                      color: _exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _exito ? '¡Acceso Recuperado! 🐾' : 'Ups... algo ha fallado',
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
                    if (_exito && _nuevaPassword != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Tu nueva contraseña temporal es:',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _nuevaPassword!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFC35E34),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFFC35E34)),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _nuevaPassword!));
                                    ToastService.showInfo(context, 'Copiado al portapapeles');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cópiala y cámbiala en tu perfil tras iniciar sesión.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC35E34),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_exito ? 'IR AL LOGIN' : 'VOLVER AL LOGIN'),
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
