import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF2F6BDB);
  static const orange = Color(0xFFF2704A);
  static const teal = Color(0xFF4FD6C4);
  static const purple = Color(0xFF9B7BFF);
  static const green = Color(0xFF5ED38A);
  static const yellow = Color(0xFFF5C451);

  static const darkBg = Color(0xFF16171B);
  static const darkCard = Color(0xFF222328);
  static const lightBg = Color(0xFFF3F4F8);
  static const lightCard = Colors.white;

  /// Colour used for each task category.
  static Color category(String c) {
    switch (c) {
      case 'Work':
        return orange;
      case 'Personal':
        return teal;
      case 'Study':
        return purple;
      case 'Health':
        return green;
      case 'Shopping':
        return yellow;
      default:
        return blue;
    }
  }
}

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final onSurface = isDark ? const Color(0xFFF2F3F7) : const Color(0xFF1B1C20);
    final muted = isDark ? const Color(0xFF9A9CA8) : const Color(0xFF6B6E7B);

    final scheme = ColorScheme(
      brightness: b,
      primary: AppColors.blue,
      onPrimary: Colors.white,
      secondary: AppColors.teal,
      onSecondary: Colors.black,
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD93025),
      onError: Colors.white,
      surface: bg,
      onSurface: onSurface,
      surfaceContainerHighest: card,
      onSurfaceVariant: muted,
      primaryContainer: isDark ? const Color(0xFF1F3A6E) : const Color(0xFFDCE6FA),
      onPrimaryContainer: isDark ? Colors.white : const Color(0xFF12337A),
      outline: muted,
    );

    OutlineInputBorder border([Color? c]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: 1.5),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            color: onSurface, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(AppColors.blue),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error),
        labelStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          backgroundColor: card,
          side: BorderSide.none,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: AppColors.blue,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: onSurface),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        checkmarkColor: Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF34353C) : const Color(0xFF2A2B31),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: muted, width: 2),
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.blue : Colors.transparent),
      ),
      dividerColor: muted.withAlpha(40),
    );
  }
}
