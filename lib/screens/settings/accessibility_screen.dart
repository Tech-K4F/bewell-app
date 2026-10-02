import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';

/// Accessibilità: dimensione del testo, contrasto e movimento. Le impostazioni
/// valgono per tutta l'app; in più Be Well segue la dimensione del testo e la
/// riduzione animazioni impostate nel telefono.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final settings = context.watch<SettingsProvider>();

    Widget tile({
      required IconData icon,
      required String title,
      required String desc,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: p.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          secondary: ExcludeSemantics(child: Icon(icon, color: p.primary)),
          title: Text(title,
              style: TextStyle(
                  color: p.text, fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text(desc,
              style: TextStyle(color: p.textSec, fontSize: 12.5, height: 1.35)),
        ),
      );
    }

    return BwScaffold(
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        title: Text(s.accessibility,
            style: TextStyle(color: p.text, fontSize: 17)),
        leading: BackButton(color: p.text),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          tile(
            icon: Icons.text_increase_rounded,
            title: s.largeText,
            desc: s.largeTextDesc,
            value: settings.largeText,
            onChanged: settings.setLargeText,
          ),
          tile(
            icon: Icons.contrast_rounded,
            title: s.highContrast,
            desc: s.highContrastDesc,
            value: settings.highContrast,
            onChanged: settings.setHighContrast,
          ),
          tile(
            icon: Icons.slow_motion_video_rounded,
            title: s.reduceMotion,
            desc: s.reduceMotionDesc,
            value: settings.reduceMotion,
            onChanged: settings.setReduceMotion,
          ),
          if (kDebugMode) ...[
            Wrap(spacing: 8, children: [
              for (final v in const [1.0, 1.5, 2.0])
                ChoiceChip(
                  label: Text('Debug testo ×$v'),
                  selected: settings.debugTextScale == v,
                  onSelected: (_) => settings.setDebugTextScale(v),
                ),
            ]),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Text(s.accessibilityHint,
              style: TextStyle(color: p.textMut, fontSize: 12, height: 1.45)),
        ],
      ),
    );
  }
}
