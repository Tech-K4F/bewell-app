import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/habit_library.dart';
import '../providers/progression_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tutorial_provider.dart';
import '../screens/habits/habits_screen.dart' show habitGoalLabel;
import 'spotlight_overlay.dart';

/// Riepilogo degli obiettivi di oggi per TUTTE le abitudini attive — mostrato
/// al massimo una volta al giorno al primo accesso utile. Tono: incoraggiante,
/// mai un conto alla rovescia o un avviso di perdita.
class DailyObjectivesDialog {
  static const _prefsKey = 'daily_objectives_shown_date';

  /// Mostra il popup una sola volta al giorno (data locale), ma SOLO se in
  /// questo momento non c'è già altro a schermo: se un tutorial o un altro
  /// popup è attivo esce senza segnare il giorno come "visto", così riprova
  /// alla prossima apertura invece di perdersi o accavallarsi.
  static Future<void> maybeShowForToday(BuildContext context) async {
    if (!context.mounted) return;
    final ctrl = context.read<SpotlightController>();
    if (ctrl.isActive || ctrl.externalBusy) return;
    final progression = context.read<ProgressionProvider>();
    if (progression.activeHabits.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    if (prefs.getString(_prefsKey) == todayKey) return;
    if (!context.mounted) return;
    if (ctrl.isActive || ctrl.externalBusy) return;
    await prefs.setString(_prefsKey, todayKey);

    ctrl.setExternalBusy(true);
    try {
      await _show(context);
    } finally {
      ctrl.setExternalBusy(false);
      if (context.mounted) {
        context.read<TutorialProvider>().retryQueueIfIdle(context);
      }
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> _show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DailyObjectivesSheet(),
    );
  }
}

class _DailyObjectivesSheet extends StatelessWidget {
  const _DailyObjectivesSheet();

  bool _doneToday(ProgressionProvider progression, String habitId) {
    final last = progression.stateOf(habitId)?.lastCompletedAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final progression = context.watch<ProgressionProvider>();
    final habits = [
      ...progression.activeHabits.where((h) => h.id == 'water'),
      ...progression.activeHabits.where((h) => h.id != 'water'),
    ];
    final doneCount = habits.where((h) => _doneToday(progression, h.id)).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: p.textMut.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    s.dailyObjectivesTitle,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.text),
                  ),
                ),
                Text(
                  s.dailyObjectivesSub(doneCount, habits.length),
                  style: TextStyle(fontSize: 12, color: p.textSec),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final h = habits[i];
                  final isWater = h.id == 'water';
                  return _ObjectiveRow(
                    habit: h,
                    habitName: s.habitName(h.id),
                    goalLabel: habitGoalLabel(
                      s,
                      progression.daysCompletedFor(h.id),
                      todayCount: isWater ? progression.todayWaterCount : null,
                      todayTarget:
                          isWater ? progression.todayWaterTarget : null,
                    ),
                    done: _doneToday(progression, h.id),
                    p: p,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.btn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(s.confirm,
                    style: TextStyle(
                        color: p.btnText, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  final HabitDefinition habit;
  final String habitName;
  final String goalLabel;
  final bool done;
  final BwPaletteData p;

  const _ObjectiveRow({
    required this.habit,
    required this.habitName,
    required this.goalLabel,
    required this.done,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 62,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: done
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply),
              child: Image.asset(habit.imageAsset,
                  fit: BoxFit.cover,
                  alignment: habit.imageAlignment,
                  errorBuilder: (_, __, ___) => Container(color: p.bg2)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: done ? 0.78 : 0.72),
                    Colors.black.withValues(alpha: done ? 0.62 : 0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? p.primary : Colors.transparent,
                      border: done
                          ? null
                          : Border.all(color: Colors.white70, width: 1.6),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habitName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  if (!done && habit.points > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⭐ +${habit.points}',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
