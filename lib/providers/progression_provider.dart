// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — ProgressionProvider
//  Gestisce lo stato di progressione dell'utente: quali abitudini sono attive,
//  quali sono consolidate, quali sono pronte per essere sbloccate.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_library.dart';
import '../models/questionnaire_answers.dart';
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
  consolidated, // 🌳 7-65 giorni completati
  automatic,    // 💚 66+ giorni completati (Lally et al., 2010)
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
  /// Se impostato e nel futuro, questa proposta non va ripresentata prima
  /// di allora — l'utente ha risposto "non sono pronto".
  DateTime? notReadySnoozeUntil;

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
    this.notReadySnoozeUntil,
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
    'notReadySnoozeUntil': notReadySnoozeUntil?.toIso8601String(),
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
    notReadySnoozeUntil: j['notReadySnoozeUntil'] != null
        ? DateTime.parse(j['notReadySnoozeUntil'] as String) : null,
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

  /// Coda di abitudini appena diventate "consolidate" (assimilate) in questa
  /// sessione, in attesa che la UI mostri la celebrazione a schermo intero.
  /// Consumata una alla volta con [consumeNextConsolidation].
  final List<String> _pendingCelebrations = [];
  String? get nextConsolidationToCelebrate =>
      _pendingCelebrations.isEmpty ? null : _pendingCelebrations.first;
  void consumeNextConsolidation() {
    if (_pendingCelebrations.isNotEmpty) _pendingCelebrations.removeAt(0);
  }

  // ── Getters ────────────────────────────────────────────────────────────────

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
    final now = DateTime.now();
    return HabitLibrary.all.where((h) {
      final s = statusOf(h.id);
      final isActiveStatus = s == HabitStatus.active ||
          s == HabitStatus.sprouting ||
          s == HabitStatus.growing ||
          s == HabitStatus.consolidated ||
          s == HabitStatus.automatic;
      if (!isActiveStatus) return false;
      // Accettata ma non ancora "iniziata" (parte da domani, vedi
      // acceptHabit) — non compare tra le abitudini di oggi fino ad allora.
      final startsAt = _states[h.id]?.activatedAt;
      if (startsAt != null && startsAt.isAfter(now)) return false;
      return true;
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
    await _evaluateUnlocks();

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
    final wasConsolidated = state.status == HabitStatus.consolidated ||
        state.status == HabitStatus.automatic;
    _updateHabitStatus(state);
    final justConsolidated = !wasConsolidated &&
        (state.status == HabitStatus.consolidated || state.status == HabitStatus.automatic);

    if (justConsolidated) {
      // Abitudine assimilata proprio ora: la UI mostra una celebrazione a
      // schermo intero prima di proporre, se pronta, la prossima abitudine —
      // il progresso deve sentirsi guadagnato, non un batch notturno silenzioso.
      _pendingCelebrations.add(habitId);
      await _evaluateUnlocks();
    }

    await _saveStates();
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
    await _evaluateUnlocks();
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
    // Parte da domani, non da subito: oggi l'utente ha appena festeggiato un
    // traguardo, non deve sentirsi mettere davanti un altro impegno nello
    // stesso istante. activeHabits esclude le abitudini con activatedAt
    // futuro, quindi non compare tra quelle "di oggi" fino a domani.
    final now = DateTime.now();
    state.activatedAt = DateTime(now.year, now.month, now.day + 1);
    state.unlockedAt = now;
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

  /// L'utente ha risposto "non sono pronto" alla proposta corrente: le
  /// abitudini in scelta tornano bloccate e non vengono riproposte prima di
  /// 7 giorni, invece di restare "pending" per sempre bloccando anche la
  /// valutazione di qualsiasi altra abitudine (vecchio comportamento).
  Future<void> declineChoice() async {
    final snoozeUntil = DateTime.now().add(const Duration(days: 7));
    for (final entry in _states.entries) {
      if (entry.value.isChoicePending) {
        entry.value.isChoicePending = false;
        entry.value.status = HabitStatus.locked;
        entry.value.notReadySnoozeUntil = snoozeUntil;
      }
    }
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

  /// Carica le risposte del configuratore facoltativo (se compilato) e le
  /// converte nel formato (questionId → valori) usato dalle IfThenRule del
  /// catalogo abitudini. Le chiavi 'Qn' sono quelle del catalogo originale
  /// (non i numeri mostrati oggi nel questionario — vedi il commento in
  /// questionnaire_answers.dart); le chiavi testuali (EXERCISE_FREQ,
  /// SCREEN_TIME, SCHEDULE_TYPE, MEETING_LOAD) sono nuove, aggiunte insieme
  /// alle rispettive IfThenRule in habit_library.dart. Q19 nel catalogo si
  /// aspetta una FONTE di distrazione (telefono/social) che il questionario
  /// non chiede più — resta volutamente non mappata piuttosto che inventare
  /// una corrispondenza approssimativa che darebbe suggerimenti sbagliati.
  Future<Map<String, Set<String>>> _loadIfThenAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('questionnaire_answers');
    if (raw == null) return {};

    final QuestionnaireAnswers a;
    try {
      a = QuestionnaireAnswers.fromJson(json.decode(raw));
    } catch (_) {
      return {};
    }

    final map = <String, Set<String>>{};
    void add(String q, String v) => map.putIfAbsent(q, () => {}).add(v);

    if (a.workLocation == 'office') add('Q2', 'Office/University');
    if (a.workLocation == 'home') add('Q2', 'From home');

    if (a.goals.contains('stress')) add('Q3', 'Reduce stress');
    if (a.goals.contains('health')) add('Q3', 'Develop healthy habits');

    if (a.stressLevel == 4) add('Q4', '4 – High');
    if (a.stressLevel == 5) add('Q4', '5 – Very high');

    if (a.lunchDuration == '30m') add('Q9', '30 minutes');
    if (a.lunchDuration == '60m+') add('Q9', '1 hour');

    add('Q11', a.hasParkAccess ? 'Yes – <5 min' : 'No');
    add('Q14', a.hasQuietSpace ? 'Yes – at work' : 'No');

    add('Q15', a.sleepHours);
    add('Q16', a.hydrationLiters == '2L+' ? '>2L' : a.hydrationLiters);

    // focusDuration → stessi bucket "15-25 min"/"45-60 min" già usati da
    // focus_25 (bucket exact match per 15-25m, approssimazione ragionevole
    // 45m+ ≈ "45-60 min").
    if (a.focusDuration == '15-25m') add('Q21', '15-25 min');
    if (a.focusDuration == '45m+') add('Q21', '45-60 min');

    if (a.exerciseFreq == 'never') add('EXERCISE_FREQ', 'never');
    if (a.screenTimeHours >= 6) add('SCREEN_TIME', 'high');
    if (a.scheduleType == 'irregular') add('SCHEDULE_TYPE', 'irregular');
    if (a.scheduleType == 'shift') add('SCHEDULE_TYPE', 'shift');
    if (a.meetingLoad == '6+/day') add('MEETING_LOAD', '6+/day');

    return map;
  }

  bool _ruleMatches(IfThenRule r, Map<String, Set<String>> answers) =>
      answers[r.questionId]?.contains(r.answerValue) ?? false;

  bool _hasEffect(HabitDefinition h, Map<String, Set<String>> answers, String effect) =>
      h.ifThenRules.any((r) => r.effect == effect && _ruleMatches(r, answers));

  /// Valutazione dinamica: niente coppie fisse.
  /// Trova tutti gli habit bloccati con condizione soddisfatta, prende i
  /// PRIMI DUE dall'ordine di HabitLibrary.all e li propone come scelta —
  /// ma se l'utente ha compilato il configuratore facoltativo, le sue
  /// risposte influenzano davvero quali abitudini vengono proposte:
  /// nascoste (hide_habit), sbloccate in anticipo
  /// (unlock_immediately_skip_prerequisite) o messe in cima alla scelta
  /// quando ce n'è più di una pronta.
  /// Se è rimasto solo un habit pronto, si auto-accetta.
  Future<void> _evaluateUnlocks() async {
    // SLOWDOWN VOLONTARIO
    if (isSlowdownActive) return;

    // Se ci sono già habit pending non aggiungerne altri
    final hasPending = _states.values.any((s) => s.isChoicePending);
    if (hasPending) return;

    final answers = await _loadIfThenAnswers();

    // Raccogli tutti gli habit pronti (locked + condizione soddisfatta,
    // oppure condizione bypassata da una risposta esplicita), esclusi
    // quelli che le risposte marcano come non rilevanti per l'utente.
    final now = DateTime.now();
    final readyToUnlock = <HabitDefinition>[];
    for (final habit in HabitLibrary.all) {
      if (habit.isStarter) continue;
      if (statusOf(habit.id) != HabitStatus.locked) continue;
      if (_hasEffect(habit, answers, 'hide_habit')) continue;
      // "Non sono pronto" risposto di recente: non riproporla prima del
      // termine della pausa di 7 giorni.
      final snoozeUntil = _states[habit.id]?.notReadySnoozeUntil;
      if (snoozeUntil != null && now.isBefore(snoozeUntil)) continue;
      final conditionMet = _conditionMet(habit) ||
          _hasEffect(habit, answers, 'unlock_immediately_skip_prerequisite');
      if (conditionMet) readyToUnlock.add(habit);
    }

    if (readyToUnlock.isEmpty) return;

    // Tra i pronti, chi ha una risposta che lo rende esplicitamente
    // rilevante per l'utente passa avanti (List.sort non è stabile in Dart,
    // quindi partizioniamo a mano per preservare l'ordine del catalogo
    // all'interno di ciascun gruppo).
    bool isRelevant(HabitDefinition h) =>
        h.ifThenRules.any((r) => r.effect != 'hide_habit' && _ruleMatches(r, answers));
    final relevant = readyToUnlock.where(isRelevant).toList();
    final rest = readyToUnlock.where((h) => !isRelevant(h)).toList();
    readyToUnlock
      ..clear()
      ..addAll(relevant)
      ..addAll(rest);

    // ANTI-OVERLOAD: min 7 giorni dall'ultimo sblocco EFFETTIVO
    // (non blocca la valutazione quando è la prima volta)
    if (_lastUnlockDate != null && _daysSinceLastUnlock() < 7) return;

    if (readyToUnlock.length == 1) {
      // Un solo habit pronto → auto-accept (nessuna scelta da fare), ma
      // parte comunque da domani come le scelte esplicite (acceptHabit) —
      // stessa "consecutio": oggi il traguardo appena celebrato, da domani
      // il nuovo impegno.
      final habit = readyToUnlock.first;
      final st = _getOrCreate(habit.id);
      final now = DateTime.now();
      st.status = HabitStatus.active;
      st.activatedAt = DateTime(now.year, now.month, now.day + 1);
      st.unlockedAt = now;
      AnalyticsService.instance.logHabitUnlocked(habit.id);
      // Notifica fuori app (solo se in background — gestito dal service).
      // Nome e messaggio localizzati nella lingua corrente dell'utente:
      // habit.name/coachIntro sono solo i testi grezzi italiani del catalogo.
      currentBwStrings().then((s) => NotificationService.instance.showHabitUnlocked(
            habitId: habit.id,
            habitName: s.habitName(habit.id),
            message: s.habitStartsTomorrow(s.habitName(habit.id)),
          ));
    } else {
      // Due o più pronti → popup di scelta con i PRIMI DUE
      final toShow = readyToUnlock.take(2).toList();
      for (final habit in toShow) {
        _getOrCreate(habit.id)
          ..isChoicePending = true
          ..status = HabitStatus.available;
        AnalyticsService.instance.logHabitUnlocked(habit.id);
      }
      currentBwStrings().then((s) => NotificationService.instance.showNotification(
            id: 99998,
            title: s.notifHabitChoiceTitle,
            body: s.notifHabitChoiceBody,
          ));
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
    await _evaluateUnlocks();
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
      final state = _states[habit.id]!;
      state.status = HabitStatus.active;
      state.activatedAt = DateTime.now();
      // 30 giorni completati, come dichiara il pulsante — e passa da
      // _updateHabitStatus invece di forzare "active" a mano, altrimenti
      // lo stato risultante (daysCompleted=30 ma status=active) è uno che
      // il percorso normale non produrrebbe mai: consolidatedHabitsCount,
      // currentPhase e i badge in Growth restavano a zero nonostante il
      // pulsante dicesse "tutto sbloccato".
      state.daysCompleted = 30;
      _updateHabitStatus(state);
    }
    _debugDayOffset = 30;
    await _saveStates();
    notifyListeners();
  }
  Future<void> forceEvaluate() async {
    await _evaluateUnlocks();
    await _saveStates();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _states.clear();
    _debugDayOffset = 0;
    _installDate = null;
    _initialized = false;
    // Anche questi tre — non azzerarli lasciava, es., un rallentamento
    // volontario attivo da una sessione precedente sopravvivere a un
    // "reset come nuovo utente", bloccando in silenzio ogni sblocco sul
    // profilo appena azzerato.
    _lastUnlockDate = null;
    _lastEvaluateDate = null;
    _slowdownActiveUntil = null;
    _pendingCelebrations.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('habit_states');
    await prefs.remove('install_date');
    await prefs.remove('debug_day_offset');
    await prefs.remove('last_unlock_date');
    await prefs.remove('last_evaluate_date');
    await prefs.remove('slowdown_active_until');
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

  /// Giorni mancanti allo sblocco di una specifica abitudine.
  /// Un'abitudine può avere più condizioni contemporaneamente — vedi
  /// [_conditionMet], che le combina in AND — quindi il tempo mancante
  /// reale è quello della condizione più lenta a soddisfarsi, non solo
  /// la prima trovata (in precedenza `requiredTotalDays` non era gestito
  /// affatto, e per le abitudini gated solo da quello tornava sempre 0
  /// anche a settimane di distanza dallo sblocco reale).
  int daysUntilUnlock(String habitId) {
    final habit = HabitLibrary.findById(habitId);
    if (habit == null) return 0;
    final unlock = habit.unlock;
    final remaining = <int>[];

    if (unlock.requiredTotalDays != null) {
      remaining.add((unlock.requiredTotalDays! - appDayNumber).clamp(0, 999));
    }
    if (unlock.requiredHabitId != null) {
      // altRequiredHabitId è un OR in _conditionMet: basta il più vicino dei due.
      final mainRemaining =
          (unlock.requiredDaysCompleted - daysCompletedFor(unlock.requiredHabitId!))
              .clamp(0, 999);
      final altRemaining = unlock.altRequiredHabitId != null
          ? (unlock.requiredDaysCompleted - daysCompletedFor(unlock.altRequiredHabitId!))
              .clamp(0, 999)
          : mainRemaining;
      remaining.add(mainRemaining < altRemaining ? mainRemaining : altRemaining);
    }
    if (unlock.appDayMin != null) {
      remaining.add((unlock.appDayMin! - appDayNumber).clamp(0, 999));
    }

    if (remaining.isEmpty) return 0;
    return remaining.reduce((a, b) => a > b ? a : b);
  }

  /// Tutti i badge (guadagnati + prossimo obiettivo da sbloccare per ogni
  /// famiglia a livelli) — sempre la stessa lista di tile, alcune piene,
  /// altre col traguardo successivo mostrato esplicitamente.
  List<BadgeInfo> allBadges(BwStrings s) {
    final total = totalDaysCompleted;
    final activeCount = activeHabits.length;
    final rooted = consolidatedHabitsCount;

    return [
      // ── Costanza: bronzo 7g / argento 21g / oro 42g ────────────────────
      _tierBadge(key: 'consistency', progress: total, tiers: [
        (7,  '🥉', s.badgeOneWeek,    s.badgeOneWeekDesc),
        (21, '🥈', s.badgeThreeWeeks, s.badgeThreeWeeksDesc),
        (42, '🥇', s.badgeSixWeeks,   s.badgeSixWeeksDesc),
      ]),
      // ── Abitudini attive in parallelo: bronzo 2 / oro 4 ────────────────
      _tierBadge(key: 'activeHabits', progress: activeCount, tiers: [
        (2, '🥉', s.badgeInSync,     s.badgeInSyncDesc),
        (4, '🥇', s.badgeMultihabit, s.badgeMultihabitDesc),
      ]),
      // ── Abitudini radicate (soglie di fase 2/3/4): bronzo 1 / argento 3 / oro 7
      _tierBadge(key: 'rooted', progress: rooted, tiers: [
        (1, '🥉', '${s.badgeRootedName} · ${s.badgeTierBronze}', s.badgeRootedDesc),
        (3, '🥈', '${s.badgeRootedName} · ${s.badgeTierSilver}', s.badgeRootedDesc),
        (7, '🥇', '${s.badgeRootedName} · ${s.badgeTierGold}',   s.badgeRootedDesc),
      ]),
      // ── Traguardi unici ─────────────────────────────────────────────────
      BadgeInfo(key: 'firstStep', emoji: '🌱', name: s.badgeFirstStep, description: s.badgeFirstStepDesc,
          earned: total >= 1, progress: total.clamp(0, 1), target: 1),
      BadgeInfo(key: 'veteran', emoji: '✨', name: s.badgeThreeMonths, description: s.badgeThreeMonthsDesc,
          earned: total >= 90, progress: total.clamp(0, 90), target: 90),
      // ── Specialità per abitudine ─────────────────────────────────────────
      _specialtyBadge('hydrated', '💧', s.badgeHydrated, s.badgeHydratedDesc, statusOf('water')),
      _specialtyBadge('focused', '🎯', s.badgeFocused, s.badgeFocusedDesc, statusOf('focus_25')),
      _specialtyBadge('walker', '🚶', s.badgeWalker, s.badgeWalkerDesc, statusOf('walk_lunch')),
      _specialtyBadge('breath', '🧘', s.badgeBreath, s.badgeBreathDesc, statusOf('breathing_box')),
    ];
  }

  /// Costruisce la tile di una famiglia di badge a livelli: se il livello
  /// più alto è già raggiunto la mostra completa, altrimenti mostra il
  /// prossimo livello da sbloccare con il progresso reale — così l'utente
  /// vede sempre il prossimo obiettivo, non solo quelli già ottenuti.
  BadgeInfo _tierBadge({
    required String key,
    required int progress,
    required List<(int target, String emoji, String name, String desc)> tiers,
  }) {
    var highestEarnedIdx = -1;
    for (var i = 0; i < tiers.length; i++) {
      if (progress >= tiers[i].$1) highestEarnedIdx = i;
    }
    final earned = highestEarnedIdx >= 0;
    final isMaxed = highestEarnedIdx == tiers.length - 1;
    final showIdx = isMaxed ? highestEarnedIdx : highestEarnedIdx + 1;
    final tier = tiers[showIdx];
    return BadgeInfo(
      key: key,
      emoji: tier.$2,
      name: tier.$3,
      description: tier.$4,
      earned: earned,
      progress: progress.clamp(0, tier.$1),
      target: tier.$1,
    );
  }

  BadgeInfo _specialtyBadge(String key, String emoji, String name, String desc, HabitStatus? status) {
    final earned = status == HabitStatus.consolidated || status == HabitStatus.automatic;
    return BadgeInfo(
      key: key, emoji: emoji, name: name, description: desc,
      earned: earned, progress: earned ? 1 : 0, target: 1,
    );
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

  /// Data (stimata) di raggiungimento di una fase — calcolata con la STESSA
  /// metrica di [currentPhase] (numero di abitudini consolidate), non con
  /// soglie di giorni scollegate: usare due formule diverse per "fase
  /// attuale" e "quando l'ho raggiunta" è quello che faceva sembrare le fasi
  /// avanzare "a caso" tra la Companion Hero e il Percorso Welly.
  /// Stima: 7 giorni dopo l'attivazione della N-esima abitudine che si
  /// consolida (usiamo activatedAt, conservato per sempre, invece della
  /// data esatta del 7° completamento — completionDates tiene solo gli
  /// ultimi 70 giorni e per abitudini più vecchie non sarebbe più presente).
  DateTime? phaseReachedDate(int phase) {
    const thresholds = [0, 1, 3, 7, 12];
    if (phase < 1 || phase > 5) return null;
    final needed = thresholds[phase - 1];
    if (needed == 0) return installDate;

    final consolidatedActivations = _states.values
        .where((st) => st.daysCompleted >= 7 && st.activatedAt != null)
        .map((st) => st.activatedAt!)
        .toList()
      ..sort();
    if (consolidatedActivations.length < needed) return null;
    return consolidatedActivations[needed - 1].add(const Duration(days: 7));
  }

  /// Quante abitudini consolidate mancano ancora per raggiungere [phase].
  int habitsUntilPhase(int phase) {
    const thresholds = [0, 1, 3, 7, 12];
    if (phase < 1 || phase > 5) return 0;
    return (thresholds[phase - 1] - consolidatedHabitsCount).clamp(0, 999);
  }

  DateTime? get installDate => _installDate;

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

/// Un badge (guadagnato o prossimo obiettivo) mostrato nella schermata Growth.
class BadgeInfo {
  /// Identificatore stabile della FAMIGLIA di badge (non del livello) — usato
  /// per rilevare quando un badge passa da non-guadagnato a guadagnato,
  /// senza dipendere da nome/emoji che cambiano da un livello all'altro.
  final String key;
  final String emoji;
  final String name;
  final String description;
  /// True se almeno il primo livello della famiglia è stato raggiunto.
  final bool earned;
  /// Valore corrente della metrica (es. giorni, abitudini attive).
  final int progress;
  /// Soglia del livello mostrato (raggiunto se maxato, prossimo altrimenti).
  final int target;
  const BadgeInfo({
    required this.key,
    required this.emoji,
    required this.name,
    required this.description,
    required this.earned,
    required this.progress,
    required this.target,
  });

  /// True se questa tile è al livello massimo della sua famiglia (piena),
  /// non solo "un livello raggiunto ma ne restano altri".
  bool get isMaxed => progress >= target;
}



















