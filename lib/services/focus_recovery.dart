import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/habit_library.dart';
import '../providers/app_provider.dart';
import '../providers/progression_provider.dart';

/// Se una sessione Focus finisce mentre l'app è chiusa (o il sistema l'ha
/// terminata) la notifica "Blocco completato" arriva comunque: qui si ricorda
/// la sessione in corso e, alla riapertura, se è davvero scaduta la si
/// riconosce, così i punti e il progresso non vanno persi.
class FocusRecovery {
  static const _endKey = 'focus_pending_end';
  static const _habitKey = 'focus_pending_habit';

  /// Una sessione scaduta da più di così non viene più riconosciuta.
  static const _maxAge = Duration(hours: 12);

  static Future<void> save(String habitId, DateTime endsAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_endKey, endsAt.millisecondsSinceEpoch);
    await prefs.setString(_habitKey, habitId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_endKey);
    await prefs.remove(_habitKey);
  }

  /// Da chiamare all'apertura/ripresa dell'app.
  static Future<void> completeIfFinished(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_endKey);
    final habitId = prefs.getString(_habitKey);
    if (endMs == null || habitId == null) return;
    final endsAt = DateTime.fromMillisecondsSinceEpoch(endMs);
    final now = DateTime.now();
    if (now.isBefore(endsAt))
      return; // ancora in corso: se ne occupa la schermata
    await clear();
    if (now.difference(endsAt) > _maxAge) return;
    if (!context.mounted) return;

    final progression = context.read<ProgressionProvider>();
    final app = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final s = context.sL;
    await progression.markCompleted(habitId);
    await app.completeHabit(habitId);
    final base = HabitLibrary.findById(habitId)?.points ?? 0;
    final pts = app.lastCompletionWasBonus ? base * 3 : base;
    if (pts > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(s.breathingPointsEarned(pts)),
        duration: const Duration(seconds: 3),
      ));
    }
  }
}
