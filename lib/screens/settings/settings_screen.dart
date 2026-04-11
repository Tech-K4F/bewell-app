import 'package:flutter/material.dart';
import '../../widgets/locale_selector.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ThemeProvider>(
      builder: (context, settings, theme, _) {
        final p = theme.paletteData;
        return Scaffold(
          backgroundColor: p.bg,
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.text, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Impostazioni',
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
                  label: 'Stile e tonalità',
                  subtitle: '${theme.style == BwStyle.card ? "Card" : "Ambientale"} · ${theme.paletteData.name}',
                  p: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── ACCESSIBILITÀ ──────────────────────────────────────────────
              _SectionHeader(label: 'Accessibilità', p: p),
              _SettingsCard(p: p, children: [
                _ToggleRow(
                  icon: Icons.contrast,
                  iconBg: const Color(0x1A2B5EA7),
                  iconColor: const Color(0xFF2B5EA7),
                  label: context.sL.highContrast,
                  subtitle: 'Aumenta il contrasto dei testi',
                  value: settings.highContrast,
                  onChanged: (v) => settings.setHighContrast(v),
                  p: p,
                ),
                _ToggleRow(
                  icon: Icons.text_fields,
                  iconBg: const Color(0x1AC47E3A),
                  iconColor: const Color(0xFFC47E3A),
                  label: context.sL.largeText,
                  subtitle: 'Aumenta la dimensione dei caratteri',
                  value: settings.largeText,
                  onChanged: (v) => settings.setLargeText(v),
                  p: p,
                ),
              ]),

              const SizedBox(height: 20),

              // ── NOTIFICHE ──────────────────────────────────────────────────
              _SectionHeader(label: context.sL.notifications, p: p),
              _SettingsCard(p: p, children: [
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  iconBg: const Color(0x1A1D9E75),
                  iconColor: const Color(0xFF1D9E75),
                  label: 'Promemoria attività',
                  subtitle: 'Notifiche per le attività pianificate',
                  value: settings.notificationsEnabled,
                  onChanged: (v) => settings.setNotificationsEnabled(v),
                  p: p,
                ),
                _ToggleRow(
                  icon: Icons.local_drink_outlined,
                  iconBg: const Color(0x1A2B5EA7),
                  iconColor: const Color(0xFF2B5EA7),
                  label: context.sL.waterReminder,
                  subtitle: context.sL.waterReminderDesc,
                  value: settings.soundEnabled,
                  onChanged: (v) => settings.setSound(v),
                  p: p,
                ),
              ]),

              const SizedBox(height: 20),

              // ── ACCOUNT ────────────────────────────────────────────────────
              _SectionHeader(label: 'Account', p: p),
              _SettingsCard(p: p, children: [
                _NavRow(
                  icon: Icons.privacy_tip_outlined,
                  iconBg: const Color(0x1AB87333),
                  iconColor: const Color(0xFFB87333),
                  label: context.sL.privacy,
                  p: p,
                  onTap: () {},
                ),
                _NavRow(
                  icon: Icons.help_outline,
                  iconBg: const Color(0x1A7090AA),
                  iconColor: const Color(0xFF7090AA),
                  label: context.sL.support,
                  p: p,
                  onTap: () {},
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







