import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';

enum _TimerState { idle, running, paused, done }

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 25 * 60;
  int _remaining = _totalSeconds;
  _TimerState _state = _TimerState.idle;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _state = _TimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _state = _TimerState.done;
          _timer?.cancel();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _state = _TimerState.paused);
  }

  void _resume() => _start();

  void _stop() {
    _timer?.cancel();
    setState(() {
      _state = _TimerState.idle;
      _remaining = _totalSeconds;
    });
  }

  String get _timeLabel {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remaining / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;

        return BwScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                SizedBox(height: isAmb ? 80 : 0),

                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAmb ? context.sL.focusTitle.toLowerCase() : context.sL.focusTitle,
                      style: TextStyle(
                        fontSize: isAmb ? 28 : 22,
                        fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                        fontFamily: isAmb ? 'CormorantGaramond' : null,
                        fontStyle: isAmb ? FontStyle.normal : null,
                        color: p.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(context.sL.focusPomodoro,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primaryText)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Ring timer ──────────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _progress,
                        trackColor: p.ringTrack,
                        progressColor: p.ring,
                        ambient: isAmb,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeLabel,
                              style: TextStyle(
                                fontSize: isAmb ? 52 : 44,
                                fontWeight: isAmb
                                    ? FontWeight.w300
                                    : FontWeight.w600,
                                fontFamily:
                                    isAmb ? 'CormorantGaramond' : null,
                                color: p.text,
                              ),
                            ),
                            Text(
                              context.sL.focusRemaining,
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSec,
                                fontFamily:
                                    isAmb ? 'CormorantGaramond' : null,
                                fontStyle: isAmb
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                letterSpacing: isAmb ? 1.5 : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Info sessione
                Text(
                  _state == _TimerState.done
                      ? context.sL.focusDone
                      : 'Blocco 1 di 4 · pausa tra ${_remaining ~/ 60} min',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textSec,
                    fontFamily: isAmb ? 'CormorantGaramond' : null,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Bottoni ──────────────────────────────────────────────
                if (_state == _TimerState.idle) ...[
                  _BigButton(
                    label: context.sL.focusNewSession,
                    color: p.btn,
                    textColor: p.btnText,
                    onTap: _start,
                    ambient: isAmb,
                  ),
                ] else if (_state == _TimerState.running) ...[
                  Row(children: [
                    Expanded(
                      child: _BigButton(
                        label: context.sL.focusPause,
                        color: p.bg2,
                        textColor: p.textSec,
                        onTap: _pause,
                        ambient: isAmb,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigButton(
                        label: context.sL.focusStop,
                        color: p.btn,
                        textColor: p.btnText,
                        onTap: _stop,
                        ambient: isAmb,
                      ),
                    ),
                  ]),
                ] else if (_state == _TimerState.paused) ...[
                  Row(children: [
                    Expanded(
                      child: _BigButton(
                        label: context.sL.focusResume,
                        color: p.btn,
                        textColor: p.btnText,
                        onTap: _resume,
                        ambient: isAmb,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigButton(
                        label: context.sL.focusStop,
                        color: p.bg2,
                        textColor: p.textSec,
                        onTap: _stop,
                        ambient: isAmb,
                      ),
                    ),
                  ]),
                ] else ...[
                  _BigButton(
                    label: context.sL.focusNewSession,
                    color: p.btn,
                    textColor: p.btnText,
                    onTap: _stop,
                    ambient: isAmb,
                  ),
                ],

                const SizedBox(height: 32),

                // ── Stats ────────────────────────────────────────────────
                if (isAmb) ...[
                  Divider(color: p.cardBorder, height: 1),
                  const SizedBox(height: 20),
                  Text('oggi',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'CormorantGaramond',
                        fontStyle: FontStyle.italic,
                        color: p.textSec,
                        letterSpacing: 2,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AmbStat(label: context.sL.focusSessions, value: '3', p: p),
                      _AmbStat(label: context.sL.focusMinutes, value: '75', p: p),
                      _AmbStat(label: context.sL.focusStreak, value: '7', p: p),
                    ],
                  ),
                ] else ...[
                  Row(children: [
                    Expanded(child: _StatCard(label: context.sL.focusSessions, value: '3', p: p)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: context.sL.focusMinutes, value: '75', p: p)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: context.sL.focusStreak, value: '7 gg', p: p)),
                  ]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool ambient;

  const _BigButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    required this.ambient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ambient ? 25 : 14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: ambient ? FontWeight.w400 : FontWeight.w600,
              fontFamily: ambient ? 'CormorantGaramond' : null,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final BwPaletteData p;
  const _StatCard({required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10, color: p.textSec)),
        ],
      ),
    );
  }
}

class _AmbStat extends StatelessWidget {
  final String label, value;
  final BwPaletteData p;
  const _AmbStat({required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                fontFamily: 'CormorantGaramond',
                color: p.text,
              )),
          Text(label,
              style: TextStyle(fontSize: 10, color: p.textSec)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor, progressColor;
  final bool ambient;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.ambient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final stroke = ambient ? 2.0 : 8.0;

    // Track
    canvas.drawCircle(
        center, radius, Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);

    // Tick marks (ambient only)
    if (ambient) {
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
            ..color = progressColor.withValues(alpha: isMaj ? 0.22 : 0.10)
            ..strokeWidth = isMaj ? 0.9 : 0.5
            ..strokeCap = StrokeCap.round,
        );
      }
      // Ripple rings
      for (final dr in [14.0, 26.0]) {
        canvas.drawCircle(
            center, radius + dr, Paint()
              ..color = progressColor.withValues(alpha: 0.05)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
      }
    }

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ambient != ambient;
}




