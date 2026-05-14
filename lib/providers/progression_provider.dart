// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — ProgressionProvider
//  Gestisce lo stato di progressione dell'utente: quali abitudini sono attive,
//  quali sono consolidate, quali sono pronte per essere sbloccate.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_library.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';

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
  List<String> completionDates; // 'YYYY-MM-DD' — ultimi 70 giorni

  HabitState({
    required this.habitId,
    this.status = HabitStatus.locked,
    this.daysCompleted = 0,
    this.daysWithoutReminder = 0,
    this.unlockedAt,
    this.activatedAt,
    this.lastCompletedAt,
    this.isChoicePending = false,
    List<String>? completionDates,
  }) : completionDates = completionDates ?? [];

  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'status': status.index,
    'daysCompleted': daysCompleted,
    'daysWithoutReminder': daysWithoutReminder,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'activatedAt': activatedAt?.toIso8601String(),
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    'isChoicePending': isChoicePending,
    'completionDates': completionDates,
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
    completionDates: (j['completionDates'] as List<dynamic>?)
        ?.cast<String>() ?? [],
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


// ── ProgressionProvider ───────────────────────────────────────────────────────
class ProgressionProvider extends ChangeNotifier {
  final Map<String, HabitState> _states = {};
  DateTime? _installDate;
  DateTime? _lastUnlockDate;       // Anti-overload: data dell'ultimo sblocco
  DateTime? _slowdownActiveUntil;  // Rallentamento attivo fino a questa data
  DateTime? _lastEvaluateDate;     // Evita valutazioni multiple nello stesso giorno
  int _debugDayOffset = 0;
  bool _initialized = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get initialized => _initialized;
  DateTime? get installDatePublic => _installDate;

  /// True se almeno un'abitudine attiva ha un tasso di completamento < 60%
  /// (calcolato sul totale dei giorni dall'attivazione).
  bool get needsSlowdown {
    final now = DateTime.now();
    for (final h in activeHabits) {
      if (h.id == 'water') continue; // acqua tracciata separatamente
      final state = _states[h.id];
      if (state == null || state.activatedAt == null) continue;
      final daysActive = now.difference(state.activatedAt!).inDays + 1;
      if (daysActive < 7) continue; // troppo presto per giudicare
      final rate = state.daysCompleted / daysActive;
      if (rate < 0.6) return true;
    }
    return false;
  }

  /// True se il rallentamento volontario è ancora attivo.
  bool get isSlowdownActive =>
      _slowdownActiveUntil != null &&
      DateTime.now().isBefore(_slowdownActiveUntil!);

  int get appDayNumber {
    if (_installDate == null) return 0;
    return DateTime.now().difference(_installDate!).inDays + _debugDayOffset;
  }

  bool get isInitialized => _initialized;

  HabitState? stateOf(String habitId) => _states[habitId];

  HabitStatus statusOf(String habitId) =>
      _states[habitId]?.status ?? HabitStatus.locked;

  int daysCompletedFor(String habitId) =>
      _states[habitId]?.daysCompleted ?? 0;

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

  /// Primi due habit con isChoicePending=true (coppia dinamica, senza coppie fisse)
  (HabitDefinition, HabitDefinition)? get pendingChoicePair {
    final pending = HabitLibrary.all
        .where((h) => _states[h.id]?.isChoicePending == true)
        .take(2)
        .toList();
    if (pending.length >= 2) return (pending[0], pending[1]);
    return null;
  }

  /// Lista di coppie pendenti (prese a due a due nell'ordine di HabitLibrary.all)
  List<(HabitDefinition, HabitDefinition)> get pendingChoicePairs {
    final pending = HabitLibrary.all
        .where((h) => _states[h.id]?.isChoicePending == true)
        .toList();
    final result = <(HabitDefinition, HabitDefinition)>[];
    for (int i = 0; i + 1 < pending.length; i += 2) {
      result.add((pending[i], pending[i + 1]));
    }
    return result;
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Debug day offset (persisted for multi-session testing)
    _debugDayOffset = prefs.getInt('debug_day_offset') ?? 0;

    // Install date
    final installDateStr = prefs.getString('install_date');
    if (installDateStr == null) {
      _installDate = DateTime.now();
      await prefs.setString(
          'install_date', _installDate!.toIso8601String());
    } else {
      _installDate = DateTime.parse(installDateStr);
    }

    // Last unlock date (anti-overload)
    final lastUnlockStr = prefs.getString('last_unlock_date');
    if (lastUnlockStr != null) {
      _lastUnlockDate = DateTime.tryParse(lastUnlockStr);
    }

    // Ultima data di valutazione sblocchi (una per giorno)
    final lastEvalStr = prefs.getString('last_evaluate_date');
    if (lastEvalStr != null) {
      _lastEvaluateDate = DateTime.tryParse(lastEvalStr);
    }

    // Slowdown attivo
    final slowdownStr = prefs.getString('slowdown_active_until');
    if (slowdownStr != null) {
      _slowdownActiveUntil = DateTime.tryParse(slowdownStr);
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
    AnalyticsService.instance.logHabitCompleted(habitId, state.daysCompleted, currentPhase);
    // Registra la data per la heatmap (max 70 giorni)
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (!state.completionDates.contains(dateStr)) {
      state.completionDates.add(dateStr);
      if (state.completionDates.length > 70) state.completionDates.removeAt(0);
    }
    _updateHabitStatus(state);

    await _saveStates();
    // NON chiamiamo _evaluateUnlocks() qui: i nuovi sblocchi vengono
    // valutati una volta al giorno (all'apertura/ripresa dell'app).
    notifyListeners();
  }

  /// Valuta sblocchi solo se oggi non è già stato fatto (chiamare dall'UI
  /// su resume o apertura app — non su ogni completamento).
  Future<void> evaluateIfNewDay() async {
    final today = DateTime.now();
    if (_lastEvaluateDate != null &&
        _lastEvaluateDate!.year == today.year &&
        _lastEvaluateDate!.month == today.month &&
        _lastEvaluateDate!.day == today.day) return;
    _lastEvaluateDate = today;
    _evaluateUnlocks();
    await _saveStates();
    notifyListeners();
  }

  void _updateHabitStatus(HabitState state) {
    // Non retrocedere uno stato già avanzato (es. da automatic a consolidated)
    if (state.status == HabitStatus.automatic) return;
    if (state.daysCompleted >= 66) {
      // Lally et al. (2010): 66 giorni = automaticità comportamentale media
      state.status = HabitStatus.automatic;
    } else if (state.daysCompleted >= 7) {
      state.status = HabitStatus.consolidated;
    } else if (state.daysCompleted >= 4) {
      state.status = HabitStatus.growing;
    } else if (state.daysCompleted >= 1) {
      state.status = HabitStatus.sprouting;
    }
  }

  // ── Accettazione scelta popup ─────────────────────────────────────────────

  Future<void> acceptHabit(String habitId) async {
    final state = _getOrCreate(habitId);
    state.status = HabitStatus.active;
    state.activatedAt = DateTime.now();
    state.unlockedAt = DateTime.now();
    state.isChoicePending = false;

    // Registra la scelta con l'alternativa scartata (prima di rimuoverla)
    final alternativeId = _states.entries
        .where((e) => e.key != habitId && e.value.isChoicePending)
        .map((e) => e.key)
        .firstOrNull ?? 'none';
    AnalyticsService.instance.logHabitChoiceMade(habitId, alternativeId);

    // Tutti gli altri habit rimasti "pending" nella stessa sessione tornano a
    // locked: verranno riproposti al prossimo ciclo di valutazione giornaliera.
    for (final entry in _states.entries) {
      if (entry.key != habitId && entry.value.isChoicePending) {
        entry.value.isChoicePending = false;
        entry.value.status = HabitStatus.locked;
      }
    }

    await _saveStates();
    notifyListeners();
  }

  /// Rimanda la scelta: le habit rimangono "available+pending" e
  /// verranno riproposte alla prossima sessione.
  Future<void> dismissChoice() async {
    // Non facciamo nulla: lo stato isChoicePending persiste, il banner
    // in home mostrerà di nuovo la card di scelta alla prossima apertura.
    // Resettiamo _lastEvaluateDate per non bloccare la prossima valutazione.
    _lastEvaluateDate = null;
    await _saveStates();
    notifyListeners();
  }

  // ── Valutazione sblocchi ──────────────────────────────────────────────────

  bool _isActiveStatus(HabitStatus s) =>
      s == HabitStatus.active ||
      s == HabitStatus.sprouting ||
      s == HabitStatus.growing ||
      s == HabitStatus.consolidated ||
      s == HabitStatus.automatic;

  // ── Giorni dall'ultimo sblocco (anti-overload) ───────────────────────────
  int _daysSinceLastUnlock() {
    if (_lastUnlockDate == null) return 999;
    return DateTime.now().difference(_lastUnlockDate!).inDays + _debugDayOffset;
  }

  /// Controlla se le condizioni di sblocco di un habit sono soddisfatte.
  bool _conditionMet(HabitDefinition habit) {
    final unlock = habit.unlock;
    final totalDays = appDayNumber;
    bool conditionMet = false;

    if (unlock.requiredTotalDays != null) {
      conditionMet = totalDays >= unlock.requiredTotalDays!;
      if (!conditionMet) return false;
    }

    if (unlock.requiredHabitId != null) {
      final prereqDays = daysCompletedFor(unlock.requiredHabitId!);
      final habitCond = prereqDays >= unlock.requiredDaysCompleted;
      final altCond = unlock.altRequiredHabitId != null
          ? daysCompletedFor(unlock.altRequiredHabitId!) >= unlock.requiredDaysCompleted
          : false;
      final prereqMet = habitCond || altCond;
      conditionMet = unlock.requiredTotalDays != null
          ? conditionMet && prereqMet
          : prereqMet;
    }

    if (unlock.appDayMin != null) {
      final dayCondition = appDayNumber >= unlock.appDayMin!;
      conditionMet = unlock.requiredHabitId != null
          ? conditionMet && dayCondition
          : dayCondition;
    }

    return conditionMet;
  }

  /// Valutazione dinamica: niente coppie fisse.
  /// Trova tutti gli habit bloccati con condizione soddisfatta, prende i
  /// PRIMI DUE dall'ordine di HabitLibrary.all e li propone come scelta.
  /// Se è rimasto solo un habit pronto, si auto-accetta.
  void _evaluateUnlocks() {
    // SLOWDOWN VOLONTARIO
    if (isSlowdownActive) return;

    // Se ci sono già habit pending non aggiungerne altri
    final hasPending = _states.values.any((s) => s.isChoicePending);
    if (hasPending) return;

    // Raccogli tutti gli habit pronti (locked + condizione soddisfatta)
    final readyToUnlock = <HabitDefinition>[];
    for (final habit in HabitLibrary.all) {
      if (habit.isStarter) continue;
      if (statusOf(habit.id) != HabitStatus.locked) continue;
      if (_conditionMet(habit)) readyToUnlock.add(habit);
    }

    if (readyToUnlock.isEmpty) return;

    // ANTI-OVERLOAD: min 7 giorni dall'ultimo sblocco EFFETTIVO
    // (non blocca la valutazione quando è la prima volta)
    if (_lastUnlockDate != null && _daysSinceLastUnlock() < 7) return;

    if (readyToUnlock.length == 1) {
      // Un solo habit pronto → auto-accept (nessuna scelta da fare)
      final habit = readyToUnlock.first;
      final st = _getOrCreate(habit.id);
      st.status = HabitStatus.active;
      st.activatedAt = DateTime.now();
      st.unlockedAt = DateTime.now();
      AnalyticsService.instance.logHabitUnlocked(habit.id);
      // Notifica fuori app (solo se in background — gestito dal service)
      NotificationService.instance.showHabitUnlocked(
        habitId: habit.id,
        habitName: habit.name,
        message: habit.coachIntro,
      );
    } else {
      // Due o più pronti → popup di scelta con i PRIMI DUE
      final toShow = readyToUnlock.take(2).toList();
      for (final habit in toShow) {
        _getOrCreate(habit.id)
          ..isChoicePending = true
          ..status = HabitStatus.available;
        AnalyticsService.instance.logHabitUnlocked(habit.id);
      }
      NotificationService.instance.showNotification(
        id: 99998,
        title: '✨ Nuova abitudine disponibile',
        body: 'Apri Be Well per scegliere la tua prossima abitudine.',
      );
    }

    _lastUnlockDate = DateTime.now();
  }

  HabitState _getOrCreate(String habitId) {
    if (!_states.containsKey(habitId)) {
      _states[habitId] = HabitState(habitId: habitId);
    }
    return _states[habitId]!;
  }

  // ── Persistenza ───────────────────────────────────────────────────────────

  Future<void> _saveStates() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final entry in _states.entries)
        entry.key: entry.value.toJson()
    };
    await prefs.setString('habit_states', jsonEncode(map));
    await prefs.setInt('debug_day_offset', _debugDayOffset);
    if (_lastUnlockDate != null) {
      await prefs.setString('last_unlock_date', _lastUnlockDate!.toIso8601String());
    }
    if (_lastEvaluateDate != null) {
      await prefs.setString('last_evaluate_date', _lastEvaluateDate!.toIso8601String());
    } else {
      await prefs.remove('last_evaluate_date');
    }
    if (_slowdownActiveUntil != null) {
      await prefs.setString('slowdown_active_until', _slowdownActiveUntil!.toIso8601String());
    }
  }

  /// Applica il rallentamento: blocca nuovi sblocchi per 14 giorni.
  Future<void> applySlowdown() async {
    _slowdownActiveUntil = DateTime.now().add(const Duration(days: 14));
    await _saveStates();
    notifyListeners();
  }


  // -- Debug methods --------------------------------------------------------
  Future<void> debugSimulateDays(int days) async {
    _debugDayOffset += days;
    _lastEvaluateDate = null; // forza ri-valutazione sblocchi

    // Usa ieri come lastCompletedAt: il giorno simulato è "passato",
    // non "oggi" — così il check isWaterDoneToday non scatta
    final yesterday = DateTime.now().subtract(const Duration(hours: 36));
    for (final state in _states.values) {
      if (state.status != HabitStatus.locked) {
        state.daysCompleted += days;
        state.lastCompletedAt = yesterday;
        _updateHabitStatus(state);
      }
    }

    // Reset tracker acqua del giorno corrente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_count', 0);
    await prefs.remove('water_date');

    await _saveStates();
    _evaluateUnlocks();
    notifyListeners();
  }

  /// Resetta solo i completamenti di oggi — utile per ri-testare il flusso
  /// giornaliero senza perdere la progressione accumulata.
  Future<void> debugResetToday() async {
    final now = DateTime.now();
    for (final state in _states.values) {
      final last = state.lastCompletedAt;
      if (last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        state.lastCompletedAt = last.subtract(const Duration(days: 1));
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_count', 0);
    await prefs.remove('water_date');
    await _saveStates();
    notifyListeners();
  }

  Future<void> debugUnlockAll() async {
    for (final habit in HabitLibrary.all) {
      if (!_states.containsKey(habit.id)) {
        _states[habit.id] = HabitState(habitId: habit.id);
      }
      _states[habit.id]!.status = HabitStatus.active;
      _states[habit.id]!.daysCompleted = 5;
      _states[habit.id]!.activatedAt = DateTime.now();
    }
    _debugDayOffset = 30;
    await _saveStates();
    notifyListeners();
  }
  Future<void> forceEvaluate() async {
    _evaluateUnlocks();
    await _saveStates();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _states.clear();
    _debugDayOffset = 0;
    _installDate = null;
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('habit_states');
    await prefs.remove('install_date');
    await prefs.remove('debug_day_offset');
    notifyListeners();
  }
}

// ── Metodi aggiuntivi per GrowthScreen ───────────────────────────────────────
extension ProgressionProviderUI on ProgressionProvider {

  /// Numero di abitudini consolidate (≥7 giorni completati) o automatiche.
  /// È il metro principale per le fasi di crescita del companion.
  int get consolidatedHabitsCount => _states.values.where((s) =>
      s.status == HabitStatus.consolidated ||
      s.status == HabitStatus.automatic).length;

  /// Fase corrente 1-5 basata sulle abitudini assimilate (consolidate/automatiche).
  ///   Fase 2 →  1 abitudine assimilata  (la prima routine è nata)
  ///   Fase 3 →  3 abitudini assimilate  (routine solida multi-habit)
  ///   Fase 4 →  7 abitudini assimilate  (stile di vita ben radicato)
  ///   Fase 5 → 12 abitudini assimilate  (maestria)
  int get currentPhase {
    final n = consolidatedHabitsCount;
    if (n >= 12) return 5;
    if (n >=  7) return 4;
    if (n >=  3) return 3;
    if (n >=  1) return 2;
    return 1;
  }

  /// Completamenti cumulativi dell'abitudine più praticata.
  /// Usato per badge e display dei giorni — basato esclusivamente su completamenti reali.
  int get totalDaysCompleted {
    int maxDays = 0;
    for (final state in _states.values) {
      if (state.daysCompleted > maxDays) maxDays = state.daysCompleted;
    }
    return maxDays;
  }

  /// Progresso verso prossima fase (0.0 - 1.0) — basato su abitudini assimilate.
  double get phaseProgress {
    const thresholds = [0, 1, 3, 7, 12];
    final phase = currentPhase;
    if (phase >= 5) return 1.0;
    final n    = consolidatedHabitsCount;
    final from = thresholds[phase - 1];
    final to   = thresholds[phase];
    return ((n - from) / (to - from)).clamp(0.0, 1.0);
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

  /// Badge guadagnati (localizzati)
  List<BwBadge> earnedBadges(BwStrings s) {
    final badges = <BwBadge>[];
    final total = totalDaysCompleted;
    final active = activeHabits;

    if (total >= 1)  badges.add(BwBadge('🌱', s.badgeFirstStep, s.badgeFirstStepDesc));
    if (total >= 7)  badges.add(BwBadge('💧', s.badgeOneWeek, s.badgeOneWeekDesc));
    if (total >= 21) badges.add(BwBadge('🌿', s.badgeThreeWeeks, s.badgeThreeWeeksDesc));
    if (total >= 42) badges.add(BwBadge('🌳', s.badgeSixWeeks, s.badgeSixWeeksDesc));
    if (total >= 90) badges.add(BwBadge('✨', s.badgeThreeMonths, s.badgeThreeMonthsDesc));

    if (active.length >= 2) badges.add(BwBadge('🔗', s.badgeInSync, s.badgeInSyncDesc));
    if (active.length >= 4) badges.add(BwBadge('🎯', s.badgeMultihabit, s.badgeMultihabitDesc));

    if (statusOf('water') == HabitStatus.consolidated ||
        statusOf('water') == HabitStatus.automatic) {
      badges.add(BwBadge('💧', s.badgeHydrated, s.badgeHydratedDesc));
    }
    if (statusOf('focus_25') == HabitStatus.consolidated ||
        statusOf('focus_25') == HabitStatus.automatic) {
      badges.add(BwBadge('🎯', s.badgeFocused, s.badgeFocusedDesc));
    }
    if (statusOf('walk_lunch') == HabitStatus.consolidated ||
        statusOf('walk_lunch') == HabitStatus.automatic) {
      badges.add(BwBadge('🚶', s.badgeWalker, s.badgeWalkerDesc));
    }
    if (statusOf('breathing_box') == HabitStatus.consolidated ||
        statusOf('breathing_box') == HabitStatus.automatic) {
      badges.add(BwBadge('🧘', s.badgeBreath, s.badgeBreathDesc));
    }

    return badges;
  }

  /// Heatmap: per ogni giorno degli ultimi 35 giorni → numero di habit completate.
  /// [filterHabitId]: se non null, conta solo quella specifica abitudine (0 o 1).
  /// Ritorna una lista di 35 valori (dal più vecchio al più recente).
  /// Fallback: se completionDates è vuoto, usa lastCompletedAt per il giorno più recente.
  List<int> heatmapData({String? filterHabitId}) {
    final today = DateTime.now();
    final data = <int>[];
    for (int i = 34; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (filterHabitId != null) {
        final state = _states[filterHabitId];
        data.add(_habitCompletedOn(state, dateStr) ? 1 : 0);
      } else {
        int count = 0;
        for (final state in _states.values) {
          if (_habitCompletedOn(state, dateStr)) count++;
        }
        data.add(count);
      }
    }
    return data;
  }

  /// Controlla se un'abitudine è stata completata in un dato giorno.
  /// Prima controlla completionDates, poi cade su lastCompletedAt come fallback.
  bool _habitCompletedOn(HabitState? state, String dateStr) {
    if (state == null) return false;
    if (state.completionDates.contains(dateStr)) return true;
    // Fallback: usa lastCompletedAt per dati migrati senza completionDates
    final last = state.lastCompletedAt;
    if (last == null) return false;
    final lastStr = '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';
    return lastStr == dateStr;
  }

  /// Data di raggiungimento di una fase (approssimata dall'installDate + threshold)
  DateTime? phaseReachedDate(int phase) {
    final install = installDate;
    if (install == null) return null;
    const thresholds = [0, 7, 21, 42, 90];
    if (phase < 1 || phase > 5) return null;
    final daysNeeded = thresholds[phase - 1];
    final reached = install.add(Duration(days: daysNeeded));
    // Solo se è già passata
    return reached.isBefore(DateTime.now()) ? reached : null;
  }

  DateTime? get installDate => installDatePublic;

  String getLocalizedMessage(BwStrings s) {
    final activeList = activeHabits;
    if (activeList.isEmpty) return s.waterZero;
    // Trova l'abitudine con meno giorni completati (quella che ha più bisogno di rinforzo)
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
        // Tutti i messaggi usano BwStrings — localizzati nelle 5 lingue.
        // coachIntro/coachDaily sono solo in italiano e non vanno mai mostrati direttamente.
        if (minDays == 0) {
          if (def.id == 'water') return s.firstHabitBody2;
          return s.habitDesc(def.id); // Primo giorno: descrizione abitudine localizzata
        }
        if (minDays == 1)  return s.coachDay1;
        if (minDays == 3)  return s.coachDay3;
        if (minDays == 7)  return s.coachDay7;
        if (minDays == 14) return s.coachDay14;
        return s.habitDesc(def.id); // Default: descrizione localizzata
      }
    }
    return s.coachGeneral;
  }

}

/// Badge earned dal sistema

class BwBadge {
  final String emoji;
  final String name;
  final String description;
  const BwBadge(this.emoji, this.name, this.description);
}



















