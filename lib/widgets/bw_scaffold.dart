import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/progression_provider.dart';

/// Sostituto di [Scaffold] che applica automaticamente il tema BeWell.
/// - Stile Card: sfondo piatto con colori della palette
/// - Stile Ambient: paesaggio atmosferico in cima che sfuma nel contenuto
class BwScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  const BwScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final p = theme.paletteData;

        if (!theme.isAmbient) {
          // ── Stile Card: Scaffold normale con colori palette ─────────────
          return Scaffold(
            backgroundColor: p.bg,
            appBar: appBar,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            body: body,
          );
        }

        // ── Stile Ambient: Cormorant come font di default per tutti i Text ──
        // Leggi la fase corrente per il glow adattivo (fallback silenzioso)
        double glowFactor = 0.0;
        try {
          final progression = Provider.of<ProgressionProvider>(context, listen: false);
          glowFactor = (progression.currentPhase - 1) / 4.0; // fase 1→0.0, fase 5→1.0
        } catch (_) {}

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'CormorantGaramond',
            ),
          ),
          child: Scaffold(
          backgroundColor: p.bg,
          appBar: appBar != null ? _AmbientAppBar(child: appBar!, p: p) : null,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: Stack(
            children: [
              // Paesaggio atmosferico in cima — glow adattivo per fase
              Positioned(
                top: 0, left: 0, right: 0,
                height: 100,
                child: CustomPaint(
                  painter: HorizonPainter(
                    dark: p.isDark,
                    bgColor: p.bg,
                    glowFactor: glowFactor,
                    primaryColor: p.primary,
                  ),
                ),
              ),
              // Contenuto scrollabile sopra
              body,
            ],
          ),
          ),
        );
      },
    );
  }
}

/// AppBar trasparente per lo stile ambient
class _AmbientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  final BwPaletteData p;

  const _AmbientAppBar({required this.child, required this.p});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ── Horizon Painter ───────────────────────────────────────────────────────────
/// [glowFactor] 0.0 = fase 1 (base), 1.0 = fase 5 (radioso).
/// Interpola colori più caldi / luminosi all'aumentare della fase.
class HorizonPainter extends CustomPainter {
  final bool dark;
  final Color bgColor;
  final double glowFactor;     // 0.0 – 1.0
  final Color primaryColor;

  const HorizonPainter({
    required this.dark,
    required this.bgColor,
    this.glowFactor = 0.0,
    this.primaryColor = const Color(0xFF6B9E78),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dark) {
      _paintNight(canvas, size);
    } else {
      _paintDawn(canvas, size);
    }
    _paintGlow(canvas, size);
    _paintFade(canvas, size);
  }

  /// Sovrimpressione calda basata su glowFactor (visibile solo in fase 2+)
  void _paintGlow(Canvas canvas, Size size) {
    if (glowFactor <= 0.0) return;
    // Alone caldo sull'orizzonte — usa il colore primary del tema
    final warmAlpha = glowFactor * 0.18;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          primaryColor.withValues(alpha: warmAlpha * 1.5),
          primaryColor.withValues(alpha: warmAlpha * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Fase 4+: piccoli punti luminosi sull'orizzonte
    if (glowFactor >= 0.75) {
      final dotAlpha = (glowFactor - 0.75) * 4 * 0.5; // 0→0.5 per fase 4-5
      final dotPaint = Paint()..color = primaryColor.withValues(alpha: dotAlpha);
      final rng = math.Random(7);
      for (int i = 0; i < 5; i++) {
        final x = size.width * (0.1 + rng.nextDouble() * 0.8);
        final y = size.height * (0.55 + rng.nextDouble() * 0.25);
        canvas.drawCircle(Offset(x, y), 1.5 + rng.nextDouble(), dotPaint);
      }
    }
  }

  void _paintDawn(Canvas canvas, Size size) {
    // Cielo alba
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEDE5D8),
    );
    // Sole emergente dal bordo superiore
    canvas.drawCircle(
      Offset(size.width * 0.5, -8),
      32,
      Paint()..color = const Color(0xFFF0C870).withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, -8),
      20,
      Paint()..color = const Color(0xFFEAB840).withValues(alpha: 0.40),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, -8),
      10,
      Paint()..color = const Color(0xFFE0A820).withValues(alpha: 0.68),
    );
    // Nebbia / nuvole basse
    canvas.drawOval(
      Rect.fromLTWH(-20, size.height * 0.3, size.width * 0.7, size.height * 0.4),
      Paint()..color = const Color(0xFFDDD0B8).withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.2, size.width * 0.7, size.height * 0.45),
      Paint()..color = const Color(0xFFD4C4A4).withValues(alpha: 0.45),
    );
    // Colline
    final hills1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.45,
          size.width * 0.42, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.42,
          size.width * 0.82, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.5,
          size.width, size.height * 0.6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);
    canvas.drawPath(hills1, Paint()..color = const Color(0xFFC4B498).withValues(alpha: 0.5));

    final hills2 = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.68,
          size.width * 0.55, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.65,
          size.width, size.height * 0.75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);
    canvas.drawPath(hills2, Paint()..color = const Color(0xFFB8A880).withValues(alpha: 0.45));
  }

  void _paintNight(Canvas canvas, Size size) {
    // Cielo notturno
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1520),
    );
    // Stelle
    final starPaint = Paint()..color = const Color(0xFFC8E0D8);
    final rng = math.Random(42); // seed fisso per stelle sempre uguali
    for (int i = 0; i < 28; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.85;
      final r = 0.6 + rng.nextDouble() * 1.6;
      final op = 0.35 + rng.nextDouble() * 0.55;
      canvas.drawCircle(Offset(x, y), r, starPaint..color = const Color(0xFFC8E0D8).withValues(alpha: op));
    }
    // Luna (falce)
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.22),
      16,
      Paint()..color = const Color(0xFF1A3048),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.18),
      14,
      Paint()..color = const Color(0xFFC4D8E8).withValues(alpha: 0.88),
    );
    canvas.drawCircle(
      Offset(size.width * 0.81, size.height * 0.15),
      12,
      Paint()..color = const Color(0xFF0D1520),
    );
    // Montagne
    final mts1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.18, size.height * 0.38,
          size.width * 0.36, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.28,
          size.width * 0.65, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.32,
          size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);
    canvas.drawPath(mts1, Paint()..color = const Color(0xFF162238).withValues(alpha: 0.88));

    final mts2 = Path()
      ..moveTo(0, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.68,
          size.width * 0.52, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.65,
          size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);
    canvas.drawPath(mts2, Paint()..color = const Color(0xFF111D2C));
  }

  void _paintFade(Canvas canvas, Size size) {
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bgColor.withValues(alpha: 0.0),
          bgColor.withValues(alpha: 0.72),
          bgColor,
        ],
        stops: const [0.25, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grad);
  }

  @override
  bool shouldRepaint(HorizonPainter old) =>
      old.dark != dark || old.bgColor != bgColor ||
      old.glowFactor != glowFactor || old.primaryColor != primaryColor;
}




