import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Quante volte al giorno arrivano i reminder delle abitudini.
/// Le fasce orarie sono scelte per restare nell'orario di veglia (9-21)
/// e distanziate almeno 2h per evitare assuefazione da notifica —
/// un intervallo più fitto (es. ogni 90 min sui cicli ultradiani di
/// Kleitman) satura l'attenzione invece di sostenerla.
enum NotificationFrequency { off, low, normal, high }

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
  NotificationFrequency _frequency = NotificationFrequency.normal;
  DateTime? _snoozeUntil;

  // ── Getters ─────────────────────────────────────────────────────────────
  bool get largeText            => _largeText;
  bool get highContrast         => _highContrast;
  NotificationFrequency get frequency => _frequency;
  DateTime? get snoozeUntil     => _snoozeUntil;
  bool get isSnoozed            => _snoozeUntil != null && _snoozeUntil!.isAfter(DateTime.now());

  // ── Init ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _largeText    = p.getBool('setting_large_text')    ?? false;
    _highContrast = p.getBool('setting_high_contrast') ?? false;
    _frequency = NotificationFrequency.values.firstWhere(
      (f) => f.name == (p.getString('notif_frequency') ?? 'normal'),
      orElse: () => NotificationFrequency.normal,
    );
    final snoozeMs = p.getInt('notif_snooze_until');
    _snoozeUntil = snoozeMs != null ? DateTime.fromMillisecondsSinceEpoch(snoozeMs) : null;
    notifyListeners();
    await rescheduleBwReminders();
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

  Future<void> setFrequency(NotificationFrequency f) async {
    _frequency = f;
    _snoozeUntil = null; // scegliere una frequenza esplicita annulla la pausa
    final p = await SharedPreferences.getInstance();
    await p.setString('notif_frequency', f.name);
    await p.remove('notif_snooze_until');
    notifyListeners();
    await rescheduleBwReminders();
  }

  /// Mette in pausa i reminder per [hours] ore, senza cambiare la frequenza
  /// scelta — riprendono automaticamente allo scadere.
  Future<void> setSnoozeHours(int hours) async {
    _snoozeUntil = DateTime.now().add(Duration(hours: hours));
    final p = await SharedPreferences.getInstance();
    await p.setInt('notif_snooze_until', _snoozeUntil!.millisecondsSinceEpoch);
    notifyListeners();
    await rescheduleBwReminders();
  }

  Future<void> clearSnooze() async {
    _snoozeUntil = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('notif_snooze_until');
    notifyListeners();
    await rescheduleBwReminders();
  }
}
