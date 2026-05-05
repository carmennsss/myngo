import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/boton_carga.dart';
import '../../widgets/gatos_animados.dart';
import '../../services/servicio_usuarios.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/boton_idioma.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  Offset _posicionMouse = Offset.zero;
  EstadoMonstruo _estadoGatos = EstadoMonstruo.inactivo;
  double _ratioMirada = 0.5;

  void _onGatosChange(EstadoMonstruo estado, double ratio) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _estadoGatos = estado;
          _ratioMirada = ratio;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (evento) {
        setState(() {
          _posicionMouse = evento.position;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF5F1),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SizedBox.expand(
            child: Container(
              color: const Color(0xFFFEF5F1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      _buildContenido(context, constraints),
                      const Positioned(
                        top: 20,
                        right: 20,
                        child: BotonIdioma(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(BuildContext context, BoxConstraints constraints) {
    final isDesktop = constraints.maxWidth > 900;
    
    if (isDesktop) {
                    return Row(
                      children: [
                        // Lado Izquierdo: Visual/Fun Premium
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFC35E34).withOpacity(0.02),
                              border: Border(right: BorderSide(color: const Color(0xFFC35E34).withOpacity(0.05))),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: 40,
                                  left: 60,
                                  child: _BurbujaDecorativa(size: 180, color: const Color(0xFF248EA6).withOpacity(0.08)),
                                ),
                                Positioned(
                                  bottom: 100,
                                  right: 80,
                                  child: _BurbujaDecorativa(size: 240, color: const Color(0xFFC35E34).withOpacity(0.08)),
                                ),
                                Positioned(
                                  top: 200,
                                  right: 40,
                                  child: _BurbujaDecorativa(size: 120, color: const Color(0xFFF29C50).withOpacity(0.05)),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC35E34).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.pets, color: Color(0xFFC35E34), size: 48),
                                      ),
                                      const SizedBox(height: 32),
                                      // Los Gatos a la izquierda
                                      GatosAnimados(
                                        estado: _estadoGatos,
                                        ratioMirada: _ratioMirada,
                                        posicionMouseGlobal: _posicionMouse,
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'MYNGO',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFC35E34),
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 8.0,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Lado Derecho: Formulario
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: TarjetaLogin(
                                  posicionMouse: _posicionMouse,
                                  onGatosChange: _onGatosChange,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
    
                  // Vista Móvil
                  return Center(
                    child: SingleChildScrollView(
                      primary: false,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pets, color: Color(0xFFC35E34), size: 32),
                                const SizedBox(width: 12),
                                Text(
                                  'MYNGO',
                                  style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GatosAnimados(
                              estado: _estadoGatos,
                              ratioMirada: _ratioMirada,
                              posicionMouseGlobal: _posicionMouse,
                            ),
                            const SizedBox(height: 32),
                            TarjetaLogin(
                              posicionMouse: _posicionMouse,
                              onGatosChange: _onGatosChange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
  }
}

class _BurbujaDecorativa extends StatelessWidget {
  final double size;
  final Color color;
  const _BurbujaDecorativa({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// Componente visual principal que contiene el formulario de inicio de sesión.
class TarjetaLogin extends StatefulWidget {
  /// Posición del ratón para sincronizar la mirada de los gatos.
  final Offset posicionMouse;
  final Function(EstadoMonstruo, double)? onGatosChange;
  
  const TarjetaLogin({super.key, this.posicionMouse = Offset.zero, this.onGatosChange});

  @override
  State<TarjetaLogin> createState() => _TarjetaLoginState();
}

class _TarjetaLoginState extends State<TarjetaLogin> {
  final _nodoEnfoqueEmail = FocusNode();
  final _nodoEnfoquePassword = FocusNode();
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();

  /// Estado observable para manejar la visibilidad del indicador de carga.
  final _estaCargando = ValueNotifier<bool>(false);
  final _llaveFormulario = GlobalKey<FormState>();
  
  /// Instancia del servicio para la autenticación con el backend.
  final _servicioUsuarios = ServicioUsuarios();

  /// Estado actual que determina la animación y expresión de los gatos.
  EstadoMonstruo _estadoGatos = EstadoMonstruo.inactivo;

  /// Factor que suaviza el movimiento de la mirada de los gatos (0.0 a 1.0).
  double _ratioMirada = 0.5;

  /// Controla la visibilidad enmascarada del campo de contraseña.
  bool _esPasswordVisible = false;

  /// Estado de la casilla "Recuérdame"
  bool _recordarme = false;

  @override
  void initState() {
    super.initState();
    _nodoEnfoqueEmail.addListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.addListener(_alCambiarEnfoque);
    _checkExistingTokenAndRedirect(); 
    _cargarCredencialesGuardadas();
  }

  Future<void> _checkExistingTokenAndRedirect() async {
    final token = await _servicioUsuarios.obtenerToken();
    if (token != null && mounted) {
      // Si ya hay token, vamos directo a inicio
      context.go('/inicio');
    }
  }

  Future<void> _cargarCredencialesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final emailGuardado = prefs.getString('recordar_email');
    final passGuardada = prefs.getString('recordar_pass');
    
    if (mounted) {
      if (emailGuardado != null && passGuardada != null) {
        setState(() {
          _recordarme = true;
          _controladorEmail.text = emailGuardado;
          _controladorPassword.text = passGuardada;
        });
      } else {
        setState(() {
          _recordarme = false;
          _controladorEmail.clear();
          _controladorPassword.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _nodoEnfoqueEmail.removeListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.removeListener(_alCambiarEnfoque);
    _nodoEnfoqueEmail.dispose();
    _nodoEnfoquePassword.dispose();
    _controladorEmail.dispose();
    _controladorPassword.dispose();
    _estaCargando.dispose();
    super.dispose();
  }

  /// Gestiona el cambio de estado de los gatos al enfocar los campos de texto.
  void _alCambiarEnfoque() {
    if (_nodoEnfoquePassword.hasFocus) {
      _estadoGatos = _esPasswordVisible ? EstadoMonstruo.escondido : EstadoMonstruo.mirando;
    } else if (_nodoEnfoqueEmail.hasFocus) {
      _estadoGatos = EstadoMonstruo.mirando;
    } else {
      if (_estadoGatos != EstadoMonstruo.feliz && _estadoGatos != EstadoMonstruo.triste) {
        _estadoGatos = EstadoMonstruo.inactivo;
      }
    }
    _notificarCambioGato();
  }

  void _notificarCambioGato() {
    widget.onGatosChange?.call(_estadoGatos, _ratioMirada);
  }

  /// Alterna la visibilidad del texto en el campo de contraseña.
  void _alCambiarVisibilidadPassword(bool esVisible) {
    setState(() {
      _esPasswordVisible = esVisible;
    });
    if (_nodoEnfoquePassword.hasFocus) {
      _estadoGatos = _esPasswordVisible ? EstadoMonstruo.escondido : EstadoMonstruo.mirando;
      _notificarCambioGato();
    }
  }

  /// Calcula el ratio de la mirada según la longitud del texto ingresado.
  void _actualizarPosicionMirada(String valor) {
    if (_nodoEnfoqueEmail.hasFocus) {
      setState(() {
        _ratioMirada = (valor.length / 30).clamp(0.0, 1.0);
      });
      _notificarCambioGato();
    }
  }

  /// Procesa el intento de inicio de sesión conectando con el servicio de usuarios.
  Future<void> _iniciarSesion() async {
    _nodoEnfoqueEmail.unfocus();
    _nodoEnfoquePassword.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      _estadoGatos = EstadoMonstruo.calculando;
      _notificarCambioGato();

      try {
        final respuesta = await _servicioUsuarios.iniciarSesion(
          _controladorEmail.text.trim(),
          _controladorPassword.text.trim(),
        );

        _estaCargando.value = false;

        if (!mounted) return;

        if (respuesta.exito) {
          final prefs = await SharedPreferences.getInstance();
          if (_recordarme) {
            await prefs.setString('recordar_email', _controladorEmail.text);
            await prefs.setString('recordar_pass', _controladorPassword.text);
          } else {
            await prefs.remove('recordar_email');
            await prefs.remove('recordar_pass');
          }

          if (!mounted) return;
          _estadoGatos = EstadoMonstruo.feliz;
          _notificarCambioGato();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(respuesta.mensaje),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/inicio');
        } else {
          setState(() {
            _estadoGatos = EstadoMonstruo.triste;
          });
          _notificarCambioGato();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(respuesta.mensaje),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _estadoGatos = EstadoMonstruo.inactivo;
              });
              _notificarCambioGato();
            }
          });
        }
      } catch (e) {
        _estaCargando.value = false;
        if (!mounted) return;
        
        setState(() {
          _estadoGatos = EstadoMonstruo.triste;
        });
        _notificarCambioGato();
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error de conexión. Inténtalo de nuevo.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _estadoGatos = EstadoMonstruo.inactivo;
            });
            _notificarCambioGato();
          }
        });
      }
    } else {
      _estadoGatos = EstadoMonstruo.triste;
      _notificarCambioGato();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _estadoGatos = EstadoMonstruo.inactivo;
          });
          _notificarCambioGato();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF2D0BD).withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF29C50).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
      child: Form(
        key: _llaveFormulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Miau-bienvenido!',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4A4440),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Entra en tu rincón michi',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AutofillGroup(
              child: Column(
                children: [
                  CampoTextoPersonalizado(
                    etiqueta: 'Email',
                    icono: Icons.alternate_email_rounded,
                    controlador: _controladorEmail,
                    nodoEnfoque: _nodoEnfoqueEmail,
                    alCambiar: _actualizarPosicionMirada,
                    tipoTeclado: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return '¿Tu email? 🐾';
                      if (!valor.contains('@')) return 'Email no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CampoTextoPersonalizado(
                    etiqueta: 'Contraseña',
                    icono: Icons.lock_open_rounded,
                    controlador: _controladorPassword,
                    nodoEnfoque: _nodoEnfoquePassword,
                    esContrasena: true,
                    autofillHints: const [AutofillHints.password],
                    alCambiarVisibilidad: _alCambiarVisibilidadPassword,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return 'Falta la clave michi';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _recordarme = !_recordarme),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _recordarme,
                          onChanged: (valor) => setState(() => _recordarme = valor!),
                          activeColor: const Color(0xFFF28B50),
                          side: BorderSide(color: Colors.grey.shade700, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recuérdame',
                        style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/recuperar_contrasena'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFF29C50)),
                  child: const Text('¿Perdiste tu clave?'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            BotonCarga(
              alPresionar: _iniciarSesion,
              notificadorCargando: _estaCargando,
              texto: 'ENTRAR 🐾',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿No eres parte?',
                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                ),
                TextButton(
                  onPressed: () => context.push('/registro'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFF28B50)),
                  child: const Text(
                    'Únete ahora',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

