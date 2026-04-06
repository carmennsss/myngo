import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../services/servicio_usuarios.dart';
import '../../widgets/boton_carga.dart';

class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() =>
      _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState
    extends State<PantallaRecuperarContrasena>
    with SingleTickerProviderStateMixin {
  final _llaveFormulario = GlobalKey<FormState>();
  final _controladorEmail = TextEditingController();
  final _nodoEnfoqueEmail = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _servicioUsuarios = ServicioUsuarios();
  final _estaCargando = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controladorEmail.dispose();
    _nodoEnfoqueEmail.dispose();
    _estaCargando.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
          ),
        ),
        child: Stack(
          children: [
            // Decoración bubble de fondo
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFF28B50).withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
                            child: Form(
                              key: _llaveFormulario,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Icono con resplandor
                                  Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF28B50), Color(0xFFF29C50)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF28B50).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.lock_reset_rounded, size: 42, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Text(
                                    'Introduce tu email y te enviaremos un código miau-mágico de recuperación.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey.shade400,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 48),
                                  
                                  CampoTextoPersonalizado(
                                    etiqueta: 'Email de recuperación',
                                    icono: Icons.alternate_email_rounded,
                                    controlador: _controladorEmail,
                                    nodoEnfoque: _nodoEnfoqueEmail,
                                    tipoTeclado: TextInputType.emailAddress,
                                    validador: (valor) {
                                      if (valor == null || valor.isEmpty) return 'Danos tu email 🐾';
                                      if (!valor.contains('@')) return 'Email no válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  BotonCarga(
                                    alPresionar: _procesarRecuperacion,
                                    notificadorCargando: _estaCargando,
                                    texto: 'RECUPERAR MI ACCESO',
                                  ),
                                  const SizedBox(height: 28),
                                  
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                      label: Text('ME ACORDÉ, VOLVER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFF29C50),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarRecuperacion() async {
    _nodoEnfoqueEmail.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      final respuesta = await _servicioUsuarios.recuperarContrasena(_controladorEmail.text.trim());
      _estaCargando.value = false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (respuesta.exito) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        });
      }
    }
  }
}
