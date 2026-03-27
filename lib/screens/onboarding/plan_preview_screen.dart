import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../models/generated_plan.dart';

const _teal = Color(0xFF1E9E87);
const _tealLight = Color(0x1A1E9E87);
const _amber = Color(0xFFD99820);
const _amberLight = Color(0x1FD99820);
const _panel = Color(0xFF0F1F33);
const _panelBorder = Color(0xFF1A2E42);

/// S-10 · Plan Preview
/// Mostra il piano generato prima del primo accesso alla Home.
/// L'utente può confermarlo o aggiustare i parametri di base.
class PlanPreviewScreen extends StatefulWidget {
  const PlanPreviewScreen({super.key});

  @override
  State<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends State<PlanPreviewScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final plan = onb.generatedPlan;

      if (plan == null) {
        return const Scaffold(
          backgroundColor: Color(0xFF0B1929),
          body: Center(child: CircularProgressIndicator(color: _teal)),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0B1929),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(plan),
                      const SizedBox(height: 28),

                      // Sezione mattina
                      if (plan.morningActivities.isNotEmpty) ...[
                        _SectionHeader(label: '🌅 Mattina', time: plan.workStart),
                        const SizedBox(height: 10),
                        ...plan.morningActivities
                            .map((a) => _ActivityRow(activity: a)),
                        const SizedBox(height: 20),
                      ],

                      // Sezione pomeriggio
                      if (plan.afternoonActivities.isNotEmpty) ...[
                        _SectionHeader(
                            label: '☀️ Pomeriggio', time: plan.lunchTime),
                        const SizedBox(height: 10),
                        ...plan.afternoonActivities
                            .map((a) => _ActivityRow(activity: a)),
                        const SizedBox(height: 20),
                      ],

                      // Sezione sera
                      if (plan.eveningActivities.isNotEmpty) ...[
                        _SectionHeader(label: '🌙 Sera', time: '18:00'),
                        const SizedBox(height: 10),
                        ...plan.eveningActivities
                            .map((a) => _ActivityRow(activity: a)),
                        const SizedBox(height: 20),
                      ],

                      // Note piano
                      if (onb.planStatus == PlanGenStatus.error)
                        _buildFallbackNote(),

                      // Calendario da connettere
                      if (plan.calendarToConnect != 'none')
                        _buildCalendarCTA(plan.calendarToConnect),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // CTA bottom
              _buildBottomCTA(context, onb, plan),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(GeneratedPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge "Piano generato"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _tealLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _teal.withOpacity(0.3)),
          ),
          child: const Text(
            '🎉 Piano pronto!',
            style: TextStyle(
                color: _teal, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Il tuo piano\ndi benessere',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalizzato sulle tue risposte. Potrai sempre modificarlo da Impostazioni.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),

        // Stats strip
        Row(
          children: [
            _StatPill(
                emoji: '🔔',
                value: '${plan.remindersPerDay}',
                label: 'reminder/giorno'),
            const SizedBox(width: 8),
            _StatPill(
                emoji: '⏱️',
                value: '${plan.focusSessionMinutes}min',
                label: 'sessioni focus'),
            const SizedBox(width: 8),
            _StatPill(
                emoji: '⭐',
                value: '${plan.totalDailyPoints}',
                label: 'punti/giorno'),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarCTA(String calendar) {
    final labels = {
      'google': ('📅', 'Google Calendar'),
      'outlook': ('📧', 'Outlook'),
      'apple': ('🍎', 'Apple Calendar'),
    };
    final info = labels[calendar] ?? ('📅', 'Calendario');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1A3A7BD5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF3A7BD5).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(info.$1, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connetti ${info.$2}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  'Richiederemo il permesso dopo la conferma',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Color(0xFF3A7BD5), size: 14),
        ],
      ),
    );
  }

  Widget _buildFallbackNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amberLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Abbiamo usato un piano di default. Lo raffineremo man mano che usi l\'app.',
              style: TextStyle(
                  color: _amber.withOpacity(0.9), fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(
    BuildContext context,
    OnboardingProvider onb,
    GeneratedPlan plan,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1929),
        border: Border(top: BorderSide(color: _panelBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isConfirming ? null : () async {
                setState(() => _isConfirming = true);
                await onb.confirmPlan();
                // La navigazione a /home è gestita da OnboardingScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                disabledBackgroundColor: _teal.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Inizia con Be Well  ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text(
                          '+${plan.totalDailyPoints}⭐',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _amber),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Potrai modificare il piano in qualsiasi momento da Impostazioni',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Widget locali ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String time;
  const _SectionHeader({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
        const SizedBox(width: 8),
        Text(
          'dalle $time',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 11),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final PlannedActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _panelBorder),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 44,
            child: Text(
              activity.time,
              style: const TextStyle(
                  color: _teal, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          // Emoji
          Text(activity.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          // Name + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${activity.durationMinutes} min',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11),
                ),
              ],
            ),
          ),
          // Points
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _amberLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${activity.points}⭐',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatPill(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _panelBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
