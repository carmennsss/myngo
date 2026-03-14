import 'dart:math';
import 'package:flutter/material.dart';

enum MonsterState { idle, looking, hiding, computing, happy, sad }

class AnimatedMonsters extends StatefulWidget {
  final MonsterState state;
  final double lookRatio;
  final Offset globalMousePosition;

  const AnimatedMonsters({
    super.key,
    required this.state,
    this.lookRatio = 0.5,
    this.globalMousePosition = Offset.zero,
  });

  @override
  State<AnimatedMonsters> createState() => _AnimatedMonstersState();
}

class _AnimatedMonstersState extends State<AnimatedMonsters> with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _jumpController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedMonsters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == MonsterState.happy) {
        _jumpController.forward(from: 0.0).then((_) => _jumpController.reverse());
      } else if (widget.state == MonsterState.sad) {
        _shakeController.forward(from: 0.0);
      } else if (widget.state == MonsterState.computing) {
        _idleController.duration = const Duration(milliseconds: 500);
        _idleController.repeat(reverse: true);
      } else {
        _idleController.duration = const Duration(milliseconds: 2000);
        _idleController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _jumpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowSize = MediaQuery.of(context).size;
        double mouseOffsetX = 0.0;
        double mouseOffsetY = 0.0;
        
        if (widget.state == MonsterState.idle || widget.state == MonsterState.looking) {
           final dx = widget.globalMousePosition.dx - (windowSize.width / 2);
           final dy = widget.globalMousePosition.dy - (windowSize.height / 3);
           mouseOffsetX = (dx / windowSize.width) * 15.0; 
           mouseOffsetY = (dy / windowSize.height) * 15.0;
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_idleController, _jumpController, _shakeController]),
          builder: (context, child) {
            double jumpOffset = sin(_jumpController.value * pi) * -30.0;
            double shakeOffset = widget.state == MonsterState.sad ? sin(_shakeController.value * 6 * pi) * 10.0 : 0.0;
            double fT = _idleController.value * pi; // float time
            
            Offset eyeOffset = _getEyeOffset(mouseOffsetX, mouseOffsetY);
            bool isClosed = widget.state == MonsterState.hiding || widget.state == MonsterState.happy;
            bool isSad = widget.state == MonsterState.sad;
            bool isHappy = widget.state == MonsterState.happy;

            return Container(
              height: 220, 
              width: 320,
              padding: const EdgeInsets.only(top: 20),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                   // Purple (Back Left-ish)
                   Positioned(
                     left: 70,
                     bottom: jumpOffset + sin(fT) * 4,
                     child: Transform.translate(
                       offset: Offset(shakeOffset, 0),
                       child: _buildPurple(eyeOffset, isClosed, isSad, isHappy),
                     ),
                   ),
                   // Black (Middle Right)
                   Positioned(
                     left: 155,
                     bottom: jumpOffset + sin(fT + 1) * 6,
                     child: Transform.translate(
                       offset: Offset(shakeOffset * 0.8, 0),
                       child: _buildBlack(eyeOffset, isClosed, isSad, isHappy),
                     ),
                   ),
                   // Yellow (Front Right)
                   Positioned(
                     left: 210,
                     bottom: jumpOffset + sin(fT + 2) * 5,
                     child: Transform.translate(
                       offset: Offset(shakeOffset * 1.2, 0),
                       child: _buildYellow(eyeOffset, isClosed, isSad, isHappy),
                     ),
                   ),
                   // Orange (Front Left)
                   Positioned(
                     left: 10,
                     bottom: jumpOffset + sin(fT + 3) * 4,
                     child: Transform.translate(
                       offset: Offset(shakeOffset * 0.9, 0),
                       child: _buildOrange(eyeOffset, isClosed, isSad, isHappy),
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

  Offset _getEyeOffset(double mouseX, double mouseY) {
    if (widget.state == MonsterState.looking) {
      return Offset((widget.lookRatio - 0.5) * 20, 0); 
    } else if (widget.state == MonsterState.idle) {
      return Offset(mouseX.clamp(-8.0, 8.0), mouseY.clamp(-4.0, 4.0));
    } else if (widget.state == MonsterState.sad) {
      return const Offset(0, 4);
    }
    return const Offset(0, 0);
  }

  Widget _buildPurple(Offset eye, bool isClosed, bool isSad, bool isHappy) {
    return Container(
      width: 90,
      height: 180,
      color: const Color(0xFF6F32FF), // Purple
      child: Stack(
        clipBehavior: Clip.none,
        children: [
           // Eyes
           AnimatedPositioned(
             duration: const Duration(milliseconds: 100),
             top: 40 + eye.dy,
             left: 25 + eye.dx,
             child: Row(
               children: [
                 _buildWhiteEye(isClosed, isSad, isHappy),
                 const SizedBox(width: 12),
                 _buildWhiteEye(isClosed, isSad, isHappy),
               ],
             ),
           ),
           // Mouth (vertical line)
           AnimatedPositioned(
             duration: const Duration(milliseconds: 200),
             top: isHappy ? 55 : (isSad ? 60 : 45), // Drops when sad
             left: 45 + eye.dx * 0.5,
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               width: 5,
               height: isHappy ? 12 : (isSad ? 6 : 20),
               color: const Color(0xFF141414),
             ),
           ),
        ],
      )
    );
  }

  Widget _buildBlack(Offset eye, bool isClosed, bool isSad, bool isHappy) {
    return Container(
      width: 70,
      height: 120,
      color: const Color(0xFF1F2024), // Dark Grey/Black
      child: Stack(
        clipBehavior: Clip.none,
        children: [
           // Eyes protruding to the right
           AnimatedPositioned(
             duration: const Duration(milliseconds: 100),
             top: 35 + eye.dy,
             right: -7 - eye.dx, // Sticks out to the right
             child: Row(
               children: [
                 _buildWhiteEye(isClosed, isSad, isHappy),
                 const SizedBox(width: 5),
                 _buildWhiteEye(isClosed, isSad, isHappy),
               ],
             ),
           ),
        ],
      )
    );
  }

  Widget _buildYellow(Offset eye, bool isClosed, bool isSad, bool isHappy) {
    return Container(
      width: 65,
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFFF1CA19), // Yellow
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        )
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
           // Eye (one dot)
           AnimatedPositioned(
             duration: const Duration(milliseconds: 100),
             top: 30 + eye.dy,
             left: 25 + eye.dx,
             child: isClosed 
                ? Container(width: 10, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2)))
                : Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF141414), shape: BoxShape.circle)),
           ),
           // Nose/Mouth (Horizontal line protruding right)
           AnimatedPositioned(
             duration: const Duration(milliseconds: 200),
             top: 45 + eye.dy * 0.5,
             right: -15, // Sticks out further
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               width: isSad ? 25 : 35, // shorter when sad
               height: 4,
               color: const Color(0xFF141414),
             ),
           ),
        ],
      )
    );
  }

  Widget _buildOrange(Offset eye, bool isClosed, bool isSad, bool isHappy) {
    return Container(
      width: 150,
      height: 75,
      decoration: const BoxDecoration(
        color: Color(0xFFFF7E36), // Orange
        borderRadius: BorderRadius.only(
           topLeft: Radius.circular(75),
           topRight: Radius.circular(75),
        )
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
           // Eyes
           AnimatedPositioned(
             duration: const Duration(milliseconds: 100),
             top: 40 + eye.dy,
             left: 45 + eye.dx,
             child: Row(
               children: [
                 isClosed ? Container(width: 10, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2))) : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF141414), shape: BoxShape.circle)),
                 const SizedBox(width: 40),
                 isClosed ? Container(width: 10, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2))) : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF141414), shape: BoxShape.circle)),
               ],
             ),
           ),
           // Mouth
           AnimatedPositioned(
             duration: const Duration(milliseconds: 200),
             top: 55 + eye.dy,
             left: 63 + eye.dx,
             child: _buildOrangeMouth(isSad, isHappy, isClosed),
           ),
        ],
      )
    );
  }

  Widget _buildWhiteEye(bool isClosed, bool isSad, bool isHappy) {
    // White eye background
    return Container(
       width: 16,
       height: 16,
       decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
       alignment: Alignment.center,
       child: isClosed 
          ? Container(width: 10, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2)))
          : AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: isHappy ? 8 : 6,
            height: isHappy ? 8 : 6,
            decoration: const BoxDecoration(color: Color(0xFF141414), shape: BoxShape.circle)
          ),
    );
  }

  Widget _buildOrangeMouth(bool isSad, bool isHappy, bool isClosed) {
    if (isSad) {
      return Container(
        width: 24,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
      );
    }
    if (isClosed) {
       return Container(
         margin: const EdgeInsets.only(top: 4),
         width: 16, height: 3, decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(2))
       );
    }
    // Smile
    return Container(
      width: 24,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
    );
  }
}
