import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/habit_library.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/spotlight_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../focus/focus_screen.dart';
import '../stress/breathing_screen.dart';
import 'guided_habit_screen.dart';
import '../../data/habit_guides.dart';
import 'habit_calendar.dart';
import '../../providers/tutorial_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/banner_ad_widget.dart';

/// Etichetta del pulsante "avvia timer" per le abitudini con sessione guidata.
String _timerLabel(String habitId, BwStrings s) {
  switch (habitId) {
    case 'focus_50': return '▶ 50 min';
    case 'focus_25': return '▶ 25 min';
    case 'breathing_box':
    case 'breathing_478': return '▶ ${s.guideStart}';
    default: return HabitGuides.hasGuide(habitId) ? '▶ ${s.guideStart}' : '▶ 25 min';
  }
}

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // Timer per aggiornare titolo, ordinamento e calendario ogni minuto
  // sincronizzandosi con l'orologio reale del telefono.
  Timer? _clockTick;

  // Configuratore a 5 fasi: facoltativo, non più un passaggio obbligato
  // dell'onboarding. `null` = non ancora caricato da prefs.
  bool? _hasPersonalizedPlan;

  static const List<SpotlightStep> _habitsSpotlightSteps = [
    SpotlightStep(textId: 'habits_welcome'),
    SpotlightStep(textId: 'habits_now',  targetId: 'spot_now_card'),
    SpotlightStep(textId: 'habits_list', targetId: 'spot_habits_card'),
    SpotlightStep(textId: 'habits_ready'),
  ];

  @override
  void initState() {
    super.initState();
    _clockTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkHabitsSpotlight();
    });
    _loadPersonalizedPlanState();
  }

  Future<void> _loadPersonalizedPlanState() async {
    final prefs = await SharedPreferences.getInstance();
    final has = prefs.getString('questionnaire_answers') != null;
    if (mounted) setState(() => _hasPersonalizedPlan = has);
  }

  Future<void> _openConfigurator(BuildContext context) async {
    await Navigator.of(context).pushNamed('/onboarding');
    await _loadPersonalizedPlanState();
  }

  Future<void> _checkHabitsSpotlight() async {
    if (!mounted) return;
    final ctrl = context.read<SpotlightController>();
    final seen = await ctrl.hasSeenTutorial('habits_tour');
    if (!mounted) return;
    if (!seen) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) ctrl.startTutorial('habits_tour', _habitsSpotlightSteps);
      // Vedi commento equivalente in home_screen.dart: bisogna passare dal
      // TutorialProvider vero, non da un bool SharedPreferences che non
      // legge nessuno.
      if (mounted) {
        final tutorial = context.read<TutorialProvider>();
        await tutorial.markSeenExternally('habits_tab_first');
        await tutorial.markSeenExternally('habit_card_explain');
      }
    } else {
      if (mounted) {
        context.read<TutorialProvider>().scheduleTrigger('habits_tab_first', context);
      }
    }
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    super.dispose();
  }

  // ── Titolo dinamico per ora ───────────────────────────────────────────────
  static String _habitsTitle(BwStrings s, int hour) {
    if (hour < 10) return s.habitsMorningTitle;
    if (hour < 13) return s.habitsMiddayTitle;
    if (hour < 17) return s.habitsAfternoonTitle;
    return s.habitsEveningTitle;
  }

  // ── Fascia oraria dall'ora corrente ───────────────────────────────────────
  static TimeSlot _currentSlot(int hour) {
    if (hour < 10) return TimeSlot.morning;
    if (hour < 12) return TimeSlot.midday;
    if (hour < 14) return TimeSlot.lunch;
    if (hour < 18) return TimeSlot.afternoon;
    return TimeSlot.evening;
  }

  // ── Ordine numerico dei time slot ─────────────────────────────────────────
  static int _slotOrder(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:   return 0;
      case TimeSlot.midday:    return 1;
      case TimeSlot.lunch:     return 2;
      case TimeSlot.afternoon: return 3;
      case TimeSlot.evening:   return 4;
    }
  }

  // ── Ordine dinamico abitudini ─────────────────────────────────────────────
  // 1. Slot corrente, non completate
  // 2. Slot futuri, non completate (in ordine cronologico)
  // 3. Slot passati, non completate
  // 4. Completate oggi (in fondo)
  static List<HabitDefinition> _sortHabits(
    List<HabitDefinition> habits,
    ProgressionProvider progression,
    ScheduleProvider schedule,
    int hour,
  ) {
    final now = DateTime.now();
    final currentSlot = _currentSlot(hour);

    bool isDoneToday(HabitDefinition h) {
      final last = progression.stateOf(h.id)?.lastCompletedAt;
      if (last == null) return false;
      return last.year == now.year && last.month == now.month && last.day == now.day;
    }

    final done    = habits.where(isDoneToday).toList();
    final notDone = habits.where((h) => !isDoneToday(h)).toList();

    notDone.sort((a, b) {
      final sa = schedule.getTimeSlot(a);
      final sb = schedule.getTimeSlot(b);
      final oa = _slotOrder(sa);
      final ob = _slotOrder(sb);
      final curOrder = _slotOrder(currentSlot);

      // Priorità slot corrente
      final aCurrent = oa == _slotOrder(currentSlot) ? 0 : 1;
      final bCurrent = ob == _slotOrder(currentSlot) ? 0 : 1;
      if (aCurrent != bCurrent) return aCurrent - bCurrent;

      // Tra slot non correnti: slot futuri prima degli slot passati
      final aFuture = oa > curOrder ? 0 : 1;
      final bFuture = ob > curOrder ? 0 : 1;
      if (aFuture != bFuture) return aFuture - bFuture;

      return oa - ob;
    });

    return [...notDone, ...done];
  }

  // ── Etichetta fascia oraria (emoji + testo) ───────────────────────────────
  static (String, String) _slotLabel(TimeSlot slot, BwStrings s) {
    switch (slot) {
      case TimeSlot.morning:   return ('🌅', s.timeMorning);
      case TimeSlot.midday:    return ('☀️', s.timeMidday);
      case TimeSlot.lunch:     return ('🍃', s.timeLunch);
      case TimeSlot.afternoon: return ('🌤', s.timeAfternoon);
      case TimeSlot.evening:   return ('🌙', s.timeEvening);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, ProgressionProvider, AppProvider>(
      builder: (context, theme, progression, app, _) {
        final schedule = context.watch<ScheduleProvider>();
        final p = theme.paletteData;

        final isAmb = theme.isAmbient;
        final s = context.sL;
        final habits = progression.activeHabits;
        final hour = DateTime.now().hour;

        // Completati oggi
        final now = DateTime.now();
        final completedToday = habits.where((h) {
          final last = progression.stateOf(h.id)?.lastCompletedAt;
          if (last == null) return false;
          return last.year == now.year &&
              last.month == now.month &&
              last.day == now.day;
        }).length;

        // Lista ordinata
        final sorted = _sortHabits(habits, progression, schedule, hour);

        // Abitudine suggerita per adesso (non completate)
        final notDoneNow = habits.where((h) {
          final last = progression.stateOf(h.id)?.lastCompletedAt;
          final done = last != null &&
              last.year == now.year &&
              last.month == now.month &&
              last.day == now.day;
          return !done;
        }).toList();
        final habitForNow = schedule.getHabitForNow(notDoneNow, hour);

        // "In lista oggi": tutte le abitudini ESCLUSA quella in Card Adesso
        // (l'abitudine in Card Adesso appare solo lì, non duplicata nella lista)
        final listaOggi = habitForNow != null
            ? sorted.where((h) => h.id != habitForNow.id).toList()
            : sorted;

        // Abitudini in arrivo (locked, max 2)
        final comingUpHabits = HabitLibrary.all
            .where((h) => progression.statusOf(h.id) == HabitStatus.locked)
            .take(2)
            .toList();

        return BwScaffold(
          bottomNavigationBar: const BannerAdWidget(),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, isAmb ? 72 : 24, 20, 40),
              children: [

                // ── Titolo dinamico ───────────────────────────────────────
                Text(
                  _habitsTitle(s, hour),
                  style: TextStyle(
                    fontSize: isAmb ? 28 : 22,
                    fontWeight: isAmb ? FontWeight.w300 : FontWeight.w700,
                    fontFamily: isAmb ? 'CormorantGaramond' : null,
                    color: p.text,
                    letterSpacing: isAmb ? 1 : 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${habits.length} ${s.activeHabits.toLowerCase()} · $completedToday ${s.completedToday}',
                  style: TextStyle(fontSize: 13, color: p.textSec),
                ),

                const SizedBox(height: 20),

                // ── Card "Adesso" ─────────────────────────────────────────
                if (habitForNow != null) ...[
                  SpotlightTarget(
                    id: 'spot_now_card',
                    child: _NowCard(
                      habit: habitForNow,
                      daysCompleted: progression.daysCompletedFor(habitForNow.id),
                      schedule: schedule,
                      p: p,
                      s: s,
                      onComplete: habitForNow.id == 'water'
                          ? null
                          : () => _complete(context, habitForNow.id, progression, app),
                      onStartTimer: habitForNow.id == 'focus_25' || habitForNow.id == 'focus_50'
                          ? () => _openFocus(context, durationMinutes: habitForNow.id == 'focus_50' ? 50 : 25)
                          : habitForNow.id == 'breathing_box' || habitForNow.id == 'breathing_478'
                              ? () => _openBreathing(context, habitId: habitForNow.id)
                              : HabitGuides.hasGuide(habitForNow.id)
                                  ? () => _openGuided(context, habitId: habitForNow.id)
                                  : null,
                      slotLabelFn: (slot) => _slotLabel(slot, s),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── "In lista oggi" section label ─────────────────────────
                if (listaOggi.isNotEmpty) ...[
                  _SectionLabel(label: s.habitsToday, p: p),
                  const SizedBox(height: 12),
                ],

                // ── Lista abitudini (esclusa quella in Card Adesso) ────────
                if (habits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        s.waterZero,
                        style: TextStyle(fontSize: 14, color: p.textSec),
                      ),
                    ),
                  )
                else
                  ...listaOggi.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final h = entry.value;
                    final state = progression.stateOf(h.id);
                    final slot = schedule.getTimeSlot(h);
                    final card = GestureDetector(
                      onLongPress: h.id == 'water'
                          ? null
                          : () => _showSlowdownMenu(context, h, p, s),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HabitCard(
                          habit: h,
                          state: state,
                          p: p,
                          isAmb: isAmb,
                          s: s,
                          timeSlot: slot,
                          slotLabel: _slotLabel(slot, s),
                          onComplete: h.id == 'water'
                              ? null
                              : () => _complete(context, h.id, progression, app),
                          onStartTimer: h.id == 'focus_25' || h.id == 'focus_50'
                              ? () => _openFocus(context, durationMinutes: h.id == 'focus_50' ? 50 : 25)
                              : h.id == 'breathing_box' || h.id == 'breathing_478'
                                  ? () => _openBreathing(context, habitId: h.id)
                                  : HabitGuides.hasGuide(h.id)
                                      ? () => _openGuided(context, habitId: h.id)
                                      : null,
                        ),
                      ),
                    );
                    return idx == 0
                        ? SpotlightTarget(id: 'spot_habits_card', child: card)
                        : card;
                  }),

                // ── Calendario giornaliero (visibile quando focus_25 sbloccato) ──
                if (habits.isNotEmpty &&
                    progression.statusOf('focus_25') != HabitStatus.locked) ...[
                  const SizedBox(height: 24),
                  Divider(color: p.text.withValues(alpha: 0.07), height: 1),
                  const SizedBox(height: 20),
                  const HabitCalendar(),
                  // Tutorial: calendario apparso per la prima volta
                  Builder(builder: (_) {
                    context.read<TutorialProvider>()
                        .scheduleTrigger('calendar_appears', context);
                    return const SizedBox.shrink();
                  }),
                ],

                // ── Configuratore facoltativo (dal primo sblocco reale) ─────
                // Non più un passaggio obbligato dell'onboarding: appare qui,
                // dopo il calendario, una volta che l'utente ha sbloccato
                // almeno un'abitudine oltre quelle di partenza — a quel punto
                // ha già visto come funziona l'app ed è pronto a raccontarle
                // qualcosa di più su di sé per ricevere suggerimenti mirati.
                if (_hasPersonalizedPlan != null &&
                    habits.any((h) => !h.isStarter)) ...[
                  const SizedBox(height: 20),
                  _ConfiguratorCard(
                    p: p,
                    s: s,
                    completed: _hasPersonalizedPlan!,
                    onTap: () => _openConfigurator(context),
                  ),
                ],

                // ── In arrivo (locked, max 2) ──────────────────────────────
                if (comingUpHabits.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(label: s.habitsComingSoon, p: p),
                  const SizedBox(height: 12),
                  ...comingUpHabits.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LockedHabitTile(habit: h, p: p, s: s),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _complete(
    BuildContext context,
    String habitId,
    ProgressionProvider progression,
    AppProvider app,
  ) async {
    // Tutorial: prima abitudine completata — schedulato prima degli await
    // (scheduleTrigger usa postFrameCallback, sicuro anche con async successivi)
    context.read<TutorialProvider>().scheduleTrigger('first_completion', context);
    await progression.markCompleted(habitId);
    await app.completeHabit(habitId);

    // ── Welly Bonus (variable ratio reward) ──────────────────────────────────
    if (app.lastCompletionWasBonus && context.mounted) {
      final loc = context.sL;
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
                      loc.wellyBonusTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      loc.wellyBonusBody,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D7D46),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openBreathing(BuildContext context, {required String habitId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BreathingScreen(habitId: habitId),
      ),
    );
  }

  void _openGuided(BuildContext context, {required String habitId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedHabitScreen(habitId: habitId),
      ),
    );
  }

  void _openFocus(BuildContext context, {int durationMinutes = 25}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusScreen(durationMinutes: durationMinutes),
      ),
    );
  }

  void _showSlowdownMenu(
    BuildContext context,
    HabitDefinition habit,
    BwPaletteData p,
    BwStrings s,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlowdownMenuSheet(
        habit: habit,
        p: p,
        s: s,
        onSlowdown: () async {
          AnalyticsService.instance.logSlowdownRequested(habit.id);
          await context.read<ProgressionProvider>().applySlowdown();
          if (context.mounted) Navigator.pop(context);
          if (context.mounted) {
            _showSlowdownResponse(context, p, s);
          }
        },
      ),
    );
  }

  void _showSlowdownResponse(BuildContext context, BwPaletteData p, BwStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: p.textMut,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🤝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              s.slowdownWellyResponse,
              style: TextStyle(
                fontSize: 15,
                color: p.text,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: p.btn,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Ok',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.btnText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card "Adesso" ─────────────────────────────────────────────────────────────
class _NowCard extends StatelessWidget {
  final HabitDefinition habit;
  final int daysCompleted;
  final ScheduleProvider schedule;
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback? onComplete;
  final VoidCallback? onStartTimer;
  final (String, String) Function(TimeSlot) slotLabelFn;

  const _NowCard({
    required this.habit,
    required this.daysCompleted,
    required this.schedule,
    required this.p,
    required this.s,
    required this.slotLabelFn,
    this.onComplete,
    this.onStartTimer,
  });

  bool get _isWater => habit.id == 'water';

  Color _arcColor(BwPaletteData p) {
    if (_isWater) return p.accent;
    if (habit.id.startsWith('focus')) return p.primary;
    if (habit.id.contains('breath') || habit.id == 'meditation') return p.primary;
    return p.primary;
  }

  @override
  Widget build(BuildContext context) {
    final slot = schedule.getTimeSlot(habit);
    final (slotEmoji, slotText) = slotLabelFn(slot);
    final arcColor = _arcColor(p);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                s.habitsNowLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '$slotEmoji $slotText',
                style: TextStyle(fontSize: 11, color: p.textSec),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contenuto
          Row(
            children: [
              // Arco 48px (giorni di QUESTA abitudine)
              _HabitArc(
                daysCompleted: daysCompleted,
                color: arcColor,
                size: 48,
              ),
              const SizedBox(width: 12),

              // Nome + descrizione
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.habitName(habit.id),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.habitDesc(habit.id),
                      style: TextStyle(fontSize: 12, color: p.textSec),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Pulsante azione
              if (_isWater)
                Icon(Icons.water_drop_outlined, color: p.primary, size: 26)
              else if (onStartTimer != null)
                GestureDetector(
                  onTap: onStartTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _timerLabel(habit.id, s),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.habitMarkDone,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Habit Card ────────────────────────────────────────────────────────────────
class _HabitCard extends StatelessWidget {
  final HabitDefinition habit;
  final HabitState? state;
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  final TimeSlot timeSlot;
  final (String, String) slotLabel;   // (emoji, testo)
  final VoidCallback? onComplete;
  final VoidCallback? onStartTimer;

  const _HabitCard({
    required this.habit,
    required this.state,
    required this.p,
    required this.isAmb,
    required this.s,
    required this.timeSlot,
    required this.slotLabel,
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
    final (slotEmoji, slotText) = slotLabel;

    return AnimatedOpacity(
      opacity: done ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
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
            // Immagine hero
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
                            0,      0,      0,      1, 0,
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

                // Overlay completata
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

                // Badge fascia oraria — top-left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Badge(text: '$slotEmoji $slotText'),
                      if (_isWater) ...[
                        const SizedBox(height: 4),
                        _Badge(text: '💧 ${s.waterTrackedInHome}'),
                      ],
                    ],
                  ),
                ),

                // Streak badge — top-right
                if (days > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _Badge(text: '🔥 $days ${s.days}'),
                  ),
              ],
            ),

            // Info + action
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  // Arco 40px (giorni di questa abitudine specifica)
                  _HabitArc(
                    daysCompleted: days,
                    color: _isWater ? p.accent : p.primary,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
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
                          // Usa la descrizione localizzata (BwStrings) — coachDaily è in italiano.
                          done ? '✓ ${s.completedToday}' : s.habitDesc(habit.id),
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
                          _timerLabel(habit.id, s),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.btnText),
                        ),
                      ),
                    )
                  else if (onStartTimer != null && done)
                    Icon(Icons.check_circle_rounded, color: p.primary, size: 28)
                  else
                    GestureDetector(
                      onTap: done ? null : onComplete,
                      child: Container(
                        width: 36, height: 36,
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

// ── Menu rallentamento (long press su card) ───────────────────────────────────
class _SlowdownMenuSheet extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback onSlowdown;

  const _SlowdownMenuSheet({
    required this.habit,
    required this.p,
    required this.s,
    required this.onSlowdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: p.textMut,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            s.habitName(habit.id),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 6),
          // Il rallentamento non è per-abitudine: mette in pausa TUTTE le
          // nuove proposte per 2 settimane. Prima questo non era spiegato
          // da nessuna parte e il menu (aperto da una singola card) lasciava
          // credere il contrario.
          Text(
            s.slowdownMenuSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textSec, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SlowdownOption(
            emoji: '⏸',
            label: s.slowdownHabitMenu,
            p: p,
            onTap: onSlowdown,
          ),
          const SizedBox(height: 10),
          _SlowdownOption(
            emoji: '😮‍💨',
            label: s.slowdownReasonHeavy,
            p: p,
            onTap: onSlowdown,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: TextStyle(fontSize: 14, color: p.textMut),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlowdownOption extends StatelessWidget {
  final String emoji;
  final String label;
  final BwPaletteData p;
  final VoidCallback onTap;

  const _SlowdownOption({
    required this.emoji,
    required this.label,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge generico ────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Arco progresso abitudine ──────────────────────────────────────────────────
/// Mostra i giorni completati dell'abitudine specifica verso la prossima fase.
/// NON mostra la fase globale di Welly.
class _HabitArc extends StatelessWidget {
  final int daysCompleted;
  final Color color;
  final double size;

  const _HabitArc({
    required this.daysCompleted,
    required this.color,
    required this.size,
  });

  /// Range [from, to] della milestone corrente.
  /// Il progresso si calcola come (days - from) / (to - from),
  /// così l'arco non "salta indietro" al passaggio di soglia.
  static (int, int) _milestone(int days) {
    if (days < 7)  return (0, 7);   // Prima settimana
    if (days < 21) return (7, 21);  // Tre settimane
    if (days < 66) return (21, 66); // 66 giorni (habit formation)
    return (66, 90);                // Maestria
  }

  @override
  Widget build(BuildContext context) {
    final (from, to) = _milestone(daysCompleted);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          days: daysCompleted,
          fromMilestone: from,
          toMilestone: to,
          color: color,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int days;
  final int fromMilestone;
  final int toMilestone;
  final Color color;

  const _ArcPainter({
    required this.days,
    required this.fromMilestone,
    required this.toMilestone,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeW = 3.5;

    // Anello di sfondo
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Arco progresso nel range della milestone corrente
    if (days > 0) {
      final range = (toMilestone - fromMilestone).toDouble();
      final progress = ((days - fromMilestone) / range).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Numero giorni al centro
    final tp = TextPainter(
      text: TextSpan(
        text: '$days',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.days != days ||
      old.fromMilestone != fromMilestone ||
      old.toMilestone != toMilestone ||
      old.color != color;
}

// ── Section Label ─────────────────────────────────────────────────────────────
// ── Configurator Card ─────────────────────────────────────────────────────────
/// Invito facoltativo a compilare il questionario di personalizzazione:
/// appare dopo il calendario, solo dopo il primo sblocco reale.
class _ConfiguratorCard extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  final bool completed;
  final VoidCallback onTap;
  const _ConfiguratorCard({
    required this.p,
    required this.s,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed ? p.cardBorder : p.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (completed ? p.primary : p.accent).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.tune_rounded : Icons.auto_awesome_rounded,
                color: completed ? p.primary : p.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed ? s.configuratorDoneTitle : s.configuratorTitle,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completed ? s.configuratorDoneSubtitle : s.configuratorSubtitle,
                    style: TextStyle(fontSize: 12, color: p.textSec),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMut, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _SectionLabel({required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: p.textSec,
      ),
    );
  }
}

// ── Locked Habit Tile ─────────────────────────────────────────────────────────
/// Card compatta per un'abitudine ancora bloccata ("In arrivo").
class _LockedHabitTile extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final BwStrings s;

  const _LockedHabitTile({
    required this.habit,
    required this.p,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          // Immagine desaturata con lucchetto
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey, BlendMode.saturation,
                  ),
                  child: Image.asset(
                    habit.imageAsset,
                    width: 44, height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: p.bg2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.bg.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_outline, color: p.textMut, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.habitName(habit.id),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.textSec,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.habitDesc(habit.id),
                  style: TextStyle(fontSize: 11, color: p.textMut),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: p.textMut.withValues(alpha: 0.4), size: 14),
        ],
      ),
    );
  }
}
