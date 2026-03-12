import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX 4: legge da SettingsProvider invece di setState locale
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: BwColors.darkPanel,
          appBar: AppBar(title: const Text('Impostazioni')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // ── Notifiche ──────────────────────────────────────────────────
              _sectionHeader('🔔 Notifiche'),
              _switchTile(
                context,
                'Notifiche attive',
                'Ricevi reminder per le tue attività',
                settings.notificationsEnabled,
                (v) => settings.setNotificationsEnabled(v),
              ),
              if (settings.notificationsEnabled) ...[
                _switchTile(
                  context,
                  'Reminder urgenti (Hard)',
                  'Per attività critiche come 20-20-20',
                  settings.hardRemindersEnabled,
                  (v) => settings.setHardReminders(v),
                ),
                _switchTile(
                  context,
                  'Suoni',
                  'Notifiche con suono',
                  settings.soundEnabled,
                  (v) => settings.setSound(v),
                ),
                _switchTile(
                  context,
                  'Vibrazione',
                  'Vibrazione per le notifiche',
                  settings.vibrationEnabled,
                  (v) => settings.setVibration(v),
                ),
                _dropdownTile(
                  context,
                  'Frequenza reminder',
                  'Con quale frequenza ricevere promemoria',
                  settings.reminderFrequency,
                  const {
                    '30min': 'Ogni 30 min',
                    '60min': 'Ogni ora',
                    '90min': 'Ogni 90 min',
                    '120min': 'Ogni 2 ore',
                  },
                  (v) => settings.setReminderFrequency(v!),
                ),
              ],
              const SizedBox(height: 8),

              // ── Accessibilità ──────────────────────────────────────────────
              _sectionHeader('♿ Accessibilità'),

              // Preview badge mostra l'effetto PRIMA di toccare il toggle
              if (settings.largeText || settings.highContrast)
                _accessibilityPreviewBadge(settings),

              _switchTile(
                context,
                'Testo grande',
                'Aumenta la dimensione del testo del 20%',
                settings.largeText,
                (v) => settings.setLargeText(v),
                // FIX: ora chiama SettingsProvider.setLargeText()
                // che chiama notifyListeners() → MaterialApp si ricostruisce
                // → AppTheme.build(largeText: true) viene applicato
              ),
              _switchTile(
                context,
                'Alto contrasto',
                'Maggiore contrasto per ipovedenti',
                settings.highContrast,
                (v) => settings.setHighContrast(v),
                // FIX: stessa logica — ricostruisce il tema globalmente
              ),
              const SizedBox(height: 8),

              // ── Piano ──────────────────────────────────────────────────────
              _sectionHeader('📅 Piano'),
              _navigationTile(
                context,
                '⏰',
                'Orari di lavoro',
                'Configura inizio e fine giornata lavorativa',
                () => Navigator.pop(context),
              ),
              _navigationTile(
                context,
                '🎯',
                'Obiettivi',
                'Imposta i tuoi obiettivi di benessere',
                () {},
              ),
              const SizedBox(height: 8),

              // ── Account ────────────────────────────────────────────────────
              _sectionHeader('👤 Account'),
              Consumer<AppProvider>(builder: (context, p, _) {
                return Column(
                  children: [
                    _navigationTile(context, '✏️', 'Modifica profilo',
                        'Nome, email, tipo utente', () {}),
                    _navigationTile(
                        context,
                        '🔄',
                        'Ripristina progressi',
                        'Azzera punti e streak',
                        () => _showResetDialog(context, p)),
                  ],
                );
              }),
              const SizedBox(height: 8),

              // ── Info ───────────────────────────────────────────────────────
              _sectionHeader('ℹ️ Info App'),
              _navigationTile(context, '❓', 'Come funziona',
                  'Guida all\'app', () {}),
              _navigationTile(context, '⭐', 'Lascia una recensione',
                  'Aiutaci a migliorare', () {}),
              _navigationTile(context, '📧', 'Contatta il supporto',
                  'Segnala problemi o suggerimenti', () {}),
              const SizedBox(height: 16),
              Center(
                child: Text('Be Well v1.0.0',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.2), fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mostra badge se accessibilità attiva ──────────────────────────────────
  Widget _accessibilityPreviewBadge(SettingsProvider s) {
    final parts = <String>[];
    if (s.largeText) parts.add('Testo grande attivo');
    if (s.highContrast) parts.add('Alto contrasto attivo');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BwColors.tealLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BwColors.teal.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(
                  color: BwColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  Widget _switchTile(
    BuildContext context,
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(sub,
            style: TextStyle(
                color: Colors.white.withOpacity(.3), fontSize: 11)),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _dropdownTile(
    BuildContext context,
    String title,
    String sub,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text(sub,
                      style: TextStyle(
                          color: Colors.white.withOpacity(.3),
                          fontSize: 11)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: value,
              dropdownColor: BwColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(
                  color: BwColors.teal, fontWeight: FontWeight.w600),
              items: options.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationTile(BuildContext ctx, String emoji, String title,
      String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 20)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(sub,
            style: TextStyle(
                color: Colors.white.withOpacity(.3), fontSize: 11)),
        trailing: Icon(Icons.chevron_right,
            color: Colors.white.withOpacity(.2), size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Ripristina progressi',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Azzererai punti, streak e badge. Questa azione non è reversibile.',
          style: TextStyle(color: Colors.white.withOpacity(.5)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla',
                  style: TextStyle(color: BwColors.teal))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                p.resetAll();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: BwColors.coral),
              child: const Text('Ripristina')),
        ],
      ),
    );
  }
}
