import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
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

  // Box: 4-4-4-4 | 478: 4-7-8 | Deep: 5-5-5
  String _technique = 'box';
  int _totalCycles = 3;

  static const Map<String, List<int>> _techniques = {
    'box': [4, 4, 4, 4],
    '478': [4, 7, 8, 0],
    'deep': [5, 0, 5, 0],
  };

  static const Map<String, String> _names = {
    'box': 'Box Breathing',
    '478': 'Respirazione 4-7-8',
    'deep': 'Respirazione Profonda',
  };

  static const _phaseLabels = [
    'Inspira',
    'Trattieni',
    'Espira',
    'Trattieni',
  ];

  List<int> get _durations => _techniques[_technique]!;

  int get _currentPhaseDuration => _durations[_phaseIndex];

  String get _phaseLabel {
    if (_currentPhaseDuration == 0) return '';
    return _phaseLabels[_phaseIndex];
  }

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    // Skip phases with 0 duration
    while (_currentPhaseDuration == 0 && _phaseIndex < 3) {
      _phaseIndex = (_phaseIndex + 1) % 4;
    }

    _scaleCtrl.duration =
        Duration(seconds: _currentPhaseDuration);

    if (_phaseIndex == 0) {
      _scaleCtrl.forward(from: 0);
    } else if (_phaseIndex == 2) {
      _scaleCtrl.reverse(from: 1);
    }
    // Hold phases: keep scale where it is

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

    // After exhale (phase 2) + hold2 (phase 3) → next cycle
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

  void _onComplete() {
    setState(() => _isRunning = false);
    context.read<AppProvider>().completeActivity('STR001');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('🌿 Ottimo lavoro!',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_totalCycles cicli completati.',
              style: TextStyle(
                  color: Colors.white.withOpacity(.6), fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: BwColors.amberLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('+30 punti ⭐',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BwColors.amber)),
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
            child: const Text('Fatto'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _start();
            },
            child: const Text('Di nuovo',
                style: TextStyle(color: BwColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(
        title: const Text('Respirazione'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          children: [
            // Technique selector
            if (!_isRunning) ...[
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: BwColors.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BwColors.panelBorder),
                ),
                child: Row(
                  children: _techniques.keys.map((key) {
                    final sel = _technique == key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _technique = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? BwColors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _names[key]!.split(' ').first,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withOpacity(.3)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BwColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: BwColors.blue.withOpacity(.3)),
                ),
                child: Column(
                  children: [
                    Text(_names[_technique]!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        4,
                        (i) => _durations[i] > 0
                            ? Column(
                                children: [
                                  Text(_phaseLabels[i],
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(.5),
                                          fontSize: 10)),
                                  Text('${_durations[i]}s',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18)),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cycles selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Cicli:  ',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 14)),
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
                          color: sel ? BwColors.blue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: sel
                                  ? BwColors.blue
                                  : Colors.white.withOpacity(.15)),
                        ),
                        child: Center(
                          child: Text('$n',
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : Colors.white.withOpacity(.4),
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

            // Breathing circle
            AnimatedBuilder(
              animation: _scale,
              builder: (_, __) {
                final radius = 100 + (_scale.value * 50);
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow rings
                      if (_isRunning)
                        ...List.generate(3, (i) {
                          final r = radius + (i + 1) * 20;
                          return Container(
                            width: r * 2,
                            height: r * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BwColors.blue.withOpacity(
                                    0.15 * (1 - i * 0.3)),
                                width: 1,
                              ),
                            ),
                          );
                        }),
                      // Main circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              BwColors.blue.withOpacity(.5),
                              BwColors.blue.withOpacity(.1),
                            ],
                          ),
                          boxShadow: _isRunning
                              ? [
                                  BoxShadow(
                                    color: BwColors.blue.withOpacity(.4),
                                    blurRadius: 40,
                                    spreadRadius: 5,
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
                                  _phaseLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_currentPhaseDuration - _phaseSecond}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                Text(
                                  'Ciclo ${_cycleCount + 1}/$_totalCycles',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ] else ...[
                                const Text('🫁',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                Text(
                                  'Tocca per\ncominciare',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(.5),
                                      fontSize: 14),
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
            const SizedBox(height: 48),

            // Start / Stop button
            if (!_isRunning)
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BwColors.blue,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Inizia respirazione',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              )
            else
              OutlinedButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop_rounded,
                    color: BwColors.coral),
                label: const Text('Interrompi',
                    style: TextStyle(color: BwColors.coral)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BwColors.coral),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
