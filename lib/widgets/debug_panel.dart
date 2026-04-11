import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';

// ── Config globale debug ──────────────────────────────────────────────────────
// Questi valori vengono letti da SharedPreferences al runtime
// e modificati dal pannello debug. In produzione sono sempre default.
class DebugConfig {
  static bool enabled = false;
  static double timeAccelerator = 1.0; // 1.0 = tempo reale, 144.0 = 1gg=10min

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('debug_enabled') ?? false;
    timeAccelerator = prefs.getDouble('debug_time_accelerator') ?? 1.0;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_enabled', enabled);
    await prefs.setDouble('debug_time_accelerator', timeAccelerator);
  }

  // Converte giorni reali in giorni simulati
  static int simulatedDays(int realDays) {
    if (!enabled || timeAccelerator <= 1.0) return realDays;
    return (realDays * timeAccelerator).floor();
  }

  // Converte minuti reali in minuti simulati per i reminder
  static int simulatedMinutes(int realMinutes) {
    if (!enabled || timeAccelerator <= 1.0) return realMinutes;
    return (realMinutes / timeAccelerator).ceil().clamp(1, realMinutes);
  }
}

// ── Trigger nascosto ──────────────────────────────────────────────────────────
// Wrappa qualsiasi widget — 7 tap aprono il pannello
class DebugTrigger extends StatefulWidget {
  final Widget child;
  const DebugTrigger({super.key, required this.child});

  @override
  State<DebugTrigger> createState() => _DebugTriggerState();
}

class _DebugTriggerState extends State<DebugTrigger> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _onTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;

    if (_tapCount >= 7) {
      _tapCount = 0;
      _openPanel();
    }
  }

  void _openPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DebugPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

// ── Pannello debug ────────────────────────────────────────────────────────────
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _enabled = DebugConfig.enabled;
  double _accelerator = DebugConfig.timeAccelerator;

  final _acceleratorOptions = [
    (1.0, 'Tempo reale'),
    (12.0, '1 ora = 12 ore'),
    (24.0, '1 ora = 1 giorno'),
    (144.0, '10 min = 1 giorno'),
    (1440.0, '1 min = 1 giorno'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final p = theme.paletteData;
    final progression = context.read<ProgressionProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Handle + titolo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('🛠️',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    const Text(
                      'Debug Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Toggle debug mode
                    Row(
                      children: [
                        Text(
                          _enabled ? 'ON' : 'OFF',
                          style: TextStyle(
                            color: _enabled
                                ? const Color(0xFF1D9E75)
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _enabled,
                          onChanged: (v) async {
                            setState(() => _enabled = v);
                            DebugConfig.enabled = v;
                            if (!v) {
                              _accelerator = 1.0;
                              DebugConfig.timeAccelerator = 1.0;
                            }
                            await DebugConfig.save();
                          },
                          activeColor: const Color(0xFF1D9E75),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [

                // ── Acceleratore tempo ──────────────────────────────
                _Section(
                  title: '⏱ Velocità tempo',
                  child: Column(
                    children: _acceleratorOptions.map((opt) {
                      final selected =
                          (_accelerator - opt.$1).abs() < 0.1;
                      return GestureDetector(
                        onTap: _enabled
                            ? () async {
                                setState(
                                    () => _accelerator = opt.$1);
                                DebugConfig.timeAccelerator = opt.$1;
                                await DebugConfig.save();
                              }
                            : null,
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1D9E75)
                                    .withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1D9E75)
                                  : Colors.white12,
                              width: selected ? 1 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                opt.$2,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF1D9E75)
                                      : Colors.white60,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              if (selected)
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF1D9E75),
                                    size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Stato app ───────────────────────────────────────
                _Section(
                  title: '📅 Stato progressione',
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Giorno app',
                        value:
                            '${progression.appDayNumber} (simulato: ${DebugConfig.simulatedDays(progression.appDayNumber)})',
                      ),
                      _InfoRow(
                        label: 'Fase attuale',
                        value: '${progression.currentPhase} / 5',
                      ),
                      _InfoRow(
                        label: 'Giorni totali',
                        value:
                            '${progression.totalDaysCompleted}',
                      ),
                      _InfoRow(
                        label: 'Abitudini attive',
                        value:
                            '${progression.activeHabits.length}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Sblocco manuale abitudini ───────────────────────
                _Section(
                  title: '🔓 Sblocca abitudine',
                  child: Column(
                    children: HabitLibrary.all
                        .where((h) => !h.isStarter)
                        .map((h) {
                      final status = progression.statusOf(h.id);
                      final isActive =
                          status != HabitStatus.locked;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1D9E75)
                                  .withValues(alpha: 0.1)
                              : Colors.white
                                  .withValues(alpha: 0.04),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF1D9E75)
                                    .withValues(alpha: 0.3)
                                : Colors.white12,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white70
                                          : Colors.white38,
                                      fontSize: 12,
                                      fontWeight: isActive
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    status.name,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isActive)
                              GestureDetector(
                                onTap: () async {
                                  await progression
                                      .acceptHabit(h.id);
                                  setState(() {});
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D9E75)
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          const Color(0xFF1D9E75),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Text(
                                    'Sblocca',
                                    style: TextStyle(
                                      color: Color(0xFF1D9E75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF1D9E75),
                                  size: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Simula giorni ───────────────────────────────────
                _Section(
                  title: '📆 Simula giorni completati',
                  child: Column(
                    children: [
                      Text(
                        'Aggiunge giorni completati all\'abitudine acqua per testare gli sblocchi',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [3, 7, 14, 21].map((days) =>
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                for (int i = 0; i < days; i++) {
                                  // Forza completamento per N giorni
                                  final state = progression
                                      .stateOf('water');
                                  if (state != null) {
                                    state.daysCompleted += 1;
                                    state.lastCompletedAt =
                                        DateTime.now().subtract(
                                            Duration(days: days - i));
                                  }
                                }
                                // Trigger unlock evaluation
                                await progression.forceEvaluate();
                                setState(() {});
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        '+$days giorni simulati'),
                                    backgroundColor:
                                        const Color(0xFF1D9E75),
                                  ));
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    right: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white12,
                                      width: 0.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$days gg',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Reset ───────────────────────────────────────────
                _Section(
                  title: '🗑 Reset',
                  child: Column(
                    children: [
                      _DangerButton(
                        label: 'Sblocca tutto (debug)',
                        onTap: () async {
                          await progression.resetAll();
                          setState(() {});
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _DangerButton(
                        label: 'Reset onboarding Welly',
                        onTap: () async {
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('welly_welcomed');
                          await prefs.remove('welly_name');
                          if (mounted) Navigator.pop(context);
                          Navigator.pushReplacementNamed(
                              context, '/welly-welcome');
                        },
                      ),
                      const SizedBox(height: 8),
                      _DangerButton(
                        label: 'Reset tutto (come nuovo utente)',
                        danger: true,
                        onTap: () async {
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.clear();
                          await progression.resetAll();
                          if (mounted) Navigator.pop(context);
                          Navigator.pushReplacementNamed(
                              context, '/welly-welcome');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Componenti UI debug ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _DangerButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: danger
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: danger ? Colors.red.withValues(alpha: 0.4) : Colors.white12,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: danger ? Colors.redAccent : Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

