import 'package:flutter/material.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/gatos_registro_animados.dart';
import '../../services/servicio_usuarios.dart';
/// Pantalla de registro con fondo degradado, idéntica en estética al login
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  Offset _posicionMouse = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (evento) {
        setState(() {
          _posicionMouse = evento.position;
        });
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0C3FC), // Morado Pastel
                Color(0xFF8EC5FC), // Azul Pastel
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 450,
                  ),
                  child: TarjetaRegistro(posicionMouse: _posicionMouse),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca central con sombras suaves — misma estructura que TarjetaLogin
class TarjetaRegistro extends StatefulWidget {
  final Offset posicionMouse;
  const TarjetaRegistro({super.key, this.posicionMouse = Offset.zero});

  @override
  State<TarjetaRegistro> createState() => _TarjetaRegistroState();
}

class _TarjetaRegistroState extends State<TarjetaRegistro> {
  final _servicioUsuarios = ServicioUsuarios();
  final _nodoEnfoqueNombre = FocusNode();
  final _nodoEnfoqueEmail = FocusNode();
  final _nodoEnfoquePassword = FocusNode();

  final _controladorNombre = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();

  final _llaveFormulario = GlobalKey<FormState>();
  final _estaCargando = ValueNotifier<bool>(false);

  EstadoMonstruo _estadoGatos = EstadoMonstruo.inactivo;
  double _ratioMirada = 0.5;
  bool _esPasswordVisible = false;
  bool _aceptaTerminos = false;

  @override
  void initState() {
    super.initState();
    _nodoEnfoqueNombre.addListener(_alCambiarEnfoque);
    _nodoEnfoqueEmail.addListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.addListener(_alCambiarEnfoque);
  }

  @override
  void dispose() {
    _nodoEnfoqueNombre.removeListener(_alCambiarEnfoque);
    _nodoEnfoqueEmail.removeListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.removeListener(_alCambiarEnfoque);
    _nodoEnfoqueNombre.dispose();
    _nodoEnfoqueEmail.dispose();
    _nodoEnfoquePassword.dispose();
    _controladorNombre.dispose();
    _controladorEmail.dispose();
    _controladorPassword.dispose();
    _estaCargando.dispose();
    super.dispose();
  }

  void _alCambiarEnfoque() {
    if (_nodoEnfoquePassword.hasFocus) {
      setState(() {
        _estadoGatos = _esPasswordVisible
            ? EstadoMonstruo.escondido
            : EstadoMonstruo.mirando;
      });
    } else if (_nodoEnfoqueEmail.hasFocus || _nodoEnfoqueNombre.hasFocus) {
      setState(() {
        _estadoGatos = EstadoMonstruo.mirando;
      });
    } else {
      if (_estadoGatos != EstadoMonstruo.feliz &&
          _estadoGatos != EstadoMonstruo.triste) {
        setState(() {
          _estadoGatos = EstadoMonstruo.inactivo;
        });
      }
    }
  }

  void _alCambiarVisibilidadPassword(bool esVisible) {
    setState(() {
      _esPasswordVisible = esVisible;
      if (_nodoEnfoquePassword.hasFocus) {
        _estadoGatos = _esPasswordVisible
            ? EstadoMonstruo.escondido
            : EstadoMonstruo.mirando;
      }
    });
  }

  void _actualizarPosicionMirada(String valor) {
    if (_nodoEnfoqueEmail.hasFocus || _nodoEnfoqueNombre.hasFocus) {
      setState(() {
        _ratioMirada = (valor.length / 30).clamp(0.0, 1.0);
      });
    }
  }

  // Igual que _iniciarSesion en el login: valida y pone triste si hay error
  Future<void> _crearCuenta() async {
    // 1. Quitamos el foco de los teclados para que bajen
    _nodoEnfoqueNombre.unfocus();
    _nodoEnfoqueEmail.unfocus();
    _nodoEnfoquePassword.unfocus();

    // 2. Validación de los campos de texto
    if (_llaveFormulario.currentState!.validate()) {
      
      // 3. Validación extra: ¿Aceptó los términos?
      if (!_aceptaTerminos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar los términos y condiciones'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _estadoGatos = EstadoMonstruo.triste);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _estadoGatos = EstadoMonstruo.inactivo);
        });
        return;
      }

      // 4. Activamos estado de carga
      _estaCargando.value = true;
      setState(() {
        _estadoGatos = EstadoMonstruo.calculando;
      });

      // 5. Llamada al servicio (Asíncrona)
      final respuesta = await _servicioUsuarios.registrarse(
        _controladorNombre.text,
        _controladorEmail.text,
        _controladorPassword.text,
      );

      _estaCargando.value = false;

      // Comprobamos que la pantalla siga existiendo
      if (!mounted) return;

      // 6. Gestionamos la respuesta de Django
      if (respuesta.exito) {
        setState(() => _estadoGatos = EstadoMonstruo.feliz);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Opcional: Redirigir al login tras 2 segundos de éxito
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        });

      } else {
        // Error (Email ya existe, nombre muy corto, etc.)
        setState(() => _estadoGatos = EstadoMonstruo.triste);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Volver al estado normal tras el susto
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _estadoGatos = EstadoMonstruo.inactivo);
        });
      }
    } else {
      // Formulario inválido localmente
      setState(() => _estadoGatos = EstadoMonstruo.triste);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _estadoGatos = EstadoMonstruo.inactivo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Lavanda muy suave — diferente al blanco puro del login
        color: const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gatos alternativos exclusivos del registro
          GatosRegistroAnimados(
            estado: _estadoGatos,
            ratioMirada: _ratioMirada,
            posicionMouseGlobal: widget.posicionMouse,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _llaveFormulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Título ──
                  Text(
                    '¡Únete a Myngo!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu cuenta para empezar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9094A6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── Campo: Nombre de usuario ──
                  CampoTextoPersonalizado(
                    etiqueta: 'Nombre de usuario',
                    icono: Icons.person_outline,
                    controlador: _controladorNombre,
                    nodoEnfoque: _nodoEnfoqueNombre,
                    alCambiar: _actualizarPosicionMirada,
                    tipoTeclado: TextInputType.name,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa tu nombre de usuario';
                      }
                      if (valor.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Campo: Email ──
                  CampoTextoPersonalizado(
                    etiqueta: 'Correo Electrónico',
                    icono: Icons.email_outlined,
                    controlador: _controladorEmail,
                    nodoEnfoque: _nodoEnfoqueEmail,
                    alCambiar: _actualizarPosicionMirada,
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
                  const SizedBox(height: 16),

                  // ── Campo: Contraseña ──
                  CampoTextoPersonalizado(
                    etiqueta: 'Contraseña',
                    icono: Icons.lock_outline,
                    controlador: _controladorPassword,
                    nodoEnfoque: _nodoEnfoquePassword,
                    esContrasena: true,
                    alCambiarVisibilidad: _alCambiarVisibilidadPassword,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (valor.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Checkbox: Términos y condiciones ──
                  Row(
                    children: [
                      Checkbox(
                        value: _aceptaTerminos,
                        onChanged: (valor) {
                          setState(() {
                            _aceptaTerminos = valor ?? false;
                          });
                        },
                        activeColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            children: const [
                              TextSpan(text: 'Acepto los '),
                              TextSpan(
                                text: 'Términos y condiciones',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Botón Crear cuenta (misma estética que BotonCarga) ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _crearCuenta,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Enlace: Volver al login ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
