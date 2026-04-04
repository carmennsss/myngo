import 'package:flutter/material.dart';

class SelectorEstrellas extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  const SelectorEstrellas({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
  });

  @override
  State<SelectorEstrellas> createState() => _SelectorEstrellasState();
}

class _SelectorEstrellasState extends State<SelectorEstrellas> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1;
            });
            widget.onRatingChanged(_currentRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              index < _currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: index < _currentRating ? Colors.amber : Colors.grey.shade400,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
