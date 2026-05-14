import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Stili disponibili ────────────────────────────────────────────────────────
enum BwStyle {
  card,
  ambient,
}

// ── Palette disponibili ──────────────────────────────────────────────────────
enum BwPalette {
  naturaCalma,
  ariaFresca,
  notteProfonda,
  ambientaleAlba,
  ambientaleNotte,
}

// ── Dati palette ─────────────────────────────────────────────────────────────
class BwPaletteData {
  final String name;
  final Color bg;
  final Color bg2;
  final Color card;
  final Color cardBorder;
  final Color primary;
  final Color primaryLight;
  final Color primaryText;
  final Color accent;
  final Color text;
  final Color textSec;
  final Color textMut;
  final Color nav;
  final Color navBorder;
  final bool isDark;
  // Per stile ambient
  final Color ring;
  final Color ringTrack;
  final Color btn;
  final Color btnText;

  const BwPaletteData({
    required this.name,
    required this.bg,
    required this.bg2,
    required this.card,
    required this.cardBorder,
    required this.primary,
    required this.primaryLight,
    required this.primaryText,
    required this.accent,
    required this.text,
    required this.textSec,
    required this.textMut,
    required this.nav,
    required this.navBorder,
    this.isDark = false,
    required this.ring,
    required this.ringTrack,
    required this.btn,
    required this.btnText,
  });
}

const Map<BwPalette, BwPaletteData> kPalettes = {
  BwPalette.naturaCalma: BwPaletteData(
    name: 'Natura calma',
    bg: Color(0xFFF5F1EA),
    bg2: Color(0xFFEAE5D8),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDDD8CC),
    primary: Color(0xFF4A7C59),
    primaryLight: Color(0xFFE5EFE8),
    primaryText: Color(0xFF2A5038),
    accent: Color(0xFFC47E3A),
    text: Color(0xFF1A291A),
    textSec: Color(0xFF6B7A6B),
    textMut: Color(0xFFA0ACA0),
    nav: Color(0xFFFFFFFF),
    navBorder: Color(0xFFDDD8CC),
    ring: Color(0xFF4A7C59),
    ringTrack: Color(0x2E4A7C59),
    btn: Color(0xFF4A7C59),
    btnText: Color(0xFFFFFFFF),
  ),
  BwPalette.ariaFresca: BwPaletteData(
    name: 'Aria fresca',
    bg: Color(0xFFEDF1F7),
    bg2: Color(0xFFE0E8F2),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFD4DEEC),
    primary: Color(0xFF2B5EA7),
    primaryLight: Color(0xFFE4EEF9),
    primaryText: Color(0xFF0C3470),
    accent: Color(0xFFC47A0A),
    text: Color(0xFF18223A),
    textSec: Color(0xFF556070),
    textMut: Color(0xFF8898AA),
    nav: Color(0xFFFFFFFF),
    navBorder: Color(0xFFD4DEEC),
    ring: Color(0xFF2B5EA7),
    ringTrack: Color(0x262B5EA7),
    btn: Color(0xFF2B5EA7),
    btnText: Color(0xFFFFFFFF),
  ),
  BwPalette.notteProfonda: BwPaletteData(
    name: 'Notte profonda',
    bg: Color(0xFF131C28),
    bg2: Color(0xFF192433),
    card: Color(0xFF1C2C3E),
    cardBorder: Color(0xFF253548),
    primary: Color(0xFF1D9E75),
    primaryLight: Color(0xFF172E28),
    primaryText: Color(0xFF5DCAA5),
    accent: Color(0xFFB87333),
    text: Color(0xFFEAF0F8),
    textSec: Color(0xFF7090AA),
    textMut: Color(0xFF405870),
    nav: Color(0xFF192433),
    navBorder: Color(0xFF253548),
    isDark: true,
    ring: Color(0xFF1D9E75),
    ringTrack: Color(0x2E1D9E75),
    btn: Color(0xFF1D9E75),
    btnText: Color(0xFFFFFFFF),
  ),
  BwPalette.ambientaleAlba: BwPaletteData(
    name: 'Ambientale Alba',
    bg: Color(0xFFF2EDE4),
    bg2: Color(0xFFE8E0D2),
    card: Color(0xBFFFFFFF),
    cardBorder: Color(0x2E5C5044),
    primary: Color(0xFF5C5044),
    primaryLight: Color(0x1A5C5044),
    primaryText: Color(0xFF3A2E22),
    accent: Color(0xFF9C6E3A),
    text: Color(0xFF1E1810),
    textSec: Color(0xFF5C4E3A),
    textMut: Color(0x595C4E3A),
    nav: Color(0xF7F2EDE4),
    navBorder: Color(0x1A5C5044),
    ring: Color(0xFF9C6E3A),
    ringTrack: Color(0x339C6E3A),
    btn: Color(0xFF3A2E22),
    btnText: Color(0xFFF2EDE4),
  ),
  BwPalette.ambientaleNotte: BwPaletteData(
    name: 'Ambientale Notte',
    bg: Color(0xFF0D1520),
    bg2: Color(0xFF111D2C),
    card: Color(0xD91C2C3E),
    cardBorder: Color(0x2E6AAAA8),
    primary: Color(0xFF6AAAA8),
    primaryLight: Color(0x1F6AAAA8),
    primaryText: Color(0xFF5DCAA5),
    accent: Color(0xFF6AAAA8),
    text: Color(0xFFE8F2EE),
    textSec: Color(0xFF9ABCB4),
    textMut: Color(0x599ABCB4),
    nav: Color(0xFA0B121C),
    navBorder: Color(0x1A6AAAA8),
    isDark: true,
    ring: Color(0xFF6AAAA8),
    ringTrack: Color(0x2E6AAAA8),
    btn: Color(0xFF1A3A48),
    btnText: Color(0xFFC8E8E0),
  ),
};

// ── ThemeProvider ────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  BwStyle _style = BwStyle.ambient;
  BwPalette _palette = BwPalette.ambientaleNotte;

  BwStyle get style => _style;
  BwPalette get palette => _palette;
  BwPaletteData get paletteData => kPalettes[_palette]!;

  bool get isAmbient => _style == BwStyle.ambient;
  bool get isDark => paletteData.isDark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIdx = prefs.getInt('bw_style') ?? 0;
    final paletteIdx = prefs.getInt('bw_palette') ?? 0;
    _style = BwStyle.values[styleIdx.clamp(0, BwStyle.values.length - 1)];
    _palette = BwPalette.values[paletteIdx.clamp(0, BwPalette.values.length - 1)];
    notifyListeners();
  }

  Future<void> setStyle(BwStyle style) async {
    _style = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bw_style', style.index);
    notifyListeners();
  }

  Future<void> setPalette(BwPalette palette) async {
    _palette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bw_palette', palette.index);
    notifyListeners();
  }

  // Helper per ottenere il MaterialColor theme dell'app
  ThemeData buildMaterialTheme({
    bool largeText = false,
    bool highContrast = false,
  }) {
    final p = paletteData;
    final isAmb = _style == BwStyle.ambient;
    final fontFamily = isAmb ? 'CormorantGaramond' : 'DM Sans';
    final fs = largeText ? 1.20 : 1.0;

    // High contrast overrides text colors if enabled
    final textColor = highContrast
        ? (p.isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : p.text;
    final textSecColor = highContrast
        ? (p.isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333))
        : p.textSec;

    return ThemeData(
      fontFamily: fontFamily,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme(
        brightness: p.isDark ? Brightness.dark : Brightness.light,
        primary: p.primary,
        onPrimary: p.btnText,
        secondary: p.accent,
        onSecondary: p.btnText,
        surface: p.card,
        onSurface: textColor,
        error: const Color(0xFFE05640),
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge:  TextStyle(color: textColor,    fontSize: 28 * fs, fontWeight: FontWeight.w700, fontFamily: fontFamily),
        headlineMedium: TextStyle(color: textColor,    fontSize: 22 * fs, fontWeight: FontWeight.w700, fontFamily: fontFamily),
        headlineSmall:  TextStyle(color: textColor,    fontSize: 18 * fs, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        bodyLarge:      TextStyle(color: textColor,    fontSize: 16 * fs, fontFamily: fontFamily),
        bodyMedium:     TextStyle(color: textColor,    fontSize: 14 * fs, fontFamily: fontFamily),
        bodySmall:      TextStyle(color: textSecColor, fontSize: 12 * fs, fontFamily: fontFamily),
        labelLarge:     TextStyle(color: textColor,    fontSize: 14 * fs, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        labelMedium:    TextStyle(color: textSecColor, fontSize: 12 * fs, fontFamily: fontFamily),
        labelSmall:     TextStyle(color: textSecColor, fontSize: 10 * fs, fontFamily: fontFamily),
        titleLarge:     TextStyle(color: textColor,    fontSize: 18 * fs, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        titleMedium:    TextStyle(color: textColor,    fontSize: 15 * fs, fontWeight: FontWeight.w500, fontFamily: fontFamily),
        titleSmall:     TextStyle(color: textColor,    fontSize: 13 * fs, fontWeight: FontWeight.w500, fontFamily: fontFamily),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 17 * fs,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}


