import 'dart:math';
import 'package:flutter/material.dart';

/// Define los posibles estados de ánimo y comportamientos de los gatos animados.
enum EstadoMonstruo { 
  /// Los gatos están en reposo, respirando suavemente.
  inactivo, 
  /// Los gatos siguen el cursor o el foco de entrada con la mirada.
  mirando, 
  /// Los gatos se esconden tras el borde (típicamente al escribir una contraseña).
  escondido, 
  /// Los gatos se mueven rápidamente, simulando un proceso de espera.
  calculando, 
  /// Los gatos saltan de alegría tras una operación exitosa.
  feliz, 
  /// Los gatos vibran y muestran ojos de decepción tras un error.
  triste 
}

/// Widget que renderiza una serie de gatos animados interactivos.
/// 
/// Los gatos reaccionan al estado de la aplicación, al movimiento del mouse
/// y a la interacción con otros widgets. Utiliza múltiples controladores de 
/// animación para lograr efectos de respiración, parpadeo, saltos y vibraciones.
class GatosAnimados extends StatefulWidget {
  /// El estado actual de los gatos.
  final EstadoMonstruo estado;

  /// Factor de posición de la mirada (0.0 a 1.0) usado principalmente para
  /// seguir la longitud del texto en un campo de entrada.
  final double ratioMirada;

  /// Posición absoluta del puntero del mouse en la pantalla.
  final Offset posicionMouseGlobal;

  const GatosAnimados({
    super.key,
    required this.estado,
    this.ratioMirada = 0.5,
    this.posicionMouseGlobal = Offset.zero,
  });

  @override
  State<GatosAnimados> createState() => _GatosAnimadosState();
}

class _GatosAnimadosState extends State<GatosAnimados> with TickerProviderStateMixin {
  /// Controlador para la animación rítmica de respiración (idle).
  late AnimationController _controladorIdle;
  /// Controlador para el efecto de salto (éxito).
  late AnimationController _controladorSalto;
  /// Controlador para el efecto de vibración lateral (error).
  late AnimationController _controladorVibracion;
  /// Controlador para el parpadeo aleatorio de los ojos.
  late AnimationController _controladorParpadeo;

  @override
  void initState() {
    super.initState();
    _controladorIdle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    )..repeat(reverse: true);

    _controladorSalto = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controladorVibracion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controladorParpadeo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _programarParpadeo();
  }

  /// Gestiona el parpadeo de los ojos de forma asíncrona y con intervalos aleatorios.
  void _programarParpadeo() {
    if (!mounted) return;
    Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(4000)), () {
      if (!mounted) return;
      if (widget.estado != EstadoMonstruo.escondido && widget.estado != EstadoMonstruo.triste) {
         _controladorParpadeo.forward().then((_) => _controladorParpadeo.reverse());
      }
      _programarParpadeo();
    });
  }

  @override
  void didUpdateWidget(covariant GatosAnimados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado != oldWidget.estado) {
      if (widget.estado == EstadoMonstruo.feliz) {
        _controladorSalto.forward(from: 0.0).then((_) => _controladorSalto.reverse());
      } else if (widget.estado == EstadoMonstruo.triste) {
        _controladorVibracion.forward(from: 0.0);
      } else if (widget.estado == EstadoMonstruo.calculando) {
        _controladorIdle.duration = const Duration(milliseconds: 400); 
        _controladorIdle.repeat(reverse: true);
      } else {
        _controladorIdle.duration = const Duration(milliseconds: 1500);
        _controladorIdle.repeat(reverse: true);
      }
    } else if (widget.estado == EstadoMonstruo.mirando && (widget.ratioMirada - oldWidget.ratioMirada).abs() > 0.1) {
      _controladorVibracion.forward(from: 0.5).then((_) => _controladorVibracion.reverse());
    }
  }

  @override
  void dispose() {
    _controladorIdle.dispose();
    _controladorSalto.dispose();
    _controladorVibracion.dispose();
    _controladorParpadeo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tamanoVentana = MediaQuery.of(context).size;
        double offsetMouseX = 0.0;
        double offsetMouseY = 0.0;
        
        if (widget.estado == EstadoMonstruo.inactivo || widget.estado == EstadoMonstruo.mirando) {
           final dx = widget.posicionMouseGlobal.dx - (tamanoVentana.width / 2);
           final dy = widget.posicionMouseGlobal.dy - (tamanoVentana.height / 3);
           offsetMouseX = (dx / tamanoVentana.width) * 15.0; 
           offsetMouseY = (dy / tamanoVentana.height) * 15.0;
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_controladorIdle, _controladorSalto, _controladorVibracion, _controladorParpadeo]),
          builder: (context, child) {
            double offsetSalto = sin(_controladorSalto.value * pi) * -40.0;
            double offsetVibracion = widget.estado == EstadoMonstruo.triste 
               ? sin(_controladorVibracion.value * 8 * pi) * 6.0 
               : (widget.estado == EstadoMonstruo.mirando ? sin(_controladorVibracion.value * pi) * 2.0 : 0.0);
            
            double fT = _controladorIdle.value * pi;
            double escalaRespiracionY = 1.0 + (_controladorIdle.value * 0.04);
            double escalaRespiracionX = 1.0 - (_controladorIdle.value * 0.01);
            
            Offset offsetOjo = _obtenerOffsetOjo(offsetMouseX, offsetMouseY);
            bool estaCerrado = widget.estado == EstadoMonstruo.escondido || widget.estado == EstadoMonstruo.feliz;
            bool estaTriste = widget.estado == EstadoMonstruo.triste;
            bool estaFeliz = widget.estado == EstadoMonstruo.feliz;
            bool estaParpadeando = _controladorParpadeo.value > 0.5;

            return Container(
              height: 220, 
              width: 320,
              padding: const EdgeInsets.only(top: 20),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                   Positioned(
                     left: 70,
                     bottom: offsetSalto + sin(fT) * 6,
                     child: Transform.translate(
                       offset: Offset(offsetVibracion, 0),
                       child: Transform.scale(
                         scaleX: escalaRespiracionX, scaleY: escalaRespiracionY, alignment: Alignment.bottomCenter,
                         child: _construirGatoNegro(offsetOjo, estaCerrado, estaTriste, estaFeliz, estaParpadeando, fT),
                       )
                     ),
                   ),
                   Positioned(
                     left: 155,
                     bottom: offsetSalto + sin(fT + 1) * 8,
                     child: Transform.translate(
                       offset: Offset(offsetVibracion * 0.8, 0),
                       child: Transform.scale(
                         scaleX: escalaRespiracionX, scaleY: escalaRespiracionY, alignment: Alignment.bottomCenter,
                         child: _construirGatoSiames(offsetOjo, estaCerrado, estaTriste, estaFeliz, estaParpadeando, fT),
                       )
                     ),
                   ),
                   Positioned(
                     left: 210,
                     bottom: offsetSalto + sin(fT + 2) * 7,
                     child: Transform.translate(
                       offset: Offset(offsetVibracion * 1.2, 0),
                       child: Transform.scale(
                         scaleX: escalaRespiracionX, scaleY: escalaRespiracionY, alignment: Alignment.bottomCenter,
                         child: _construirGatoNaranja(offsetOjo, estaCerrado, estaTriste, estaFeliz, estaParpadeando, fT),
                       )
                     ),
                   ),
                   Positioned(
                     left: 10,
                     bottom: offsetSalto + sin(fT + 3) * 5,
                     child: Transform.translate(
                       offset: Offset(offsetVibracion * 0.9, 0),
                       child: Transform.scale(
                         scaleX: escalaRespiracionX, scaleY: escalaRespiracionY, alignment: Alignment.bottomCenter,
                         child: _construirGatoCalico(offsetOjo, estaCerrado, estaTriste, estaFeliz, estaParpadeando, fT),
                       )
                     ),
                   ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  /// Calcula el desplazamiento de los ojos en función de la interacción actual.
  Offset _obtenerOffsetOjo(double mouseX, double mouseY) {
    if (widget.estado == EstadoMonstruo.mirando) {
      return Offset((widget.ratioMirada - 0.5) * 25, 0); 
    } else if (widget.estado == EstadoMonstruo.inactivo) {
      return Offset(mouseX.clamp(-10.0, 10.0), mouseY.clamp(-5.0, 5.0));
    } else if (widget.estado == EstadoMonstruo.triste) {
      return const Offset(0, 5);
    }
    return const Offset(0, 0);
  }


  // ================= CONSTRUCCIÓN DE COMPONENTES DE GATOS ================= //

  /// Construye la representación visual del gato negro (vació).
  Widget _construirGatoNegro(Offset ojo, bool estaCerrado, bool estaTriste, bool estaFeliz, bool estaParpadeando, double t) {
    const color = Color(0xFF1A1A1A);
    
    return SizedBox(
      width: 90, height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
           Positioned(top: 5, left: 5, child: _construirOreja(color, angulo: 0, origen: Alignment.bottomRight)),
           Positioned(top: 5, right: 5, child: _construirOreja(color, angulo: 0)),
           
           if (estaTriste) Positioned.fill(child: _construirPeloErizado(color, 90, 160)),

           Container(
             width: 90, height: 160,
             decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45))),
             child: Stack(
               clipBehavior: Clip.none,
               children: [
                  AnimatedPositioned(duration: const Duration(milliseconds: 100), top: 40 + ojo.dy, left: 25 + ojo.dx, child: Row(children: [_construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFFFFD700)), const SizedBox(width: 12), _construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFFFFD700))])),
                  AnimatedPositioned(duration: const Duration(milliseconds: 200), top: 65 + ojo.dy, left: 42 + ojo.dx * 0.5, child: _construirNarizGato(const Color(0xFF2E2E2E))),
               ],
             )
           )
        ],
      )
    );
  }

  /// Construye la representación visual del gato siamés.
  Widget _construirGatoSiames(Offset ojo, bool estaCerrado, bool estaTriste, bool estaFeliz, bool estaParpadeando, double t) {
    const colorBase = Color(0xFFEBE0D0);
    const colorPuntos = Color(0xFF3B2F2F);
    
    return SizedBox(
      width: 75, height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
           Positioned(top: 0, left: 0, child: _construirOreja(colorPuntos)),
           Positioned(top: 0, right: 0, child: _construirOreja(colorPuntos)),
           
           if (estaTriste) Positioned.fill(child: _construirPeloErizado(colorBase, 75, 120)),

           Container(
             width: 75, height: 120,
             decoration: const BoxDecoration(color: colorBase, borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35))),
             child: Stack(
               clipBehavior: Clip.none,
               children: [
                  AnimatedPositioned(duration: const Duration(milliseconds: 100), top: 25 + ojo.dy * 0.5, left: 7 + ojo.dx * 0.3, child: Container(width: 60, height: 50, decoration: BoxDecoration(color: colorPuntos, borderRadius: BorderRadius.circular(30)))),
                  AnimatedPositioned(duration: const Duration(milliseconds: 100), top: 35 + ojo.dy, left: 17 + ojo.dx, child: Row(children: [_construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF4FC3F7)), const SizedBox(width: 10), _construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF4FC3F7))])),
                  AnimatedPositioned(duration: const Duration(milliseconds: 200), top: 58 + ojo.dy, left: 34 + ojo.dx * 0.5, child: _construirNarizGato(const Color(0xFF1A1A1A))),
               ],
             )
           )
        ],
      )
    );
  }

  /// Construye la representación visual del gato naranja atigrado.
  Widget _construirGatoNaranja(Offset ojo, bool estaCerrado, bool estaTriste, bool estaFeliz, bool estaParpadeando, double t) {
    const color = Color(0xFFF29C38);
    return SizedBox(
      width: 70, height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
           Positioned(top: 0, left: -2, child: _construirOreja(color, angulo: -pi/12, origen: Alignment.bottomRight)),
           Positioned(top: 0, right: -2, child: _construirOreja(color, angulo: pi/12, origen: Alignment.bottomLeft)),
           
           if (estaTriste) Positioned.fill(child: _construirPeloErizado(color, 70, 100)),

           Container(
             width: 70, height: 100,
             decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35))),
             child: Stack(
               clipBehavior: Clip.none,
               children: [
                  Positioned(top: 5, left: 22, child: Container(width: 4, height: 15, color: const Color(0xFFD67215))),
                  Positioned(top: 5, left: 33, child: Container(width: 4, height: 18, color: const Color(0xFFD67215))),
                  Positioned(top: 5, left: 44, child: Container(width: 4, height: 15, color: const Color(0xFFD67215))),
                  AnimatedPositioned(duration: const Duration(milliseconds: 100), top: 30 + ojo.dy, left: 16 + ojo.dx, child: Row(children: [_construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF81C784)), const SizedBox(width: 8), _construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF81C784))])),
                  AnimatedPositioned(duration: const Duration(milliseconds: 200), top: 52 + ojo.dy, left: 30 + ojo.dx * 0.5, child: _construirNarizGato(const Color(0xFFE57373))),
               ],
             )
           )
        ],
      )
    );
  }

  /// Construye la representación visual del gato cálico.
  Widget _construirGatoCalico(Offset ojo, bool estaCerrado, bool estaTriste, bool estaFeliz, bool estaParpadeando, double t) {
    const colorBase = Color(0xFFFFFFFF);
    const manchaNaranja = Color(0xFFF29C38);
    const manchaNegra = Color(0xFF2E2E2E);

    return SizedBox(
      width: 150, height: 95,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
           Positioned(top: -5, left: 30, child: _construirOreja(manchaNaranja, angulo: 0)), 
           Positioned(top: -5, right: 30, child: _construirOreja(manchaNegra, angulo: 0)),
           
           if (estaTriste) Positioned.fill(child: _construirPeloErizado(const Color(0xFFD1D1D1), 150, 75)), 

           Container(
             width: 150, height: 75,
             decoration: const BoxDecoration(color: colorBase, borderRadius: BorderRadius.only(topLeft: Radius.circular(75), topRight: Radius.circular(75))),
             clipBehavior: Clip.hardEdge,
             child: Stack(
               clipBehavior: Clip.none,
               children: [
                  Positioned(top: -10, left: 10, child: Container(width: 60, height: 60, decoration: const BoxDecoration(color: manchaNaranja, shape: BoxShape.circle))),
                  Positioned(top: 10, right: -20, child: Container(width: 80, height: 80, decoration: const BoxDecoration(color: manchaNegra, shape: BoxShape.circle))),
                  AnimatedPositioned(duration: const Duration(milliseconds: 100), top: 35 + ojo.dy, left: 45 + ojo.dx, child: Row(children: [_construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF81C784)), const SizedBox(width: 40), _construirOjo(estaCerrado || estaParpadeando, estaTriste, estaFeliz, colorOjo: const Color(0xFF4FC3F7))])), 
                  AnimatedPositioned(duration: const Duration(milliseconds: 200), top: 55 + ojo.dy, left: 70 + ojo.dx, child: _construirNarizGato(const Color(0xFFF06292))),
               ],
             )
           )
        ],
      )
    );
  }

  // ================= ELEMENTOS COMUNES ================= //

  /// Dibuja el efecto de pelo erizado rodeando la silueta del gato.
  Widget _construirPeloErizado(Color color, double ancho, double alto) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: CustomPaint(
        size: Size(ancho, alto),
        painter: _PintorPeloErizado(color: color),
      ),
    );
  }

  /// Crea un ojo con pupilas dinámicas que reaccionan al estado de ánimo.
  Widget _construirOjo(bool estaCerrado, bool estaTriste, bool estaFeliz, {required Color colorOjo}) {
    if (estaCerrado) {
       return Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2)));
    }
    return Container(
       width: 14, height: 14,
       decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
       alignment: Alignment.center,
       child: Container(
          width: 12, height: 12, 
          decoration: BoxDecoration(color: colorOjo, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: AnimatedContainer(
             duration: const Duration(milliseconds: 100),
             width: estaFeliz ? 8 : (estaTriste ? 2 : 5), 
             height: estaFeliz ? 8 : 10,
             decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(estaFeliz ? 4 : 2))
          )
       )
    );
  }

  /// Dibuja una oreja triangular utilizando un trazado personalizado.
  Widget _construirOreja(Color color, {double angulo = 0, Alignment origen = Alignment.bottomCenter}) {
    return Transform.rotate(
      angle: angulo,
      alignment: origen,
      child: Container(
        margin: const EdgeInsets.only(top: 15), 
        child: ClipPath(
          clipper: _RecortadorOrejaGato(),
          child: Container(
            width: 35, 
            height: 45, 
            color: color,
          ),
        ),
      ),
    );
  }

  /// Construye el conjunto de nariz, boca y bigotes base.
  Widget _construirNarizGato(Color color) {
    return Column(
      children: [
        ClipPath(
          clipper: _RecortadorNarizGato(),
          child: Container(width: 8, height: 5, color: color),
        ),
        Container(
          width: 2, height: 4, color: const Color(0xFF141414),
        ),
        SizedBox(
          width: 12, height: 4,
          child: CustomPaint(painter: _PintorPequenaW()),
        )
      ],
    );
  }
}

/// Pintor que genera pinchos matemáticos alineados con el borde curvo de los gatos.
class _PintorPeloErizado extends CustomPainter {
  final Color color;
  _PintorPeloErizado({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    
    // Gatos anchos (horizontal) como el cálico.
    if (size.width > size.height) {
       double r = size.height;
       int pasos = 18;
       for(int i = 0; i < pasos; i++) {
         double t1 = i / pasos;
         double t2 = (i+1) / pasos;
         double x1 = size.width * t1;
         double x2 = size.width * t2;
         double medioX = (x1 + x2) / 2;
         double archY1 = size.height - (sin(t1 * pi) * r);
         double archY2 = size.height - (sin(t2 * pi) * r);
         double topeArchY = size.height - (sin(((t1 + t2)/2) * pi) * (r + 10));
         double offsetPuntoX = ((i % 2 == 0) ? -5 : 5);
         path.moveTo(x1, (archY1>size.height)?size.height:archY1);
         path.lineTo(medioX + offsetPuntoX, topeArchY - 5);
         path.lineTo(x2, (archY2>size.height)?size.height:archY2);
       }
       canvas.drawPath(path, paint);
       return;
    }

    // Gatos verticales estándar.
    double r = size.width / 2;
    for (double y = size.height; y > r; y -= 15) {
      path.moveTo(0, y);
      path.lineTo(-8, y - 5);
      path.lineTo(0, y - 10);
    }
    for (double angulo = pi; angulo > 0; angulo -= pi / 7) {
       double cx = r;
       double cy = r; 
       double x = cx + r * cos(angulo);
       double y = cy - r * sin(angulo);
       double tx = cx + (r + 8) * cos(angulo - pi/20);
       double ty = cy - (r + 8) * sin(angulo - pi/20);
       double siguienteAngulo = angulo - (pi/7);
       double nx = cx + r * cos(siguienteAngulo);
       double ny = cy - r * sin(siguienteAngulo);
       path.moveTo(x, y);
       path.lineTo(tx, ty);
       path.lineTo(nx, ny);
    }
    for (double y = r; y < size.height; y += 15) {
      path.moveTo(size.width, y);
      path.lineTo(size.width + 8, y + 5);
      path.lineTo(size.width, y + 10);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Define la forma triangular de la oreja con curvas suaves en la base.
class _RecortadorOrejaGato extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0); 
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.5, size.width, size.height); 
    path.lineTo(0, size.height); 
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.5, size.width * 0.5, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Define la pequeña tripa triangular invertida de la nariz.
class _RecortadorNarizGato extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.5, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Dibuja las dos curvas que representan la boca felina.
class _PintorPequenaW extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF141414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
