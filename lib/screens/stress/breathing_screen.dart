import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../widgets/bw_scaffold.dart';

/// Sessione di respirazione guidata, legata a un'abitudine reale
/// (breathing_box o breathing_478) — il completamento aggiorna
/// progressione, punti e streak come ogni altra abitudine.
class BreathingScreen extends StatefulWidget {
  final String habitId; // 'breathing_box' | 'breathing_478'
  const BreathingScreen({super.key, required this.habitId});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  bool _isRunning = false;
  int _cycleCount = 0;
  int _phaseIndex = 0; // 0=inhale 1=hold 2=exhale 3=hold2
  int _phaseSecond = 0;
  Timer? _ticker;
  int _totalCycles = 3;

  // Box: 4-4-4-4 | 4-7-8: 4-7-8-0 (nessuna seconda trattenuta)
  List<int> get _durations =>
      widget.habitId == 'breathing_478' ? const [4, 7, 8, 0] : const [4, 4, 4, 4];

  int get _currentPhaseDuration => _durations[_phaseIndex];

  String _phaseLabel(BwStrings s) {
    if (_currentPhaseDuration == 0) return '';
    return switch (_phaseIndex) {
      0 => s.breathingInhale,
      2 => s.breathingExhale,
      _ => s.breathingHold,
    };
  }

  // Colore distinto per fase, cosi il box "respira" visivamente anche
  // nel colore, non solo nella dimensione — non solo pulsazione, un vero
  // cambio di stato leggibile a colpo d'occhio.
  Color _phaseColor(BwPaletteData p) {
    if (!_isRunning) return p.primary;
    return switch (_phaseIndex) {
      0 => p.primary,                            // inspira
      2 => p.accent,                              // espira
      _ => Color.lerp(p.primary, p.accent, 0.5)!, // trattieni
    };
  }

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _cycleCount = 0;
      _phaseIndex = 0;
      _phaseSecond = 0;
    });
    _enterPhase();
  }

  void _stop() {
    _ticker?.cancel();
    _scaleCtrl.stop();
    setState(() => _isRunning = false);
  }

  void _enterPhase() {
    while (_currentPhaseDuration == 0 && _phaseIndex < 3) {
      _phaseIndex = (_phaseIndex + 1) % 4;
    }

    _scaleCtrl.duration = Duration(seconds: _currentPhaseDuration);

    if (_phaseIndex == 0) {
      _scaleCtrl.forward(from: 0);
    } else if (_phaseIndex == 2) {
      _scaleCtrl.reverse(from: 1);
    }
    // Fasi di trattenuta: la scala resta ferma dove si trova

    _phaseSecond = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _phaseSecond++;
      if (_phaseSecond >= _currentPhaseDuration) {
        _ticker?.cancel();
        _nextPhase();
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _nextPhase() {
    int next = (_phaseIndex + 1) % 4;

    if (next == 0) {
      final newCycle = _cycleCount + 1;
      if (newCycle >= _totalCycles) {
        _onComplete();
        return;
      }
      setState(() {
        _cycleCount = newCycle;
        _phaseIndex = 0;
      });
    } else {
      setState(() => _phaseIndex = next);
    }
    _enterPhase();
  }

  Future<void> _onComplete() async {
    setState(() => _isRunning = false);
    final progression = context.read<ProgressionProvider>();
    final app = context.read<AppProvider>();
    await progression.markCompleted(widget.habitId);
    if (!mounted) return;
    await app.completeHabit(widget.habitId);
    if (!mounted) return;

    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    // Punti reali dell'abitudine (habit_library.dart è la fonte unica di
    // verità) — un valore fisso 25/75 qui mostrava un numero sbagliato ogni
    // volta che l'abitudine dietro questa schermata ne valeva un altro.
    final basePts = HabitLibrary.findById(widget.habitId)?.points ?? 25;
    final pts = app.lastCompletionWasBonus ? basePts * 3 : basePts;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.breathingWellDone,
            style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.breathingCyclesCompleted(_totalCycles),
              style: TextStyle(color: p.textSec, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: p.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(s.breathingPointsEarned(pts),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.primaryText)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: Text(s.confirm),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _start();
            },
            child: Text(s.breathingAgain, style: TextStyle(color: p.textSec)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final title = s.habitName(widget.habitId);

    return BwScaffold(
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        title: Text(title, style: TextStyle(color: p.text, fontSize: 17)),
        leading: BackButton(color: p.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          children: [
            if (!_isRunning) ...[
              // Info card: durata di ogni fase
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.cardBorder),
                ),
                child: Column(
                  children: [
                    Text(title,
                        style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (i) {
                        if (_durations[i] <= 0) return const SizedBox();
                        return Column(
                          children: [
                            Text(_phaseLabel3(s, i),
                                style: TextStyle(color: p.textMut, fontSize: 10)),
                            Text('${_durations[i]}s',
                                style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 18)),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selettore cicli
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.breathingCycles, style: TextStyle(color: p.textMut, fontSize: 14)),
                  const SizedBox(width: 6),
                  ...[3, 5, 7].map((n) {
                    final sel = n == _totalCycles;
                    return GestureDetector(
                      onTap: () => setState(() => _totalCycles = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel ? p.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: sel ? p.primary : p.cardBorder),
                        ),
                        child: Center(
                          child: Text('$n',
                              style: TextStyle(
                                  color: sel ? p.btnText : p.textSec,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 36),
            ],

            // Cerchio animato — area a dimensione fissa: il cerchio pulsa e
            // cambia colore al suo interno senza mai spostare gli elementi
            // sotto (in particolare il pulsante interrompi).
            SizedBox(
              width: 340,
              height: 340,
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, __) {
                  final radius = 70 + (_scale.value * 80);
                  final color = _phaseColor(p);
                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isRunning)
                          ...List.generate(3, (i) {
                            final r = radius + (i + 1) * 20;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: r * 2,
                              height: r * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color.withValues(alpha: 0.18 * (1 - i * 0.3)),
                                  width: 1,
                                ),
                              ),
                            );
                          }),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: radius * 2,
                          height: radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                color.withValues(alpha: .6),
                                color.withValues(alpha: .12),
                              ],
                            ),
                            boxShadow: _isRunning
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: .5),
                                      blurRadius: 44,
                                      spreadRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isRunning) ...[
                                  Text(
                                    _phaseLabel(s),
                                    style: TextStyle(
                                      color: p.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_currentPhaseDuration - _phaseSecond}',
                                    style: TextStyle(color: p.text, fontSize: 48, fontWeight: FontWeight.w200),
                                  ),
                                  Text(
                                    '${_cycleCount + 1}/$_totalCycles',
                                    style: TextStyle(color: p.textMut, fontSize: 12),
                                  ),
                                ] else ...[
                                  const Text('🫁', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.breathingTapToStart,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: p.textSec, fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 48),

            if (!_isRunning)
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.btn,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(s.breathingStart,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.btnText)),
              )
            else
              OutlinedButton.icon(
                onPressed: _stop,
                icon: Icon(Icons.stop_rounded, color: p.primary),
                label: Text(s.breathingStop, style: TextStyle(color: p.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.primary),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel3(BwStrings s, int i) {
    return switch (i) {
      0 => s.breathingInhale,
      2 => s.breathingExhale,
      _ => s.breathingHold,
    };
  }
}
