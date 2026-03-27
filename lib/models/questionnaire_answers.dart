// ═══════════════════════════════════════════════════════════════════════════
// MODELLO RISPOSTE QUESTIONARIO — 23 domande su 5 schermate
// ═══════════════════════════════════════════════════════════════════════════

class QuestionnaireAnswers {
  // ── S-08A Profile ──────────────────────────────────────────────────────
  final String occupation;       // Q1: student | employee | freelancer | other
  final String workLocation;     // Q2: home | office | hybrid | varies

  // ── S-08B Goals & Stress ───────────────────────────────────────────────
  final List<String> goals;      // Q3: stress|focus|health|sleep|energy|weight (multi)
  final int stressLevel;         // Q4: 1-5 (Likert)
  final String priorApps;        // Q23: none | headspace | calm | other | multiple

  // ── S-08C Health Habits ────────────────────────────────────────────────
  final String sleepHours;       // Q15: <5h | 5-6h | 6-7h | 7-8h | 8h+
  final String hydrationLiters;  // Q16: <1L | 1-1.5L | 1.5-2L | 2L+
  final int screenTimeHours;     // Q17: 0-8 slider
  final String exerciseFreq;     // Q18: never | 1-2x | 3-4x | daily

  // ── S-08D Schedule ─────────────────────────────────────────────────────
  final String scheduleType;     // Q5: fixed | flexible | shift | irregular
  final String calendarSync;     // Q6: google | outlook | apple | none
  final String reminderFreq;     // Q7: minimal | moderate | frequent | very_frequent
  final String breakDuration;    // Q8: 5m | 10m | 15m | 20m+
  final String lunchTime;        // Q9: 11:00-15:00
  final String lunchDuration;    // Q10: 15m | 30m | 45m | 60m+

  // ── S-08E Environment ──────────────────────────────────────────────────
  final bool hasParkAccess;      // Q11
  final bool hasGymAccess;       // Q12
  final bool hasWindowView;      // Q13
  final bool hasQuietSpace;      // Q14
  final String distractionLevel; // Q19: low | medium | high | very_high
  final String peakFocusTime;    // Q20: morning | midday | afternoon | evening
  final String focusDuration;    // Q21: <15m | 15-25m | 25-45m | 45m+
  final String meetingLoad;      // Q22: 0-2/day | 2-4/day | 4-6/day | 6+/day

  const QuestionnaireAnswers({
    this.occupation = 'employee',
    this.workLocation = 'hybrid',
    this.goals = const ['stress'],
    this.stressLevel = 3,
    this.priorApps = 'none',
    this.sleepHours = '6-7h',
    this.hydrationLiters = '1-1.5L',
    this.screenTimeHours = 3,
    this.exerciseFreq = '1-2x',
    this.scheduleType = 'fixed',
    this.calendarSync = 'none',
    this.reminderFreq = 'moderate',
    this.breakDuration = '10m',
    this.lunchTime = '13:00',
    this.lunchDuration = '30m',
    this.hasParkAccess = false,
    this.hasGymAccess = false,
    this.hasWindowView = true,
    this.hasQuietSpace = false,
    this.distractionLevel = 'medium',
    this.peakFocusTime = 'morning',
    this.focusDuration = '25-45m',
    this.meetingLoad = '2-4/day',
  });

  QuestionnaireAnswers copyWith({
    String? occupation,
    String? workLocation,
    List<String>? goals,
    int? stressLevel,
    String? priorApps,
    String? sleepHours,
    String? hydrationLiters,
    int? screenTimeHours,
    String? exerciseFreq,
    String? scheduleType,
    String? calendarSync,
    String? reminderFreq,
    String? breakDuration,
    String? lunchTime,
    String? lunchDuration,
    bool? hasParkAccess,
    bool? hasGymAccess,
    bool? hasWindowView,
    bool? hasQuietSpace,
    String? distractionLevel,
    String? peakFocusTime,
    String? focusDuration,
    String? meetingLoad,
  }) =>
      QuestionnaireAnswers(
        occupation: occupation ?? this.occupation,
        workLocation: workLocation ?? this.workLocation,
        goals: goals ?? this.goals,
        stressLevel: stressLevel ?? this.stressLevel,
        priorApps: priorApps ?? this.priorApps,
        sleepHours: sleepHours ?? this.sleepHours,
        hydrationLiters: hydrationLiters ?? this.hydrationLiters,
        screenTimeHours: screenTimeHours ?? this.screenTimeHours,
        exerciseFreq: exerciseFreq ?? this.exerciseFreq,
        scheduleType: scheduleType ?? this.scheduleType,
        calendarSync: calendarSync ?? this.calendarSync,
        reminderFreq: reminderFreq ?? this.reminderFreq,
        breakDuration: breakDuration ?? this.breakDuration,
        lunchTime: lunchTime ?? this.lunchTime,
        lunchDuration: lunchDuration ?? this.lunchDuration,
        hasParkAccess: hasParkAccess ?? this.hasParkAccess,
        hasGymAccess: hasGymAccess ?? this.hasGymAccess,
        hasWindowView: hasWindowView ?? this.hasWindowView,
        hasQuietSpace: hasQuietSpace ?? this.hasQuietSpace,
        distractionLevel: distractionLevel ?? this.distractionLevel,
        peakFocusTime: peakFocusTime ?? this.peakFocusTime,
        focusDuration: focusDuration ?? this.focusDuration,
        meetingLoad: meetingLoad ?? this.meetingLoad,
      );

  Map<String, dynamic> toJson() => {
        'occupation': occupation,
        'workLocation': workLocation,
        'goals': goals,
        'stressLevel': stressLevel,
        'priorApps': priorApps,
        'sleepHours': sleepHours,
        'hydrationLiters': hydrationLiters,
        'screenTimeHours': screenTimeHours,
        'exerciseFreq': exerciseFreq,
        'scheduleType': scheduleType,
        'calendarSync': calendarSync,
        'reminderFreq': reminderFreq,
        'breakDuration': breakDuration,
        'lunchTime': lunchTime,
        'lunchDuration': lunchDuration,
        'hasParkAccess': hasParkAccess,
        'hasGymAccess': hasGymAccess,
        'hasWindowView': hasWindowView,
        'hasQuietSpace': hasQuietSpace,
        'distractionLevel': distractionLevel,
        'peakFocusTime': peakFocusTime,
        'focusDuration': focusDuration,
        'meetingLoad': meetingLoad,
      };

  factory QuestionnaireAnswers.fromJson(Map<String, dynamic> j) =>
      QuestionnaireAnswers(
        occupation: j['occupation'] ?? 'employee',
        workLocation: j['workLocation'] ?? 'hybrid',
        goals: List<String>.from(j['goals'] ?? ['stress']),
        stressLevel: j['stressLevel'] ?? 3,
        priorApps: j['priorApps'] ?? 'none',
        sleepHours: j['sleepHours'] ?? '6-7h',
        hydrationLiters: j['hydrationLiters'] ?? '1-1.5L',
        screenTimeHours: j['screenTimeHours'] ?? 3,
        exerciseFreq: j['exerciseFreq'] ?? '1-2x',
        scheduleType: j['scheduleType'] ?? 'fixed',
        calendarSync: j['calendarSync'] ?? 'none',
        reminderFreq: j['reminderFreq'] ?? 'moderate',
        breakDuration: j['breakDuration'] ?? '10m',
        lunchTime: j['lunchTime'] ?? '13:00',
        lunchDuration: j['lunchDuration'] ?? '30m',
        hasParkAccess: j['hasParkAccess'] ?? false,
        hasGymAccess: j['hasGymAccess'] ?? false,
        hasWindowView: j['hasWindowView'] ?? true,
        hasQuietSpace: j['hasQuietSpace'] ?? false,
        distractionLevel: j['distractionLevel'] ?? 'medium',
        peakFocusTime: j['peakFocusTime'] ?? 'morning',
        focusDuration: j['focusDuration'] ?? '25-45m',
        meetingLoad: j['meetingLoad'] ?? '2-4/day',
      );
}
