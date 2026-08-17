import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../data/habit_guides.dart';
import '../../widgets/bw_scaffold.dart';

/// Sequenza guidata passo-passo per abitudini che l'utente non sa
/// eseguire a memoria (es. "esercizi alla scrivania"): un cerchio
/// cronometrato accompagna ogni passo, esattamente come la respirazione
/// guidata, e il completamento aggiorna progressione, punti e streak.
class GuidedHabitScreen extends StatefulWidget {
  final String habitId;
  const GuidedHabitScreen({super.key, required this.habitId});

  @override
  State<GuidedHabitScreen> createState() => _GuidedHabitScreenState();
}

class _GuidedHabitScreenState extends State<GuidedHabitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  bool _isRunning = false;
  int _stepIndex = 0;
  int _secondsLeft = 0;
  Timer? _ticker;

  List<GuideStep> get _steps => HabitGuides.forHabit(widget.habitId) ?? const [];

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
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _stepIndex = 0;
      _secondsLeft = _steps.first.seconds;
    });
    _tick();
  }

  void _stop() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
  }

  void _tick() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        _nextStep();
      }
    });
  }

  void _nextStep() {
    final next = _stepIndex + 1;
    if (next >= _steps.length) {
      _onComplete();
      return;
    }
    setState(() {
      _stepIndex = next;
      _secondsLeft = _steps[next].seconds;
    });
    _tick();
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
    // Punti reali dell'abitudine, non un fisso 25/75 — desk_exercise e
    // neck_stretch valgono 20 (60 con bonus), non 25/75: il numero mostrato
    // qui non corrispondeva a quello davvero accreditato.
    final basePts = HabitLibrary.findById(widget.habitId)?.points ?? 25;
    final pts = app.lastCompletionWasBonus ? basePts * 3 : basePts;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.guideWellDone,
            style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.guideStepsCompleted(_steps.length),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final title = s.habitName(widget.habitId);
    final steps = _steps;
    final step = _isRunning && _stepIndex < steps.length ? steps[_stepIndex] : null;

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(steps.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(color: p.primaryText, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(steps[i].label(s),
                                style: TextStyle(color: p.text, fontSize: 13.5)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 48),
            ],

            // Cerchio guida — area a dimensione fissa così il pulsante
            // interrompi sotto non si sposta mai durante la sequenza.
            SizedBox(
              width: 340,
              height: 340,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final pulse = _isRunning ? (0.9 + _pulseCtrl.value * 0.1) : 0.75;
                  final radius = 130 * pulse;
                  return Center(
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            p.primary.withValues(alpha: .55),
                            p.primary.withValues(alpha: .12),
                          ],
                        ),
                        boxShadow: _isRunning
                            ? [
                                BoxShadow(
                                  color: p.primary.withValues(alpha: .4),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: step != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.guideStepProgress(_stepIndex + 1, steps.length),
                                    style: TextStyle(color: p.textMut, fontSize: 12, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_secondsLeft',
                                    style: TextStyle(color: p.text, fontSize: 48, fontWeight: FontWeight.w200),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      step.label(s),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🧘', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.guideTapToStart,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: p.textSec, fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 48),

            if (!_isRunning)
              ElevatedButton(
                onPressed: steps.isEmpty ? null : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.btn,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(s.guideStart,
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
}
