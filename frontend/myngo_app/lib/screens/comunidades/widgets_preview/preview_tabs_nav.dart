import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreviewTabsNav extends StatelessWidget {
  final int indiceSeccion;
  final Function(int) onTabChange;

  const PreviewTabsNav({
    super.key,
    required this.indiceSeccion,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTab(0, 'POSTS 📌'),
          const SizedBox(width: 12),
          _buildTab(2, 'GALERÍA 🖼️'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final active = indiceSeccion == index;
    return GestureDetector(
      onTap: () => onTabChange(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFF28B50)
              : (Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFF28B50)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
