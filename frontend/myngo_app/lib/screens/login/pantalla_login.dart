import 'package:flutter/material.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/boton_carga.dart';
import '../../widgets/gatos_animados.dart';
import '../../services/servicio_usuarios.dart';

/// Pantalla de inicio de sesión de la aplicación.
/// 
/// Presenta una interfaz minimalista con un fondo degradado animado
/// y rastro del cursor para la interacción con los elementos visuales.
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  /// Almacena la posición actual del cursor para las animaciones de los gatos.
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
                  constraints: const BoxConstraints(
                    maxWidth: 450,
                  ),
                  child: TarjetaLogin(posicionMouse: _posicionMouse),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Componente visual principal que contiene el formulario de inicio de sesión.
class TarjetaLogin extends StatefulWidget {
  /// Posición del ratón para sincronizar la mirada de los gatos.
  final Offset posicionMouse;
  
  const TarjetaLogin({super.key, this.posicionMouse = Offset.zero});

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

  @override
  void initState() {
    super.initState();
    _nodoEnfoqueEmail.addListener(_alCambiarEnfoque);
    _nodoEnfoquePassword.addListener(_alCambiarEnfoque);
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
      setState(() {
        _estadoGatos = _esPasswordVisible ? EstadoMonstruo.escondido : EstadoMonstruo.mirando;
      });
    } else if (_nodoEnfoqueEmail.hasFocus) {
      setState(() {
        _estadoGatos = EstadoMonstruo.mirando;
      });
    } else {
      if (_estadoGatos != EstadoMonstruo.feliz && _estadoGatos != EstadoMonstruo.triste) {
        setState(() {
          _estadoGatos = EstadoMonstruo.inactivo;
        });
      }
    }
  }

  /// Alterna la visibilidad del texto en el campo de contraseña.
  void _alCambiarVisibilidadPassword(bool esVisible) {
    setState(() {
      _esPasswordVisible = esVisible;
      if (_nodoEnfoquePassword.hasFocus) {
        _estadoGatos = _esPasswordVisible ? EstadoMonstruo.escondido : EstadoMonstruo.mirando;
      }
    });
  }

  /// Calcula el ratio de la mirada según la longitud del texto ingresado.
  void _actualizarPosicionMirada(String valor) {
    if (_nodoEnfoqueEmail.hasFocus) {
      setState(() {
        _ratioMirada = (valor.length / 30).clamp(0.0, 1.0);
      });
    }
  }

  /// Procesa el intento de inicio de sesión conectando con el servicio de usuarios.
  Future<void> _iniciarSesion() async {
    _nodoEnfoqueEmail.unfocus();
    _nodoEnfoquePassword.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      setState(() {
        _estadoGatos = EstadoMonstruo.calculando;
      });

      final respuesta = await _servicioUsuarios.iniciarSesion(
        _controladorEmail.text,
        _controladorPassword.text,
      );

      _estaCargando.value = false;

      if (!mounted) return;

      if (respuesta.exito) {
        setState(() {
          _estadoGatos = EstadoMonstruo.feliz;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _estadoGatos = EstadoMonstruo.triste;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _estadoGatos = EstadoMonstruo.inactivo;
            });
          }
        });
      }
    } else {
      setState(() {
        _estadoGatos = EstadoMonstruo.triste;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _estadoGatos = EstadoMonstruo.inactivo;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GatosAnimados(
            estado: _estadoGatos,
            ratioMirada: _ratioMirada,
            posicionMouseGlobal: widget.posicionMouse,
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _llaveFormulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Hola de nuevo!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9094A6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
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
                  
                  CampoTextoPersonalizado(
                    etiqueta: 'Contraseña',
                    icono: Icons.lock_outline,
                    controlador: _controladorPassword,
                    nodoEnfoque: _nodoEnfoquePassword,
                    esContrasena: true,
                    alCambiarVisibilidad: _alCambiarVisibilidadPassword,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (valor) {},
                            activeColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            'Recordarme',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6C63FF),
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  BotonCarga(
                    alPresionar: _iniciarSesion,
                    notificadorCargando: _estaCargando,
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
