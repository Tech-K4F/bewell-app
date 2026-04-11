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
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _waterCount = 0;
  String _wellyName = 'Welly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
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
    setState(() {
      _waterCount = prefs.getInt('water_count') ?? 0;
      _wellyName = prefs.getString('welly_name') ?? 'Welly';
    });
  }

  Future<void> _addWater() async {
    if (_waterCount >= 8) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _waterCount++);
    await prefs.setInt('water_count', _waterCount);
    if (_waterCount >= 8 && mounted) {
      await context.read<ProgressionProvider>().markCompleted('water');
    }
  }

  Future<void> _removeWater() async {
    if (_waterCount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _waterCount--);
    await prefs.setInt('water_count', _waterCount);
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

                const SizedBox(height: 28),

                // ── Companion ────────────────────────────────────────
                Center(
                  child: DebugTrigger(
                    child: CompanionWidget(
                      size: 180,
                      mood: CompanionMood.idle,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Messaggio Welly ──────────────────────────────────
                if (message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: p.primary.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              color: p.text,
                              height: 1.55,
                              fontStyle: isAmb
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                _Divider(p: p),
                const SizedBox(height: 20),

                // ── Tracker acqua ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.waterToday,
                      style: TextStyle(
                        fontSize: isAmb ? 18 : 16,
                        fontWeight: isAmb
                            ? FontWeight.w300
                            : FontWeight.w600,
                        color: p.text,
                        fontStyle: isAmb
                            ? FontStyle.italic
                            : FontStyle.normal,
                        letterSpacing: isAmb ? 1 : 0,
                      ),
                    ),
                    Text(
                      '$_waterCount / 8',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _waterCount >= 8 ? p.primary : p.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _waterCount == 0
                      ? s.waterZero
                      : _waterCount < 4
                          ? s.waterLow
                          : _waterCount < 8
                              ? s.waterMid
                              : s.waterDone,
                  style: TextStyle(fontSize: 12, color: p.textSec),
                ),
                const SizedBox(height: 14),

                // Bicchieri
                Row(
                  children: List.generate(8, (i) {
                    final filled = i < _waterCount;
                    return Expanded(
                      child: GestureDetector(
                        onTap: filled ? _removeWater : _addWater,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 38,
                          decoration: BoxDecoration(
                            color: filled
                                ? p.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: filled
                                  ? p.accent
                                  : p.textSec.withValues(alpha: 0.25),
                              width: filled ? 0 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '💧',
                              style: TextStyle(
                                fontSize: filled ? 16 : 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _waterCount / 8,
                    backgroundColor: p.bg2,
                    color: _waterCount >= 8 ? p.primary : p.accent,
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 12),
                if (_waterCount < 8)
                  GestureDetector(
                    onTap: _addWater,
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        color: p.btn,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          s.addGlass,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: p.btnText,
                          ),
                        ),
                      ),
                    ),
                  ),

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
                if (nextHabit != null) ...[
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
                  _NextHabitPreview(
                    habit: nextHabit,
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
                  _habitName(habit.id, s),
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



String _habitName(String id, BwStrings s) {
  switch (id) {
    case 'water': return s.habitWaterName;
    case 'focus_25': return s.habitFocus25Name;
    case 'eyes_20_20_20': return s.habitEyes2020Name;
    case 'neck_stretch': return s.habitNeckName;
    case 'breathing_box': return s.habitBreathingBoxName;
    case 'walk_lunch': return s.habitWalkLunchName;
    case 'desk_exercise': return s.habitDeskExName;
    case 'water_morning': return s.habitWaterMornName;
    case 'posture': return s.habitPostureName;
    case 'lunch_park': return s.habitLunchParkName;
    case 'breathing_478': return s.habitBreathing478Name;
    case 'stretching_active': return s.habitStretchName;
    case 'snack': return s.habitSnackName;
    case 'lunch_no_screen': return s.habitLunchNoScreenName;
    case 'focus_50': return s.habitFocus50Name;
    case 'meditation': return s.habitMeditationName;
    case 'stairs': return s.habitStairsName;
    case 'sleep_routine': return s.habitSleepName;
    case 'wake_consistent': return s.habitWakeName;
    case 'nap': return s.habitNapName;
    case 'focus_no_phone': return s.habitFocusPhoneName;
    default: return id;
  }
}

String _habitCoachIntro(String id, BwStrings s) {
  // Usa il coachIntro localizzato per l'abitudine water
  // Le altre abitudini usano il testo di default dall'habit_library
  switch (id) {
    case 'water': return s.firstHabitBody1;
    default: return '';
  }
}



String _habitCoachDaily(String id, BwStrings s) {
  switch (id) {
    case 'water': return s.habitWaterDesc;
    case 'focus_25': return s.habitFocus25Desc;
    case 'eyes_20_20_20': return s.habitEyes2020Desc;
    case 'neck_stretch': return s.habitNeckDesc;
    case 'breathing_box': return s.habitBreathingBoxDesc;
    case 'walk_lunch': return s.habitWalkLunchDesc;
    case 'desk_exercise': return s.habitDeskExDesc;
    case 'water_morning': return s.habitWaterMornDesc;
    case 'posture': return s.habitPostureDesc;
    case 'lunch_park': return s.habitLunchParkDesc;
    case 'breathing_478': return s.habitBreathing478Desc;
    case 'stretching_active': return s.habitStretchDesc;
    case 'snack': return s.habitSnackDesc;
    case 'lunch_no_screen': return s.habitLunchNoScreenDesc;
    case 'focus_50': return s.habitFocus50Desc;
    case 'meditation': return s.habitMeditationDesc;
    case 'stairs': return s.habitStairsDesc;
    case 'sleep_routine': return s.habitSleepDesc;
    case 'wake_consistent': return s.habitWakeDesc;
    case 'nap': return s.habitNapDesc;
    case 'focus_no_phone': return s.habitFocusPhoneDesc;
    default: return '';
  }
}
