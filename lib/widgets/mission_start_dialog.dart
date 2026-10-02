import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/habit_library.dart';
import '../providers/theme_provider.dart';
import '../providers/progression_provider.dart';
import '../providers/tutorial_provider.dart';
import 'companion/companion_widget.dart';
import 'habit_progress_calendar.dart';
import 'spotlight_overlay.dart';

/// Annuncio a schermo intero di una nuova "missione" (prima abitudine da
/// fare, sblocco di una nuova attività) — prima questi momenti erano solo
/// testo descrittivo nella bolla del tutorial: informativo, ma mai sentito
/// come un vero "si comincia adesso, ufficialmente". Stessa famiglia visiva
/// delle celebrazioni (HabitConsolidatedDialog/BadgeUnlockedDialog), qui
/// usata per l'INIZIO invece che per il traguardo.
class MissionStartDialog {
  /// Controlla TUTTE le abitudini attive (acqua compresa) e annuncia quelle
  /// la cui missione non è ancora stata mostrata — usa lo stesso set "visti"
  /// persistito di TutorialProvider (chiave 'mission_<id>'), così la
  /// verifica è ripetibile e si autocorregge: prima un singolo flag in
  /// memoria (_knownFocusUnlocked) poteva perdere l'evento se lo sblocco
  /// avveniva mentre quel flag era già stato seminato come "visto" (es.
  /// salto giorni da debug), e l'annuncio spariva per sempre.
  /// Ritorna true se ha mostrato almeno un annuncio (il chiamante può così
  /// evitare di accodare subito un altro popup informativo).
  static Future<bool> checkPending(BuildContext context) async {
    var shown = false;
    if (!context.mounted) return false;
    final ctrl = context.read<SpotlightController>();
    if (ctrl.isActive || ctrl.externalBusy) {
      return false; // riprovato al prossimo giro
    }
    final progression = context.read<ProgressionProvider>();
    final tutorial = context.read<TutorialProvider>();

    final ordered = [
      ...progression.activeHabits.where((h) => h.id == 'water'),
      ...progression.activeHabits.where((h) => h.id != 'water'),
    ];

    for (final habit in ordered) {
      if (!context.mounted) return shown;
      final seenKey = 'mission_${habit.id}';
      if (tutorial.hasSeen(seenKey)) continue;
      if (ctrl.isActive || ctrl.externalBusy) return shown;
      await tutorial.markSeenExternally(seenKey);
      final s = context.sL;
      final isWater = habit.id == 'water';
      shown = true;
      ctrl.setExternalBusy(true);
      try {
        await show(
          context,
          habit: habit,
          daysCompleted: progression.daysCompletedFor(habit.id),
          todayCount: isWater ? progression.todayWaterCount : null,
          todayTarget: isWater ? progression.todayWaterTarget : null,
          streakNote: isWater ? s.missionStreakStart : null,
          mood: isWater ? WellyMood.welcoming : WellyMood.radiant,
        );
      } finally {
        ctrl.setExternalBusy(false);
      }
    }
    if (shown && context.mounted) {
      context.read<TutorialProvider>().retryQueueIfIdle(context);
    }
    return shown;
  }

  static Future<void> show(
    BuildContext context, {
    required HabitDefinition habit,
    required int daysCompleted,
    int? todayCount,
    int? todayTarget,
    String? streakNote,
    WellyMood mood = WellyMood.welcoming,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _MissionCard(
        habit: habit,
        daysCompleted: daysCompleted,
        todayCount: todayCount,
        todayTarget: todayTarget,
        streakNote: streakNote,
        mood: mood,
      ),
    );
  }
}

class _MissionCard extends StatefulWidget {
  final HabitDefinition habit;
  final int daysCompleted;
  final int? todayCount;
  final int? todayTarget;
  final String? streakNote;
  final WellyMood mood;
  const _MissionCard({
    required this.habit,
    required this.daysCompleted,
    this.todayCount,
    this.todayTarget,
    required this.mood,
    this.streakNote,
  });

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;

    return ScaleTransition(
      scale: _scale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: p.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.35),
                  blurRadius: 48,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HabitProgressCalendar(
                    habit: widget.habit,
                    daysCompleted: widget.daysCompleted,
                    todayCount: widget.todayCount,
                    todayTarget: widget.todayTarget,
                    heroAspectRatio: 2.1,
                    heroBadge: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.card.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.newMissionLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.primaryText,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    heroCompanion: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: p.card.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: p.primary.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Center(
                        child: CompanionWidget(size: 56, mood: widget.mood),
                      ),
                    ),
                  ),
                  if (widget.streakNote != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.streakNote!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: p.textMut),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: 48, minWidth: double.infinity),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.btn,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        s.missionStartCta,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: p.btnText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
