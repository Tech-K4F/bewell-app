import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/progression_provider.dart';
import '../providers/theme_provider.dart';

/// Celebrazione a schermo intero per lo sblocco di un badge/achievement —
/// prima era un toast che si auto-chiudeva in 4 secondi senza mostrare
/// alcuna ricompensa: il momento più "da videogioco" dell'app aveva il
/// trattamento più dimesso. Ora è alla pari della festa di consolidamento
/// abitudine, con i punti guadagnati contati a video.
class BadgeUnlockedDialog {
  static Future<void> show(BuildContext context, BadgeInfo badge,
      {required int points}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _BadgeCelebration(badge: badge, points: points),
    );
  }
}

class _BadgeCelebration extends StatefulWidget {
  final BadgeInfo badge;
  final int points;
  const _BadgeCelebration({required this.badge, required this.points});

  @override
  State<_BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<_BadgeCelebration>
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

    // Conteggio punti "che sale" invece di un numero statico — è la
    // differenza fra una ricompensa che si sente guadagnata e una scritta.
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
    final badge = widget.badge;

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
                numberOfParticles: 22,
                gravity: 0.25,
                shouldLoop: false,
                colors: [
                  p.primary,
                  p.accent,
                  p.primaryLight,
                  Colors.amber,
                ],
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
                color: p.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 48,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.amber.withValues(alpha: .5),
                        Colors.amber.withValues(alpha: .08),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.amber.withValues(alpha: .35),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: badge.imageAsset != null
                          ? ClipOval(
                              child: Image.asset(
                                badge.imageAsset!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(badge.emoji,
                                    style: const TextStyle(fontSize: 52)),
                              ),
                            )
                          : Text(badge.emoji,
                              style: const TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.badgeUnlockedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isAmb ? 24 : 21,
                      fontWeight: isAmb ? FontWeight.w300 : FontWeight.w800,
                      fontFamily: isAmb ? 'CormorantGaramond' : null,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: p.textSec, height: 1.4),
                  ),
                  const SizedBox(height: 20),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
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
                        s.badgeUnlockedCta,
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
