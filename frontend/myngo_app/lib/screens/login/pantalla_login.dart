import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/boton_carga.dart';
import '../../widgets/gatos_animados.dart';
import '../../services/servicio_usuarios.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/boton_idioma.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Pantalla de entrada a Myngo. En escritorio muestra los gatos animados a la izquierda
// y el formulario a la derecha; en móvil todo va en columna.
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  Offset _posicionMouse = Offset.zero;
  EstadoMonstruo _estadoGatos = EstadoMonstruo.inactivo;
  double _ratioMirada = 0.5;

  // Notifica el nuevo estado del gato animado al padre para sincronizar la animación
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
    return Builder(
      builder: (context) {
        return MouseRegion(
          onHover: (evento) {
            setState(() {
              _posicionMouse = evento.position;
            });
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFEF5F1),
            body: SafeArea(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SizedBox.expand(
                  child: Container(
                    color: const Color(0xFFFEF5F1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            _buildContenido(context, constraints, tr),
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
          ),
        );
      },
    );
  }

  // Monta el layout adaptativo (columna en móvil, dos columnas en escritorio)
  Widget _buildContenido(BuildContext context, BoxConstraints constraints, dynamic tr) {
    final isDesktop = constraints.maxWidth > 900;
    
    if (isDesktop) {
      return Row(
        children: [
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
                        GatosAnimados(
                          estado: _estadoGatos,
                          ratioMirada: _ratioMirada,
                          posicionMouseGlobal: _posicionMouse,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          tr('commonAppTitle'),
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
                    tr: tr,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
                    tr('commonAppTitle'),
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
                tr: tr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Circulo difuso decorativo del fondo, no tiene lógica de negocio
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

// El formulario de login: email, contraseña, "Recþrdame" y botón.
// También controla el estado de los gatos (miran cuando escribes, se tapan con la pass).
class TarjetaLogin extends StatefulWidget {
  final Offset posicionMouse;
  final Function(EstadoMonstruo, double)? onGatosChange;
  final dynamic tr;
  
  const TarjetaLogin({super.key, this.posicionMouse = Offset.zero, this.onGatosChange, required this.tr});

  @override
  State<TarjetaLogin> createState() => _TarjetaLoginState();
}

class _TarjetaLoginState extends State<TarjetaLogin> {
  final _nodoEnfoqueEmail = FocusNode();
  final _nodoEnfoquePassword = FocusNode();
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();

  final _estaCargando = ValueNotifier<bool>(false);
  final _llaveFormulario = GlobalKey<FormState>();
  final _servicioUsuarios = ServicioUsuarios();
  EstadoMonstruo _estadoGatos = EstadoMonstruo.inactivo;
  double _ratioMirada = 0.5;
  bool _esPasswordVisible = false;
  bool _recordarme = false;

  @override
  void initState() {
    super.initState();
    _nodoEnfoqueEmail.addListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.addListener(_alCambiarEnfoque);
    _checkExistingTokenAndRedirect(); 
    _cargarCredencialesGuardadas();
  }

  // Si ya hay token guardado, salta directo al inicio sin mostrar el login
  Future<void> _checkExistingTokenAndRedirect() async {
    // Pequeño retardo para dar tiempo a que SharedPreferences se asiente si venimos de un logout
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final preferencias = await SharedPreferences.getInstance();
    final token = preferencias.getString('auth_token');
    
    // Solo redirigimos si el token existe
    if (token != null && token.isNotEmpty && mounted) {
      context.go('/inicio');
    }
  }

  // Rellena el email y la pass si el usuario marcó "Recþrdame" en una sesión anterior
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

  // Mueve los ojos del gato según qué campo tiene el foco
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

  // Dispara el callback para que el padre repinte el gato
  void _notificarCambioGato() {
    widget.onGatosChange?.call(_estadoGatos, _ratioMirada);
  }

  // Cuando el usuario activa/desactiva ver la pass, el gato se tapa los ojos o vuelve a mirar
  void _alCambiarVisibilidadPassword(bool esVisible) {
    setState(() {
      _esPasswordVisible = esVisible;
    });
    if (_nodoEnfoquePassword.hasFocus) {
      _estadoGatos = _esPasswordVisible ? EstadoMonstruo.escondido : EstadoMonstruo.mirando;
      _notificarCambioGato();
    }
  }

  // Mueve los ojos del gato siguiendo el cursor del ratón mientras escribes el email
  void _actualizarPosicionMirada(String valor) {
    if (_nodoEnfoqueEmail.hasFocus) {
      setState(() {
        _ratioMirada = (valor.length / 30).clamp(0.0, 1.0);
      });
      _notificarCambioGato();
    }
  }

  // Llama al servicio de login y navega al inicio si va bien, o muestra el error si falla
  Future<void> _iniciarSesion() async {
    _nodoEnfoqueEmail.unfocus();
    _nodoEnfoquePassword.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      _estadoGatos = EstadoMonstruo.calculando;
      _notificarCambioGato();

      try {
        // Medida de seguridad: limpiar cualquier rastro antes de intentar nuevo login
        await _servicioUsuarios.limpiarToken();

        final respuesta = await _servicioUsuarios.iniciarSesion(
          _controladorEmail.text.trim(),
          _controladorPassword.text.trim(),
        );

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

          if (respuesta.errores != null) {

          }
          
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
              duration: const Duration(seconds: 4),
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
        if (!mounted) return;
        
        setState(() {
          _estadoGatos = EstadoMonstruo.triste;
        });
        _notificarCambioGato();
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.tr('authConnectionError')}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } finally {
        // ASEGURAMOS que el botón siempre vuelva a su estado normal
        if (mounted) {
          _estaCargando.value = false;
        }
      }
    } else {
      _estadoGatos = EstadoMonstruo.triste;
      _notificarCambioGato();
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Form(
        key: _llaveFormulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.tr('authLoginWelcome'),
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4A4440),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.tr('authLoginSubtitle'),
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
                    etiqueta: widget.tr('formEmailLabel'),
                    icono: Icons.alternate_email_rounded,
                    controlador: _controladorEmail,
                    nodoEnfoque: _nodoEnfoqueEmail,
                    alCambiar: _actualizarPosicionMirada,
                    tipoTeclado: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return widget.tr('formUsernameHint');
                      if (!valor.contains('@')) return widget.tr('errorInvalidEmail');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CampoTextoPersonalizado(
                    etiqueta: widget.tr('formPasswordLabel'),
                    icono: Icons.lock_open_rounded,
                    controlador: _controladorPassword,
                    nodoEnfoque: _nodoEnfoquePassword,
                    esContrasena: true,
                    autofillHints: const [AutofillHints.password],
                    alCambiarVisibilidad: _alCambiarVisibilidadPassword,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return widget.tr('authPasswordRequired');
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
                Flexible(
                  child: GestureDetector(
                    onTap: () => setState(() => _recordarme = !_recordarme),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.tr('authRememberMe'),
                            style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/recuperar_contrasena'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF29C50),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    widget.tr('authForgotPassword'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            BotonCarga(
              alPresionar: _iniciarSesion,
              notificadorCargando: _estaCargando,
              texto: widget.tr('authLoginButton'),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.tr('authRegisterLink'),
                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => context.push('/registro'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF29C50),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    widget.tr('authRegisterButton').replaceAll(' 🐾', ''),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
