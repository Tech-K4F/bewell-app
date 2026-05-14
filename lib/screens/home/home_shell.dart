import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit_library.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/badge_toast.dart';
import '../../widgets/habits/habit_intro_sheet.dart';
import '../../providers/tutorial_provider.dart';
import '../home/home_screen.dart';
import '../habits/habits_screen.dart';
import '../growth/growth_screen.dart';
import '../profile/profile_screen.dart';

enum NavItem { home, habits, growth, profile }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  ProgressionProvider? _progressionRef;
  AppProvider? _appRef;
  bool _introShowing = false;
  /// Chiave dell'ultima coppia mostrata: previene il re-show se l'utente
  /// chiude il foglio senza scegliere (pendingChoicePair rimane non-null).
  String? _lastShownPairKey;
  Set<String> _knownActiveIds = {};
  int _knownPhase = 1;
  bool _knownFocusUnlocked = false;
  int _knownStreak = -1; // -1 = not yet seeded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.setForeground(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progressionRef = context.read<ProgressionProvider>()
        ..addListener(_onProgressionChange);
      _appRef = context.read<AppProvider>()
        ..addListener(_onAppChange);
      // Seed known IDs to avoid spurious notifications on first load
      _knownActiveIds =
          _progressionRef!.activeHabits.map((h) => h.id).toSet();
      // Seed known phase + focus state so we don't fire on first load
      _knownPhase = _progressionRef!.currentPhase;
      _knownFocusUnlocked =
          _progressionRef!.activeHabits.any((h) => h.id == 'focus_25');
      // _knownStreak = -1 → primo _checkStreakTutorials lo inizializzerà senza sparare
      _onProgressionChange();
      // Controlla inattività al primo avvio (una tantum — TutorialProvider deduplica)
      _checkInactivityTutorial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.setForeground(false);
    _progressionRef?.removeListener(_onProgressionChange);
    _appRef?.removeListener(_onAppChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        NotificationService.instance.setForeground(true);
        // Controlla se l'utente è stato inattivo 3+ giorni al ritorno in app
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkInactivityTutorial();
        });
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        NotificationService.instance.setForeground(false);
      case AppLifecycleState.inactive:
        break; // transient state, keep current value
    }
  }

  // ── Listener callbacks ────────────────────────────────────────────────────

  void _onProgressionChange() {
    _checkPendingChoice();
    _checkNewHabits();
    _checkProgressionTutorials();
  }

  void _onAppChange() {
    _checkNewBadges();
    _checkStreakTutorials();
  }

  // ── Tutorial: progressione fase + focus unlock ────────────────────────────

  void _checkProgressionTutorials() {
    if (!mounted) return;
    final progression = context.read<ProgressionProvider>();
    final tutorial = context.read<TutorialProvider>();

    // Sblocco fase
    final phase = progression.currentPhase;
    if (phase > _knownPhase) {
      _knownPhase = phase;
      if (phase >= 2 && phase <= 5) {
        final eventId = 'phase${phase}_reached';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) tutorial.trigger(eventId, context);
        });
      }
    }

    // Sblocco Focus 25
    final focusNowUnlocked =
        progression.activeHabits.any((h) => h.id == 'focus_25');
    if (focusNowUnlocked && !_knownFocusUnlocked) {
      _knownFocusUnlocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tutorial.trigger('focus_unlocked', context);
      });
    }
  }

  // ── Tutorial: streak (rotto + milestone + settimana perfetta) ───────────────

  void _checkStreakTutorials() {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    final tutorial = context.read<TutorialProvider>();
    final prev = _knownStreak;
    final curr = app.user?.streak ?? 0;

    // Prima esecuzione: inizializza senza sparare trigger
    if (prev < 0) {
      _knownStreak = curr;
      return;
    }

    // Streak azzerata: utente ha saltato un giorno
    if (prev > 0 && curr == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tutorial.trigger('streak_broken', context);
      });
    }

    // Milestone: 7, 21, 66 giorni consecutivi
    for (final days in [7, 21, 66]) {
      if (prev < days && curr >= days) {
        final eventId = 'milestone_${days}_days';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) tutorial.trigger(eventId, context);
        });
      }
    }

    // Settimana perfetta: streak appena diventato ≥ 7
    // Accodiamo con 800 ms di ritardo perché milestone_7_days va prima
    if (prev < 7 && curr >= 7) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) tutorial.trigger('perfect_week', context);
      });
    }

    _knownStreak = curr;
  }

  // ── Tutorial: inattività 3+ giorni ───────────────────────────────────────

  void _checkInactivityTutorial() {
    if (!mounted) return;
    final progression = context.read<ProgressionProvider>();
    final tutorial = context.read<TutorialProvider>();

    // Cerca l'ultima data di completamento fra tutte le abitudini attive
    DateTime? lastCompletion;
    for (final habit in progression.activeHabits) {
      final dt = progression.stateOf(habit.id)?.lastCompletedAt;
      if (dt != null &&
          (lastCompletion == null || dt.isAfter(lastCompletion))) {
        lastCompletion = dt;
      }
    }

    if (lastCompletion == null) return; // Utente non ha mai completato nulla

    final daysSince = DateTime.now().difference(lastCompletion).inDays;
    if (daysSince >= 3) {
      AnalyticsService.instance.logReturnAfterAbsence(daysSince);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tutorial.trigger('no_completion_3days', context);
      });
    }
  }

  // ── Popup scelta coppia ───────────────────────────────────────────────────

  void _checkPendingChoice() {
    if (!mounted || _introShowing) return;
    final pair = context.read<ProgressionProvider>().pendingChoicePair;
    if (pair == null) {
      _lastShownPairKey = null; // coppia accettata → reset per la prossima
      return;
    }
    // Chiave stabile che identifica la coppia corrente.
    final pairKey = '${pair.$1.id}__${pair.$2.id}';
    // Se questa coppia è già stata mostrata (e l'utente ha chiuso senza scegliere),
    // non la mostriamo di nuovo automaticamente — resta visibile nella home come card.
    if (pairKey == _lastShownPairKey) return;
    _introShowing = true;
    _lastShownPairKey = pairKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HabitIntroSheet.show(
        context,
        habitA: pair.$1,
        habitB: pair.$2,
        onHabitChosen: (habitId) {
          // Usa il contesto dello shell (sempre valido) e rimanda al frame
          // successivo così il popup appare DOPO che lo sheet si è chiuso.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<TutorialProvider>()
                  .scheduleTrigger('habit_chosen_$habitId', context);
            }
          });
        },
      ).then((_) {
        if (mounted) setState(() => _introShowing = false);
      });
    });
  }

  // ── Notifica nuove abitudini sbloccate ────────────────────────────────────

  void _checkNewHabits() {
    if (!mounted) return;
    final progression = context.read<ProgressionProvider>();
    final currentIds = progression.activeHabits.map((h) => h.id).toSet();
    final newIds = currentIds.difference(_knownActiveIds);
    _knownActiveIds = currentIds;

    for (final id in newIds) {
      if (id == 'water') continue; // starter, no notification
      final habit = HabitLibrary.all.where((h) => h.id == id).firstOrNull;
      if (habit == null || !mounted) continue;
      BwBanner.showHabitUnlock(
        context,
        emoji: _habitEmoji(id),
        habitName: context.sL.habitName(id),
        coachIntro: context.sL.habitDesc(id),
      );
    }
  }

  // ── Notifica nuovi badge ──────────────────────────────────────────────────

  void _checkNewBadges() {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    final badges = List<String>.from(app.newlyEarnedBadges);
    if (badges.isEmpty) return;
    app.clearNewBadges();
    for (final badgeId in badges) {
      BwBanner.showBadge(context, badgeId);
    }
  }

  // ── Emoji per habit unlock toast ──────────────────────────────────────────

  static String _habitEmoji(String habitId) {
    const map = {
      'focus_25': '⏱',
      'neck_stretch': '🧘',
      'postura': '🪑',
      'breathing_box': '🌬',
      'walk_lunch': '🚶',
      'desk_exercise': '💪',
      'water_morn': '🌅',
      'stretching_active': '🤸',
      'lunch_park': '🌳',
      'breathing_478': '🌬',
      'focus_50': '🎯',
      'meditation': '🧘',
      'sleep_routine': '🌙',
      'nap': '😴',
    };
    return map[habitId] ?? '✨';
  }

  // ── Navigazione con analytics ─────────────────────────────────────────────

  void _onNavTap(int i) {
    const tabNames = ['home', 'habits', 'growth', 'profile'];
    final tabName = tabNames[i.clamp(0, tabNames.length - 1)];
    AnalyticsService.instance.logTabOpened(tabName);
    if (i == 2 && _progressionRef != null) {
      AnalyticsService.instance.logGrowthScreenOpened(
        _progressionRef!.totalDaysCompleted,
        _progressionRef!.currentPhase,
      );
    }
    _appRef?.setNavIndex(i);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProvider, ThemeProvider, ProgressionProvider>(
      builder: (context, app, theme, progression, _) {
        final p = theme.paletteData;
        final tabs = _buildTabs(context, progression);
        final screens = _buildScreens(progression);
        final currentIndex = app.currentNavIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          backgroundColor: p.bg,
          body: screens[currentIndex],
          bottomNavigationBar: _ProgressiveNavBar(
            tabs: tabs,
            currentIndex: currentIndex,
            p: p,
            onTap: _onNavTap,
          ),
        );
      },
    );
  }

  // Habits si sblocca quando focus_25 è attivo (dopo 3 giorni di acqua)
  // Growth si sblocca con 14 completamenti totali (≈ 1 settimana con 2 abitudini)
  bool _habitsUnlocked(ProgressionProvider p) =>
      p.activeHabits.any((h) => h.id == 'focus_25');

  bool _growthUnlocked(ProgressionProvider p) =>
      p.totalDaysCompleted >= 14;

  List<_NavTab> _buildTabs(BuildContext context, ProgressionProvider progression) {
    final s = context.sL;
    return [
      const _NavTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        item: NavItem.home,
        available: true,
      ),
      _NavTab(
        icon: Icons.timer_outlined,
        activeIcon: Icons.timer_rounded,
        item: NavItem.habits,
        available: _habitsUnlocked(progression),
        unlockHint: s.navUnlockHabitsMsg,
      ),
      _NavTab(
        icon: Icons.spa_outlined,
        activeIcon: Icons.spa_rounded,
        item: NavItem.growth,
        available: _growthUnlocked(progression),
        unlockHint: s.navUnlockGrowthMsg,
      ),
      const _NavTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        item: NavItem.profile,
        available: true,
      ),
    ];
  }

  List<Widget> _buildScreens(ProgressionProvider progression) {
    return [
      const HomeScreen(),
      _habitsUnlocked(progression)
          ? const HabitsScreen()
          : const _ComingSoonScreen(item: NavItem.habits),
      _growthUnlocked(progression)
          ? const GrowthScreen()
          : const _ComingSoonScreen(item: NavItem.growth),
      const ProfileScreen(),
    ];
  }
}

// ── Tab data ──────────────────────────────────────────────────────────────────
class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final NavItem item;
  final bool available;
  final String? unlockHint;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.item,
    required this.available,
    this.unlockHint,
  });
}

// ── Nav Bar progressiva ───────────────────────────────────────────────────────
class _ProgressiveNavBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int currentIndex;
  final BwPaletteData p;
  final ValueChanged<int> onTap;

  const _ProgressiveNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.nav,
        border: Border(top: BorderSide(color: p.navBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = i == currentIndex;
              final isAvailable = tab.available;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isAvailable) {
                      onTap(i);
                    } else {
                      _showUnlockHint(context, tab);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    opacity: isAvailable ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: isActive ? p.primary : p.textMut,
                            ),
                            if (!isAvailable)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: p.bg2,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: p.cardBorder, width: 0.5),
                                  ),
                                  child: Icon(Icons.lock_outline,
                                      size: 8, color: p.textMut),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _translateLabel(context, tab.item),
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? p.primary : p.textMut,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? p.primary : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _translateLabel(BuildContext context, NavItem item) {
    final s = context.sL;
    switch (item) {
      case NavItem.home:    return s.navHome;
      case NavItem.habits:  return s.navHabits;
      case NavItem.growth:  return s.navGrowth;
      case NavItem.profile: return s.navProfile;
    }
  }

  void _showUnlockHint(BuildContext context, _NavTab tab) {
    if (tab.unlockHint == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tab.unlockHint!),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Coming Soon ───────────────────────────────────────────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final NavItem item;
  const _ComingSoonScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;

    final isHabits = item == NavItem.habits;
    final title = isHabits ? s.navHabits : s.navGrowth;
    final subtitle = isHabits ? s.comingSoonHabitsDesc : s.comingSoonGrowthDesc;
    final emoji = isHabits ? '⏱' : '🌱';

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: p.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: p.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 15, color: p.textSec, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: p.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: p.primary),
                      const SizedBox(width: 6),
                      Text(
                        s.lockedForNow,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: p.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
