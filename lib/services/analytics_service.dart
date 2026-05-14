// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — AnalyticsService
//  Singleton wrapper attorno a FirebaseAnalytics.
//  Tutti i metodi sono fire-and-forget: nessun await richiesto dal chiamante.
//  In caso di errore (Firebase non inizializzato, debug build) stampa solo
//  un debugPrint senza propagare eccezioni.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Invia un evento custom, ignorando silenziosamente gli errori.
  void _log(String name, [Map<String, Object>? parameters]) {
    _fa.logEvent(name: name, parameters: parameters).catchError((Object e) {
      debugPrint('AnalyticsService: error in "$name": $e');
    });
  }

  // ── Onboarding ───────────────────────────────────────────────────────────────

  /// Utente ha completato il flusso di benvenuto.
  void logOnboardingCompleted(String userType) =>
      _log('onboarding_completed', {'user_type': userType});

  /// Utente ha scelto il nome del companion.
  void logWellyNamed(String name) =>
      _log('welly_named', {
        'name': name.trim().isEmpty ? 'welly' : name.trim().toLowerCase(),
      });

  // ── Acqua ────────────────────────────────────────────────────────────────────

  /// Utente ha segnato un bicchiere d'acqua.
  void logWaterAdded(int count, int target) =>
      _log('water_glass_added', {'count': count, 'target': target});

  /// Utente ha raggiunto il target giornaliero d'acqua.
  void logWaterGoalReached() => _log('water_goal_reached');

  /// Utente ha modificato le impostazioni del contenitore.
  void logWaterContainerChanged(String type, int ml) =>
      _log('water_container_changed', {'type': type, 'ml': ml});

  // ── Abitudini ────────────────────────────────────────────────────────────────

  /// Utente ha completato un'abitudine per [dayOfHabit]-esima volta.
  void logHabitCompleted(String habitId, int dayOfHabit, int phase) =>
      _log('habit_completed', {
        'habit_id': habitId,
        'day_of_habit': dayOfHabit,
        'phase': phase,
      });

  /// Un'abitudine è diventata disponibile (auto-unlock o popup scelta).
  void logHabitUnlocked(String habitId) =>
      _log('habit_unlocked', {'habit_id': habitId});

  /// Utente ha scelto [chosenId] scartando [alternativeId] nel popup coppia.
  void logHabitChoiceMade(String chosenId, String alternativeId) =>
      _log('habit_choice_made', {
        'chosen_id': chosenId,
        'alternative_id': alternativeId,
      });

  /// Utente ha richiesto il rallentamento su [habitId].
  void logSlowdownRequested(String habitId) =>
      _log('slowdown_requested', {'habit_id': habitId});

  // ── Focus ────────────────────────────────────────────────────────────────────

  /// Timer focus avviato (solo al primo start, non al resume).
  void logFocusSessionStarted(int durationMinutes) =>
      _log('focus_session_started', {'duration_minutes': durationMinutes});

  /// Timer focus completato naturalmente (countdown a 0).
  void logFocusSessionCompleted(int durationMinutes) =>
      _log('focus_session_completed', {'duration_minutes': durationMinutes});

  // ── Navigazione ──────────────────────────────────────────────────────────────

  /// Utente ha aperto un tab della bottom nav.
  void logTabOpened(String tabName) =>
      _log('tab_opened', {'tab_name': tabName});

  /// Utente ha aperto la schermata Growth.
  void logGrowthScreenOpened(int totalDays, int phase) =>
      _log('growth_screen_opened', {'total_days': totalDays, 'phase': phase});

  // ── Reward ───────────────────────────────────────────────────────────────────

  /// Utente ha riscattato un premio.
  void logRewardRedeemed(String rewardId, int pointsSpent) =>
      _log('reward_redeemed', {
        'reward_id': rewardId,
        'points_spent': pointsSpent,
      });

  // ── Retention ────────────────────────────────────────────────────────────────

  /// Streak corrente dopo un completamento.
  void logDayStreak(int streakDays) =>
      _log('day_streak', {'streak_days': streakDays});

  /// Utente è tornato dopo [daysAbsent] giorni di inattività (≥ 3).
  void logReturnAfterAbsence(int daysAbsent) =>
      _log('return_after_absence', {'days_absent': daysAbsent});

  // ── Welly ────────────────────────────────────────────────────────────────────

  /// Companion ha mostrato un determinato mood (drinking, radiant, ecc.).
  void logWellyMoodShown(String mood) =>
      _log('welly_mood_shown', {'mood': mood});
}
