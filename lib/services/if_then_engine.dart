import '../models/questionnaire_answers.dart';
import '../models/generated_plan.dart';

// ═══════════════════════════════════════════════════════════════════════════
// IF-THEN ENGINE
// Applica le regole dalle specifiche BeWell per generare il piano iniziale.
// Gira interamente lato client — nessuna API esterna necessaria per Day 1-7.
// ═══════════════════════════════════════════════════════════════════════════

class IfThenEngine {
  IfThenEngine._();
  static final instance = IfThenEngine._();

  GeneratedPlan generate(QuestionnaireAnswers q) {
    final flags = _detectFlags(q);
    final focusMinutes = _resolveFocusMinutes(q);
    final remindersPerDay = _resolveRemindersPerDay(q);
    final workStart = _resolveWorkStart(q);
    final workEnd = '18:00';
    final lunchMin = _parseLunchMinutes(q.lunchDuration);

    final morning = _buildMorning(q, flags, focusMinutes);
    final afternoon = _buildAfternoon(q, flags, focusMinutes);
    final evening = _buildEvening(q, flags);

    final allPoints = [...morning, ...afternoon, ...evening]
        .fold(0, (sum, a) => sum + a.points);

    return GeneratedPlan(
      morningActivities: morning,
      afternoonActivities: afternoon,
      eveningActivities: evening,
      remindersPerDay: remindersPerDay,
      focusSessionMinutes: focusMinutes,
      workStart: workStart,
      workEnd: workEnd,
      lunchTime: q.lunchTime,
      lunchDurationMinutes: lunchMin,
      totalDailyPoints: allPoints,
      enabledCategories: _enabledCategories(q, flags),
      hasHighStressSupport: q.stressLevel >= 4,
      calendarToConnect: q.calendarSync,
      flags: flags,
    );
  }

  // ── FLAGS: segnali trasversali che influenzano più regole ───────────────

  List<String> _detectFlags(QuestionnaireAnswers q) {
    final flags = <String>[];

    // Eye strain: schermo ≥5h OPPURE studente/lavoratore intensive PC
    if (q.screenTimeHours >= 5) flags.add('eye_strain');

    // Meeting fatigue: 4+ meeting al giorno + stress ≥4
    if (q.meetingLoad == '4-6/day' || q.meetingLoad == '6+/day') {
      flags.add('meeting_fatigue');
      if (q.stressLevel >= 4) flags.add('heavy_load_high_stress');
    }

    // Isolamento: lavoro da casa + stress ≥3
    if (q.workLocation == 'home' && q.stressLevel >= 3) {
      flags.add('isolation_risk');
    }

    // Sleep deficit
    if (q.sleepHours == '<5h' || q.sleepHours == '5-6h') {
      flags.add('sleep_deficit');
    }

    // Sedentarietà
    if (q.exerciseFreq == 'never') flags.add('sedentary');

    // Digital detox
    if (q.screenTimeHours >= 5) flags.add('digital_detox_candidate');

    // Alto stress (necessita risorse mentale)
    if (q.stressLevel == 5) flags.add('crisis_support');
    if (q.stressLevel >= 4) flags.add('high_stress');

    // Idratazione insufficiente
    if (q.hydrationLiters == '<1L') flags.add('dehydration_risk');

    return flags;
  }

  // ── RIMINDER AL GIORNO ─────────────────────────────────────────────────
  // Regola: Q7=Minimal + Q4=5 → Q4 vince

  int _resolveRemindersPerDay(QuestionnaireAnswers q) {
    int base;
    switch (q.reminderFreq) {
      case 'minimal':
        base = 2;
      case 'moderate':
        base = 4;
      case 'frequent':
        base = 6;
      case 'very_frequent':
        base = 8;
      default:
        base = 4;
    }
    // Override: stress alto forza almeno 4 reminder
    if (q.stressLevel >= 4 && base < 4) base = 4;
    // Studente: sessioni più brevi
    if (q.occupation == 'student') base = (base * 0.8).round();
    return base;
  }

  // ── DURATA FOCUS ───────────────────────────────────────────────────────

  int _resolveFocusMinutes(QuestionnaireAnswers q) {
    switch (q.focusDuration) {
      case '<15m':
        return 15;
      case '15-25m':
        return 20;
      case '25-45m':
        return 25;
      case '45m+':
        return 45;
      default:
        return 25;
    }
  }

  // ── ORARIO INIZIO LAVORO ───────────────────────────────────────────────

  String _resolveWorkStart(QuestionnaireAnswers q) {
    if (q.occupation == 'student') return '08:30';
    if (q.scheduleType == 'flexible') return '09:30';
    if (q.peakFocusTime == 'morning') return '08:00';
    return '09:00';
  }

  int _parseLunchMinutes(String lunchDuration) {
    switch (lunchDuration) {
      case '15m':
        return 15;
      case '30m':
        return 30;
      case '45m':
        return 45;
      case '60m+':
        return 60;
      default:
        return 30;
    }
  }

  // ── MATTINA ───────────────────────────────────────────────────────────

  List<PlannedActivity> _buildMorning(
    QuestionnaireAnswers q,
    List<String> flags,
    int focusMinutes,
  ) {
    final activities = <PlannedActivity>[];
    final workStart = _resolveWorkStart(q);

    // [SEMPRE] Acqua al risveglio
    activities.add(const PlannedActivity(
      activityId: 'HYD001',
      name: 'Bevi un bicchiere d\'acqua',
      emoji: '💧',
      time: '08:00',
      durationMinutes: 1,
      points: 5,
      category: 'Hydration & Nutrition',
    ));

    // [Q4≥3 OR goal=stress] Box breathing mattutino
    if (q.stressLevel >= 3 || q.goals.contains('stress')) {
      activities.add(PlannedActivity(
        activityId: 'STR001',
        name: 'Box Breathing 4-4-4-4',
        emoji: '🧘',
        time: workStart,
        durationMinutes: 3,
        points: 15,
        category: 'Stress & Mindfulness',
      ));
    }

    // [Q17≥3h OR eye_strain] 20-20-20 subito dopo inizio lavoro
    if (flags.contains('eye_strain') || q.screenTimeHours >= 3) {
      activities.add(PlannedActivity(
        activityId: 'VIS001',
        name: 'Regola 20-20-20',
        emoji: '👁️',
        time: _addMinutes(workStart, 20),
        durationMinutes: 1,
        points: 5,
        category: 'Eyes & Vision',
      ));
    }

    // [goal=focus OR peak=morning] Focus session mattutina
    if (q.goals.contains('focus') || q.peakFocusTime == 'morning') {
      activities.add(PlannedActivity(
        activityId: 'FOC001',
        name: 'Sessione Focus ${focusMinutes}min',
        emoji: '⏱️',
        time: _addMinutes(workStart, 30),
        durationMinutes: focusMinutes,
        points: focusMinutes >= 45 ? 60 : 30,
        category: 'Focus & Productivity',
      ));
    }

    // [SEMPRE] Pausa attiva 
    activities.add(PlannedActivity(
      activityId: 'MOV001',
      name: 'Pausa attiva — stretching',
      emoji: '🏃',
      time: _addMinutes(workStart, focusMinutes + 45),
      durationMinutes: 5,
      points: 15,
      category: 'Movement & Posture',
    ));

    return activities.take(4).toList(); // Day 1: max 4 attività mattina
  }

  // ── POMERIGGIO ─────────────────────────────────────────────────────────

  List<PlannedActivity> _buildAfternoon(
    QuestionnaireAnswers q,
    List<String> flags,
    int focusMinutes,
  ) {
    final activities = <PlannedActivity>[];
    final lunch = q.lunchTime;

    // [SEMPRE] Acqua dopo pranzo
    activities.add(PlannedActivity(
      activityId: 'HYD002',
      name: 'Bevi acqua dopo pranzo',
      emoji: '💧',
      time: _addMinutes(lunch, _parseLunchMinutes(q.lunchDuration) + 5),
      durationMinutes: 1,
      points: 5,
      category: 'Hydration & Nutrition',
    ));

    // [hasParkAccess AND lunchDuration>=30] Camminata pranzo
    if (q.hasParkAccess && q.lunchDuration != '15m') {
      activities.add(PlannedActivity(
        activityId: 'MOV004',
        name: 'Camminata durante pranzo',
        emoji: '🌳',
        time: _addMinutes(lunch, 5),
        durationMinutes: 15,
        points: 25,
        category: 'Movement & Posture',
      ));
    }

    // [meeting_fatigue OR heavy_load_high_stress] Micro-pausa anti-meeting
    if (flags.contains('meeting_fatigue') ||
        flags.contains('heavy_load_high_stress')) {
      activities.add(const PlannedActivity(
        activityId: 'STR001',
        name: 'Respirazione anti-stress',
        emoji: '🫁',
        time: '14:30',
        durationMinutes: 3,
        points: 15,
        category: 'Stress & Mindfulness',
      ));
    }

    // [peak=afternoon OR goal=focus] Focus session pomeriggio
    if (q.peakFocusTime == 'afternoon' ||
        (q.goals.contains('focus') && q.peakFocusTime != 'morning')) {
      activities.add(PlannedActivity(
        activityId: 'FOC001',
        name: 'Sessione Focus ${focusMinutes}min',
        emoji: '⏱️',
        time: '14:00',
        durationMinutes: focusMinutes,
        points: focusMinutes >= 45 ? 60 : 30,
        category: 'Focus & Productivity',
      ));
    }

    // [eye_strain] Occhi: massaggio e palming
    if (flags.contains('eye_strain')) {
      activities.add(const PlannedActivity(
        activityId: 'VIS004',
        name: 'Massaggio e palming occhi',
        emoji: '👁️',
        time: '15:30',
        durationMinutes: 2,
        points: 10,
        category: 'Eyes & Vision',
      ));
    }

    // [sleep deficit AND !student] Idratazione caffè limit
    if (flags.contains('sleep_deficit') && q.occupation != 'student') {
      activities.add(const PlannedActivity(
        activityId: 'SLP004',
        name: 'Ultimo caffè della giornata',
        emoji: '☕',
        time: '14:30',
        durationMinutes: 1,
        points: 8,
        category: 'Sleep & Recovery',
      ));
    }

    return activities.take(4).toList();
  }

  // ── SERA ───────────────────────────────────────────────────────────────

  List<PlannedActivity> _buildEvening(
    QuestionnaireAnswers q,
    List<String> flags,
  ) {
    final activities = <PlannedActivity>[];

    // [SEMPRE] Shutdown ritual
    activities.add(const PlannedActivity(
      activityId: 'EOD001',
      name: 'Shutdown ritual fine giornata',
      emoji: '✅',
      time: '18:00',
      durationMinutes: 10,
      points: 25,
      category: 'End of Day',
    ));

    // [goal=sleep OR sleep_deficit] Routine pre-sonno
    if (q.goals.contains('sleep') || flags.contains('sleep_deficit')) {
      activities.add(const PlannedActivity(
        activityId: 'SLP002',
        name: 'Wind-down routine',
        emoji: '😴',
        time: '21:30',
        durationMinutes: 20,
        points: 25,
        category: 'Sleep & Recovery',
      ));
    }

    // [goal=stress OR high_stress] Gratitudine serale
    if (q.stressLevel >= 3 || q.goals.contains('stress')) {
      activities.add(const PlannedActivity(
        activityId: 'STR003',
        name: 'Pratica della gratitudine',
        emoji: '🙏',
        time: '21:00',
        durationMinutes: 3,
        points: 15,
        category: 'Stress & Mindfulness',
      ));
    }

    // [digital_detox_candidate] Digital detox serale
    if (flags.contains('digital_detox_candidate')) {
      activities.add(const PlannedActivity(
        activityId: 'EOD002',
        name: 'Detox digitale serale',
        emoji: '📵',
        time: '22:00',
        durationMinutes: 30,
        points: 20,
        category: 'End of Day',
      ));
    }

    return activities.take(3).toList();
  }

  // ── CATEGORIE ABILITATE ────────────────────────────────────────────────

  List<String> _enabledCategories(
    QuestionnaireAnswers q,
    List<String> flags,
  ) {
    final cats = <String>[
      'Hydration & Nutrition',
      'Movement & Posture',
      'Focus & Productivity',
    ];
    if (q.stressLevel >= 2) cats.add('Stress & Mindfulness');
    if (flags.contains('eye_strain')) cats.add('Eyes & Vision');
    if (q.goals.contains('sleep') || flags.contains('sleep_deficit')) {
      cats.add('Sleep & Recovery');
    }
    if (flags.contains('digital_detox_candidate')) cats.add('End of Day');
    return cats;
  }

  // ── UTILITY ───────────────────────────────────────────────────────────

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final totalMin = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
