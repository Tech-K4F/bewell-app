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
import '../../widgets/habit_consolidated_dialog.dart';
import '../../widgets/badge_unlocked_dialog.dart';
import '../../widgets/mission_start_dialog.dart';
import '../../widgets/streak_milestone_dialog.dart';
import '../../providers/tutorial_provider.dart';
import '../home/home_screen.dart';
import '../habits/habits_screen.dart';
import '../growth/growth_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/spotlight_overlay.dart';
import '../../providers/schedule_provider.dart';
import '../../services/smart_reminders.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/focus_recovery.dart';

enum NavItem { home, habits, growth, marketplace, profile }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  ProgressionProvider? _progressionRef;
  AppProvider? _appRef;
  ScheduleProvider? _scheduleRef;
  bool _introShowing = false;

  /// Aggiorna [_introShowing] e specchia lo stato su [SpotlightController],
  /// così TutorialProvider.trigger() vede questi popup a schermo intero e
  /// non ci si accavalla sopra (successo qui il giorno 1 di un'abitudine:
  /// il dialog "first_completion" e il badge "primo passo" scattano nello
  /// stesso istante, uno da questo file e uno dal motore tutorial).
  void _setIntroShowing(bool value) {
    _introShowing = value;
    if (!mounted) return;
    final ctrl = context.read<SpotlightController>();
    ctrl.setExternalBusy(value);
    if (!value) context.read<TutorialProvider>().retryQueueIfIdle(context);
  }

  /// Chiave dell'ultima coppia mostrata: previene il re-show se l'utente
  /// chiude il foglio senza scegliere (pendingChoicePair rimane non-null).
  String? _lastShownPairKey;
  Set<String> _knownActiveIds = {};
  int _knownPhase = 1;
  int _knownStreak = -1; // -1 = not yet seeded
  /// key delle famiglie badge (ProgressionProvider.allBadges) già maxate —
  /// seminato al primo caricamento, poi diffato per mostrare il toast solo
  /// quando una famiglia raggiunge il suo livello più alto proprio ora.
  /// Solo "maxed" (non ogni singolo livello): quando un livello intermedio
  /// (es. bronzo) viene appena raggiunto, la tile mostrata da allBadges()
  /// punta già al livello SUCCESSIVO da sbloccare — un toast in quel momento
  /// mostrerebbe il nome/emoji del livello sbagliato.
  Set<String> _knownMaxedBadgeKeys = {};
  // Evita popup di fase/sblocco al primo caricamento (progression.init() è asincrono
  // e il seeding iniziale avviene prima che gli stati siano caricati da prefs).
  bool _progressionSeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.setForeground(true);
    CloudSyncService.instance.startAutoSync();
    NotificationService.instance.tapRoute.addListener(_onNotifRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onNotifRoute();
      FocusRecovery.completeIfFinished(context);
      _progressionRef = context.read<ProgressionProvider>()
        ..addListener(_onProgressionChange);
      _appRef = context.read<AppProvider>()..addListener(_onAppChange);
      // Cambio orari di lavoro / tipo utente → ripianifica i promemoria subito,
      // non solo quando l'app va in background.
      _scheduleRef = context.read<ScheduleProvider>()
        ..addListener(_refreshSmartReminders);
      // NON seminare qui: progression.init() è ancora in corso (asincrono) e _states
      // è vuoto → currentPhase = 1 anche se l'utente è già a fase 3.
      // Il seeding reale avviene in _onProgressionChange() al primo isInitialized=true.
      // _knownStreak = -1 → primo _checkStreakTutorials lo inizializzerà senza sparare.
      // Controlla inattività al primo avvio (una tantum — TutorialProvider deduplica)
      _checkInactivityTutorial();
      context.read<SpotlightController>().loadCompanionName();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.setForeground(false);
    _progressionRef?.removeListener(_onProgressionChange);
    _appRef?.removeListener(_onAppChange);
    _scheduleRef?.removeListener(_refreshSmartReminders);
    CloudSyncService.instance.stopAutoSync();
    NotificationService.instance.tapRoute.removeListener(_onNotifRoute);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        NotificationService.instance.setForeground(true);
        // Rivaluta i nuovi sblocchi al resume — qui, non solo in
        // HomeScreen.didChangeAppLifecycleState, perché HomeShell mostra un
        // solo screen alla volta (non un IndexedStack): se l'utente torna in
        // app mentre è su Habits/Growth/Marketplace/Profile, HomeScreen non
        // esiste nell'albero e il suo observer non riceve questo evento —
        // la valutazione giornaliera restava bloccata finché non si tornava
        // manualmente sul tab Home. evaluateIfNewDay() è dedup'd per data,
        // quindi chiamarla anche da HomeScreen.initState() resta innocuo.
        if (_progressionRef != null) {
          _progressionRef!.evaluateIfNewDay();
        }
        // Controlla se l'utente è stato inattivo 3+ giorni al ritorno in app
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkInactivityTutorial();
          if (mounted) FocusRecovery.completeIfFinished(context);
        });
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        NotificationService.instance.setForeground(false);
        _refreshSmartReminders();
        CloudSyncService.instance.pushIfChanged();
      case AppLifecycleState.inactive:
        break; // transient state, keep current value
    }
  }

  // ── Listener callbacks ────────────────────────────────────────────────────

  void _onProgressionChange() {
    if (!mounted) return;
    final prog = context.read<ProgressionProvider>();
    // Prima notifica dopo il completamento di init(): ri-seminare i valori noti
    // con i dati reali (prima del completamento init, _states è vuoto → fase = 1).
    // Senza questo, qualunque fase > 1 provocherebbe un popup fasullo all'avvio.
    if (!_progressionSeeded && prog.isInitialized) {
      _progressionSeeded = true;
      _knownPhase = prog.currentPhase;
      _knownActiveIds = prog.activeHabits.map((h) => h.id).toSet();
      _knownMaxedBadgeKeys = prog
          .allBadges(context.sL)
          .where((b) => b.isMaxed)
          .map((b) => b.key)
          .toSet();
      return; // Non sparare alcun popup/toast sul primo caricamento
    }
    _checkConsolidationCelebration(prog);
    _refreshSmartReminders();
  }

  /// Aggiorna il piano dei promemoria (cosa è attivo, cosa è già fatto oggi):
  /// ripianifica solo se qualcosa è davvero cambiato.
  void _refreshSmartReminders() {
    if (!mounted) return;
    SmartReminders.refresh(
      context.read<ProgressionProvider>(),
      context.read<ScheduleProvider>(),
    );
  }

  // ── Celebrazione consolidamento ───────────────────────────────────────────
  // Mostrata PRIMA di proporre una nuova abitudine: il traguardo va
  // festeggiato per sé, non liquidato come passo intermedio verso la
  // prossima cosa da fare.
  void _checkConsolidationCelebration(ProgressionProvider prog) {
    final pending = prog.nextConsolidationToCelebrate;
    if (pending == null) {
      _afterConsolidationChecks();
      return;
    }
    final (habitId, isAutomatic) = pending;
    if (_introShowing || context.read<SpotlightController>().isActive) {
      return; // riproverà al prossimo notifyListeners()
    }
    _setIntroShowing(true);
    // Sappiamo già, prima di mostrare la celebrazione, se subito dopo si
    // aprirà la scelta della prossima abitudine — il CTA del dialog lo
    // anticipa invece di lasciare che il foglio arrivi come un salto
    // scollegato dal momento appena vissuto.
    final hasNextChoice = prog.pendingChoicePair != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _setIntroShowing(false);
        return;
      }
      final pts = isAutomatic ? pointsForAutomatic : pointsForConsolidation;
      await context.read<AppProvider>().addPoints(pts);
      if (!mounted) {
        _setIntroShowing(false);
        return;
      }
      await HabitConsolidatedDialog.show(context, habitId,
          points: pts, isAutomatic: isAutomatic, hasNextChoice: hasNextChoice);
      prog.consumeNextConsolidation();
      if (!mounted) return;
      _setIntroShowing(false);
      _afterConsolidationChecks();
    });
  }

  void _afterConsolidationChecks() {
    _checkPendingChoice();
    _checkNewHabits();
    _checkProgressionTutorials();
    _checkNewBadges();
    // Ripetuto ad ogni cambio di stato: si autocorregge se una missione
    // (es. Focus appena sbloccato con un salto giorni da debug) fosse
    // sfuggita al primo giro invece di restare persa per sempre.
    MissionStartDialog.checkPending(context);
  }

  void _onAppChange() {
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

    // Sblocco Focus 25 — l'annuncio "nuova missione" è gestito centralmente
    // da MissionStartDialog.checkPending (chiamato da _afterConsolidationChecks
    // ad ogni cambio di stato, non solo sulla transizione): qui resta solo
    // la spiegazione scientifica del Pomodoro, che TutorialProvider.trigger()
    // mostra comunque una volta sola (si autoprotegge via _seen).
    final focusNowUnlocked =
        progression.activeHabits.any((h) => h.id == 'focus_25');
    if (focusNowUnlocked) {
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
    final curr = app.liveStreak;

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

    // Milestone: 7, 21, 66 giorni consecutivi — celebrazione a schermo
    // intero (coriandoli), non il dialog Welly piatto usato per il resto
    // dei tutorial: è un motore di ritorno a sé, va sentito come tale.
    for (final days in [7, 21, 66]) {
      if (prev < days && curr >= days) {
        final eventId = 'milestone_${days}_days';
        if (tutorial.hasSeen(eventId)) continue;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (_introShowing || context.read<SpotlightController>().isActive) {
            // Un'altra celebrazione è già a schermo — non perdere l'evento,
            // mostralo con il dialog standard invece di accodare a tempo indefinito.
            tutorial.trigger(eventId, context);
            return;
          }
          _setIntroShowing(true);
          await StreakMilestoneDialog.show(context, days);
          await tutorial.markSeenExternally(eventId);
          if (mounted) _setIntroShowing(false);
        });
      }
    }

    // Nota: perfect_week non viene triggerato qui perché coinciderebbe esattamente con
    // milestone_7_days (stesso evento: streak che raggiunge 7).
    // perfect_week è riservato a un futuro tracciamento di "7/7 abitudini in una settimana".

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
    if (!mounted ||
        _introShowing ||
        context.read<SpotlightController>().isActive) {
      return;
    }
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
    _setIntroShowing(true);
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
              context
                  .read<TutorialProvider>()
                  .scheduleTrigger('habit_chosen_$habitId', context);
            }
          });
        },
      ).then((_) {
        if (mounted) _setIntroShowing(false);
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
    final progression = context.read<ProgressionProvider>();
    final s = context.sL;
    final newlyMaxed = <BadgeInfo>[];
    for (final b in progression.allBadges(s)) {
      final justMaxed = b.isMaxed && !_knownMaxedBadgeKeys.contains(b.key);
      if (b.isMaxed) _knownMaxedBadgeKeys.add(b.key);
      if (justMaxed) newlyMaxed.add(b);
    }
    if (newlyMaxed.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showBadgeCelebrations(newlyMaxed);
    });
  }

  /// Mostra le celebrazioni una alla volta: prima erano toast impilabili
  /// senza ricompensa, ora sono popup a schermo intero che assegnano punti
  /// reali, quindi più badge sbloccati nello stesso istante vanno in coda
  /// invece che accavallarsi.
  Future<void> _showBadgeCelebrations(List<BadgeInfo> badges) async {
    for (final b in badges) {
      if (!mounted) return;
      // Un dialog Welly del motore tutorial può scattare nello stesso
      // istante (es. "first_completion" e il badge "primo passo" sparano
      // entrambi al primo giorno completato) — senza controllare anche
      // isActive qui, i due popup si accavallavano a schermo.
      final tutorialActive = context.read<SpotlightController>().isActive;
      if (_introShowing || tutorialActive) {
        // Un'altra celebrazione occupa già lo schermo: non perdere il
        // badge, avvisane con il toast leggero invece di bloccare la coda.
        BwBanner.showBadge(context,
            emoji: b.emoji, title: b.name, subtitle: b.description);
        continue;
      }
      _setIntroShowing(true);
      final pts = pointsForBadge(b);
      await context.read<AppProvider>().addPoints(pts);
      if (!mounted) return;
      await BadgeUnlockedDialog.show(context, b, points: pts);
      if (mounted) _setIntroShowing(false);
    }
  }

  // ── Emoji per habit unlock toast ──────────────────────────────────────────

  static String _habitEmoji(String habitId) {
    const map = {
      'focus_25': '⏱',
      'neck_stretch': '🧘',
      'posture': '🪑',
      'breathing_box': '🌬',
      'walk_lunch': '🚶',
      'desk_exercise': '💪',
      'water_morning': '🌅',
      'stretching_active': '🤸',
      'lunch_park': '🌳',
      'breathing_478': '🌬',
      'focus_50': '🎯',
      'meditation': '🧘',
      'sleep_routine': '🌙',
      'nap': '😴',
      'snack': '🍎',
      'lunch_no_screen': '📵',
      'focus_no_phone': '🔇',
      'stairs': '🪜',
      'wake_consistent': '⏰',
    };
    return map[habitId] ?? '✨';
  }

  // ── Navigazione con analytics ─────────────────────────────────────────────

  /// Notifica toccata: porta alla schermata giusta (es. `tab:habits`).
  void _onNotifRoute() {
    final route = NotificationService.instance.tapRoute.value;
    if (route == null || !mounted) return;
    NotificationService.instance.tapRoute.value = null;
    final idx = switch (route) {
      'tab:home' => 0,
      'tab:habits' => 1,
      'tab:growth' => 2,
      'tab:market' => 3,
      'tab:profile' => 4,
      _ => -1,
    };
    if (idx < 0) return;
    final tabs = _buildTabs(context, context.read<ProgressionProvider>());
    if (tabs[idx].available) _onNavTap(idx);
  }

  void _onNavTap(int i) {
    const tabNames = ['home', 'habits', 'growth', 'marketplace', 'profile'];
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

        return SpotlightOverlay(
          child: Scaffold(
            backgroundColor: p.bg,
            body: screens[currentIndex],
            bottomNavigationBar: SpotlightTarget(
              id: 'spot_nav',
              child: _ProgressiveNavBar(
                tabs: tabs,
                currentIndex: currentIndex,
                p: p,
                onTap: _onNavTap,
              ),
            ),
          ),
        );
      },
    );
  }

  // Habits si sblocca quando focus_25 è attivo (dopo 14 giorni di acqua)
  // Growth si sblocca con 14 completamenti totali (≈ 1 settimana con 2 abitudini)
  bool _habitsUnlocked(ProgressionProvider p) =>
      p.activeHabits.any((h) => h.id == 'focus_25');

  bool _growthUnlocked(ProgressionProvider p) => p.totalDaysCompleted >= 14;

  List<_NavTab> _buildTabs(
      BuildContext context, ProgressionProvider progression) {
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
        icon: Icons.card_giftcard_outlined,
        activeIcon: Icons.card_giftcard_rounded,
        item: NavItem.marketplace,
        available: true,
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
      const MarketplaceScreen(),
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
    return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(1.0, 1.3)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: p.nav,
            border: Border(top: BorderSide(color: p.navBorder, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Row(
                children: tabs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tab = entry.value;
                  final isActive = i == currentIndex;
                  final isAvailable = tab.available;

                  return Expanded(
                    child: Semantics(
                        button: true,
                        selected: isActive,
                        container: true,
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
                            opacity: isAvailable ? 1.0 : 0.6,
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
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: p.bg2,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: p.cardBorder,
                                                width: 0.5),
                                          ),
                                          child: Icon(Icons.lock_outline,
                                              size: 10, color: p.textSec),
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
                                    color: isActive
                                        ? p.primary
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  );
                }).toList(),
              ),
            ),
          ),
        ));
  }

  String _translateLabel(BuildContext context, NavItem item) {
    final s = context.sL;
    switch (item) {
      case NavItem.home:
        return s.navHome;
      case NavItem.habits:
        return s.navHabits;
      case NavItem.growth:
        return s.navGrowth;
      case NavItem.marketplace:
        return s.navRewards;
      case NavItem.profile:
        return s.navProfile;
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
                  width: 80,
                  height: 80,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: p.text,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
