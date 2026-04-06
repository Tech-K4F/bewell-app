import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, ThemeProvider>(
      builder: (context, app, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final user = app.user;

        return BwScaffold(
          body: SafeArea(
            child: isAmb
                ? _AmbientHome(p: p, user: user)
                : _CardHome(p: p, user: user),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STILE CARD
// ══════════════════════════════════════════════════════════════
class _CardHome extends StatelessWidget {
  final BwPaletteData p;
  final dynamic user;
  const _CardHome({required this.p, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buongiorno,',
                        style: TextStyle(fontSize: 10, color: p.textSec)),
                    const SizedBox(height: 1),
                    Text(user?.name ?? 'Marco',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                            height: 1.1)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 17,
                backgroundColor: p.primaryLight,
                child: Text(user?.initials ?? 'M',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.primaryText)),
              ),
            ],
          ),
        ),
        // Streak
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Row(children: [
            Text('🔥 ${user?.streak ?? 0} gg streak',
                style: TextStyle(fontSize: 11, color: p.textSec)),
            const SizedBox(width: 14),
            Text('⭐ ${user?.points ?? 0} pt',
                style: TextStyle(fontSize: 11, color: p.textSec)),
            const SizedBox(width: 14),
            Text('🎯 ${user?.totalSessions ?? 0} sess.',
                style: TextStyle(fontSize: 11, color: p.textSec)),
          ]),
        ),
        // Cards
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              // Card Focus
              _BwCard(p: p, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sessione focus',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600, color: p.text)),
                        const SizedBox(height: 2),
                        Text('25 min · Pomodoro',
                            style: TextStyle(fontSize: 10, color: p.textSec)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: p.primaryLight,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Focus',
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: p.primaryText)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(height: 3,
                      decoration: BoxDecoration(
                          color: p.bg2,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity, height: 42,
                      decoration: BoxDecoration(
                          color: p.btn,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Inizia sessione',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.btnText))),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 10),
              // Card Acqua
              _BwCard(p: p, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acqua oggi',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600, color: p.text)),
                        const SizedBox(height: 2),
                        Text('4 di 8 bicchieri',
                            style: TextStyle(fontSize: 10, color: p.textSec)),
                      ],
                    )),
                    Text('50%',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600, color: p.accent)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: List.generate(8, (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 4 ? p.accent : p.bg2,
                        border: Border.all(
                            color: i < 4 ? p.accent : p.cardBorder,
                            width: 0.5),
                      ),
                    ),
                  ))),
                  const SizedBox(height: 8),
                  Stack(children: [
                    Container(height: 3,
                        decoration: BoxDecoration(
                            color: p.bg2,
                            borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(height: 3,
                          decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                  ]),
                ],
              )),
              const SizedBox(height: 10),
              // Card Oggi
              _BwCard(p: p, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Oggi', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: p.text)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: p.primaryLight,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('4 / 6 completati',
                            style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: p.primaryText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    ('12:00', 'Pausa pranzo', true),
                    ('14:00', 'Focus pomeridiano', false),
                    ('16:00', 'Stretching attivo', false),
                  ].map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(children: [
                      SizedBox(width: 42,
                          child: Text(s.$1, style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500,
                              color: p.textSec))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.$2, style: TextStyle(
                          fontSize: 13,
                          fontWeight: s.$3 ? FontWeight.w600 : FontWeight.w400,
                          color: s.$3 ? p.primary : p.text))),
                      if (s.$3) Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: p.primary, shape: BoxShape.circle)),
                    ]),
                  )),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STILE AMBIENT
// ══════════════════════════════════════════════════════════════
class _AmbientHome extends StatelessWidget {
  final BwPaletteData p;
  final dynamic user;
  const _AmbientHome({required this.p, required this.user});

  @override
  Widget build(BuildContext context) {
    final circR = 2 * math.pi * 62;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 72, 22, 32),
      children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('buongiorno,',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                      color: p.textSec)),
              Text(user?.name ?? 'Marco',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300,
                      color: p.text, height: 1.05)),
            ],
          )),
          CircleAvatar(radius: 18, backgroundColor: p.primaryLight,
              child: Text(user?.initials ?? 'M',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: p.primaryText))),
        ]),
        const SizedBox(height: 8),
        Divider(color: p.text.withValues(alpha: 0.08), height: 1),
        const SizedBox(height: 8),
        // Streak
        Row(children: [
          Text('🔥 ${user?.streak ?? 0} gg',
              style: TextStyle(fontSize: 10, color: p.textSec)),
          const SizedBox(width: 16),
          Text('⭐ ${user?.points ?? 0} pt',
              style: TextStyle(fontSize: 10, color: p.textSec)),
          const SizedBox(width: 16),
          Text('🎯 ${user?.totalSessions ?? 0} sess.',
              style: TextStyle(fontSize: 10, color: p.textSec)),
        ]),
        const SizedBox(height: 20),
        Divider(color: p.text.withValues(alpha: 0.07), height: 1),
        const SizedBox(height: 14),

        // Label sezione
        Text('concentrazione',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                color: p.textSec, letterSpacing: 2)),
        const SizedBox(height: 20),

        // Ring timer centrato
        Center(child: SizedBox(
          width: 160, height: 160,
          child: CustomPaint(
            painter: _AmbRingPainter(p: p, progress: 0, circR: circR),
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('25', style: TextStyle(fontSize: 44,
                    fontWeight: FontWeight.w300, color: p.text)),
                Text('minuti', style: TextStyle(fontSize: 12,
                    color: p.textSec, letterSpacing: 1,
                    fontStyle: FontStyle.italic)),
              ],
            )),
          ),
        )),

        const SizedBox(height: 28),

        // Bottone
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            height: 44,
            decoration: BoxDecoration(
                color: p.btn, borderRadius: BorderRadius.circular(22)),
            child: Center(child: Text('inizia sessione',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400,
                    color: p.btnText))),
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: p.text.withValues(alpha: 0.07), height: 1),
        const SizedBox(height: 14),

        // Acqua
        Text('acqua',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                color: p.textSec, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('4 di 8 bicchieri',
            style: TextStyle(fontSize: 13, color: p.textSec)),
        const SizedBox(height: 10),
        Row(children: List.generate(8, (i) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < 4 ? p.accent : Colors.transparent,
              border: Border.all(
                  color: i < 4 ? p.accent : p.textSec.withValues(alpha: 0.28),
                  width: 1),
            ),
          ),
        ))),
        const SizedBox(height: 10),
        Stack(children: [
          Container(height: 2,
              decoration: BoxDecoration(
                  color: p.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(1))),
          FractionallySizedBox(
            widthFactor: 0.5,
            child: Container(height: 2,
                decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(1))),
          ),
        ]),

        const SizedBox(height: 28),
        Divider(color: p.text.withValues(alpha: 0.07), height: 1),
        const SizedBox(height: 14),

        // Schedule preview
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('oggi, 5 aprile',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                  color: p.textSec, letterSpacing: 1)),
          Text('4 / 6 ✓',
              style: TextStyle(fontSize: 11, color: p.accent)),
        ]),
        const SizedBox(height: 12),
        ...[
          ('12:00', 'Pausa pranzo', true),
          ('14:00', 'Focus pomeridiano', false),
          ('16:00', 'Stretching attivo', false),
        ].map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 44, child: Text(s.$1,
                style: TextStyle(fontSize: 10, color: p.textSec,
                    fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            Expanded(child: Text(s.$2,
                style: TextStyle(fontSize: 14,
                    fontWeight: s.$3 ? FontWeight.w400 : FontWeight.w300,
                    color: s.$3 ? p.primary : p.text))),
            if (s.$3) Container(width: 5, height: 5,
                decoration: BoxDecoration(
                    color: p.primary, shape: BoxShape.circle)),
          ]),
        )),
      ],
    );
  }
}

// ── Ring painter ambient ──────────────────────────────────────────────────────
class _AmbRingPainter extends CustomPainter {
  final BwPaletteData p;
  final double progress;
  final double circR;
  const _AmbRingPainter(
      {required this.p, required this.progress, required this.circR});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Cerchi concentrici decorativi
    for (final dr in [22.0, 11.0]) {
      canvas.drawCircle(center, radius + dr,
          Paint()
            ..color = p.ring.withValues(alpha: 0.05)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }

    // Track
    canvas.drawCircle(center, radius,
        Paint()
          ..color = p.ringTrack
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Tick marks
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      final isMaj = i % 3 == 0;
      final r1 = radius + 6;
      final r2 = radius + (isMaj ? 14 : 9);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * r1,
            center.dy + math.sin(angle) * r1),
        Offset(center.dx + math.cos(angle) * r2,
            center.dy + math.sin(angle) * r2),
        Paint()
          ..color = p.ring.withValues(alpha: isMaj ? 0.22 : 0.10)
          ..strokeWidth = isMaj ? 0.9 : 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..color = p.ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_AmbRingPainter old) => old.progress != progress;
}

// ── Card wrapper card style ───────────────────────────────────────────────────
class _BwCard extends StatelessWidget {
  final Widget child;
  final BwPaletteData p;
  const _BwCard({required this.child, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: child,
    );
  }
}
