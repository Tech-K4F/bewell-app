import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../data/habit_guides.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/guide_motion_disc.dart';
import '../../widgets/habit_hero_band.dart';
import '../../widgets/guide_pose_image.dart';
import '../../widgets/leave_session_guard.dart';

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
  int _phaseIndex = 0;
  int _secondsLeft = 0;
  Timer? _ticker;
  DateTime? _phaseStartedAt;

  List<GuideStep> get _steps =>
      HabitGuides.forHabit(widget.habitId) ?? const [];

  GuidePhase? get _currentPhase {
    if (!_isRunning || _stepIndex >= _steps.length) return null;
    final phases = _steps[_stepIndex].phases;
    return _phaseIndex < phases.length ? phases[_phaseIndex] : null;
  }

  Color _phaseColor(BwPaletteData p) {
    return switch (_currentPhase?.kind) {
      GuidePhaseKind.primary => p.primary,
      GuidePhaseKind.accent => p.accent,
      GuidePhaseKind.blend => Color.lerp(p.primary, p.accent, 0.5)!,
      null => p.primary,
    };
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // Movimento ridotto: nessuna pulsazione continua.
    if (Motion.reduced) {
      _pulseCtrl.value = 0.5;
      _pulseCtrl.stop();
    }
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
      _phaseIndex = 0;
      _secondsLeft = _steps.first.phases.first.seconds;
      _phaseStartedAt = DateTime.now();
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
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    final phases = _steps[_stepIndex].phases;
    final nextPhase = _phaseIndex + 1;
    if (nextPhase < phases.length) {
      setState(() {
        _phaseIndex = nextPhase;
        _secondsLeft = phases[nextPhase].seconds;
        _phaseStartedAt = DateTime.now();
      });
      _tick();
      return;
    }
    final nextStep = _stepIndex + 1;
    if (nextStep >= _steps.length) {
      _onComplete();
      return;
    }
    setState(() {
      _stepIndex = nextStep;
      _phaseIndex = 0;
      _secondsLeft = _steps[nextStep].phases.first.seconds;
      _phaseStartedAt = DateTime.now();
    });
    _tick();
  }

  Future<void> _onComplete() async {
    setState(() => _isRunning = false);
    final progression = context.read<ProgressionProvider>();
    final app = context.read<AppProvider>();
    HapticFeedback.mediumImpact();
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
            style: TextStyle(
                color: p.text, fontWeight: FontWeight.w700, fontSize: 18)),
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.primaryText)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
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
    final step =
        _isRunning && _stepIndex < steps.length ? steps[_stepIndex] : null;
    final hasPose = step?.image != null;

    return LeaveSessionGuard(
        active: _isRunning,
        child: BwScaffold(
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
                  HabitHeroBand(habitId: widget.habitId),
                  const SizedBox(height: 16),
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
                        final st = steps[i];
                        final how = st.how?.call(s);
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: i == steps.length - 1 ? 0 : 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: TextStyle(
                                        color: p.primaryText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(st.title(s),
                                        style: TextStyle(
                                            color: p.text,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700)),
                                    if (how != null) ...[
                                      const SizedBox(height: 4),
                                      Text(how,
                                          style: TextStyle(
                                              color: p.textSec,
                                              fontSize: 12,
                                              height: 1.4)),
                                    ],
                                  ],
                                ),
                              ),
                              if (st.image != null) ...[
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 66,
                                  child: GuidePoseImage(
                                    image: AssetImage(st.image!),
                                    arrows: st.arrows,
                                    borderRadius: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.guideSafetyNote,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: p.textMut, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                ],

                // Durante l'esercizio: la posa con le frecce del movimento, così
                // non serve leggere — si guarda e si fa.
                if (_isRunning && step?.image != null) ...[
                  SizedBox(
                    height: 220,
                    child: GuidePoseImage(
                      image: AssetImage(step!.image!),
                      arrows: step.arrows,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.title(s),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  if (step.how != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.how!(s),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textSec, fontSize: 12, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // Cerchio guida — area a dimensione fissa così il pulsante
                // interrompi sotto non si sposta mai durante la sequenza.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isRunning || steps.isEmpty ? null : _start,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      final color = _isRunning ? _phaseColor(p) : p.primary;
                      final phase = _currentPhase;
                      final elapsed = _phaseStartedAt == null
                          ? 0.0
                          : DateTime.now()
                                  .difference(_phaseStartedAt!)
                                  .inMilliseconds /
                              1000;
                      return GuideMotionDisc(
                        motion: phase?.motion ?? GuideMotion.calm,
                        elapsedSeconds: elapsed,
                        phaseSeconds: phase?.seconds ?? 1,
                        pulse: _pulseCtrl.value,
                        size: hasPose ? 250 : 340,
                        accent: color,
                        discColor: p.card,
                        ringColor: p.textMut,
                        active: _isRunning,
                        child: step != null && phase != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      s.guideStepProgress(
                                          _stepIndex + 1, steps.length),
                                      style: TextStyle(
                                          color: p.textSec,
                                          fontSize: 12,
                                          letterSpacing: 1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_secondsLeft',
                                      style: TextStyle(
                                          color: p.text,
                                          fontSize: hasPose ? 40 : 52,
                                          fontWeight: FontWeight.w300),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      phase.label(s),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: p.text,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (!hasPose) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        step.title(s),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: p.textSec, fontSize: 12.5),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🧘',
                                      style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: Text(
                                      s.guideTapToStart,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: p.textSec, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                SizedBox(height: hasPose ? 24 : 48),

                if (_isRunning)
                  OutlinedButton.icon(
                    onPressed: _stop,
                    icon: Icon(Icons.stop_rounded, color: p.primary),
                    label: Text(s.breathingStop,
                        style: TextStyle(color: p.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: p.primary),
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
