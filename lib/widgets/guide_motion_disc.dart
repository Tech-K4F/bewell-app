import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/habit_guides.dart' show GuideMotion;

/// Indicatore circolare di una fase guidata il cui MOVIMENTO è pertinente al
/// gesto: un anello fisso fa da riferimento e
///  • per una rotazione un punto gli gira intorno (in senso orario o
///    antiorario, come chiede l'esercizio);
///  • per alzare/abbassare o spostarsi a destra/sinistra è il disco centrale a
///    salire, scendere o scivolare lungo l'anello;
///  • nelle pause il disco respira piano sul posto.
/// Il testo sta su un disco pieno (colore della card), non su un
/// gradiente colorato: il contrasto è quello del tema, qualunque sia la fase.
class GuideMotionDisc extends StatelessWidget {
  final GuideMotion motion;
  final double elapsedSeconds;
  final int phaseSeconds;
  final double pulse;
  final double size;
  final Color accent;
  final Color discColor;
  final Color ringColor;
  final bool active;
  final Widget child;

  const GuideMotionDisc({
    super.key,
    required this.motion,
    required this.elapsedSeconds,
    required this.phaseSeconds,
    required this.pulse,
    required this.size,
    required this.accent,
    required this.discColor,
    required this.ringColor,
    required this.child,
    this.active = true,
  });

  /// Secondi per un giro completo del punto nelle rotazioni.
  static const _secondsPerTurn = 4.0;

  @override
  Widget build(BuildContext context) {
    final ring = size / 2 - 6;
    final discRadius = ring * 0.74;
    final travel = ring - discRadius - 3;

    var offset = Offset.zero;
    var scale = 1.0;
    if (!active || motion.isCalm) {
      scale = active ? 0.97 + 0.03 * pulse : 0.95;
    } else if (motion.rotation == 0) {
      final ease = math.min(2.5, phaseSeconds * 0.5);
      final u =
          Curves.easeInOut.transform((elapsedSeconds / ease).clamp(0.0, 1.0));
      final pos = Offset.lerp(motion.from, motion.to, u)!;
      offset = Offset(pos.dx * travel, pos.dy * travel);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              ringRadius: ring,
              ringColor: ringColor,
              accent: accent,
              orbit: active && motion.rotation != 0,
              angle: -math.pi / 2 +
                  motion.rotation *
                      2 *
                      math.pi *
                      (elapsedSeconds / _secondsPerTurn),
              direction: motion.rotation,
            ),
          ),
          Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: discRadius * 2,
                height: discRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: discColor,
                  border: Border.all(color: accent, width: 3),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ringRadius;
  final Color ringColor;
  final Color accent;
  final bool orbit;
  final double angle;
  final int direction;

  const _RingPainter({
    required this.ringRadius,
    required this.ringColor,
    required this.accent,
    required this.orbit,
    required this.angle,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      ringRadius,
      Paint()
        ..color = ringColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    if (!orbit) return;

    // Scia dietro il punto (più intensa vicino al punto): mostra il verso di
    // rotazione a colpo d'occhio.
    const segments = 10;
    const trail = 1.3;
    final rect = Rect.fromCircle(center: c, radius: ringRadius);
    for (var i = 0; i < segments; i++) {
      final t0 = i / segments;
      final t1 = (i + 1) / segments;
      // Il segmento più vicino al punto ha alpha massima.
      final from = angle - direction * trail * (1 - t0);
      final sweep = direction * trail * (t1 - t0);
      canvas.drawArc(
        rect,
        from,
        sweep,
        false,
        Paint()
          ..color = accent.withValues(alpha: 0.18 + 0.75 * t1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
    final dot = c + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
    canvas.drawCircle(dot, 9, Paint()..color = accent);
    canvas.drawCircle(
      dot,
      9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.angle != angle ||
      old.orbit != orbit ||
      old.accent != accent ||
      old.ringColor != ringColor;
}
