import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// ── Lingue supportate ─────────────────────────────────────────────────────────
enum BwLocale {
  en('en', 'English', '🇬🇧'),
  it('it', 'Italiano', '🇮🇹'),
  fr('fr', 'Français', '🇫🇷'),
  de('de', 'Deutsch', '🇩🇪'),
  es('es', 'Español', '🇪🇸');

  final String code;
  final String label;
  final String flag;
  const BwLocale(this.code, this.label, this.flag);
}

// ── LocaleProvider ────────────────────────────────────────────────────────────
class LocaleProvider extends ChangeNotifier {
  BwLocale _locale = BwLocale.en;
  BwLocale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    _locale = BwLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => BwLocale.en,
    );
    notifyListeners();
  }

  Future<void> setLocale(BwLocale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.code);
    notifyListeners();
  }

  // Shortcut per ottenere le stringhe
  BwStrings get s => BwStrings.of(_locale);
}

// ── Stringhe app ──────────────────────────────────────────────────────────────
abstract class BwStrings {
  static BwStrings of(BwLocale locale) {
    switch (locale) {
      case BwLocale.it: return _It();
      case BwLocale.fr: return _Fr();
      case BwLocale.de: return _De();
      case BwLocale.es: return _Es();
      case BwLocale.en: return _En();
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get appName;
  String get welcome;
  String get welcomeBack;
  String get continueJourney;
  String get login;
  String get register;
  String get email;
  String get password;
  String get forgotPassword;
  String get noAccount;
  String get createOne;
  String get loginWithBiometrics;
  String get orDivider;
  String get loginWithGoogle;
  String get loginWithApple;
  String get attemptsRemaining;
  String get accountLocked;
  String get verifyEmail;
  String get verifyEmailSent;
  String get resendEmail;
  String get confirmPassword;
  String get name;
  String get createAccount;
  String get alreadyHaveAccount;
  String get signIn;
  String get passwordForgotTitle;
  String get passwordForgotSub;
  String get sendResetEmail;
  String get backToLogin;
  String get emailSent;

  // ── Welly onboarding ─────────────────────────────────────────────────────
  String get wellyHi;
  String get wellyIntro;
  String get letsGo;
  String get wellyNameQuestion;
  String get wellyNameSub;
  String get perfect;
  String get firstHabitTitle;
  String get firstHabitBody1;
  String get firstHabitBody2;
  String get drinkFirstGlass;
  String get rewardTitle;
  String get rewardBody;
  String get goToHome;
  String get rewardLocked;

  // ── Home ─────────────────────────────────────────────────────────────────
  String get goodMorning;
  String get phase;
  String get waterToday;
  String get waterGlasses;
  String get waterTrackedInHome;
  String get achievementUnlocked;
  String get newHabitUnlocked;
  String get waterZero;
  String get waterLow;
  String get waterMid;
  String get waterDone;
  String get addGlass;
  String get comingNext;
  String get daysStreak;
  String get points;
  String get days;
  String get unlocksIn;
  String get unlocksTomorrow;
  String get almostReady;

  // ── Percorso ─────────────────────────────────────────────────────────────
  String get yourJourney;
  String get activeHabits;
  String get nextUnlock;
  String get badges;
  String get noBadgesYet;
  String get todayCompleted;
  String get phase1; String get phase2; String get phase3;
  String get phase4; String get phase5;

  // ── Focus ────────────────────────────────────────────────────────────────
  String get focusTitle;
  String get focusPomodoro;
  String get focusSession;
  String get focusBlock;
  String get focusPause;
  String get focusBreak;
  String get focusStop;
  String get focusResume;
  String get focusNewSession;
  String get focusDone;
  String get focusRemaining;
  String get focusSessions;
  String get focusMinutes;
  String get focusStreak;

  // ── Piano ─────────────────────────────────────────────────────────────────
  String get planToday;
  String get planCompleted;

  // ── Profilo ───────────────────────────────────────────────────────────────
  String get profile;
  String get settings;
  String get editName;
  String get changePassword;
  String get appearance;
  String get notifications;
  String get privacy;
  String get support;
  String get logout;
  String get logoutConfirm;
  String get logoutConfirmSub;
  String get cancel;
  String get confirm;
  String get save;
  String get currentPassword;
  String get newPassword;
  String get confirmPasswordShort;
  String get passwordUpdated;
  String get passwordMismatch;
  String get passwordTooShort;
  String get wrongPassword;

  // ── Impostazioni tema ─────────────────────────────────────────────────────
  String get themeTitle;
  String get themeCard;
  String get themeCardDesc;
  String get themeAmbient;
  String get themeAmbientDesc;
  String get palette;
  String get palNatura;
  String get palAria;
  String get palNotte;
  String get palAlba;
  String get palNotteAmb;

  // ── Accessibilità ─────────────────────────────────────────────────────────
  String get accessibility;
  String get highContrast;
  String get highContrastDesc;
  String get largeText;
  String get largeTextDesc;

  // ── Notifiche ─────────────────────────────────────────────────────────────
  String get reminders;
  String get waterReminder;
  String get waterReminderDesc;

  // ── Nav ───────────────────────────────────────────────────────────────────
  String get navHome;
  String get navHabits;
  String get navFocus;
  String get navGrowth;
  String get navPlan;
  String get navRewards;
  String get navProfile;
  String get navUnlockIn;

  // ── Premi ─────────────────────────────────────────────────────────────────
  String get rewards;
  String get rewardsPoints;
  String get rewardsLocked;
  String get rewardsLockedDesc;
  String get rewardsHeader;
  String get rewardsHeaderSub;

  // ── Habit names & descriptions ────────────────────────────────────────────
  String get habitWaterName; String get habitWaterDesc;
  String get habitFocus25Name; String get habitFocus25Desc;
  String get habitEyes2020Name; String get habitEyes2020Desc;
  String get habitNeckName; String get habitNeckDesc;
  String get habitBreathingBoxName; String get habitBreathingBoxDesc;
  String get habitWalkLunchName; String get habitWalkLunchDesc;
  String get habitDeskExName; String get habitDeskExDesc;
  String get habitWaterMornName; String get habitWaterMornDesc;
  String get habitPostureName; String get habitPostureDesc;
  String get habitLunchParkName; String get habitLunchParkDesc;
  String get habitBreathing478Name; String get habitBreathing478Desc;
  String get habitStretchName; String get habitStretchDesc;
  String get habitSnackName; String get habitSnackDesc;
  String get habitLunchNoScreenName; String get habitLunchNoScreenDesc;
  String get habitFocus50Name; String get habitFocus50Desc;
  String get habitMeditationName; String get habitMeditationDesc;
  String get habitStairsName; String get habitStairsDesc;
  String get habitSleepName; String get habitSleepDesc;
  String get habitWakeName; String get habitWakeDesc;
  String get habitNapName; String get habitNapDesc;
  String get habitFocusPhoneName; String get habitFocusPhoneDesc;
  String get habitMicroWalkName; String get habitMicroWalkDesc;
  String get habitDigitalSunsetName; String get habitDigitalSunsetDesc;

  /// Restituisce il nome localizzato di un'abitudine dato il suo ID.
  String habitName(String id) {
    switch (id) {
      case 'water':             return habitWaterName;
      case 'focus_25':          return habitFocus25Name;
      case 'eyes_20_20_20':     return habitEyes2020Name;
      case 'neck_stretch':      return habitNeckName;
      case 'breathing_box':     return habitBreathingBoxName;
      case 'walk_lunch':        return habitWalkLunchName;
      case 'desk_exercise':     return habitDeskExName;
      case 'water_morning':     return habitWaterMornName;
      case 'posture':           return habitPostureName;
      case 'lunch_park':        return habitLunchParkName;
      case 'breathing_478':     return habitBreathing478Name;
      case 'stretching_active': return habitStretchName;
      case 'snack':             return habitSnackName;
      case 'lunch_no_screen':   return habitLunchNoScreenName;
      case 'focus_50':          return habitFocus50Name;
      case 'meditation':        return habitMeditationName;
      case 'stairs':            return habitStairsName;
      case 'sleep_routine':     return habitSleepName;
      case 'wake_consistent':   return habitWakeName;
      case 'nap':               return habitNapName;
      case 'focus_no_phone':    return habitFocusPhoneName;
      case 'micro_walk':        return habitMicroWalkName;
      case 'digital_sunset':    return habitDigitalSunsetName;
      default:                  return id;
    }
  }

  /// Restituisce la descrizione localizzata di un'abitudine dato il suo ID.
  String habitDesc(String id) {
    switch (id) {
      case 'water':             return habitWaterDesc;
      case 'focus_25':          return habitFocus25Desc;
      case 'eyes_20_20_20':     return habitEyes2020Desc;
      case 'neck_stretch':      return habitNeckDesc;
      case 'breathing_box':     return habitBreathingBoxDesc;
      case 'walk_lunch':        return habitWalkLunchDesc;
      case 'desk_exercise':     return habitDeskExDesc;
      case 'water_morning':     return habitWaterMornDesc;
      case 'posture':           return habitPostureDesc;
      case 'lunch_park':        return habitLunchParkDesc;
      case 'breathing_478':     return habitBreathing478Desc;
      case 'stretching_active': return habitStretchDesc;
      case 'snack':             return habitSnackDesc;
      case 'lunch_no_screen':   return habitLunchNoScreenDesc;
      case 'focus_50':          return habitFocus50Desc;
      case 'meditation':        return habitMeditationDesc;
      case 'stairs':            return habitStairsDesc;
      case 'sleep_routine':     return habitSleepDesc;
      case 'wake_consistent':   return habitWakeDesc;
      case 'nap':               return habitNapDesc;
      case 'focus_no_phone':    return habitFocusPhoneDesc;
      case 'micro_walk':        return habitMicroWalkDesc;
      case 'digital_sunset':    return habitDigitalSunsetDesc;
      default:                  return '';
    }
  }

  // ── Habit intro sheet ─────────────────────────────────────────────────────
  String get habitIntroTitle;
  String get habitIntroSubtitle;
  String get habitIntroMoreOptions;
  String get effortLow;
  String get effortMedium;
  String get effortHigh;
  String get daysOfHabits;

  // ── FASE 2: Schermata Abitudini ───────────────────────────────────────────
  String get habitStart;
  String get habitMarkDone;
  String get habitCompletedToday;
  String get habitDaysToNextPhase;
  String get habitsGuide;
  String get habitsAllDone;
  String get habitLate;
  String get habitDetailWhyNow;
  String get habitDetailWhatDoes;
  String get habitDetailHowStart;
  String get habitYourProgress;

  // ── FASE 3: Home migliorata ────────────────────────────────────────────────
  String get homeMomentNow;
  String get homeFirstVisit;
  String get homeReturnAfter2;
  String get homeReturnAfter3to6;
  String get homeReturnAfter7;
  String get homeStreakBroken;
  String get homeResume;

  // ── FASE 4: Crescita / Marketplace ────────────────────────────────────────
  String get growthMarketplaceHeader;
  String get growthMilestones;
  String get growthStats;
  String get growthTotalDays;
  String get growthTotalGlasses;
  String get growthTotalFocusMin;
  String get rewardRedeem;
  String get rewardConfirmTitle;
  String get rewardConfirmBody;
  String get rewardCodeLabel;
  String get rewardCopyCode;
  String get rewardCopied;
  String get rewardNotEnough;
  String get rewardPointsLeft;
  String get rewardUsed;
  String get rewardMarkUsed;
  String get marketplaceGuide;

  // ── FASE 5: Celebrazioni ───────────────────────────────────────────────────
  String get celebrationDay1to6;
  String get celebrationDay7;
  String get celebrationDay14;
  String get celebrationNormal;
  String get celebrationClose;
  String get celebrationPointsToday;
  String get navUnlockHabitsMsg;
  String get navUnlockGrowthMsg;
  String get navNewBadge;

  // ── FASE 6: Notifiche re-engagement ────────────────────────────────────────
  String get notifReturn1day;
  String get notifReturn3days;
  String get notifReturn7days;
  String get notifStreakRisk;
  String get notifMilestoneNear;
  String get notifNewUnlock;

  // ── Never miss twice banner ───────────────────────────────────────────────
  String get neverMissTwiceTitle;
  String get neverMissTwiceBody;
  String get neverMissTwiceCta;

  // ── Welly Bonus ───────────────────────────────────────────────────────────
  String get wellyBonusTitle;
  String get wellyBonusBody;

  // ── Focus screen (nuove stringhe) ─────────────────────────────────────────
  String get focusDeepWork;
  String get focusMinRemaining;
  String get focusBlockOf4;

  // ── Coach messages ────────────────────────────────────────────────────────
  String get coachDay1; String get coachDay3; String get coachDay7;
  String get coachDay14; String get coachGeneral;

  // ── Errori ────────────────────────────────────────────────────────────────
  String get errorNetwork;
  String get errorGeneral;
  String get errorInvalidEmail;
  String get errorWeakPassword;
  String get errorEmailInUse;
  String get errorInvalidCredentials;
}

// ══════════════════════════════════════════════════════════════════════════════
// ENGLISH
// ══════════════════════════════════════════════════════════════════════════════
class _En extends BwStrings {
  String get appName => 'Be Well';
  String get welcome => 'Welcome';
  String get welcomeBack => 'Welcome back';
  String get continueJourney => 'Sign in to continue your journey';
  String get login => 'Sign in';
  String get register => 'Sign up';
  String get email => 'Email';
  String get password => 'Password';
  String get forgotPassword => 'Forgot password?';
  String get noAccount => 'No account yet? ';
  String get createOne => 'Create one';
  String get loginWithBiometrics => 'Sign in with biometrics';
  String get orDivider => 'or';
  String get loginWithGoogle => 'Continue with Google';
  String get loginWithApple => 'Continue with Apple';
  String get attemptsRemaining => 'attempts remaining before lockout';
  String get accountLocked => 'Account temporarily locked';
  String get verifyEmail => 'Verify your email';
  String get verifyEmailSent => 'We sent a verification link to';
  String get resendEmail => 'Resend email';
  String get confirmPassword => 'Confirm password';
  String get name => 'Name';
  String get createAccount => 'Create account';
  String get alreadyHaveAccount => 'Already have an account? ';
  String get signIn => 'Sign in';
  String get passwordForgotTitle => 'Reset password';
  String get passwordForgotSub => 'Enter your email and we\'ll send you a reset link';
  String get sendResetEmail => 'Send reset email';
  String get backToLogin => 'Back to login';
  String get emailSent => 'Email sent';

  String get wellyHi => 'Hi, I\'m Welly.';
  String get wellyIntro => 'Be Well is the first app that guides you step by step in building healthy habits — and rewards you as you do. I\'m not asking you to change everything in one day. Just start with one small thing, with me.';
  String get letsGo => 'Let\'s go';
  String get wellyNameQuestion => 'First things first: what do you want to call me?';
  String get wellyNameSub => 'My name is Welly, but you can give me your own name if you prefer.';
  String get perfect => 'Perfect';
  String get firstHabitTitle => 'First habit: water.';
  String get firstHabitBody1 => 'Your body is 60% water. When you\'re dehydrated by just 2%, concentration drops, mood worsens and you tire more easily. Yet most people drink less than half of what they should.';
  String get firstHabitBody2 => 'We start here: 8 glasses of water. I\'ll remind you when to drink. Then, step by step, we\'ll add new activities as we consolidate previous ones — building healthy habits together that truly work for you.';
  String get drinkFirstGlass => 'Drink the first glass now';
  String get rewardTitle => 'Perfect. One.';
  String get rewardBody => 'Every time you complete something, you earn Be Well points. You\'ll accumulate them without thinking — and you can use them for discount vouchers, gift cards, accessories, premium app features and much more.';
  String get goToHome => 'Go to your home';
  String get rewardLocked => 'Unlocked with points';

  String get goodMorning => 'Good morning,';
  String get phase => 'Phase';
  String get waterToday => 'Water today';
  String get waterGlasses => 'glasses';
  String get waterTrackedInHome => '💧 home';
  String get achievementUnlocked => 'Achievement unlocked!';
  String get newHabitUnlocked => 'New habit unlocked!';
  String get waterZero => 'Start with the first glass.';
  String get waterLow => 'Good start — keep going.';
  String get waterMid => 'More than half — great!';
  String get waterDone => 'Goal reached! 💚';
  String get addGlass => '+ Mark a glass';
  String get comingNext => 'Coming next';
  String get daysStreak => 'day streak';
  String get points => 'pts';
  String get days => 'days';
  String get unlocksIn => 'Unlocks in';
  String get unlocksTomorrow => 'Unlocks tomorrow';
  String get almostReady => 'Almost ready...';

  String get yourJourney => 'Your journey';
  String get activeHabits => 'Active habits';
  String get nextUnlock => 'Coming up';
  String get badges => 'Badges';
  String get noBadgesYet => 'Your badges will appear here as you progress.';
  String get todayCompleted => 'Completed today';
  String get phase1 => 'Seed'; String get phase2 => 'Sprout';
  String get phase3 => 'Young'; String get phase4 => 'Mature';
  String get phase5 => 'Radiant';

  String get focusTitle => 'Focus';
  String get focusPomodoro => 'Pomodoro';
  String get focusSession => 'Focus session';
  String get focusBlock => 'Block';
  String get focusPause => 'Pause';
  String get focusBreak => 'break in';
  String get focusStop => 'Stop';
  String get focusResume => 'Resume';
  String get focusNewSession => 'New session';
  String get focusDone => 'Session complete!';
  String get focusRemaining => 'remaining';
  String get focusSessions => 'sessions';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'streak';

  String get planToday => 'Today';
  String get planCompleted => 'completed';

  String get profile => 'Profile';
  String get settings => 'Settings';
  String get editName => 'Edit name';
  String get changePassword => 'Change password';
  String get appearance => 'Appearance & theme';
  String get notifications => 'Notifications';
  String get privacy => 'Privacy & data';
  String get support => 'Support';
  String get logout => 'Sign out';
  String get logoutConfirm => 'Sign out';
  String get logoutConfirmSub => 'Are you sure?';
  String get cancel => 'Cancel';
  String get confirm => 'Confirm';
  String get save => 'Save';
  String get currentPassword => 'Current password';
  String get newPassword => 'New password';
  String get confirmPasswordShort => 'Confirm';
  String get passwordUpdated => 'Password updated';
  String get passwordMismatch => 'Passwords don\'t match';
  String get passwordTooShort => 'Minimum 8 characters';
  String get wrongPassword => 'Current password is wrong';

  String get themeTitle => 'Appearance';
  String get themeCard => 'Card';
  String get themeCardDesc => 'Cards layout,\nclear typography';
  String get themeAmbient => 'Ambient';
  String get themeAmbientDesc => 'Atmospheric landscape,\neditorial font';
  String get palette => 'Colour tone';
  String get palNatura => 'Calm nature';
  String get palAria => 'Fresh air';
  String get palNotte => 'Deep night';
  String get palAlba => 'Ambient dawn';
  String get palNotteAmb => 'Ambient night';

  String get accessibility => 'Accessibility';
  String get highContrast => 'High contrast';
  String get highContrastDesc => 'Increases text contrast';
  String get largeText => 'Large text';
  String get largeTextDesc => 'Increases font size';

  String get reminders => 'Reminders';
  String get waterReminder => 'Water reminders';
  String get waterReminderDesc => 'Remind me to drink every hour';

  String get navHome => 'Home';
  String get navHabits => 'Habits';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Rewards';
  String get navProfile => 'Profile';
  String get navUnlockIn => 'Unlocks in';

  String get rewards => 'Rewards';
  String get rewardsPoints => 'Be Well points';
  String get rewardsLocked => 'Rewards are coming';
  String get rewardsLockedDesc => 'Keep building habits to unlock your rewards';
  String get rewardsHeader => 'Your rewards';
  String get rewardsHeaderSub => 'Collect what you\'ve sown';

  String get habitWaterName => 'Drink water'; String get habitWaterDesc => '8 glasses throughout the day';
  String get habitFocus25Name => 'Focus session 25 min'; String get habitFocus25Desc => 'One distraction-free Pomodoro';
  String get habitEyes2020Name => '20-20-20 rule'; String get habitEyes2020Desc => 'Every 20 min, look 20ft away for 20 sec';
  String get habitNeckName => 'Neck stretch'; String get habitNeckDesc => '2 min neck and shoulder stretch every hour';
  String get habitBreathingBoxName => 'Box breathing'; String get habitBreathingBoxDesc => '4s inhale, 4s hold, 4s exhale, 4s hold';
  String get habitWalkLunchName => 'Lunch walk'; String get habitWalkLunchDesc => 'A 15-minute walk during your lunch break';
  String get habitDeskExName => 'Desk exercises'; String get habitDeskExDesc => '5 min of active stretching every 2 hours';
  String get habitWaterMornName => 'Morning water'; String get habitWaterMornDesc => 'A glass of water first thing in the morning';
  String get habitPostureName => 'Posture check'; String get habitPostureDesc => 'Check and correct posture every hour';
  String get habitLunchParkName => 'Lunch at the park'; String get habitLunchParkDesc => 'Eat outdoors, away from screens';
  String get habitBreathing478Name => '4-7-8 breathing'; String get habitBreathing478Desc => 'Anti-anxiety: inhale 4s, hold 7s, exhale 8s';
  String get habitStretchName => 'Active stretching'; String get habitStretchDesc => '5 minutes of full body movement';
  String get habitSnackName => 'Healthy snack'; String get habitSnackDesc => 'A nutritious snack mid-morning';
  String get habitLunchNoScreenName => 'Screen-free lunch'; String get habitLunchNoScreenDesc => 'Lunch without phone or computer';
  String get habitFocus50Name => 'Deep focus 50 min'; String get habitFocus50Desc => 'An uninterrupted deep work session';
  String get habitMeditationName => 'Micro-meditation'; String get habitMeditationDesc => '3 minutes of mindful presence';
  String get habitStairsName => 'Take the stairs'; String get habitStairsDesc => 'Choose stairs over the lift';
  String get habitSleepName => 'Pre-sleep routine'; String get habitSleepDesc => '30 minutes screen-free before bed';
  String get habitWakeName => 'Consistent wake time'; String get habitWakeDesc => 'Wake at the same time every day';
  String get habitNapName => 'Power nap 20 min'; String get habitNapDesc => 'A short intentional rest in the afternoon';
  String get habitFocusPhoneName => 'Focus without phone'; String get habitFocusPhoneDesc => 'Phone face-down during focus sessions';
  String get habitMicroWalkName => '5-min micro walk';
  String get habitMicroWalkDesc => '5 minutes walking every 90 minutes — ultradian cycle';
  String get habitDigitalSunsetName => 'Digital sunset';
  String get habitDigitalSunsetDesc => 'No social media in the hour before sleep';

  String get neverMissTwiceTitle => 'Don\'t miss two days in a row.';
  String get neverMissTwiceBody => 'One small action counts. Even a glass of water.';
  String get neverMissTwiceCta => '💧 Add a glass of water';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Triple points this round 🎉';
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min left';
  String get focusBlockOf4 => 'of 4';

  String get coachDay1 => 'First day. The most important one.';
  String get coachDay3 => '3 days. Your body is starting to register it.';
  String get coachDay7 => '7 days. You\'re building something.';
  String get coachDay14 => '2 weeks. This habit is yours now.';
  String get coachGeneral => 'Every day counts. Even the hard ones.';
  String get habitIntroTitle => 'Time to add\nsomething new.';
  String get habitIntroSubtitle => 'Choose where to focus next.';
  String get habitIntroMoreOptions => 'show me other options ›';
  String get effortLow => 'easy';
  String get effortMedium => 'moderate';
  String get effortHigh => 'demanding';
  String get daysOfHabits => 'days of habits';
  String get habitStart => 'Start';
  String get habitMarkDone => 'Done';
  String get habitCompletedToday => 'Done today';
  String get habitDaysToNextPhase => 'to next level';
  String get habitsGuide => 'Your active habits are here. Tap a card to start, or mark "Done" if you\'ve already done it. Every day you complete builds something.';
  String get habitsAllDone => 'All done for today.';
  String get habitLate => 'Late';
  String get habitDetailWhyNow => 'Why now';
  String get habitDetailWhatDoes => 'What it does';
  String get habitDetailHowStart => 'How to start';
  String get habitYourProgress => 'Your progress';
  String get homeMomentNow => 'Right now';
  String get homeFirstVisit => 'This is your home. Come back every day — I\'m here.';
  String get homeReturnAfter2 => 'Welcome back. I missed you.';
  String get homeReturnAfter3to6 => 'Great to see you. You\'re back — and that\'s what matters.';
  String get homeReturnAfter7 => 'There you are. No matter how much time has passed — you\'re here now, and that\'s the starting point.';
  String get homeStreakBroken => 'The streak stopped — but everything you\'ve built is still there. Let\'s continue from here.';
  String get homeResume => 'Let\'s go';
  String get growthMarketplaceHeader => 'Reap what you\'ve sown';
  String get growthMilestones => 'Milestones';
  String get growthStats => 'Statistics';
  String get growthTotalDays => 'Total days';
  String get growthTotalGlasses => 'Glasses of water';
  String get growthTotalFocusMin => 'Focus minutes';
  String get rewardRedeem => 'Redeem';
  String get rewardConfirmTitle => 'Are you sure?';
  String get rewardConfirmBody => 'Points will be deducted.';
  String get rewardCodeLabel => 'Your code';
  String get rewardCopyCode => 'Copy code';
  String get rewardCopied => 'Copied!';
  String get rewardNotEnough => 'Not enough points yet. Keep going with your habits — they arrive faster than you think.';
  String get rewardPointsLeft => 'You\'ll have';
  String get rewardUsed => 'Used';
  String get rewardMarkUsed => 'Mark as used';
  String get marketplaceGuide => 'These are the rewards you can redeem with your points. You earned them — enjoy the choice.';
  String get celebrationDay1to6 => 'All done today. Tomorrow we start again.';
  String get celebrationDay7 => 'A whole week. That\'s no small thing.';
  String get celebrationDay14 => 'Two weeks. You\'re building something solid.';
  String get celebrationNormal => 'Day complete. Welly is satisfied — and you?';
  String get celebrationClose => 'Close';
  String get celebrationPointsToday => 'points today';
  String get navUnlockHabitsMsg => 'There\'s a new section for you. Your habits now have their own space.';
  String get navUnlockGrowthMsg => 'You have enough history now to look at it. Your growth has its own space.';
  String get navNewBadge => 'New';
  String get notifReturn1day => 'How are you? I haven\'t seen you today.';
  String get notifReturn3days => 'I\'m here when you\'re ready. Your habits are waiting for you.';
  String get notifReturn7days => 'A week has passed. No pressure — but when you want to come back, I\'m here.';
  String get notifStreakRisk => 'The day is ending. You still have time.';
  String get notifMilestoneNear => 'You\'re 2 days away from a week in a row. You\'re almost there.';
  String get notifNewUnlock => 'There\'s something new for you. Open Be Well.';

  String get errorNetwork => 'No internet connection';
  String get errorGeneral => 'Something went wrong. Try again.';
  String get errorInvalidEmail => 'Invalid email address';
  String get errorWeakPassword => 'Password is too weak';
  String get errorEmailInUse => 'This email is already in use';
  String get errorInvalidCredentials => 'Incorrect email or password';
}

// ══════════════════════════════════════════════════════════════════════════════
// ITALIANO
// ══════════════════════════════════════════════════════════════════════════════
class _It extends BwStrings {
  String get appName => 'Be Well';
  String get welcome => 'Benvenuto';
  String get welcomeBack => 'Bentornato';
  String get continueJourney => 'Accedi per continuare il tuo percorso';
  String get login => 'Accedi';
  String get register => 'Registrati';
  String get email => 'Email';
  String get password => 'Password';
  String get forgotPassword => 'Password dimenticata?';
  String get noAccount => 'Non hai un account? ';
  String get createOne => 'Creane uno';
  String get loginWithBiometrics => 'Accedi con biometria';
  String get orDivider => 'oppure';
  String get loginWithGoogle => 'Continua con Google';
  String get loginWithApple => 'Continua con Apple';
  String get attemptsRemaining => 'tentativi rimanenti prima del blocco';
  String get accountLocked => 'Account temporaneamente bloccato';
  String get verifyEmail => 'Verifica la tua email';
  String get verifyEmailSent => 'Abbiamo inviato un link di verifica a';
  String get resendEmail => 'Reinvia email';
  String get confirmPassword => 'Conferma password';
  String get name => 'Nome';
  String get createAccount => 'Crea account';
  String get alreadyHaveAccount => 'Hai già un account? ';
  String get signIn => 'Accedi';
  String get passwordForgotTitle => 'Reimposta password';
  String get passwordForgotSub => 'Inserisci la tua email e ti invieremo un link di reset';
  String get sendResetEmail => 'Invia email di reset';
  String get backToLogin => 'Torna al login';
  String get emailSent => 'Email inviata';

  String get wellyHi => 'Ciao, sono Welly.';
  String get wellyIntro => 'Be Well è la prima app che ti guida passo passo nel costruire abitudini sane — e ti premia mentre lo fai. Non ti chiedo di cambiare tutto in un giorno. Ti chiedo solo di iniziare da una cosa piccola, e di farlo con me.';
  String get letsGo => 'Iniziamo';
  String get wellyNameQuestion => 'Prima di tutto: come vuoi chiamarmi?';
  String get wellyNameSub => 'Il mio nome è Welly, ma se preferisci puoi darmi un nome tutto tuo.';
  String get perfect => 'Perfetto';
  String get firstHabitTitle => 'Prima abitudine: l\'acqua.';
  String get firstHabitBody1 => 'Il tuo corpo è composto per il 60% di acqua. Quando sei disidratato anche solo del 2%, la concentrazione cala, l\'umore peggiora e ti stanchi prima. Eppure la maggior parte delle persone beve meno della metà di quello che dovrebbe.';
  String get firstHabitBody2 => 'Oggi partiamo da qui: 8 bicchieri d\'acqua. Ti ricorderò io quando bere. Poi, passo dopo passo, aggiungeremo nuove attività man mano che consolideremo quelle precedenti — costruendo insieme delle sane abitudini che funzionano davvero per te.';
  String get drinkFirstGlass => 'Bevi il primo bicchiere adesso';
  String get rewardTitle => 'Perfetto. Uno.';
  String get rewardBody => 'Ogni volta che completi qualcosa, guadagni punti Be Well. Li accumulerai senza pensarci — e potrai usarli per buoni sconto, voucher, accessori, funzionalità premium nell\'app e molto altro ancora.';
  String get goToHome => 'Vai alla tua home';
  String get rewardLocked => 'Si sbloccano con i punti';

  String get goodMorning => 'Buongiorno,';
  String get phase => 'Fase';
  String get waterToday => 'Acqua oggi';
  String get waterGlasses => 'bicchieri';
  String get waterTrackedInHome => '💧 home';
  String get achievementUnlocked => 'Achievement sbloccato!';
  String get newHabitUnlocked => 'Nuova abitudine sbloccata!';
  String get waterZero => 'Inizia con il primo bicchiere.';
  String get waterLow => 'Stai andando bene — continua così.';
  String get waterMid => 'Più della metà — ottimo!';
  String get waterDone => 'Obiettivo raggiunto! 💚';
  String get addGlass => '+ Segna un bicchiere';
  String get comingNext => 'In arrivo';
  String get daysStreak => 'gg streak';
  String get points => 'pt';
  String get days => 'giorni';
  String get unlocksIn => 'Tra';
  String get unlocksTomorrow => 'Si sblocca domani';
  String get almostReady => 'Quasi pronta...';

  String get yourJourney => 'Il tuo percorso';
  String get activeHabits => 'Abitudini attive';
  String get nextUnlock => 'In arrivo';
  String get badges => 'Badge';
  String get noBadgesYet => 'I tuoi badge appariranno qui man mano che progredisci.';
  String get todayCompleted => 'Completato oggi';
  String get phase1 => 'Seme'; String get phase2 => 'Germoglio';
  String get phase3 => 'Giovane'; String get phase4 => 'Maturo';
  String get phase5 => 'Fiorente';

  String get focusTitle => 'Focus';
  String get focusPomodoro => 'Pomodoro';
  String get focusSession => 'Sessione focus';
  String get focusBlock => 'Blocco';
  String get focusPause => 'Pausa';
  String get focusBreak => 'pausa tra';
  String get focusStop => 'Stop';
  String get focusResume => 'Riprendi';
  String get focusNewSession => 'Nuova sessione';
  String get focusDone => 'Sessione completata!';
  String get focusRemaining => 'rimanenti';
  String get focusSessions => 'sessioni';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'streak';

  String get planToday => 'Oggi';
  String get planCompleted => 'completati';

  String get profile => 'Profilo';
  String get settings => 'Impostazioni';
  String get editName => 'Modifica nome';
  String get changePassword => 'Cambia password';
  String get appearance => 'Aspetto e tema';
  String get notifications => 'Notifiche';
  String get privacy => 'Privacy e dati';
  String get support => 'Supporto';
  String get logout => 'Esci dall\'account';
  String get logoutConfirm => 'Esci dall\'account';
  String get logoutConfirmSub => 'Sei sicuro?';
  String get cancel => 'Annulla';
  String get confirm => 'Conferma';
  String get save => 'Salva';
  String get currentPassword => 'Password attuale';
  String get newPassword => 'Nuova password';
  String get confirmPasswordShort => 'Conferma';
  String get passwordUpdated => 'Password aggiornata';
  String get passwordMismatch => 'Le password non coincidono';
  String get passwordTooShort => 'Minimo 8 caratteri';
  String get wrongPassword => 'Password attuale errata';

  String get themeTitle => 'Aspetto';
  String get themeCard => 'Card';
  String get themeCardDesc => 'Contenuti in schede,\ntipografia chiara';
  String get themeAmbient => 'Ambientale';
  String get themeAmbientDesc => 'Paesaggio atmosferico,\nfont editoriale';
  String get palette => 'Tonalità';
  String get palNatura => 'Natura calma';
  String get palAria => 'Aria fresca';
  String get palNotte => 'Notte profonda';
  String get palAlba => 'Ambientale Alba';
  String get palNotteAmb => 'Ambientale Notte';

  String get accessibility => 'Accessibilità';
  String get highContrast => 'Alto contrasto';
  String get highContrastDesc => 'Aumenta il contrasto dei testi';
  String get largeText => 'Testo grande';
  String get largeTextDesc => 'Aumenta la dimensione dei caratteri';

  String get reminders => 'Notifiche';
  String get waterReminder => 'Promemoria acqua';
  String get waterReminderDesc => 'Ricordami di bere ogni ora';

  String get navHome => 'Home';
  String get navHabits => 'Abitudini';
  String get navFocus => 'Focus';
  String get navGrowth => 'Crescita';
  String get navPlan => 'Piano';
  String get navRewards => 'Premi';
  String get navProfile => 'Profilo';
  String get navUnlockIn => 'Sblocco tra';

  String get rewards => 'Premi';
  String get rewardsPoints => 'Punti Be Well';
  String get rewardsLocked => 'I premi stanno arrivando';
  String get rewardsLockedDesc => 'Continua a costruire abitudini per sbloccare i tuoi premi';
  String get rewardsHeader => 'I tuoi premi';
  String get rewardsHeaderSub => 'Raccogli quello che hai seminato';

  String get habitWaterName => 'Bevi acqua'; String get habitWaterDesc => '8 bicchieri durante la giornata';
  String get habitFocus25Name => 'Sessione focus 25 min'; String get habitFocus25Desc => 'Un Pomodoro senza distrazioni';
  String get habitEyes2020Name => 'Regola 20-20-20'; String get habitEyes2020Desc => 'Ogni 20 min, guarda a 6m per 20 sec';
  String get habitNeckName => 'Stretching collo'; String get habitNeckDesc => '2 min di stretching collo e spalle ogni ora';
  String get habitBreathingBoxName => 'Respirazione box'; String get habitBreathingBoxDesc => '4s inspira, 4s trattieni, 4s espira, 4s trattieni';
  String get habitWalkLunchName => 'Passeggiata pausa pranzo'; String get habitWalkLunchDesc => 'Una camminata di 15 min durante la pausa';
  String get habitDeskExName => 'Esercizi alla scrivania'; String get habitDeskExDesc => '5 min di stretching attivo ogni 2 ore';
  String get habitWaterMornName => 'Acqua appena svegli'; String get habitWaterMornDesc => 'Un bicchiere d\'acqua come prima cosa';
  String get habitPostureName => 'Check postura'; String get habitPostureDesc => 'Controlla e correggi la postura ogni ora';
  String get habitLunchParkName => 'Pranzo al parco'; String get habitLunchParkDesc => 'Mangia fuori, all\'aperto, senza schermo';
  String get habitBreathing478Name => 'Respirazione 4-7-8'; String get habitBreathing478Desc => 'Anti-ansia: inspira 4s, trattieni 7s, espira 8s';
  String get habitStretchName => 'Stretching attivo'; String get habitStretchDesc => '5 minuti di movimento globale del corpo';
  String get habitSnackName => 'Spuntino sano'; String get habitSnackDesc => 'Un piccolo spuntino nutriente a metà mattina';
  String get habitLunchNoScreenName => 'Pranzo senza schermo'; String get habitLunchNoScreenDesc => 'Il pranzo lontano da telefono e computer';
  String get habitFocus50Name => 'Focus profondo 50 min'; String get habitFocus50Desc => 'Una sessione di lavoro profondo senza interruzioni';
  String get habitMeditationName => 'Micro-meditazione'; String get habitMeditationDesc => '3 minuti di presenza consapevole';
  String get habitStairsName => 'Scala invece ascensore'; String get habitStairsDesc => 'Scegli le scale ogni volta che puoi';
  String get habitSleepName => 'Routine pre-sonno'; String get habitSleepDesc => '30 minuti senza schermi prima di dormire';
  String get habitWakeName => 'Sveglia costante'; String get habitWakeDesc => 'Alzati sempre alla stessa ora';
  String get habitNapName => 'Power nap 20 min'; String get habitNapDesc => 'Un riposo breve e intenzionale nel pomeriggio';
  String get habitFocusPhoneName => 'Focus senza telefono'; String get habitFocusPhoneDesc => 'Telefono capovolto durante il focus';
  String get habitMicroWalkName => 'Micro-camminata 5 min';
  String get habitMicroWalkDesc => '5 minuti di camminata ogni 90 minuti — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Digital sunset';
  String get habitDigitalSunsetDesc => 'Niente social media nell\'ora prima di dormire';

  String get neverMissTwiceTitle => 'Stai per saltare due giorni di fila.';
  String get neverMissTwiceBody => 'Una sola azione conta. Anche un bicchiere d\'acqua.';
  String get neverMissTwiceCta => '💧 Aggiungi un bicchiere d\'acqua';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Punti tripli questo giro 🎉';
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min rimasti';
  String get focusBlockOf4 => 'di 4';

  String get coachDay1 => 'Primo giorno. Il più importante.';
  String get coachDay3 => '3 giorni. Il corpo inizia a registrarlo.';
  String get coachDay7 => '7 giorni. Stai costruendo qualcosa.';
  String get coachDay14 => '2 settimane. Questa abitudine è tua adesso.';
  String get coachGeneral => 'Ogni giorno conta. Anche i giorni difficili.';
  String get habitIntroTitle => 'È il momento di aggiungere\nqualcosa di nuovo.';
  String get habitIntroSubtitle => 'Scegli dove concentrarti adesso.';
  String get habitIntroMoreOptions => 'mostrami altre opzioni ›';
  String get effortLow => 'facile';
  String get effortMedium => 'moderato';
  String get effortHigh => 'impegnativo';
  String get daysOfHabits => 'giorni di abitudini';
  String get habitStart => 'Inizia';
  String get habitMarkDone => 'Fatto';
  String get habitCompletedToday => 'Fatto oggi';
  String get habitDaysToNextPhase => 'al prossimo livello';
  String get habitsGuide => 'Le tue abitudini attive sono qui. Tocca una card per iniziare, o segna "Fatto" se l\'hai già fatta. Ogni giorno che completi costruisce qualcosa.';
  String get habitsAllDone => 'Tutto fatto per oggi.';
  String get habitLate => 'In ritardo';
  String get habitDetailWhyNow => 'Perché ora';
  String get habitDetailWhatDoes => 'Cosa fa';
  String get habitDetailHowStart => 'Come iniziare';
  String get habitYourProgress => 'I tuoi progressi';
  String get homeMomentNow => 'Adesso';
  String get homeFirstVisit => 'Questa è la tua home. Torna qui ogni giorno — io ci sono.';
  String get homeReturnAfter2 => 'Bentornato. Mi sei mancato.';
  String get homeReturnAfter3to6 => 'Che bello rivederti. Sei tornato — ed è quello che conta.';
  String get homeReturnAfter7 => 'Eccoti. Non importa quanto tempo è passato — sei qui adesso, e questo è il punto di partenza.';
  String get homeStreakBroken => 'La serie si è fermata — ma tutto quello che hai costruito è ancora lì. Continuiamo da dove siamo.';
  String get homeResume => 'Riprendiamo';
  String get growthMarketplaceHeader => 'Raccogli quello che hai seminato';
  String get growthMilestones => 'Momenti memorabili';
  String get growthStats => 'Statistiche';
  String get growthTotalDays => 'Giorni totali';
  String get growthTotalGlasses => 'Bicchieri d\'acqua';
  String get growthTotalFocusMin => 'Minuti di focus';
  String get rewardRedeem => 'Riscatta';
  String get rewardConfirmTitle => 'Sei sicuro?';
  String get rewardConfirmBody => 'Verranno scalati i punti.';
  String get rewardCodeLabel => 'Il tuo codice';
  String get rewardCopyCode => 'Copia codice';
  String get rewardCopied => 'Copiato!';
  String get rewardNotEnough => 'Ti mancano ancora un po\' di punti. Continua con le abitudini — arrivano più in fretta di quanto pensi.';
  String get rewardPointsLeft => 'Ti resterebbero';
  String get rewardUsed => 'Usato';
  String get rewardMarkUsed => 'Segna come usato';
  String get marketplaceGuide => 'Questi sono i premi che puoi riscattare con i tuoi punti. Li hai guadagnati tu — goditi la scelta.';
  String get celebrationDay1to6 => 'Tutto fatto oggi. Domani si riparte.';
  String get celebrationDay7 => 'Una settimana intera. Non è poco.';
  String get celebrationDay14 => 'Due settimane. Stai costruendo qualcosa di solido.';
  String get celebrationNormal => 'Giornata completa. Welly è soddisfatto — e tu?';
  String get celebrationClose => 'Chiudi';
  String get celebrationPointsToday => 'punti oggi';
  String get navUnlockHabitsMsg => 'C\'è una sezione nuova per te. Le tue abitudini hanno adesso il loro spazio.';
  String get navUnlockGrowthMsg => 'Hai abbastanza storia adesso per guardarla. La tua crescita ha il suo spazio.';
  String get navNewBadge => 'Nuovo';
  String get notifReturn1day => 'Come stai? Non ti ho visto oggi.';
  String get notifReturn3days => 'Sono qui quando sei pronto. Le tue abitudini ti aspettano.';
  String get notifReturn7days => 'È passata una settimana. Nessuna pressione — ma quando vuoi tornare, ci sono.';
  String get notifStreakRisk => 'La giornata sta finendo. Hai ancora tempo.';
  String get notifMilestoneNear => 'Ti mancano 2 giorni a una settimana consecutiva. Ci sei quasi.';
  String get notifNewUnlock => 'C\'è qualcosa di nuovo per te. Apri Be Well.';

  String get errorNetwork => 'Nessuna connessione internet';
  String get errorGeneral => 'Qualcosa è andato storto. Riprova.';
  String get errorInvalidEmail => 'Indirizzo email non valido';
  String get errorWeakPassword => 'La password è troppo debole';
  String get errorEmailInUse => 'Questa email è già in uso';
  String get errorInvalidCredentials => 'Email o password errati';
}

// ══════════════════════════════════════════════════════════════════════════════
// FRANÇAIS
// ══════════════════════════════════════════════════════════════════════════════
class _Fr extends BwStrings {
  String get appName => 'Be Well';
  String get welcome => 'Bienvenue';
  String get welcomeBack => 'Bon retour';
  String get continueJourney => 'Connectez-vous pour continuer votre parcours';
  String get login => 'Se connecter';
  String get register => 'S\'inscrire';
  String get email => 'Email';
  String get password => 'Mot de passe';
  String get forgotPassword => 'Mot de passe oublié ?';
  String get noAccount => 'Pas encore de compte ? ';
  String get createOne => 'Créez-en un';
  String get loginWithBiometrics => 'Se connecter avec la biométrie';
  String get orDivider => 'ou';
  String get loginWithGoogle => 'Continuer avec Google';
  String get loginWithApple => 'Continuer avec Apple';
  String get attemptsRemaining => 'tentatives restantes avant le blocage';
  String get accountLocked => 'Compte temporairement bloqué';
  String get verifyEmail => 'Vérifiez votre email';
  String get verifyEmailSent => 'Nous avons envoyé un lien de vérification à';
  String get resendEmail => 'Renvoyer l\'email';
  String get confirmPassword => 'Confirmer le mot de passe';
  String get name => 'Nom';
  String get createAccount => 'Créer un compte';
  String get alreadyHaveAccount => 'Déjà un compte ? ';
  String get signIn => 'Se connecter';
  String get passwordForgotTitle => 'Réinitialiser le mot de passe';
  String get passwordForgotSub => 'Entrez votre email et nous vous enverrons un lien';
  String get sendResetEmail => 'Envoyer l\'email';
  String get backToLogin => 'Retour à la connexion';
  String get emailSent => 'Email envoyé';

  String get wellyHi => 'Salut, je suis Welly.';
  String get wellyIntro => 'Be Well est la première app qui vous guide pas à pas dans la création de bonnes habitudes — et vous récompense en chemin. Je ne vous demande pas de tout changer en un jour. Juste de commencer par une petite chose, avec moi.';
  String get letsGo => 'Allons-y';
  String get wellyNameQuestion => 'Avant tout : comment voulez-vous m\'appeler ?';
  String get wellyNameSub => 'Mon nom est Welly, mais vous pouvez me donner un nom qui vous plaît.';
  String get perfect => 'Parfait';
  String get firstHabitTitle => 'Première habitude : l\'eau.';
  String get firstHabitBody1 => 'Votre corps est composé à 60% d\'eau. Quand vous êtes déshydraté de seulement 2%, la concentration baisse, l\'humeur se détériore et vous vous fatiguez plus vite. Pourtant la plupart des gens boivent moins de la moitié de ce qu\'ils devraient.';
  String get firstHabitBody2 => 'On commence ici : 8 verres d\'eau. Je vous rappellerai quand boire. Puis, étape par étape, nous ajouterons de nouvelles activités — construisant ensemble de saines habitudes qui fonctionnent vraiment pour vous.';
  String get drinkFirstGlass => 'Boire le premier verre maintenant';
  String get rewardTitle => 'Parfait. Un.';
  String get rewardBody => 'Chaque fois que vous terminez quelque chose, vous gagnez des points Be Well. Vous les accumulerez sans y penser — et pourrez les utiliser pour des bons de réduction, vouchers, accessoires, fonctionnalités premium et bien plus encore.';
  String get goToHome => 'Aller à votre accueil';
  String get rewardLocked => 'Débloqués avec les points';

  String get goodMorning => 'Bonjour,';
  String get phase => 'Phase';
  String get waterToday => 'Eau aujourd\'hui';
  String get waterGlasses => 'verres';
  String get waterTrackedInHome => '💧 home';
  String get achievementUnlocked => 'Achievement débloqué !';
  String get newHabitUnlocked => 'Nouvelle habitude débloquée !';
  String get waterZero => 'Commencez par le premier verre.';
  String get waterLow => 'Bien parti — continuez !';
  String get waterMid => 'Plus de la moitié — excellent !';
  String get waterDone => 'Objectif atteint ! 💚';
  String get addGlass => '+ Marquer un verre';
  String get comingNext => 'À venir';
  String get daysStreak => 'j. de suite';
  String get points => 'pts';
  String get days => 'jours';
  String get unlocksIn => 'Dans';
  String get unlocksTomorrow => 'Se débloque demain';
  String get almostReady => 'Presque prêt...';

  String get yourJourney => 'Votre parcours';
  String get activeHabits => 'Habitudes actives';
  String get nextUnlock => 'À venir';
  String get badges => 'Badges';
  String get noBadgesYet => 'Vos badges apparaîtront ici au fil de votre progression.';
  String get todayCompleted => 'Complété aujourd\'hui';
  String get phase1 => 'Graine'; String get phase2 => 'Pousse';
  String get phase3 => 'Jeune'; String get phase4 => 'Mature';
  String get phase5 => 'Radieux';

  String get focusTitle => 'Focus';
  String get focusPomodoro => 'Pomodoro';
  String get focusSession => 'Session focus';
  String get focusBlock => 'Bloc';
  String get focusPause => 'Pause';
  String get focusBreak => 'pause dans';
  String get focusStop => 'Arrêter';
  String get focusResume => 'Reprendre';
  String get focusNewSession => 'Nouvelle session';
  String get focusDone => 'Session terminée !';
  String get focusRemaining => 'restantes';
  String get focusSessions => 'sessions';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'série';

  String get planToday => 'Aujourd\'hui';
  String get planCompleted => 'complétés';

  String get profile => 'Profil';
  String get settings => 'Paramètres';
  String get editName => 'Modifier le nom';
  String get changePassword => 'Changer le mot de passe';
  String get appearance => 'Apparence et thème';
  String get notifications => 'Notifications';
  String get privacy => 'Confidentialité';
  String get support => 'Assistance';
  String get logout => 'Se déconnecter';
  String get logoutConfirm => 'Se déconnecter';
  String get logoutConfirmSub => 'Êtes-vous sûr ?';
  String get cancel => 'Annuler';
  String get confirm => 'Confirmer';
  String get save => 'Enregistrer';
  String get currentPassword => 'Mot de passe actuel';
  String get newPassword => 'Nouveau mot de passe';
  String get confirmPasswordShort => 'Confirmer';
  String get passwordUpdated => 'Mot de passe mis à jour';
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';
  String get passwordTooShort => 'Minimum 8 caractères';
  String get wrongPassword => 'Mot de passe actuel incorrect';

  String get themeTitle => 'Apparence';
  String get themeCard => 'Carte';
  String get themeCardDesc => 'Contenu en cartes,\ntypographie claire';
  String get themeAmbient => 'Ambiant';
  String get themeAmbientDesc => 'Paysage atmosphérique,\npolice éditoriale';
  String get palette => 'Tonalité';
  String get palNatura => 'Nature calme';
  String get palAria => 'Air frais';
  String get palNotte => 'Nuit profonde';
  String get palAlba => 'Aube ambiante';
  String get palNotteAmb => 'Nuit ambiante';

  String get accessibility => 'Accessibilité';
  String get highContrast => 'Contraste élevé';
  String get highContrastDesc => 'Augmente le contraste des textes';
  String get largeText => 'Grand texte';
  String get largeTextDesc => 'Augmente la taille des caractères';

  String get reminders => 'Rappels';
  String get waterReminder => 'Rappel eau';
  String get waterReminderDesc => 'Me rappeler de boire chaque heure';

  String get navHome => 'Accueil';
  String get navHabits => 'Habitudes';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Récompenses';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Débloque dans';

  String get rewards => 'Récompenses';
  String get rewardsPoints => 'Points Be Well';
  String get rewardsLocked => 'Les récompenses arrivent';
  String get rewardsLockedDesc => 'Continuez à construire des habitudes pour débloquer vos récompenses';
  String get rewardsHeader => 'Vos récompenses';
  String get rewardsHeaderSub => 'Récoltez ce que vous avez semé';

  String get habitWaterName => 'Boire de l\'eau'; String get habitWaterDesc => '8 verres tout au long de la journée';
  String get habitFocus25Name => 'Session focus 25 min'; String get habitFocus25Desc => 'Un Pomodoro sans distractions';
  String get habitEyes2020Name => 'Règle 20-20-20'; String get habitEyes2020Desc => 'Toutes les 20 min, regarder au loin 20 sec';
  String get habitNeckName => 'Étirement du cou'; String get habitNeckDesc => '2 min d\'étirements cou et épaules par heure';
  String get habitBreathingBoxName => 'Respiration en boîte'; String get habitBreathingBoxDesc => '4s inspirer, 4s tenir, 4s expirer, 4s tenir';
  String get habitWalkLunchName => 'Marche du déjeuner'; String get habitWalkLunchDesc => 'Une marche de 15 min pendant la pause déjeuner';
  String get habitDeskExName => 'Exercices au bureau'; String get habitDeskExDesc => '5 min d\'étirements actifs toutes les 2 heures';
  String get habitWaterMornName => 'Eau au réveil'; String get habitWaterMornDesc => 'Un verre d\'eau dès le réveil';
  String get habitPostureName => 'Contrôle posture'; String get habitPostureDesc => 'Vérifier et corriger la posture chaque heure';
  String get habitLunchParkName => 'Déjeuner au parc'; String get habitLunchParkDesc => 'Manger dehors, sans écran';
  String get habitBreathing478Name => 'Respiration 4-7-8'; String get habitBreathing478Desc => 'Anti-anxiété : inspirer 4s, tenir 7s, expirer 8s';
  String get habitStretchName => 'Étirement actif'; String get habitStretchDesc => '5 minutes de mouvement global du corps';
  String get habitSnackName => 'Collation saine'; String get habitSnackDesc => 'Une petite collation nutritive en milieu de matinée';
  String get habitLunchNoScreenName => 'Déjeuner sans écran'; String get habitLunchNoScreenDesc => 'Déjeuner sans téléphone ni ordinateur';
  String get habitFocus50Name => 'Focus profond 50 min'; String get habitFocus50Desc => 'Une session de travail profond sans interruption';
  String get habitMeditationName => 'Micro-méditation'; String get habitMeditationDesc => '3 minutes de présence consciente';
  String get habitStairsName => 'Prendre les escaliers'; String get habitStairsDesc => 'Choisir les escaliers plutôt que l\'ascenseur';
  String get habitSleepName => 'Routine pré-sommeil'; String get habitSleepDesc => '30 minutes sans écran avant de dormir';
  String get habitWakeName => 'Réveil constant'; String get habitWakeDesc => 'Se lever à la même heure chaque jour';
  String get habitNapName => 'Sieste 20 min'; String get habitNapDesc => 'Un court repos intentionnel l\'après-midi';
  String get habitFocusPhoneName => 'Focus sans téléphone'; String get habitFocusPhoneDesc => 'Téléphone retourné pendant les sessions focus';
  String get habitMicroWalkName => 'Micro-marche 5 min';
  String get habitMicroWalkDesc => '5 minutes de marche toutes les 90 minutes — cycle ultradien';
  String get habitDigitalSunsetName => 'Coucher digital';
  String get habitDigitalSunsetDesc => 'Pas de réseaux sociaux dans l\'heure avant de dormir';

  String get neverMissTwiceTitle => 'Ne ratez pas deux jours de suite.';
  String get neverMissTwiceBody => 'Une seule action compte. Même un verre d\'eau.';
  String get neverMissTwiceCta => '💧 Ajouter un verre d\'eau';
  String get wellyBonusTitle => 'Bonus Welly !';
  String get wellyBonusBody => 'Points triplés ce tour 🎉';
  String get focusDeepWork => 'Travail profond';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'sur 4';

  String get coachDay1 => 'Premier jour. Le plus important.';
  String get coachDay3 => '3 jours. Votre corps commence à l\'enregistrer.';
  String get coachDay7 => '7 jours. Vous construisez quelque chose.';
  String get coachDay14 => '2 semaines. Cette habitude est la vôtre maintenant.';
  String get coachGeneral => 'Chaque jour compte. Même les jours difficiles.';
  String get habitIntroTitle => 'Il est temps d\'ajouter\nquelque chose de nouveau.';
  String get habitIntroSubtitle => 'Choisissez où vous concentrer maintenant.';
  String get habitIntroMoreOptions => 'montrez-moi d\'autres options ›';
  String get effortLow => 'facile';
  String get effortMedium => 'modéré';
  String get effortHigh => 'exigeant';
  String get daysOfHabits => 'jours d\'habitudes';
  String get habitStart => 'Démarrer';
  String get habitMarkDone => 'Fait';
  String get habitCompletedToday => 'Fait aujourd\'hui';
  String get habitDaysToNextPhase => 'au niveau suivant';
  String get habitsGuide => 'Vos habitudes actives sont ici. Touchez une carte pour commencer, ou marquez "Fait" si vous l\'avez déjà faite. Chaque jour que vous complétez construit quelque chose.';
  String get habitsAllDone => 'Tout fait pour aujourd\'hui.';
  String get habitLate => 'En retard';
  String get habitDetailWhyNow => 'Pourquoi maintenant';
  String get habitDetailWhatDoes => 'Ce que ça fait';
  String get habitDetailHowStart => 'Comment commencer';
  String get habitYourProgress => 'Vos progrès';
  String get homeMomentNow => 'Maintenant';
  String get homeFirstVisit => 'C\'est votre accueil. Revenez chaque jour — je suis là.';
  String get homeReturnAfter2 => 'Bienvenue. Tu m\'as manqué.';
  String get homeReturnAfter3to6 => 'Quelle joie de te revoir. Tu es revenu — et c\'est ce qui compte.';
  String get homeReturnAfter7 => 'Te voilà. Peu importe le temps passé — tu es là maintenant, et c\'est le point de départ.';
  String get homeStreakBroken => 'La série s\'est arrêtée — mais tout ce que tu as construit est toujours là. Continuons d\'où nous sommes.';
  String get homeResume => 'Reprendre';
  String get growthMarketplaceHeader => 'Récoltez ce que vous avez semé';
  String get growthMilestones => 'Moments mémorables';
  String get growthStats => 'Statistiques';
  String get growthTotalDays => 'Jours totaux';
  String get growthTotalGlasses => 'Verres d\'eau';
  String get growthTotalFocusMin => 'Minutes de focus';
  String get rewardRedeem => 'Utiliser';
  String get rewardConfirmTitle => 'Êtes-vous sûr ?';
  String get rewardConfirmBody => 'Les points seront déduits.';
  String get rewardCodeLabel => 'Votre code';
  String get rewardCopyCode => 'Copier le code';
  String get rewardCopied => 'Copié !';
  String get rewardNotEnough => 'Il vous manque encore quelques points. Continuez avec vos habitudes — ils arrivent plus vite que vous ne pensez.';
  String get rewardPointsLeft => 'Il vous resterait';
  String get rewardUsed => 'Utilisé';
  String get rewardMarkUsed => 'Marquer comme utilisé';
  String get marketplaceGuide => 'Ce sont les récompenses que vous pouvez échanger avec vos points. Vous les avez gagnées — profitez du choix.';
  String get celebrationDay1to6 => 'Tout fait aujourd\'hui. Demain on recommence.';
  String get celebrationDay7 => 'Une semaine entière. C\'est pas rien.';
  String get celebrationDay14 => 'Deux semaines. Vous construisez quelque chose de solide.';
  String get celebrationNormal => 'Journée complète. Welly est satisfait — et vous ?';
  String get celebrationClose => 'Fermer';
  String get celebrationPointsToday => 'points aujourd\'hui';
  String get navUnlockHabitsMsg => 'Il y a une nouvelle section pour vous. Vos habitudes ont maintenant leur propre espace.';
  String get navUnlockGrowthMsg => 'Vous avez assez d\'histoire maintenant pour la regarder. Votre croissance a son propre espace.';
  String get navNewBadge => 'Nouveau';
  String get notifReturn1day => 'Comment vas-tu ? Je ne t\'ai pas vu aujourd\'hui.';
  String get notifReturn3days => 'Je suis là quand tu es prêt. Tes habitudes t\'attendent.';
  String get notifReturn7days => 'Une semaine a passé. Pas de pression — mais quand tu veux revenir, je suis là.';
  String get notifStreakRisk => 'La journée se termine. Tu as encore le temps.';
  String get notifMilestoneNear => 'Il te manque 2 jours pour une semaine consécutive. Tu y es presque.';
  String get notifNewUnlock => 'Il y a quelque chose de nouveau pour toi. Ouvre Be Well.';

  String get errorNetwork => 'Pas de connexion internet';
  String get errorGeneral => 'Quelque chose s\'est mal passé. Réessayez.';
  String get errorInvalidEmail => 'Adresse email invalide';
  String get errorWeakPassword => 'Le mot de passe est trop faible';
  String get errorEmailInUse => 'Cet email est déjà utilisé';
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect';
}

// ══════════════════════════════════════════════════════════════════════════════
// DEUTSCH
// ══════════════════════════════════════════════════════════════════════════════
class _De extends BwStrings {
  String get appName => 'Be Well';
  String get welcome => 'Willkommen';
  String get welcomeBack => 'Willkommen zurück';
  String get continueJourney => 'Melde dich an, um deine Reise fortzusetzen';
  String get login => 'Anmelden';
  String get register => 'Registrieren';
  String get email => 'E-Mail';
  String get password => 'Passwort';
  String get forgotPassword => 'Passwort vergessen?';
  String get noAccount => 'Noch kein Konto? ';
  String get createOne => 'Erstelle eines';
  String get loginWithBiometrics => 'Mit Biometrie anmelden';
  String get orDivider => 'oder';
  String get loginWithGoogle => 'Mit Google fortfahren';
  String get loginWithApple => 'Mit Apple fortfahren';
  String get attemptsRemaining => 'Versuche verbleibend bis zur Sperrung';
  String get accountLocked => 'Konto vorübergehend gesperrt';
  String get verifyEmail => 'E-Mail bestätigen';
  String get verifyEmailSent => 'Wir haben einen Bestätigungslink gesendet an';
  String get resendEmail => 'E-Mail erneut senden';
  String get confirmPassword => 'Passwort bestätigen';
  String get name => 'Name';
  String get createAccount => 'Konto erstellen';
  String get alreadyHaveAccount => 'Bereits ein Konto? ';
  String get signIn => 'Anmelden';
  String get passwordForgotTitle => 'Passwort zurücksetzen';
  String get passwordForgotSub => 'Gib deine E-Mail ein und wir senden dir einen Link';
  String get sendResetEmail => 'Reset-E-Mail senden';
  String get backToLogin => 'Zurück zur Anmeldung';
  String get emailSent => 'E-Mail gesendet';

  String get wellyHi => 'Hallo, ich bin Welly.';
  String get wellyIntro => 'Be Well ist die erste App, die dich Schritt für Schritt beim Aufbau gesunder Gewohnheiten begleitet — und dich dabei belohnt. Ich bitte dich nicht, alles an einem Tag zu ändern. Nur mit einer kleinen Sache zu beginnen, mit mir.';
  String get letsGo => 'Los geht\'s';
  String get wellyNameQuestion => 'Zuerst: Wie möchtest du mich nennen?';
  String get wellyNameSub => 'Mein Name ist Welly, aber du kannst mir auch einen eigenen Namen geben.';
  String get perfect => 'Perfekt';
  String get firstHabitTitle => 'Erste Gewohnheit: Wasser.';
  String get firstHabitBody1 => 'Dein Körper besteht zu 60% aus Wasser. Wenn du nur 2% dehydriert bist, sinkt die Konzentration, die Stimmung verschlechtert sich und du wirst schneller müde. Dennoch trinken die meisten Menschen weniger als die Hälfte dessen, was sie sollten.';
  String get firstHabitBody2 => 'Wir beginnen hier: 8 Gläser Wasser. Ich erinnere dich daran, wann du trinken sollst. Dann fügen wir Schritt für Schritt neue Aktivitäten hinzu — und bauen gemeinsam gesunde Gewohnheiten auf, die wirklich für dich funktionieren.';
  String get drinkFirstGlass => 'Erstes Glas jetzt trinken';
  String get rewardTitle => 'Perfekt. Eins.';
  String get rewardBody => 'Jedes Mal, wenn du etwas abschließt, verdienst du Be Well-Punkte. Du sammelst sie, ohne nachzudenken — und kannst sie für Rabattgutscheine, Voucher, Zubehör, Premium-Funktionen und vieles mehr einlösen.';
  String get goToHome => 'Zur Startseite';
  String get rewardLocked => 'Mit Punkten freischalten';

  String get goodMorning => 'Guten Morgen,';
  String get phase => 'Phase';
  String get waterToday => 'Wasser heute';
  String get waterGlasses => 'Gläser';
  String get waterTrackedInHome => '💧 home';
  String get achievementUnlocked => 'Achievement freigeschaltet!';
  String get newHabitUnlocked => 'Neue Gewohnheit freigeschaltet!';
  String get waterZero => 'Beginne mit dem ersten Glas.';
  String get waterLow => 'Gut so — weiter so!';
  String get waterMid => 'Mehr als die Hälfte — toll!';
  String get waterDone => 'Ziel erreicht! 💚';
  String get addGlass => '+ Glas markieren';
  String get comingNext => 'Demnächst';
  String get daysStreak => 'Tage-Serie';
  String get points => 'Pkt';
  String get days => 'Tage';
  String get unlocksIn => 'In';
  String get unlocksTomorrow => 'Morgen verfügbar';
  String get almostReady => 'Fast bereit...';

  String get yourJourney => 'Deine Reise';
  String get activeHabits => 'Aktive Gewohnheiten';
  String get nextUnlock => 'Demnächst';
  String get badges => 'Abzeichen';
  String get noBadgesYet => 'Deine Abzeichen erscheinen hier, wenn du Fortschritte machst.';
  String get todayCompleted => 'Heute abgeschlossen';
  String get phase1 => 'Samen'; String get phase2 => 'Keim';
  String get phase3 => 'Jung'; String get phase4 => 'Reif';
  String get phase5 => 'Strahlend';

  String get focusTitle => 'Fokus';
  String get focusPomodoro => 'Pomodoro';
  String get focusSession => 'Fokus-Sitzung';
  String get focusBlock => 'Block';
  String get focusPause => 'Pause';
  String get focusBreak => 'Pause in';
  String get focusStop => 'Stop';
  String get focusResume => 'Fortsetzen';
  String get focusNewSession => 'Neue Sitzung';
  String get focusDone => 'Sitzung abgeschlossen!';
  String get focusRemaining => 'verbleibend';
  String get focusSessions => 'Sitzungen';
  String get focusMinutes => 'Min Fokus';
  String get focusStreak => 'Serie';

  String get planToday => 'Heute';
  String get planCompleted => 'abgeschlossen';

  String get profile => 'Profil';
  String get settings => 'Einstellungen';
  String get editName => 'Name bearbeiten';
  String get changePassword => 'Passwort ändern';
  String get appearance => 'Erscheinungsbild';
  String get notifications => 'Benachrichtigungen';
  String get privacy => 'Datenschutz';
  String get support => 'Support';
  String get logout => 'Abmelden';
  String get logoutConfirm => 'Abmelden';
  String get logoutConfirmSub => 'Bist du sicher?';
  String get cancel => 'Abbrechen';
  String get confirm => 'Bestätigen';
  String get save => 'Speichern';
  String get currentPassword => 'Aktuelles Passwort';
  String get newPassword => 'Neues Passwort';
  String get confirmPasswordShort => 'Bestätigen';
  String get passwordUpdated => 'Passwort aktualisiert';
  String get passwordMismatch => 'Passwörter stimmen nicht überein';
  String get passwordTooShort => 'Mindestens 8 Zeichen';
  String get wrongPassword => 'Aktuelles Passwort falsch';

  String get themeTitle => 'Erscheinungsbild';
  String get themeCard => 'Karte';
  String get themeCardDesc => 'Inhalte in Karten,\nklare Typografie';
  String get themeAmbient => 'Ambient';
  String get themeAmbientDesc => 'Atmosphärische Landschaft,\nredaktionelle Schrift';
  String get palette => 'Farbton';
  String get palNatura => 'Ruhige Natur';
  String get palAria => 'Frische Luft';
  String get palNotte => 'Tiefe Nacht';
  String get palAlba => 'Ambient Morgenrot';
  String get palNotteAmb => 'Ambient Nacht';

  String get accessibility => 'Barrierefreiheit';
  String get highContrast => 'Hoher Kontrast';
  String get highContrastDesc => 'Erhöht den Textkontrast';
  String get largeText => 'Großer Text';
  String get largeTextDesc => 'Erhöht die Schriftgröße';

  String get reminders => 'Erinnerungen';
  String get waterReminder => 'Wasser-Erinnerung';
  String get waterReminderDesc => 'Mich stündlich ans Trinken erinnern';

  String get navHome => 'Startseite';
  String get navHabits => 'Gewohnheiten';
  String get navFocus => 'Fokus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Belohnungen';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Freischalten in';

  String get rewards => 'Belohnungen';
  String get rewardsPoints => 'Be Well-Punkte';
  String get rewardsLocked => 'Belohnungen kommen';
  String get rewardsLockedDesc => 'Baue weiter Gewohnheiten auf, um deine Belohnungen freizuschalten';
  String get rewardsHeader => 'Deine Belohnungen';
  String get rewardsHeaderSub => 'Ernte, was du gesät hast';

  String get habitWaterName => 'Wasser trinken'; String get habitWaterDesc => '8 Gläser über den Tag verteilt';
  String get habitFocus25Name => 'Fokus-Sitzung 25 Min'; String get habitFocus25Desc => 'Ein Pomodoro ohne Ablenkungen';
  String get habitEyes2020Name => '20-20-20-Regel'; String get habitEyes2020Desc => 'Alle 20 Min in die Ferne schauen für 20 Sek';
  String get habitNeckName => 'Nackendehnung'; String get habitNeckDesc => '2 Min Nacken- und Schulterdehnung pro Stunde';
  String get habitBreathingBoxName => 'Box-Atmung'; String get habitBreathingBoxDesc => '4s einatmen, 4s halten, 4s ausatmen, 4s halten';
  String get habitWalkLunchName => 'Mittagsspaziergang'; String get habitWalkLunchDesc => 'Ein 15-minütiger Spaziergang in der Mittagspause';
  String get habitDeskExName => 'Schreibtischübungen'; String get habitDeskExDesc => '5 Min aktives Dehnen alle 2 Stunden';
  String get habitWaterMornName => 'Morgenwasser'; String get habitWaterMornDesc => 'Ein Glas Wasser als erstes am Morgen';
  String get habitPostureName => 'Haltungscheck'; String get habitPostureDesc => 'Haltung jede Stunde überprüfen und korrigieren';
  String get habitLunchParkName => 'Mittagessen im Park'; String get habitLunchParkDesc => 'Draußen essen, ohne Bildschirm';
  String get habitBreathing478Name => '4-7-8-Atmung'; String get habitBreathing478Desc => 'Anti-Angst: 4s einatmen, 7s halten, 8s ausatmen';
  String get habitStretchName => 'Aktives Dehnen'; String get habitStretchDesc => '5 Minuten Ganzkörperbewegung';
  String get habitSnackName => 'Gesunder Snack'; String get habitSnackDesc => 'Ein kleiner nahrhafter Snack am Vormittag';
  String get habitLunchNoScreenName => 'Mittagessen ohne Bildschirm'; String get habitLunchNoScreenDesc => 'Mittagessen ohne Telefon oder Computer';
  String get habitFocus50Name => 'Tiefes Fokus 50 Min'; String get habitFocus50Desc => 'Eine ununterbrochene Tiefarbeits-Sitzung';
  String get habitMeditationName => 'Mikro-Meditation'; String get habitMeditationDesc => '3 Minuten achtsame Präsenz';
  String get habitStairsName => 'Treppe statt Aufzug'; String get habitStairsDesc => 'Wann immer möglich die Treppe nehmen';
  String get habitSleepName => 'Vor-Schlaf-Routine'; String get habitSleepDesc => '30 Minuten ohne Bildschirm vor dem Schlafen';
  String get habitWakeName => 'Konstante Aufwachzeit'; String get habitWakeDesc => 'Jeden Tag zur gleichen Zeit aufstehen';
  String get habitNapName => 'Power-Nap 20 Min'; String get habitNapDesc => 'Eine kurze intentionale Ruhe am Nachmittag';
  String get habitFocusPhoneName => 'Fokus ohne Telefon'; String get habitFocusPhoneDesc => 'Telefon während Fokus-Sitzungen umgedreht';
  String get habitMicroWalkName => 'Mikro-Spaziergang 5 Min';
  String get habitMicroWalkDesc => '5 Minuten Gehen alle 90 Minuten — Ultradianischer Zyklus';
  String get habitDigitalSunsetName => 'Digitaler Sonnenuntergang';
  String get habitDigitalSunsetDesc => 'Kein Social Media in der Stunde vor dem Schlafen';

  String get neverMissTwiceTitle => 'Nicht zwei Tage hintereinander auslassen.';
  String get neverMissTwiceBody => 'Eine kleine Aktion zählt. Sogar ein Glas Wasser.';
  String get neverMissTwiceCta => '💧 Ein Glas Wasser hinzufügen';
  String get wellyBonusTitle => 'Welly-Bonus!';
  String get wellyBonusBody => 'Dreifache Punkte diese Runde 🎉';
  String get focusDeepWork => 'Tiefe Arbeit';
  String get focusMinRemaining => 'Min verbleibend';
  String get focusBlockOf4 => 'von 4';

  String get coachDay1 => 'Erster Tag. Der wichtigste.';
  String get coachDay3 => '3 Tage. Dein Körper beginnt es zu registrieren.';
  String get coachDay7 => '7 Tage. Du baust etwas auf.';
  String get coachDay14 => '2 Wochen. Diese Gewohnheit gehört dir jetzt.';
  String get coachGeneral => 'Jeder Tag zählt. Auch die schwierigen.';
  String get habitIntroTitle => 'Zeit, etwas Neues\nhinzuzufügen.';
  String get habitIntroSubtitle => 'Wähle, worauf du dich jetzt konzentrieren möchtest.';
  String get habitIntroMoreOptions => 'zeig mir andere Optionen ›';
  String get effortLow => 'einfach';
  String get effortMedium => 'moderat';
  String get effortHigh => 'anspruchsvoll';
  String get daysOfHabits => 'Tage mit Gewohnheiten';
  String get habitStart => 'Starten';
  String get habitMarkDone => 'Erledigt';
  String get habitCompletedToday => 'Heute erledigt';
  String get habitDaysToNextPhase => 'zur nächsten Phase';
  String get habitsGuide => 'Deine aktiven Gewohnheiten sind hier. Tippe auf eine Karte, um zu beginnen, oder markiere "Erledigt", wenn du es bereits getan hast. Jeder Tag, den du abschließt, baut etwas auf.';
  String get habitsAllDone => 'Alles für heute erledigt.';
  String get habitLate => 'Verspätet';
  String get habitDetailWhyNow => 'Warum jetzt';
  String get habitDetailWhatDoes => 'Was es bewirkt';
  String get habitDetailHowStart => 'Wie man beginnt';
  String get habitYourProgress => 'Dein Fortschritt';
  String get homeMomentNow => 'Jetzt';
  String get homeFirstVisit => 'Das ist dein Zuhause. Komm jeden Tag zurück — ich bin hier.';
  String get homeReturnAfter2 => 'Willkommen zurück. Du hast mir gefehlt.';
  String get homeReturnAfter3to6 => 'Schön, dich wiederzusehen. Du bist zurück — und das ist es, was zählt.';
  String get homeReturnAfter7 => 'Da bist du. Egal wie viel Zeit vergangen ist — du bist jetzt hier, und das ist der Ausgangspunkt.';
  String get homeStreakBroken => 'Die Serie hat aufgehört — aber alles, was du aufgebaut hast, ist noch da. Machen wir weiter, wo wir sind.';
  String get homeResume => 'Weitermachen';
  String get growthMarketplaceHeader => 'Ernte, was du gesät hast';
  String get growthMilestones => 'Meilensteine';
  String get growthStats => 'Statistiken';
  String get growthTotalDays => 'Gesamttage';
  String get growthTotalGlasses => 'Gläser Wasser';
  String get growthTotalFocusMin => 'Fokus-Minuten';
  String get rewardRedeem => 'Einlösen';
  String get rewardConfirmTitle => 'Bist du sicher?';
  String get rewardConfirmBody => 'Punkte werden abgezogen.';
  String get rewardCodeLabel => 'Dein Code';
  String get rewardCopyCode => 'Code kopieren';
  String get rewardCopied => 'Kopiert!';
  String get rewardNotEnough => 'Es fehlen dir noch ein paar Punkte. Mach weiter mit deinen Gewohnheiten — sie kommen schneller als du denkst.';
  String get rewardPointsLeft => 'Es würden dir bleiben';
  String get rewardUsed => 'Verwendet';
  String get rewardMarkUsed => 'Als verwendet markieren';
  String get marketplaceGuide => 'Das sind die Belohnungen, die du mit deinen Punkten einlösen kannst. Du hast sie verdient — genieße die Auswahl.';
  String get celebrationDay1to6 => 'Alles heute erledigt. Morgen fangen wir wieder an.';
  String get celebrationDay7 => 'Eine ganze Woche. Das ist nicht wenig.';
  String get celebrationDay14 => 'Zwei Wochen. Du baust etwas Solides auf.';
  String get celebrationNormal => 'Tag abgeschlossen. Welly ist zufrieden — und du?';
  String get celebrationClose => 'Schließen';
  String get celebrationPointsToday => 'Punkte heute';
  String get navUnlockHabitsMsg => 'Es gibt einen neuen Bereich für dich. Deine Gewohnheiten haben jetzt ihren eigenen Platz.';
  String get navUnlockGrowthMsg => 'Du hast jetzt genug Geschichte, um sie anzusehen. Dein Wachstum hat seinen eigenen Platz.';
  String get navNewBadge => 'Neu';
  String get notifReturn1day => 'Wie geht es dir? Ich habe dich heute nicht gesehen.';
  String get notifReturn3days => 'Ich bin hier, wenn du bereit bist. Deine Gewohnheiten warten auf dich.';
  String get notifReturn7days => 'Eine Woche ist vergangen. Kein Druck — aber wenn du zurückkommen möchtest, bin ich hier.';
  String get notifStreakRisk => 'Der Tag endet. Du hast noch Zeit.';
  String get notifMilestoneNear => 'Es fehlen dir 2 Tage bis zu einer Woche in Folge. Du bist fast da.';
  String get notifNewUnlock => 'Es gibt etwas Neues für dich. Öffne Be Well.';

  String get errorNetwork => 'Keine Internetverbindung';
  String get errorGeneral => 'Etwas ist schiefgelaufen. Versuche es erneut.';
  String get errorInvalidEmail => 'Ungültige E-Mail-Adresse';
  String get errorWeakPassword => 'Das Passwort ist zu schwach';
  String get errorEmailInUse => 'Diese E-Mail wird bereits verwendet';
  String get errorInvalidCredentials => 'Falsche E-Mail oder falsches Passwort';
}

// ══════════════════════════════════════════════════════════════════════════════
// ESPAÑOL
// ══════════════════════════════════════════════════════════════════════════════
class _Es extends BwStrings {
  String get appName => 'Be Well';
  String get welcome => 'Bienvenido';
  String get welcomeBack => 'Bienvenido de nuevo';
  String get continueJourney => 'Inicia sesión para continuar tu camino';
  String get login => 'Iniciar sesión';
  String get register => 'Registrarse';
  String get email => 'Correo electrónico';
  String get password => 'Contraseña';
  String get forgotPassword => '¿Olvidaste tu contraseña?';
  String get noAccount => '¿No tienes cuenta? ';
  String get createOne => 'Crea una';
  String get loginWithBiometrics => 'Iniciar sesión con biometría';
  String get orDivider => 'o';
  String get loginWithGoogle => 'Continuar con Google';
  String get loginWithApple => 'Continuar con Apple';
  String get attemptsRemaining => 'intentos restantes antes del bloqueo';
  String get accountLocked => 'Cuenta temporalmente bloqueada';
  String get verifyEmail => 'Verifica tu correo';
  String get verifyEmailSent => 'Enviamos un enlace de verificación a';
  String get resendEmail => 'Reenviar correo';
  String get confirmPassword => 'Confirmar contraseña';
  String get name => 'Nombre';
  String get createAccount => 'Crear cuenta';
  String get alreadyHaveAccount => '¿Ya tienes cuenta? ';
  String get signIn => 'Iniciar sesión';
  String get passwordForgotTitle => 'Restablecer contraseña';
  String get passwordForgotSub => 'Ingresa tu correo y te enviaremos un enlace';
  String get sendResetEmail => 'Enviar correo de restablecimiento';
  String get backToLogin => 'Volver al inicio de sesión';
  String get emailSent => 'Correo enviado';

  String get wellyHi => 'Hola, soy Welly.';
  String get wellyIntro => 'Be Well es la primera app que te guía paso a paso en la creación de hábitos saludables — y te premia mientras lo haces. No te pido que lo cambies todo en un día. Solo que empieces por una cosa pequeña, conmigo.';
  String get letsGo => 'Empecemos';
  String get wellyNameQuestion => 'Antes que nada: ¿cómo quieres llamarme?';
  String get wellyNameSub => 'Mi nombre es Welly, pero puedes darme el nombre que prefieras.';
  String get perfect => 'Perfecto';
  String get firstHabitTitle => 'Primer hábito: el agua.';
  String get firstHabitBody1 => 'Tu cuerpo está compuesto en un 60% de agua. Cuando estás deshidratado solo un 2%, la concentración baja, el humor empeora y te cansas antes. Sin embargo, la mayoría de las personas bebe menos de la mitad de lo que debería.';
  String get firstHabitBody2 => 'Empezamos aquí: 8 vasos de agua. Yo te recordaré cuándo beber. Luego, paso a paso, añadiremos nuevas actividades a medida que consolidemos las anteriores — construyendo juntos hábitos saludables que realmente funcionen para ti.';
  String get drinkFirstGlass => 'Beber el primer vaso ahora';
  String get rewardTitle => 'Perfecto. Uno.';
  String get rewardBody => 'Cada vez que completas algo, ganas puntos Be Well. Los acumularás sin pensarlo — y podrás usarlos para descuentos, vouchers, accesorios, funciones premium y mucho más.';
  String get goToHome => 'Ir a tu inicio';
  String get rewardLocked => 'Se desbloquean con puntos';

  String get goodMorning => 'Buenos días,';
  String get phase => 'Fase';
  String get waterToday => 'Agua hoy';
  String get waterGlasses => 'vasos';
  String get waterTrackedInHome => '💧 home';
  String get achievementUnlocked => '¡Logro desbloqueado!';
  String get newHabitUnlocked => '¡Nuevo hábito desbloqueado!';
  String get waterZero => 'Empieza con el primer vaso.';
  String get waterLow => 'Bien encaminado — sigue así.';
  String get waterMid => 'Más de la mitad — ¡genial!';
  String get waterDone => '¡Objetivo alcanzado! 💚';
  String get addGlass => '+ Marcar un vaso';
  String get comingNext => 'Próximamente';
  String get daysStreak => 'días seguidos';
  String get points => 'pts';
  String get days => 'días';
  String get unlocksIn => 'En';
  String get unlocksTomorrow => 'Se desbloquea mañana';
  String get almostReady => 'Casi lista...';

  String get yourJourney => 'Tu camino';
  String get activeHabits => 'Hábitos activos';
  String get nextUnlock => 'Próximamente';
  String get badges => 'Insignias';
  String get noBadgesYet => 'Tus insignias aparecerán aquí a medida que progreses.';
  String get todayCompleted => 'Completado hoy';
  String get phase1 => 'Semilla'; String get phase2 => 'Brote';
  String get phase3 => 'Joven'; String get phase4 => 'Maduro';
  String get phase5 => 'Radiante';

  String get focusTitle => 'Enfoque';
  String get focusPomodoro => 'Pomodoro';
  String get focusSession => 'Sesión de enfoque';
  String get focusBlock => 'Bloque';
  String get focusPause => 'Pausa';
  String get focusBreak => 'pausa en';
  String get focusStop => 'Detener';
  String get focusResume => 'Reanudar';
  String get focusNewSession => 'Nueva sesión';
  String get focusDone => '¡Sesión completada!';
  String get focusRemaining => 'restantes';
  String get focusSessions => 'sesiones';
  String get focusMinutes => 'min enfoque';
  String get focusStreak => 'racha';

  String get planToday => 'Hoy';
  String get planCompleted => 'completados';

  String get profile => 'Perfil';
  String get settings => 'Ajustes';
  String get editName => 'Editar nombre';
  String get changePassword => 'Cambiar contraseña';
  String get appearance => 'Apariencia y tema';
  String get notifications => 'Notificaciones';
  String get privacy => 'Privacidad y datos';
  String get support => 'Soporte';
  String get logout => 'Cerrar sesión';
  String get logoutConfirm => 'Cerrar sesión';
  String get logoutConfirmSub => '¿Estás seguro?';
  String get cancel => 'Cancelar';
  String get confirm => 'Confirmar';
  String get save => 'Guardar';
  String get currentPassword => 'Contraseña actual';
  String get newPassword => 'Nueva contraseña';
  String get confirmPasswordShort => 'Confirmar';
  String get passwordUpdated => 'Contraseña actualizada';
  String get passwordMismatch => 'Las contraseñas no coinciden';
  String get passwordTooShort => 'Mínimo 8 caracteres';
  String get wrongPassword => 'Contraseña actual incorrecta';

  String get themeTitle => 'Apariencia';
  String get themeCard => 'Tarjeta';
  String get themeCardDesc => 'Contenido en tarjetas,\ntipografía clara';
  String get themeAmbient => 'Ambiental';
  String get themeAmbientDesc => 'Paisaje atmosférico,\nfuente editorial';
  String get palette => 'Tonalidad';
  String get palNatura => 'Naturaleza tranquila';
  String get palAria => 'Aire fresco';
  String get palNotte => 'Noche profunda';
  String get palAlba => 'Amanecer ambiental';
  String get palNotteAmb => 'Noche ambiental';

  String get accessibility => 'Accesibilidad';
  String get highContrast => 'Alto contraste';
  String get highContrastDesc => 'Aumenta el contraste de los textos';
  String get largeText => 'Texto grande';
  String get largeTextDesc => 'Aumenta el tamaño de los caracteres';

  String get reminders => 'Recordatorios';
  String get waterReminder => 'Recordatorio de agua';
  String get waterReminderDesc => 'Recordarme beber cada hora';

  String get navHome => 'Inicio';
  String get navHabits => 'Hábitos';
  String get navFocus => 'Enfoque';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Recompensas';
  String get navProfile => 'Perfil';
  String get navUnlockIn => 'Se desbloquea en';

  String get rewards => 'Recompensas';
  String get rewardsPoints => 'Puntos Be Well';
  String get rewardsLocked => 'Las recompensas están llegando';
  String get rewardsLockedDesc => 'Sigue construyendo hábitos para desbloquear tus recompensas';
  String get rewardsHeader => 'Tus recompensas';
  String get rewardsHeaderSub => 'Cosecha lo que has sembrado';

  String get habitWaterName => 'Beber agua'; String get habitWaterDesc => '8 vasos durante el día';
  String get habitFocus25Name => 'Sesión de enfoque 25 min'; String get habitFocus25Desc => 'Un Pomodoro sin distracciones';
  String get habitEyes2020Name => 'Regla 20-20-20'; String get habitEyes2020Desc => 'Cada 20 min, mirar lejos 20 seg';
  String get habitNeckName => 'Estiramiento de cuello'; String get habitNeckDesc => '2 min de estiramiento de cuello y hombros por hora';
  String get habitBreathingBoxName => 'Respiración en caja'; String get habitBreathingBoxDesc => '4s inhalar, 4s retener, 4s exhalar, 4s retener';
  String get habitWalkLunchName => 'Paseo del almuerzo'; String get habitWalkLunchDesc => 'Un paseo de 15 min durante el almuerzo';
  String get habitDeskExName => 'Ejercicios en el escritorio'; String get habitDeskExDesc => '5 min de estiramientos activos cada 2 horas';
  String get habitWaterMornName => 'Agua al despertar'; String get habitWaterMornDesc => 'Un vaso de agua nada más levantarse';
  String get habitPostureName => 'Control de postura'; String get habitPostureDesc => 'Verificar y corregir la postura cada hora';
  String get habitLunchParkName => 'Almuerzo en el parque'; String get habitLunchParkDesc => 'Comer al aire libre, sin pantallas';
  String get habitBreathing478Name => 'Respiración 4-7-8'; String get habitBreathing478Desc => 'Antiansiedad: inhalar 4s, retener 7s, exhalar 8s';
  String get habitStretchName => 'Estiramiento activo'; String get habitStretchDesc => '5 minutos de movimiento corporal global';
  String get habitSnackName => 'Snack saludable'; String get habitSnackDesc => 'Un pequeño snack nutritivo a media mañana';
  String get habitLunchNoScreenName => 'Almuerzo sin pantalla'; String get habitLunchNoScreenDesc => 'Almorzar sin teléfono ni ordenador';
  String get habitFocus50Name => 'Enfoque profundo 50 min'; String get habitFocus50Desc => 'Una sesión de trabajo profundo sin interrupciones';
  String get habitMeditationName => 'Micro-meditación'; String get habitMeditationDesc => '3 minutos de presencia consciente';
  String get habitStairsName => 'Escaleras en vez del ascensor'; String get habitStairsDesc => 'Elegir las escaleras siempre que puedas';
  String get habitSleepName => 'Rutina pre-sueño'; String get habitSleepDesc => '30 minutos sin pantallas antes de dormir';
  String get habitWakeName => 'Despertar constante'; String get habitWakeDesc => 'Levantarse a la misma hora cada día';
  String get habitNapName => 'Siesta de 20 min'; String get habitNapDesc => 'Un breve descanso intencional por la tarde';
  String get habitFocusPhoneName => 'Enfoque sin teléfono'; String get habitFocusPhoneDesc => 'Teléfono boca abajo durante las sesiones de enfoque';
  String get habitMicroWalkName => 'Micro-caminata 5 min';
  String get habitMicroWalkDesc => '5 minutos caminando cada 90 minutos — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Atardecer digital';
  String get habitDigitalSunsetDesc => 'Sin redes sociales en la hora antes de dormir';

  String get neverMissTwiceTitle => 'No faltes dos días seguidos.';
  String get neverMissTwiceBody => 'Una sola acción cuenta. Incluso un vaso de agua.';
  String get neverMissTwiceCta => '💧 Añadir un vaso de agua';
  String get wellyBonusTitle => '¡Bonus Welly!';
  String get wellyBonusBody => 'Puntos triplicados esta vez 🎉';
  String get focusDeepWork => 'Trabajo profundo';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'de 4';

  String get coachDay1 => 'Primer día. El más importante.';
  String get coachDay3 => '3 días. Tu cuerpo empieza a registrarlo.';
  String get coachDay7 => '7 días. Estás construyendo algo.';
  String get coachDay14 => '2 semanas. Este hábito es tuyo ahora.';
  String get coachGeneral => 'Cada día cuenta. Incluso los días difíciles.';
  String get habitIntroTitle => 'Es hora de añadir\nalgo nuevo.';
  String get habitIntroSubtitle => 'Elige en qué enfocarte ahora.';
  String get habitIntroMoreOptions => 'muéstrame otras opciones ›';
  String get effortLow => 'fácil';
  String get effortMedium => 'moderado';
  String get effortHigh => 'exigente';
  String get daysOfHabits => 'días de hábitos';
  String get habitStart => 'Comenzar';
  String get habitMarkDone => 'Hecho';
  String get habitCompletedToday => 'Hecho hoy';
  String get habitDaysToNextPhase => 'al siguiente nivel';
  String get habitsGuide => 'Tus hábitos activos están aquí. Toca una tarjeta para empezar, o marca "Hecho" si ya lo has hecho. Cada día que completas construye algo.';
  String get habitsAllDone => 'Todo hecho por hoy.';
  String get habitLate => 'Con retraso';
  String get habitDetailWhyNow => 'Por qué ahora';
  String get habitDetailWhatDoes => 'Qué hace';
  String get habitDetailHowStart => 'Cómo empezar';
  String get habitYourProgress => 'Tu progreso';
  String get homeMomentNow => 'Ahora';
  String get homeFirstVisit => 'Este es tu hogar. Vuelve cada día — yo estoy aquí.';
  String get homeReturnAfter2 => 'Bienvenido de vuelta. Te he echado de menos.';
  String get homeReturnAfter3to6 => 'Qué alegría verte. Has vuelto — y eso es lo que importa.';
  String get homeReturnAfter7 => 'Aquí estás. No importa cuánto tiempo ha pasado — estás aquí ahora, y ese es el punto de partida.';
  String get homeStreakBroken => 'La racha se detuvo — pero todo lo que has construido sigue ahí. Continuemos desde donde estamos.';
  String get homeResume => 'Retomemos';
  String get growthMarketplaceHeader => 'Cosecha lo que has sembrado';
  String get growthMilestones => 'Momentos memorables';
  String get growthStats => 'Estadísticas';
  String get growthTotalDays => 'Días totales';
  String get growthTotalGlasses => 'Vasos de agua';
  String get growthTotalFocusMin => 'Minutos de enfoque';
  String get rewardRedeem => 'Canjear';
  String get rewardConfirmTitle => '¿Estás seguro?';
  String get rewardConfirmBody => 'Se deducirán los puntos.';
  String get rewardCodeLabel => 'Tu código';
  String get rewardCopyCode => 'Copiar código';
  String get rewardCopied => '¡Copiado!';
  String get rewardNotEnough => 'Todavía te faltan algunos puntos. Sigue con tus hábitos — llegan más rápido de lo que crees.';
  String get rewardPointsLeft => 'Te quedarían';
  String get rewardUsed => 'Usado';
  String get rewardMarkUsed => 'Marcar como usado';
  String get marketplaceGuide => 'Estas son las recompensas que puedes canjear con tus puntos. Tú las ganaste — disfruta la elección.';
  String get celebrationDay1to6 => 'Todo hecho hoy. Mañana empezamos de nuevo.';
  String get celebrationDay7 => 'Una semana entera. No es poco.';
  String get celebrationDay14 => 'Dos semanas. Estás construyendo algo sólido.';
  String get celebrationNormal => 'Día completo. Welly está satisfecho — ¿y tú?';
  String get celebrationClose => 'Cerrar';
  String get celebrationPointsToday => 'puntos hoy';
  String get navUnlockHabitsMsg => 'Hay una nueva sección para ti. Tus hábitos ahora tienen su propio espacio.';
  String get navUnlockGrowthMsg => 'Tienes suficiente historia ahora para verla. Tu crecimiento tiene su propio espacio.';
  String get navNewBadge => 'Nuevo';
  String get notifReturn1day => '¿Cómo estás? No te he visto hoy.';
  String get notifReturn3days => 'Estoy aquí cuando estés listo. Tus hábitos te esperan.';
  String get notifReturn7days => 'Ha pasado una semana. Sin presión — pero cuando quieras volver, estoy aquí.';
  String get notifStreakRisk => 'El día está terminando. Todavía tienes tiempo.';
  String get notifMilestoneNear => 'Te faltan 2 días para una semana consecutiva. Ya casi estás.';
  String get notifNewUnlock => 'Hay algo nuevo para ti. Abre Be Well.';

  String get errorNetwork => 'Sin conexión a internet';
  String get errorGeneral => 'Algo salió mal. Inténtalo de nuevo.';
  String get errorInvalidEmail => 'Dirección de correo no válida';
  String get errorWeakPassword => 'La contraseña es demasiado débil';
  String get errorEmailInUse => 'Este correo ya está en uso';
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos';
}

// ── Extension per accesso rapido dal context ──────────────────────────────────
extension LocaleContext on BuildContext {
  BwStrings get s {
    try {
      return Provider.of<LocaleProvider>(this, listen: false).s;
    } catch (_) {
      return BwStrings.of(BwLocale.en);
    }
  }
  BwStrings get sL {
    try {
      return Provider.of<LocaleProvider>(this, listen: true).s;
    } catch (_) {
      return BwStrings.of(BwLocale.en);
    }
  }
}


