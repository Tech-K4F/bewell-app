import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/companion/companion_widget.dart';
import '../../widgets/debug_panel.dart';
import '../../widgets/habits/habit_intro_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _waterCount = 0;
  int _waterTargetN = 8;
  int _containerMl = 250;
  String _containerType = 'glass'; // 'glass' | 'bottle'
  String _wellyName = 'Welly';
  bool _showWorkBanner = false;
  bool _slowdownDismissed = false;
  // Persistito in prefs come 'never_miss_twice_dismissed_date' (YYYY-M-D)
  // così sopravvive alle ricreazioni del widget quando si cambia tab.
  String _neverMissTwiceDismissedDate = '';
  ProgressionProvider? _progressionRef;
  WellyMood _wellyMood = WellyMood.calm;
  Timer? _drinkTimer;
  // ── Water cooldown + undo ─────────────────────────────────────────────────
  bool _waterCooldownActive = false;
  Timer? _waterCooldownTimer;
  DateTime? _lastGlassAddedAt; // null se non sono stati aggiunti bicchieri (o dopo undo)
  int? _lastGlassPoints;        // punti dell'ultimo bicchiere (per rimuoverli in undo)
  // 2 minuti: abbastanza per evitare tap accidentali rapidi,
  // non così lungo da bloccare chi vuole davvero aggiungere un bicchiere.
  static const _cooldownDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    // Ascolta ProgressionProvider per ricaricare quando debug simulate/reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progressionRef = context.read<ProgressionProvider>()
        ..addListener(_loadData);
      // Prima valutazione sblocchi dell'app (una volta al giorno)
      context.read<ProgressionProvider>().evaluateIfNewDay();
      // Tutorial: prima apertura home (scheduleTrigger riprova se init() non è ancora completo)
      context.read<TutorialProvider>().scheduleTrigger('home_first_open', context);
    });
  }

  @override
  void dispose() {
    _drinkTimer?.cancel();
    _waterCooldownTimer?.cancel();
    _progressionRef?.removeListener(_loadData);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── WellyMood —————————————————————————————————————————————————————————————
  WellyMood _getCurrentMood(int waterCount, bool allHabitsDone, int hour) {
    if (allHabitsDone) return WellyMood.radiant;
    if (hour >= 22) return WellyMood.resting;
    if (hour >= 20 && waterCount == 0) return WellyMood.wondering;
    if (waterCount >= 4) return WellyMood.engaged;
    if (waterCount >= 1) return WellyMood.present;
    if (hour < 10) return WellyMood.welcoming;
    return WellyMood.calm;
  }

  void _updateMood(bool allHabitsDone) {
    if (!mounted) return;
    final mood = _getCurrentMood(_waterCount, allHabitsDone, DateTime.now().hour);
    if (mood != _wellyMood) setState(() => _wellyMood = mood);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      // Valuta sblocchi solo al primo resume della giornata (non ad ogni completion)
      if (mounted) {
        context.read<ProgressionProvider>().evaluateIfNewDay();
      }
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final savedDate = prefs.getString('water_date') ?? '';
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (savedDate != todayStr) {
      await prefs.setString('water_date', todayStr);
      await prefs.setInt('water_count', 0);
    }
    // Salva data primo lancio se non esiste ancora
    if (!prefs.containsKey('app_first_launch_date')) {
      await prefs.setString('app_first_launch_date', todayStr);
    }
    final firstLaunchStr = prefs.getString('app_first_launch_date') ?? todayStr;
    final firstLaunch = DateTime.tryParse(firstLaunchStr.replaceAll('-', '/')) ?? today;
    final appDay = today.difference(DateTime(firstLaunch.year, firstLaunch.month, firstLaunch.day)).inDays + 1;

    final userType = prefs.getString('user_type') ?? 'worker';
    final scheduleConfirmed = prefs.getBool('work_schedule_confirmed') ?? false;

    // ── Ripristino cooldown acqua ─────────────────────────────────────────
    final cooldownUntilMs = prefs.getInt('water_cooldown_until') ?? 0;
    final cooldownUntil = DateTime.fromMillisecondsSinceEpoch(cooldownUntilMs);
    final cooldownActive = cooldownUntil.isAfter(DateTime.now());

    // Ripristino data/punti ultimo bicchiere (per undo)
    final lastGlassMs = prefs.getInt('water_last_glass_at') ?? 0;
    final lastGlassAt = lastGlassMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastGlassMs)
        : null;
    final lastGlassPts = prefs.getInt('water_last_glass_pts');
    final neverMissDismissed = prefs.getString('never_miss_twice_dismissed_date') ?? '';

    if (mounted) {
      setState(() {
        _waterCount = prefs.getInt('water_count') ?? 0;
        _wellyName = prefs.getString('welly_name') ?? 'Welly';
        _waterTargetN = prefs.getInt('water_target_n') ?? 8;
        _containerMl = prefs.getInt('water_container_ml') ?? 250;
        _neverMissTwiceDismissedDate = neverMissDismissed;
        _containerType = prefs.getString('water_container_type') ?? 'glass';
        _showWorkBanner = userType == 'worker' && !scheduleConfirmed && appDay >= 2;
        _waterCooldownActive = cooldownActive;
        _lastGlassAddedAt = lastGlassAt;
        _lastGlassPoints = lastGlassPts;
      });

      // Avvia timer per la parte di cooldown rimasta (se ancora attivo)
      if (cooldownActive) {
        _waterCooldownTimer?.cancel();
        final remaining = cooldownUntil.difference(DateTime.now());
        _waterCooldownTimer = Timer(remaining, () {
          if (mounted) setState(() => _waterCooldownActive = false);
        });
      }
    }
  }

  Future<void> _dismissWorkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('work_schedule_confirmed', true);
    setState(() => _showWorkBanner = false);
  }

  void _openWorkScheduleSheet(BuildContext ctx, BwPaletteData p) {
    final schedule = context.read<ScheduleProvider>().schedule;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkScheduleSheet(
        p: p,
        initial: schedule,
        onSave: (s) async {
          await context.read<ScheduleProvider>().setSchedule(s);
          await _dismissWorkBanner();
        },
      ),
    );
  }

  Future<void> _addWater() async {
    if (_waterCount >= _waterTargetN) return;
    if (_waterCooldownActive) return; // cooldown attivo
    // Tutorial: primo bicchiere → mostra il dialogo del tracker acqua
    if (_waterCount == 0 && mounted) {
      context.read<TutorialProvider>().trigger('water_tracker_first', context);
    }
    final prefs = await SharedPreferences.getInstance();
    final newCount = _waterCount + 1;

    // ── Punti progressivi per questo bicchiere ─────────────────────────────
    final pts = AppProvider.waterGlassPoints(newCount, _waterTargetN);
    final now = DateTime.now();
    final cooldownUntil = now.add(_cooldownDuration);

    setState(() {
      _waterCount = newCount;
      _wellyMood = WellyMood.drinking; // animazione bicchiere
      _waterCooldownActive = true;
      _lastGlassAddedAt = now;
      _lastGlassPoints = pts;
    });
    AnalyticsService.instance.logWaterAdded(newCount, _waterTargetN);
    AnalyticsService.instance.logWellyMoodShown('drinking');
    // Salva su prefs: cooldown, conta bicchieri, info undo
    await prefs.setInt('water_count', newCount);
    await prefs.setInt('water_cooldown_until', cooldownUntil.millisecondsSinceEpoch);
    await prefs.setInt('water_last_glass_at', now.millisecondsSinceEpoch);
    await prefs.setInt('water_last_glass_pts', pts);

    if (mounted) {
      await context.read<AppProvider>().awardWaterGlass(pts);
    }

    // Timer che aggiorna l'UI quando scade il cooldown
    _waterCooldownTimer?.cancel();
    _waterCooldownTimer = Timer(_cooldownDuration, () {
      if (mounted) setState(() => _waterCooldownActive = false);
    });

    // Dopo 2s torna al mood normale
    _drinkTimer?.cancel();
    _drinkTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final done = newCount >= _waterTargetN;
      final nextMood = done
          ? WellyMood.radiant
          : _getCurrentMood(newCount, false, DateTime.now().hour);
      setState(() => _wellyMood = nextMood);
      AnalyticsService.instance.logWellyMoodShown(nextMood.name);
    });

    // Completamento: aggiorna streak/sessioni (punti già assegnati per-bicchiere)
    if (newCount >= _waterTargetN && mounted) {
      AnalyticsService.instance.logWaterGoalReached();
      // Tutorial: prima abitudine completata (anche via acqua)
      context.read<TutorialProvider>().scheduleTrigger('first_completion', context);
      await context.read<ProgressionProvider>().markCompleted('water');
      if (mounted) {
        await context.read<AppProvider>().completeActivity('water');
      }
    }
  }

  /// Annulla l'ultimo bicchiere — solo entro 2 minuti dall'aggiunta,
  /// solo se l'acqua non è stata già completata.
  Future<void> _undoGlass() async {
    if (_waterCount <= 0) return;
    if (_lastGlassAddedAt == null) return;
    final elapsed = DateTime.now().difference(_lastGlassAddedAt!);
    if (elapsed.inMinutes >= 2) return;
    // Non si può annullare se l'acqua è già completata (streak/sessione già registrate)
    if (_isWaterDoneToday(context.read<ProgressionProvider>())) return;

    final prefs = await SharedPreferences.getInstance();
    final newCount = _waterCount - 1;
    final ptsToRemove = _lastGlassPoints ?? 0;

    setState(() {
      _waterCount = newCount;
      _lastGlassAddedAt = null;
      _lastGlassPoints = null;
      _waterCooldownActive = false;
    });
    _waterCooldownTimer?.cancel();
    await prefs.setInt('water_count', newCount);
    await prefs.remove('water_cooldown_until');
    await prefs.remove('water_last_glass_at');
    await prefs.remove('water_last_glass_pts');

    // Rimuovi i punti dell'ultimo bicchiere
    if (mounted && ptsToRemove > 0) {
      await context.read<AppProvider>().removeWaterGlassPoints(ptsToRemove);
    }
  }

  Future<void> _saveContainerSettings(String type, int ml) async {
    final n = (2000 / ml).ceil();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_container_type', type);
    await prefs.setInt('water_container_ml', ml);
    await prefs.setInt('water_target_n', n);
    AnalyticsService.instance.logWaterContainerChanged(type, ml);
    if (mounted) {
      setState(() {
        _containerType = type;
        _containerMl = ml;
        _waterTargetN = n;
      });
    }
  }

  void _openWaterSettings(BuildContext ctx, BwPaletteData p) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaterSettingsSheet(
        containerType: _containerType,
        containerMl: _containerMl,
        p: p,
        onSave: _saveContainerSettings,
      ),
    );
  }

  String _waterContextualText(BwStrings s) {
    if (_waterCount == 0) return s.waterZero;
    final fraction = _waterTargetN > 0 ? _waterCount / _waterTargetN : 0.0;
    if (fraction < 0.31) return s.waterLow;
    if (fraction < 0.61) return s.waterMid;
    if (fraction < 1.0) return s.waterMid; // "Quasi — ancora poco." verrà da TASK 2
    return s.waterDone;
  }

  bool _isWaterDoneToday(ProgressionProvider progression) {
    final last = progression.stateOf('water')?.lastCompletedAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProgressionProvider>(
      builder: (context, theme, progression, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final user = context.watch<AppProvider>().user;
        final s = context.sL;
        final message = progression.getLocalizedMessage(s);
        final phase = progression.currentPhase;
        final nextHabit = progression.nextHabitToUnlock;
        final pendingPair = progression.pendingChoicePair;
        final isWaterDone = _isWaterDoneToday(progression);

        // Aggiorna mood Welly (solo se non c'è animazione drink in corso)
        if (_wellyMood != WellyMood.drinking && _wellyMood != WellyMood.radiant) {
          final allHabitsDone = progression.activeHabits.isNotEmpty &&
              progression.activeHabits.every((h) {
                final last = progression.stateOf(h.id)?.lastCompletedAt;
                if (last == null) return false;
                final now = DateTime.now();
                return last.year == now.year && last.month == now.month && last.day == now.day;
              });
          final computed = _getCurrentMood(_waterCount, allHabitsDone || isWaterDone, DateTime.now().hour);
          if (computed != _wellyMood) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _wellyMood = computed);
            });
          }
        }

        return BwScaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, isAmb ? 80 : 24, 20, 32),
              children: [

                // ── Greeting ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.goodMorning,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: p.textSec,
                            ),
                          ),
                          Text(
                            user?.name ?? _wellyName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              color: p.text,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${s.phase} $phase',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Fumetto Welly ────────────────────────────────────
                if (message.isNotEmpty)
                  _WellySpeechBubble(message: message, p: p, isAmb: isAmb),

                const SizedBox(height: 16),

                // ── Banner rallentamento automatico ──────────────────
                if (progression.needsSlowdown &&
                    !progression.isSlowdownActive &&
                    !_slowdownDismissed) ...[
                  _SlowdownBanner(
                    p: p,
                    s: s,
                    onYes: () async {
                      await progression.applySlowdown();
                      setState(() => _slowdownDismissed = true);
                    },
                    onNo: () => setState(() => _slowdownDismissed = true),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Banner "never miss twice" (James Clear) ──────────
                // Mostrato quando ieri E oggi non ci sono completamenti.
                // Scopo: intervento gentile prima che il secondo skip diventi abitudine.
                // Dismissione persistita in prefs per sopravvivere ai tab switch.
                if (user != null &&
                    context.watch<AppProvider>().shouldShowNeverMissTwiceBanner &&
                    _waterCount == 0 &&
                    _neverMissTwiceDismissedDate != '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}') ...[
                  _NeverMissTwiceBanner(
                    p: p,
                    onAddWater: () async {
                      final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('never_miss_twice_dismissed_date', todayStr);
                      if (mounted) setState(() => _neverMissTwiceDismissedDate = todayStr);
                      _addWater();
                    },
                    onDismiss: () async {
                      final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('never_miss_twice_dismissed_date', todayStr);
                      if (mounted) setState(() => _neverMissTwiceDismissedDate = todayStr);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Companion ────────────────────────────────────────
                Center(
                  child: DebugTrigger(
                    child: CompanionWidget(
                      size: 180,
                      mood: _wellyMood,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _Divider(p: p),
                const SizedBox(height: 20),

                // ── Banner orario (solo worker, giorno 2) ────────────
                if (_showWorkBanner) ...[
                  _WorkScheduleBanner(
                    p: p,
                    s: s,
                    onConfirm: _dismissWorkBanner,
                    onEdit: () => _openWorkScheduleSheet(context, p),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Tracker acqua ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.waterToday,
                      style: TextStyle(
                        fontSize: isAmb ? 18 : 16,
                        fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                        color: p.text,
                        fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
                        letterSpacing: isAmb ? 1 : 0,
                      ),
                    ),
                    Text(
                      '$_waterCount / $_waterTargetN ${s.waterGlasses}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isWaterDone ? p.primary : p.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Testo contestuale Welly
                Text(
                  _waterContextualText(s),
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSec,
                    fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 10),
                // Barra fluida 8px
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _waterTargetN > 0
                        ? (_waterCount / _waterTargetN).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: p.bg2,
                    color: isWaterDone ? p.primary : p.accent,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                // ── Pulsante principale bicchiere ─────────────────────────
                if (isWaterDone)
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.primary, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: p.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          s.waterDone,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _waterCooldownActive ? null : _addWater,
                    child: AnimatedOpacity(
                      opacity: _waterCooldownActive ? 0.55 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: p.btn,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _waterCooldownActive ? s.waterCooldown : s.addGlass,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: p.btnText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Pulsanti secondari: annulla + contenitore ─────────────
                if (!isWaterDone) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Annulla ultimo bicchiere (entro 2 minuti)
                      Expanded(
                        child: Builder(builder: (ctx) {
                          final canUndo = _lastGlassAddedAt != null &&
                              DateTime.now().difference(_lastGlassAddedAt!).inMinutes < 2 &&
                              !isWaterDone;
                          return GestureDetector(
                            onTap: canUndo ? _undoGlass : null,
                            child: AnimatedOpacity(
                              opacity: canUndo ? 1.0 : 0.35,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: p.textMut.withValues(alpha: 0.4), width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    s.waterUndo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.textSec,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      // Impostazioni contenitore
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openWaterSettings(context, p),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.textMut.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Center(
                              child: Text(
                                '${s.waterContainerBtn} · ${_containerMl}ml',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.textSec,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                _Divider(p: p),
                const SizedBox(height: 20),

                // ── Stats ────────────────────────────────────────────
                Row(
                  children: [
                    _StatPill(
                      emoji: '🔥',
                      label: '${user?.streak ?? 0} ${s.daysStreak}',
                      p: p,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      emoji: '⭐',
                      label: '${user?.points ?? 0} ${s.points}',
                      p: p,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      emoji: progression.currentPhase >= 5 ? '💚' : '🌱',
                      label: '${progression.totalDaysCompleted} ${s.days}',
                      p: p,
                    ),
                  ],
                ),

                // ── Prossima abitudine ────────────────────────────────
                if (pendingPair != null || nextHabit != null) ...[
                  const SizedBox(height: 24),
                  _Divider(p: p),
                  const SizedBox(height: 20),
                  Text(
                    s.comingNext,
                    style: TextStyle(
                      fontSize: isAmb ? 16 : 13,
                      fontStyle: isAmb
                          ? FontStyle.italic
                          : FontStyle.normal,
                      fontWeight: isAmb
                          ? FontWeight.w300
                          : FontWeight.w600,
                      color: p.textSec,
                      letterSpacing: isAmb ? 1 : 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (pendingPair != null)
                    _PendingChoiceCard(pair: pendingPair, p: p, s: s)
                  else
                    _NextHabitPreview(
                      habit: nextHabit!,
                      p: p,
                      progression: progression,
                      s: s,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  final BwPaletteData p;
  const _Divider({required this.p});
  @override
  Widget build(BuildContext context) =>
      Divider(color: p.text.withValues(alpha: 0.07), height: 1);
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String label;
  final BwPaletteData p;
  const _StatPill({required this.emoji, required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: p.textSec,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _NextHabitPreview extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final ProgressionProvider progression;
  final BwStrings s;

  const _NextHabitPreview({
    required this.habit,
    required this.p,
    required this.progression,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = progression.daysUntilUnlock(habit.id);
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
                borderRadius: BorderRadius.circular(10),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                      Colors.grey, BlendMode.saturation),
                  child: Image.asset(
                    habit.imageAsset,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: p.bg2,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.bg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lock_outline,
                      color: p.textMut, size: 18),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.textSec,
                  ),
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

// ── Speech bubble Welly ───────────────────────────────────────────────────────
class _WellySpeechBubble extends StatelessWidget {
  final String message;
  final BwPaletteData p;
  final bool isAmb;
  const _WellySpeechBubble({required this.message, required this.p, required this.isAmb});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.primary.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: p.text,
              height: 1.6,
              fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Triangolino che punta verso il basso (verso Welly)
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _BubbleTailPainter(
              color: p.primaryLight,
              borderColor: p.primary.withValues(alpha: 0.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = borderColor);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
class _PendingChoiceCard extends StatelessWidget {
  final (HabitDefinition, HabitDefinition) pair;
  final BwPaletteData p;
  final BwStrings s;

  const _PendingChoiceCard({
    required this.pair,
    required this.p,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HabitIntroSheet.show(
        context,
        habitA: pair.$1,
        habitB: pair.$2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: p.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_outlined,
                  color: p.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.habitChoiceOpen,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.habitName(pair.$1.id)}  ·  ${s.habitName(pair.$2.id)}',
                    style: TextStyle(fontSize: 11, color: p.textSec),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Water Settings Sheet ──────────────────────────────────────────────────────
class _WaterSettingsSheet extends StatefulWidget {
  final String containerType;
  final int containerMl;
  final BwPaletteData p;
  final Future<void> Function(String type, int ml) onSave;

  const _WaterSettingsSheet({
    required this.containerType,
    required this.containerMl,
    required this.p,
    required this.onSave,
  });

  @override
  State<_WaterSettingsSheet> createState() => _WaterSettingsSheetState();
}

class _WaterSettingsSheetState extends State<_WaterSettingsSheet> {
  late String _type;
  late int _ml;

  static const _bottleSizes = [350, 500, 750, 1000];

  @override
  void initState() {
    super.initState();
    _type = widget.containerType;
    _ml = widget.containerMl;
  }

  int get _targetN => (2000 / _ml).ceil();

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: p.textMut,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            context.sL.waterContainerSettings,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 20),

          // Selezione tipo
          Row(
            children: [
              _TypeTab(
                emoji: '🥛',
                label: context.sL.waterContainerGlass,
                selected: _type == 'glass',
                p: p,
                onTap: () => setState(() {
                  _type = 'glass';
                  if (_ml > 400) _ml = 250;
                }),
              ),
              const SizedBox(width: 12),
              _TypeTab(
                emoji: '🫙',
                label: context.sL.waterContainerBottle,
                selected: _type == 'bottle',
                p: p,
                onTap: () => setState(() {
                  _type = 'bottle';
                  if (_ml < 350) _ml = 500;
                }),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_type == 'glass') ...[
            // Slider bicchiere 150-400ml step 50
            Text(
              'Dimensione: ${_ml}ml',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: p.primary,
                inactiveTrackColor: p.bg2,
                thumbColor: p.primary,
                overlayColor: p.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: _ml.toDouble(),
                min: 150,
                max: 400,
                divisions: 5, // (400-150)/50
                label: '${_ml}ml',
                onChanged: (v) => setState(() => _ml = (v / 50).round() * 50),
              ),
            ),
          ] else ...[
            // Scelta borraccia
            Text(
              'Dimensione',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text),
            ),
            const SizedBox(height: 10),
            Row(
              children: _bottleSizes.map((size) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _ml = size),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _ml == size ? p.primaryLight : p.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _ml == size ? p.primary : p.cardBorder,
                        width: _ml == size ? 1.5 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        size >= 1000 ? '1L' : '${size}ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _ml == size ? p.primaryText : p.textSec,
                        ),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],

          const SizedBox(height: 16),
          // Riepilogo obiettivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.bg2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.sL.waterGoalCalc.replaceFirst('N', '$_targetN'),
              style: TextStyle(fontSize: 12, color: p.textSec),
            ),
          ),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await widget.onSave(_type, _ml);
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: p.btn,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  context.sL.workScheduleSave,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.btnText),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner rallentamento ──────────────────────────────────────────────────────
class _SlowdownBanner extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _SlowdownBanner({
    required this.p,
    required this.s,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.slowdownPrompt,
            style: TextStyle(fontSize: 13, color: p.text, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onNo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.cardBorder, width: 0.5),
                  ),
                  child: Text(
                    s.slowdownNo,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.text),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onYes,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.slowdownYes,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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

// ── Banner orario ─────────────────────────────────────────────────────────────
class _WorkScheduleBanner extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const _WorkScheduleBanner({
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
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.cardBorder, width: 0.5),
                  ),
                  child: Text(
                    s.workScheduleEdit,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.text),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.workScheduleConfirm,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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

// ── Work Schedule Sheet ───────────────────────────────────────────────────────
class _WorkScheduleSheet extends StatefulWidget {
  final BwPaletteData p;
  final WorkSchedule initial;
  final Future<void> Function(WorkSchedule) onSave;

  const _WorkScheduleSheet({
    required this.p,
    required this.initial,
    required this.onSave,
  });

  @override
  State<_WorkScheduleSheet> createState() => _WorkScheduleSheetState();
}

class _WorkScheduleSheetState extends State<_WorkScheduleSheet> {
  late int _startMorning;
  late int _endMorning;
  late int _startAfternoon;
  late int _endAfternoon;
  late int _lunchHour;
  late int _lunchDuration;
  bool _hasLunch = true;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _startMorning   = s.startMorning;
    _endMorning     = s.endMorning;
    _startAfternoon = s.startAfternoon;
    _endAfternoon   = s.endAfternoon;
    _lunchHour      = s.lunchHour;
    _lunchDuration  = s.lunchDurationMin;
  }

  Future<void> _pickHour(BuildContext ctx, int current, ValueChanged<int> onPicked) async {
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

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = context.sL;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: p.textMut,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            s.workScheduleTitle,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 20),

          // Mattina
          Text(
            s.workScheduleMorning,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSec, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Inizio',
                  time: _fmt(_startMorning),
                  p: p,
                  onTap: () => _pickHour(context, _startMorning, (h) => setState(() => _startMorning = h)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeButton(
                  label: 'Fine',
                  time: _fmt(_endMorning),
                  p: p,
                  onTap: () => _pickHour(context, _endMorning, (h) => setState(() => _endMorning = h)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pomeriggio
          Text(
            s.workScheduleAfternoon,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSec, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Inizio',
                  time: _fmt(_startAfternoon),
                  p: p,
                  onTap: () => _pickHour(context, _startAfternoon, (h) => setState(() => _startAfternoon = h)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeButton(
                  label: 'Fine',
                  time: _fmt(_endAfternoon),
                  p: p,
                  onTap: () => _pickHour(context, _endAfternoon, (h) => setState(() => _endAfternoon = h)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pausa pranzo
          GestureDetector(
            onTap: () => setState(() => _hasLunch = !_hasLunch),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _hasLunch ? p.primary : p.card,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _hasLunch ? p.primary : p.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: _hasLunch
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  s.workScheduleLunch,
                  style: TextStyle(fontSize: 13, color: p.text, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          if (_hasLunch) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Orario',
                    time: _fmt(_lunchHour),
                    p: p,
                    onTap: () => _pickHour(context, _lunchHour, (h) => setState(() => _lunchHour = h)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        items: [30, 45, 60, 90].map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('${d} min'),
                        )).toList(),
                        onChanged: (v) => setState(() => _lunchDuration = v ?? 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () async {
              final schedule = WorkSchedule(
                startMorning: _startMorning,
                endMorning: _endMorning,
                startAfternoon: _startAfternoon,
                endAfternoon: _endAfternoon,
                lunchHour: _lunchHour,
                lunchDurationMin: _hasLunch ? _lunchDuration : 0,
              );
              await widget.onSave(schedule);
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: p.btn,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  s.workScheduleSave,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.btnText),
                ),
              ),
            ),
          ),
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
    return GestureDetector(
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
            Text(label, style: TextStyle(fontSize: 10, color: p.textMut, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner "never miss twice" ─────────────────────────────────────────────────
/// Mostrato quando l'utente non ha completato nulla né ieri né oggi.
/// Messaggio urgente ma gentile — CTA immediata all'azione più piccola possibile.
class _NeverMissTwiceBanner extends StatelessWidget {
  final BwPaletteData p;
  final VoidCallback onAddWater;
  final VoidCallback onDismiss;

  const _NeverMissTwiceBanner({
    required this.p,
    required this.onAddWater,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // amber chiaro
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.sL.neverMissTwiceTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 16, color: p.textMut),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.sL.neverMissTwiceBody,
            style: TextStyle(fontSize: 12, color: p.textSec, height: 1.4),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAddWater,
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  context.sL.neverMissTwiceCta,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final BwPaletteData p;
  final VoidCallback onTap;

  const _TypeTab({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? p.primaryLight : p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? p.primary : p.cardBorder,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? p.primaryText : p.textSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
