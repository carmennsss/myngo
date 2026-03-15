import 'package:flutter/material.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../services/servicio_usuarios.dart';
import '../../widgets/boton_carga.dart';

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
    _estaCargando.dispose();
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
                              BotonCarga(
                                alPresionar: _procesarRecuperacion,
                                notificadorCargando: _estaCargando,
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

  /// Método para procesar la solicitud de recuperación de contraseña.
  Future<void> _procesarRecuperacion() async {
    _nodoEnfoqueEmail.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;

      final respuesta = await _servicioUsuarios.recuperarContrasena(
        _controladorEmail.text.trim(),
      );

      _estaCargando.value = false;

      if (!mounted) return;

      if (respuesta.exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Esperamos un momento y volvemos al login
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
