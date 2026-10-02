import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../models/questionnaire_answers.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/stress/breathing_screen.dart';

/// Categorie di abitudine → obiettivi del questionario che servono.
/// Usato solo per mostrare "in linea con il tuo obiettivo" quando c'è un
/// riscontro reale con le risposte dell'utente — mai inventato.
const Map<HabitCategory, List<String>> _categoryGoals = {
  HabitCategory.hydration: ['health', 'energy'],
  HabitCategory.focus: ['focus'],
  HabitCategory.eyes: ['health'],
  HabitCategory.breathing: ['stress'],
  HabitCategory.movement: ['health', 'energy', 'weight'],
  HabitCategory.sleep: ['sleep'],
  HabitCategory.nutrition: ['health', 'weight'],
};

String? _goalLabel(BwStrings s, String goal) {
  switch (goal) {
    case 'stress':
      return s.goalStress;
    case 'focus':
      return s.goalFocus;
    case 'health':
      return s.goalHealth;
    case 'sleep':
      return s.goalSleep;
    case 'energy':
      return s.goalEnergy;
    case 'weight':
      return s.goalWeight;
    default:
      return null;
  }
}

/// Popup di introduzione nuova abitudine.
/// Mostra due opzioni illustrate affiancate — l'utente sceglie una.
/// Supporta ciclo su più coppie via "altre opzioni".
class HabitIntroSheet extends StatefulWidget {
  /// Coppie da mostrare (di solito una, ma possono essere più).
  /// La prima è quella "corrente", le altre accessibili via "altre opzioni".
  final List<(HabitDefinition, HabitDefinition)> pairs;

  /// Callback chiamata con l'ID dell'abitudine scelta (prima del pop).
  final void Function(String habitId)? onHabitChosen;

  const HabitIntroSheet({
    super.key,
    required this.pairs,
    this.onHabitChosen,
  });

  static Future<void> show(
    BuildContext context, {
    required HabitDefinition habitA,
    required HabitDefinition habitB,
    List<(HabitDefinition, HabitDefinition)>? allPairs,
    void Function(String habitId)? onHabitChosen,
  }) {
    final pairs = allPairs ?? [(habitA, habitB)];
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          HabitIntroSheet(pairs: pairs, onHabitChosen: onHabitChosen),
    );
  }

  @override
  State<HabitIntroSheet> createState() => _HabitIntroSheetState();
}

class _HabitIntroSheetState extends State<HabitIntroSheet>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<String> _userGoals = const [];
  late final AnimationController _entryCtrl;

  (HabitDefinition, HabitDefinition) get _currentPair =>
      widget.pairs[_currentIndex];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadGoals();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('questionnaire_answers');
    if (raw == null || !mounted) return;
    try {
      final answers = QuestionnaireAnswers.fromJson(json.decode(raw));
      setState(() => _userGoals = answers.goals);
    } catch (_) {
      // Risposte corrotte/assenti: nessuna riga di motivazione, va bene così.
    }
  }

  /// Primo obiettivo dell'utente servito da questa categoria, se c'è un
  /// riscontro reale — altrimenti null (nessuna riga inventata).
  String? _matchedGoal(HabitDefinition habit) {
    final served = _categoryGoals[habit.category] ?? const [];
    for (final g in _userGoals) {
      if (served.contains(g)) return g;
    }
    return null;
  }

  void _nextPair() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.pairs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final isAmb = context.read<ThemeProvider>().isAmbient;
    final s = context.sL;
    final (habitA, habitB) = _currentPair;

    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: p.textMut.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titolo
          Text(
            s.habitChoiceTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isAmb ? 22 : 18,
              fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
              color: p.text,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            s.habitChoiceSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSec),
          ),

          const SizedBox(height: 24),

          // Le due opzioni affiancate — entrata a cascata (la seconda
          // arriva un attimo dopo la prima): prima apparivano insieme e
          // di scatto, subito dopo una celebrazione a schermo intero —
          // un salto troppo brusco per il momento più identitario
          // dell'app ("quale abitudine costruirò adesso").
          Row(
            children: [
              Expanded(
                child: _AnimatedEntry(
                  controller: _entryCtrl,
                  delay: 0.0,
                  child: _HabitOption(
                    habit: habitA,
                    p: p,
                    isAmb: isAmb,
                    goalLabel: _goalLabel(s, _matchedGoal(habitA) ?? ''),
                    onTap: () => _choose(context, habitA.id),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedEntry(
                  controller: _entryCtrl,
                  delay: 0.15,
                  child: _HabitOption(
                    habit: habitB,
                    p: p,
                    isAmb: isAmb,
                    goalLabel: _goalLabel(s, _matchedGoal(habitB) ?? ''),
                    onTap: () => _choose(context, habitB.id),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // "Altre opzioni" — visibile solo se ci sono più coppie da mostrare
          if (widget.pairs.length > 1)
            Semantics(
                button: true,
                container: true,
                child: GestureDetector(
                  onTap: _nextPair,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      s.habitChoiceShowOther,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSec,
                        decoration: TextDecoration.underline,
                        decorationColor: p.textSec,
                      ),
                    ),
                  ),
                )),

          // "Non mi sento pronto" — non blocca per sempre: rimanda la
          // proposta di 7 giorni invece di lasciarla "pending" a tempo
          // indeterminato (che bloccava anche la valutazione di qualsiasi
          // altra abitudine).
          Semantics(
              button: true,
              container: true,
              child: GestureDetector(
                onTap: () => _declineChoice(context, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    s.habitChoiceNotReady,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textMut,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _choose(BuildContext context, String habitId) {
    context.read<ProgressionProvider>().acceptHabit(habitId);
    // Notifica il chiamante PRIMA del pop così può usare il proprio contesto
    // per triggerare il tutorial (il contesto dello sheet viene invalidato dal pop).
    widget.onHabitChosen?.call(habitId);
    Navigator.pop(context);
    // La conferma visiva è gestita dal BwBanner in home_shell.dart
    // tramite _checkNewHabits() — nessun SnackBar duplicato qui.
  }

  // "Non sono pronto" non deve essere una zona morta di 7 giorni senza
  // nessun altro invito nel frattempo: propone subito qualcosa di leggero
  // e senza impegno (respirazione guidata, sempre disponibile) invece di
  // un semplice "ok, ci risentiamo tra una settimana".
  void _declineChoice(BuildContext context, BwStrings s) {
    context.read<ProgressionProvider>().declineChoice();
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = context;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.habitNotReadySnoozed),
        action: SnackBarAction(
          label: s.habitNotReadyMeanwhile,
          onPressed: () {
            Navigator.of(rootContext).push(
              MaterialPageRoute(
                builder: (_) => const BreathingScreen(habitId: 'breathing_box'),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fade + scorrimento verso l'alto, con un piccolo ritardo per card così
/// la seconda opzione arriva un istante dopo la prima invece che insieme.
class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, (delay + 0.7).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, __) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: child,
        ),
      ),
    );
  }
}

class _HabitOption extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final bool isAmb;
  final String? goalLabel;
  final VoidCallback onTap;

  const _HabitOption({
    required this.habit,
    required this.p,
    required this.isAmb,
    required this.onTap,
    this.goalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Immagine illustrata
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.asset(
                  habit.imageAsset,
                  fit: BoxFit.cover,
                  alignment: habit.imageAlignment,
                  errorBuilder: (_, __, ___) => Container(
                    color: p.primaryLight,
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          color: p.primary, size: 32),
                    ),
                  ),
                ),
              ),
            ),

            // Nome e descrizione — LOCALIZZATI
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.habitName(habit.id),
                    style: TextStyle(
                      fontSize: isAmb ? 16 : 14,
                      fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                      fontFamily: isAmb ? 'CormorantGaramond' : null,
                      color: p.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.habitDesc(habit.id),
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textSec,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // "In linea con il tuo obiettivo" — mostrata solo quando
                  // c'è un riscontro reale con le risposte del questionario,
                  // mai un testo generico buttato lì per sembrare personale.
                  if (goalLabel != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: p.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            s.habitMatchesGoal(goalLabel!),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: p.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Effort indicator
                  Row(
                    children: [
                      ...List.generate(
                          3,
                          (i) => Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i < habit.effort.index + 1
                                        ? p.primary
                                        : p.bg2,
                                  ),
                                ),
                              )),
                      const SizedBox(width: 4),
                      Text(
                        _effortLabel(s, habit.effort),
                        style: TextStyle(fontSize: 9, color: p.textSec),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _effortLabel(BwStrings s, HabitEffort e) {
    switch (e) {
      case HabitEffort.low:
        return s.habitEffortLow;
      case HabitEffort.medium:
        return s.habitEffortMedium;
      case HabitEffort.high:
        return s.habitEffortHigh;
    }
  }
}
