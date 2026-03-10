class UserProfile {
  final String id;
  final String name;
  final String email;
  final String userType; // worker | student | both
  final int points;
  final int streak;
  final int graceSkipsUsed;
  final DateTime? lastActivityDate;
  final List<String> earnedBadgeIds;
  final Map<String, dynamic> settings;
  final int stressLevel; // 1-5
  final String primaryGoal;
  final int totalSessions;
  final int totalMinutes;
  final Map<String, int> weeklyCompletions; // date -> count

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.points = 0,
    this.streak = 0,
    this.graceSkipsUsed = 0,
    this.lastActivityDate,
    this.earnedBadgeIds = const [],
    this.settings = const {},
    this.stressLevel = 3,
    this.primaryGoal = 'stress',
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.weeklyCompletions = const {},
  });

  String get levelName {
    if (points < 100) return 'Seedling';
    if (points < 300) return 'Sprout';
    if (points < 600) return 'Sapling';
    if (points < 1000) return 'Tree';
    if (points < 2000) return 'Forest';
    return 'Grove';
  }

  String get levelEmoji {
    if (points < 100) return '🌱';
    if (points < 300) return '🌿';
    if (points < 600) return '🌳';
    if (points < 1000) return '🌲';
    if (points < 2000) return '🌲🌲';
    return '🌲🌲🌲';
  }

  int get nextLevelThreshold {
    if (points < 100) return 100;
    if (points < 300) return 300;
    if (points < 600) return 600;
    if (points < 1000) return 1000;
    if (points < 2000) return 2000;
    return 9999;
  }

  int get currentLevelBase {
    if (points < 100) return 0;
    if (points < 300) return 100;
    if (points < 600) return 300;
    if (points < 1000) return 600;
    if (points < 2000) return 1000;
    return 2000;
  }

  double get levelProgress {
    final base = currentLevelBase;
    final next = nextLevelThreshold;
    if (next == base) return 1.0;
    return ((points - base) / (next - base)).clamp(0.0, 1.0);
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserProfile copyWith({
    int? points,
    int? streak,
    int? graceSkipsUsed,
    DateTime? lastActivityDate,
    List<String>? earnedBadgeIds,
    Map<String, dynamic>? settings,
    int? totalSessions,
    int? totalMinutes,
    Map<String, int>? weeklyCompletions,
  }) {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      userType: userType,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      graceSkipsUsed: graceSkipsUsed ?? this.graceSkipsUsed,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      settings: settings ?? this.settings,
      stressLevel: stressLevel,
      primaryGoal: primaryGoal,
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'userType': userType,
        'points': points,
        'streak': streak,
        'graceSkipsUsed': graceSkipsUsed,
        'lastActivityDate': lastActivityDate?.toIso8601String(),
        'earnedBadgeIds': earnedBadgeIds,
        'settings': settings,
        'stressLevel': stressLevel,
        'primaryGoal': primaryGoal,
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'weeklyCompletions': weeklyCompletions,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        userType: j['userType'] ?? 'worker',
        points: j['points'] ?? 0,
        streak: j['streak'] ?? 0,
        graceSkipsUsed: j['graceSkipsUsed'] ?? 0,
        lastActivityDate: j['lastActivityDate'] != null
            ? DateTime.tryParse(j['lastActivityDate'])
            : null,
        earnedBadgeIds: List<String>.from(j['earnedBadgeIds'] ?? []),
        settings: Map<String, dynamic>.from(j['settings'] ?? {}),
        stressLevel: j['stressLevel'] ?? 3,
        primaryGoal: j['primaryGoal'] ?? 'stress',
        totalSessions: j['totalSessions'] ?? 0,
        totalMinutes: j['totalMinutes'] ?? 0,
        weeklyCompletions: Map<String, int>.from(j['weeklyCompletions'] ?? {}),
      );
}
