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

  // ── High contrast variants ─────────────────────────────────────────────
  static const hcDarkPanel  = Color(0xFF000000);
  static const hcPanel      = Color(0xFF0A0A0A);
  static const hcBorder     = Color(0xFF444444);
  static const hcSurface    = Color(0xFF111111);
  static const hcText       = Color(0xFFFFFFFF);
  static const hcTextMuted  = Color(0xFFCCCCCC);
  static const hcTeal       = Color(0xFF00FFD4);
  static const hcAmber      = Color(0xFFFFD000);
  static const hcCoral      = Color(0xFFFF4422);

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
  // ── Costruttore dinamico — unico punto di verità ───────────────────────
  static ThemeData build({
    bool highContrast = false,
    bool largeText = false,
  }) {
    // Sceglie palette base o high-contrast
    final bgMain   = highContrast ? BwColors.hcDarkPanel : BwColors.darkPanel;
    final bgPanel  = highContrast ? BwColors.hcPanel     : BwColors.panel;
    final bgSurf   = highContrast ? BwColors.hcSurface   : BwColors.surface;
    final border   = highContrast ? BwColors.hcBorder    : BwColors.panelBorder;
    final primary  = highContrast ? BwColors.hcTeal      : BwColors.teal;
    final amber    = highContrast ? BwColors.hcAmber     : BwColors.amber;
    final coral    = highContrast ? BwColors.hcCoral     : BwColors.coral;
    final txtMain  = highContrast ? BwColors.hcText      : Colors.white;
    final txtMuted = highContrast ? BwColors.hcTextMuted : const Color(0x99FFFFFF);

    // Scala font: normale 1.0, grande 1.20
    final fontScale = largeText ? 1.20 : 1.0;

    // Helper per scalare font size
    double fs(double base) => base * fontScale;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,

      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: highContrast ? BwColors.hcTeal : BwColors.blue,
        surface: bgPanel,
        error: coral,
      ),

      // ── Testo globale ──────────────────────────────────────────────────
      textTheme: TextTheme(
        // Titoli
        headlineLarge:  TextStyle(color: txtMain, fontSize: fs(28), fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: txtMain, fontSize: fs(22), fontWeight: FontWeight.w700),
        headlineSmall:  TextStyle(color: txtMain, fontSize: fs(18), fontWeight: FontWeight.w600),
        // Body
        bodyLarge:   TextStyle(color: txtMain,  fontSize: fs(16)),
        bodyMedium:  TextStyle(color: txtMain,  fontSize: fs(14)),
        bodySmall:   TextStyle(color: txtMuted, fontSize: fs(12)),
        // Labels
        labelLarge:  TextStyle(color: txtMain,  fontSize: fs(14), fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: txtMuted, fontSize: fs(12)),
        labelSmall:  TextStyle(color: txtMuted, fontSize: fs(10)),
        // Title (usato da AppBar, ListTile ecc.)
        titleLarge:  TextStyle(color: txtMain, fontSize: fs(18), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: txtMain, fontSize: fs(15), fontWeight: FontWeight.w500),
        titleSmall:  TextStyle(color: txtMain, fontSize: fs(13), fontWeight: FontWeight.w500),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgMain,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: txtMain,
          fontSize: fs(18),
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: txtMain),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgPanel,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0x55FFFFFF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: fs(10), fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: fs(10)),
      ),

      cardTheme: CardThemeData(
        color: bgPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: txtMuted, fontSize: fs(14)),
        hintStyle: TextStyle(color: const Color(0x40FFFFFF), fontSize: fs(14)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: highContrast ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: TextStyle(fontSize: fs(15), fontWeight: FontWeight.w600),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.white.withOpacity(.1),
        thumbColor: primary,
        overlayColor: primary.withOpacity(.2),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withOpacity(.4)
                : null),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: const Color(0x99FFFFFF),
        labelStyle: TextStyle(fontSize: fs(13), fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: fs(13)),
      ),

      dividerTheme: DividerThemeData(color: border),
    );
  }

  // Mantieni il getter .dark per retrocompatibilità con eventuali
  // riferimenti vecchi nel codebase (non usato dalla nuova BewellApp)
  static ThemeData get dark => build();
}
