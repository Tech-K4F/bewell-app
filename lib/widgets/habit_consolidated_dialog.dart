import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'companion/companion_widget.dart';

/// Celebrazione a schermo intero quando un'abitudine viene assimilata
/// (status → consolidated, 7gg) o diventa automatica (status → automatic,
/// 66gg): il progresso deve sentirsi guadagnato, non un cambio di stato
/// silenzioso in un batch notturno. Entrambi i traguardi assegnano un
/// bonus punti — quello a 66 giorni vale di più, è l'ultimo della singola
/// abitudine.
class HabitConsolidatedDialog {
  /// [hasNextChoice] true quando subito dopo si aprirà la scelta della
  /// prossima abitudine (HabitIntroSheet) — il CTA lo anticipa invece di
  /// dire semplicemente "Continua" e lasciare che il foglio successivo
  /// arrivi come un salto scollegato dal momento appena vissuto.
  /// [isAutomatic] true per il traguardo a 66 giorni, false per quello a 7.
  static Future<void> show(
    BuildContext context,
    String habitId, {
    required int points,
    bool isAutomatic = false,
    bool hasNextChoice = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _CelebrationDialog(
        habitId: habitId,
        points: points,
        isAutomatic: isAutomatic,
        hasNextChoice: hasNextChoice,
      ),
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  final String habitId;
  final int points;
  final bool isAutomatic;
  final bool hasNextChoice;
  const _CelebrationDialog({
    required this.habitId,
    required this.points,
    required this.isAutomatic,
    required this.hasNextChoice,
  });

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final ConfettiController _confettiCtrl;
  late final int _countTo;
  int _shownCount = 0;

  @override
  void initState() {
    super.initState();
    _countTo = widget.points;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _confettiCtrl =
        ConfettiController(duration: const Duration(milliseconds: 1600));
    _ctrl.forward();
    _confettiCtrl.play();
    HapticFeedback.heavyImpact();

    // Stesso conteggio "che sale" del popup badge — coerenza tra i due
    // momenti in cui l'app mostra un guadagno di punti a schermo intero.
    _ctrl.addListener(() {
      final t = Curves.easeOut.transform(_ctrl.value.clamp(0.0, 1.0));
      final next = (_countTo * t).round();
      if (next != _shownCount && mounted) setState(() => _shownCount = next);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final isAmb = context.read<ThemeProvider>().isAmbient;
    final s = context.sL;
    final habitName = s.habitName(widget.habitId);
    final isAuto = widget.isAutomatic;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 24,
                minBlastForce: 10,
                emissionFrequency: 0.05,
                numberOfParticles: isAuto ? 28 : 20,
                gravity: 0.25,
                shouldLoop: false,
                colors: [p.primary, p.accent, p.primaryLight, Colors.amber],
              ),
            ),
          ),
        ),
        ScaleTransition(
          scale: _scale,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              decoration: BoxDecoration(
                // p.card, non p.bg — coerente con le altre finestre
                // dell'app, che usano sempre la superficie card, non il
                // colore di sfondo pagina, per i loro pannelli.
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
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        p.primary.withValues(alpha: .5),
                        p.primary.withValues(alpha: .1),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: p.primary.withValues(alpha: .4),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: const Center(
                      child: CompanionWidget(size: 96, mood: WellyMood.radiant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAuto ? s.automaticTitle : s.consolidatedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isAmb ? 24 : 21,
                      fontWeight: isAmb ? FontWeight.w300 : FontWeight.w800,
                      fontFamily: isAmb ? 'CormorantGaramond' : null,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAuto
                        ? s.automaticBody(habitName)
                        : s.consolidatedBody(habitName),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: p.textSec, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAuto ? s.automaticBadge : s.consolidatedBadge,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.primaryText),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          '+$_shownCount ${s.points}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: p.pointsText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: 50, minWidth: double.infinity),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.btn,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.hasNextChoice
                            ? s.consolidatedCtaNext
                            : s.consolidatedCta,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: p.btnText),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ),
      ],
    );
  }
}
