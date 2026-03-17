import 'package:flutter/material.dart';
import '../comunidades/pantalla_comunidades.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../comunidades/widgets/tarjeta_comunidad.dart';
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_notificaciones.dart';
import '../notificaciones/pantalla_notificaciones.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indiceSeleccionado = 0;

  final List<Widget> _vistas = [
    const _SeccionMisComunidades(),
    const PantallaComunidades(),
    const PantallaNotificaciones(),
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

class _SeccionMisComunidades extends StatefulWidget {
  const _SeccionMisComunidades();

  @override
  State<_SeccionMisComunidades> createState() => _SeccionMisComunidadesState();
}

class _SeccionMisComunidadesState extends State<_SeccionMisComunidades> {
  final _servicio = ServicioComunidades();
  List<Comunidad> _misComunidades = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPropias();
  }

  Future<void> _cargarPropias() async {
    final respuesta = await _servicio.listarComunidadesPropias();
    if (mounted) {
      setState(() {
        _misComunidades = respuesta.datos ?? [];
        _estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) return const Center(child: CircularProgressIndicator());
    
    if (_misComunidades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets_rounded, size: 64, color: Color(0xFFB0B3C6)),
            const SizedBox(height: 16),
            const Text(
              'Aún no eres parte de ninguna comunidad.',
              style: TextStyle(color: Color(0xFF9094A6), fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {}, // Aquí podríamos cambiar el índice a 1 para explorar
              child: const Text('¡Explora y únete a una! ✨'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Comunidades 🐾',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _misComunidades.length,
            itemBuilder: (context, index) => TarjetaComunidad(
              comunidad: _misComunidades[index],
              alPresionar: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaDetalleComunidad(comunidad: _misComunidades[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar personalizado de Myngo
// ─────────────────────────────────────────────────────────────────────────────
class _BarraMyngo extends StatefulWidget implements PreferredSizeWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> alPulsar;

  const _BarraMyngo({
    required this.indiceSeleccionado,
    required this.alPulsar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<_BarraMyngo> createState() => _BarraMyngoState();
}

class _BarraMyngoState extends State<_BarraMyngo> {
  final _servicioNotificaciones = ServicioNotificaciones();
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarConteo();
  }

  @override
  void didUpdateWidget(_BarraMyngo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh count when switching to or from notifications tab
    if (widget.indiceSeleccionado != oldWidget.indiceSeleccionado) {
      _cargarConteo();
    }
  }

  Future<void> _cargarConteo() async {
    final count = await _servicioNotificaciones.obtenerConteoNoLeidas();
    if (mounted) setState(() => _notifCount = count);
  }

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
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _IconNav(
                  indice: 0,
                  seleccionado: widget.indiceSeleccionado == 0,
                  alPulsar: widget.alPulsar,
                  icono: Icons.home_outlined,
                  iconoActivo: Icons.home_rounded,
                  esAsset: true,
                ),
                _IconNav(
                  indice: 1,
                  seleccionado: widget.indiceSeleccionado == 1,
                  alPulsar: widget.alPulsar,
                  icono: Icons.groups_outlined,
                  iconoActivo: Icons.groups_rounded,
                ),
                // Notificaciones con badge
                _IconNavConBadge(
                  indice: 2,
                  seleccionado: widget.indiceSeleccionado == 2,
                  alPulsar: widget.alPulsar,
                  icono: Icons.notifications_none_rounded,
                  iconoActivo: Icons.notifications_rounded,
                  count: _notifCount,
                ),
                _IconNav(
                  indice: 3,
                  seleccionado: widget.indiceSeleccionado == 3,
                  alPulsar: widget.alPulsar,
                  icono: Icons.chat_bubble_outline_rounded,
                  iconoActivo: Icons.chat_bubble_rounded,
                ),
                _IconNav(
                  indice: 4,
                  seleccionado: widget.indiceSeleccionado == 4,
                  alPulsar: widget.alPulsar,
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

// ─────────────────────────────────────────────────────────────────────────────
// Icono de notificaciones con badge numérico
// ─────────────────────────────────────────────────────────────────────────────
class _IconNavConBadge extends StatelessWidget {
  final int indice;
  final bool seleccionado;
  final ValueChanged<int> alPulsar;
  final IconData icono;
  final IconData iconoActivo;
  final int count;

  const _IconNavConBadge({
    required this.indice,
    required this.seleccionado,
    required this.alPulsar,
    required this.icono,
    required this.iconoActivo,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconNav(
          indice: indice,
          seleccionado: seleccionado,
          alPulsar: alPulsar,
          icono: icono,
          iconoActivo: iconoActivo,
        ),
        if (count > 0)
          Positioned(
            top: 2,
            right: 2,
            child: AnimatedScale(
              scale: count > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 9 ? '+9' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}