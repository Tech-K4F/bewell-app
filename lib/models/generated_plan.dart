// ═══════════════════════════════════════════════════════════════════════════
// PIANO GENERATO — output dell'IF-THEN engine
// ═══════════════════════════════════════════════════════════════════════════

class GeneratedPlan {
  final List<PlannedActivity> morningActivities;
  final List<PlannedActivity> afternoonActivities;
  final List<PlannedActivity> eveningActivities;
  final int remindersPerDay;
  final int focusSessionMinutes;
  final String workStart;
  final String workEnd;
  final String lunchTime;
  final int lunchDurationMinutes;
  final int totalDailyPoints;
  final List<String> enabledCategories;
  final bool hasHighStressSupport;
  final String calendarToConnect;   // 'google' | 'outlook' | 'apple' | 'none'
  final List<String> flags;         // es: 'eye_strain', 'meeting_fatigue', 'isolation'

  const GeneratedPlan({
    required this.morningActivities,
    required this.afternoonActivities,
    required this.eveningActivities,
    required this.remindersPerDay,
    required this.focusSessionMinutes,
    required this.workStart,
    required this.workEnd,
    required this.lunchTime,
    required this.lunchDurationMinutes,
    required this.totalDailyPoints,
    required this.enabledCategories,
    required this.hasHighStressSupport,
    required this.calendarToConnect,
    required this.flags,
  });

  List<PlannedActivity> get allActivities => [
        ...morningActivities,
        ...afternoonActivities,
        ...eveningActivities,
      ];

  Map<String, dynamic> toJson() => {
        'morningActivities': morningActivities.map((a) => a.toJson()).toList(),
        'afternoonActivities':
            afternoonActivities.map((a) => a.toJson()).toList(),
        'eveningActivities': eveningActivities.map((a) => a.toJson()).toList(),
        'remindersPerDay': remindersPerDay,
        'focusSessionMinutes': focusSessionMinutes,
        'workStart': workStart,
        'workEnd': workEnd,
        'lunchTime': lunchTime,
        'lunchDurationMinutes': lunchDurationMinutes,
        'totalDailyPoints': totalDailyPoints,
        'enabledCategories': enabledCategories,
        'hasHighStressSupport': hasHighStressSupport,
        'calendarToConnect': calendarToConnect,
        'flags': flags,
      };

  factory GeneratedPlan.fromJson(Map<String, dynamic> j) => GeneratedPlan(
        morningActivities: (j['morningActivities'] as List? ?? [])
            .map((a) => PlannedActivity.fromJson(a))
            .toList(),
        afternoonActivities: (j['afternoonActivities'] as List? ?? [])
            .map((a) => PlannedActivity.fromJson(a))
            .toList(),
        eveningActivities: (j['eveningActivities'] as List? ?? [])
            .map((a) => PlannedActivity.fromJson(a))
            .toList(),
        remindersPerDay: j['remindersPerDay'] ?? 4,
        focusSessionMinutes: j['focusSessionMinutes'] ?? 25,
        workStart: j['workStart'] ?? '09:00',
        workEnd: j['workEnd'] ?? '18:00',
        lunchTime: j['lunchTime'] ?? '13:00',
        lunchDurationMinutes: j['lunchDurationMinutes'] ?? 30,
        totalDailyPoints: j['totalDailyPoints'] ?? 0,
        enabledCategories:
            List<String>.from(j['enabledCategories'] ?? []),
        hasHighStressSupport: j['hasHighStressSupport'] ?? false,
        calendarToConnect: j['calendarToConnect'] ?? 'none',
        flags: List<String>.from(j['flags'] ?? []),
      );
}

class PlannedActivity {
  final String activityId;
  final String name;
  final String emoji;
  final String time;        // es: '09:00'
  final int durationMinutes;
  final int points;
  final String category;

  const PlannedActivity({
    required this.activityId,
    required this.name,
    required this.emoji,
    required this.time,
    required this.durationMinutes,
    required this.points,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'name': name,
        'emoji': emoji,
        'time': time,
        'durationMinutes': durationMinutes,
        'points': points,
        'category': category,
      };

  factory PlannedActivity.fromJson(Map<String, dynamic> j) => PlannedActivity(
        activityId: j['activityId'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '🌿',
        time: j['time'] ?? '09:00',
        durationMinutes: j['durationMinutes'] ?? 5,
        points: j['points'] ?? 10,
        category: j['category'] ?? '',
      );
}
