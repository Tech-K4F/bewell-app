import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Freccia sottile disegnata a mano sopra l'immagine di una posa, per far
/// capire la DIREZIONE del movimento (un'immagine ferma non lo mostra).
/// Le coordinate sono normalizzate sull'immagine: (0,0) alto-sinistra,
/// (1,1) basso-destra. Angoli in gradi, 0 = destra, positivi in senso orario.
class GuideArrow {
  final Offset from;
  final Offset control;
  final Offset to;
  final bool bothEnds;
  final Offset? center;
  final double rx;
  final double ry;
  final double startDeg;
  final double sweepDeg;

  /// Freccia curva (curva di Bézier quadratica); con [control] a metà
  /// strada tra [from] e [to] è una freccia dritta.
  const GuideArrow.curve(this.from, this.control, this.to,
      {this.bothEnds = false})
      : center = null,
        rx = 0,
        ry = 0,
        startDeg = 0,
        sweepDeg = 0;

  /// Freccia ad arco (ellittico) per movimenti circolari.
  const GuideArrow.arc(
      Offset this.center, this.rx, this.ry, this.startDeg, this.sweepDeg)
      : from = Offset.zero,
        control = Offset.zero,
        to = Offset.zero,
        bothEnds = false;
}

/// Immagine di una posa (3:4) con le frecce del movimento sovrapposte.
class GuidePoseImage extends StatelessWidget {
  final ImageProvider image;
  final List<GuideArrow> arrows;
  final double borderRadius;

  const GuidePoseImage({
    super.key,
    required this.image,
    this.arrows = const [],
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: image, fit: BoxFit.cover),
            if (arrows.isNotEmpty) CustomPaint(painter: _ArrowsPainter(arrows)),
          ],
        ),
      ),
    );
  }
}

class _ArrowsPainter extends CustomPainter {
  final List<GuideArrow> arrows;
  const _ArrowsPainter(this.arrows);

  static const _ink = Color(0xFF3B3B3B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = (w * 0.0065).clamp(1.5, 3.0);
    for (var i = 0; i < arrows.length; i++) {
      final pts = _sample(arrows[i], size, seed: i * 1.7);
      if (pts.length < 2) continue;
      // Due passate leggermente sfalsate: l'effetto "penna a mano".
      _stroke(canvas, pts, stroke, 0.85, Offset.zero);
      _stroke(canvas, pts, stroke * 0.6, 0.35, Offset(w * 0.0025, w * 0.002));
      _head(canvas, pts, w, stroke, atEnd: true);
      if (arrows[i].bothEnds) {
        _head(canvas, pts.reversed.toList(), w, stroke, atEnd: true);
      }
    }
  }

  List<Offset> _sample(GuideArrow a, Size size, {required double seed}) {
    const n = 48;
    final pts = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final t = k / n;
      late Offset p;
      if (a.center == null) {
        final u = 1 - t;
        p = a.from * (u * u) + a.control * (2 * u * t) + a.to * (t * t);
      } else {
        final ang = (a.startDeg + a.sweepDeg * t) * math.pi / 180;
        p = a.center! + Offset(math.cos(ang) * a.rx, math.sin(ang) * a.ry);
      }
      // Leggero tremolio perpendicolare, deterministico.
      final wobble = math.sin(t * math.pi * 3 + seed) * 0.0022;
      pts.add(Offset(
        (p.dx + wobble) * size.width,
        (p.dy - wobble * 0.7) * size.height,
      ));
    }
    return pts;
  }

  void _stroke(Canvas canvas, List<Offset> pts, double width, double alpha,
      Offset shift) {
    final path = Path()
      ..moveTo(pts.first.dx + shift.dx, pts.first.dy + shift.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx + shift.dx, p.dy + shift.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _ink.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _head(Canvas canvas, List<Offset> pts, double w, double stroke,
      {required bool atEnd}) {
    final tip = pts.last;
    final back = pts[pts.length - 6];
    final dir = math.atan2(tip.dy - back.dy, tip.dx - back.dx);
    final len = w * 0.05;
    final paint = Paint()
      ..color = _ink.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final spread = 0.5 + side * 0.06;
      final a = dir + math.pi + side * spread;
      canvas.drawLine(
        tip,
        Offset(tip.dx + math.cos(a) * len, tip.dy + math.sin(a) * len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowsPainter old) => old.arrows != arrows;
}
