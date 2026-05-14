// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — ScheduleProvider
//  Gestisce tipo utente (student/worker), orari di lavoro e logica di
//  schedulazione delle abitudini per ora del giorno.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_library.dart';

// ── Tipo utente ───────────────────────────────────────────────────────────────

enum UserType { student, worker }

// ── Fascia oraria ─────────────────────────────────────────────────────────────

enum TimeSlot { morning, midday, lunch, afternoon, evening }

// ── Orari di lavoro ───────────────────────────────────────────────────────────

class WorkSchedule {
  /// Ore inizio mattina (default 9)
  final int startMorning;
  /// Ore fine mattina (default 13)
  final int endMorning;
  /// Ore inizio pomeriggio (default 14)
  final int startAfternoon;
  /// Ore fine pomeriggio (default 18)
  final int endAfternoon;
  /// Ora pausa pranzo (default 13)
  final int lunchHour;
  /// Durata pausa pranzo in minuti (default 30)
  final int lunchDurationMin;

  const WorkSchedule({
    this.startMorning = 9,
    this.endMorning = 13,
    this.startAfternoon = 14,
    this.endAfternoon = 18,
    this.lunchHour = 13,
    this.lunchDurationMin = 30,
  });

  WorkSchedule copyWith({
    int? startMorning,
    int? endMorning,
    int? startAfternoon,
    int? endAfternoon,
    int? lunchHour,
    int? lunchDurationMin,
  }) {
    return WorkSchedule(
      startMorning: startMorning ?? this.startMorning,
      endMorning: endMorning ?? this.endMorning,
      startAfternoon: startAfternoon ?? this.startAfternoon,
      endAfternoon: endAfternoon ?? this.endAfternoon,
      lunchHour: lunchHour ?? this.lunchHour,
      lunchDurationMin: lunchDurationMin ?? this.lunchDurationMin,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ScheduleProvider extends ChangeNotifier {
  UserType _userType = UserType.worker;
  WorkSchedule _schedule = const WorkSchedule();

  /// Per ogni abitudine: timestamp (millisecondsSinceEpoch) dell'eventuale
  /// rallentamento volontario. Se null → nessun rallentamento attivo.
  final Map<String, int> _slowdownTimestamps = {};

  UserType get userType => _userType;
  WorkSchedule get schedule => _schedule;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final typeStr = prefs.getString('user_type') ?? 'worker';
    _userType = typeStr == 'student' ? UserType.student : UserType.worker;

    _schedule = WorkSchedule(
      startMorning:   _parseHour(prefs.getString('work_start_morning')   ?? '09:00'),
      endMorning:     _parseHour(prefs.getString('work_end_morning')     ?? '13:00'),
      startAfternoon: _parseHour(prefs.getString('work_start_afternoon') ?? '14:00'),
      endAfternoon:   _parseHour(prefs.getString('work_end_afternoon')   ?? '18:00'),
      lunchHour:      _parseHour(prefs.getString('lunch_time')           ?? '13:00'),
      lunchDurationMin: prefs.getInt('lunch_duration_min') ?? 30,
    );

    // Carica eventuali rallentamenti salvati
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('habit_') && key.endsWith('_slowdown_ts')) {
        final habitId = key
            .replaceFirst('habit_', '')
            .replaceAll('_slowdown_ts', '');
        _slowdownTimestamps[habitId] = prefs.getInt(key) ?? 0;
      }
    }

    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setUserType(UserType type) async {
    _userType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type == UserType.student ? 'student' : 'worker');
    notifyListeners();
  }

  Future<void> setSchedule(WorkSchedule s) async {
    _schedule = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_start_morning',   '${s.startMorning.toString().padLeft(2,'0')}:00');
    await prefs.setString('work_end_morning',     '${s.endMorning.toString().padLeft(2,'0')}:00');
    await prefs.setString('work_start_afternoon', '${s.startAfternoon.toString().padLeft(2,'0')}:00');
    await prefs.setString('work_end_afternoon',   '${s.endAfternoon.toString().padLeft(2,'0')}:00');
    await prefs.setString('lunch_time',           '${s.lunchHour.toString().padLeft(2,'0')}:00');
    await prefs.setInt('lunch_duration_min', s.lunchDurationMin);
    notifyListeners();
  }

  /// Segna un rallentamento volontario per l'abitudine specificata.
  /// Posticipa il prossimo sblocco di 14 giorni (gestito da ProgressionProvider).
  Future<void> setSlowdown(String habitId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _slowdownTimestamps[habitId] = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('habit_${habitId}_slowdown_ts', now);
    // Incrementa contatore
    final count = (prefs.getInt('habit_${habitId}_slowdown_count') ?? 0) + 1;
    await prefs.setInt('habit_${habitId}_slowdown_count', count);
    notifyListeners();
  }

  /// True se almeno un'abitudine ha un rallentamento attivo negli ultimi 14 giorni.
  bool get needsSlowdown {
    final now = DateTime.now().millisecondsSinceEpoch;
    const fourteenDaysMs = 14 * 24 * 60 * 60 * 1000;
    return _slowdownTimestamps.values.any((ts) => (now - ts) < fourteenDaysMs);
  }

  // ── Fascia oraria di un'abitudine ─────────────────────────────────────────

  TimeSlot getTimeSlot(HabitDefinition habit) {
    switch (habit.id) {
      case 'water':
      case 'water_morning':
        return TimeSlot.morning;

      case 'snack':
        return TimeSlot.midday;

      case 'focus_25':
      case 'focus_50':
      case 'focus_no_phone':
      case 'eyes_20_20_20':
      case 'neck_stretch':
      case 'posture':
      case 'breathing_box':
        return TimeSlot.midday;

      case 'walk_lunch':
      case 'lunch_no_screen':
      case 'lunch_park':
        return TimeSlot.lunch;

      case 'desk_exercise':
      case 'stretching_active':
      case 'nap':
      case 'breathing_478':
      case 'meditation':
      case 'stairs':
        return TimeSlot.afternoon;

      case 'sleep_routine':
      case 'wake_consistent':
        return TimeSlot.evening;

      default:
        // Determina dalla categoria
        switch (habit.category) {
          case HabitCategory.hydration:
            return TimeSlot.morning;
          case HabitCategory.focus:
            return TimeSlot.midday;
          case HabitCategory.movement:
            return TimeSlot.afternoon;
          case HabitCategory.sleep:
            return TimeSlot.evening;
          default:
            return TimeSlot.midday;
        }
    }
  }

  // ── Abitudine suggerita per l'ora corrente ────────────────────────────────

  /// Restituisce l'abitudine più adatta da fare in questo momento.
  /// [active] = lista delle abitudini attive (non completate oggi).
  /// [hour]   = ora corrente (0-23).
  HabitDefinition? getHabitForNow(
      List<HabitDefinition> active, int hour) {
    if (active.isEmpty) return null;

    if (_userType == UserType.worker) {
      return _getHabitForNowWorker(active, hour);
    } else {
      return _getHabitForNowStudent(active, hour);
    }
  }

  // ── Logica worker ─────────────────────────────────────────────────────────

  HabitDefinition? _getHabitForNowWorker(
      List<HabitDefinition> active, int hour) {
    final s = _schedule;

    // Prima dell'inizio lavoro — attività mattutine
    if (hour < s.startMorning) {
      return _pickFirst(active, ['water_morning', 'water', 'stretching_active']);
    }

    // Inizio lavoro — primo blocco focus (picco cognitivo)
    if (hour == s.startMorning) {
      return _pickFirst(active, ['focus_25', 'focus_50']);
    }

    // Metà mattina (startMorning + 2h) — pausa vera
    if (hour == s.startMorning + 2) {
      return _pickFirst(active, ['stretching_active', 'neck_stretch', 'breathing_box', 'water']);
    }

    // Fine mattina (endMorning - 1h) — snack + acqua
    if (hour == s.endMorning - 1) {
      return _pickFirst(active, ['snack', 'water']);
    }

    // Blocco mattutino — micro-break ogni ora
    if (hour > s.startMorning && hour < s.endMorning) {
      return _pickFirst(active, ['eyes_20_20_20', 'neck_stretch', 'posture', 'water']);
    }

    // Pausa pranzo
    if (hour >= s.lunchHour && hour < s.startAfternoon) {
      return _pickFirst(active, ['walk_lunch', 'lunch_no_screen', 'lunch_park', 'water']);
    }

    // Inizio pomeriggio — recovery + focus
    if (hour == s.startAfternoon) {
      if (hour < 15) {
        return _pickFirst(active, ['nap', 'meditation', 'breathing_478']);
      }
      return _pickFirst(active, ['focus_25', 'focus_50']);
    }

    // Primo blocco pomeriggio (startAfternoon + 30min ~≈ startAfternoon + 1h)
    if (hour == s.startAfternoon + 1) {
      return _pickFirst(active, ['focus_25', 'focus_50', 'focus_no_phone']);
    }

    // Metà pomeriggio (startAfternoon + 2h) — pausa vera
    if (hour == s.startAfternoon + 2) {
      return _pickFirst(active, ['desk_exercise', 'stretching_active', 'breathing_box']);
    }

    // Blocco pomeriggio — micro-break
    if (hour > s.startAfternoon && hour < s.endAfternoon) {
      return _pickFirst(active, ['posture', 'eyes_20_20_20', 'water']);
    }

    // Fine lavoro
    if (hour == s.endAfternoon) {
      return _pickFirst(active, ['stairs', 'water', 'stretching_active']);
    }

    // Sera
    if (hour >= 21) {
      return _pickFirst(active, ['sleep_routine']);
    }
    if (hour > s.endAfternoon) {
      return _pickFirst(active, ['water', 'meditation', 'breathing_478']);
    }

    return _pickFirst(active, ['water']);
  }

  // ── Logica student ────────────────────────────────────────────────────────

  HabitDefinition? _getHabitForNowStudent(
      List<HabitDefinition> active, int hour) {
    // Mattina 8-12: cicli focus 90 min
    if (hour >= 8 && hour < 12) {
      if (hour == 10) {
        return _pickFirst(active, ['water', 'snack']);
      }
      return _pickFirst(active, ['focus_25', 'focus_50', 'water_morning', 'water']);
    }

    // Pranzo 12-14
    if (hour >= 12 && hour < 14) {
      return _pickFirst(active, ['walk_lunch', 'lunch_no_screen', 'water']);
    }

    // Primo pomeriggio 14-17: flessibile
    if (hour >= 14 && hour < 17) {
      return _pickFirst(active, ['breathing_box', 'meditation', 'focus_25', 'breathing_478']);
    }

    // Sera 17+
    if (hour >= 18) {
      return _pickFirst(active, ['sleep_routine', 'water']);
    }

    // Default mattino presto
    return _pickFirst(active, ['water_morning', 'water']);
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Prova gli id in ordine e restituisce il primo presente in [active].
  HabitDefinition? _pickFirst(
      List<HabitDefinition> active, List<String> preferredIds) {
    for (final id in preferredIds) {
      final found = active.where((h) => h.id == id).firstOrNull;
      if (found != null) return found;
    }
    // Nessuno dei preferiti disponibile → restituisce il primo attivo
    return active.firstOrNull;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _parseHour(String hhmm) {
    try {
      return int.parse(hhmm.split(':').first);
    } catch (_) {
      return 0;
    }
  }
}
