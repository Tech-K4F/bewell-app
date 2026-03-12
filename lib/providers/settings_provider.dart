import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce tutte le impostazioni dell'app che influenzano
/// il tema e il comportamento globale.
///
/// Separato da AppProvider per responsabilità singola:
/// AppProvider → dati utente e attività
/// SettingsProvider → preferenze UI e accessibilità
class SettingsProvider extends ChangeNotifier {
  // ── Accessibilità ───────────────────────────────────────────────────────
  bool _largeText     = false;
  bool _highContrast  = false;

  // ── Notifiche ───────────────────────────────────────────────────────────
  bool _notificationsEnabled  = true;
  bool _hardRemindersEnabled  = true;
  bool _soundEnabled          = true;
  bool _vibrationEnabled      = true;
  String _reminderFrequency   = '90min';

  // ── Getters ─────────────────────────────────────────────────────────────
  bool get largeText            => _largeText;
  bool get highContrast         => _highContrast;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get hardRemindersEnabled => _hardRemindersEnabled;
  bool get soundEnabled         => _soundEnabled;
  bool get vibrationEnabled     => _vibrationEnabled;
  String get reminderFrequency  => _reminderFrequency;

  // ── Init ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _largeText            = p.getBool('setting_large_text')    ?? false;
    _highContrast         = p.getBool('setting_high_contrast') ?? false;
    _notificationsEnabled = p.getBool('setting_notifications') ?? true;
    _hardRemindersEnabled = p.getBool('setting_hard_reminders')  ?? true;
    _soundEnabled         = p.getBool('setting_sound')         ?? true;
    _vibrationEnabled     = p.getBool('setting_vibration')     ?? true;
    _reminderFrequency    = p.getString('setting_freq')        ?? '90min';
    notifyListeners();
  }

  // ── Setters con persist ──────────────────────────────────────────────────
  Future<void> setLargeText(bool v) async {
    _largeText = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_large_text', v);
    notifyListeners(); // ← ricostruisce MaterialApp → tema ricalcolato
  }

  Future<void> setHighContrast(bool v) async {
    _highContrast = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_high_contrast', v);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool v) async {
    _notificationsEnabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_notifications', v);
    notifyListeners();
  }

  Future<void> setHardReminders(bool v) async {
    _hardRemindersEnabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_hard_reminders', v);
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    _soundEnabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_sound', v);
    notifyListeners();
  }

  Future<void> setVibration(bool v) async {
    _vibrationEnabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('setting_vibration', v);
    notifyListeners();
  }

  Future<void> setReminderFrequency(String v) async {
    _reminderFrequency = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('setting_freq', v);
    notifyListeners();
  }
}
