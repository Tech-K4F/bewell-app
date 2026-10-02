import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/progression_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';

// Foglio per impostare giorni e orari di lavoro/studio, scheda d'invito in
// Abitudini e popup d'invito (una volta sola). Riusa lo stile esistente.

class WorkScheduleCard extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const WorkScheduleCard({
    required this.p,
    required this.s,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💼', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.workScheduleBanner,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.text,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                  button: true,
                  container: true,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.cardBorder, width: 0.5),
                      ),
                      child: Text(
                        s.workScheduleEdit,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.text),
                      ),
                    ),
                  )),
              const SizedBox(width: 8),
              Semantics(
                  button: true,
                  container: true,
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.workScheduleConfirm,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Work Schedule Sheet ───────────────────────────────────────────────────────
class WorkScheduleSheet extends StatefulWidget {
  final BwPaletteData p;
  final WorkSchedule initial;
  final Future<void> Function(WorkSchedule) onSave;

  const WorkScheduleSheet({
    required this.p,
    required this.initial,
    required this.onSave,
  });

  /// Apre il foglio con gli orari attuali; salvando li conferma.
  static Future<void> show(BuildContext context) async {
    final p = context.read<ThemeProvider>().paletteData;
    final provider = context.read<ScheduleProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkScheduleSheet(
        p: p,
        initial: provider.schedule,
        onSave: (s) async {
          await provider.setSchedule(s);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('work_schedule_confirmed', true);
        },
      ),
    );
  }

  @override
  State<WorkScheduleSheet> createState() => _WorkScheduleSheetState();
}

class _WorkScheduleSheetState extends State<WorkScheduleSheet> {
  late int _startMorning;
  late int _endMorning;
  late int _startAfternoon;
  late int _endAfternoon;
  late int _lunchHour;
  late int _lunchDuration;
  late Set<int> _days;
  bool _hasLunch = true;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _startMorning = s.startMorning;
    _endMorning = s.endMorning;
    _startAfternoon = s.startAfternoon;
    _endAfternoon = s.endAfternoon;
    _lunchHour = s.lunchHour;
    _lunchDuration = s.lunchDurationMin;
    _days = {...s.workDays};
  }

  Future<void> _pickHour(
      BuildContext ctx, int current, ValueChanged<int> onPicked) async {
    final result = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(hour: current, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (result != null) onPicked(result.hour);
  }

  String _dayLabel(BwStrings s, int d) => switch (d) {
        1 => s.wdMon,
        2 => s.wdTue,
        3 => s.wdWed,
        4 => s.wdThu,
        5 => s.wdFri,
        6 => s.wdSat,
        _ => s.wdSun,
      };

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = context.sL;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            32,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: p.textMut,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            s.workScheduleTitle,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 20),

          // Giorni di lavoro / studio
          Text(
            s.workScheduleDays,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textSec,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in const [1, 2, 3, 4, 5, 6, 7])
                Semantics(
                  button: true,
                  selected: _days.contains(d),
                  label: _dayLabel(s, d),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (_days.contains(d)) {
                        if (_days.length > 1) _days.remove(d);
                      } else {
                        _days.add(d);
                      }
                    }),
                    child: Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _days.contains(d) ? p.primaryLight : p.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _days.contains(d) ? p.primary : p.cardBorder,
                          width: _days.contains(d) ? 1.5 : 0.5,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          _dayLabel(s, d),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _days.contains(d)
                                  ? p.primaryText
                                  : p.textSec),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Mattina
          Text(
            s.workScheduleMorning,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textSec,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: s.workScheduleStart,
                  time: _fmt(_startMorning),
                  p: p,
                  onTap: () => _pickHour(context, _startMorning,
                      (h) => setState(() => _startMorning = h)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeButton(
                  label: s.workScheduleEnd,
                  time: _fmt(_endMorning),
                  p: p,
                  onTap: () => _pickHour(context, _endMorning,
                      (h) => setState(() => _endMorning = h)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pomeriggio
          Text(
            s.workScheduleAfternoon,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textSec,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: s.workScheduleStart,
                  time: _fmt(_startAfternoon),
                  p: p,
                  onTap: () => _pickHour(context, _startAfternoon,
                      (h) => setState(() => _startAfternoon = h)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeButton(
                  label: s.workScheduleEnd,
                  time: _fmt(_endAfternoon),
                  p: p,
                  onTap: () => _pickHour(context, _endAfternoon,
                      (h) => setState(() => _endAfternoon = h)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pausa pranzo
          Semantics(
              button: true,
              container: true,
              child: GestureDetector(
                onTap: () => setState(() => _hasLunch = !_hasLunch),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _hasLunch ? p.primary : p.card,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _hasLunch ? p.primary : p.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: _hasLunch
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.workScheduleLunch,
                      style: TextStyle(
                          fontSize: 13,
                          color: p.text,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),

          if (_hasLunch) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: s.workScheduleTime,
                    time: _fmt(_lunchHour),
                    p: p,
                    onTap: () => _pickHour(context, _lunchHour,
                        (h) => setState(() => _lunchHour = h)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.cardBorder, width: 0.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _lunchDuration,
                        isExpanded: true,
                        style: TextStyle(fontSize: 13, color: p.text),
                        dropdownColor: p.card,
                        items: [30, 45, 60, 90]
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('${d} min'),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _lunchDuration = v ?? 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          Semantics(
              button: true,
              container: true,
              child: GestureDetector(
                onTap: () async {
                  final schedule = WorkSchedule(
                    startMorning: _startMorning,
                    endMorning: _endMorning,
                    startAfternoon: _startAfternoon,
                    endAfternoon: _endAfternoon,
                    lunchHour: _lunchHour,
                    lunchDurationMin: _hasLunch ? _lunchDuration : 0,
                    workDays: _days,
                  );
                  await widget.onSave(schedule);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: p.btn,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      s.workScheduleSave,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: p.btnText),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final BwPaletteData p;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
        button: true,
        container: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: p.textMut,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
                ),
              ],
            ),
          ),
        ));
  }
}

/// Scheda sotto "In arrivo oggi" in Abitudini: finché gli orari non sono
/// confermati (dal secondo giorno) li propone, con "Imposta" e "Va bene così".
class WorkScheduleSection extends StatefulWidget {
  final BwPaletteData p;
  const WorkScheduleSection({super.key, required this.p});

  @override
  State<WorkScheduleSection> createState() => _WorkScheduleSectionState();
}

class _WorkScheduleSectionState extends State<WorkScheduleSection> {
  bool _confirmed = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool('work_schedule_confirmed') ?? false;
    if (mounted) setState(() => _confirmed = v);
  }

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('work_schedule_confirmed', true);
    if (mounted) setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    final day = context.watch<ProgressionProvider>().calendarDayNumber;
    if (_confirmed || day < 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: WorkScheduleCard(
        p: widget.p,
        s: context.sL,
        onConfirm: _confirm,
        onEdit: () async {
          await WorkScheduleSheet.show(context);
          await _load();
        },
      ),
    );
  }
}

/// Popup d'invito: una sola volta, dal secondo giorno, se gli orari non sono
/// ancora stati confermati. Resta sempre modificabile da Abitudini.
class WorkScheduleInvite {
  static const _shownKey = 'work_schedule_invite_shown';

  static Future<void> maybeShowOnce(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('work_schedule_confirmed') ?? false) return;
    if (prefs.getBool(_shownKey) ?? false) return;
    if (!context.mounted) return;
    if (context.read<ProgressionProvider>().calendarDayNumber < 1) return;
    await prefs.setBool(_shownKey, true);
    if (!context.mounted) return;
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    final set = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text(s.workScheduleInviteTitle,
            style: TextStyle(color: p.text, fontSize: 17)),
        content: Text(s.workScheduleInviteBody,
            style: TextStyle(color: p.textSec, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.workScheduleInviteLater,
                style: TextStyle(color: p.textSec)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: p.primary),
            child: Text(s.workScheduleInviteSet),
          ),
        ],
      ),
    );
    if (set == true && context.mounted) await WorkScheduleSheet.show(context);
  }
}
