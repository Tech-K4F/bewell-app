import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hardRemindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _reminderFrequency = '90min';
  bool _largeText = false;
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Notifications
          _sectionHeader('🔔 Notifiche'),
          _switchTile(
            'Notifiche attive',
            'Ricevi reminder per le tue attività',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          if (_notificationsEnabled) ...[
            _switchTile(
              'Reminder urgenti (Hard)',
              'Per attività critiche come 20-20-20',
              _hardRemindersEnabled,
              (v) => setState(() => _hardRemindersEnabled = v),
            ),
            _switchTile(
              'Suoni',
              'Notifiche con suono',
              _soundEnabled,
              (v) => setState(() => _soundEnabled = v),
            ),
            _switchTile(
              'Vibrazione',
              'Vibrazione per le notifiche',
              _vibrationEnabled,
              (v) => setState(() => _vibrationEnabled = v),
            ),
            _dropdownTile(
              'Frequenza reminder',
              'Con quale frequenza ricevere promemoria',
              _reminderFrequency,
              const {'30min': 'Ogni 30 min', '60min': 'Ogni ora', '90min': 'Ogni 90 min', '120min': 'Ogni 2 ore'},
              (v) => setState(() => _reminderFrequency = v!),
            ),
          ],
          const SizedBox(height: 8),

          // Accessibility
          _sectionHeader('♿ Accessibilità'),
          _switchTile(
            'Testo grande',
            'Aumenta la dimensione del testo',
            _largeText,
            (v) => setState(() => _largeText = v),
          ),
          _switchTile(
            'Alto contrasto',
            'Migliore visibilità per ipovedenti',
            _highContrast,
            (v) => setState(() => _highContrast = v),
          ),
          const SizedBox(height: 8),

          // Planner
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

          // Account
          _sectionHeader('👤 Account'),
          Consumer<AppProvider>(builder: (context, p, _) {
            return Column(
              children: [
                _navigationTile(context, '✏️', 'Modifica profilo',
                    'Nome, email, tipo utente', () {}),
                _navigationTile(context, '🔄', 'Ripristina progressi',
                    'Azzera punti e streak', () => _showResetDialog(context, p)),
              ],
            );
          }),
          const SizedBox(height: 8),

          // Info
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
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
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

  Widget _dropdownTile(String title, String sub, String value,
      Map<String, String> options, ValueChanged<String?> onChanged) {
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: BwColors.coral),
              child: const Text('Ripristina')),
        ],
      ),
    );
  }
}
