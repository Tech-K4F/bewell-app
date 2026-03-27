import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../models/questionnaire_answers.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

const _teal = Color(0xFF1E9E87);
const _coral = Color(0xFFE05640);

// Wrapper di layout comune per tutte le schermate questionario
class _QuestionnaireShell extends StatelessWidget {
  final int screenNumber;
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkipAll;
  final String nextLabel;

  const _QuestionnaireShell({
    required this.screenNumber,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onNext,
    this.onBack,
    required this.onSkipAll,
    this.nextLabel = 'Avanti →',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1929),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: QuestionnaireProgressBar(
                current: screenNumber,
                total: 5,
                timeRemaining:
                    context.read<OnboardingProvider>().estimatedTimeRemaining,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    body,
                    const SizedBox(height: 28),
                    QuestionnaireNavRow(
                      onNext: onNext,
                      onBack: onBack,
                      onSkipAll: onSkipAll,
                      nextLabel: nextLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08A — PROFILO (Q1 Occupation + Q2 Work Location)
// ═══════════════════════════════════════════════════════════════════════════

class ProfileQuestionnaireScreen extends StatelessWidget {
  const ProfileQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      return _QuestionnaireShell(
        screenNumber: 1,
        title: 'Parlaci di te',
        subtitle: 'Ci aiuta a costruire il piano giusto per te.',
        onNext: onb.nextFromProfile,
        onBack: () => onb.goToStep(OnboardingStep.welcome),
        onSkipAll: onb.skipAll,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q1 — Occupation
            const QuestionLabel(label: 'Q1 · Sono principalmente…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                OptionCard(
                  emoji: '📚',
                  label: 'Studente',
                  selected: a.occupation == 'student',
                  onTap: () => onb.updateAnswers(
                      a.copyWith(occupation: 'student')),
                ),
                OptionCard(
                  emoji: '💼',
                  label: 'Dipendente',
                  selected: a.occupation == 'employee',
                  onTap: () => onb.updateAnswers(
                      a.copyWith(occupation: 'employee')),
                ),
                OptionCard(
                  emoji: '💻',
                  label: 'Freelancer',
                  selected: a.occupation == 'freelancer',
                  onTap: () => onb.updateAnswers(
                      a.copyWith(occupation: 'freelancer')),
                ),
                OptionCard(
                  emoji: '👤',
                  label: 'Altro',
                  selected: a.occupation == 'other',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(occupation: 'other')),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Q2 — Work Location
            const QuestionLabel(label: 'Q2 · Lavoro/studio principalmente…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                OptionCard(
                  emoji: '🏠',
                  label: 'Da casa',
                  selected: a.workLocation == 'home',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'home')),
                ),
                OptionCard(
                  emoji: '🏢',
                  label: 'In ufficio',
                  selected: a.workLocation == 'office',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'office')),
                ),
                OptionCard(
                  emoji: '🔀',
                  label: 'Ibrido',
                  selected: a.workLocation == 'hybrid',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'hybrid')),
                ),
                OptionCard(
                  emoji: '🌍',
                  label: 'Varia',
                  selected: a.workLocation == 'varies',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'varies')),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08B — OBIETTIVI & STRESS (Q3 Goals + Q4 Stress + Q23 Prior apps)
// ═══════════════════════════════════════════════════════════════════════════

class GoalsQuestionnaireScreen extends StatelessWidget {
  const GoalsQuestionnaireScreen({super.key});

  static const _goalOptions = [
    ('stress', '🧘', 'Ridurre lo stress'),
    ('focus', '⏱️', 'Migliorare il focus'),
    ('health', '💧', 'Salute generale'),
    ('sleep', '😴', 'Dormire meglio'),
    ('energy', '⚡', 'Più energia'),
    ('weight', '🏃', 'Forma fisica'),
  ];

  static const _stressEmojis = ['😌', '😊', '😐', '😓', '😰'];
  static const _stressLabels = [
    'Molto calmo', 'Abbastanza calmo', 'Normale',
    'Un po\' stressato', 'Molto stressato'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final showCrisisSupport = a.stressLevel == 5;

      return _QuestionnaireShell(
        screenNumber: 2,
        title: 'Obiettivi & Stress',
        subtitle: 'La schermata più importante per personalizzare il tuo piano.',
        onNext: onb.nextFromGoals,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q3 — Goals (multi-select)
            const QuestionLabel(label: 'Q3 · Cosa vuoi migliorare? (più opzioni)'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: _goalOptions.map((opt) {
                final selected = a.goals.contains(opt.$1);
                return OptionCard(
                  emoji: opt.$2,
                  label: opt.$3,
                  selected: selected,
                  onTap: () {
                    final goals = List<String>.from(a.goals);
                    if (selected) {
                      goals.remove(opt.$1);
                    } else {
                      goals.add(opt.$1);
                    }
                    onb.updateAnswers(a.copyWith(goals: goals.isEmpty ? ['stress'] : goals));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Q4 — Stress Level (Likert 1-5)
            const QuestionLabel(label: 'Q4 · Livello di stress attuale'),
            Center(
              child: Text(
                _stressEmojis[a.stressLevel - 1],
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _stressLabels[a.stressLevel - 1],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Slider(
              value: a.stressLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(stressLevel: v.round())),
              activeColor: _teal,
              inactiveColor: Colors.white.withOpacity(0.1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calmo',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.3))),
                Text('Stressato',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.3))),
              ],
            ),

            // Crisis support (solo Q4=5)
            if (showCrisisSupport) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7BD5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3A7BD5).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stai attraversando un momento difficile',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Be Well è qui per supportarti. Se hai bisogno di aiuto immediato: Telefono Amico 02 2327 2327',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Q23 — Prior apps
            const QuestionLabel(label: 'Q23 · Hai già usato app di benessere?'),
            Column(
              children: [
                for (final opt in [
                  ('none', '🚫', 'No, mai'),
                  ('headspace', '🧠', 'Headspace'),
                  ('calm', '🌊', 'Calm'),
                  ('multiple', '📱', 'Più di una'),
                  ('other', '❓', 'Altra app'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () =>
                          onb.updateAnswers(a.copyWith(priorApps: opt.$1)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: a.priorApps == opt.$1
                              ? const Color(0x1A1E9E87)
                              : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: a.priorApps == opt.$1
                                ? _teal.withOpacity(0.5)
                                : const Color(0xFF1A2E42),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(opt.$2,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Text(
                              opt.$3,
                              style: TextStyle(
                                color: a.priorApps == opt.$1
                                    ? _teal
                                    : Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (a.priorApps == opt.$1) ...[
                              const Spacer(),
                              const Icon(Icons.check_circle,
                                  color: _teal, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08C — SALUTE (Q15 Sleep + Q16 Hydration + Q17 Screen time + Q18 Exercise)
// ═══════════════════════════════════════════════════════════════════════════

class HealthQuestionnaireScreen extends StatelessWidget {
  const HealthQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      return _QuestionnaireShell(
        screenNumber: 3,
        title: 'Le tue abitudini',
        subtitle: 'Calibra la frequenza e il tipo di reminder.',
        onNext: onb.nextFromHealth,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q15 — Sleep
            const QuestionLabel(label: 'Q15 · Di solito dormo…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                for (final s in ['<5h', '5-6h', '6-7h', '7-8h', '8h+'])
                  OptionCard(
                    emoji: s == '7-8h' || s == '8h+' ? '😴' : '😪',
                    label: s,
                    selected: a.sleepHours == s,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(sleepHours: s)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q16 — Hydration
            const QuestionLabel(label: 'Q16 · Bevo circa…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                for (final h in ['<1L', '1-1.5L', '1.5-2L', '2L+'])
                  OptionCard(
                    emoji: '💧',
                    label: h,
                    sublabel: h == '<1L' ? 'poco' : h == '2L+' ? 'ottimo' : null,
                    selected: a.hydrationLiters == h,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(hydrationLiters: h)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q17 — Screen time slider
            LabeledSlider(
              label: 'Q17 · Tempo schermo (svago, escluso lavoro)',
              value: a.screenTimeHours.toDouble(),
              min: 0,
              max: 8,
              divisions: 8,
              valueLabel: (v) => '${v.round()}h',
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(screenTimeHours: v.round())),
            ),
            if (a.screenTimeHours >= 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFD99820), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Attiveremo i reminder occhi più frequenti',
                      style: TextStyle(
                          color: const Color(0xFFD99820).withOpacity(0.8),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Q18 — Exercise
            const QuestionLabel(label: 'Q18 · Faccio esercizio fisico…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                OptionCard(emoji: '🛋️', label: 'Mai', selected: a.exerciseFreq == 'never',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: 'never'))),
                OptionCard(emoji: '🚶', label: '1-2x/settimana', selected: a.exerciseFreq == '1-2x',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: '1-2x'))),
                OptionCard(emoji: '🏃', label: '3-4x/settimana', selected: a.exerciseFreq == '3-4x',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: '3-4x'))),
                OptionCard(emoji: '🏋️', label: 'Ogni giorno', selected: a.exerciseFreq == 'daily',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: 'daily'))),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08D — ORARIO (Q5-Q10)
// ═══════════════════════════════════════════════════════════════════════════

class ScheduleQuestionnaireScreen extends StatelessWidget {
  const ScheduleQuestionnaireScreen({super.key});

  static const _lunchTimes = [
    '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      return _QuestionnaireShell(
        screenNumber: 4,
        title: 'Il tuo orario',
        subtitle: 'Impostiamo i reminder nei momenti giusti.',
        onNext: onb.nextFromSchedule,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q5 — Schedule type
            const QuestionLabel(label: 'Q5 · Il mio orario è…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '📅', label: 'Fisso', selected: a.scheduleType == 'fixed',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'fixed'))),
                OptionCard(emoji: '🔄', label: 'Flessibile', selected: a.scheduleType == 'flexible',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'flexible'))),
                OptionCard(emoji: '🌙', label: 'A turni', selected: a.scheduleType == 'shift',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'shift'))),
                OptionCard(emoji: '⚡', label: 'Irregolare', selected: a.scheduleType == 'irregular',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'irregular'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q6 — Calendar sync (nota: OAuth si fa DOPO S-10)
            const QuestionLabel(label: 'Q6 · Vuoi sincronizzare il calendario?'),
            Column(
              children: [
                for (final cal in [
                  ('google', '📅', 'Google Calendar'),
                  ('outlook', '📧', 'Outlook / Microsoft 365'),
                  ('apple', '🍎', 'Apple Calendar'),
                  ('none', '🚫', 'No grazie, per ora'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () =>
                          onb.updateAnswers(a.copyWith(calendarSync: cal.$1)),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: a.calendarSync == cal.$1
                              ? const Color(0x1A1E9E87)
                              : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: a.calendarSync == cal.$1
                                ? _teal.withOpacity(0.5)
                                : const Color(0xFF1A2E42),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(cal.$2, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(cal.$3,
                                  style: TextStyle(
                                    color: a.calendarSync == cal.$1
                                        ? _teal
                                        : Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  )),
                            ),
                            if (a.calendarSync == cal.$1)
                              const Icon(Icons.check_circle,
                                  color: _teal, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (a.calendarSync != 'none')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '✓ Ti chiederemo i permessi dopo aver confermato il piano',
                  style: TextStyle(
                      color: _teal.withOpacity(0.7), fontSize: 11),
                ),
              ),
            const SizedBox(height: 20),

            // Q7 — Reminder frequency
            const QuestionLabel(label: 'Q7 · Quanti reminder vuoi al giorno?'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                OptionCard(emoji: '🔕', label: 'Minimi', sublabel: '~2/giorno',
                    selected: a.reminderFreq == 'minimal',
                    onTap: () => onb.updateAnswers(a.copyWith(reminderFreq: 'minimal'))),
                OptionCard(emoji: '🔔', label: 'Moderati', sublabel: '~4/giorno',
                    selected: a.reminderFreq == 'moderate',
                    onTap: () => onb.updateAnswers(a.copyWith(reminderFreq: 'moderate'))),
                OptionCard(emoji: '🔔', label: 'Frequenti', sublabel: '~6/giorno',
                    selected: a.reminderFreq == 'frequent',
                    onTap: () => onb.updateAnswers(a.copyWith(reminderFreq: 'frequent'))),
                OptionCard(emoji: '🔊', label: 'Molto freq.', sublabel: '8+/giorno',
                    selected: a.reminderFreq == 'very_frequent',
                    onTap: () => onb.updateAnswers(a.copyWith(reminderFreq: 'very_frequent'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q8 — Break duration
            const QuestionLabel(label: 'Q8 · Pausa ideale…'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                for (final d in ['5m', '10m', '15m', '20m+'])
                  OptionCard(
                    emoji: d == '5m' ? '⚡' : d == '20m+' ? '🧘' : '☕',
                    label: d,
                    selected: a.breakDuration == d,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(breakDuration: d)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q9 + Q10 — Lunch
            const QuestionLabel(label: 'Q9–Q10 · Pausa pranzo'),
            Row(
              children: [
                Expanded(
                  child: CompactTimePicker(
                    label: 'Ora',
                    value: a.lunchTime,
                    onChanged: (v) =>
                        onb.updateAnswers(a.copyWith(lunchTime: v)),
                    options: _lunchTimes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactTimePicker(
                    label: 'Durata',
                    value: a.lunchDuration,
                    onChanged: (v) =>
                        onb.updateAnswers(a.copyWith(lunchDuration: v)),
                    options: ['15m', '30m', '45m', '60m+'],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08E — AMBIENTE & PRODUTTIVITÀ (Q11-Q14, Q19-Q22)
// ═══════════════════════════════════════════════════════════════════════════

class EnvironmentQuestionnaireScreen extends StatelessWidget {
  const EnvironmentQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      return _QuestionnaireShell(
        screenNumber: 5,
        title: 'Ambiente & Produttività',
        subtitle: 'Gli ultimi dettagli per il tuo piano.',
        onNext: onb.submitEnvironmentAndGenerate,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        nextLabel: 'Costruisci il mio piano →',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q11-Q14 — Physical resources
            const QuestionLabel(label: 'Q11–Q14 · Ho accesso a…'),
            ResourceToggle(
              emoji: '🌳',
              label: 'Parco o spazio verde',
              sublabel: 'Per camminate durante la pausa pranzo',
              value: a.hasParkAccess,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasParkAccess: v)),
            ),
            const SizedBox(height: 8),
            ResourceToggle(
              emoji: '🏋️',
              label: 'Palestra o spazio fitness',
              sublabel: 'In ufficio o nelle vicinanze',
              value: a.hasGymAccess,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasGymAccess: v)),
            ),
            const SizedBox(height: 8),
            ResourceToggle(
              emoji: '🪟',
              label: 'Finestra con vista',
              sublabel: 'Per la regola 20-20-20 degli occhi',
              value: a.hasWindowView,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasWindowView: v)),
            ),
            const SizedBox(height: 8),
            ResourceToggle(
              emoji: '🔇',
              label: 'Spazio tranquillo',
              sublabel: 'Per meditazione e concentrazione profonda',
              value: a.hasQuietSpace,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasQuietSpace: v)),
            ),
            const SizedBox(height: 24),

            // Q19 — Distraction level
            const QuestionLabel(label: 'Q19 · Livello di distrazioni nell\'ambiente'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '🤫', label: 'Basso',
                    selected: a.distractionLevel == 'low',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'low'))),
                OptionCard(emoji: '🔈', label: 'Medio',
                    selected: a.distractionLevel == 'medium',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'medium'))),
                OptionCard(emoji: '🔊', label: 'Alto',
                    selected: a.distractionLevel == 'high',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'high'))),
                OptionCard(emoji: '📣', label: 'Molto alto',
                    selected: a.distractionLevel == 'very_high',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'very_high'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q20 — Peak focus time
            const QuestionLabel(label: 'Q20 · Quando sei più concentrato?'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '🌅', label: 'Mattina',
                    selected: a.peakFocusTime == 'morning',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'morning'))),
                OptionCard(emoji: '☀️', label: 'Mezzogiorno',
                    selected: a.peakFocusTime == 'midday',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'midday'))),
                OptionCard(emoji: '🌤️', label: 'Pomeriggio',
                    selected: a.peakFocusTime == 'afternoon',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'afternoon'))),
                OptionCard(emoji: '🌙', label: 'Sera',
                    selected: a.peakFocusTime == 'evening',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'evening'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q21 — Focus duration
            const QuestionLabel(label: 'Q21 · Quanto riesci a concentrarti di fila?'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                for (final d in ['<15m', '15-25m', '25-45m', '45m+'])
                  OptionCard(
                    emoji: d == '<15m' ? '⚡' : d == '45m+' ? '🏆' : '⏱️',
                    label: d,
                    selected: a.focusDuration == d,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(focusDuration: d)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q22 — Meeting load
            const QuestionLabel(label: 'Q22 · Quanti meeting hai al giorno (in media)?'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '📵', label: '0-2 / giorno',
                    selected: a.meetingLoad == '0-2/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '0-2/day'))),
                OptionCard(emoji: '📅', label: '2-4 / giorno',
                    selected: a.meetingLoad == '2-4/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '2-4/day'))),
                OptionCard(emoji: '😓', label: '4-6 / giorno',
                    selected: a.meetingLoad == '4-6/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '4-6/day'))),
                OptionCard(emoji: '😰', label: '6+ / giorno',
                    selected: a.meetingLoad == '6+/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '6+/day'))),
              ],
            ),
          ],
        ),
      );
    });
  }
}
