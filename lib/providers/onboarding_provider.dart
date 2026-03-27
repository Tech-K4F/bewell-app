import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/questionnaire_answers.dart';
import '../models/generated_plan.dart';
import '../services/if_then_engine.dart';

enum OnboardingStep {
  welcome,       // S-07
  profileQ,      // S-08A
  goalsQ,        // S-08B
  healthQ,       // S-08C
  scheduleQ,     // S-08D
  environmentQ,  // S-08E
  generating,    // S-09
  planPreview,   // S-10
  done,
}

enum PlanGenStatus { idle, loading, success, error }

class OnboardingProvider extends ChangeNotifier {
  OnboardingStep _step = OnboardingStep.welcome;
  QuestionnaireAnswers _answers = const QuestionnaireAnswers();
  GeneratedPlan? _generatedPlan;
  PlanGenStatus _planStatus = PlanGenStatus.idle;
  bool _wasPartiallyCompleted = false;
  int _questionsAnswered = 0;

  // ── Getters ────────────────────────────────────────────────────────────
  OnboardingStep get step => _step;
  QuestionnaireAnswers get answers => _answers;
  GeneratedPlan? get generatedPlan => _generatedPlan;
  PlanGenStatus get planStatus => _planStatus;
  bool get wasPartiallyCompleted => _wasPartiallyCompleted;

  int get currentScreenIndex {
    final screens = [
      OnboardingStep.welcome,
      OnboardingStep.profileQ,
      OnboardingStep.goalsQ,
      OnboardingStep.healthQ,
      OnboardingStep.scheduleQ,
      OnboardingStep.environmentQ,
    ];
    final idx = screens.indexOf(_step);
    return idx < 0 ? 0 : idx;
  }

  int get totalQuestionnaireScreens => 5;

  double get questionnaireProgress {
    const questionnaireSteps = [
      OnboardingStep.profileQ,
      OnboardingStep.goalsQ,
      OnboardingStep.healthQ,
      OnboardingStep.scheduleQ,
      OnboardingStep.environmentQ,
    ];
    final idx = questionnaireSteps.indexOf(_step);
    if (idx < 0) return 0;
    return (idx + 1) / questionnaireSteps.length;
  }

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

  Future<void> submitEnvironmentAndGenerate() async {
    _questionsAnswered += 8;
    goToStep(OnboardingStep.generating);
    await _generatePlan();
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
    goToStep(OnboardingStep.generating);
    await _generatePlan();
  }

  // ── Aggiornamento risposte ─────────────────────────────────────────────

  void updateAnswers(QuestionnaireAnswers updated) {
    _answers = updated;
    notifyListeners();
  }

  // ── Generazione piano ─────────────────────────────────────────────────

  Future<void> _generatePlan() async {
    _planStatus = PlanGenStatus.loading;
    notifyListeners();

    // Simula i 4 step di animazione (vedi spec S-09)
    // In produzione: POST /user/plan/generate con _answers.toJson()
    // Per ora l'engine gira localmente (cold start)
    await Future.delayed(const Duration(milliseconds: 800));  // step 1
    await Future.delayed(const Duration(milliseconds: 1000)); // step 2
    await Future.delayed(const Duration(milliseconds: 1200)); // step 3

    try {
      _generatedPlan = IfThenEngine.instance.generate(_answers);
      _planStatus = PlanGenStatus.success;
      await Future.delayed(const Duration(milliseconds: 800)); // step 4
      goToStep(OnboardingStep.planPreview);
    } catch (e) {
      // Fallback: piano default
      _generatedPlan = IfThenEngine.instance
          .generate(const QuestionnaireAnswers());
      _planStatus = PlanGenStatus.error;
      goToStep(OnboardingStep.planPreview);
    }
  }

  // ── Conferma piano e completamento onboarding ─────────────────────────

  Future<void> confirmPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    await prefs.remove('onboarding_partial');

    // Salva il piano generato
    if (_generatedPlan != null) {
      await prefs.setString(
          'generated_plan', json.encode(_generatedPlan!.toJson()));
    }
    // Salva le risposte per analytics future
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
