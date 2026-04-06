import 'package:flutter/material.dart';

/// Un wrapper que añade una animación de "presión física" (escala y desplazamiento).
class BotonTactil extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double offset;

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

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
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
