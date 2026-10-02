import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/habit_library.dart';
import '../providers/progression_provider.dart';
import '../providers/schedule_provider.dart';
import 'notification_service.dart';

/// Promemoria "intelligenti": non uno per ogni mini attività, ma pochi
/// momenti nella giornata costruiti sulle abitudini realmente attive.
///  • Le attività lunghe di concentrazione (Focus) hanno la loro notifica.
///  • Le attività brevi vengono RAGGRUPPATE per fascia oraria in un solo
///    avviso ("Acqua e Stretching"), collocato dopo i blocchi di Focus.
///  • Quello che è già stato fatto oggi non viene mai ricordato.
///  • Un tetto giornaliero (dalla frequenza scelta) e una distanza minima
///    tra un avviso e l'altro evitano l'effetto "bombardamento".
/// Tono: un invito gentile, mai una pressione.
class SmartReminders {
  SmartReminders._();

  static const _inputKey = 'smart_reminder_input';
  static const _minGapMinutes = 90;
  static const _quietStartHour = 7;
  static const _quietEndHour = 22;
  static String? _lastSignature;

  // ── Snapshot dello stato ───────────────────────────────────────────────────

  /// Salva lo stato attuale (abitudini attive, cosa è già fatto oggi, orari)
  /// e ripianifica. Va chiamata quando cambiano le abitudini/completamenti e
  /// quando l'app va in background. Se nulla è cambiato non fa niente.
  static Future<void> refresh(
    ProgressionProvider progression,
    ScheduleProvider schedule,
  ) async {
    if (!progression.isInitialized) return;
    final now = DateTime.now();
    bool doneToday(String id) {
      final last = progression.stateOf(id)?.lastCompletedAt;
      return last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
    }

    final sc = schedule.schedule;
    final input = {
      'date': _dateKey(now),
      'userType': schedule.userType == UserType.student ? 'student' : 'worker',
      'sched': [
        sc.startMorning,
        sc.endMorning,
        sc.startAfternoon,
        sc.endAfternoon,
        sc.lunchHour,
      ],
      'workDays': (sc.workDays.toList()..sort()),
      'habits': [
        for (final h in progression.activeHabits)
          {
            'id': h.id,
            'slot': schedule.getTimeSlot(h).name,
            'focus': h.category == HabitCategory.focus,
            'done': doneToday(h.id),
          },
      ],
    };
    final encoded = jsonEncode(input);
    if (encoded == _lastSignature) return;
    _lastSignature = encoded;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inputKey, encoded);
    await replan();
  }

  // ── Pianificazione ─────────────────────────────────────────────────────────

  /// Ricalcola e ripianifica leggendo tutto da SharedPreferences: usabile
  /// anche da chi non ha un BuildContext (cambio lingua, frequenza, pausa).
  static Future<void> replan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inputKey);
    final service = NotificationService.instance;
    await service.cancelReminders();
    if (raw == null) return;

    final Map<String, dynamic> input;
    try {
      input = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final cap = switch (prefs.getString('notif_frequency') ?? 'normal') {
      'off' => 0,
      'low' => 2,
      'high' => 6,
      _ => 4,
    };
    if (cap == 0) return;

    final now = DateTime.now();
    var earliest = now.add(const Duration(minutes: 2));
    final snoozeMs = prefs.getInt('notif_snooze_until');
    if (snoozeMs != null) {
      final snooze = DateTime.fromMillisecondsSinceEpoch(snoozeMs);
      if (snooze.isAfter(earliest)) earliest = snooze;
    }

    // Lo snapshot vale solo per il giorno in cui è stato scritto: da domani
    // in poi si assume che nulla sia ancora stato fatto.
    final snapshotIsToday = input['date'] == _dateKey(now);
    final today = DateTime(now.year, now.month, now.day);
    final planned = <_Reminder>[
      ..._planDay(input, today, cap: cap, useDoneFlags: snapshotIsToday),
      ..._planDay(input, today.add(const Duration(days: 1)),
          cap: cap, useDoneFlags: false),
    ].where((r) => r.at.isAfter(earliest)).toList();

    final s = await currentBwStrings();
    for (var i = 0; i < planned.length && i < 12; i++) {
      final r = planned[i];
      final (title, body) = _texts(s, r);
      await service.scheduleAt(
        id: NotificationIds.reminderBase + i,
        title: title,
        body: body,
        at: r.at,
        payload: r.kind == _Kind.focus
            ? 'tab:habits'
            : (r.ids.contains('water') ? 'tab:home' : 'tab:habits'),
      );
    }

    await _scheduleComebacks(service, s, now, earliest);
  }

  /// Notifiche di ritorno: se l'app non viene aperta, un invito gentile ogni
  /// 3 giorni (per circa 18 giorni, poi si ferma). Contano dall'ultimo uso:
  /// ogni volta che l'app si apre vengono rimandate in avanti.
  static const _comebackEveryDays = 3;
  static const _comebackHour = 19;

  static Future<void> _scheduleComebacks(NotificationService service,
      BwStrings s, DateTime now, DateTime earliest) async {
    for (var k = 1; k <= NotificationIds.comebackSlots; k++) {
      final day = now.add(Duration(days: _comebackEveryDays * k));
      final at = DateTime(day.year, day.month, day.day, _comebackHour);
      if (!at.isAfter(earliest)) continue;
      final (title, body) = switch ((k - 1) % 4) {
        0 => (s.notifComebackTitle1, s.notifComebackBody1),
        1 => (s.notifComebackTitle2, s.notifComebackBody2),
        2 => (s.notifComebackTitle3, s.notifComebackBody3),
        _ => (s.notifComebackTitle4, s.notifComebackBody4),
      };
      await service.scheduleAt(
        id: NotificationIds.comebackBase + k - 1,
        title: title,
        body: body,
        at: at,
        payload: 'tab:home',
      );
    }
  }

  static List<_Reminder> _planDay(
    Map<String, dynamic> input,
    DateTime day, {
    required int cap,
    required bool useDoneFlags,
  }) {
    // Nei giorni liberi niente promemoria legati al lavoro (Focus) e orari
    // più rilassati.
    final workDays =
        (input['workDays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5];
    final isWorkDay = workDays.contains(day.weekday);
    final worker = input['userType'] != 'student' && isWorkDay;
    final sched = (input['sched'] as List).cast<int>();
    final startMorning = sched[0];
    final startAfternoon = sched[2];
    final lunchHour = sched[4];

    final pending = <_Habit>[];
    for (final h in (input['habits'] as List).cast<Map<String, dynamic>>()) {
      if (useDoneFlags && h['done'] == true) continue;
      pending.add(_Habit(h['id'] as String, h['slot'] as String,
          isFocus: h['focus'] == true));
    }
    if (pending.isEmpty) return const [];

    int clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
    final bundleHour = <String, int>{
      'morning': worker ? clamp(startMorning - 1, 7, 10) : (isWorkDay ? 7 : 9),
      'midday': worker ? clamp(startMorning + 2, 9, 12) : (isWorkDay ? 10 : 11),
      'lunch': worker ? clamp(lunchHour, 12, 14) : (isWorkDay ? 12 : 13),
      'afternoon':
          worker ? clamp(startAfternoon + 2, 14, 18) : (isWorkDay ? 15 : 16),
      'evening': 20,
    };

    DateTime at(int hour) => DateTime(day.year, day.month, day.day, hour);
    final candidates = <_Reminder>[];

    // Attività lunghe (Focus): una notifica ciascuna, nel loro momento.
    final focus = pending.where((h) => h.isFocus).toList();
    final mainFocus = focus.where((h) => h.id != 'focus_no_phone').firstOrNull;
    if (mainFocus != null && isWorkDay) {
      candidates.add(_Reminder(
        at(worker ? startMorning : 8),
        _Kind.focus,
        [mainFocus.id],
        100,
      ));
    }
    final noPhone = focus.where((h) => h.id == 'focus_no_phone').firstOrNull;
    if (noPhone != null && isWorkDay) {
      candidates.add(_Reminder(
        at(worker ? clamp(startAfternoon + 1, 13, 17) : 14),
        _Kind.focus,
        [noPhone.id],
        90,
      ));
    }

    // Attività brevi: raggruppate per fascia; l'acqua si aggiunge finché
    // non è completata.
    final water = pending.where((h) => h.id == 'water').firstOrNull;
    for (final slot in bundleHour.keys) {
      final members = <String>[
        if (water != null && slot != 'evening' && slot != 'lunch') water.id,
        ...pending
            .where((h) => !h.isFocus && h.id != 'water' && h.slot == slot)
            .map((h) => h.id),
      ];
      if (members.isEmpty) continue;
      final kind = switch (slot) {
        'morning' => _Kind.bundleMorning,
        'evening' => _Kind.bundleEvening,
        _ => _Kind.bundleBreak,
      };
      candidates.add(_Reminder(
        at(bundleHour[slot]!),
        kind,
        members,
        10 + members.length,
      ));
    }

    // Selezione: prima ciò che conta di più, rispettando tetto giornaliero
    // e distanza minima; poi in ordine cronologico.
    candidates.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : a.at.compareTo(b.at);
    });
    final chosen = <_Reminder>[];
    for (final c in candidates) {
      if (chosen.length >= cap) break;
      if (c.at.hour < _quietStartHour || c.at.hour >= _quietEndHour) continue;
      final tooClose = chosen
          .any((o) => o.at.difference(c.at).abs().inMinutes < _minGapMinutes);
      if (!tooClose) chosen.add(c);
    }
    chosen.sort((a, b) => a.at.compareTo(b.at));
    return chosen;
  }

  // ── Testi ──────────────────────────────────────────────────────────────────

  static (String, String) _texts(BwStrings s, _Reminder r) {
    switch (r.kind) {
      case _Kind.focus:
        return (s.notifFocusTitle, s.notifFocusBody);
      case _Kind.bundleMorning:
        return (s.notifBundleTitle, s.notifBundleMorningBody(_names(s, r.ids)));
      case _Kind.bundleBreak:
        return (s.notifBundleTitle, s.notifBundleBreakBody(_names(s, r.ids)));
      case _Kind.bundleEvening:
        return (s.notifBundleTitle, s.notifBundleEveningBody(_names(s, r.ids)));
    }
  }

  /// "A e B" oppure "A, B +N": al massimo due nomi, mai un elenco lungo.
  static String _names(BwStrings s, List<String> ids) {
    final names = ids.take(2).map(s.habitName).toList();
    if (ids.length > 2) return '${names.join(', ')} +${ids.length - 2}';
    return names.join(' ${s.notifAndWord} ');
  }

  // ── Fine sessione Focus ────────────────────────────────────────────────────

  /// Programma la notifica "Focus finito" per quando scade il timer, con le
  /// attività brevi ancora da fare raggruppate ("ora: Acqua e Stretching").
  /// Da annullare con [cancelFocusEnd] se la sessione viene fermata o
  /// completata mentre l'app è aperta.
  static Future<void> scheduleFocusEnd({
    required Duration after,
    required List<String> pendingHabitIds,
  }) async {
    final s = await currentBwStrings();
    final body = pendingHabitIds.isEmpty
        ? s.notifFocusDoneBodyPlain
        : s.notifFocusDoneBody(_names(s, pendingHabitIds));
    await NotificationService.instance.scheduleAt(
      id: NotificationIds.focusEnd,
      title: s.notifFocusDoneTitle,
      body: body,
      at: DateTime.now().add(after),
      exact: true,
      payload: 'tab:habits',
    );
  }

  /// Timer Focus persistente (conto alla rovescia fino a [endsAt]).
  static Future<void> showFocusRunning(DateTime endsAt) async {
    final s = await currentBwStrings();
    await NotificationService.instance.showFocusTimer(
      title: s.notifFocusRunningTitle,
      body: s.notifFocusRunningBody,
      endsAt: endsAt,
    );
  }

  static Future<void> showFocusPaused() async {
    final s = await currentBwStrings();
    await NotificationService.instance.showFocusTimer(
      title: s.notifFocusPausedTitle,
      body: s.notifFocusPausedBody,
    );
  }

  static Future<void> cancelFocusTimer() =>
      NotificationService.instance.cancel(NotificationIds.focusTimer);

  static Future<void> cancelFocusEnd() =>
      NotificationService.instance.cancel(NotificationIds.focusEnd);

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

enum _Kind { focus, bundleMorning, bundleBreak, bundleEvening }

class _Habit {
  final String id;
  final String slot;
  final bool isFocus;
  const _Habit(this.id, this.slot, {this.isFocus = false});
}

class _Reminder {
  final DateTime at;
  final _Kind kind;
  final List<String> ids;
  final int priority;
  const _Reminder(this.at, this.kind, this.ids, this.priority);
}
