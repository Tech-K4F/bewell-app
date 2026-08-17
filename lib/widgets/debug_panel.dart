import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/inapp_provider.dart';
import '../../models/habit_library.dart';
import 'spotlight_overlay.dart';

// ── Config globale debug ──────────────────────────────────────────────────────
class DebugConfig {
  static bool enabled = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('debug_enabled') ?? false;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_enabled', enabled);
  }
}

// ── Trigger nascosto ──────────────────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    final progression = context.read<ProgressionProvider>();
    final now = DateTime.now();

    // Abitudini completate oggi
    final completedToday = HabitLibrary.all.where((h) {
      final last = progression.stateOf(h.id)?.lastCompletedAt;
      if (last == null) return false;
      return last.year == now.year && last.month == now.month && last.day == now.day;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('🛠️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    const Text(
                      'Debug Panel',
                      style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _enabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _enabled
                            ? const Color(0xFF1D9E75)
                            : Colors.white38,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _enabled,
                      onChanged: (v) async {
                        setState(() => _enabled = v);
                        DebugConfig.enabled = v;
                        await DebugConfig.save();
                      },
                      activeColor: const Color(0xFF1D9E75),
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

                // ── Stato progressione ──────────────────────────────
                _Section(
                  title: '📅 Stato',
                  child: Column(
                    children: [
                      _InfoRow(label: 'Giorno app',      value: '${progression.appDayNumber}'),
                      _InfoRow(label: 'Fase',            value: '${progression.currentPhase} / 5'),
                      _InfoRow(label: 'Giorni totali',   value: '${progression.totalDaysCompleted}'),
                      _InfoRow(label: 'Abitudini attive',value: '${progression.activeHabits.length}'),
                      _InfoRow(
                        label: 'Completate oggi',
                        value: completedToday.isEmpty
                            ? 'nessuna'
                            : completedToday.map((h) => h.id).join(', '),
                      ),
                      _InfoRow(
                        label: 'Nav sbloccate',
                        value: progression.appDayNumber >= 14
                            ? 'home / habits / growth / profile'
                            : progression.appDayNumber >= 4
                                ? 'home / habits / profile'
                                : 'home / profile',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Simula giorni ───────────────────────────────────
                _Section(
                  title: '📆 Simula giorni',
                  child: Column(
                    children: [
                      const Text(
                        'Avanza il giorno app. Giorno 4 sblocca Habits, giorno 14 sblocca Growth. '
                        'I completamenti simulati vengono marcati come "ieri" così puoi testare il flusso di oggi.',
                        style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [1, 3, 7, 14].map((days) =>
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await progression.debugSimulateDays(days);
                                if (!mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '+$days giorni → giorno ${progression.appDayNumber} | fase ${progression.currentPhase}'),
                                    backgroundColor: const Color(0xFF1D9E75),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12, width: 0.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$days gg',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12, fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Reset solo oggi — utile per ri-testare senza perdere progressione
                      GestureDetector(
                        onTap: () async {
                          await progression.debugResetToday();
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completamenti di oggi azzerati — puoi ri-testare il flusso'),
                              backgroundColor: Color(0xFF1D9E75),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                                width: 0.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Reset completamenti di oggi',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12, fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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
                      final isActive = status != HabitStatus.locked;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1D9E75).withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF1D9E75).withValues(alpha: 0.3)
                                : Colors.white12,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: Colors.white30, fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isActive)
                              GestureDetector(
                                onTap: () async {
                                  await progression.acceptHabit(h.id);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D9E75).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFF1D9E75), width: 0.5),
                                  ),
                                  child: const Text(
                                    'Sblocca',
                                    style: TextStyle(
                                      color: Color(0xFF1D9E75),
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF1D9E75), size: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Reset ───────────────────────────────────────────
                _Section(
                  title: '🗑 Reset',
                  child: Column(
                    children: [
                      _DangerButton(
                        label: 'Sblocca tutto (giorno 30)',
                        onTap: () async {
                          await progression.debugUnlockAll();
                          if (!mounted) return;
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _DangerButton(
                        label: 'Reset onboarding Welly',
                        onTap: () async {
                          final nav = Navigator.of(context);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('welly_welcomed');
                          await prefs.remove('welly_name');
                          await prefs.remove('is_onboarded');
                          nav.pop();
                          nav.pushReplacementNamed('/welly-welcome');
                        },
                      ),
                      const SizedBox(height: 8),
                      _DangerButton(
                        label: 'Reset tutto (come nuovo utente)',
                        danger: true,
                        onTap: () async {
                          final nav = Navigator.of(context);
                          final app = context.read<AppProvider>();
                          final inApp = context.read<InAppProvider>();
                          final spotlight = context.read<SpotlightController>();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          await progression.resetAll();
                          // Prima non veniva mai toccato: l'AppProvider in
                          // memoria restava con punti/utente vecchi, e la
                          // prossima _saveUser() li riscriveva su prefs
                          // appena svuotate — il "reset" non teneva.
                          await app.resetOnLogout();
                          // Ricrea subito un profilo pulito dalla sessione
                          // Firebase corrente (l'utente resta loggato) —
                          // altrimenti AppProvider.user resta null finché
                          // non si passa di nuovo dal login vero.
                          await app.onLoginComplete();
                          await inApp.debugReset();
                          for (final tour in [
                            'home_tour', 'habits_tour', 'growth_tour', 'marketplace_tour',
                          ]) {
                            await spotlight.debugReset(tour);
                          }
                          nav.pop();
                          nav.pushReplacementNamed('/welly-welcome');
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
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
            color: danger
                ? Colors.red.withValues(alpha: 0.4)
                : Colors.white12,
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
