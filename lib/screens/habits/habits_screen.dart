import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/habit_library.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/companion/companion_widget.dart';
import '../../widgets/habits/habit_intro_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../focus/focus_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _guideShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGuide());
  }

  void _complete(String habitId) {
    final prog = context.read<ProgressionProvider>();
    prog.markCompleted(habitId);
    context.read<AppProvider>().completeActivity(habitId);
    if (!mounted) return;
    final s = context.sL;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.wellyBonusTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    s.wellyBonusBody,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _maybeShowGuide() {
    if (_guideShown || !mounted) return;
    _guideShown = true;
    final s = context.sL;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.habitsGuide,
            style: const TextStyle(fontSize: 13, height: 1.4)),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProgressionProvider>(
      builder: (context, theme, prog, _) {
        final p = theme.paletteData;
        final s = context.sL;
        final active = prog.activeHabits;

        final incomplete = active
            .where((h) => !prog.isCompletedToday(h.id))
            .toList()
          ..sort((a, b) => prog.daysCompletedFor(a.id)
              .compareTo(prog.daysCompletedFor(b.id)));
        final complete = active.where((h) => prog.isCompletedToday(h.id)).toList();

        final locked = _lockedSoon(prog);
        final pendingPair = prog.pendingChoicePair;
        final allDone = incomplete.isEmpty && complete.isNotEmpty;

        return BwScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Header ────────────────────────────────────────────────
                _HabitsHeader(
                  p: p,
                  isAmb: theme.isAmbient,
                  s: s,
                  allDone: allDone,
                  activeCount: active.length,
                  completeCount: complete.length,
                ),
                const SizedBox(height: 20),

                // ── Pending choice pair ────────────────────────────────────
                if (pendingPair != null)
                  _PendingChoiceBanner(
                    p: p,
                    s: s,
                    pair: pendingPair,
                    onTap: () => HabitIntroSheet.show(context,
                        habitA: pendingPair.$1, habitB: pendingPair.$2),
                  ),
                if (pendingPair != null) const SizedBox(height: 16),

                // ── Abitudini incomplete ───────────────────────────────────
                ...incomplete.map((h) => _HabitCard(
                  habit: h,
                  state: prog.stateOf(h.id),
                  p: p,
                  isAmb: theme.isAmbient,
                  s: s,
                  onComplete: h.id == 'water' ? null : () => _complete(h.id),
                  onStartTimer: h.id == 'focus_25'
                      ? () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FocusScreen()))
                      : null,
                )),

                // ── Abitudini completate oggi ──────────────────────────────
                if (complete.isNotEmpty) ...[
                  if (incomplete.isNotEmpty) const SizedBox(height: 4),
                  ...complete.map((h) => _HabitCard(
                    habit: h,
                    state: prog.stateOf(h.id),
                    p: p,
                    isAmb: theme.isAmbient,
                    s: s,
                    onComplete: null,
                    onStartTimer: null,
                  )),
                ],

                // ── Empty state ────────────────────────────────────────────
                if (active.isEmpty)
                  _EmptyState(p: p, s: s),

                // ── In arrivo ─────────────────────────────────────────────
                if (locked.isNotEmpty || pendingPair != null) ...[
                  const SizedBox(height: 8),
                  _SectionLabel(label: s.nextUnlock, p: p),
                  const SizedBox(height: 12),
                  ...locked.take(2).map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LockedCard(habit: h, p: p, s: s, prog: prog),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<HabitDefinition> _lockedSoon(ProgressionProvider prog) {
    return HabitLibrary.all
        .where((h) => prog.statusOf(h.id) == HabitStatus.locked)
        .toList()
      ..sort((a, b) =>
          prog.daysUntilUnlock(a.id).compareTo(prog.daysUntilUnlock(b.id)));
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HabitsHeader extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  final bool allDone;
  final int activeCount;
  final int completeCount;

  const _HabitsHeader({
    required this.p,
    required this.isAmb,
    required this.s,
    required this.allDone,
    required this.activeCount,
    required this.completeCount,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = allDone
        ? s.habitsAllDone
        : '$completeCount / $activeCount';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.activeHabits,
                style: TextStyle(
                  fontSize: isAmb ? 28 : 24,
                  fontWeight: isAmb ? FontWeight.w300 : FontWeight.w700,
                  fontFamily: isAmb ? 'CormorantGaramond' : null,
                  color: p.text,
                  letterSpacing: isAmb ? 1 : 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: allDone ? p.primary : p.textSec,
                  fontWeight: allDone ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (allDone)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: p.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('✓', style: TextStyle(color: p.primary, fontSize: 16)),
          ),
      ],
    );
  }
}

// ── Pending choice banner ─────────────────────────────────────────────────────
class _PendingChoiceBanner extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  final (HabitDefinition, HabitDefinition) pair;
  final VoidCallback onTap;

  const _PendingChoiceBanner({
    required this.p,
    required this.s,
    required this.pair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Text('✨', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.habitIntroSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.primary),
          ],
        ),
      ),
    );
  }
}

// ── Habit card ────────────────────────────────────────────────────────────────
class _HabitCard extends StatelessWidget {
  final HabitDefinition habit;
  final HabitState? state;
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  final VoidCallback? onComplete;
  final VoidCallback? onStartTimer;

  const _HabitCard({
    required this.habit,
    required this.state,
    required this.p,
    required this.isAmb,
    required this.s,
    this.onComplete,
    this.onStartTimer,
  });

  bool get _isWater => habit.id == 'water';
  bool get _isCompletedToday {
    final last = state?.lastCompletedAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final done = _isCompletedToday;
    final days = state?.daysCompleted ?? 0;
    return AnimatedOpacity(
      opacity: done ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? p.primary.withValues(alpha: 0.4) : p.cardBorder,
            width: done ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero image with overlay ───────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: ColorFiltered(
                    colorFilter: done
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
                    child: Image.asset(
                      habit.imageAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: p.primaryLight,
                        child: Icon(Icons.spa_outlined, color: p.primary, size: 40),
                      ),
                    ),
                  ),
                ),
                if (done)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 44),
                      ),
                    ),
                  ),
                if (days > 0)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            '$days ${s.days}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isWater)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.waterTrackedInHome,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            // ── Info + action ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.habitName(habit.id),
                          style: TextStyle(
                            fontSize: isAmb ? 17 : 15,
                            fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                            fontFamily: isAmb ? 'CormorantGaramond' : null,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          done ? '✓ ${s.waterDone}' : habit.description,
                          style: TextStyle(fontSize: 11, color: p.textSec),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isWater)
                    Icon(done ? Icons.water_drop : Icons.water_drop_outlined,
                        color: p.primary, size: 24)
                  else if (onStartTimer != null && !done)
                    GestureDetector(
                      onTap: onStartTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.btn,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '▶ 25 min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.btnText,
                          ),
                        ),
                      ),
                    )
                  else if (onStartTimer != null && done)
                    Icon(Icons.check_circle_rounded, color: p.primary, size: 28)
                  else
                    GestureDetector(
                      onTap: done ? null : onComplete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? p.primary : Colors.transparent,
                          border: Border.all(
                            color: done ? p.primary : p.textMut,
                            width: 1.5,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
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

// ── Locked card ───────────────────────────────────────────────────────────────
class _LockedCard extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final BwStrings s;
  final ProgressionProvider prog;

  const _LockedCard({
    required this.habit,
    required this.p,
    required this.s,
    required this.prog,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = prog.daysUntilUnlock(habit.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                      Colors.grey, BlendMode.saturation),
                  child: Image.asset(
                    habit.imageAsset,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: p.bg2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(habit.emoji,
                          style: const TextStyle(fontSize: 24))),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.bg.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock_outline, color: p.textMut, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _habitNameL(habit.id, s),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: p.textSec),
                ),
                const SizedBox(height: 3),
                Text(
                  daysLeft <= 0
                      ? s.almostReady
                      : daysLeft == 1
                          ? s.unlocksTomorrow
                          : '${s.unlocksIn} $daysLeft ${s.days}',
                  style: TextStyle(fontSize: 11, color: p.textMut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;

  const _EmptyState({required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CompanionWidget(size: 100, mood: CompanionMood.idle),
          const SizedBox(height: 20),
          Text(
            s.habitsGuide,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.textSec, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _SectionLabel({required this.label, required this.p});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: p.textSec,
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _habitNameL(String id, BwStrings s) {
  switch (id) {
    case 'water':             return s.habitWaterName;
    case 'focus_25':          return s.habitFocus25Name;
    case 'eyes_20_20_20':     return s.habitEyes2020Name;
    case 'neck_stretch':      return s.habitNeckName;
    case 'breathing_box':     return s.habitBreathingBoxName;
    case 'walk_lunch':        return s.habitWalkLunchName;
    case 'desk_exercise':     return s.habitDeskExName;
    case 'water_morning':     return s.habitWaterMornName;
    case 'posture':           return s.habitPostureName;
    case 'lunch_park':        return s.habitLunchParkName;
    case 'breathing_478':     return s.habitBreathing478Name;
    case 'stretching_active': return s.habitStretchName;
    case 'snack':             return s.habitSnackName;
    case 'lunch_no_screen':   return s.habitLunchNoScreenName;
    case 'focus_50':          return s.habitFocus50Name;
    case 'meditation':        return s.habitMeditationName;
    case 'stairs':            return s.habitStairsName;
    case 'sleep_routine':     return s.habitSleepName;
    case 'wake_consistent':   return s.habitWakeName;
    case 'nap':               return s.habitNapName;
    case 'focus_no_phone':    return s.habitFocusPhoneName;
    default:                  return id;
  }
}

