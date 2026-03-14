import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/animated_monsters.dart'; // Módulo de monstruos

/// Pantalla principal con fondo degradado web responsive
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    // Usamos MouseRegion para rastrear la posición del ratón de forma global
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.position;
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
                Color(0xFFE0C3FC), // Pastel Purple
                Color(0xFF8EC5FC), // Pastel Blue
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
                    maxWidth: 450, // UI Minimalista Web
                  ),
                  child: LoginCard(mousePosition: _mousePosition),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca central con sombras suaves
class LoginCard extends StatefulWidget {
  final Offset mousePosition;
  const LoginCard({super.key, this.mousePosition = Offset.zero});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _isLoading = ValueNotifier<bool>(false);
  final _formKey = GlobalKey<FormState>();

  MonsterState _monsterState = MonsterState.idle;
  double _lookRatio = 0.5;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      // Si la contraseña ES visible, se tapan los ojos.
      // Si está tapada (puntitos), NO se tapan los ojos (están mirando).
      setState(() {
        _monsterState = _isPasswordVisible ? MonsterState.hiding : MonsterState.looking;
      });
    } else if (_emailFocusNode.hasFocus) {
      setState(() {
        _monsterState = MonsterState.looking;
      });
    } else {
      if (_monsterState != MonsterState.happy && _monsterState != MonsterState.sad) {
        setState(() {
          _monsterState = MonsterState.idle;
        });
      }
    }
  }

  void _onPasswordVisibilityChanged(bool isVisible) {
    setState(() {
      _isPasswordVisible = isVisible;
      if (_passwordFocusNode.hasFocus) {
        _monsterState = _isPasswordVisible ? MonsterState.hiding : MonsterState.looking;
      }
    });
  }

  void _updateLookPosition(String value) {
    if (_emailFocusNode.hasFocus) {
      // ratio: cuán largo es el texto (suponiendo ancho campo visible ~30 caracteres)
      setState(() {
        _lookRatio = (value.length / 30).clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _login() async {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      setState(() {
        _monsterState = MonsterState.computing;
      });
      
      await Future.delayed(const Duration(seconds: 2));
      _isLoading.value = false;

      if (!mounted) return;

      if (_emailController.text == "admin@myngo.com" && _passwordController.text == "123456") {
        setState(() {
          _monsterState = MonsterState.happy;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Inicio de sesión exitoso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _monsterState = MonsterState.sad;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Return to idle after animation
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _monsterState = MonsterState.idle;
            });
          }
        });
      }
    } else {
      setState(() {
        _monsterState = MonsterState.sad;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _monsterState = MonsterState.idle;
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
          // Monstruos Animados propios
          AnimatedMonsters(
            state: _monsterState,
            lookRatio: _lookRatio,
            globalMousePosition: widget.mousePosition,
          ),
          
          // Formulario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _formKey,
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
                  
                  // Campo Email
                  CustomTextField(
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    onChanged: _updateLookPosition,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo Contraseña
                  CustomTextField(
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    isPassword: true,
                    onVisibilityChanged: _onPasswordVisibilityChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Recordarme y Olvidé contraseña
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (value) {},
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
                  
                  // Botón de Login
                  LoadingButton(
                    onPressed: _login,
                    isLoadingNotifier: _isLoading,
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
