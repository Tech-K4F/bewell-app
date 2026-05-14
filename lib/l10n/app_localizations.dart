import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';

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
    _scheduleNotifications();
    notifyListeners();
  }

  Future<void> setLocale(BwLocale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.code);
    _scheduleNotifications();
    notifyListeners();
  }

  void _scheduleNotifications() {
    final strings = BwStrings.of(_locale);
    NotificationService.instance.rescheduleReminders(
      waterTitle:   strings.notifWaterTitle,
      waterBody:    strings.notifWaterBody,
      eveningTitle: strings.notifEveningTitle,
      eveningBody:  strings.notifEveningBody,
    );
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
  // ── Notification permission page (onboarding step 5) ─────────────────────
  String get notifPermTitle;
  String get notifPermBody;
  String get notifPermAllow;
  String get notifPermSkip;
  // ── Water UI ──────────────────────────────────────────────────────────────
  String get waterUndo;
  String get waterCooldown;
  String get waterContainerBtn;

  // ── Home ─────────────────────────────────────────────────────────────────
  String get goodMorning;
  String get phase;
  String get waterToday;
  String get waterGlasses;
  String get waterTrackedInHome;
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
  String get lockedForNow;

  // ── Percorso ─────────────────────────────────────────────────────────────
  String get yourJourney;
  String get activeHabits;
  String get nextUnlock;
  String get badges;
  String get noBadgesYet;
  String get todayCompleted;
  String get phase1; String get phase2; String get phase3;
  String get phase4; String get phase5;

  // ── Crescita ──────────────────────────────────────────────────────────────
  String get growthWellyJourney;
  String get growthOurJourney;
  String get growthConsistency;
  String get growthMoments;
  String get growthNextMilestone;

  // ── Milestone ─────────────────────────────────────────────────────────────
  String get milestone7days;
  String get milestone14days;
  String get milestone21days;
  String get milestone42days;
  String get milestone66days;
  String get milestone100days;

  // ── Welly stati ───────────────────────────────────────────────────────────
  String get wellyStateCalm;
  String get wellyStateRadiant;
  String get wellyStateReturning;

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
  // Testi notifiche push (background)
  String get notifWaterTitle;
  String get notifWaterBody;
  String get notifEveningTitle;
  String get notifEveningBody;
  String get notifHabitChoiceTitle;
  String get notifHabitChoiceBody;

  // ── Nav ───────────────────────────────────────────────────────────────────
  String get navHome;
  String get navHabits;
  String get navFocus;
  String get navGrowth;
  String get navPlan;
  String get navRewards;
  String get navProfile;
  String get navUnlockIn;
  String get navUnlockHabitsMsg;
  String get navUnlockGrowthMsg;
  String get comingSoonHabitsDesc;
  String get comingSoonGrowthDesc;
  String get achievementUnlocked;
  String get newHabitUnlocked;

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

  // ── Coach messages ────────────────────────────────────────────────────────
  String get coachDay1; String get coachDay3; String get coachDay7;
  String get coachDay14; String get coachGeneral;

  // ── Badges ────────────────────────────────────────────────────────────────
  String get badgeFirstStep; String get badgeFirstStepDesc;
  String get badgeOneWeek; String get badgeOneWeekDesc;
  String get badgeThreeWeeks; String get badgeThreeWeeksDesc;
  String get badgeSixWeeks; String get badgeSixWeeksDesc;
  String get badgeThreeMonths; String get badgeThreeMonthsDesc;
  String get badgeInSync; String get badgeInSyncDesc;
  String get badgeMultihabit; String get badgeMultihabitDesc;
  String get badgeHydrated; String get badgeHydratedDesc;
  String get badgeFocused; String get badgeFocusedDesc;
  String get badgeWalker; String get badgeWalkerDesc;
  String get badgeBreath; String get badgeBreathDesc;

  // ── Habit intro sheet ────────────────────────────────────────────────────
  String get habitChoiceTitle;
  String get habitChoiceSub;
  String get habitChoiceShowOther;
  String get habitChoiceOpen;
  String get habitEffortLow;
  String get habitEffortMedium;
  String get habitEffortHigh;

  // ── Errori ────────────────────────────────────────────────────────────────
  String get errorNetwork;
  String get errorGeneral;
  String get errorInvalidEmail;
  String get errorWeakPassword;
  String get errorEmailInUse;
  String get errorInvalidCredentials;

  // ── Tracker acqua personalizzato ──────────────────────────────────────────
  String get waterContainerGlass;
  String get waterContainerBottle;
  String get waterContainerSettings;
  String get waterGoalCalc;

  // ── Schermata Abitudini ───────────────────────────────────────────────────
  String get habitsMorningTitle;
  String get habitsMiddayTitle;
  String get habitsAfternoonTitle;
  String get habitsEveningTitle;
  String get habitsNowLabel;
  String get habitsComingSoon;
  String get habitsAllDone;
  String get habitsToday;
  String get completedToday;

  // ── Fasce orarie ─────────────────────────────────────────────────────────
  String get timeMorning;
  String get timeMidday;
  String get timeLunch;
  String get timeAfternoon;
  String get timeEvening;

  // ── Onboarding tipo utente ────────────────────────────────────────────────
  String get onboardingUserTypeTitle;
  String get onboardingStudent;
  String get onboardingWorker;

  // ── Banner / impostazioni orario lavoro ───────────────────────────────────
  String get workScheduleBanner;
  String get workScheduleConfirm;
  String get workScheduleEdit;
  String get workScheduleTitle;
  String get workScheduleMorning;
  String get workScheduleAfternoon;
  String get workScheduleLunch;
  String get workScheduleSave;

  // ── Sistema adattivo ──────────────────────────────────────────────────────
  String get slowdownPrompt;
  String get slowdownYes;
  String get slowdownNo;
  String get slowdownHabitMenu;
  String get slowdownWellyResponse;
  String get speedupPrompt;
  String get speedupYes;
  String get speedupNo;

  // ── Calendario ────────────────────────────────────────────────────────────
  String get calendarTitle;
  String get calendarFocus;
  String get calendarBreak;
  String get calendarLongBreak;

  // ── Home banners ─────────────────────────────────────────────────────────
  String get neverMissTwiceTitle;
  String get neverMissTwiceBody;
  String get neverMissTwiceCta;

  // ── Welly Bonus ───────────────────────────────────────────────────────────
  String get wellyBonusTitle;
  String get wellyBonusBody;

  // ── Focus avanzato ────────────────────────────────────────────────────────
  String get focusDeepWork;
  String get focusMinRemaining;
  String get focusBlockOf4;

  // ── Tutorial Welly ────────────────────────────────────────────────────────
  String get tutorialOk;
  String get tutorialMore;
  String get tutorialSkip;
  String tutorialText(String id);
  String? tutorialFact(String id);
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
  String get notifPermTitle => 'One last thing.';
  String get notifPermBody => 'To help you stay consistent, Welly can send you a gentle reminder — just once a day. No spam, no pressure. Only when it really matters.';
  String get notifPermAllow => 'Yes, enable notifications';
  String get notifPermSkip => 'Not now';
  String get waterUndo => 'Undo last';
  String get waterCooldown => 'Wait a moment…';
  String get waterContainerBtn => 'Container';

  String get goodMorning => 'Good morning,';
  String get phase => 'Phase';
  String get waterToday => 'Water today';
  String get waterGlasses => 'glasses';
  String get waterTrackedInHome => '💧 tracked in Home';
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
  String get lockedForNow => 'Locked for now';

  String get yourJourney => 'Your journey';
  String get activeHabits => 'Active habits';
  String get nextUnlock => 'Coming up';
  String get badges => 'Badges';
  String get noBadgesYet => 'Your badges will appear here as you progress.';
  String get todayCompleted => 'Completed today';
  String get phase1 => 'Seed'; String get phase2 => 'Sprout';
  String get phase3 => 'Young'; String get phase4 => 'Mature';
  // Growth
  String get growthWellyJourney => 'Welly\'s journey';
  String get growthOurJourney => 'Our journey';
  String get growthConsistency => 'Consistency';
  String get growthMoments => 'Moments';
  String get growthNextMilestone => 'Next milestone';
  String get milestone7days => 'First week in a row';
  String get milestone14days => 'Two weeks completed';
  String get milestone21days => 'Three weeks — the turning point';
  String get milestone42days => 'Six weeks of growth';
  String get milestone66days => 'Habit formed';
  String get milestone100days => 'One hundred days';
  String get wellyStateCalm => 'Welly is here';
  String get wellyStateRadiant => 'Welly is radiant';
  String get wellyStateReturning => 'Welcome back';
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
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min left';
  String get focusBlockOf4 => 'of 4';

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
  String get notifWaterTitle => '💧 Be Well';
  String get notifWaterBody => 'Have you drunk enough water today?';
  String get notifEveningTitle => 'Be Well 🌱';
  String get notifEveningBody => 'How are your habits going today?';
  String get notifHabitChoiceTitle => '✨ New habit available';
  String get notifHabitChoiceBody => 'Open Be Well to choose your next habit.';

  String get navHome => 'Home';
  String get navHabits => 'Habits';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Rewards';
  String get navProfile => 'Profile';
  String get navUnlockIn => 'Unlocks in';
  String get navUnlockHabitsMsg => 'Complete 3 days of water to unlock habits.';
  String get navUnlockGrowthMsg => 'Keep building habits to unlock your growth journey.';
  String get comingSoonHabitsDesc => 'Complete 3 consecutive days of water.\nYour focus timer will unlock.';
  String get comingSoonGrowthDesc => 'Keep building your habits.\nThe growth screen will unlock soon.';
  String get achievementUnlocked => 'Achievement unlocked!';
  String get newHabitUnlocked => 'New habit unlocked!';

  String get rewards => 'Rewards';
  String get rewardsPoints => 'Be Well points';
  String get rewardsLocked => 'Rewards are coming';
  String get rewardsLockedDesc => 'Keep building habits to unlock your rewards';
  String get rewardsHeader => 'Your rewards';
  String get rewardsHeaderSub => 'Collect what you\'ve earned';

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
  String get habitMicroWalkName => '5-min micro walk'; String get habitMicroWalkDesc => '5 minutes walking every 90 minutes — ultradian cycle';
  String get habitDigitalSunsetName => 'Digital sunset'; String get habitDigitalSunsetDesc => 'No social media in the hour before sleep';

  String get neverMissTwiceTitle => 'Don\'t miss two days in a row.';
  String get neverMissTwiceBody => 'One small action counts. Even a glass of water.';
  String get neverMissTwiceCta => '💧 Add a glass of water';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Triple points this round 🎉';

  String get coachDay1 => 'First day. The most important one.';
  String get coachDay3 => '3 days. Your body is starting to register it.';
  String get coachDay7 => '7 days. You\'re building something.';
  String get coachDay14 => '2 weeks. This habit is yours now.';
  String get coachGeneral => 'Every day counts. Even the hard ones.';

  String get badgeFirstStep => 'First step'; String get badgeFirstStepDesc => 'First day completed';
  String get badgeOneWeek => 'One week'; String get badgeOneWeekDesc => '7 days of habits';
  String get badgeThreeWeeks => 'Three weeks'; String get badgeThreeWeeksDesc => '21 days completed';
  String get badgeSixWeeks => 'Six weeks'; String get badgeSixWeeksDesc => '42 days completed';
  String get badgeThreeMonths => 'Three months'; String get badgeThreeMonthsDesc => '90 days of growth';
  String get badgeInSync => 'In sync'; String get badgeInSyncDesc => '2 active habits';
  String get badgeMultihabit => 'Multihabit'; String get badgeMultihabitDesc => '4 active habits';
  String get badgeHydrated => 'Well hydrated'; String get badgeHydratedDesc => 'Water consolidated';
  String get badgeFocused => 'In focus'; String get badgeFocusedDesc => 'Focus 25 consolidated';
  String get badgeWalker => 'Walker'; String get badgeWalkerDesc => 'Lunch walk consolidated';
  String get badgeBreath => 'Breath'; String get badgeBreathDesc => 'Breathing consolidated';

  String get habitChoiceTitle => 'Time to add something new.';
  String get habitChoiceSub => 'Choose where to focus next.';
  String get habitChoiceShowOther => 'show me other options ›';
  String get habitChoiceOpen => 'Choose your next habit';
  String get habitEffortLow => 'easy';
  String get habitEffortMedium => 'moderate';
  String get habitEffortHigh => 'challenging';

  String get errorNetwork => 'No internet connection';
  String get errorGeneral => 'Something went wrong. Try again.';
  String get errorInvalidEmail => 'Invalid email address';
  String get errorWeakPassword => 'Password is too weak';
  String get errorEmailInUse => 'This email is already in use';
  String get errorInvalidCredentials => 'Incorrect email or password';

  String get waterContainerGlass => 'glass';
  String get waterContainerBottle => 'bottle';
  String get waterContainerSettings => 'How are you tracking your water?';
  String get waterGoalCalc => 'You need about N containers for your 2 litres a day';

  String get habitsMorningTitle => 'Start the day well.';
  String get habitsMiddayTitle => 'In the right moment.';
  String get habitsAfternoonTitle => 'Good afternoon.';
  String get habitsEveningTitle => 'How did it go today?';
  String get habitsNowLabel => 'Right now';
  String get habitsComingSoon => 'Coming up';
  String get habitsAllDone => 'All good for now. Welly is with you.';
  String get habitsToday => 'Today';
  String get completedToday => 'completed today';

  String get timeMorning => 'Morning';
  String get timeMidday => 'Mid-morning';
  String get timeLunch => 'Lunch break';
  String get timeAfternoon => 'Afternoon';
  String get timeEvening => 'Evening';

  String get onboardingUserTypeTitle => 'And how do you spend your days?';
  String get onboardingStudent => 'Study';
  String get onboardingWorker => 'Work';

  String get workScheduleBanner => 'I\'ve set standard hours: 9-13 / 14-18. Is that right for you?';
  String get workScheduleConfirm => 'That\'s fine';
  String get workScheduleEdit => 'Edit';
  String get workScheduleTitle => 'Your working hours';
  String get workScheduleMorning => 'Morning';
  String get workScheduleAfternoon => 'Afternoon';
  String get workScheduleLunch => 'I have a fixed lunch break';
  String get workScheduleSave => 'Save';

  String get slowdownPrompt => 'I noticed you\'re finding it a bit hard to keep the pace. Want to slow down a little?';
  String get slowdownYes => 'Yes, let\'s slow down';
  String get slowdownNo => 'No, I\'ll keep going';
  String get slowdownHabitMenu => 'I need more time with this one';
  String get slowdownWellyResponse => 'No problem — let\'s strengthen this one before adding anything new. That\'s exactly the right choice.';
  String get speedupPrompt => 'You\'re doing really well — are you ready for something new ahead of schedule?';
  String get speedupYes => 'Yes, I\'m ready';
  String get speedupNo => 'No, I\'ll stay here';

  String get calendarTitle => 'Your rhythm today';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Break';
  String get calendarLongBreak => 'Long break';

  String get tutorialOk   => 'Got it!';
  String get tutorialMore => 'Tell me more →';
  String get tutorialSkip => 'Skip';

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return '✅ ${habitName(hid)} is now in your plan! ${habitDesc(hid)} Complete it every day to make it stick.';
    }
    switch (id) {
      case 'home_first_open':     return 'Welcome! This is your base. At the top you\'ll always find the most urgent habit for right now. Start there — everything else can wait.';
      case 'home_first_open_2':   return 'Water is the first habit because it\'s the biological foundation for everything else. Without hydration, concentration drops by up to 20% after just 90 minutes.';
      case 'water_tracker_first': return 'The tracker counts glasses from when you open the app each morning. 8 a day is the target — but even hitting 5 is already better than yesterday.';
      case 'first_completion':    return 'Done! Every completion creates a new neural connection. Small, but real. Your brain has just strengthened a circuit.';
      case 'streak_explain':      return 'If you come back tomorrow, your streak begins. The only rule that matters: never skip two days in a row. One stop is human. Two is a new habit — the wrong one.';
      case 'habits_tab_first':    return 'Here you\'ll find all your habits sorted for the best moment in your day. Welly knows your rhythms — morning habits appear in the morning, evening ones in the evening.';
      case 'habit_card_explain':  return 'The circular arc fills each time you complete. At 7 days something interesting happens — your brain starts registering it as a routine.';
      case 'focus_unlocked':      return 'You\'ve unlocked the 25-minute Focus! The human brain has a natural concentration cycle of about 20–30 minutes. You\'ve earned this by building the water habit.';
      case 'focus_unlocked_2':    return 'Golden rule of Focus: when the timer starts, the phone goes face-down. Even Welly goes quiet. The notification you\'re waiting for can wait 25 minutes — I promise.';
      case 'calendar_appears':    return 'New! The contextual calendar shows only the coming hours, not the whole day. Less to see = more mental space to act. The distant future isn\'t your problem yet.';
      case 'growth_first_visit':  return 'This section shows who you\'re becoming, not just what you\'re doing. The phases aren\'t rewards — they\'re real descriptions of your neurological change. Science, not motivation, guides the journey.';
      case 'phase2_reached':      return '🌱 Phase 2: Beginning! Your first habit has become automatic — your brain no longer needs to decide to do it. A new habit pair is waiting for you to choose from. Pick the one that feels right.';
      case 'phase3_reached':      return '🌿 Phase 3: Growth! Three habits consolidated. Your routine truly exists now — it\'s no longer an effort, it\'s a structure. The hardest part is behind you.';
      case 'phase4_reached':      return '🌳 Phase 4: Roots. Seven habits absorbed — your routine has become a lifestyle. Most people never get here. You\'ve done it through consistency, not willpower.';
      case 'phase5_reached':      return '🌸 Flourishing. You\'ve arrived. It doesn\'t mean it\'s over — it means you\'ve become someone who builds habits. That\'s the real result. Not the individual habits, but the ability.';
      case 'milestone_7_days':    return '7 consecutive days! Science says that after this threshold, 90% of those who continue will reach 21. You\'re in the zone where change becomes much more likely.';
      case 'milestone_21_days':   return '21 days! The old myth said 3 weeks was enough to form a habit. The truth: 21 days builds only the initial groove. Now starts the part where it truly becomes yours.';
      case 'milestone_66_days':   return '66 days! This is the magic number from Phillippa Lally\'s UCL study. Officially, according to science, you\'ve formed a habit. You\'re not building it — you have it.';
      case 'streak_broken':       return 'No problem. The rule is simple: never skip two days in a row. You\'re already back today — the streak restarts from now. Welly doesn\'t count the days you missed.';
      case 'no_completion_3days': return 'Welly is still here. No judgement. Coming back is easier than you think — even a single glass of water counts. One small act reactivates the loop.';
      case 'perfect_week':        return 'Perfect week! 7 out of 7 completions. Your brain received 7 consecutive reinforcement signals. From a neurological standpoint, this week counted triple.';
      case 'rewards_first_visit': return 'Badges aren\'t fake points. Each badge corresponds to a real behaviour you\'ve maintained for a measurable period. They\'re snapshots of your progress, not decorations.';
      default: return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':   return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first': return 'EFSA: daily water requirement 2.0–2.5 L for adults under normal conditions.';
      case 'first_completion':    return 'Hebb (1949): "neurons that fire together, wire together" — each repetition strengthens the synapse.';
      case 'streak_explain':      return 'James Clear, Atomic Habits: "Never miss twice" is the most effective rule for maintaining a habit.';
      case 'habit_card_explain':  return 'Phillippa Lally (UCL, 2010): automaticity begins on average between 18 and 66 days, with the biggest growth in the first weeks.';
      case 'focus_unlocked':      return 'Kleitman (1963): ultradian cycles of 90 min with attention peaks of 20–30 min. Pomodoro techniques leverage this rhythm.';
      case 'calendar_appears':    return 'Sweller (1988): Cognitive Load Theory — fewer simultaneously visible pieces of information = better decisions.';
      case 'growth_first_visit':  return 'Wood & Neal (2007): identity changes when behaviours become automatic. Identity precedes action.';
      case 'phase2_reached':      return 'Gardner (2012): automaticity = execution without conscious intention. The first automatism is always the hardest.';
      case 'phase3_reached':      return 'Lally et al. (2010): with 3 consolidated habits, long-term compliance rises significantly compared to just 1.';
      case 'phase4_reached':      return 'Duhigg (2012): consolidated routines require almost zero conscious deliberation — the prefrontal cortex delegates to the basal ganglia.';
      case 'milestone_7_days':    return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: automaticity grows most rapidly in the first weeks — initial consistency is the strongest predictor of long-term maintenance.';
      case 'milestone_21_days':   return 'Maltz (1960): the "21 days" was a surgical observation, not a scientific study. Lally (2010) estimates 66 days on average.';
      case 'milestone_66_days':   return 'Lally et al. (2010), UCL: average of 66 days (range 18–254) to reach behavioural automaticity.';
      case 'no_completion_3days': return 'Fogg (2020): Tiny Habits — even a minimal action keeps the habit neural loop alive.';
      case 'perfect_week':        return 'Schultz et al. (1997): the dopaminergic system responds to the consistency of reinforcement — consecutive sequences amplify the effect.';
      default: return null;
    }
  }
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
  String get notifPermTitle => 'Un\'ultima cosa.';
  String get notifPermBody => 'Per aiutarti a restare costante, Welly può mandarti un promemoria gentile — solo una volta al giorno. Niente spam, niente pressioni. Solo quando conta davvero.';
  String get notifPermAllow => 'Sì, attiva le notifiche';
  String get notifPermSkip => 'Magari dopo';
  String get waterUndo => 'Annulla ultimo';
  String get waterCooldown => 'Aspetta un attimo…';
  String get waterContainerBtn => 'Contenitore';

  String get goodMorning => 'Buongiorno,';
  String get phase => 'Fase';
  String get waterToday => 'Acqua oggi';
  String get waterGlasses => 'bicchieri';
  String get waterTrackedInHome => '💧 tracciata in Home';
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
  String get lockedForNow => 'Bloccata per ora';

  String get yourJourney => 'Il tuo percorso';
  String get activeHabits => 'Abitudini attive';
  String get nextUnlock => 'In arrivo';
  String get badges => 'Badge';
  String get noBadgesYet => 'I tuoi badge appariranno qui man mano che progredisci.';
  String get todayCompleted => 'Completato oggi';
  String get phase1 => 'Seme'; String get phase2 => 'Germoglio';
  String get phase3 => 'Giovane'; String get phase4 => 'Maturo';
  // Crescita
  String get growthWellyJourney => 'Il percorso di Welly';
  String get growthOurJourney => 'Il nostro percorso';
  String get growthConsistency => 'Consistenza';
  String get growthMoments => 'Momenti';
  String get growthNextMilestone => 'Prossimo traguardo';
  String get milestone7days => 'Prima settimana consecutiva';
  String get milestone14days => 'Due settimane completate';
  String get milestone21days => 'Tre settimane — la svolta';
  String get milestone42days => 'Sei settimane di crescita';
  String get milestone66days => 'Abitudine formata';
  String get milestone100days => 'Cento giorni';
  String get wellyStateCalm => 'Welly è con te';
  String get wellyStateRadiant => 'Welly è raggiante';
  String get wellyStateReturning => 'Bentornato';
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
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min rimasti';
  String get focusBlockOf4 => 'di 4';

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
  String get notifWaterTitle => '💧 Be Well';
  String get notifWaterBody => 'Hai bevuto abbastanza acqua oggi?';
  String get notifEveningTitle => 'Be Well 🌱';
  String get notifEveningBody => 'Come stai andando con le tue abitudini oggi?';
  String get notifHabitChoiceTitle => '✨ Nuova abitudine disponibile';
  String get notifHabitChoiceBody => 'Apri Be Well per scegliere la tua prossima abitudine.';

  String get navHome => 'Home';
  String get navHabits => 'Abitudini';
  String get navFocus => 'Focus';
  String get navGrowth => 'Crescita';
  String get navPlan => 'Piano';
  String get navRewards => 'Premi';
  String get navProfile => 'Profilo';
  String get navUnlockIn => 'Sblocco tra';
  String get navUnlockHabitsMsg => 'Completa 3 giorni di acqua per sbloccare le abitudini.';
  String get navUnlockGrowthMsg => 'Continua a costruire abitudini per sbloccare la crescita.';
  String get comingSoonHabitsDesc => 'Completa 3 giorni consecutivi di acqua.\nIl tuo focus timer si sbloccherà.';
  String get comingSoonGrowthDesc => 'Continua a costruire le tue abitudini.\nLa schermata di crescita si sbloccherà presto.';
  String get achievementUnlocked => 'Achievement sbloccato!';
  String get newHabitUnlocked => 'Nuova abitudine sbloccata!';

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
  String get habitMicroWalkName => 'Micro-camminata 5 min'; String get habitMicroWalkDesc => '5 minuti di camminata ogni 90 minuti — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Digital sunset'; String get habitDigitalSunsetDesc => 'Niente social media nell\'ora prima di dormire';

  String get neverMissTwiceTitle => 'Stai per saltare due giorni di fila.';
  String get neverMissTwiceBody => 'Una sola azione conta. Anche un bicchiere d\'acqua.';
  String get neverMissTwiceCta => '💧 Aggiungi un bicchiere d\'acqua';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Punti tripli questo giro 🎉';

  String get coachDay1 => 'Primo giorno. Il più importante.';
  String get coachDay3 => '3 giorni. Il corpo inizia a registrarlo.';
  String get coachDay7 => '7 giorni. Stai costruendo qualcosa.';
  String get coachDay14 => '2 settimane. Questa abitudine è tua adesso.';
  String get coachGeneral => 'Ogni giorno conta. Anche i giorni difficili.';

  String get badgeFirstStep => 'Primo passo'; String get badgeFirstStepDesc => 'Primo giorno completato';
  String get badgeOneWeek => 'Una settimana'; String get badgeOneWeekDesc => '7 giorni di abitudini';
  String get badgeThreeWeeks => 'Tre settimane'; String get badgeThreeWeeksDesc => '21 giorni completati';
  String get badgeSixWeeks => 'Un mese e mezzo'; String get badgeSixWeeksDesc => '42 giorni completati';
  String get badgeThreeMonths => 'Tre mesi'; String get badgeThreeMonthsDesc => '90 giorni di crescita';
  String get badgeInSync => 'In sincronia'; String get badgeInSyncDesc => '2 abitudini attive';
  String get badgeMultihabit => 'Multihabit'; String get badgeMultihabitDesc => '4 abitudini attive';
  String get badgeHydrated => 'Ben idratato'; String get badgeHydratedDesc => 'Acqua consolidata';
  String get badgeFocused => 'In focus'; String get badgeFocusedDesc => 'Focus 25 min consolidato';
  String get badgeWalker => 'Camminatore'; String get badgeWalkerDesc => 'Passeggiata pranzo consolidata';
  String get badgeBreath => 'Respiro'; String get badgeBreathDesc => 'Respirazione consolidata';

  String get habitChoiceTitle => 'È il momento di aggiungere\nqualcosa di nuovo.';
  String get habitChoiceSub => 'Scegli dove concentrarti adesso.';
  String get habitChoiceShowOther => 'mostrami altre opzioni ›';
  String get habitChoiceOpen => 'Scegli la prossima abitudine';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'moderato';
  String get habitEffortHigh => 'impegnativo';

  String get errorNetwork => 'Nessuna connessione internet';
  String get errorGeneral => 'Qualcosa è andato storto. Riprova.';
  String get errorInvalidEmail => 'Indirizzo email non valido';
  String get errorWeakPassword => 'La password è troppo debole';
  String get errorEmailInUse => 'Questa email è già in uso';
  String get errorInvalidCredentials => 'Email o password errati';

  String get waterContainerGlass => 'bicchiere';
  String get waterContainerBottle => 'borraccia';
  String get waterContainerSettings => 'Come stai tracciando l\'acqua?';
  String get waterGoalCalc => 'Ci vogliono circa N contenitori per i tuoi 2 litri al giorno';

  String get habitsMorningTitle => 'Inizia bene la giornata.';
  String get habitsMiddayTitle => 'Nel momento giusto.';
  String get habitsAfternoonTitle => 'Buon pomeriggio.';
  String get habitsEveningTitle => 'Come è andata oggi?';
  String get habitsNowLabel => 'Adesso';
  String get habitsComingSoon => 'Prossimamente';
  String get habitsAllDone => 'Tutto sotto controllo per ora. Welly è con te.';
  String get habitsToday => 'In lista oggi';
  String get completedToday => 'completate oggi';

  String get timeMorning => 'Mattina';
  String get timeMidday => 'Metà mattina';
  String get timeLunch => 'Pausa pranzo';
  String get timeAfternoon => 'Pomeriggio';
  String get timeEvening => 'Sera';

  String get onboardingUserTypeTitle => 'E come passi le tue giornate?';
  String get onboardingStudent => 'Studio';
  String get onboardingWorker => 'Lavoro';

  String get workScheduleBanner => 'Ho impostato orario standard: 9-13 / 14-18. È quello giusto per te?';
  String get workScheduleConfirm => 'Va bene così';
  String get workScheduleEdit => 'Modifica';
  String get workScheduleTitle => 'I tuoi orari di lavoro';
  String get workScheduleMorning => 'Mattina';
  String get workScheduleAfternoon => 'Pomeriggio';
  String get workScheduleLunch => 'Ho una pausa pranzo fissa';
  String get workScheduleSave => 'Salva';

  String get slowdownPrompt => 'Ho notato che stai trovando un po\' difficile mantenere il ritmo. Vuoi che rallentiamo un po\'?';
  String get slowdownYes => 'Sì, rallentiamo';
  String get slowdownNo => 'No, continuo';
  String get slowdownHabitMenu => 'Ho bisogno di più tempo con questa';
  String get slowdownWellyResponse => 'Nessun problema — rafforziamo questa prima di aggiungere altro. È esattamente la scelta giusta.';
  String get speedupPrompt => 'Stai andando molto bene — sei pronto per qualcosa di nuovo prima del previsto?';
  String get speedupYes => 'Sì, sono pronto';
  String get speedupNo => 'No, resto qui';

  String get calendarTitle => 'Il tuo ritmo oggi';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pausa';
  String get calendarLongBreak => 'Pausa lunga';

  String get tutorialOk   => 'Capito!';
  String get tutorialMore => 'Di più →';
  String get tutorialSkip => 'Salta';

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return '✅ ${habitName(hid)} è ora nel tuo piano! ${habitDesc(hid)} Completala ogni giorno per consolidarla.';
    }
    switch (id) {
      case 'home_first_open':     return 'Benvenuto! Questa è la tua base. In cima trovi sempre l\'abitudine più urgente per adesso. Inizia sempre da lì — il resto può aspettare.';
      case 'home_first_open_2':   return 'L\'acqua è la prima abitudine perché è la base biologica di tutto il resto. Senza idratazione, la concentrazione cala fino al 20% già dopo 90 minuti.';
      case 'water_tracker_first': return 'Il tracker conta i bicchieri da quando apri l\'app ogni mattina. 8 al giorno è il target — ma anche arrivare a 5 è già meglio di ieri.';
      case 'first_completion':    return 'Fatto! Ogni completamento crea una connessione neurale nuova. Piccola, ma reale. Il tuo cervello ha appena rinforzato un circuito.';
      case 'streak_explain':      return 'Se torni domani, inizia la tua streak. L\'unica regola che conta: non saltare mai due giorni di fila. Uno stop è umano. Due sono un\'abitudine nuova — quella sbagliata.';
      case 'habits_tab_first':    return 'Qui trovi tutte le abitudini ordinate per il momento migliore della tua giornata. Welly conosce i tuoi ritmi — le abitudini mattutine si mostrano di mattina, quelle serali di sera.';
      case 'habit_card_explain':  return 'L\'arco circolare in basso a sinistra si riempie ogni volta che completi. A 7 giorni scatta qualcosa di interessante — il tuo cervello inizia a registrarla come routina.';
      case 'focus_unlocked':      return 'Hai sbloccato il Focus da 25 minuti! Il cervello umano ha un ciclo naturale di concentrazione di circa 20–30 minuti. Hai guadagnato questa abilità costruendo l\'abitudine dell\'acqua.';
      case 'focus_unlocked_2':    return 'Regola d\'oro del Focus: quando il timer parte, il telefono va a faccia in giù. Anche Welly tace. La notifica che aspetti può aspettare 25 minuti — lo prometto.';
      case 'calendar_appears':    return 'Nuovo! Il calendario contestuale mostra solo le prossime ore, non l\'intera giornata. Meno cose da vedere = più spazio mentale per agire. Il futuro lontano non è ancora il tuo problema.';
      case 'growth_first_visit':  return 'Questa scheda mostra chi stai diventando, non solo cosa stai facendo. Le fasi non sono premi — sono descrizioni reali del tuo cambiamento neurologico. La scienza, non la motivazione, guida il percorso.';
      case 'phase2_reached':      return '🌱 Fase 2: Inizio! La tua prima abitudine è diventata automatica — il tuo cervello non ha più bisogno di "decidere" di farla. Una nuova coppia di abitudini ti aspetta. Scegli quella che senti più adatta a te.';
      case 'phase3_reached':      return '🌿 Fase 3: Crescita! Tre abitudini consolidate. A questo punto la tua routine esiste davvero — non è più uno sforzo, è una struttura. Il più duro è alle spalle.';
      case 'phase4_reached':      return '🌳 Fase 4: Radici. Sette abitudini assimilate — la tua routine è diventata stile di vita. La maggior parte delle persone non arriva qui. Tu l\'hai fatto con costanza, non con forza di volontà.';
      case 'phase5_reached':      return '🌸 Fioritura. Sei arrivato. Non vuol dire che finisce — vuol dire che sei diventato qualcuno che costruisce abitudini. Questo è il vero risultato. Non le singole abitudini, ma la capacità.';
      case 'milestone_7_days':    return '7 giorni consecutivi! La scienza dice che dopo questa soglia il 90% di chi continua arriverà a 21. Sei nella zona in cui il cambiamento diventa molto più probabile.';
      case 'milestone_21_days':   return '21 giorni! Il vecchio mito diceva che bastano 3 settimane per formare un\'abitudine. La verità: 21 giorni costruiscono solo il groove iniziale. Ora inizia la parte in cui diventa davvero tua.';
      case 'milestone_66_days':   return '66 giorni! Questo è il numero magico dello studio di Phillippa Lally all\'UCL. Ufficialmente, secondo la scienza, hai formato un\'abitudine. Non la stai costruendo — la hai.';
      case 'streak_broken':       return 'Nessun problema. La regola è semplice: mai saltare due giorni di fila. Oggi sei già tornato — la streak riparte da adesso. Welly non conta i giorni saltati.';
      case 'no_completion_3days': return 'Welly è ancora qui. Nessun giudizio. Rientrare è più facile di quanto pensi — anche solo un bicchiere d\'acqua conta. Un atto minimo riattiva il loop.';
      case 'perfect_week':        return 'Settimana perfetta! 7 completamenti su 7. Il tuo cervello ha ricevuto 7 segnali di rinforzo consecutivi. Dal punto di vista neurologico, questa settimana ha contato triplo.';
      case 'rewards_first_visit': return 'I badge non sono punti finti. Ogni badge corrisponde a un comportamento reale che hai mantenuto per un periodo misurabile. Sono snapshot del tuo progresso, non decorazioni.';
      default: return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':   return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first': return 'EFSA: fabbisogno idrico giornaliero 2,0–2,5 L per adulti in condizioni normali.';
      case 'first_completion':    return 'Hebb (1949): "neurons that fire together, wire together" — ogni repetizione rafforza la sinapsi.';
      case 'streak_explain':      return 'James Clear, Atomic Habits: "Never miss twice" è la regola più efficace per mantenere un\'abitudine.';
      case 'habit_card_explain':  return 'Phillippa Lally (UCL, 2010): l\'automaticità inizia in media tra i 18 e i 66 giorni, con il picco di crescita nelle prime settimane.';
      case 'focus_unlocked':      return 'Kleitman (1963): cicli ultradiani di 90 min con picchi di attenzione da 20–30 min. Tecniche Pomodoro sfruttano questo ritmo.';
      case 'calendar_appears':    return 'Sweller (1988): Cognitive Load Theory — meno informazioni visibili simultaneamente = migliori decisioni.';
      case 'growth_first_visit':  return 'Wood & Neal (2007): l\'identità cambia quando i comportamenti diventano automatici. Identity precedes action.';
      case 'phase2_reached':      return 'Gardner (2012): automaticità = esecuzione senza intenzione conscia. Il primo automatismo è sempre il più difficile.';
      case 'phase3_reached':      return 'Lally et al. (2010): con 3 abitudini consolidate, la compliance a lungo termine sale significativamente rispetto a 1 sola.';
      case 'phase4_reached':      return 'Duhigg (2012): routine consolidate richiedono quasi zero deliberazione conscia — la corteccia prefrontale delega ai gangli basali.';
      case 'milestone_7_days':    return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: l\'automaticità cresce più rapidamente nelle prime settimane — la consistenza iniziale è il predittore più forte del mantenimento.';
      case 'milestone_21_days':   return 'Maltz (1960): il "21 giorni" era un\'osservazione chirurgica, non uno studio scientifico. Lally (2010) stima 66 gg in media.';
      case 'milestone_66_days':   return 'Lally et al. (2010), UCL: media di 66 giorni (range 18–254) per raggiungere l\'automaticità comportamentale.';
      case 'no_completion_3days': return 'Fogg (2020): Tiny Habits — anche un\'azione minima mantiene vivo il loop neurale dell\'abitudine.';
      case 'perfect_week':        return 'Schultz et al. (1997): il sistema dopaminergico risponde alla coerenza del rinforzo — sequenze consecutive amplificano l\'effetto.';
      default: return null;
    }
  }
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
  String get notifPermTitle => 'Une dernière chose.';
  String get notifPermBody => 'Pour vous aider à rester régulier, Welly peut vous envoyer un rappel doux — juste une fois par jour. Pas de spam, pas de pression. Seulement quand ça compte vraiment.';
  String get notifPermAllow => 'Oui, activer les notifications';
  String get notifPermSkip => 'Pas maintenant';
  String get waterUndo => 'Annuler le dernier';
  String get waterCooldown => 'Attendez un instant…';
  String get waterContainerBtn => 'Contenant';

  String get goodMorning => 'Bonjour,';
  String get phase => 'Phase';
  String get waterToday => 'Eau aujourd\'hui';
  String get waterGlasses => 'verres';
  String get waterTrackedInHome => '💧 suivi dans Accueil';
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
  String get lockedForNow => 'Bloqué pour l\'instant';

  String get yourJourney => 'Votre parcours';
  String get activeHabits => 'Habitudes actives';
  String get nextUnlock => 'À venir';
  String get badges => 'Badges';
  String get noBadgesYet => 'Vos badges apparaîtront ici au fil de votre progression.';
  String get todayCompleted => 'Complété aujourd\'hui';
  String get phase1 => 'Graine'; String get phase2 => 'Pousse';
  String get phase3 => 'Jeune'; String get phase4 => 'Mature';
  // Croissance
  String get growthWellyJourney => 'Le parcours de Welly';
  String get growthOurJourney => 'Notre parcours';
  String get growthConsistency => 'Régularité';
  String get growthMoments => 'Moments';
  String get growthNextMilestone => 'Prochain jalon';
  String get milestone7days => 'Première semaine d\'affilée';
  String get milestone14days => 'Deux semaines complétées';
  String get milestone21days => 'Trois semaines — le tournant';
  String get milestone42days => 'Six semaines de croissance';
  String get milestone66days => 'Habitude formée';
  String get milestone100days => 'Cent jours';
  String get wellyStateCalm => 'Welly est là';
  String get wellyStateRadiant => 'Welly est radieux';
  String get wellyStateReturning => 'Bienvenue de retour';
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
  String get focusDeepWork => 'Travail profond';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'sur 4';

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
  String get notifWaterTitle => '💧 Be Well';
  String get notifWaterBody => 'As-tu bu assez d\'eau aujourd\'hui?';
  String get notifEveningTitle => 'Be Well 🌱';
  String get notifEveningBody => 'Comment se passent tes habitudes aujourd\'hui?';
  String get notifHabitChoiceTitle => '✨ Nouvelle habitude disponible';
  String get notifHabitChoiceBody => 'Ouvre Be Well pour choisir ta prochaine habitude.';

  String get navHome => 'Accueil';
  String get navHabits => 'Habitudes';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Récompenses';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Débloque dans';
  String get navUnlockHabitsMsg => 'Complétez 3 jours d\'eau pour débloquer les habitudes.';
  String get navUnlockGrowthMsg => 'Continuez à construire des habitudes pour débloquer la croissance.';
  String get comingSoonHabitsDesc => 'Complétez 3 jours consécutifs d\'eau.\nVotre minuteur focus se débloquera.';
  String get comingSoonGrowthDesc => 'Continuez à construire vos habitudes.\nL\'écran de croissance se débloquera bientôt.';
  String get achievementUnlocked => 'Achievement débloqué !';
  String get newHabitUnlocked => 'Nouvelle habitude débloquée !';

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
  String get habitMicroWalkName => 'Micro-marche 5 min'; String get habitMicroWalkDesc => '5 minutes de marche toutes les 90 minutes — cycle ultradien';
  String get habitDigitalSunsetName => 'Coucher digital'; String get habitDigitalSunsetDesc => 'Pas de réseaux sociaux dans l\'heure avant de dormir';

  String get neverMissTwiceTitle => 'Ne ratez pas deux jours de suite.';
  String get neverMissTwiceBody => 'Une seule action compte. Même un verre d\'eau.';
  String get neverMissTwiceCta => '💧 Ajouter un verre d\'eau';
  String get wellyBonusTitle => 'Bonus Welly !';
  String get wellyBonusBody => 'Points triplés ce tour 🎉';

  String get coachDay1 => 'Premier jour. Le plus important.';
  String get coachDay3 => '3 jours. Votre corps commence à l\'enregistrer.';
  String get coachDay7 => '7 jours. Vous construisez quelque chose.';
  String get coachDay14 => '2 semaines. Cette habitude est la vôtre maintenant.';
  String get coachGeneral => 'Chaque jour compte. Même les jours difficiles.';

  String get badgeFirstStep => 'Premier pas'; String get badgeFirstStepDesc => 'Premier jour complété';
  String get badgeOneWeek => 'Une semaine'; String get badgeOneWeekDesc => '7 jours d\'habitudes';
  String get badgeThreeWeeks => 'Trois semaines'; String get badgeThreeWeeksDesc => '21 jours complétés';
  String get badgeSixWeeks => 'Six semaines'; String get badgeSixWeeksDesc => '42 jours complétés';
  String get badgeThreeMonths => 'Trois mois'; String get badgeThreeMonthsDesc => '90 jours de croissance';
  String get badgeInSync => 'En synchronie'; String get badgeInSyncDesc => '2 habitudes actives';
  String get badgeMultihabit => 'Multihabitude'; String get badgeMultihabitDesc => '4 habitudes actives';
  String get badgeHydrated => 'Bien hydraté'; String get badgeHydratedDesc => 'Eau consolidée';
  String get badgeFocused => 'En focus'; String get badgeFocusedDesc => 'Focus 25 min consolidé';
  String get badgeWalker => 'Marcheur'; String get badgeWalkerDesc => 'Marche déjeuner consolidée';
  String get badgeBreath => 'Souffle'; String get badgeBreathDesc => 'Respiration consolidée';

  String get habitChoiceTitle => 'Il est temps d\'ajouter\nquelque chose de nouveau.';
  String get habitChoiceSub => 'Choisissez où vous concentrer.';
  String get habitChoiceShowOther => 'voir d\'autres options ›';
  String get habitChoiceOpen => 'Choisir votre prochaine habitude';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'modéré';
  String get habitEffortHigh => 'exigeant';

  String get errorNetwork => 'Pas de connexion internet';
  String get errorGeneral => 'Quelque chose s\'est mal passé. Réessayez.';
  String get errorInvalidEmail => 'Adresse email invalide';
  String get errorWeakPassword => 'Le mot de passe est trop faible';
  String get errorEmailInUse => 'Cet email est déjà utilisé';
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect';

  String get waterContainerGlass => 'verre';
  String get waterContainerBottle => 'gourde';
  String get waterContainerSettings => 'Comment suis-tu ta consommation d\'eau ?';
  String get waterGoalCalc => 'Il te faut environ N contenants pour tes 2 litres par jour';

  String get habitsMorningTitle => 'Bien commencer la journée.';
  String get habitsMiddayTitle => 'Au bon moment.';
  String get habitsAfternoonTitle => 'Bon après-midi.';
  String get habitsEveningTitle => 'Comment s\'est passée ta journée ?';
  String get habitsNowLabel => 'Maintenant';
  String get habitsComingSoon => 'À venir';
  String get habitsAllDone => 'Tout est bon pour l\'instant. Welly est avec toi.';
  String get habitsToday => 'Aujourd\'hui';
  String get completedToday => 'complétées aujourd\'hui';

  String get timeMorning => 'Matin';
  String get timeMidday => 'Milieu de matinée';
  String get timeLunch => 'Pause déjeuner';
  String get timeAfternoon => 'Après-midi';
  String get timeEvening => 'Soir';

  String get onboardingUserTypeTitle => 'Et comment passes-tu tes journées ?';
  String get onboardingStudent => 'Études';
  String get onboardingWorker => 'Travail';

  String get workScheduleBanner => 'J\'ai configuré les horaires standard : 9-13 / 14-18. C\'est le bon ?';
  String get workScheduleConfirm => 'C\'est bon';
  String get workScheduleEdit => 'Modifier';
  String get workScheduleTitle => 'Tes horaires de travail';
  String get workScheduleMorning => 'Matin';
  String get workScheduleAfternoon => 'Après-midi';
  String get workScheduleLunch => 'J\'ai une pause déjeuner fixe';
  String get workScheduleSave => 'Enregistrer';

  String get slowdownPrompt => 'J\'ai remarqué que tu as du mal à maintenir le rythme. Tu veux qu\'on ralentisse un peu ?';
  String get slowdownYes => 'Oui, ralentissons';
  String get slowdownNo => 'Non, je continue';
  String get slowdownHabitMenu => 'J\'ai besoin de plus de temps avec celle-ci';
  String get slowdownWellyResponse => 'Pas de problème — renforçons celle-ci avant d\'en ajouter une autre. C\'est exactement le bon choix.';
  String get speedupPrompt => 'Tu vas très bien — es-tu prêt pour quelque chose de nouveau avant le temps prévu ?';
  String get speedupYes => 'Oui, je suis prêt';
  String get speedupNo => 'Non, je reste ici';

  String get calendarTitle => 'Ton rythme aujourd\'hui';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pause';
  String get calendarLongBreak => 'Grande pause';

  String get tutorialOk   => 'Compris !';
  String get tutorialMore => 'En savoir plus →';
  String get tutorialSkip => 'Passer';

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return '✅ ${habitName(hid)} est maintenant dans ton plan ! ${habitDesc(hid)} Accomplis-la chaque jour pour l\'ancrer.';
    }
    switch (id) {
      case 'home_first_open':     return 'Bienvenue ! Voici ta base. En haut, tu trouveras toujours l\'habitude la plus urgente du moment. Commence toujours par là — le reste peut attendre.';
      case 'home_first_open_2':   return 'L\'eau est la première habitude parce que c\'est le fondement biologique de tout le reste. Sans hydratation, la concentration chute jusqu\'à 20 % après seulement 90 minutes.';
      case 'water_tracker_first': return 'Le tracker compte les verres depuis l\'ouverture de l\'app chaque matin. 8 par jour est l\'objectif — mais même atteindre 5, c\'est déjà mieux qu\'hier.';
      case 'first_completion':    return 'Fait ! Chaque accomplissement crée une nouvelle connexion neurale. Petite, mais réelle. Ton cerveau vient de renforcer un circuit.';
      case 'streak_explain':      return 'Si tu reviens demain, ta série commence. La seule règle qui compte : ne jamais sauter deux jours de suite. Un arrêt, c\'est humain. Deux, c\'est une nouvelle habitude — la mauvaise.';
      case 'habits_tab_first':    return 'Ici tu trouves toutes tes habitudes organisées pour le meilleur moment de ta journée. Welly connaît tes rythmes — les habitudes matinales apparaissent le matin, celles du soir le soir.';
      case 'habit_card_explain':  return 'L\'arc circulaire se remplit chaque fois que tu complètes. À 7 jours, quelque chose d\'intéressant se passe — ton cerveau commence à l\'enregistrer comme une routine.';
      case 'focus_unlocked':      return 'Tu as débloqué le Focus de 25 minutes ! Le cerveau humain a un cycle naturel de concentration d\'environ 20–30 minutes. Tu as gagné cette capacité en construisant l\'habitude de l\'eau.';
      case 'focus_unlocked_2':    return 'Règle d\'or du Focus : quand le minuteur part, le téléphone est posé face en bas. Même Welly se tait. La notification que tu attends peut attendre 25 minutes — promis.';
      case 'calendar_appears':    return 'Nouveau ! Le calendrier contextuel montre uniquement les prochaines heures, pas toute la journée. Moins à voir = plus d\'espace mental pour agir. Le futur lointain n\'est pas encore ton problème.';
      case 'growth_first_visit':  return 'Cette section montre qui tu deviens, pas seulement ce que tu fais. Les phases ne sont pas des récompenses — ce sont de vraies descriptions de ton changement neurologique. La science, pas la motivation, guide le parcours.';
      case 'phase2_reached':      return '🌱 Phase 2 : Début ! Ta première habitude est devenue automatique — ton cerveau n\'a plus besoin de « décider » de la faire. Une nouvelle paire d\'habitudes t\'attend. Choisis celle qui te semble la plus juste.';
      case 'phase3_reached':      return '🌿 Phase 3 : Croissance ! Trois habitudes consolidées. Ta routine existe vraiment maintenant — ce n\'est plus un effort, c\'est une structure. Le plus dur est derrière toi.';
      case 'phase4_reached':      return '🌳 Phase 4 : Racines. Sept habitudes assimilées — ta routine est devenue un mode de vie. La plupart des gens n\'arrivent pas là. Tu l\'as fait par constance, pas par volonté.';
      case 'phase5_reached':      return '🌸 Épanouissement. Tu es arrivé. Ça ne veut pas dire que c\'est fini — ça veut dire que tu es devenu quelqu\'un qui construit des habitudes. C\'est le vrai résultat.';
      case 'milestone_7_days':    return '7 jours consécutifs ! La science dit qu\'après ce seuil, 90 % de ceux qui continuent atteindront 21. Tu es dans la zone où le changement devient beaucoup plus probable.';
      case 'milestone_21_days':   return '21 jours ! L\'ancien mythe disait que 3 semaines suffisent pour former une habitude. La vérité : 21 jours ne construisent que le sillon initial. Maintenant commence la partie où elle devient vraiment tienne.';
      case 'milestone_66_days':   return '66 jours ! C\'est le chiffre magique de l\'étude de Phillippa Lally à l\'UCL. Officiellement, selon la science, tu as formé une habitude. Tu ne la construis pas — tu l\'as.';
      case 'streak_broken':       return 'Aucun problème. La règle est simple : ne jamais sauter deux jours de suite. Tu es déjà revenu aujourd\'hui — la série repart de maintenant. Welly ne compte pas les jours manqués.';
      case 'no_completion_3days': return 'Welly est toujours là. Sans jugement. Revenir est plus facile que tu ne le penses — même un seul verre d\'eau compte. Un acte minimal réactive la boucle.';
      case 'perfect_week':        return 'Semaine parfaite ! 7 complétions sur 7. Ton cerveau a reçu 7 signaux de renforcement consécutifs. D\'un point de vue neurologique, cette semaine a compté triple.';
      case 'rewards_first_visit': return 'Les badges ne sont pas de faux points. Chaque badge correspond à un comportement réel que tu as maintenu pendant une période mesurable. Ce sont des instantanés de tes progrès, pas des décorations.';
      default: return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':   return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first': return 'EFSA: apport quotidien en eau recommandé 2,0–2,5 L pour un adulte en conditions normales.';
      case 'first_completion':    return 'Hebb (1949): "neurons that fire together, wire together" — chaque répétition renforce la synapse.';
      case 'streak_explain':      return 'James Clear, Atomic Habits: "Never miss twice" est la règle la plus efficace pour maintenir une habitude.';
      case 'habit_card_explain':  return 'Phillippa Lally (UCL, 2010): l\'automaticité débute en moyenne entre 18 et 66 jours, avec la plus forte croissance dans les premières semaines.';
      case 'focus_unlocked':      return 'Kleitman (1963): cycles ultradiens de 90 min avec des pics d\'attention de 20–30 min. Les techniques Pomodoro exploitent ce rythme.';
      case 'calendar_appears':    return 'Sweller (1988): Cognitive Load Theory — moins d\'informations visibles simultanément = meilleures décisions.';
      case 'growth_first_visit':  return 'Wood & Neal (2007): l\'identité change lorsque les comportements deviennent automatiques. Identity precedes action.';
      case 'phase2_reached':      return 'Gardner (2012): automaticité = exécution sans intention consciente. Le premier automatisme est toujours le plus difficile.';
      case 'phase3_reached':      return 'Lally et al. (2010): avec 3 habitudes consolidées, la compliance à long terme augmente significativement par rapport à 1 seule.';
      case 'phase4_reached':      return 'Duhigg (2012): les routines consolidées nécessitent presque zéro délibération consciente — le cortex préfrontal délègue aux ganglions de la base.';
      case 'milestone_7_days':    return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: l\'automaticité croît le plus rapidement dans les premières semaines — la cohérence initiale est le meilleur prédicteur du maintien à long terme.';
      case 'milestone_21_days':   return 'Maltz (1960): les "21 jours" étaient une observation chirurgicale, pas une étude scientifique. Lally (2010) estime 66 jours en moyenne.';
      case 'milestone_66_days':   return 'Lally et al. (2010), UCL: moyenne de 66 jours (plage 18–254) pour atteindre l\'automaticité comportementale.';
      case 'no_completion_3days': return 'Fogg (2020): Tiny Habits — même une action minimale maintient vivant le loop neuronal de l\'habitude.';
      case 'perfect_week':        return 'Schultz et al. (1997): le système dopaminergique répond à la cohérence du renforcement — les séquences consécutives amplifient l\'effet.';
      default: return null;
    }
  }
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
  String get notifPermTitle => 'Noch eine Sache.';
  String get notifPermBody => 'Um dir zu helfen, konsequent zu bleiben, kann Welly dir eine sanfte Erinnerung schicken — nur einmal täglich. Kein Spam, kein Druck. Nur wenn es wirklich wichtig ist.';
  String get notifPermAllow => 'Ja, Benachrichtigungen aktivieren';
  String get notifPermSkip => 'Nicht jetzt';
  String get waterUndo => 'Letztes rückgängig';
  String get waterCooldown => 'Einen Moment warten…';
  String get waterContainerBtn => 'Behälter';

  String get goodMorning => 'Guten Morgen,';
  String get phase => 'Phase';
  String get waterToday => 'Wasser heute';
  String get waterGlasses => 'Gläser';
  String get waterTrackedInHome => '💧 in Home erfasst';
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
  String get lockedForNow => 'Noch gesperrt';

  String get yourJourney => 'Deine Reise';
  String get activeHabits => 'Aktive Gewohnheiten';
  String get nextUnlock => 'Demnächst';
  String get badges => 'Abzeichen';
  String get noBadgesYet => 'Deine Abzeichen erscheinen hier, wenn du Fortschritte machst.';
  String get todayCompleted => 'Heute abgeschlossen';
  String get phase1 => 'Samen'; String get phase2 => 'Keim';
  String get phase3 => 'Jung'; String get phase4 => 'Reif';
  // Wachstum
  String get growthWellyJourney => 'Wellys Reise';
  String get growthOurJourney => 'Unsere Reise';
  String get growthConsistency => 'Beständigkeit';
  String get growthMoments => 'Momente';
  String get growthNextMilestone => 'Nächster Meilenstein';
  String get milestone7days => 'Erste Woche am Stück';
  String get milestone14days => 'Zwei Wochen geschafft';
  String get milestone21days => 'Drei Wochen — die Wende';
  String get milestone42days => 'Sechs Wochen Wachstum';
  String get milestone66days => 'Gewohnheit gebildet';
  String get milestone100days => 'Hundert Tage';
  String get wellyStateCalm => 'Welly ist hier';
  String get wellyStateRadiant => 'Welly strahlt';
  String get wellyStateReturning => 'Willkommen zurück';
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
  String get focusDeepWork => 'Tiefe Arbeit';
  String get focusMinRemaining => 'Min verbleibend';
  String get focusBlockOf4 => 'von 4';

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
  String get notifWaterTitle => '💧 Be Well';
  String get notifWaterBody => 'Hast du heute genug Wasser getrunken?';
  String get notifEveningTitle => 'Be Well 🌱';
  String get notifEveningBody => 'Wie laufen deine Gewohnheiten heute?';
  String get notifHabitChoiceTitle => '✨ Neue Gewohnheit verfügbar';
  String get notifHabitChoiceBody => 'Öffne Be Well, um deine nächste Gewohnheit zu wählen.';

  String get navHome => 'Startseite';
  String get navHabits => 'Gewohnheiten';
  String get navFocus => 'Fokus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Belohnungen';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Freischalten in';
  String get navUnlockHabitsMsg => 'Schließe 3 Tage Wasser ab, um Gewohnheiten freizuschalten.';
  String get navUnlockGrowthMsg => 'Baue weiter Gewohnheiten auf, um das Wachstum freizuschalten.';
  String get comingSoonHabitsDesc => 'Schließe 3 aufeinanderfolgende Wassertage ab.\nDein Fokus-Timer wird freigeschaltet.';
  String get comingSoonGrowthDesc => 'Baue weiter deine Gewohnheiten auf.\nDer Wachstumsbildschirm wird bald freigeschaltet.';
  String get achievementUnlocked => 'Achievement freigeschaltet!';
  String get newHabitUnlocked => 'Neue Gewohnheit freigeschaltet!';

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
  String get habitMicroWalkName => 'Mikro-Spaziergang 5 Min'; String get habitMicroWalkDesc => '5 Minuten Gehen alle 90 Minuten — Ultradianischer Zyklus';
  String get habitDigitalSunsetName => 'Digitaler Sonnenuntergang'; String get habitDigitalSunsetDesc => 'Kein Social Media in der Stunde vor dem Schlafen';

  String get neverMissTwiceTitle => 'Nicht zwei Tage hintereinander auslassen.';
  String get neverMissTwiceBody => 'Eine kleine Aktion zählt. Sogar ein Glas Wasser.';
  String get neverMissTwiceCta => '💧 Ein Glas Wasser hinzufügen';
  String get wellyBonusTitle => 'Welly-Bonus!';
  String get wellyBonusBody => 'Dreifache Punkte diese Runde 🎉';

  String get coachDay1 => 'Erster Tag. Der wichtigste.';
  String get coachDay3 => '3 Tage. Dein Körper beginnt es zu registrieren.';
  String get coachDay7 => '7 Tage. Du baust etwas auf.';
  String get coachDay14 => '2 Wochen. Diese Gewohnheit gehört dir jetzt.';
  String get coachGeneral => 'Jeder Tag zählt. Auch die schwierigen.';

  String get badgeFirstStep => 'Erster Schritt'; String get badgeFirstStepDesc => 'Erster Tag abgeschlossen';
  String get badgeOneWeek => 'Eine Woche'; String get badgeOneWeekDesc => '7 Tage Gewohnheiten';
  String get badgeThreeWeeks => 'Drei Wochen'; String get badgeThreeWeeksDesc => '21 Tage abgeschlossen';
  String get badgeSixWeeks => 'Sechs Wochen'; String get badgeSixWeeksDesc => '42 Tage abgeschlossen';
  String get badgeThreeMonths => 'Drei Monate'; String get badgeThreeMonthsDesc => '90 Tage Wachstum';
  String get badgeInSync => 'Im Einklang'; String get badgeInSyncDesc => '2 aktive Gewohnheiten';
  String get badgeMultihabit => 'Multigewohnheit'; String get badgeMultihabitDesc => '4 aktive Gewohnheiten';
  String get badgeHydrated => 'Gut hydriert'; String get badgeHydratedDesc => 'Wasser gefestigt';
  String get badgeFocused => 'Im Fokus'; String get badgeFocusedDesc => 'Fokus 25 Min gefestigt';
  String get badgeWalker => 'Spaziergänger'; String get badgeWalkerDesc => 'Mittagsspaziergang gefestigt';
  String get badgeBreath => 'Atem'; String get badgeBreathDesc => 'Atmung gefestigt';

  String get habitChoiceTitle => 'Zeit für etwas Neues.';
  String get habitChoiceSub => 'Wähle, worauf du dich jetzt konzentrierst.';
  String get habitChoiceShowOther => 'andere Optionen zeigen ›';
  String get habitChoiceOpen => 'Nächste Gewohnheit wählen';
  String get habitEffortLow => 'leicht';
  String get habitEffortMedium => 'moderat';
  String get habitEffortHigh => 'anspruchsvoll';

  String get errorNetwork => 'Keine Internetverbindung';
  String get errorGeneral => 'Etwas ist schiefgelaufen. Versuche es erneut.';
  String get errorInvalidEmail => 'Ungültige E-Mail-Adresse';
  String get errorWeakPassword => 'Das Passwort ist zu schwach';
  String get errorEmailInUse => 'Diese E-Mail wird bereits verwendet';
  String get errorInvalidCredentials => 'Falsche E-Mail oder falsches Passwort';

  String get waterContainerGlass => 'Glas';
  String get waterContainerBottle => 'Flasche';
  String get waterContainerSettings => 'Wie verfolgst du dein Wasser?';
  String get waterGoalCalc => 'Du brauchst etwa N Behälter für deine 2 Liter am Tag';

  String get habitsMorningTitle => 'Starte gut in den Tag.';
  String get habitsMiddayTitle => 'Im richtigen Moment.';
  String get habitsAfternoonTitle => 'Guten Nachmittag.';
  String get habitsEveningTitle => 'Wie war dein Tag?';
  String get habitsNowLabel => 'Jetzt';
  String get habitsComingSoon => 'Demnächst';
  String get habitsAllDone => 'Alles gut für jetzt. Welly ist bei dir.';
  String get habitsToday => 'Heute';
  String get completedToday => 'heute erledigt';

  String get timeMorning => 'Morgen';
  String get timeMidday => 'Vormittag';
  String get timeLunch => 'Mittagspause';
  String get timeAfternoon => 'Nachmittag';
  String get timeEvening => 'Abend';

  String get onboardingUserTypeTitle => 'Und wie verbringst du deine Tage?';
  String get onboardingStudent => 'Studium';
  String get onboardingWorker => 'Arbeit';

  String get workScheduleBanner => 'Ich habe Standardzeiten eingestellt: 9-13 / 14-18. Stimmt das für dich?';
  String get workScheduleConfirm => 'Passt so';
  String get workScheduleEdit => 'Bearbeiten';
  String get workScheduleTitle => 'Deine Arbeitszeiten';
  String get workScheduleMorning => 'Morgen';
  String get workScheduleAfternoon => 'Nachmittag';
  String get workScheduleLunch => 'Ich habe eine feste Mittagspause';
  String get workScheduleSave => 'Speichern';

  String get slowdownPrompt => 'Ich habe bemerkt, dass du Schwierigkeiten hast, das Tempo zu halten. Sollen wir ein wenig langsamer werden?';
  String get slowdownYes => 'Ja, langsamer';
  String get slowdownNo => 'Nein, ich mache weiter';
  String get slowdownHabitMenu => 'Ich brauche mehr Zeit mit dieser';
  String get slowdownWellyResponse => 'Kein Problem — stärken wir diese, bevor wir etwas Neues hinzufügen. Das ist genau die richtige Entscheidung.';
  String get speedupPrompt => 'Du machst das sehr gut — bist du bereit für etwas Neues vor dem geplanten Zeitpunkt?';
  String get speedupYes => 'Ja, ich bin bereit';
  String get speedupNo => 'Nein, ich bleibe hier';

  String get calendarTitle => 'Dein Rhythmus heute';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pause';
  String get calendarLongBreak => 'Lange Pause';

  String get tutorialOk   => 'Verstanden!';
  String get tutorialMore => 'Mehr →';
  String get tutorialSkip => 'Überspringen';

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return '✅ ${habitName(hid)} ist jetzt in deinem Plan! ${habitDesc(hid)} Schließe sie täglich ab, um sie zu festigen.';
    }
    switch (id) {
      case 'home_first_open':     return 'Willkommen! Dies ist deine Basis. Oben findest du immer die dringendste Gewohnheit für den Moment. Fang dort an — der Rest kann warten.';
      case 'home_first_open_2':   return 'Wasser ist die erste Gewohnheit, weil es die biologische Grundlage für alles andere ist. Ohne Flüssigkeit sinkt die Konzentration nach nur 90 Minuten um bis zu 20 %.';
      case 'water_tracker_first': return 'Der Tracker zählt Gläser ab dem Öffnen der App jeden Morgen. 8 pro Tag ist das Ziel — aber schon 5 zu erreichen ist besser als gestern.';
      case 'first_completion':    return 'Geschafft! Jeder Abschluss schafft eine neue neuronale Verbindung. Klein, aber real. Dein Gehirn hat gerade eine Schaltung gestärkt.';
      case 'streak_explain':      return 'Wenn du morgen zurückkommst, beginnt deine Serie. Die einzige Regel: nie zwei Tage hintereinander auslassen. Eine Pause ist menschlich. Zwei sind eine neue Gewohnheit — die falsche.';
      case 'habits_tab_first':    return 'Hier findest du alle Gewohnheiten nach dem besten Moment deines Tages sortiert. Welly kennt deine Rhythmen — Morgengewohnheiten erscheinen morgens, Abendgewohnheiten abends.';
      case 'habit_card_explain':  return 'Der kreisförmige Bogen füllt sich bei jedem Abschluss. Nach 7 Tagen passiert etwas Interessantes — dein Gehirn beginnt, es als Routine zu registrieren.';
      case 'focus_unlocked':      return 'Du hast den 25-Minuten-Fokus freigeschaltet! Das menschliche Gehirn hat einen natürlichen Konzentrationsrhythmus von etwa 20–30 Minuten. Du hast diese Fähigkeit durch die Wassergewohnheit erworben.';
      case 'focus_unlocked_2':    return 'Goldene Regel des Fokus: Wenn der Timer läuft, kommt das Handy mit dem Display nach unten. Sogar Welly schweigt. Die Benachrichtigung, auf die du wartest, kann 25 Minuten warten — versprochen.';
      case 'calendar_appears':    return 'Neu! Der kontextuelle Kalender zeigt nur die nächsten Stunden, nicht den ganzen Tag. Weniger zu sehen = mehr mentaler Raum zum Handeln. Die ferne Zukunft ist noch nicht dein Problem.';
      case 'growth_first_visit':  return 'Dieser Bereich zeigt, wer du wirst, nicht nur was du tust. Die Phasen sind keine Belohnungen — sie sind echte Beschreibungen deiner neurologischen Veränderung. Wissenschaft, nicht Motivation, leitet den Weg.';
      case 'phase2_reached':      return '🌱 Phase 2: Anfang! Deine erste Gewohnheit ist automatisch geworden — dein Gehirn muss nicht mehr bewusst entscheiden, sie zu tun. Ein neues Gewohnheitspaar wartet auf deine Wahl. Nimm das, das sich richtig anfühlt.';
      case 'phase3_reached':      return '🌿 Phase 3: Wachstum! Drei Gewohnheiten gefestigt. Deine Routine existiert wirklich jetzt — sie ist keine Anstrengung mehr, sie ist eine Struktur. Das Schwerste liegt hinter dir.';
      case 'phase4_reached':      return '🌳 Phase 4: Wurzeln. Sieben Gewohnheiten verinnerlicht — deine Routine ist zum Lebensstil geworden. Die meisten Menschen kommen nicht hierher. Du hast es durch Beständigkeit erreicht, nicht durch Willenskraft.';
      case 'phase5_reached':      return '🌸 Aufblühen. Du bist angekommen. Das bedeutet nicht, dass es vorbei ist — es bedeutet, dass du jemand geworden bist, der Gewohnheiten aufbaut. Das ist das wahre Ergebnis.';
      case 'milestone_7_days':    return '7 aufeinanderfolgende Tage! Die Wissenschaft sagt, dass nach dieser Schwelle 90 % derer, die weitermachen, 21 Tage erreichen werden. Du bist in der Zone, in der Veränderung viel wahrscheinlicher wird.';
      case 'milestone_21_days':   return '21 Tage! Der alte Mythos besagte, dass 3 Wochen ausreichen, um eine Gewohnheit zu bilden. Die Wahrheit: 21 Tage bilden nur die erste Rille. Jetzt beginnt der Teil, wo sie wirklich deine wird.';
      case 'milestone_66_days':   return '66 Tage! Das ist die magische Zahl aus der UCL-Studie von Phillippa Lally. Offiziell, laut Wissenschaft, hast du eine Gewohnheit gebildet. Du baust sie nicht — du hast sie.';
      case 'streak_broken':       return 'Kein Problem. Die Regel ist einfach: nie zwei Tage hintereinander auslassen. Du bist heute schon zurück — die Serie beginnt von jetzt an. Welly zählt die verpassten Tage nicht.';
      case 'no_completion_3days': return 'Welly ist noch hier. Kein Urteil. Zurückzukehren ist einfacher als du denkst — sogar ein einziges Glas Wasser zählt. Ein minimaler Akt reaktiviert die Schleife.';
      case 'perfect_week':        return 'Perfekte Woche! 7 von 7 Abschlüssen. Dein Gehirn empfing 7 aufeinanderfolgende Verstärkungssignale. Aus neurologischer Sicht hat diese Woche dreifach gezählt.';
      case 'rewards_first_visit': return 'Abzeichen sind keine falschen Punkte. Jedes Abzeichen entspricht einem echten Verhalten, das du über einen messbaren Zeitraum aufrechterhalten hast. Es sind Momentaufnahmen deines Fortschritts, keine Dekorationen.';
      default: return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':   return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first': return 'EFSA: täglicher Wasserbedarf 2,0–2,5 L für Erwachsene unter normalen Bedingungen.';
      case 'first_completion':    return 'Hebb (1949): "neurons that fire together, wire together" — jede Wiederholung stärkt die Synapse.';
      case 'streak_explain':      return 'James Clear, Atomic Habits: "Never miss twice" ist die wirksamste Regel zur Aufrechterhaltung einer Gewohnheit.';
      case 'habit_card_explain':  return 'Phillippa Lally (UCL, 2010): Automatizität beginnt im Durchschnitt zwischen 18 und 66 Tagen, mit dem stärksten Wachstum in den ersten Wochen.';
      case 'focus_unlocked':      return 'Kleitman (1963): ultradianer Rhythmus von 90 min mit Aufmerksamkeitsspitzen von 20–30 min. Pomodoro-Techniken nutzen diesen Rhythmus.';
      case 'calendar_appears':    return 'Sweller (1988): Cognitive Load Theory — weniger gleichzeitig sichtbare Informationen = bessere Entscheidungen.';
      case 'growth_first_visit':  return 'Wood & Neal (2007): Identität verändert sich, wenn Verhaltensweisen automatisch werden. Identity precedes action.';
      case 'phase2_reached':      return 'Gardner (2012): Automatizität = Ausführung ohne bewusste Absicht. Der erste Automatismus ist immer der schwierigste.';
      case 'phase3_reached':      return 'Lally et al. (2010): Mit 3 gefestigten Gewohnheiten steigt die langfristige Compliance deutlich gegenüber nur 1.';
      case 'phase4_reached':      return 'Duhigg (2012): Konsolidierte Routinen erfordern fast null bewusste Überlegung — der präfrontale Kortex delegiert an die Basalganglien.';
      case 'milestone_7_days':    return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: Die Automatizität nimmt in den ersten Wochen am stärksten zu — frühe Konsequenz ist der stärkste Prädiktor für langfristige Beibehaltung.';
      case 'milestone_21_days':   return 'Maltz (1960): Die "21 Tage" waren eine chirurgische Beobachtung, keine wissenschaftliche Studie. Lally (2010) schätzt im Durchschnitt 66 Tage.';
      case 'milestone_66_days':   return 'Lally et al. (2010), UCL: Durchschnitt von 66 Tagen (Bereich 18–254), um Verhaltensautomatizität zu erreichen.';
      case 'no_completion_3days': return 'Fogg (2020): Tiny Habits — selbst eine minimale Handlung hält die neuronale Schleife der Gewohnheit am Leben.';
      case 'perfect_week':        return 'Schultz et al. (1997): Das dopaminerge System reagiert auf die Konsistenz der Verstärkung — aufeinanderfolgende Sequenzen verstärken den Effekt.';
      default: return null;
    }
  }
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
  String get notifPermTitle => 'Una última cosa.';
  String get notifPermBody => 'Para ayudarte a ser constante, Welly puede enviarte un recordatorio suave — solo una vez al día. Sin spam, sin presión. Solo cuando realmente importa.';
  String get notifPermAllow => 'Sí, activar notificaciones';
  String get notifPermSkip => 'Ahora no';
  String get waterUndo => 'Deshacer último';
  String get waterCooldown => 'Espera un momento…';
  String get waterContainerBtn => 'Recipiente';

  String get goodMorning => 'Buenos días,';
  String get phase => 'Fase';
  String get waterToday => 'Agua hoy';
  String get waterGlasses => 'vasos';
  String get waterTrackedInHome => '💧 registrado en Inicio';
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
  String get lockedForNow => 'Bloqueada por ahora';

  String get yourJourney => 'Tu camino';
  String get activeHabits => 'Hábitos activos';
  String get nextUnlock => 'Próximamente';
  String get badges => 'Insignias';
  String get noBadgesYet => 'Tus insignias aparecerán aquí a medida que progreses.';
  String get todayCompleted => 'Completado hoy';
  String get phase1 => 'Semilla'; String get phase2 => 'Brote';
  String get phase3 => 'Joven'; String get phase4 => 'Maduro';
  // Crecimiento
  String get growthWellyJourney => 'El camino de Welly';
  String get growthOurJourney => 'Nuestro camino';
  String get growthConsistency => 'Consistencia';
  String get growthMoments => 'Momentos';
  String get growthNextMilestone => 'Próximo hito';
  String get milestone7days => 'Primera semana seguida';
  String get milestone14days => 'Dos semanas completadas';
  String get milestone21days => 'Tres semanas — el punto de inflexión';
  String get milestone42days => 'Seis semanas de crecimiento';
  String get milestone66days => 'Hábito formado';
  String get milestone100days => 'Cien días';
  String get wellyStateCalm => 'Welly está contigo';
  String get wellyStateRadiant => 'Welly está radiante';
  String get wellyStateReturning => 'Bienvenido de vuelta';
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
  String get focusDeepWork => 'Trabajo profundo';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'de 4';

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
  String get notifWaterTitle => '💧 Be Well';
  String get notifWaterBody => '¿Has bebido suficiente agua hoy?';
  String get notifEveningTitle => 'Be Well 🌱';
  String get notifEveningBody => '¿Cómo van tus hábitos hoy?';
  String get notifHabitChoiceTitle => '✨ Nuevo hábito disponible';
  String get notifHabitChoiceBody => 'Abre Be Well para elegir tu próximo hábito.';

  String get navHome => 'Inicio';
  String get navHabits => 'Hábitos';
  String get navFocus => 'Enfoque';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Recompensas';
  String get navProfile => 'Perfil';
  String get navUnlockIn => 'Se desbloquea en';
  String get navUnlockHabitsMsg => 'Completa 3 días de agua para desbloquear los hábitos.';
  String get navUnlockGrowthMsg => 'Sigue construyendo hábitos para desbloquear el crecimiento.';
  String get comingSoonHabitsDesc => 'Completa 3 días consecutivos de agua.\nTu temporizador de enfoque se desbloqueará.';
  String get comingSoonGrowthDesc => 'Sigue construyendo tus hábitos.\nLa pantalla de crecimiento se desbloqueará pronto.';
  String get achievementUnlocked => '¡Logro desbloqueado!';
  String get newHabitUnlocked => '¡Nuevo hábito desbloqueado!';

  String get rewards => 'Recompensas';
  String get rewardsPoints => 'Puntos Be Well';
  String get rewardsLocked => 'Las recompensas están llegando';
  String get rewardsLockedDesc => 'Sigue construyendo hábitos para desbloquear tus recompensas';
  String get rewardsHeader => 'Tus recompensas';
  String get rewardsHeaderSub => 'Recoge lo que has sembrado';

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
  String get habitMicroWalkName => 'Micro-caminata 5 min'; String get habitMicroWalkDesc => '5 minutos caminando cada 90 minutos — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Atardecer digital'; String get habitDigitalSunsetDesc => 'Sin redes sociales en la hora antes de dormir';

  String get neverMissTwiceTitle => 'No faltes dos días seguidos.';
  String get neverMissTwiceBody => 'Una sola acción cuenta. Incluso un vaso de agua.';
  String get neverMissTwiceCta => '💧 Añadir un vaso de agua';
  String get wellyBonusTitle => '¡Bonus Welly!';
  String get wellyBonusBody => 'Puntos triplicados esta vez 🎉';

  String get coachDay1 => 'Primer día. El más importante.';
  String get coachDay3 => '3 días. Tu cuerpo empieza a registrarlo.';
  String get coachDay7 => '7 días. Estás construyendo algo.';
  String get coachDay14 => '2 semanas. Este hábito es tuyo ahora.';
  String get coachGeneral => 'Cada día cuenta. Incluso los días difíciles.';

  String get badgeFirstStep => 'Primer paso'; String get badgeFirstStepDesc => 'Primer día completado';
  String get badgeOneWeek => 'Una semana'; String get badgeOneWeekDesc => '7 días de hábitos';
  String get badgeThreeWeeks => 'Tres semanas'; String get badgeThreeWeeksDesc => '21 días completados';
  String get badgeSixWeeks => 'Seis semanas'; String get badgeSixWeeksDesc => '42 días completados';
  String get badgeThreeMonths => 'Tres meses'; String get badgeThreeMonthsDesc => '90 días de crecimiento';
  String get badgeInSync => 'En sincronía'; String get badgeInSyncDesc => '2 hábitos activos';
  String get badgeMultihabit => 'Multihábito'; String get badgeMultihabitDesc => '4 hábitos activos';
  String get badgeHydrated => 'Bien hidratado'; String get badgeHydratedDesc => 'Agua consolidada';
  String get badgeFocused => 'En foco'; String get badgeFocusedDesc => 'Focus 25 min consolidado';
  String get badgeWalker => 'Caminante'; String get badgeWalkerDesc => 'Caminata almuerzo consolidada';
  String get badgeBreath => 'Respiración'; String get badgeBreathDesc => 'Respiración consolidada';

  String get habitChoiceTitle => 'Es hora de agregar\nalgo nuevo.';
  String get habitChoiceSub => 'Elige dónde centrarte ahora.';
  String get habitChoiceShowOther => 'mostrarme otras opciones ›';
  String get habitChoiceOpen => 'Elige tu próximo hábito';
  String get habitEffortLow => 'fácil';
  String get habitEffortMedium => 'moderado';
  String get habitEffortHigh => 'desafiante';

  String get errorNetwork => 'Sin conexión a internet';
  String get errorGeneral => 'Algo salió mal. Inténtalo de nuevo.';
  String get errorInvalidEmail => 'Dirección de correo no válida';
  String get errorWeakPassword => 'La contraseña es demasiado débil';
  String get errorEmailInUse => 'Este correo ya está en uso';
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos';

  String get waterContainerGlass => 'vaso';
  String get waterContainerBottle => 'botella';
  String get waterContainerSettings => '¿Cómo estás registrando tu agua?';
  String get waterGoalCalc => 'Necesitas unos N recipientes para tus 2 litros al día';

  String get habitsMorningTitle => 'Empieza bien el día.';
  String get habitsMiddayTitle => 'En el momento justo.';
  String get habitsAfternoonTitle => 'Buenas tardes.';
  String get habitsEveningTitle => '¿Cómo te fue hoy?';
  String get habitsNowLabel => 'Ahora';
  String get habitsComingSoon => 'Próximamente';
  String get habitsAllDone => 'Todo bien por ahora. Welly está contigo.';
  String get habitsToday => 'Hoy';
  String get completedToday => 'completadas hoy';

  String get timeMorning => 'Mañana';
  String get timeMidday => 'Media mañana';
  String get timeLunch => 'Pausa del almuerzo';
  String get timeAfternoon => 'Tarde';
  String get timeEvening => 'Noche';

  String get onboardingUserTypeTitle => '¿Y cómo pasas tus días?';
  String get onboardingStudent => 'Estudio';
  String get onboardingWorker => 'Trabajo';

  String get workScheduleBanner => 'He configurado el horario estándar: 9-13 / 14-18. ¿Es el correcto para ti?';
  String get workScheduleConfirm => 'Está bien';
  String get workScheduleEdit => 'Editar';
  String get workScheduleTitle => 'Tus horarios de trabajo';
  String get workScheduleMorning => 'Mañana';
  String get workScheduleAfternoon => 'Tarde';
  String get workScheduleLunch => 'Tengo una pausa para el almuerzo fija';
  String get workScheduleSave => 'Guardar';

  String get slowdownPrompt => 'He notado que te está costando mantener el ritmo. ¿Quieres que vayamos más despacio?';
  String get slowdownYes => 'Sí, vamos más despacio';
  String get slowdownNo => 'No, sigo adelante';
  String get slowdownHabitMenu => 'Necesito más tiempo con este hábito';
  String get slowdownWellyResponse => 'Sin problema — reforcemos este antes de añadir algo nuevo. Es exactamente la decisión correcta.';
  String get speedupPrompt => 'Lo estás haciendo muy bien — ¿estás listo para algo nuevo antes de lo previsto?';
  String get speedupYes => 'Sí, estoy listo';
  String get speedupNo => 'No, me quedo aquí';

  String get calendarTitle => 'Tu ritmo hoy';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pausa';
  String get calendarLongBreak => 'Pausa larga';

  String get tutorialOk   => '¡Entendido!';
  String get tutorialMore => 'Más →';
  String get tutorialSkip => 'Saltar';

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return '✅ ${habitName(hid)} está ahora en tu plan. ${habitDesc(hid)} Complétalo cada día para consolidarlo.';
    }
    switch (id) {
      case 'home_first_open':     return '¡Bienvenido! Esta es tu base. En la parte superior siempre encontrarás el hábito más urgente para ahora. Empieza siempre por ahí — el resto puede esperar.';
      case 'home_first_open_2':   return 'El agua es el primer hábito porque es la base biológica de todo lo demás. Sin hidratación, la concentración cae hasta un 20 % después de solo 90 minutos.';
      case 'water_tracker_first': return 'El tracker cuenta los vasos desde que abres la app cada mañana. 8 al día es el objetivo — pero llegar a 5 ya es mejor que ayer.';
      case 'first_completion':    return '¡Hecho! Cada completación crea una nueva conexión neuronal. Pequeña, pero real. Tu cerebro acaba de reforzar un circuito.';
      case 'streak_explain':      return 'Si vuelves mañana, empieza tu racha. La única regla que importa: nunca saltes dos días seguidos. Una pausa es humana. Dos es un nuevo hábito — el equivocado.';
      case 'habits_tab_first':    return 'Aquí encuentras todos tus hábitos ordenados para el mejor momento de tu día. Welly conoce tus ritmos — los hábitos matutinos aparecen por la mañana, los nocturnos por la noche.';
      case 'habit_card_explain':  return 'El arco circular se llena cada vez que completas. A los 7 días ocurre algo interesante — tu cerebro empieza a registrarlo como rutina.';
      case 'focus_unlocked':      return '¡Has desbloqueado el Foco de 25 minutos! El cerebro humano tiene un ciclo natural de concentración de unos 20–30 minutos. Has ganado esta habilidad construyendo el hábito del agua.';
      case 'focus_unlocked_2':    return 'Regla de oro del Foco: cuando arranca el temporizador, el teléfono va boca abajo. Incluso Welly se calla. La notificación que esperas puede esperar 25 minutos — te lo prometo.';
      case 'calendar_appears':    return '¡Nuevo! El calendario contextual muestra solo las próximas horas, no todo el día. Menos que ver = más espacio mental para actuar. El futuro lejano aún no es tu problema.';
      case 'growth_first_visit':  return 'Esta sección muestra en quién te estás convirtiendo, no solo lo que estás haciendo. Las fases no son premios — son descripciones reales de tu cambio neurológico. La ciencia, no la motivación, guía el camino.';
      case 'phase2_reached':      return '🌱 Fase 2: ¡Inicio! Tu primer hábito se ha vuelto automático — tu cerebro ya no necesita "decidir" hacerlo. Un nuevo par de hábitos te espera. Elige el que mejor encaje contigo.';
      case 'phase3_reached':      return '🌿 Fase 3: ¡Crecimiento! Tres hábitos consolidados. Tu rutina existe de verdad ahora — ya no es un esfuerzo, es una estructura. Lo más difícil quedó atrás.';
      case 'phase4_reached':      return '🌳 Fase 4: Raíces. Siete hábitos asimilados — tu rutina se ha convertido en estilo de vida. La mayoría de las personas no llegan aquí. Lo has logrado con constancia, no con fuerza de voluntad.';
      case 'phase5_reached':      return '🌸 Florecimiento. Has llegado. No significa que termina — significa que te has convertido en alguien que construye hábitos. Ese es el verdadero resultado.';
      case 'milestone_7_days':    return '¡7 días consecutivos! La ciencia dice que tras este umbral, el 90 % de los que continúan llegarán a 21. Estás en la zona donde el cambio se vuelve mucho más probable.';
      case 'milestone_21_days':   return '¡21 días! El viejo mito decía que 3 semanas bastan para formar un hábito. La verdad: 21 días solo construyen el surco inicial. Ahora empieza la parte donde se vuelve verdaderamente tuyo.';
      case 'milestone_66_days':   return '¡66 días! Este es el número mágico del estudio de Phillippa Lally en la UCL. Oficialmente, según la ciencia, has formado un hábito. No lo estás construyendo — lo tienes.';
      case 'streak_broken':       return 'Ningún problema. La regla es simple: nunca saltes dos días seguidos. Ya has vuelto hoy — la racha empieza de nuevo desde ahora. Welly no cuenta los días que faltaste.';
      case 'no_completion_3days': return 'Welly sigue aquí. Sin juicios. Volver es más fácil de lo que crees — incluso un solo vaso de agua cuenta. Un acto mínimo reactiva el bucle.';
      case 'perfect_week':        return '¡Semana perfecta! 7 de 7 completaciones. Tu cerebro recibió 7 señales de refuerzo consecutivas. Desde el punto de vista neurológico, esta semana contó el triple.';
      case 'rewards_first_visit': return 'Las insignias no son puntos falsos. Cada insignia corresponde a un comportamiento real que has mantenido durante un período medible. Son instantáneas de tu progreso, no decoraciones.';
      default: return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':   return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first': return 'EFSA: necesidad diaria de agua 2,0–2,5 L para adultos en condiciones normales.';
      case 'first_completion':    return 'Hebb (1949): "neurons that fire together, wire together" — cada repetición refuerza la sinapsis.';
      case 'streak_explain':      return 'James Clear, Atomic Habits: "Never miss twice" es la regla más eficaz para mantener un hábito.';
      case 'habit_card_explain':  return 'Phillippa Lally (UCL, 2010): la automaticidad comienza en promedio entre los 18 y los 66 días, con el mayor crecimiento en las primeras semanas.';
      case 'focus_unlocked':      return 'Kleitman (1963): ciclos ultradianos de 90 min con picos de atención de 20–30 min. Las técnicas Pomodoro aprovechan este ritmo.';
      case 'calendar_appears':    return 'Sweller (1988): Cognitive Load Theory — menos información visible simultáneamente = mejores decisiones.';
      case 'growth_first_visit':  return 'Wood & Neal (2007): la identidad cambia cuando los comportamientos se vuelven automáticos. Identity precedes action.';
      case 'phase2_reached':      return 'Gardner (2012): automaticidad = ejecución sin intención consciente. El primer automatismo es siempre el más difícil.';
      case 'phase3_reached':      return 'Lally et al. (2010): con 3 hábitos consolidados, el cumplimiento a largo plazo aumenta significativamente respecto a solo 1.';
      case 'phase4_reached':      return 'Duhigg (2012): las rutinas consolidadas requieren casi cero deliberación consciente — la corteza prefrontal delega a los ganglios basales.';
      case 'milestone_7_days':    return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: la automaticidad crece más rápidamente en las primeras semanas — la consistencia inicial es el predictor más fuerte del mantenimiento a largo plazo.';
      case 'milestone_21_days':   return 'Maltz (1960): los "21 días" eran una observación quirúrgica, no un estudio científico. Lally (2010) estima 66 días en promedio.';
      case 'milestone_66_days':   return 'Lally et al. (2010), UCL: promedio de 66 días (rango 18–254) para alcanzar la automaticidad conductual.';
      case 'no_completion_3days': return 'Fogg (2020): Tiny Habits — incluso una acción mínima mantiene vivo el bucle neuronal del hábito.';
      case 'perfect_week':        return 'Schultz et al. (1997): el sistema dopaminérgico responde a la consistencia del refuerzo — las secuencias consecutivas amplían el efecto.';
      default: return null;
    }
  }
}

// ── Extension utility per nomi e descrizioni abitudini ───────────────────────
extension BwStringsHabitUtils on BwStrings {
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
      default:                  return coachGeneral;
    }
  }
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


