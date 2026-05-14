// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — HabitCalendar
//  Calendario giornaliero minimalista.
//  Appare dalla Fase 2 (quando focus_25 è sbloccato).
//  Mostra solo le prossime 2-4 ore attorno all'orario corrente.
//  • Blocco corrente → evidenziato con primary + tag "▶ in corso"
//  • Passato → opacity 0.30
//  • Futuro vicino → piena visibilità
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../l10n/app_localizations.dart';

// ── Tipo di blocco ────────────────────────────────────────────────────────────

enum _BlockType { focus, shortBreak, longBreak, habit, water, meal, free }

// ── Entry del calendario ──────────────────────────────────────────────────────

class _CalEntry {
  final String time;      // es. "09:00"
  final String emoji;
  final String label;
  final _BlockType type;
  final int durationMin;  // durata in minuti (0 = punto nel tempo)

  const _CalEntry({
    required this.time,
    required this.emoji,
    required this.label,
    required this.type,
    this.durationMin = 25,
  });
}

// ── Entry annotata con stato temporale ───────────────────────────────────────

typedef _AnnotatedEntry = ({
  _CalEntry entry,
  bool isCurrent,
  bool isPast,
});

// ── Widget principale ─────────────────────────────────────────────────────────

class HabitCalendar extends StatefulWidget {
  const HabitCalendar({super.key});

  @override
  State<HabitCalendar> createState() => _HabitCalendarState();
}

class _HabitCalendarState extends State<HabitCalendar> {
  late Timer _minuteTick;

  @override
  void initState() {
    super.initState();
    // Ricostruisce ogni minuto per mantenere il "▶ in corso" sincronizzato
    // con l'orologio reale del telefono.
    _minuteTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme    = context.watch<ThemeProvider>();
    final progress = context.watch<ProgressionProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final s        = context.sL;
    final p        = theme.paletteData;

    // Mostra solo dalla fase 2 (focus_25 sbloccato)
    final focusStatus = progress.statusOf('focus_25');
    if (focusStatus == HabitStatus.locked) return const SizedBox.shrink();

    final allEntries = schedule.userType == UserType.worker
        ? _buildWorkerCalendar(progress, schedule, s)
        : _buildStudentCalendar(progress, s);

    if (allEntries.isEmpty) return const SizedBox.shrink();

    // ── Windowing: ±2h prima – +4h dopo ──────────────────────────────────────
    final now         = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 2));
    final windowEnd   = now.add(const Duration(hours: 4));

    final windowedEntries = <_AnnotatedEntry>[];
    for (final e in allEntries) {
      final start = _parseTime(e.time, now);
      final dur   = e.durationMin > 0 ? e.durationMin : 10;
      final end   = start.add(Duration(minutes: dur));

      // Includi solo se il blocco interseca la finestra temporale
      if (start.isBefore(windowEnd) && end.isAfter(windowStart)) {
        windowedEntries.add((
          entry:     e,
          isCurrent: now.isAfter(start) && now.isBefore(end),
          isPast:    end.isBefore(now),
        ));
      }
    }

    // Fallback: se la finestra è vuota (fuori orario lavorativo / sera / test)
    // mostra le prossime entry in programma, o le ultime se tutto è passato.
    if (windowedEntries.isEmpty && allEntries.isNotEmpty) {
      // Prossime entry non ancora terminate
      for (final e in allEntries) {
        final start = _parseTime(e.time, now);
        final dur   = e.durationMin > 0 ? e.durationMin : 10;
        final end   = start.add(Duration(minutes: dur));
        if (end.isAfter(now)) {
          windowedEntries.add((entry: e, isCurrent: false, isPast: false));
          if (windowedEntries.length >= 4) break;
        }
      }
      // Se tutte le entry sono passate, mostra le ultime 3
      if (windowedEntries.isEmpty) {
        final last3 = allEntries.length > 3
            ? allEntries.sublist(allEntries.length - 3)
            : allEntries;
        for (final e in last3) {
          windowedEntries.add((entry: e, isCurrent: false, isPast: true));
        }
      }
    }

    if (windowedEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione sezione
        Text(
          s.calendarTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.textSec,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Timeline (solo la finestra attuale)
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder, width: 0.5),
          ),
          child: Column(
            children: windowedEntries.asMap().entries.map((e) {
              final isLast = e.key == windowedEntries.length - 1;
              final ae     = e.value;
              return _CalRow(
                entry:     ae.entry,
                p:         p,
                isLast:    isLast,
                isCurrent: ae.isCurrent,
                isPast:    ae.isPast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Helper: converte stringa "HH:MM" in DateTime di oggi ─────────────────

  static DateTime _parseTime(String time, DateTime now) {
    final parts = time.split(':');
    return DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );
  }

  // ── Calendario worker ─────────────────────────────────────────────────────

  List<_CalEntry> _buildWorkerCalendar(
    ProgressionProvider progress,
    ScheduleProvider schedule,
    BwStrings s,
  ) {
    final sc = schedule.schedule;
    final entries = <_CalEntry>[];

    bool inCal(String id) {
      final st = progress.statusOf(id);
      return st != HabitStatus.locked && st != HabitStatus.available;
    }

    String fmt(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    // ── Pre-lavoro ─────────────────────────────────────────────────────────
    if (inCal('water_morning')) {
      entries.add(_CalEntry(
        time: fmt(sc.startMorning - 1, 0),
        emoji: '💧',
        label: s.habitName('water_morning'),
        type: _BlockType.water,
        durationMin: 5,
      ));
    }

    // ── Ciclo mattutino — 3 Pomodoro + pause ──────────────────────────────
    int h = sc.startMorning;
    int m = 0;

    for (int cycle = 0; cycle < 3; cycle++) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: s.calendarFocus,
        type: _BlockType.focus,
        durationMin: 25,
      ));
      ({ int h, int m }) next = _add(h, m, 25);
      h = next.h; m = next.m;

      if (cycle < 2) {
        final breakLabel = cycle == 0 && inCal('breathing_box')
            ? '${s.calendarBreak} · ${s.habitName('breathing_box')}'
            : cycle == 1 && inCal('eyes_20_20_20')
                ? '${s.calendarBreak} · ${s.habitName('eyes_20_20_20')}'
                : s.calendarBreak;
        final breakEmoji = cycle == 0 && inCal('breathing_box')
            ? '🌬️'
            : cycle == 1 && inCal('eyes_20_20_20')
                ? '👁️'
                : '☕';

        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: breakEmoji,
          label: breakLabel,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        next = _add(h, m, 5);
        h = next.h; m = next.m;
      }
    }

    // Pausa lunga 20 min (+ stretching se disponibile)
    final longBreakLabel = inCal('neck_stretch')
        ? '${s.calendarLongBreak} · ${s.habitName('neck_stretch')}'
        : inCal('stretching_active')
            ? '${s.calendarLongBreak} · ${s.habitName('stretching_active')}'
            : s.calendarLongBreak;
    final longBreakEmoji =
        inCal('neck_stretch') || inCal('stretching_active') ? '🤸' : '⏸';

    entries.add(_CalEntry(
      time: fmt(h, m),
      emoji: longBreakEmoji,
      label: longBreakLabel,
      type: _BlockType.longBreak,
      durationMin: 20,
    ));
    var next2 = _add(h, m, 20);
    h = next2.h; m = next2.m;

    // ── Secondo blocco mattutino (2 Pomodoro prima del pranzo) ────────────
    for (int cycle = 0; cycle < 2; cycle++) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: s.calendarFocus,
        type: _BlockType.focus,
        durationMin: 25,
      ));
      next2 = _add(h, m, 25);
      h = next2.h; m = next2.m;

      if (cycle == 0) {
        final breakLabel = inCal('posture')
            ? '${s.calendarBreak} · ${s.habitName('posture')}'
            : s.calendarBreak;
        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: inCal('posture') ? '🧍' : '☕',
          label: breakLabel,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        next2 = _add(h, m, 5);
        h = next2.h; m = next2.m;
      }
    }

    // ── Pausa pranzo ──────────────────────────────────────────────────────
    final lunchEmoji = inCal('walk_lunch')
        ? '🚶'
        : inCal('lunch_no_screen')
            ? '🍽️'
            : '🍃';
    final lunchLabel = inCal('walk_lunch')
        ? s.habitName('walk_lunch')
        : inCal('lunch_no_screen')
            ? s.habitName('lunch_no_screen')
            : s.timeLunch;

    entries.add(_CalEntry(
      time: fmt(sc.lunchHour, 0),
      emoji: lunchEmoji,
      label: lunchLabel,
      type: _BlockType.meal,
      durationMin: sc.lunchDurationMin,
    ));

    // ── Ciclo pomeriggio (startAfternoon) ─────────────────────────────────
    h = sc.startAfternoon;
    m = 0;

    if (inCal('nap')) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '😴',
        label: s.habitName('nap'),
        type: _BlockType.habit,
        durationMin: 20,
      ));
      final n = _add(h, m, 20);
      h = n.h; m = n.m;
    }

    for (int cycle = 0; cycle < 3; cycle++) {
      final label = inCal('focus_50') && cycle == 0
          ? s.habitName('focus_50')
          : s.calendarFocus;
      final dur = inCal('focus_50') && cycle == 0 ? 50 : 25;
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: label,
        type: _BlockType.focus,
        durationMin: dur,
      ));
      var n = _add(h, m, dur);
      h = n.h; m = n.m;

      if (cycle < 2) {
        final bLabel = cycle == 1 && inCal('breathing_478')
            ? '${s.calendarBreak} · ${s.habitName('breathing_478')}'
            : s.calendarBreak;
        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: cycle == 1 && inCal('breathing_478') ? '🌬️' : '☕',
          label: bLabel,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        n = _add(h, m, 5);
        h = n.h; m = n.m;
      }
    }

    entries.add(_CalEntry(
      time: fmt(h, m),
      emoji: inCal('desk_exercise') ? '💪' : '⏸',
      label: inCal('desk_exercise')
          ? '${s.calendarLongBreak} · ${s.habitName('desk_exercise')}'
          : s.calendarLongBreak,
      type: _BlockType.longBreak,
      durationMin: 15,
    ));

    entries.add(_CalEntry(
      time: fmt(sc.endAfternoon, 0),
      emoji: inCal('stairs') ? '🪜' : '🏁',
      label: inCal('stairs') ? s.habitName('stairs') : s.timeEvening,
      type: inCal('stairs') ? _BlockType.habit : _BlockType.free,
      durationMin: 0,
    ));

    return entries;
  }

  // ── Calendario studente ───────────────────────────────────────────────────

  List<_CalEntry> _buildStudentCalendar(
    ProgressionProvider progress,
    BwStrings s,
  ) {
    final entries = <_CalEntry>[];

    bool inCal(String id) {
      final st = progress.statusOf(id);
      return st != HabitStatus.locked && st != HabitStatus.available;
    }

    String fmt(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    if (inCal('water_morning')) {
      entries.add(_CalEntry(
        time: '07:30',
        emoji: '💧',
        label: s.habitName('water_morning'),
        type: _BlockType.water,
        durationMin: 5,
      ));
    }

    int h = 8; int m = 0;
    for (int i = 0; i < 3; i++) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: s.calendarFocus,
        type: _BlockType.focus,
        durationMin: 25,
      ));
      var n = _add(h, m, 25);
      h = n.h; m = n.m;
      if (i < 2) {
        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: '☕',
          label: s.calendarBreak,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        n = _add(h, m, 5);
        h = n.h; m = n.m;
      }
    }

    entries.add(_CalEntry(
      time: fmt(h, m),
      emoji: inCal('stretching_active') ? '🤸' : '⏸',
      label: inCal('stretching_active')
          ? '${s.calendarLongBreak} · ${s.habitName('stretching_active')}'
          : s.calendarLongBreak,
      type: _BlockType.longBreak,
      durationMin: 20,
    ));
    var n = _add(h, m, 20);
    h = n.h; m = n.m;

    for (int i = 0; i < 3; i++) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: s.calendarFocus,
        type: _BlockType.focus,
        durationMin: 25,
      ));
      var n2 = _add(h, m, 25);
      h = n2.h; m = n2.m;
      if (i < 2) {
        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: '☕',
          label: s.calendarBreak,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        n2 = _add(h, m, 5);
        h = n2.h; m = n2.m;
      }
    }

    entries.add(_CalEntry(
      time: '12:00',
      emoji: inCal('walk_lunch') ? '🚶' : '🍃',
      label: inCal('walk_lunch') ? s.habitName('walk_lunch') : s.timeLunch,
      type: _BlockType.meal,
      durationMin: 60,
    ));

    h = 13; m = 30;
    for (int i = 0; i < 2; i++) {
      entries.add(_CalEntry(
        time: fmt(h, m),
        emoji: '🎯',
        label: s.calendarFocus,
        type: _BlockType.focus,
        durationMin: 25,
      ));
      var n3 = _add(h, m, 25);
      h = n3.h; m = n3.m;
      if (i == 0) {
        entries.add(_CalEntry(
          time: fmt(h, m),
          emoji: inCal('breathing_box') ? '🌬️' : '☕',
          label: inCal('breathing_box')
              ? '${s.calendarBreak} · ${s.habitName('breathing_box')}'
              : s.calendarBreak,
          type: _BlockType.shortBreak,
          durationMin: 5,
        ));
        n3 = _add(h, m, 5);
        h = n3.h; m = n3.m;
      }
    }

    if (inCal('sleep_routine')) {
      entries.add(_CalEntry(
        time: '22:00',
        emoji: '🌙',
        label: s.habitName('sleep_routine'),
        type: _BlockType.habit,
        durationMin: 30,
      ));
    }

    return entries;
  }

  // ── Utility aritmetica oraria ─────────────────────────────────────────────

  static ({int h, int m}) _add(int h, int m, int minutes) {
    final total = h * 60 + m + minutes;
    return (h: total ~/ 60, m: total % 60);
  }
}

// ── Riga del calendario ───────────────────────────────────────────────────────

class _CalRow extends StatelessWidget {
  final _CalEntry entry;
  final BwPaletteData p;
  final bool isLast;
  final bool isCurrent;
  final bool isPast;

  const _CalRow({
    required this.entry,
    required this.p,
    required this.isLast,
    this.isCurrent = false,
    this.isPast = false,
  });

  Color _dotColor() {
    if (isCurrent) return p.primary;
    switch (entry.type) {
      case _BlockType.focus:      return p.primary;
      case _BlockType.water:      return p.accent;
      case _BlockType.meal:       return p.accent;
      case _BlockType.habit:      return p.primaryText;
      case _BlockType.shortBreak:
      case _BlockType.longBreak:  return p.textMut;
      case _BlockType.free:       return p.textMut;
    }
  }

  Color _labelColor() {
    if (isCurrent) return p.primary;
    switch (entry.type) {
      case _BlockType.focus:      return p.primary;
      case _BlockType.water:      return p.accent;
      case _BlockType.meal:       return p.text;
      case _BlockType.habit:      return p.text;
      case _BlockType.shortBreak:
      case _BlockType.longBreak:  return p.textSec;
      case _BlockType.free:       return p.textMut;
    }
  }

  double _dotSize() {
    switch (entry.type) {
      case _BlockType.focus:      return 10;
      case _BlockType.longBreak:  return 8;
      case _BlockType.meal:       return 9;
      case _BlockType.habit:      return 9;
      default:                    return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor   = _dotColor();
    final labelColor = _labelColor();
    // Slot corrente: dot più grande per evidenziarlo
    final dotSize    = isCurrent ? (_dotSize() + 4) : _dotSize();
    final isFocus    = entry.type == _BlockType.focus;
    final isBreak    = entry.type == _BlockType.shortBreak ||
                       entry.type == _BlockType.longBreak;
    final isFilled   = isFocus || isCurrent;

    Widget rowContent = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ora — più grande e in grassetto per lo slot corrente
          SizedBox(
            width: 50,
            child: Padding(
              padding: EdgeInsets.only(
                  top: isCurrent ? 16 : 14, left: 14),
              child: Text(
                entry.time,
                style: TextStyle(
                  fontSize: isCurrent ? 12 : 10,
                  color: isCurrent ? p.primary : p.textMut,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          // Linea verticale + dot
          Column(
            children: [
              SizedBox(height: isCurrent ? 16 : 14),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isFilled ? dotColor : Colors.transparent,
                  border: Border.all(
                      color: dotColor, width: isFilled ? 0 : 1.5),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isBreak
                        ? p.cardBorder
                        : p.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          // Contenuto
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isCurrent ? 12 : 10,
                bottom: isLast ? 16 : isCurrent ? 12 : 8,
                right: 14,
              ),
              child: Row(
                children: [
                  Text(
                    entry.emoji,
                    style: TextStyle(fontSize: isCurrent ? 16 : isBreak ? 12 : 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: isCurrent ? 14 : isBreak ? 11 : 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : isFocus
                                ? FontWeight.w600
                                : FontWeight.w400,
                        color: labelColor,
                      ),
                    ),
                  ),
                  // "▶ in corso" chip — più visibile per lo slot attivo
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: p.primary.withValues(alpha: 0.30),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '▶ ora',
                        style: TextStyle(
                          fontSize: 10,
                          color: p.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                  if (entry.durationMin > 0 && isFocus && !isCurrent)
                    Text(
                      '${entry.durationMin} min',
                      style: TextStyle(fontSize: 10, color: p.textMut),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Wrapper per stato temporale
    if (isCurrent) {
      // Slot corrente: sfondo più intenso + barra colorata a sinistra
      return DecoratedBox(
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.11),
          border: Border(
            left: BorderSide(color: p.primary, width: 3),
          ),
        ),
        child: rowContent,
      );
    }
    if (isPast) {
      return Opacity(opacity: 0.30, child: rowContent);
    }
    return rowContent;
  }
}
