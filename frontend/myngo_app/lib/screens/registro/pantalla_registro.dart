import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/gatos_registro_animados.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../services/servicio_usuarios.dart';
import '../../utils/configuracion.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF5F1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                              top: 60,
                              left: 80,
                              child: _BurbujaDecorativa(size: 200, color: const Color(0xFFC35E34).withOpacity(0.08)),
                            ),
                            Positioned(
                              bottom: 120,
                              right: 100,
                              child: _BurbujaDecorativa(size: 180, color: const Color(0xFF248EA6).withOpacity(0.08)),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF248EA6).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person_add_rounded, color: Color(0xFF248EA6), size: 48),
                                      ),
                                      const SizedBox(height: 32),
                                      GatosRegistroAnimados(
                                        estado: _estadoGatos,
                                        ratioMirada: _ratioMirada,
                                        posicionMouseGlobal: _posicionMouse,
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        'UNETE',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFC35E34),
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 4.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Crea tu rincón y empieza a compartir con otros entusiastas de los michis. 🐾',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF4A4440).withOpacity(0.6),
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
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
                            child: TarjetaRegistro(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
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
                        GatosRegistroAnimados(
                          estado: _estadoGatos,
                          ratioMirada: _ratioMirada,
                          posicionMouseGlobal: _posicionMouse,
                        ),
                        const SizedBox(height: 32),
                        TarjetaRegistro(
                          posicionMouse: _posicionMouse,
                          onGatosChange: _onGatosChange,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

class TarjetaRegistro extends StatefulWidget {
  final Offset posicionMouse;
  final Function(EstadoMonstruo, double)? onGatosChange;

  const TarjetaRegistro({super.key, this.posicionMouse = Offset.zero, this.onGatosChange});

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
      _estadoGatos = _esPasswordVisible
          ? EstadoMonstruo.escondido
          : EstadoMonstruo.mirando;
    } else if (_nodoEnfoqueEmail.hasFocus || _nodoEnfoqueNombre.hasFocus) {
      _estadoGatos = EstadoMonstruo.mirando;
    } else {
      if (_estadoGatos != EstadoMonstruo.feliz &&
          _estadoGatos != EstadoMonstruo.triste) {
        _estadoGatos = EstadoMonstruo.inactivo;
      }
    }
    _notificarCambioGato();
  }

  void _notificarCambioGato() {
    widget.onGatosChange?.call(_estadoGatos, _ratioMirada);
  }

  void _alCambiarVisibilidadPassword(bool esVisible) {
    setState(() {
      _esPasswordVisible = esVisible;
    });
    if (_nodoEnfoquePassword.hasFocus) {
      _estadoGatos = _esPasswordVisible
          ? EstadoMonstruo.escondido
          : EstadoMonstruo.mirando;
      _notificarCambioGato();
    }
  }

  void _actualizarPosicionMirada(String valor) {
    if (_nodoEnfoqueEmail.hasFocus || _nodoEnfoqueNombre.hasFocus) {
      setState(() {
        _ratioMirada = (valor.length / 30).clamp(0.0, 1.0);
      });
      _notificarCambioGato();
    }
  }

  Future<void> _crearCuenta() async {
    _nodoEnfoqueNombre.unfocus();
    _nodoEnfoqueEmail.unfocus();
    _nodoEnfoquePassword.unfocus();

    if (_llaveFormulario.currentState!.validate()) {
      _mostrarDialogoReglas();
    } else {
      _estadoGatos = EstadoMonstruo.triste;
      _notificarCambioGato();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _estadoGatos = EstadoMonstruo.inactivo;
          _notificarCambioGato();
        }
      });
    }
  }

  Future<void> _mostrarDialogoReglas() async {
    bool acepto = false;
    bool declino = false;

    final futureDescargaPdf = http.get(Uri.parse('${Configuracion.baseUrl}/documentos/reglas_comunidad/'))
      .then((res) async {
        if (res.statusCode != 200) throw Exception('Error API');
        final datos = jsonDecode(res.body);
        final urlPdf = datos['reglas_comunidad'];
        return await http.get(Uri.parse(urlPdf));
      });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32), 
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              title: Text('Reglas de la Comunidad 🐾', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FutureBuilder<http.Response>(
                          future: futureDescargaPdf,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
                            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
                              return Center(child: Text('Error al cargar reglas 😿', style: GoogleFonts.outfit(color: Colors.grey)));
                            } else {
                              final bytes = snapshot.data!.bodyBytes;
                              return SfPdfViewer.memory(bytes);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Theme(
                      data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.grey),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setDialogState(() { acepto = true; declino = false; }),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: acepto ? true : (declino ? false : null),
                                  onChanged: (_) => setDialogState(() { acepto = true; declino = false; }),
                                  activeColor: const Color(0xFFF28B50),
                                ),
                                Text('Acepto los miau-términos', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setDialogState(() { declino = true; acepto = false; }),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: declino ? true : (acepto ? false : null),
                                  onChanged: (_) => setDialogState(() { declino = true; acepto = false; }),
                                  activeColor: const Color(0xFFD95F43),
                                ),
                                Text('Declino y me voy 😿', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _estadoGatos = EstadoMonstruo.triste;
                    _notificarCambioGato();
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        _estadoGatos = EstadoMonstruo.inactivo;
                        _notificarCambioGato();
                      }
                    });
                  },
                  child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: acepto
                      ? () {
                          Navigator.pop(context);
                          _procesarRegistro();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28B50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('CONTINUAR 🐾', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _procesarRegistro() async {
    _estaCargando.value = true;
    _estadoGatos = EstadoMonstruo.calculando;
    _notificarCambioGato();

    final respuesta = await _servicioUsuarios.registrarse(
      _controladorNombre.text,
      _controladorEmail.text,
      _controladorPassword.text,
    );

    _estaCargando.value = false;
    if (!mounted) return;

    if (respuesta.exito) {
      _estadoGatos = EstadoMonstruo.feliz;
      _notificarCambioGato();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Miau! Revisa tu correo para activar tu cuenta 📧'),
          backgroundColor: const Color(0xFF248EA6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/login'); 
      });
    } else {
      _estadoGatos = EstadoMonstruo.triste;
      _notificarCambioGato();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: const Color(0xFFD95F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _estadoGatos = EstadoMonstruo.inactivo;
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
              '¡Únete a Myngo!',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4A4440),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Crea tu rincón para empezar 🐾',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AutofillGroup(
              child: Column(
                children: [
                  CampoTextoPersonalizado(
                    etiqueta: 'Nombre de usuario',
                    icono: Icons.person_outline_rounded,
                    controlador: _controladorNombre,
                    nodoEnfoque: _nodoEnfoqueNombre,
                    alCambiar: _actualizarPosicionMirada,
                    autofillHints: const [AutofillHints.username],
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return '¿Tu nombre? 🐾';
                      if (valor.length < 3) return 'Mínimo 3 letras';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CampoTextoPersonalizado(
                    etiqueta: 'Email',
                    icono: Icons.alternate_email_rounded,
                    controlador: _controladorEmail,
                    nodoEnfoque: _nodoEnfoqueEmail,
                    alCambiar: _actualizarPosicionMirada,
                    autofillHints: const [AutofillHints.email],
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return 'Falta el email 📧';
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
                    autofillHints: const [AutofillHints.newPassword],
                    alCambiarVisibilidad: _alCambiarVisibilidadPassword,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) return 'La clave secreta 🔑';
                      if (valor.length < 8) return 'Mínimo 8 caracteres';
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(valor)) {
                        return 'Debe tener: Mayúscula, minúscula, número y símbolo';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ValueListenableBuilder<bool>(
              valueListenable: _estaCargando,
              builder: (context, cargando, _) {
                return ElevatedButton(
                  onPressed: cargando ? null : _crearCuenta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28B50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 62),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 10,
                    shadowColor: const Color(0xFFF28B50).withOpacity(0.4),
                  ),
                  child: cargando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('REGISTRARME 🐾', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                );
              }
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¿Ya eres parte?', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFF28B50)),
                  child: const Text('Inicia sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

