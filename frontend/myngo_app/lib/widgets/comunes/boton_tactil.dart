import 'package:flutter/material.dart';


// Envuelve cualquier widget y le da efecto de "press" físico al tocarlo.
// Se encoge ligeramente cuando se pulsa y vuelve a su tamaño al soltar.
class BotonTactil extends StatefulWidget {
  final Widget child;    // El widget que queremos que tenga el efecto
  final VoidCallback? onTap; // Qué hacer al pulsar
  final double scale;    // Escala al presionar (0.96 = se encoge un 4%)
  final double offset;   // Desplazamiento vertical para simular que baja

  const BotonTactil({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.offset = 2.0,
  });

  @override
  State<BotonTactil> createState() => _BotonTactilState();
}

class _BotonTactilState extends State<BotonTactil> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Arranca la animación de encogimiento al bajar el dedo
    if (widget.onTap != null) _controller.forward();
  }

  // Vuelve a su tamaño y dispara el onTap al soltar
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  // Si el usuario mueve el dedo fuera, vuelve al tamaño normal sin ejecutar nada
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, (1.0 - _scaleAnimation.value) * widget.offset * 10),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
