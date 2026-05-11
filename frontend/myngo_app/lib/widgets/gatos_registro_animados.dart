import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Reutilizamos el mismo enum del login para compartir la lógica de estados
export 'gatos_animados.dart' show EstadoMonstruo;
import 'gatos_animados.dart' show EstadoMonstruo;

/// Versión alternativa del widget de gatos para la pantalla de Registro.
/// Misma arquitectura y estilo de dibujo, pero 4 razas completamente distintas.
class GatosRegistroAnimados extends StatefulWidget {
  final EstadoMonstruo estado;
  final double ratioMirada;
  final Offset posicionMouseGlobal;

  const GatosRegistroAnimados({
    super.key,
    required this.estado,
    this.ratioMirada = 0.5,
    this.posicionMouseGlobal = Offset.zero,
  });

  @override
  State<GatosRegistroAnimados> createState() => _GatosRegistroAnimadosState();
}

class _GatosRegistroAnimadosState extends State<GatosRegistroAnimados>
    with TickerProviderStateMixin {
  late AnimationController _controladorIdle;
  late AnimationController _controladorSalto;
  late AnimationController _controladorVibracion;
  late AnimationController _controladorParpadeo;
  Timer? _timerParpadeo;

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

  void _programarParpadeo() {
    _timerParpadeo?.cancel();
    if (!mounted) return;
    _timerParpadeo = Timer(Duration(milliseconds: 2000 + Random().nextInt(4000)), () {
      if (!mounted) return;
      if (widget.estado != EstadoMonstruo.escondido &&
          widget.estado != EstadoMonstruo.triste) {
        _controladorParpadeo
            .forward()
            .then((_) {
              if (mounted) _controladorParpadeo.reverse();
            });
      }
      _programarParpadeo();
    });
  }

  @override
  void didUpdateWidget(covariant GatosRegistroAnimados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado != oldWidget.estado) {
      if (widget.estado == EstadoMonstruo.feliz) {
        _controladorSalto
            .forward(from: 0.0)
            .then((_) => _controladorSalto.reverse());
      } else if (widget.estado == EstadoMonstruo.triste) {
        _controladorVibracion.forward(from: 0.0);
      } else if (widget.estado == EstadoMonstruo.calculando) {
        _controladorIdle.duration = const Duration(milliseconds: 400);
        _controladorIdle.repeat(reverse: true);
      } else {
        _controladorIdle.duration = const Duration(milliseconds: 1500);
        _controladorIdle.repeat(reverse: true);
      }
    } else if (widget.estado == EstadoMonstruo.mirando &&
        (widget.ratioMirada - oldWidget.ratioMirada).abs() > 0.1) {
      _controladorVibracion
          .forward(from: 0.5)
          .then((_) => _controladorVibracion.reverse());
    }
  }

  @override
  void dispose() {
    _timerParpadeo?.cancel();
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

        if (widget.estado == EstadoMonstruo.inactivo ||
            widget.estado == EstadoMonstruo.mirando) {
          final dx =
              widget.posicionMouseGlobal.dx - (tamanoVentana.width / 2);
          final dy =
              widget.posicionMouseGlobal.dy - (tamanoVentana.height / 3);
          offsetMouseX = (dx / tamanoVentana.width) * 15.0;
          offsetMouseY = (dy / tamanoVentana.height) * 15.0;
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            _controladorIdle,
            _controladorSalto,
            _controladorVibracion,
            _controladorParpadeo,
          ]),
          builder: (context, child) {
            double offsetSalto = sin(_controladorSalto.value * pi) * -40.0;
            double offsetVibracion =
                widget.estado == EstadoMonstruo.triste
                    ? sin(_controladorVibracion.value * 8 * pi) * 6.0
                    : (widget.estado == EstadoMonstruo.mirando
                        ? sin(_controladorVibracion.value * pi) * 2.0
                        : 0.0);

            double fT = _controladorIdle.value * pi;
            double escalaRespiracionY =
                1.0 + (_controladorIdle.value * 0.04);
            double escalaRespiracionX =
                1.0 - (_controladorIdle.value * 0.01);

            Offset offsetOjo = _obtenerOffsetOjo(offsetMouseX, offsetMouseY);
            bool estaCerrado = widget.estado == EstadoMonstruo.escondido ||
                widget.estado == EstadoMonstruo.feliz;
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
                  // GATO GRIS PLATEADO (izquierda)
                  Positioned(
                    left: 5,
                    bottom: offsetSalto + sin(fT) * 6,
                    child: Transform.translate(
                      offset: Offset(offsetVibracion, 0),
                      child: Transform.scale(
                        scaleX: escalaRespiracionX,
                        scaleY: escalaRespiracionY,
                        alignment: Alignment.bottomCenter,
                        child: _construirGatoGris(offsetOjo, estaCerrado,
                            estaTriste, estaFeliz, estaParpadeando, fT),
                      ),
                    ),
                  ),
                  // GATO AZUL RUSO (centro-izquierda)
                  Positioned(
                    left: 85,
                    bottom: offsetSalto + sin(fT + 1) * 8,
                    child: Transform.translate(
                      offset: Offset(offsetVibracion * 0.8, 0),
                      child: Transform.scale(
                        scaleX: escalaRespiracionX,
                        scaleY: escalaRespiracionY,
                        alignment: Alignment.bottomCenter,
                        child: _construirGatoAzul(offsetOjo, estaCerrado,
                            estaTriste, estaFeliz, estaParpadeando, fT),
                      ),
                    ),
                  ),
                  // GATO MARRÓN CHOCOLATE (centro-derecha)
                  Positioned(
                    left: 150,
                    bottom: offsetSalto + sin(fT + 2) * 7,
                    child: Transform.translate(
                      offset: Offset(offsetVibracion * 1.2, 0),
                      child: Transform.scale(
                        scaleX: escalaRespiracionX,
                        scaleY: escalaRespiracionY,
                        alignment: Alignment.bottomCenter,
                        child: _construirGatoChocolate(offsetOjo, estaCerrado,
                            estaTriste, estaFeliz, estaParpadeando, fT),
                      ),
                    ),
                  ),
                  // GATO BLANCO MANCHADO (derecha, tipo leopardo)
                  Positioned(
                    left: 210,
                    bottom: offsetSalto + sin(fT + 3) * 5,
                    child: Transform.translate(
                      offset: Offset(offsetVibracion * 0.9, 0),
                      child: Transform.scale(
                        scaleX: escalaRespiracionX,
                        scaleY: escalaRespiracionY,
                        alignment: Alignment.bottomCenter,
                        child: _construirGatoBlancoManchado(offsetOjo,
                            estaCerrado, estaTriste, estaFeliz,
                            estaParpadeando, fT),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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

  // ================= 1. GATO GRIS PLATEADO ================= //
  Widget _construirGatoGris(Offset ojo, bool estaCerrado, bool estaTriste,
      bool estaFeliz, bool estaParpadeando, double t) {
    const color = Color(0xFFB0BEC5); // Gris plateado
    const colorClaro = Color(0xFFCFD8DC);

    return SizedBox(
      width: 90,
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              top: 5,
              left: 5,
              child: _construirOreja(color,
                  angulo: 0, origen: Alignment.bottomRight)),
          Positioned(
              top: 5,
              right: 5,
              child: _construirOreja(color, angulo: 0)),
          if (estaTriste)
            Positioned.fill(child: _construirPeloErizado(color, 90, 160)),
          Container(
            width: 90,
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, colorClaro],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(45),
                topRight: Radius.circular(45),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Rayas sutiles en la frente
                Positioned(
                    top: 8,
                    left: 28,
                    child: Container(
                        width: 3,
                        height: 12,
                        color: const Color(0xFF90A4AE))),
                Positioned(
                    top: 8,
                    left: 38,
                    child: Container(
                        width: 3,
                        height: 14,
                        color: const Color(0xFF90A4AE))),
                Positioned(
                    top: 8,
                    left: 48,
                    child: Container(
                        width: 3,
                        height: 12,
                        color: const Color(0xFF90A4AE))),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  top: 40 + ojo.dy,
                  left: 25 + ojo.dx,
                  child: Row(children: [
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFF66BB6A)),
                    const SizedBox(width: 12),
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFF66BB6A)),
                  ]),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 65 + ojo.dy,
                  left: 42 + ojo.dx * 0.5,
                  child: _construirNarizGato(const Color(0xFF78909C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. GATO AZUL RUSO ================= //
  Widget _construirGatoAzul(Offset ojo, bool estaCerrado, bool estaTriste,
      bool estaFeliz, bool estaParpadeando, double t) {
    const color = Color(0xFF78909C); // Azul pizarra
    const colorOscuro = Color(0xFF546E7A);

    return SizedBox(
      width: 75,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              top: 0,
              left: 0,
              child: _construirOreja(colorOscuro)),
          Positioned(
              top: 0,
              right: 0,
              child: _construirOreja(colorOscuro)),
          if (estaTriste)
            Positioned.fill(child: _construirPeloErizado(color, 75, 120)),
          Container(
            width: 75,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Interior más claro del hocico
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  top: 55 + ojo.dy * 0.5,
                  left: 15 + ojo.dx * 0.3,
                  child: Container(
                    width: 45,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF90A4AE),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  top: 35 + ojo.dy,
                  left: 17 + ojo.dx,
                  child: Row(children: [
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFF26C6DA)), // Turquesa
                    const SizedBox(width: 10),
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFF26C6DA)),
                  ]),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 60 + ojo.dy,
                  left: 34 + ojo.dx * 0.5,
                  child: _construirNarizGato(const Color(0xFF37474F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. GATO MARRÓN CHOCOLATE ================= //
  Widget _construirGatoChocolate(Offset ojo, bool estaCerrado, bool estaTriste,
      bool estaFeliz, bool estaParpadeando, double t) {
    const color = Color(0xFF6D4C41); // Marrón chocolate
    const colorRaya = Color(0xFF4E342E); // Marrón oscuro para rayas

    return SizedBox(
      width: 70,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              top: 0,
              left: -2,
              child: _construirOreja(color,
                  angulo: -pi / 12, origen: Alignment.bottomRight)),
          Positioned(
              top: 0,
              right: -2,
              child: _construirOreja(color,
                  angulo: pi / 12, origen: Alignment.bottomLeft)),
          if (estaTriste)
            Positioned.fill(child: _construirPeloErizado(color, 70, 100)),
          Container(
            width: 70,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Rayas oscuras tipo atigrado
                Positioned(
                    top: 4,
                    left: 18,
                    child: Container(
                        width: 3,
                        height: 14,
                        color: colorRaya)),
                Positioned(
                    top: 4,
                    left: 27,
                    child: Container(
                        width: 3,
                        height: 18,
                        color: colorRaya)),
                Positioned(
                    top: 4,
                    left: 36,
                    child: Container(
                        width: 3,
                        height: 14,
                        color: colorRaya)),
                // Rayas en mejillas
                Positioned(
                    top: 40,
                    left: 4,
                    child: Container(
                        width: 10,
                        height: 2,
                        color: colorRaya)),
                Positioned(
                    top: 45,
                    left: 4,
                    child: Container(
                        width: 8,
                        height: 2,
                        color: colorRaya)),
                Positioned(
                    top: 40,
                    right: 4,
                    child: Container(
                        width: 10,
                        height: 2,
                        color: colorRaya)),
                Positioned(
                    top: 45,
                    right: 4,
                    child: Container(
                        width: 8,
                        height: 2,
                        color: colorRaya)),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  top: 30 + ojo.dy,
                  left: 16 + ojo.dx,
                  child: Row(children: [
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFFFFB300)), // Ámbar
                    const SizedBox(width: 8),
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFFFFB300)),
                  ]),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 52 + ojo.dy,
                  left: 30 + ojo.dx * 0.5,
                  child: _construirNarizGato(const Color(0xFFE57373)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. GATO BLANCO CON MANCHAS (estilo leopardo) ================= //
  Widget _construirGatoBlancoManchado(Offset ojo, bool estaCerrado,
      bool estaTriste, bool estaFeliz, bool estaParpadeando, double t) {
    const colorBase = Color(0xFFF5F5F5); // Blanco roto
    const colorMancha = Color(0xFF5D4037); // Marrón oscuro para las manchas

    return SizedBox(
      width: 80,
      height: 155,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              top: 5,
              left: 5,
              child: _construirOreja(const Color(0xFFDDDDDD),
                  angulo: 0, origen: Alignment.bottomRight)),
          Positioned(
              top: 5,
              right: 5,
              child: _construirOreja(const Color(0xFFDDDDDD), angulo: 0)),
          if (estaTriste)
            Positioned.fill(
                child: _construirPeloErizado(const Color(0xFFE0E0E0), 80, 135)),
          Container(
            width: 80,
            height: 135,
            decoration: BoxDecoration(
              color: colorBase,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Manchas de leopardo distribuidas
                Positioned(
                    top: 5,
                    left: 8,
                    child: _manchaLeopardo(colorMancha, 14, 10)),
                Positioned(
                    top: 15,
                    right: 6,
                    child: _manchaLeopardo(colorMancha, 12, 9)),
                Positioned(
                    top: 60,
                    left: 5,
                    child: _manchaLeopardo(colorMancha, 10, 8)),
                Positioned(
                    top: 75,
                    right: 4,
                    child: _manchaLeopardo(colorMancha, 13, 10)),
                Positioned(
                    top: 95,
                    left: 20,
                    child: _manchaLeopardo(colorMancha, 15, 10)),
                Positioned(
                    top: 100,
                    right: 15,
                    child: _manchaLeopardo(colorMancha, 11, 9)),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  top: 40 + ojo.dy,
                  left: 22 + ojo.dx,
                  child: Row(children: [
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFFAB47BC)), // Violeta
                    const SizedBox(width: 10),
                    _construirOjo(estaCerrado || estaParpadeando, estaTriste,
                        estaFeliz,
                        colorOjo: const Color(0xFFAB47BC)),
                  ]),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 63 + ojo.dy,
                  left: 36 + ojo.dx * 0.5,
                  child: _construirNarizGato(const Color(0xFFF48FB1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mancha redondeada tipo leopardo
  Widget _manchaLeopardo(Color color, double ancho, double alto) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  // ================= PARTES COMPARTIDAS ================= //

  Widget _construirPeloErizado(Color color, double ancho, double alto) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: CustomPaint(
        size: Size(ancho, alto),
        painter: _PintorPeloErizado(color: color),
      ),
    );
  }

  Widget _construirOjo(bool estaCerrado, bool estaTriste, bool estaFeliz,
      {required Color colorOjo}) {
    if (estaCerrado) {
      return Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(2)));
    }
    return Container(
      width: 14,
      height: 14,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration:
            BoxDecoration(color: colorOjo, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: estaFeliz ? 8 : (estaTriste ? 2 : 5),
          height: estaFeliz ? 8 : 10,
          decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius:
                  BorderRadius.circular(estaFeliz ? 4 : 2)),
        ),
      ),
    );
  }

  Widget _construirOreja(Color color,
      {double angulo = 0, Alignment origen = Alignment.bottomCenter}) {
    return Transform.rotate(
      angle: angulo,
      alignment: origen,
      child: Container(
        margin: const EdgeInsets.only(top: 15), // igual que en gatos_animados.dart
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

  Widget _construirNarizGato(Color color) {
    return Column(
      children: [
        ClipPath(
          clipper: _RecortadorNarizGato(),
          child: Container(width: 8, height: 5, color: color),
        ),
        Container(width: 2, height: 4, color: const Color(0xFF141414)),
        SizedBox(
          width: 12,
          height: 4,
          child: CustomPaint(painter: _PintorPequenaW()),
        ),
      ],
    );
  }
}

// ========== PINTORES Y RECORTADORES (idénticos al login) ========== //

class _PintorPeloErizado extends CustomPainter {
  final Color color;
  _PintorPeloErizado({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();

    if (size.width > size.height) {
      double r = size.height;
      int pasos = 18;
      for (int i = 0; i < pasos; i++) {
        double t1 = i / pasos;
        double t2 = (i + 1) / pasos;
        double x1 = size.width * t1;
        double x2 = size.width * t2;
        double medioX = (x1 + x2) / 2;
        double archY1 = size.height - (sin(t1 * pi) * r);
        double archY2 = size.height - (sin(t2 * pi) * r);
        double topeArchY =
            size.height - (sin(((t1 + t2) / 2) * pi) * (r + 10));
        double offsetPuntoX = ((i % 2 == 0) ? -5 : 5);
        path.moveTo(x1, (archY1 > size.height) ? size.height : archY1);
        path.lineTo(medioX + offsetPuntoX, topeArchY - 5);
        path.lineTo(x2, (archY2 > size.height) ? size.height : archY2);
      }
      canvas.drawPath(path, paint);
      return;
    }

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
      double tx = cx + (r + 8) * cos(angulo - pi / 20);
      double ty = cy - (r + 8) * sin(angulo - pi / 20);
      double siguienteAngulo = angulo - (pi / 7);
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

class _RecortadorOrejaGato extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.5, size.width, size.height);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width * 0.1, size.height * 0.5, size.width * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, 0);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
