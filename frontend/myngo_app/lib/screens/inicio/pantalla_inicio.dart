import 'package:flutter/material.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indiceSeleccionado = 0;

  final List<Widget> _vistas = [
    const Center(child: Text('Muro Estilo Pinterest', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Explorar Comunidades', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Mensajes Privados', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Mi Perfil y Puntos', style: TextStyle(fontSize: 24))),
  ];

  void _alPulsar(int index) => setState(() => _indiceSeleccionado = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: _BarraMyngo(
        indiceSeleccionado: _indiceSeleccionado,
        alPulsar: _alPulsar,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_indiceSeleccionado),
          child: _vistas[_indiceSeleccionado],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar personalizado de Myngo
// ─────────────────────────────────────────────────────────────────────────────
class _BarraMyngo extends StatelessWidget implements PreferredSizeWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> alPulsar;

  const _BarraMyngo({
    required this.indiceSeleccionado,
    required this.alPulsar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Logo / Nombre de la app ──
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF9B8BFC), Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Myngo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white, // ShaderMask colorea por encima
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const Spacer(),

            // ── Iconos de navegación ──
            Row(
              children: [
                _IconNav(
                  indice: 0,
                  seleccionado: indiceSeleccionado == 0,
                  alPulsar: alPulsar,
                  icono: Icons.home_outlined,
                  iconoActivo: Icons.home_rounded,
                  esAsset: true,
                ),
                _IconNav(
                  indice: 1,
                  seleccionado: indiceSeleccionado == 1,
                  alPulsar: alPulsar,
                  icono: Icons.groups_outlined,
                  iconoActivo: Icons.groups_rounded,
                ),
                _IconNav(
                  indice: 2,
                  seleccionado: indiceSeleccionado == 2,
                  alPulsar: alPulsar,
                  icono: Icons.chat_bubble_outline_rounded,
                  iconoActivo: Icons.chat_bubble_rounded,
                ),
                _IconNav(
                  indice: 3,
                  seleccionado: indiceSeleccionado == 3,
                  alPulsar: alPulsar,
                  icono: Icons.person_outline_rounded,
                  iconoActivo: Icons.person_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icono individual de navegación en la AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _IconNav extends StatefulWidget {
  final int indice;
  final bool seleccionado;
  final ValueChanged<int> alPulsar;
  final IconData icono;
  final IconData iconoActivo;
  final bool esAsset;

  const _IconNav({
    required this.indice,
    required this.seleccionado,
    required this.alPulsar,
    required this.icono,
    required this.iconoActivo,
    this.esAsset = false,
  });

  @override
  State<_IconNav> createState() => _IconNavState();
}

class _IconNavState extends State<_IconNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _escala;

  static const _colorActivo = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.80,
      upperBound: 1.0,
      value: 1.0,
    );
    _escala = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    widget.alPulsar(widget.indice);
  }

  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final color =
        widget.seleccionado ? _colorActivo : const Color(0xFFB0B3C6);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _escala,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: widget.seleccionado
                ? _colorActivo.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icono principal
              widget.esAsset
                  ? Image.asset(
                      'assets/icons/home.png',
                      width: 24,
                      height: 24,
                      color: color,
                      colorBlendMode: BlendMode.srcIn,
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.seleccionado
                            ? widget.iconoActivo
                            : widget.icono,
                        key: ValueKey<bool>(widget.seleccionado),
                        color: color,
                        size: 24,
                      ),
                    ),

              // Punto indicador abajo del icono cuando está seleccionado
              Positioned(
                bottom: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: widget.seleccionado ? 5 : 0,
                  height: widget.seleccionado ? 5 : 0,
                  decoration: BoxDecoration(
                    color: _colorActivo,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}