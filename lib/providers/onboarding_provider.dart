import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/questionnaire_answers.dart';

enum OnboardingStep {
  welcome,       // S-07
  profileQ,      // S-08A
  goalsQ,        // S-08B
  healthQ,       // S-08C
  scheduleQ,     // S-08D
  environmentQ,  // S-08E
  done,
}

class OnboardingProvider extends ChangeNotifier {
  OnboardingStep _step = OnboardingStep.welcome;
  QuestionnaireAnswers _answers = const QuestionnaireAnswers();
  bool _wasPartiallyCompleted = false;
  int _questionsAnswered = 0;

  // ── Getters ────────────────────────────────────────────────────────────
  OnboardingStep get step => _step;
  QuestionnaireAnswers get answers => _answers;
  bool get wasPartiallyCompleted => _wasPartiallyCompleted;

  String get estimatedTimeRemaining {
    const questionnaireSteps = [
      OnboardingStep.profileQ,
      OnboardingStep.goalsQ,
      OnboardingStep.healthQ,
      OnboardingStep.scheduleQ,
      OnboardingStep.environmentQ,
    ];
    final idx = questionnaireSteps.indexOf(_step);
    if (idx < 0) return '';
    final minutesLeft = (questionnaireSteps.length - idx) * 0.6;
    return '~${minutesLeft.ceil()} min';
  }

  // ── Init: controlla se c'è un onboarding parziale salvato ─────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final partial = prefs.getString('onboarding_partial');
    if (partial != null) {
      try {
        final data = json.decode(partial);
        _answers = QuestionnaireAnswers.fromJson(data['answers'] ?? {});
        final stepStr = data['step'] as String?;
        if (stepStr != null) {
          _step = OnboardingStep.values.firstWhere(
            (s) => s.name == stepStr,
            orElse: () => OnboardingStep.welcome,
          );
          _wasPartiallyCompleted = true;
        }
      } catch (_) {
        // Ignora dati corrotti — riparti dall'inizio
      }
      notifyListeners();
    }
  }

  // ── Navigazione tra step ──────────────────────────────────────────────

  void goToStep(OnboardingStep step) {
    _step = step;
    _savePartial();
    notifyListeners();
  }

  void nextFromWelcome() => goToStep(OnboardingStep.profileQ);

  void nextFromProfile() {
    _questionsAnswered += 2;
    goToStep(OnboardingStep.goalsQ);
  }

  void nextFromGoals() {
    _questionsAnswered += 3;
    goToStep(OnboardingStep.healthQ);
  }

  void nextFromHealth() {
    _questionsAnswered += 4;
    goToStep(OnboardingStep.scheduleQ);
  }

  void nextFromSchedule() {
    _questionsAnswered += 6;
    goToStep(OnboardingStep.environmentQ);
  }

  /// Ultima schermata del configuratore: salva subito le risposte, senza
  /// generare né mostrare un piano giornaliero — le risposte influenzano da
  /// qui in avanti quali abitudini vengono proposte/sbloccate (vedi
  /// ProgressionProvider._evaluateUnlocks), non un programma orario fisso
  /// costruito una tantum.
  Future<void> submitEnvironment() async {
    _questionsAnswered += 8;
    await _saveAnswersAndFinish();
  }

  void back() {
    switch (_step) {
      case OnboardingStep.profileQ:
        _step = OnboardingStep.welcome;
      case OnboardingStep.goalsQ:
        _step = OnboardingStep.profileQ;
      case OnboardingStep.healthQ:
        _step = OnboardingStep.goalsQ;
      case OnboardingStep.scheduleQ:
        _step = OnboardingStep.healthQ;
      case OnboardingStep.environmentQ:
        _step = OnboardingStep.scheduleQ;
      default:
        break;
    }
    notifyListeners();
  }

  /// Skip tutto il questionario — usa profilo default
  Future<void> skipAll() async {
    _answers = const QuestionnaireAnswers(); // defaults
    await _saveAnswersAndFinish();
  }

  /// Ricomincia il questionario da capo: azzera le risposte e torna al primo
  /// step. A differenza di [skipAll], non genera un piano — l'utente rifà
  /// le domande.
  void restart() {
    _answers = const QuestionnaireAnswers();
    _questionsAnswered = 0;
    goToStep(OnboardingStep.welcome);
  }

  // ── Aggiornamento risposte ─────────────────────────────────────────────

  void updateAnswers(QuestionnaireAnswers updated) {
    _answers = updated;
    notifyListeners();
  }

  // ── Salvataggio risposte e completamento configuratore ─────────────────
  // Le risposte sono lette da ProgressionProvider per influenzare quali
  // abitudini proporre/sbloccare (vedi _loadIfThenAnswers) — non esiste più
  // un piano giornaliero generato una tantum da mostrare all'utente.
  Future<void> _saveAnswersAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    await prefs.remove('onboarding_partial');
    await prefs.setString(
        'questionnaire_answers', json.encode(_answers.toJson()));

    _step = OnboardingStep.done;
    notifyListeners();
  }

  // ── Persistence parziale ──────────────────────────────────────────────

  Future<void> _savePartial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'onboarding_partial',
      json.encode({
        'step': _step.name,
        'answers': _answers.toJson(),
      }),
    );
  }

  Future<void> clearPartial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_partial');
    _wasPartiallyCompleted = false;
  }
}
