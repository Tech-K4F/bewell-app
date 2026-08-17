import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_library.dart';
import '../models/user_profile.dart';
import '../models/reward_model.dart';
import '../services/analytics_service.dart';
import '../services/referral_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isOnboarded = false;
  UserProfile? _user;
  Set<String> _completedToday = {};
  int _currentNavIndex = 0;
  List<RedeemedReward> _redeemedRewards = [];

  // ── Variable ratio reward (Skinner) ───────────────────────────────────────
  // 1 completamento su 5 (random) attiva il "Welly bonus": punti tripli.
  // Non cambia la media attesa di punti in modo significativo, ma aumenta
  // il coinvolgimento tramite rinforzo variabile intermittente.
  bool _lastCompletionWasBonus = false;
  bool get lastCompletionWasBonus => _lastCompletionWasBonus;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  UserProfile? get user => _user;
  Set<String> get completedToday => _completedToday;
  int get currentNavIndex => _currentNavIndex;
  List<RedeemedReward> get redeemedRewards => _redeemedRewards;

  /// True quando l'utente non ha completato nulla né ieri né (finora) oggi.
  /// Segnale di "rischio abbandono" — James Clear never-miss-twice rule.
  bool get shouldShowNeverMissTwiceBanner {
    if (_user == null) return false;
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final todayCount = _user!.weeklyCompletions[today] ?? 0;
    final yesterdayCount = _user!.weeklyCompletions[yesterday] ?? 0;
    return todayCount == 0 && yesterdayCount == 0;
  }

  /// Streak reale calcolata al momento della lettura, non un valore
  /// congelato all'ultimo completamento. `_user.streak` viene aggiornato
  /// solo dentro completeHabit(): senza questo getter, riaprire l'app dopo
  /// un giorno saltato mostrava ancora l'ultimo streak "vivo" accanto al
  /// banner "non fai niente da due giorni" — due segnali contraddittori
  /// nella stessa schermata.
  int get liveStreak {
    if (_user == null) return 0;
    int streak = 0;
    var day = DateTime.now();
    while ((_user!.weeklyCompletions[_dateKey(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;

      final userJson = prefs.getString('user_profile');
      if (userJson != null) {
        _user = UserProfile.fromJson(json.decode(userJson));
      }

      final redeemedJson = prefs.getString('redeemed_rewards');
      if (redeemedJson != null) {
        final list = json.decode(redeemedJson) as List;
        _redeemedRewards =
            list.map((j) => RedeemedReward.fromJson(j)).toList();
      }

      await _loadCompletedToday(prefs);
    } catch (e) {
      debugPrint('AppProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    _claimReferralBonus();
  }

  /// Riscuote in background eventuali punti bonus maturati perché altri utenti
  /// hanno riscattato il nostro codice invito (vedi ReferralService).
  ///
  /// claimPendingBonus() azzera il contatore lato server e restituisce
  /// l'importo in un'unica transazione atomica — ma tra quel momento e
  /// l'accredito locale (addPoints) c'è una finestra in cui un crash
  /// perderebbe i punti per sempre (il server è già a zero, niente da
  /// ri-reclamare al prossimo avvio). Li mettiamo prima in una chiave
  /// SharedPreferences "da accreditare": se l'app muore nel mezzo, il
  /// prossimo avvio la trova ancora lì e completa l'accredito.
  Future<void> _claimReferralBonus() async {
    const pendingKey = 'referral_bonus_pending_credit';
    try {
      final prefs = await SharedPreferences.getInstance();

      final leftover = prefs.getInt(pendingKey);
      if (leftover != null && leftover > 0) {
        await addPoints(leftover);
        await prefs.remove(pendingKey);
      }

      final bonus = await ReferralService.instance.claimPendingBonus();
      if (bonus > 0) {
        await prefs.setInt(pendingKey, bonus);
        await addPoints(bonus);
        await prefs.remove(pendingKey);
      }
    } catch (e) {
      debugPrint('Referral bonus claim error: $e');
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

  /// Registra il completamento di un'abitudine: punti (da [HabitDefinition],
  /// fonte unica di verità — vedi habit_library.dart), streak, sessioni, badge.
  /// Idempotente entro la stessa giornata.
  Future<void> completeHabit(String habitId) async {
    if (_completedToday.contains(habitId)) return;
    _completedToday.add(habitId);

    final habit = HabitLibrary.findById(habitId);
    final basePts = habit?.points ?? 20;
    final mins = habit?.minutes ?? 5;

    // ── Variable ratio reward (Skinner, 1938) ──────────────────────────────
    // 1 completamento su 5 in modo casuale → punti tripli ("Welly Bonus").
    // Il rinforzo intermittente è più efficace di quello fisso per mantenere
    // un comportamento (slot machine effect applicato al benessere).
    // Non cambia il valore medio atteso in modo significativo.
    _lastCompletionWasBonus = basePts > 0 && Random().nextInt(5) == 0;
    final pts = _lastCompletionWasBonus ? basePts * 3 : basePts;

    if (_user != null) {
      final newStreak = _calculateStreak();

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
      if (_lastCompletionWasBonus) {
        AnalyticsService.instance.logWellyBonus(habitId, pts);
      }
      await _saveUser();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_todayKey(), _completedToday.toList());
    notifyListeners();
  }

  // ── Calcolo streak reale ─────────────────────────────────────────────────
  // Conta i giorni consecutivi a ritroso a partire da oggi in cui l'utente
  // ha completato almeno 1 abitudine. Usa weeklyCompletions come fonte di
  // verità (chiavi = date ISO).
  int _calculateStreak() {
    if (_user == null) return 0;

    // Includi anche il completamento di oggi (appena aggiunto)
    final todayStr = _dateKey(DateTime.now());
    final completions = Map<String, int>.from(_user!.weeklyCompletions);
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
    // stock == -1 → illimitato. Senza un backend non c'è vera scarsità
    // cross-utente, ma niente impediva anche a UN SOLO utente di riscattare
    // un premio "scorte: 20" un numero illimitato di volte sullo stesso
    // dispositivo — questo almeno rispetta il numero dichiarato per chi lo
    // riscatta.
    if (reward.stock >= 0) {
      final alreadyRedeemed =
          _redeemedRewards.where((r) => r.rewardId == reward.id).length;
      if (alreadyRedeemed >= reward.stock) return false;
    }

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

  /// Scala [pts] punti dal saldo utente — usato da InAppProvider e futuri provider.
  /// Restituisce true se i punti erano sufficienti e l'operazione è riuscita.
  Future<bool> spendPoints(int pts) async {
    if (_user == null || pts <= 0) return false;
    if (_user!.points < pts) return false;
    _user = _user!.copyWith(points: _user!.points - pts);
    await _saveUser();
    notifyListeners();
    return true;
  }

  /// Aggiunge [pts] punti al saldo utente (rewarded ad, bonus, ecc.).
  Future<void> addPoints(int pts) async {
    if (_user == null || pts <= 0) return;
    _user = _user!.copyWith(points: _user!.points + pts);
    await _saveUser();
    notifyListeners();
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
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
        8, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${rewardId.split('_')[0]}-$suffix';
  }

  Future<void> _saveRedeemedRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _redeemedRewards.map((r) => r.toJson()).toList();
    await prefs.setString('redeemed_rewards', json.encode(list));
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
      _user = _user!.copyWith(
        id: fbId,
        name: fbName.isNotEmpty ? fbName : _user!.name,
        email: fbEmail.isNotEmpty ? fbEmail : _user!.email,
      );
      _saveUser();
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    _user = _user!.copyWith(name: name);
    await _saveUser();
    notifyListeners();
  }

  Future<void> resetOnLogout() async {
    _user = null;
    _completedToday.clear();
    _redeemedRewards = [];
    _isOnboarded = false;
    final p = await SharedPreferences.getInstance();
    await p.remove('user_profile');
    await p.remove('redeemed_rewards');
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
}
