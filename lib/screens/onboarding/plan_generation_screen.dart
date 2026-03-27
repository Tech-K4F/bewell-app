import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _teal = Color(0xFF1E9E87);
const _amber = Color(0xFFD99820);

/// S-09 · AI Plan Generation
/// Schermata non skippabile. Anima 4 step mentre l'engine gira.
class PlanGenerationScreen extends StatefulWidget {
  const PlanGenerationScreen({super.key});

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen>
    with TickerProviderStateMixin {
  int _completedSteps = 0;
  int _activeStep = 0;
  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _steps = [
    (Icons.person_outline, 'Analizzo il tuo profilo'),
    (Icons.notifications_outlined, 'Configuro i reminder'),
    (Icons.local_activity_outlined, 'Seleziono le attività'),
    (Icons.dashboard_outlined, 'Configuro la dashboard'),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Avanza gli step di animazione client-side
    _advanceSteps();
  }

  void _advanceSteps() {
    // Step 1: 800ms
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() { _completedSteps = 1; _activeStep = 1; });
    });
    // Step 2: 1.8s
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() { _completedSteps = 2; _activeStep = 2; });
    });
    // Step 3: 3s (aspetta risposta engine — il provider chiama goToStep(planPreview))
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() { _activeStep = 3; });
    });
    // Step 4: auto — triggered dal provider quando planStatus == success
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      // Completa l'animazione al successo
      if (onb.planStatus == PlanGenStatus.success && _completedSteps < 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _completedSteps = 4);
        });
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0B1929),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Icona pulsante
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B4FCC).withOpacity(0.8),
                          _teal.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _teal.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🧬', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Costruendo il tuo piano…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stiamo applicando le regole di personalizzazione',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),

                // Step list
                ..._steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final step = entry.value;
                  final isDone = i < _completedSteps;
                  final isActive = i == _activeStep;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        // Icona stato
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isDone
                              ? Container(
                                  key: const ValueKey('done'),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _teal.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _teal),
                                  ),
                                  child: const Icon(Icons.check,
                                      color: _teal, size: 14),
                                )
                              : isActive
                                  ? SizedBox(
                                      key: const ValueKey('active'),
                                      width: 28,
                                      height: 28,
                                      child: RotationTransition(
                                        turns: _spinCtrl,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _amber,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: CircularProgressIndicator(
                                              color: _amber,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      key: const ValueKey('pending'),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Icon(
                                        step.$1,
                                        color: Colors.white.withOpacity(0.2),
                                        size: 14,
                                      ),
                                    ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            step.$2,
                            style: TextStyle(
                              color: isDone
                                  ? _teal
                                  : isActive
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isDone)
                          Text(
                            '✓',
                            style: TextStyle(
                                color: _teal.withOpacity(0.7), fontSize: 12),
                          ),
                      ],
                    ),
                  );
                }),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      );
    });
  }
}
