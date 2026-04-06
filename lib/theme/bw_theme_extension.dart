import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// ── Extension shortcut ────────────────────────────────────────────────────────
extension BwThemeContext on BuildContext {
  BwPaletteData get bwTheme => read<ThemeProvider>().paletteData;
  ThemeProvider get bwProvider => read<ThemeProvider>();
  bool get isAmbient => read<ThemeProvider>().isAmbient;
}
