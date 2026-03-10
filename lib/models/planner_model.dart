class PlannerSettings {
  final String workStart;
  final String workEnd;
  final String breakStrategy; // intensive | balanced | gentle
  final int focusSessionMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool lunchEnabled;
  final String lunchStart;
  final int lunchDurationMinutes;

  const PlannerSettings({
    this.workStart = '09:00',
    this.workEnd = '18:00',
    this.breakStrategy = 'balanced',
    this.focusSessionMinutes = 50,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.lunchEnabled = true,
    this.lunchStart = '13:00',
    this.lunchDurationMinutes = 60,
  });

  PlannerSettings copyWith({
    String? workStart,
    String? workEnd,
    String? breakStrategy,
    int? focusSessionMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? lunchEnabled,
    String? lunchStart,
    int? lunchDurationMinutes,
  }) {
    return PlannerSettings(
      workStart: workStart ?? this.workStart,
      workEnd: workEnd ?? this.workEnd,
      breakStrategy: breakStrategy ?? this.breakStrategy,
      focusSessionMinutes: focusSessionMinutes ?? this.focusSessionMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      lunchStart: lunchStart ?? this.lunchStart,
      lunchDurationMinutes: lunchDurationMinutes ?? this.lunchDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'workStart': workStart,
        'workEnd': workEnd,
        'breakStrategy': breakStrategy,
        'focusSessionMinutes': focusSessionMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'lunchEnabled': lunchEnabled,
        'lunchStart': lunchStart,
        'lunchDurationMinutes': lunchDurationMinutes,
      };

  factory PlannerSettings.fromJson(Map<String, dynamic> j) => PlannerSettings(
        workStart: j['workStart'] ?? '09:00',
        workEnd: j['workEnd'] ?? '18:00',
        breakStrategy: j['breakStrategy'] ?? 'balanced',
        focusSessionMinutes: j['focusSessionMinutes'] ?? 50,
        shortBreakMinutes: j['shortBreakMinutes'] ?? 5,
        longBreakMinutes: j['longBreakMinutes'] ?? 15,
        lunchEnabled: j['lunchEnabled'] ?? true,
        lunchStart: j['lunchStart'] ?? '13:00',
        lunchDurationMinutes: j['lunchDurationMinutes'] ?? 60,
      );
}

class ScheduleBlock {
  final String id;
  final String type; // focus | short_break | long_break | lunch | custom
  final String title;
  final String startTime;
  final String endTime;
  final List<String> activityIds;
  final int points;

  const ScheduleBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.activityIds = const [],
    this.points = 0,
  });

  String get emoji {
    switch (type) {
      case 'focus': return '🧠';
      case 'short_break': return '⚡';
      case 'long_break': return '🧘';
      case 'lunch': return '🍽️';
      default: return '🌿';
    }
  }

  int get durationMinutes {
    final s = _parseTime(startTime);
    final e = _parseTime(endTime);
    return e - s;
  }

  static int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
