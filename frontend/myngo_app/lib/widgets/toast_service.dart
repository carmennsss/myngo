import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

enum ToastType { success, error, info, warning }

class ToastService {


  static final Map<ToastType, ToastificationItem?> activeToasts = {};
  static const int maxVisible = 2;

  static void _cancelPrevious(ToastType type) {
    final existing = activeToasts[type];
    if (existing != null) {
      Toastification().dismiss(existing);
      activeToasts[type] = null;
    }
  }

  static void _enforceMaxVisible() {
    final active = activeToasts.values.whereType<ToastificationItem>().toList();
    while (active.length >= maxVisible) {
      final oldest = active.removeAt(0);
      Toastification().dismiss(oldest);
      for (final entry in activeToasts.entries) {
        if (entry.value == oldest) {
          activeToasts[entry.key] = null;
          break;
        }
      }
    }
  }

  static void _show({
    required BuildContext context,
    required ToastType type,
    required String message,
    String? description,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
    Color? iconColor,
  }) {
    _cancelPrevious(type);
    _enforceMaxVisible();

    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.surface;
    final fg = foregroundColor ?? cs.onSurface;
    final iconData = icon ?? _defaultIcon(type);
    final iconCol = iconColor ?? _defaultIconColor(type, cs);

    final item = Toastification().show(
      context: context,
      type: ToastificationType.values[_typeIndex(type)],
      style: ToastificationStyle.flat,
      autoCloseDuration: duration,
      title: Text(
        message,
        style: GoogleFonts.outfit(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      description: description != null
          ? Text(
              description,
              style: GoogleFonts.outfit(
                color: fg.withOpacity(0.7),
                fontSize: 12,
              ),
            )
          : null,
      alignment: Alignment.topCenter,
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      icon: Icon(iconData, color: iconCol, size: 22),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      backgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(
        color: iconCol.withOpacity(0.6),
        linearTrackColor: iconCol.withOpacity(0.15),
      ),
      applyBlurEffect: false,
    );

    activeToasts[type] = item;
  }

  // ── Public API ──

  static void showSuccess(BuildContext context, String message,
      {String? description, Duration? duration}) {
    _show(
      context: context,
      type: ToastType.success,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: const Color(0xFFC35E34),
      foregroundColor: Colors.white,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message,
      {String? description, Duration? duration}) {
    _show(
      context: context,
      type: ToastType.error,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 4),
      backgroundColor: const Color(0xFFD95F43),
      foregroundColor: Colors.white,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.white,
    );
  }

  static void showInfo(BuildContext context, String message,
      {String? description, Duration? duration}) {
    _show(
      context: context,
      type: ToastType.info,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: const Color(0xFF248EA6),
      foregroundColor: Colors.white,
      icon: Icons.info_outline_rounded,
      iconColor: Colors.white,
    );
  }

  static void showWarning(BuildContext context, String message,
      {String? description, Duration? duration}) {
    _show(
      context: context,
      type: ToastType.warning,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 4),
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.white,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.white,
    );
  }

  // ── Helpers ──

  static IconData _defaultIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  static Color _defaultIconColor(ToastType type, ColorScheme cs) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFFC35E34);
      case ToastType.error:
        return const Color(0xFFD95F43);
      case ToastType.info:
        return const Color(0xFF248EA6);
      case ToastType.warning:
        return Colors.amber.shade700;
    }
  }

  static int _typeIndex(ToastType type) {
    switch (type) {
      case ToastType.success:
        return 0;
      case ToastType.error:
        return 1;
      case ToastType.info:
        return 2;
      case ToastType.warning:
        return 3;
    }
  }
}
