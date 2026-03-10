import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ring.dart';
import '../stress/breathing_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  int _selectedMinutes = 25;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  String _mode = 'Focus'; // Focus | Short Break | Long Break

  late AnimationController _pulseCtrl;
  late AnimationController _rotCtrl;
  late Animation<double> _pulse;

  final _durations = [15, 25, 45, 90];
  final _durationLabels = ['Quick', 'Standard', 'Deep', 'Ultra'];

  int _todaySessions = 0;
  int _todayMinutes = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _pulse = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _onComplete();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _selectedMinutes * 60;
    });
  }

  void _selectDuration(int m) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = m;
      _secondsLeft = m * 60;
    });
  }

  void _selectMode(String m) {
    if (_isRunning) return;
    setState(() {
      _mode = m;
      _selectedMinutes = m == 'Focus' ? 25 : m == 'Short Break' ? 5 : 15;
      _secondsLeft = _selectedMinutes * 60;
    });
  }

  void _onComplete() {
    setState(() {
      _todaySessions++;
      _todayMinutes += _selectedMinutes;
    });
    if (_mode == 'Focus') {
      context.read<AppProvider>().completeActivity('FOC001');
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        mode: _mode,
        minutes: _selectedMinutes,
        onContinue: () {
          Navigator.pop(context);
          _reset();
        },
      ),
    );
  }

  String get _timeStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_secondsLeft / (_selectedMinutes * 60));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(title: const Text('Focus Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          children: [
            // Mode selector
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: BwColors.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BwColors.panelBorder),
              ),
              child: Row(
                children: ['Focus', 'Short Break', 'Long Break']
                    .map((m) {
                  final sel = _mode == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectMode(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? const LinearGradient(
                                  colors: [BwColors.purple, BwColors.blue])
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(m,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withOpacity(.35))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 36),

            // Duration presets (only in Focus mode)
            if (_mode == 'Focus')
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: BwColors.panel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BwColors.panelBorder),
                    ),
                    child: Row(
                      children: List.generate(
                        _durations.length,
                        (i) {
                          final d = _durations[i];
                          final sel = d == _selectedMinutes;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDuration(d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? BwColors.teal
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text('${d}m',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? Colors.white
                                                : Colors.white.withOpacity(.3))),
                                    Text(_durationLabels[i],
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: sel
                                                ? Colors.white.withOpacity(.7)
                                                : Colors.white.withOpacity(.2))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),

            // Timer circle
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: _isRunning ? _pulse.value : 1.0,
                child: child,
              ),
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating gradient ring (when running)
                    if (_isRunning)
                      AnimatedBuilder(
                        animation: _rotCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: _rotCtrl.value * 2 * math.pi,
                          child: Container(
                            width: 244,
                            height: 244,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  BwColors.purple,
                                  BwColors.teal,
                                  BwColors.blue,
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                                stops: [0, .3, .5, .5, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Glow
                    if (_isRunning)
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: BwColors.purple.withOpacity(.25),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    // Progress ring
                    ProgressRing(progress: _progress, size: 230),
                    // Time
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_timeStr,
                            style: const TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 2)),
                        Text(
                          _isRunning ? '$_mode...' : 'Pronto',
                          style: TextStyle(
                              fontSize: 12,
                              color: _isRunning
                                  ? BwColors.teal
                                  : Colors.white.withOpacity(.3)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? _pause : _start,
                    icon: Icon(_isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(_isRunning ? 'Pausa' : 'Inizia',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BwColors.panel,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: BwColors.panelBorder),
                    ),
                    child: const Icon(Icons.stop_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Today stats
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: BwColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BwColors.panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oggi',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(_todaySessions.toString(), 'Sessioni', '🎯'),
                      _divider(),
                      _stat(_todayMinutes.toString(), 'Minuti', '⏱'),
                      _divider(),
                      _stat(
                          '${_todaySessions * 60}',
                          'Punti',
                          '⭐'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick breathing CTA
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const BreathingScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BwColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: BwColors.blue.withOpacity(.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BwColors.blue.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🧘',
                          style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hai bisogno di un respiro?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text('Prova un esercizio di respirazione',
                              style: TextStyle(
                                  color: BwColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: BwColors.textMuted, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(.35))),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 40, color: Colors.white.withOpacity(.07));
}

class _CompletionDialog extends StatelessWidget {
  final String mode;
  final int minutes;
  final VoidCallback onContinue;
  const _CompletionDialog(
      {required this.mode,
      required this.minutes,
      required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isFocus = mode == 'Focus';
    return Dialog(
      backgroundColor: BwColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFocus ? '🎉' : '✅',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              isFocus ? 'Sessione completata!' : 'Pausa finita!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (isFocus) ...[
              Text('$minutes minuti di focus',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: BwColors.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('+60 punti ⭐',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: BwColors.amber)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Continua'),
            ),
          ],
        ),
      ),
    );
  }
}
