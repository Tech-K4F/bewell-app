import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

/// Celebrazione a schermo intero per le soglie di streak (7/21/66 giorni —
/// i numeri reali dello studio Lally UCL 2010, non un 7/30/100 arbitrario).
/// Motore di ritorno distinto dal consolidamento abitudine — stessa energia
/// (coriandoli, haptic), icona diversa (🔥 non 🏆) per non ripetersi.
class StreakMilestoneDialog {
  static Future<void> show(BuildContext context, int days) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _StreakDialog(days: days),
    );
  }
}

class _StreakDialog extends StatefulWidget {
  final int days;
  const _StreakDialog({required this.days});

  @override
  State<_StreakDialog> createState() => _StreakDialogState();
}

class _StreakDialogState extends State<_StreakDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _confettiCtrl =
        ConfettiController(duration: const Duration(milliseconds: 1600));
    _ctrl.forward();
    _confettiCtrl.play();
    HapticFeedback.heavyImpact();
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
    final eventId = 'milestone_${widget.days}_days';
    final body = s.tutorialText(eventId);
    final fact = s.tutorialFact(eventId);

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
                numberOfParticles: 20,
                gravity: 0.25,
                shouldLoop: false,
                colors: [p.accent, p.primary, p.primaryLight, Colors.amber],
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
                    color: p.accent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.35),
                    blurRadius: 48,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        p.accent.withValues(alpha: .5),
                        p.accent.withValues(alpha: .1),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: p.accent.withValues(alpha: .4),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: const Center(
                        child: Text('🔥', style: TextStyle(fontSize: 44))),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.streakMilestoneTitle(widget.days),
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
                    body,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: p.textSec, height: 1.5),
                  ),
                  if (fact != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      fact,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: p.textMut,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.streakMilestoneBadge,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.primaryText),
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
                        s.consolidatedCta,
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
      ],
    );
  }
}
