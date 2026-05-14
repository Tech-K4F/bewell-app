import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../models/user_profile.dart';
import '../models/badge_model.dart' as bw;
import '../models/planner_model.dart';
import '../models/reward_model.dart';
import '../services/analytics_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isOnboarded = false;
  UserProfile? _user;
  List<Activity> _allActivities = [];
  List<Activity> _todayPlan = [];
  Set<String> _completedToday = {};
  int _currentNavIndex = 0;
  PlannerSettings _plannerSettings = const PlannerSettings();
  List<ScheduleBlock> _scheduleBlocks = [];
  Map<String, bool> _enabledActivities = {};
  List<String> _newlyEarnedBadges = [];
  List<RedeemedReward> _redeemedRewards = [];

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  UserProfile? get user => _user;
  List<Activity> get allActivities => _allActivities;
  List<Activity> get todayPlan => _todayPlan;
  Set<String> get completedToday => _completedToday;
  int get currentNavIndex => _currentNavIndex;
  PlannerSettings get plannerSettings => _plannerSettings;
  List<ScheduleBlock> get scheduleBlocks => _scheduleBlocks;
  Map<String, bool> get enabledActivities => _enabledActivities;
  List<String> get newlyEarnedBadges => _newlyEarnedBadges;
  List<RedeemedReward> get redeemedRewards => _redeemedRewards;

  double get todayCompletionPct {
    if (_todayPlan.isEmpty) return 0;
    return _completedToday.length / _todayPlan.length;
  }

  int get completedCount => _completedToday.length;
  int get totalCount => _todayPlan.length;

  List<Activity> activitiesByCategory(String cat) =>
      _allActivities.where((a) => a.category == cat).toList();

  List<String> get categories =>
      _allActivities.map((a) => a.category).toSet().toList()..sort();

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;

      final userJson = prefs.getString('user_profile');
      if (userJson != null) {
        _user = UserProfile.fromJson(json.decode(userJson));
      }

      final plannerJson = prefs.getString('planner_settings');
      if (plannerJson != null) {
        _plannerSettings = PlannerSettings.fromJson(json.decode(plannerJson));
      }

      final enabledJson = prefs.getString('enabled_activities');
      if (enabledJson != null) {
        _enabledActivities = Map<String, bool>.from(json.decode(enabledJson));
      }

      final redeemedJson = prefs.getString('redeemed_rewards');
      if (redeemedJson != null) {
        final list = json.decode(redeemedJson) as List;
        _redeemedRewards =
            list.map((j) => RedeemedReward.fromJson(j)).toList();
      }

      await _loadActivities();
      await _loadCompletedToday(prefs);
      _buildTodayPlan();
      _generateScheduleBlocks();
    } catch (e) {
      debugPrint('AppProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadActivities() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/activities.json');
      final dynamic decoded = json.decode(jsonStr);
      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('activities')) {
        data = decoded['activities'] as List;
      } else {
        data = [];
      }
      _allActivities = data
          .map((j) => Activity.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading activities: $e — using fallback');
      _allActivities = _fallbackActivities();
    }
  }

  Future<void> _loadCompletedToday(SharedPreferences prefs) async {
    final list = prefs.getStringList(_todayKey()) ?? [];
    _completedToday = list.toSet();
  }

  String _todayKey() =>
      'completed_${DateTime.now().toIso8601String().split('T')[0]}';

  // Chiave per il giorno specifico (usata anche per weeklyCompletions)
  String _dateKey(DateTime date) =>
      date.toIso8601String().split('T')[0];

  void _buildTodayPlan() {
    if (_allActivities.isEmpty) {
      _todayPlan = _fallbackActivities();
      return;
    }
    final essential =
        _allActivities.where((a) => a.importance == 'Essential').take(3);
    final recommended =
        _allActivities.where((a) => a.importance == 'Recommended').take(4);
    final optional =
        _allActivities.where((a) => a.importance == 'Optional').take(2);
    _todayPlan = [...essential, ...recommended, ...optional];
  }

  void _generateScheduleBlocks() {
    final s = _plannerSettings;
    _scheduleBlocks = [];
    int timeMin = _parseTime(s.workStart);
    int endMin = _parseTime(s.workEnd);
    int lunchMin = s.lunchEnabled ? _parseTime(s.lunchStart) : -1;
    int blockIdx = 1;

    while (timeMin + s.focusSessionMinutes <= endMin) {
      if (s.lunchEnabled &&
          timeMin < lunchMin &&
          timeMin + s.focusSessionMinutes >= lunchMin) {
        _scheduleBlocks.add(ScheduleBlock(
          id: 'lunch',
          type: 'lunch',
          title: '🍽️ Pausa pranzo',
          startTime: _formatTime(lunchMin),
          endTime: _formatTime(lunchMin + s.lunchDurationMinutes),
          points: 0,
        ));
        timeMin = lunchMin + s.lunchDurationMinutes;
        continue;
      }
      if (s.lunchEnabled &&
          timeMin >= lunchMin &&
          timeMin < lunchMin + s.lunchDurationMinutes) {
        timeMin = lunchMin + s.lunchDurationMinutes;
        continue;
      }

      final focusEnd = timeMin + s.focusSessionMinutes;
      _scheduleBlocks.add(ScheduleBlock(
        id: 'focus_$blockIdx',
        type: 'focus',
        title: '🧠 Focus Session $blockIdx',
        startTime: _formatTime(timeMin),
        endTime: _formatTime(focusEnd),
        points: 60,
      ));
      timeMin = focusEnd;
      blockIdx++;
      if (timeMin >= endMin) break;

      final isLong = blockIdx % 3 == 0;
      final breakDur = isLong ? s.longBreakMinutes : s.shortBreakMinutes;
      final breakEnd = timeMin + breakDur;
      _scheduleBlocks.add(ScheduleBlock(
        id: isLong ? 'long_break_$blockIdx' : 'short_break_$blockIdx',
        type: isLong ? 'long_break' : 'short_break',
        title: isLong ? '🧘 Wellness Break' : '⚡ Pausa Attiva',
        startTime: _formatTime(timeMin),
        endTime: _formatTime(breakEnd),
        activityIds: isLong ? ['MOV003', 'STR001'] : ['STR001', 'VIS001'],
        points: isLong ? 35 : 20,
      ));
      timeMin = breakEnd;
    }
  }

  static int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _formatTime(int totalMin) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ── Attività ───────────────────────────────────────────────────────────────

  // ── Acqua: punti progressivi per bicchiere ───────────────────────────────────
  // Distribuzione su N bicchieri con bonus al punto di mezzo e all'ultimo.
  // Per N=8 → 2-4-6-10-12-14-16-20 (cumulativo).
  // Totale sempre = 20 punti.
  static int waterGlassPoints(int glassNumber, int totalGlasses) {
    if (totalGlasses <= 0) return 0;
    final int half = (totalGlasses / 2).round();
    // Base: 2 per n≤8, 1 per n>8
    final int base = totalGlasses <= 8 ? 2 : 1;
    final int halfBonus = base * 2; // doppio al bicchiere di mezzo

    if (glassNumber == totalGlasses) {
      // Ultimo bicchiere: complementa a 20
      int sumBefore = 0;
      for (int i = 1; i < totalGlasses; i++) {
        sumBefore += (i == half) ? halfBonus : base;
      }
      return (20 - sumBefore).clamp(base, 20);
    }
    if (glassNumber == half) return halfBonus;
    return base;
  }

  /// Aggiunge punti acqua per un singolo bicchiere — nessun tracking sessione.
  Future<void> awardWaterGlass(int pts) async {
    if (_user == null || pts <= 0) return;
    _user = _user!.copyWith(points: _user!.points + pts);
    await _saveUser();
    notifyListeners();
  }

  /// Rimuove punti (undo bicchiere acqua). I punti non scendono sotto zero.
  Future<void> removeWaterGlassPoints(int pts) async {
    if (_user == null || pts <= 0) return;
    final newPts = (_user!.points - pts).clamp(0, 999999);
    _user = _user!.copyWith(points: newPts);
    await _saveUser();
    notifyListeners();
  }

  /// Mappa punti per gli ID delle abitudini (HabitLibrary).
  /// Usata quando completeActivity() viene chiamata con un habitId invece di activityId.
  static const Map<String, int> _habitPoints = {
    'water': 0, // Punti acqua gestiti per-bicchiere via awardWaterGlass()
    'water_morn': 25,
    'focus_25': 40,
    'focus_50': 60,
    'eyes_20_20_20': 15,
    'neck_stretch': 20,
    'postura': 20,
    'breathing_box': 25,
    'breathing_478': 25,
    'walk_lunch': 30,
    'desk_exercise': 20,
    'stretching_active': 25,
    'lunch_park': 30,
    'meditation': 35,
    'sleep_routine': 35,
    'nap': 30,
  };

  static const Map<String, int> _habitMinutes = {
    'water': 1,
    'water_morn': 1,
    'focus_25': 25,
    'focus_50': 50,
    'eyes_20_20_20': 5,
    'neck_stretch': 5,
    'postura': 3,
    'breathing_box': 5,
    'breathing_478': 5,
    'walk_lunch': 15,
    'desk_exercise': 10,
    'stretching_active': 15,
    'lunch_park': 30,
    'meditation': 15,
    'sleep_routine': 20,
    'nap': 20,
  };

  Future<void> completeActivity(String activityId) async {
    if (_completedToday.contains(activityId)) return;
    _completedToday.add(activityId);

    final activity =
        _allActivities.where((a) => a.id == activityId).firstOrNull;
    // Prima cerca nella mappa habit (se chiamato con habitId), poi nell'activity JSON, poi fallback
    final pts = _habitPoints[activityId] ?? activity?.points ?? 10;
    final mins = _habitMinutes[activityId] ?? activity?.durationMinutes ?? 5;

    if (_user != null) {
      // ── FIX 1: Aggiorna streak ─────────────────────────────────────────────
      final newStreak = _calculateStreak();

      // ── FIX 2: Aggiorna weeklyCompletions ──────────────────────────────────
      final todayStr = _dateKey(DateTime.now());
      final updatedWeekly = Map<String, int>.from(_user!.weeklyCompletions);
      updatedWeekly[todayStr] = (updatedWeekly[todayStr] ?? 0) + 1;

      _user = _user!.copyWith(
        points: _user!.points + pts,
        streak: newStreak,
        totalSessions: _user!.totalSessions + 1,
        totalMinutes: _user!.totalMinutes + mins,
        lastActivityDate: DateTime.now(),
        weeklyCompletions: updatedWeekly,
      );
      AnalyticsService.instance.logDayStreak(newStreak);
      await _checkAndAwardBadges();
      await _saveUser();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_todayKey(), _completedToday.toList());
    notifyListeners();
  }

  // ── FIX 1: Calcolo streak reale ─────────────────────────────────────────────
  // Logica: conta i giorni consecutivi a ritroso a partire da oggi
  // in cui l'utente ha completato almeno 1 attività.
  // Usa weeklyCompletions come fonte di verità (chiavi = date ISO).
  int _calculateStreak() {
    if (_user == null) return 0;

    // Includi anche il completamento di oggi (appena aggiunto)
    final todayStr = _dateKey(DateTime.now());
    final completions = Map<String, int>.from(_user!.weeklyCompletions);
    // Aggiungi today se non c'è ancora (il completamento corrente)
    completions[todayStr] = (completions[todayStr] ?? 0) + 1;

    int streak = 0;
    DateTime day = DateTime.now();

    while (true) {
      final key = _dateKey(day);
      if ((completions[key] ?? 0) > 0) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ── Marketplace ────────────────────────────────────────────────────────────
  Future<bool> redeemReward(RewardItem reward) async {
    if (_user == null) return false;
    if (_user!.points < reward.pointsCost) return false;

    _user = _user!.copyWith(points: _user!.points - reward.pointsCost);

    final code = _generateCode(reward.id);

    final redeemed = RedeemedReward(
      rewardId: reward.id,
      rewardTitle: reward.title,
      rewardEmoji: reward.emoji,
      pointsSpent: reward.pointsCost,
      redeemedAt: DateTime.now(),
      code: code,
    );
    _redeemedRewards = [redeemed, ..._redeemedRewards];

    AnalyticsService.instance.logRewardRedeemed(reward.id, reward.pointsCost);
    await _saveUser();
    await _saveRedeemedRewards();
    notifyListeners();
    return true;
  }

  Future<void> markRewardUsed(String code) async {
    final idx = _redeemedRewards.indexWhere((r) => r.code == code);
    if (idx == -1) return;
    _redeemedRewards = List.from(_redeemedRewards)
      ..[idx] = _redeemedRewards[idx].copyWithUsed();
    await _saveRedeemedRewards();
    notifyListeners();
  }

  String _generateCode(String rewardId) {
    final rand = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
        8, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${rewardId.split('_')[0]}-$suffix';
  }

  Future<void> _saveRedeemedRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _redeemedRewards.map((r) => r.toJson()).toList();
    await prefs.setString('redeemed_rewards', json.encode(list));
  }

  // ── Badge ──────────────────────────────────────────────────────────────────
  Future<void> _checkAndAwardBadges() async {
    if (_user == null) return;
    _newlyEarnedBadges = [];

    for (final badge in bw.allBadges) {
      if (_user!.earnedBadgeIds.contains(badge.id)) continue;

      bool earned = false;
      switch (badge.metric) {
        case 'streak':
          earned = _user!.streak >= badge.requiredCount;
          break;
        case 'points':
          earned = _user!.points >= badge.requiredCount;
          break;
        case 'sessions':
          earned = _user!.totalSessions >= badge.requiredCount;
          break;
        case 'completions':
          // Conta completamenti della categoria corrispondente
          earned = _countCompletionsByCategory(badge.category) >=
              badge.requiredCount;
          break;
        case 'plan_complete':
          earned = completedCount >= totalCount && totalCount > 0;
          break;
      }

      if (earned) {
        final updated = List<String>.from(_user!.earnedBadgeIds)..add(badge.id);
        _user = _user!.copyWith(earnedBadgeIds: updated);
        _newlyEarnedBadges.add(badge.id);
      }
    }
  }

  // Conta completamenti totali per categoria badge
  int _countCompletionsByCategory(String badgeCategory) {
    if (_user == null) return 0;
    // Usa totalSessions come proxy — in futuro si può affinare
    // per categoria specifica con un contatore dedicato
    switch (badgeCategory) {
      case 'Stress':
        // Conta sessioni breathing (attività con id STR*)
        return _completedToday
            .where((id) => id.startsWith('STR'))
            .length + (_user!.totalSessions ~/ 5);
      case 'Movimento':
        return _completedToday
            .where((id) => id.startsWith('MOV'))
            .length + (_user!.totalSessions ~/ 5);
      default:
        return _user!.totalSessions;
    }
  }

  void clearNewBadges() {
    _newlyEarnedBadges = [];
    notifyListeners();
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────
  Future<void> completeOnboarding(UserProfile profile) async {
    _user = profile;
    _isOnboarded = true;
    await _saveUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    notifyListeners();
  }

  // ── Planner ────────────────────────────────────────────────────────────────
  Future<void> updatePlannerSettings(PlannerSettings s) async {
    _plannerSettings = s;
    _generateScheduleBlocks();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planner_settings', json.encode(s.toJson()));
    notifyListeners();
  }

  Future<void> toggleActivity(String id, bool enabled) async {
    _enabledActivities[id] = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'enabled_activities', json.encode(_enabledActivities));
    notifyListeners();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _syncFirebaseUser() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final fbName = firebaseUser.displayName ?? '';
    final fbEmail = firebaseUser.email ?? '';
    final fbId = firebaseUser.uid;
    if (_user == null) {
      _user = UserProfile(id: fbId, name: fbName.isNotEmpty ? fbName : 'Utente', email: fbEmail, userType: 'worker');
      _saveUser();
      return;
    }
    final needsUpdate = (fbName.isNotEmpty && (_user!.name.isEmpty || _user!.name == 'Utente' || _user!.name == 'user' || _user!.name == 'ok')) || (fbEmail.isNotEmpty && _user!.email.isEmpty) || _user!.id != fbId;
    if (needsUpdate) {
      _user = UserProfile(id: fbId, name: fbName.isNotEmpty ? fbName : _user!.name, email: fbEmail.isNotEmpty ? fbEmail : _user!.email, userType: _user!.userType, points: _user!.points, streak: _user!.streak, graceSkipsUsed: _user!.graceSkipsUsed, lastActivityDate: _user!.lastActivityDate, earnedBadgeIds: _user!.earnedBadgeIds, settings: _user!.settings, stressLevel: _user!.stressLevel, primaryGoal: _user!.primaryGoal, totalSessions: _user!.totalSessions, totalMinutes: _user!.totalMinutes, weeklyCompletions: _user!.weeklyCompletions);
      _saveUser();
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    _user = UserProfile(
      id: _user!.id,
      name: name,
      email: _user!.email,
      userType: _user!.userType,
      points: _user!.points,
      streak: _user!.streak,
      graceSkipsUsed: _user!.graceSkipsUsed,
      lastActivityDate: _user!.lastActivityDate,
      earnedBadgeIds: _user!.earnedBadgeIds,
      settings: _user!.settings,
      stressLevel: _user!.stressLevel,
      primaryGoal: _user!.primaryGoal,
      totalSessions: _user!.totalSessions,
      totalMinutes: _user!.totalMinutes,
      weeklyCompletions: _user!.weeklyCompletions,
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> resetOnLogout() async {
    _user = null;
    _completedToday.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('user_profile');
    notifyListeners();
  }

  Future<void> onLoginComplete() async {
    await init();
    _syncFirebaseUser();
    notifyListeners();
  }

  void setNavIndex(int i) {
    _currentNavIndex = i;
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _saveUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(_user!.toJson()));
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isOnboarded = false;
    _user = null;
    _completedToday = {};
    _plannerSettings = const PlannerSettings();
    _redeemedRewards = [];
    notifyListeners();
  }

  // ── Fallback attività ──────────────────────────────────────────────────────
  List<Activity> _fallbackActivities() => [
        const Activity(
          id: 'HYD001', category: 'Hydration & Nutrition',
          name: 'Bevi un bicchiere d\'acqua', durationMinutes: 2,
          frequency: '8x/day', notificationType: 'Soft',
          importance: 'Essential', points: 5, pointsCategory: 'base',
          contentType: 'reminder_text', difficulty: 1,
          tags: ['hydration'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
        const Activity(
          id: 'FOC001', category: 'Focus & Productivity',
          name: 'Sessione Focus 25 min', durationMinutes: 25,
          frequency: 'Daily', notificationType: 'Soft',
          importance: 'Essential', points: 60, pointsCategory: 'productivity',
          contentType: 'timer', difficulty: 2,
          tags: ['focus'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
        const Activity(
          id: 'STR001', category: 'Stress & Mindfulness',
          name: 'Box Breathing 4-4-4-4', durationMinutes: 5,
          frequency: 'Daily', notificationType: 'Soft',
          importance: 'Essential', points: 30, pointsCategory: 'wellness',
          contentType: 'guided_breathing', difficulty: 1,
          tags: ['stress', 'breathing'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
        const Activity(
          id: 'MOV001', category: 'Movement & Posture',
          name: 'Pausa attiva — stretching', durationMinutes: 5,
          frequency: 'Every 90 min', notificationType: 'Soft',
          importance: 'Recommended', points: 25, pointsCategory: 'wellness',
          contentType: 'guided_movement', difficulty: 1,
          tags: ['movement'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
        const Activity(
          id: 'VIS001', category: 'Eyes & Vision',
          name: 'Regola 20-20-20', durationMinutes: 1,
          frequency: 'Every 20 min', notificationType: 'Hard',
          importance: 'Recommended', points: 15, pointsCategory: 'safety',
          contentType: 'reminder_text', difficulty: 1,
          tags: ['eyes'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
        const Activity(
          id: 'SLP001', category: 'Sleep & Recovery',
          name: 'Routine pre-sonno', durationMinutes: 10,
          frequency: 'Daily', notificationType: 'Soft',
          importance: 'Recommended', points: 40, pointsCategory: 'wellness',
          contentType: 'guided_relaxation', difficulty: 1,
          tags: ['sleep'], aiPersonalizationFactors: [], b2bRelevant: true,
        ),
      ];
}








