import 'package:flutter/material.dart';

class BwColors {
  static const teal = Color(0xFF1E9E87);
  static const tealLight = Color(0x1A1E9E87);
  static const tealGlow = Color(0x331E9E87);
  static const blue = Color(0xFF3A7BD5);
  static const blueLight = Color(0x1A3A7BD5);
  static const amber = Color(0xFFD99820);
  static const amberLight = Color(0x1FD99820);
  static const coral = Color(0xFFE05640);
  static const coralLight = Color(0x1AE05640);
  static const purple = Color(0xFF8B4FCC);
  static const purpleLight = Color(0x1A8B4FCC);
  static const green = Color(0xFF27A17A);
  static const greenLight = Color(0x1A27A17A);

  static const darkPanel = Color(0xFF0B1929);
  static const panel = Color(0xFF0F1F33);
  static const panelBorder = Color(0xFF1A2E42);
  static const surface = Color(0xFF142236);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0x99FFFFFF);
  static const textMuted = Color(0x40FFFFFF);

  static Color categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('hydration') || c.contains('nutrition')) return teal;
    if (c.contains('movement') || c.contains('posture')) return amber;
    if (c.contains('eyes') || c.contains('vision')) return coral;
    if (c.contains('focus') || c.contains('productivity')) return purple;
    if (c.contains('stress') || c.contains('mindfulness')) return blue;
    if (c.contains('sleep') || c.contains('recovery')) return const Color(0xFF1A4B8C);
    if (c.contains('digital')) return green;
    return teal;
  }

  static String categoryEmoji(String category) {
    final c = category.toLowerCase();
    if (c.contains('hydration') || c.contains('nutrition')) return '💧';
    if (c.contains('movement') || c.contains('posture')) return '🏃';
    if (c.contains('eyes') || c.contains('vision')) return '👁';
    if (c.contains('focus') || c.contains('productivity')) return '⏱';
    if (c.contains('stress') || c.contains('mindfulness')) return '🧘';
    if (c.contains('sleep') || c.contains('recovery')) return '😴';
    if (c.contains('digital')) return '📱';
    return '🌿';
  }
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BwColors.darkPanel,
      colorScheme: const ColorScheme.dark(
        primary: BwColors.teal,
        secondary: BwColors.blue,
        surface: BwColors.panel,
        error: BwColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BwColors.darkPanel,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BwColors.panel,
        selectedItemColor: BwColors.teal,
        unselectedItemColor: Color(0x55FFFFFF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      cardTheme: CardThemeData(
        color: BwColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BwColors.panelBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BwColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BwColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BwColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BwColors.teal, width: 1.5),
        ),
        labelStyle: const TextStyle(color: BwColors.textSecondary),
        hintStyle: const TextStyle(color: BwColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BwColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BwColors.teal,
        inactiveTrackColor: Colors.white.withOpacity(.1),
        thumbColor: BwColors.teal,
        overlayColor: BwColors.tealLight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? BwColors.teal : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? BwColors.tealLight : null),
      ),
    );
  }
}
