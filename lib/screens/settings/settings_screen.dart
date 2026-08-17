import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showComingSoon(BuildContext context, BwPaletteData p) {
    final s = context.sL;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.comingSoonTitle, style: TextStyle(color: p.text, fontSize: 16)),
        content: Text(s.comingSoonBody, style: TextStyle(color: p.textSec, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.confirm, style: TextStyle(color: p.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ThemeProvider>(
      builder: (context, settings, theme, _) {
        final p = theme.paletteData;
        final s = context.sL;
        return BwScaffold(
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.text, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(s.settingsTitle,
                style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [

              // ── ASPETTO ────────────────────────────────────────────────────
              _SectionHeader(label: context.sL.themeTitle, p: p),
              _SettingsCard(p: p, children: [
                _NavRow(
                  icon: Icons.palette_outlined,
                  iconBg: p.primaryLight,
                  iconColor: p.primary,
                  label: s.appearance,
                  subtitle: '${theme.style == BwStyle.card ? s.themeCard : s.themeAmbient} · ${theme.paletteData.name}',
                  p: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── ACCESSIBILITÀ ──────────────────────────────────────────────
              _SectionHeader(label: s.accessibilitySection, p: p),
              _SettingsCard(p: p, children: [
                _ToggleRow(
                  icon: Icons.contrast,
                  iconBg: const Color(0x1A2B5EA7),
                  iconColor: const Color(0xFF2B5EA7),
                  label: context.sL.highContrast,
                  subtitle: s.contrastDesc,
                  value: settings.highContrast,
                  onChanged: (v) => settings.setHighContrast(v),
                  p: p,
                ),
                _ToggleRow(
                  icon: Icons.text_fields,
                  iconBg: const Color(0x1AC47E3A),
                  iconColor: const Color(0xFFC47E3A),
                  label: context.sL.largeText,
                  subtitle: s.textSizeDesc,
                  value: settings.largeText,
                  onChanged: (v) => settings.setLargeText(v),
                  p: p,
                ),
              ]),

              const SizedBox(height: 20),

              // ── NOTIFICHE ──────────────────────────────────────────────────
              _SectionHeader(label: context.sL.notifications, p: p),
              _NotificationFrequencyCard(settings: settings, p: p, s: s),
              const SizedBox(height: 12),
              _SnoozeCard(settings: settings, p: p, s: s),

              const SizedBox(height: 20),

              // ── ACCOUNT ────────────────────────────────────────────────────
              _SectionHeader(label: s.accountSection, p: p),
              _SettingsCard(p: p, children: [
                _NavRow(
                  icon: Icons.privacy_tip_outlined,
                  iconBg: const Color(0x1AB87333),
                  iconColor: const Color(0xFFB87333),
                  label: context.sL.privacy,
                  p: p,
                  onTap: () => _showComingSoon(context, p),
                ),
                _NavRow(
                  icon: Icons.help_outline,
                  iconBg: const Color(0x1A7090AA),
                  iconColor: const Color(0xFF7090AA),
                  label: context.sL.support,
                  p: p,
                  onTap: () => _showComingSoon(context, p),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ── Componenti UI ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _SectionHeader({required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: p.textSec,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final BwPaletteData p;
  const _SettingsCard({required this.children, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        children: children.map((child) {
          final index = children.indexOf(child);
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: p.cardBorder,
                  indent: 52,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final BwPaletteData p;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: p.textSec, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textMut, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final BwPaletteData p;

  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: p.textSec, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: p.primary,
            activeTrackColor: p.primaryLight,
          ),
        ],
      ),
    );
  }
}

/// Selettore della frequenza dei reminder (zero / poche / normale / tutte).
/// Sostituisce il vecchio toggle on/off generico: l'utente sceglie quanto
/// essere sollecitato, invece di un binario tutto-o-niente.
class _NotificationFrequencyCard extends StatelessWidget {
  final SettingsProvider settings;
  final BwPaletteData p;
  final BwStrings s;
  const _NotificationFrequencyCard({required this.settings, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    final options = [
      (NotificationFrequency.off,    s.notifFreqOff,    s.notifFreqOffDesc,    Icons.notifications_off_outlined),
      (NotificationFrequency.low,    s.notifFreqLow,    s.notifFreqLowDesc,    Icons.notifications_none),
      (NotificationFrequency.normal, s.notifFreqNormal, s.notifFreqNormalDesc, Icons.notifications_outlined),
      (NotificationFrequency.high,   s.notifFreqHigh,   s.notifFreqHighDesc,   Icons.notifications_active_outlined),
    ];
    return _SettingsCard(
      p: p,
      children: options.map((opt) {
        final (freq, label, desc, icon) = opt;
        final selected = settings.frequency == freq;
        return InkWell(
          onTap: () => settings.setFrequency(freq),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? p.primary.withValues(alpha: .15) : p.bg2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: selected ? p.primary : p.textMut, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: p.text,
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                      Text(desc, style: TextStyle(color: p.textSec, fontSize: 11, height: 1.3)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: p.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Pausa temporanea dei reminder — indipendente dalla frequenza scelta,
/// riprendono da soli allo scadere del tempo impostato con lo slider.
class _SnoozeCard extends StatefulWidget {
  final SettingsProvider settings;
  final BwPaletteData p;
  final BwStrings s;
  const _SnoozeCard({required this.settings, required this.p, required this.s});

  @override
  State<_SnoozeCard> createState() => _SnoozeCardState();
}

class _SnoozeCardState extends State<_SnoozeCard> {
  double _hours = 4;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = widget.s;
    final settings = widget.settings;

    if (settings.isSnoozed) {
      final until = settings.snoozeUntil!;
      final label = '${until.hour.toString().padLeft(2, '0')}:${until.minute.toString().padLeft(2, '0')}';
      return _SettingsCard(p: p, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: p.bg2, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.snooze_rounded, color: p.textMut, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.notifSnoozeActive(label),
                    style: TextStyle(color: p.text, fontSize: 13.5, fontWeight: FontWeight.w500)),
              ),
              TextButton(
                onPressed: () => settings.clearSnooze(),
                child: Text(s.notifSnoozeCancel, style: TextStyle(color: p.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
      ]);
    }

    return _SettingsCard(p: p, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: p.bg2, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.snooze_rounded, color: p.textMut, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.notifSnoozeLabel,
                  style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Text(s.notifSnoozeHours(_hours.round()),
                style: TextStyle(color: p.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: p.primary,
          inactiveTrackColor: p.primaryLight,
          thumbColor: p.primary,
          overlayColor: p.primary.withValues(alpha: .15),
        ),
        child: Slider(
          value: _hours,
          min: 1,
          max: 24,
          divisions: 23,
          onChanged: (v) => setState(() => _hours = v),
          onChangeEnd: (v) => settings.setSnoozeHours(v.round()),
        ),
      ),
      const SizedBox(height: 4),
    ]);
  }
}




