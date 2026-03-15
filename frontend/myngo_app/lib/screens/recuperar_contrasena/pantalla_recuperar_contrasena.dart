import 'package:flutter/material.dart';
import '../../widgets/campo_texto_personalizado.dart';

/// Pantalla de recuperación de contraseña.
///
/// Muestra un formulario con un campo de correo electrónico y un botón
/// para enviar el código de recuperación. Sin funcionalidad por el momento.
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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controladorEmail.dispose();
    _nodoEnfoqueEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0C3FC),
              Color(0xFF8EC5FC),
            ],
          ),
        ),
        child: Center(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 40.0,
                        ),
                        child: Form(
                          key: _llaveFormulario,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Icono decorativo ──
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9B8BFC),
                                      Color(0xFF6C63FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
                                          .withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),

                              // ── Título ──
                              Text(
                                '¿Olvidaste tu contraseña?',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3142),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),

                              // ── Subtítulo ──
                              Text(
                                'Introduce tu correo electrónico y te\nenviamos un código de recuperación.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF9094A6),
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 36),

                              // ── Campo email ──
                              CampoTextoPersonalizado(
                                etiqueta: 'Correo Electrónico',
                                icono: Icons.email_outlined,
                                controlador: _controladorEmail,
                                nodoEnfoque: _nodoEnfoqueEmail,
                                tipoTeclado: TextInputType.emailAddress,
                                validador: (valor) {
                                  if (valor == null || valor.isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  if (!valor.contains('@')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── Botón enviar código ──
                              _BotonEnviarCodigo(
                                alPresionar: () {
                                  _nodoEnfoqueEmail.unfocus();
                                  _llaveFormulario.currentState?.validate();
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── Enlace volver al login ──
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Volver al inicio de sesión'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6C63FF),
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
      ),
    );
  }
}

/// Botón animado para enviar el código de recuperación.
class _BotonEnviarCodigo extends StatefulWidget {
  final VoidCallback alPresionar;

  const _BotonEnviarCodigo({required this.alPresionar});

  @override
  State<_BotonEnviarCodigo> createState() => _BotonEnviarCodigoState();
}

class _BotonEnviarCodigoState extends State<_BotonEnviarCodigo> {
  bool _estaHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _estaHover = true),
      onExit: (_) => setState(() => _estaHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _estaHover
                ? [const Color(0xFF8B80FF), const Color(0xFF5A52E0)]
                : [const Color(0xFF9B8BFC), const Color(0xFF6C63FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF)
                  .withOpacity(_estaHover ? 0.45 : 0.30),
              blurRadius: _estaHover ? 20 : 12,
              offset: Offset(0, _estaHover ? 6 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.alPresionar,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Enviar código',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
