// ═══════════════════════════════════════════════════════════════════════════
// MODELLO RISPOSTE QUESTIONARIO — 15 domande su 5 schermate
// ═══════════════════════════════════════════════════════════════════════════

// Numerazione domande allineata all'ordine reale in cui appaiono nelle 5
// schermate (vedi questionnaire_screens.dart). 8 domande dello spec
// originale (occupation, priorApps, calendarSync, reminderFreq,
// breakDuration, lunchTime, hasGymAccess, hasWindowView) sono state rimosse:
// nessuna ifThenRule del catalogo abitudini le usava, e non esiste
// un'abitudine a cui collegarle onestamente senza inventare contenuto nuovo.
class QuestionnaireAnswers {
  // ── S-08A Profile ──────────────────────────────────────────────────────
  final String workLocation;     // Q1: home | office | hybrid | varies

  // ── S-08B Goals & Stress ───────────────────────────────────────────────
  final List<String> goals;      // Q2: stress|focus|health|sleep|energy|weight (multi)
  final int stressLevel;         // Q3: 1-5 (Likert)

  // ── S-08C Health Habits ────────────────────────────────────────────────
  final String sleepHours;       // Q4: <5h | 5-6h | 6-7h | 7-8h | 8h+
  final String hydrationLiters;  // Q5: <1L | 1-1.5L | 1.5-2L | 2L+
  final int screenTimeHours;     // Q6: 0-8 slider
  final String exerciseFreq;     // Q7: never | 1-2x | 3-4x | daily

  // ── S-08D Schedule ─────────────────────────────────────────────────────
  final String scheduleType;     // Q8: fixed | flexible | shift | irregular
  final String lunchDuration;    // Q9: 15m | 30m | 45m | 60m+

  // ── S-08E Environment ──────────────────────────────────────────────────
  final bool hasParkAccess;      // Q10
  final bool hasQuietSpace;      // Q11
  final String distractionLevel; // Q12: low | medium | high | very_high
  final String peakFocusTime;    // Q13: morning | midday | afternoon | evening
  final String focusDuration;    // Q14: <15m | 15-25m | 25-45m | 45m+
  final String meetingLoad;      // Q15: 0-2/day | 2-4/day | 4-6/day | 6+/day

  const QuestionnaireAnswers({
    this.workLocation = 'hybrid',
    this.goals = const ['stress'],
    this.stressLevel = 3,
    this.sleepHours = '6-7h',
    this.hydrationLiters = '1-1.5L',
    this.screenTimeHours = 3,
    this.exerciseFreq = '1-2x',
    this.scheduleType = 'fixed',
    this.lunchDuration = '30m',
    this.hasParkAccess = false,
    this.hasQuietSpace = false,
    this.distractionLevel = 'medium',
    this.peakFocusTime = 'morning',
    this.focusDuration = '25-45m',
    this.meetingLoad = '2-4/day',
  });

  QuestionnaireAnswers copyWith({
    String? workLocation,
    List<String>? goals,
    int? stressLevel,
    String? sleepHours,
    String? hydrationLiters,
    int? screenTimeHours,
    String? exerciseFreq,
    String? scheduleType,
    String? lunchDuration,
    bool? hasParkAccess,
    bool? hasQuietSpace,
    String? distractionLevel,
    String? peakFocusTime,
    String? focusDuration,
    String? meetingLoad,
  }) =>
      QuestionnaireAnswers(
        workLocation: workLocation ?? this.workLocation,
        goals: goals ?? this.goals,
        stressLevel: stressLevel ?? this.stressLevel,
        sleepHours: sleepHours ?? this.sleepHours,
        hydrationLiters: hydrationLiters ?? this.hydrationLiters,
        screenTimeHours: screenTimeHours ?? this.screenTimeHours,
        exerciseFreq: exerciseFreq ?? this.exerciseFreq,
        scheduleType: scheduleType ?? this.scheduleType,
        lunchDuration: lunchDuration ?? this.lunchDuration,
        hasParkAccess: hasParkAccess ?? this.hasParkAccess,
        hasQuietSpace: hasQuietSpace ?? this.hasQuietSpace,
        distractionLevel: distractionLevel ?? this.distractionLevel,
        peakFocusTime: peakFocusTime ?? this.peakFocusTime,
        focusDuration: focusDuration ?? this.focusDuration,
        meetingLoad: meetingLoad ?? this.meetingLoad,
      );

  Map<String, dynamic> toJson() => {
        'workLocation': workLocation,
        'goals': goals,
        'stressLevel': stressLevel,
        'sleepHours': sleepHours,
        'hydrationLiters': hydrationLiters,
        'screenTimeHours': screenTimeHours,
        'exerciseFreq': exerciseFreq,
        'scheduleType': scheduleType,
        'lunchDuration': lunchDuration,
        'hasParkAccess': hasParkAccess,
        'hasQuietSpace': hasQuietSpace,
        'distractionLevel': distractionLevel,
        'peakFocusTime': peakFocusTime,
        'focusDuration': focusDuration,
        'meetingLoad': meetingLoad,
      };

  factory QuestionnaireAnswers.fromJson(Map<String, dynamic> j) =>
      QuestionnaireAnswers(
        workLocation: j['workLocation'] ?? 'hybrid',
        goals: List<String>.from(j['goals'] ?? ['stress']),
        stressLevel: j['stressLevel'] ?? 3,
        sleepHours: j['sleepHours'] ?? '6-7h',
        hydrationLiters: j['hydrationLiters'] ?? '1-1.5L',
        screenTimeHours: j['screenTimeHours'] ?? 3,
        exerciseFreq: j['exerciseFreq'] ?? '1-2x',
        scheduleType: j['scheduleType'] ?? 'fixed',
        lunchDuration: j['lunchDuration'] ?? '30m',
        hasParkAccess: j['hasParkAccess'] ?? false,
        hasQuietSpace: j['hasQuietSpace'] ?? false,
        distractionLevel: j['distractionLevel'] ?? 'medium',
        peakFocusTime: j['peakFocusTime'] ?? 'morning',
        focusDuration: j['focusDuration'] ?? '25-45m',
        meetingLoad: j['meetingLoad'] ?? '2-4/day',
      );
}
