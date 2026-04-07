// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — ProgressionProvider
//  Gestisce lo stato di progressione dell'utente: quali abitudini sono attive,
//  quali sono consolidate, quali sono pronte per essere sbloccate.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_library.dart';

// ── Stato di una singola abitudine ───────────────────────────────────────────
enum HabitStatus {
  locked,       // Non ancora sbloccata
  available,    // Pronta per essere proposta (popup)
  active,       // L'utente l'ha accettata e sta lavorandoci
  sprouting,    // 🌱 1-3 giorni completati
  growing,      // 🌿 4-6 giorni completati
  consolidated, // 🌳 7+ giorni nelle prime 2 settimane
  automatic,    // 💚 completata senza reminder per 7 giorni
}

class HabitState {
  final String habitId;
  HabitStatus status;
  int daysCompleted;       // Giorni cumulativi completati
  int daysWithoutReminder; // Per rilevare "automatica"
  DateTime? unlockedAt;
  DateTime? activatedAt;
  DateTime? lastCompletedAt;
  bool isChoicePending;    // True = in attesa di scelta popup

  HabitState({
    required this.habitId,
    this.status = HabitStatus.locked,
    this.daysCompleted = 0,
    this.daysWithoutReminder = 0,
    this.unlockedAt,
    this.activatedAt,
    this.lastCompletedAt,
    this.isChoicePending = false,
  });

  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'status': status.index,
    'daysCompleted': daysCompleted,
    'daysWithoutReminder': daysWithoutReminder,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'activatedAt': activatedAt?.toIso8601String(),
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    'isChoicePending': isChoicePending,
  };

  factory HabitState.fromJson(Map<String, dynamic> j) => HabitState(
    habitId: j['habitId'] as String,
    status: HabitStatus.values[j['status'] as int],
    daysCompleted: j['daysCompleted'] as int,
    daysWithoutReminder: j['daysWithoutReminder'] as int,
    unlockedAt: j['unlockedAt'] != null
        ? DateTime.parse(j['unlockedAt'] as String) : null,
    activatedAt: j['activatedAt'] != null
        ? DateTime.parse(j['activatedAt'] as String) : null,
    lastCompletedAt: j['lastCompletedAt'] != null
        ? DateTime.parse(j['lastCompletedAt'] as String) : null,
    isChoicePending: j['isChoicePending'] as bool? ?? false,
  );

  // Helper per l'icona di stato
  String get statusEmoji {
    switch (status) {
      case HabitStatus.locked:      return '🔒';
      case HabitStatus.available:   return '✨';
      case HabitStatus.active:      return '🌱';
      case HabitStatus.sprouting:   return '🌱';
      case HabitStatus.growing:     return '🌿';
      case HabitStatus.consolidated:return '🌳';
      case HabitStatus.automatic:   return '💚';
    }
  }
}

// ── Coach Message ─────────────────────────────────────────────────────────────
class CoachMessage {
  final String text;
  final String? habitId; // null = messaggio generale
  final DateTime date;

  const CoachMessage({
    required this.text,
    this.habitId,
    required this.date,
  });
}

// ── ProgressionProvider ───────────────────────────────────────────────────────
class ProgressionProvider extends ChangeNotifier {
  final Map<String, HabitState> _states = {};
  DateTime? _installDate;
  CoachMessage? _todayMessage;
  bool _initialized = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get initialized => _initialized;

  int get appDayNumber {
    if (_installDate == null) return 0;
    return DateTime.now().difference(_installDate!).inDays;
  }

  HabitState? stateOf(String habitId) => _states[habitId];

  HabitStatus statusOf(String habitId) =>
      _states[habitId]?.status ?? HabitStatus.locked;

  int daysCompletedFor(String habitId) =>
      _states[habitId]?.daysCompleted ?? 0;

  CoachMessage? get todayMessage => _todayMessage;

  /// Abitudini attualmente attive (in corso)
  List<HabitDefinition> get activeHabits {
    return HabitLibrary.all.where((h) {
      final s = statusOf(h.id);
      return s == HabitStatus.active ||
          s == HabitStatus.sprouting ||
          s == HabitStatus.growing ||
          s == HabitStatus.consolidated ||
          s == HabitStatus.automatic;
    }).toList();
  }

  /// Abitudini pronte per essere proposte (popup)
  List<HabitDefinition> get availableHabits {
    return HabitLibrary.all
        .where((h) => statusOf(h.id) == HabitStatus.available)
        .toList();
  }

  /// Coppia di scelta pendente (per il popup)
  (HabitDefinition, HabitDefinition)? get pendingChoicePair {
    for (final pair in HabitLibrary.choicePairs) {
      final stateA = _states[pair.$1.id];
      final stateB = _states[pair.$2.id];
      if (stateA?.isChoicePending == true || stateB?.isChoicePending == true) {
        return pair;
      }
    }
    return null;
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Install date
    final installDateStr = prefs.getString('install_date');
    if (installDateStr == null) {
      _installDate = DateTime.now();
      await prefs.setString(
          'install_date', _installDate!.toIso8601String());
    } else {
      _installDate = DateTime.parse(installDateStr);
    }

    // Load states
    final statesJson = prefs.getString('habit_states');
    if (statesJson != null) {
      final map = jsonDecode(statesJson) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _states[entry.key] =
            HabitState.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    // Init starters se non già inizializzati
    for (final habit in HabitLibrary.starters) {
      if (!_states.containsKey(habit.id)) {
        _states[habit.id] = HabitState(
          habitId: habit.id,
          status: HabitStatus.active,
          activatedAt: _installDate,
        );
      }
    }

    // Calcola sblocchi
    _evaluateUnlocks();

    // Genera messaggio coach del giorno
    _generateTodayMessage();

    _initialized = true;
    notifyListeners();
  }

  // ── Completamento giornaliero ─────────────────────────────────────────────

  Future<void> markCompleted(String habitId) async {
    final state = _states[habitId];
    if (state == null) return;

    final now = DateTime.now();
    final lastCompleted = state.lastCompletedAt;

    // Evita doppio completamento nello stesso giorno
    if (lastCompleted != null &&
        lastCompleted.year == now.year &&
        lastCompleted.month == now.month &&
        lastCompleted.day == now.day) {
      return;
    }

    state.daysCompleted++;
    state.lastCompletedAt = now;
    _updateHabitStatus(state);

    await _saveStates();
    _evaluateUnlocks();
    _generateTodayMessage();
    notifyListeners();
  }

  void _updateHabitStatus(HabitState state) {
    if (state.daysCompleted >= 7) {
      state.status = HabitStatus.consolidated;
    } else if (state.daysCompleted >= 4) {
      state.status = HabitStatus.growing;
    } else if (state.daysCompleted >= 1) {
      state.status = HabitStatus.sprouting;
    }
  }

  // ── Accettazione scelta popup ─────────────────────────────────────────────

  Future<void> acceptHabit(String habitId) async {
    if (!_states.containsKey(habitId)) {
      _states[habitId] = HabitState(habitId: habitId);
    }
    final state = _states[habitId]!;
    state.status = HabitStatus.active;
    state.activatedAt = DateTime.now();
    state.isChoicePending = false;

    // Rifiuta l'alternativa della stessa coppia
    for (final pair in HabitLibrary.choicePairs) {
      if (pair.$1.id == habitId) {
        _states[pair.$2.id]?.isChoicePending = false;
        _states[pair.$2.id]?.status = HabitStatus.locked;
      } else if (pair.$2.id == habitId) {
        _states[pair.$1.id]?.isChoicePending = false;
        _states[pair.$1.id]?.status = HabitStatus.locked;
      }
    }

    await _saveStates();
    notifyListeners();
  }

  Future<void> dismissChoice(String habitId) async {
    // L'utente vuole vedere altre opzioni — rimanda di 2 giorni
    _states[habitId]?.isChoicePending = false;
    await _saveStates();
    notifyListeners();
  }

  // ── Valutazione sblocchi ──────────────────────────────────────────────────

  void _evaluateUnlocks() {
    bool changed = false;

    for (final habit in HabitLibrary.all) {
      if (habit.isStarter) continue;
      final currentStatus = statusOf(habit.id);
      if (currentStatus != HabitStatus.locked) continue;

      final unlock = habit.unlock;
      bool conditionMet = false;

      // Controlla prerequisito abitudine
      if (unlock.requiredHabitId != null) {
        final prereqDays = daysCompletedFor(unlock.requiredHabitId!);
        conditionMet = prereqDays >= unlock.requiredDaysCompleted;
      }

      // Controlla giorno app (in alternativa o in aggiunta)
      if (unlock.appDayMin != null) {
        final dayCondition = appDayNumber >= unlock.appDayMin!;
        conditionMet = unlock.requiredHabitId != null
            ? conditionMet && dayCondition
            : dayCondition;
      }

      if (conditionMet) {
        // Controlla se fa parte di una coppia di scelta
        bool isInPair = false;
        for (final pair in HabitLibrary.choicePairs) {
          if (pair.$1.id == habit.id || pair.$2.id == habit.id) {
            isInPair = true;
            // Segna entrambe come "scelta pendente"
            _getOrCreate(pair.$1.id).isChoicePending = true;
            _getOrCreate(pair.$1.id).status = HabitStatus.available;
            _getOrCreate(pair.$2.id).isChoicePending = true;
            _getOrCreate(pair.$2.id).status = HabitStatus.available;
            break;
          }
        }

        if (!isInPair) {
          _getOrCreate(habit.id).status = HabitStatus.available;
          _getOrCreate(habit.id).unlockedAt = DateTime.now();
        }

        changed = true;
      }
    }

    if (changed) _saveStates();
  }

  HabitState _getOrCreate(String habitId) {
    if (!_states.containsKey(habitId)) {
      _states[habitId] = HabitState(habitId: habitId);
    }
    return _states[habitId]!;
  }

  // ── Coach messages ────────────────────────────────────────────────────────

  void _generateTodayMessage() {
    final activeList = activeHabits;
    if (activeList.isEmpty) {
      _todayMessage = CoachMessage(
        text: 'Inizia con un bicchiere d\'acqua. Adesso.',
        date: DateTime.now(),
      );
      return;
    }

    // Trova l'abitudine con meno giorni completati (la più in difficoltà)
    HabitDefinition? focusHabit;
    int minDays = 9999;
    for (final h in activeList) {
      final days = daysCompletedFor(h.id);
      if (days < minDays) {
        minDays = days;
        focusHabit = h;
      }
    }

    if (focusHabit != null) {
      final def = HabitLibrary.findById(focusHabit.id);
      if (def != null) {
        _todayMessage = CoachMessage(
          text: _contextualMessage(def, minDays),
          habitId: def.id,
          date: DateTime.now(),
        );
        return;
      }
    }

    _todayMessage = CoachMessage(
      text: 'Ogni giorno conta. Anche i giorni difficili.',
      date: DateTime.now(),
    );
  }

  String _contextualMessage(HabitDefinition habit, int daysCompleted) {
    if (daysCompleted == 0) return habit.coachIntro;
    if (daysCompleted == 1) return '${habit.name}: primo giorno. Il più importante.';
    if (daysCompleted == 3) return '3 giorni. Il corpo inizia a registrarlo.';
    if (daysCompleted == 7) return '7 giorni consecutivi. Stai costruendo qualcosa.';
    if (daysCompleted == 14) return '2 settimane. Questa abitudine è tua adesso.';
    return habit.coachDaily;
  }

  // ── Persistenza ───────────────────────────────────────────────────────────

  Future<void> _saveStates() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final entry in _states.entries)
        entry.key: entry.value.toJson()
    };
    await prefs.setString('habit_states', jsonEncode(map));
  }

  Future<void> resetAll() async {
    _states.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('habit_states');
    await prefs.remove('install_date');
    _installDate = null;
    notifyListeners();
  }
}

// ── Metodi aggiuntivi per GrowthScreen ───────────────────────────────────────
extension ProgressionProviderUI on ProgressionProvider {

  /// Fase corrente 1-5 basata su totalDaysCompleted
  int get currentPhase {
    final days = totalDaysCompleted;
    if (days >= 90) return 5;
    if (days >= 42) return 4;
    if (days >= 21) return 3;
    if (days >= 7)  return 2;
    return 1;
  }

  /// Totale giorni completati su tutte le abitudini
  int get totalDaysCompleted {
    return _states.values
        .fold(0, (sum, s) => sum + s.daysCompleted);
  }

  /// Progresso verso prossima fase (0.0 - 1.0)
  double get phaseProgress {
    final days = totalDaysCompleted;
    final thresholds = [0, 7, 21, 42, 90];
    final phase = currentPhase;
    if (phase >= 5) return 1.0;
    final from = thresholds[phase - 1];
    final to   = thresholds[phase];
    return ((days - from) / (to - from)).clamp(0.0, 1.0);
  }

  /// Prossima abitudine che si sbloccherà
  HabitDefinition? get nextHabitToUnlock {
    for (final habit in HabitLibrary.all) {
      if (statusOf(habit.id) == HabitStatus.locked) return habit;
    }
    return null;
  }

  /// Giorni mancanti allo sblocco di una specifica abitudine
  int daysUntilUnlock(String habitId) {
    final habit = HabitLibrary.findById(habitId);
    if (habit == null) return 0;
    final unlock = habit.unlock;
    if (unlock.requiredHabitId != null) {
      final done = daysCompletedFor(unlock.requiredHabitId!);
      final needed = unlock.requiredDaysCompleted - done;
      return needed.clamp(0, 999);
    }
    if (unlock.appDayMin != null) {
      return (unlock.appDayMin! - appDayNumber).clamp(0, 999);
    }
    return 0;
  }

  /// Badge guadagnati
  List<BwBadge> get earnedBadges {
    final badges = <BwBadge>[];
    final total = totalDaysCompleted;
    final active = activeHabits;

    if (total >= 1)  badges.add(BwBadge('🌱', 'Primo passo', 'Primo giorno completato'));
    if (total >= 7)  badges.add(BwBadge('💧', 'Una settimana', '7 giorni di abitudini'));
    if (total >= 21) badges.add(BwBadge('🌿', 'Tre settimane', '21 giorni completati'));
    if (total >= 42) badges.add(BwBadge('🌳', 'Un mese e mezzo', '42 giorni completati'));
    if (total >= 90) badges.add(BwBadge('✨', 'Tre mesi', '90 giorni di crescita'));

    if (active.length >= 2) badges.add(BwBadge('🔗', 'In sincronia', '2 abitudini attive'));
    if (active.length >= 4) badges.add(BwBadge('🎯', 'Multihabit', '4 abitudini attive'));

    // Abitudini specifiche consolidate
    if (statusOf('water') == HabitStatus.consolidated ||
        statusOf('water') == HabitStatus.automatic) {
      badges.add(BwBadge('💧', 'Ben idratato', 'Acqua consolidata'));
    }
    if (statusOf('focus_25') == HabitStatus.consolidated ||
        statusOf('focus_25') == HabitStatus.automatic) {
      badges.add(BwBadge('🎯', 'In focus', 'Focus 25 min consolidato'));
    }
    if (statusOf('walk_lunch') == HabitStatus.consolidated ||
        statusOf('walk_lunch') == HabitStatus.automatic) {
      badges.add(BwBadge('🚶', 'Camminatore', 'Passeggiata pranzo consolidata'));
    }
    if (statusOf('breathing_box') == HabitStatus.consolidated ||
        statusOf('breathing_box') == HabitStatus.automatic) {
      badges.add(BwBadge('🧘', 'Respiro', 'Respirazione consolidata'));
    }

    return badges;
  }
}

/// Badge earned dal sistema
class BwBadge {
  final String emoji;
  final String name;
  final String description;
  const BwBadge(this.emoji, this.name, this.description);
}




