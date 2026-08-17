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
    rescheduleBwReminders();
  }

  // Shortcut per ottenere le stringhe
  BwStrings get s => BwStrings.of(_locale);
}

/// Legge la lingua correntemente selezionata direttamente da
/// SharedPreferences e restituisce le stringhe corrispondenti — per il
/// codice che non ha un BuildContext a disposizione (provider, servizi
/// in background) e non può usare `context.sL`.
Future<BwStrings> currentBwStrings() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('app_locale') ?? 'en';
  final locale = BwLocale.values.firstWhere(
    (l) => l.code == code,
    orElse: () => BwLocale.en,
  );
  return BwStrings.of(locale);
}

/// Ripianifica i reminder periodici leggendo lingua, frequenza e pausa
/// direttamente da SharedPreferences — così sia [LocaleProvider] (cambio
/// lingua) sia [SettingsProvider] (cambio frequenza/pausa) possono
/// richiamarla senza doversi conoscere a vicenda.
Future<void> rescheduleBwReminders() async {
  final prefs = await SharedPreferences.getInstance();
  final s = await currentBwStrings();

  final snoozeMs = prefs.getInt('notif_snooze_until');
  if (snoozeMs != null && DateTime.now().millisecondsSinceEpoch < snoozeMs) {
    await NotificationService.instance.cancelReminders();
    return;
  }

  final freqStr = prefs.getString('notif_frequency') ?? 'normal';
  final hours = switch (freqStr) {
    'off'  => const <int>[],
    'low'  => const [10, 20],
    'high' => const [9, 11, 13, 15, 17, 19, 21],
    _      => const [10, 14, 17, 20],
  };

  await NotificationService.instance.scheduleReminders(
    hours: hours,
    waterTitle: s.notifWaterTitle,
    waterBody: s.notifWaterBody,
    habitTitle: s.notifHabitTitle,
    habitBody: s.notifHabitBody,
    eveningTitle: s.notifEveningTitle,
    eveningBody: s.notifEveningBody,
  );
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
  String get registerSubtitle;
  String get tosAccept;
  String get tosTerms;
  String get tosAnd;
  String get tosPrivacy;
  String get tosSuffix;
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
  String get greetingFallbackName;
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
  String get notifHabitTitle;
  String get notifHabitBody;
  String get notifHabitChoiceTitle;
  String get notifHabitChoiceBody;

  // ── Impostazioni notifiche ────────────────────────────────────────────────
  String get notifFrequencyLabel;
  String get notifFreqOff;
  String get notifFreqLow;
  String get notifFreqNormal;
  String get notifFreqHigh;
  String get notifFreqOffDesc;
  String get notifFreqLowDesc;
  String get notifFreqNormalDesc;
  String get notifFreqHighDesc;
  String get notifSnoozeLabel;
  String notifSnoozeActive(String until);
  String get notifSnoozeCancel;
  String notifSnoozeHours(int h);

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

  // ── Breathing session ────────────────────────────────────────────────────
  String get breathingInhale;
  String get breathingHold;
  String get breathingExhale;
  String get breathingCycles;
  String get breathingTapToStart;
  String get breathingStart;
  String get breathingStop;
  String get breathingAgain;
  String get breathingWellDone;
  String breathingCyclesCompleted(int n);
  String breathingPointsEarned(int pts);

  // ── Guided step sequence (es. esercizi alla scrivania) ──────────────────
  String get guideTapToStart;
  String get guideStart;
  String get guideWellDone;
  String guideStepProgress(int i, int total);
  String guideStepsCompleted(int n);
  // desk_exercise
  String get guideDeskStep1; String get guideDeskStep2; String get guideDeskStep3;
  String get guideDeskStep4; String get guideDeskStep5;
  // neck_stretch
  String get guideNeckStep1; String get guideNeckStep2; String get guideNeckStep3;
  // stretching_active
  String get guideStretchStep1; String get guideStretchStep2; String get guideStretchStep3;
  String get guideStretchStep4; String get guideStretchStep5;

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
  String get badgeRootedName; String get badgeRootedDesc;
  String get badgeTierBronze; String get badgeTierSilver; String get badgeTierGold;
  String get growthNextGoal;
  String growthHabitsToRoot(int n);

  // ── Habit intro sheet ────────────────────────────────────────────────────
  String get habitChoiceTitle;
  String get habitChoiceSub;
  String get habitChoiceShowOther;
  String get habitChoiceNotReady;
  String get habitChoiceOpen;
  String get habitNotReadySnoozed;
  String get consolidatedTitle;
  String consolidatedBody(String habitName);
  String get consolidatedBadge;
  String get consolidatedCta;
  String habitStartsTomorrow(String habitName);
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
  String get errorTooManyAttempts;
  String get errorTimeout;
  String get errorCancelled;
  String get errorAccountDisabled;
  String get passwordStrengthWeak;
  String get passwordStrengthMedium;
  String get passwordStrengthStrong;
  String get passwordStrengthVeryStrong;
  String get validationEmailRequired;
  String get validationPasswordRequired;
  String get validationPasswordTooShort;
  String get validationNameRequired;
  String get validationNameTooShort;
  String get accountLockedBody;
  String get accountLockedEmailSent;
  String get offlineLoginRequired;
  String get forgotCheckEmailTitle;
  String forgotEmailSentBody(String email);
  String get forgotLinkExpiry;
  String get forgotResendLimitReached;
  String forgotResendIn(int seconds);
  String get verifyEmailCta;
  String get verifyResendCta;
  String get verifyChecked;
  String get verifyDifferentEmail;
  String get verifySendError;

  // ── Welcome carousel ─────────────────────────────────────────────────────
  String get welcomeSlide1Title;
  String get welcomeSlide1Sub;
  String get welcomeSlide2Title;
  String get welcomeSlide2Sub;
  String get welcomeSlide3Title;
  String get welcomeSlide3Sub;
  String get welcomeSkip;
  String get welcomeNext;
  String get welcomeStart;
  String get welcomeConfigureLater;

  // ── Questionario onboarding ──────────────────────────────────────────────
  String get qProfileTitle;
  String get qProfileSub;
  String get qGoalsTitle;
  String get qGoalsSub;
  String get qHealthTitle;
  String get qHealthSub;
  String get qScheduleTitle;
  String get qScheduleSub;
  String get qEnvTitle;
  String get qEnvSub;
  String get qBuildPlan;
  String get q1Label;
  String get q2Label;
  String get q3Label;
  String get q4Label;
  String get q23Label;
  String get q15Label;
  String get q16Label;
  String get q17Label;
  String get q18Label;
  String get q5Label;
  String get q6Label;
  String get q7Label;
  String get q8Label;
  String get q9q10Label;
  String get q11q14Label;
  String get q19Label;
  String get q20Label;
  String get q21Label;
  String get q22Label;
  String get q1Student;
  String get q1Employee;
  String get q1Freelancer;
  String get q1Other;
  String get q1Both;
  String get q2Home;
  String get q2Office;
  String get q2Hybrid;
  String get q2Varies;
  String get goalStress;
  String get goalFocus;
  String get goalHealth;
  String get goalSleep;
  String get goalEnergy;
  String get goalWeight;
  String get stress1;
  String get stress2;
  String get stress3;
  String get stress4;
  String get stress5;
  String get stressCalmEnd;
  String get stressStressedEnd;
  String get priorNone;
  String get priorHeadspace;
  String get priorCalm;
  String get priorMultiple;
  String get priorOther;
  String get hydroLow;
  String get hydroGreat;
  String get exNever;
  String get ex12x;
  String get ex34x;
  String get exDaily;
  String get schedFixed;
  String get schedFlexible;
  String get schedShift;
  String get schedIrregular;
  String get calNoneLabel;
  String get calSyncNote;
  String get remMinimal;
  String get remMinimalSub;
  String get remModerate;
  String get remModerateSub;
  String get remFrequent;
  String get remFrequentSub;
  String get remVeryFrequent;
  String get remVeryFrequentSub;
  String get lunchTimeLabel;
  String get lunchDurationLabel;
  String get resParkLabel;
  String get resParkSub;
  String get resGymLabel;
  String get resGymSub;
  String get resWindowLabel;
  String get resWindowSub;
  String get resQuietLabel;
  String get resQuietSub;
  String get distLow;
  String get distMedium;
  String get distHigh;
  String get distVeryHigh;
  String get focusMorning;
  String get focusMidday;
  String get focusAfternoon;
  String get focusEvening;
  String get meeting02;
  String get meeting24;
  String get meeting46;
  String get meeting6plus;
  String get screenTimeWarning;
  String get crisisTitle;
  String get crisisBody;
  String get qOptional;
  String get qBack;
  String get qSkipAll;
  String qOfTotal(int current, int total);
  String get planGenTitle;
  String get planGenSub;
  String get planStep1;
  String get planStep2;
  String get planStep3;
  String get planStep4;
  String get planReadyBadge;
  String get planPreviewTitle;
  String get planPreviewSub;
  String get planRemindersPerDay;
  String get planFocusSessions;
  String get planPointsPerDay;
  String get planMorning;
  String get planAfternoon;
  String get planEvening;
  String planFromTime(String time);
  String planConnectCalendar(String name);
  String get planConnectCalendarSub;
  String get planFallbackNote;
  String get planConfirmCta;
  String get planConfirmSub;
  String planMinutes(int n);

  // ── Profile screen ───────────────────────────────────────────────────────
  String get profileTitle;
  String get accountSection;
  String get emailAccountLabel;
  String get supportSection;
  String get editNameTitle;
  String get yourNameHint;
  String get resetTutorialTitle;
  String get resetTutorialBody;
  String get resetTutorialCta;
  String get resetTutorialSnackbar;
  String genericError(String msg);
  String get settingsTitle;
  String get styleCardDesc;
  String get styleAmbientDesc;
  String get toneSection;
  String get accessibilitySection;
  String get contrastDesc;
  String get textSizeDesc;
  String get remindersLabel;
  String get remindersDesc;
  String get comingSoonTitle;
  String get comingSoonBody;
  String get habitMarkDone;
  String get slowdownReasonHeavy;
  String heatmapDaysAgo(int n);
  String get heatmapToday;
  String phaseStarted(String date);
  String phaseReached(String date);
  String get marketAdTitle;
  String get marketAdSubtitle;
  String get marketAdDialogBody;
  String get marketWatchNow;
  String get dialogGotIt;
  String get marketAdUnavailable;
  String get referralTitle;
  String get referralSubtitle;
  String get referralApply;
  String get referralApplied;
  String get referralErrorInvalid;
  String get referralErrorOwn;
  String get referralErrorAlready;
  String get referralErrorNotSignedIn;
  String get referralErrorGeneric;
  String get referralHint;
  String premiumPrice(String price);
  String referralShareButton(String code);
  String get referralRetry;
  String referralShareMessage(String code);

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
  String get configuratorTitle;
  String get configuratorSubtitle;
  String get configuratorDoneTitle;
  String get configuratorDoneSubtitle;
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
  String get slowdownMenuSubtitle;
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
  String get tutorialNext;
  String tutorialText(String id);
  String? tutorialFact(String id);

  // ── Spotlight tutorial (coach-mark stile videogame) ───────────────────────
  String spotlightText(String id);

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable;
  String get marketplaceTabRewards;
  String get marketplaceTabDiscounts;
  String get marketplaceTabInApp;
  String get rewardsToRedeem;
  String get rewardRedeemed;
  String get rewardConfirmTitle;
  String get rewardConfirmBody;
  String get rewardRedeemFailed;
  String get copyCode;
  String get codeCopied;
  String get watchAd;
  String get whyAds;
  String get whyAdsTitle;
  String get whyAdsBody;
  String get discountsActive;
  String get discountsNote;
  String get discountExclusive;
  String get goToSite;
  String get affiliateNote;
  String get inAppWelly;
  String get inAppSoundscape;
  String get inAppMinigame;
  String get inAppPercorsi;
  String get unlockItem;
  String get itemUnlocked;
  String get premiumAllContent;
  String get premiumPoints;
  String get premiumWelly;
  String get premiumDiscounts;
  String get premiumTrial;
  String get premiumOr;

  // ── Feedback ──────────────────────────────────────────────────────────────
  String get feedbackTitle;
  String get feedbackSubtitle;
  String get feedbackHint;
  String get feedbackSubmit;
  String get feedbackThanks;
  String get feedbackError;
  String get feedbackCategoryBug;
  String get feedbackCategoryIdea;
  String get feedbackCategoryFeature;
  String get feedbackCategoryOther;
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
  String get registerSubtitle => 'Start your wellness journey';
  String get tosAccept => 'I accept the ';
  String get tosTerms => 'Terms of Service';
  String get tosAnd => ' and the ';
  String get tosPrivacy => 'Privacy Policy';
  String get tosSuffix => ' of Be Well';
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
  String get firstHabitBody1 => 'Just 2% dehydration lowers focus and mood — yet most people drink far too little.';
  String get firstHabitBody2 => 'We start here: 8 glasses a day. I\'ll remind you when to drink, then we\'ll add new habits step by step.';
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
  String get greetingFallbackName => 'there';
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
  String get notifHabitTitle => '🌱 Be Well';
  String get notifHabitBody => 'Time to work on your habits — even one small action counts.';
  String get notifHabitChoiceTitle => '✨ New habit available';
  String get notifHabitChoiceBody => 'Open Be Well to choose your next habit.';

  String get notifFrequencyLabel => 'Reminder frequency';
  String get notifFreqOff => 'Off';
  String get notifFreqLow => 'Few';
  String get notifFreqNormal => 'Normal';
  String get notifFreqHigh => 'All';
  String get notifFreqOffDesc => 'No reminders';
  String get notifFreqLowDesc => '2 a day — morning and evening';
  String get notifFreqNormalDesc => '4 a day, spaced through the day';
  String get notifFreqHighDesc => 'Every ~2h during waking hours';
  String get notifSnoozeLabel => 'Pause reminders';
  String notifSnoozeActive(String until) => 'Paused until $until';
  String get notifSnoozeCancel => 'Resume now';
  String notifSnoozeHours(int h) => '$h h';

  String get navHome => 'Home';
  String get navHabits => 'Habits';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Rewards';
  String get navProfile => 'Profile';
  String get navUnlockIn => 'Unlocks in';
  String get navUnlockHabitsMsg => 'Complete 14 days of water to unlock habits.';
  String get navUnlockGrowthMsg => 'Keep building habits to unlock your growth journey.';
  String get comingSoonHabitsDesc => 'Complete 14 days of water.\nYour first new habit will unlock here.';
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
  String get breathingInhale => 'Inhale';
  String get breathingHold => 'Hold';
  String get breathingExhale => 'Exhale';
  String get breathingCycles => 'Cycles:';
  String get breathingTapToStart => 'Tap to\nbegin';
  String get breathingStart => 'Start breathing';
  String get breathingStop => 'Stop';
  String get breathingAgain => 'Again';
  String get breathingWellDone => '🌿 Well done!';
  String breathingCyclesCompleted(int n) => '$n cycles completed.';
  String breathingPointsEarned(int pts) => '+$pts points ⭐';

  String get guideTapToStart => 'Tap to\nbegin';
  String get guideStart => 'Start sequence';
  String get guideWellDone => '💪 Well done!';
  String guideStepProgress(int i, int total) => 'Step $i of $total';
  String guideStepsCompleted(int n) => '$n steps completed.';
  String get guideDeskStep1 => 'Shoulder rolls backward × 5';
  String get guideDeskStep2 => 'Seated spinal twist × 3 each side';
  String get guideDeskStep3 => 'Wrist and forearm circles × 10';
  String get guideDeskStep4 => 'Lateral neck tilt × 3 each side';
  String get guideDeskStep5 => 'Seated cat-cow × 5';
  String get guideNeckStep1 => 'Slow neck rolls × 5 each way';
  String get guideNeckStep2 => 'Shoulder shrug and release × 8';
  String get guideNeckStep3 => 'Lateral neck stretch × 3 each side';
  String get guideStretchStep1 => 'Arm reach overhead × 5';
  String get guideStretchStep2 => 'Torso side bend × 3 each side';
  String get guideStretchStep3 => 'Hip circles × 8';
  String get guideStretchStep4 => 'Calf raises × 10';
  String get guideStretchStep5 => 'Standing forward fold × 20s';

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
  String get badgeRootedName => 'Rooted habits';
  String get badgeRootedDesc => 'Habits that became second nature';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Silver';
  String get badgeTierGold => 'Gold';
  String get growthNextGoal => 'Next goal';
  String growthHabitsToRoot(int n) => n == 1 ? '1 habit to go' : '$n habits to go';

  String get habitChoiceTitle => 'Time to add something new.';
  String get habitChoiceSub => 'Choose where to focus next.';
  String get habitChoiceShowOther => 'show me other options ›';
  String get habitChoiceNotReady => 'I\'m not ready for this yet';
  String get habitChoiceOpen => 'Choose your next habit';
  String get habitNotReadySnoozed => 'No problem — I\'ll ask again in a week.';
  String get consolidatedTitle => '🏆 Congratulations!';
  String consolidatedBody(String habitName) => 'You\'ve made "$habitName" a real habit — your brain has built a lasting circuit for it.';
  String get consolidatedBadge => 'Habit consolidated';
  String get consolidatedCta => 'Continue';
  String habitStartsTomorrow(String habitName) => 'Great! Enjoy today\'s win — we\'ll start working on "$habitName" tomorrow.';
  String get habitEffortLow => 'easy';
  String get habitEffortMedium => 'moderate';
  String get habitEffortHigh => 'challenging';

  String get errorNetwork => 'No internet connection';
  String get errorGeneral => 'Something went wrong. Try again.';
  String get errorInvalidEmail => 'Invalid email address';
  String get errorWeakPassword => 'Password is too weak';
  String get errorEmailInUse => 'This email is already in use';
  String get errorInvalidCredentials => 'Incorrect email or password';
  String get errorTooManyAttempts => 'Too many attempts. Account temporarily locked';
  String get errorTimeout => 'The server isn\'t responding. Try again shortly';
  String get errorCancelled => 'Sign-in cancelled';
  String get errorAccountDisabled => 'Account disabled. Contact support';
  String get passwordStrengthWeak => 'Weak';
  String get passwordStrengthMedium => 'Medium';
  String get passwordStrengthStrong => 'Strong';
  String get passwordStrengthVeryStrong => 'Very strong';
  String get validationEmailRequired => 'Enter your email';
  String get validationPasswordRequired => 'Enter a password';
  String get validationPasswordTooShort => 'At least 8 characters';
  String get validationNameRequired => 'Enter your name';
  String get validationNameTooShort => 'At least 2 characters';
  String get accountLockedBody => 'Too many failed attempts.\nTry again in';
  String get accountLockedEmailSent => 'You\'ve received an email with instructions.';
  String get offlineLoginRequired => 'No connection — sign in requires internet';
  String get forgotCheckEmailTitle => 'Check your email';
  String forgotEmailSentBody(String email) =>
      'If an account exists for $email, you\'ll receive a link to reset your password.';
  String get forgotLinkExpiry => 'The link expires in 30 minutes.';
  String get forgotResendLimitReached => 'Resend limit reached';
  String forgotResendIn(int seconds) => 'Resend in ${seconds}s';
  String get verifyEmailCta => 'Click the link to activate your account.';
  String get verifyResendCta => 'Resend verification email';
  String get verifyChecked => 'I\'ve verified my email';
  String get verifyDifferentEmail => 'Use a different email?';
  String get verifySendError => 'Couldn\'t send the email, try again shortly';
  String get welcomeSlide1Title => 'Your personal\nwellness plan';
  String get welcomeSlide1Sub => 'Be Well builds a plan tailored to you, based on your habits and goals.';
  String get welcomeSlide2Title => 'Reminders that\nknow your calendar';
  String get welcomeSlide2Sub => 'Reminders adapt to your meetings and schedule, so they never interrupt you at the wrong time.';
  String get welcomeSlide3Title => 'Turn habits\ninto real rewards';
  String get welcomeSlide3Sub => 'Earn points by completing activities and redeem them for discounts, vouchers and more.';
  String get welcomeSkip => 'Skip';
  String get welcomeNext => 'Next →';
  String get welcomeStart => 'Start setup →';
  String get welcomeConfigureLater => 'Set up later';

  String get qProfileTitle => 'Tell us about you';
  String get qProfileSub => 'Helps us build the right plan for you.';
  String get qGoalsTitle => 'Goals & Stress';
  String get qGoalsSub => 'The most important screen for personalizing your plan.';
  String get qHealthTitle => 'Your habits';
  String get qHealthSub => 'Calibrates reminder frequency and type.';
  String get qScheduleTitle => 'Your schedule';
  String get qScheduleSub => 'We\'ll set reminders at the right moments.';
  String get qEnvTitle => 'Environment & Productivity';
  String get qEnvSub => 'The last details for your plan.';
  String get qBuildPlan => 'Done ✓';
  String get q1Label => 'Q1 · I\'m mainly…';
  String get q2Label => 'Q2 · I mainly work/study…';
  String get q3Label => 'Q3 · What do you want to improve? (multiple)';
  String get q4Label => 'Q4 · Current stress level';
  String get q23Label => 'Q5 · Have you used wellness apps before?';
  String get q15Label => 'Q6 · I usually sleep…';
  String get q16Label => 'Q7 · I drink about…';
  String get q17Label => 'Q8 · Screen time (leisure, excluding work)';
  String get q18Label => 'Q9 · I exercise…';
  String get q5Label => 'Q10 · My schedule is…';
  String get q6Label => 'Q11 · Want to sync your calendar?';
  String get q7Label => 'Q12 · How many reminders per day?';
  String get q8Label => 'Q13 · Ideal break…';
  String get q9q10Label => 'Q14–Q15 · Lunch break';
  String get q11q14Label => 'Q16–Q19 · I have access to…';
  String get q19Label => 'Q20 · Distraction level in your environment';
  String get q20Label => 'Q21 · When are you most focused?';
  String get q21Label => 'Q22 · How long can you focus at a stretch?';
  String get q22Label => 'Q23 · How many meetings per day (average)?';
  String get q1Student => 'Student';
  String get q1Employee => 'Employee';
  String get q1Freelancer => 'Freelancer';
  String get q1Other => 'Other';
  String get q1Both => 'Both';
  String get q2Home => 'From home';
  String get q2Office => 'At the office';
  String get q2Hybrid => 'Hybrid';
  String get q2Varies => 'Varies';
  String get goalStress => 'Reduce stress';
  String get goalFocus => 'Improve focus';
  String get goalHealth => 'General health';
  String get goalSleep => 'Sleep better';
  String get goalEnergy => 'More energy';
  String get goalWeight => 'Fitness';
  String get stress1 => 'Very calm';
  String get stress2 => 'Fairly calm';
  String get stress3 => 'Normal';
  String get stress4 => 'A bit stressed';
  String get stress5 => 'Very stressed';
  String get stressCalmEnd => 'Calm';
  String get stressStressedEnd => 'Stressed';
  String get priorNone => 'No, never';
  String get priorHeadspace => 'Headspace';
  String get priorCalm => 'Calm';
  String get priorMultiple => 'More than one';
  String get priorOther => 'Another app';
  String get hydroLow => 'low';
  String get hydroGreat => 'great';
  String get exNever => 'Never';
  String get ex12x => '1-2x/week';
  String get ex34x => '3-4x/week';
  String get exDaily => 'Every day';
  String get schedFixed => 'Fixed';
  String get schedFlexible => 'Flexible';
  String get schedShift => 'Shifts';
  String get schedIrregular => 'Irregular';
  String get calNoneLabel => 'No thanks, not now';
  String get calSyncNote => '✓ We\'ll ask for permissions after you confirm your plan';
  String get remMinimal => 'Minimal';
  String get remMinimalSub => '~2/day';
  String get remModerate => 'Moderate';
  String get remModerateSub => '~4/day';
  String get remFrequent => 'Frequent';
  String get remFrequentSub => '~6/day';
  String get remVeryFrequent => 'Very frequent';
  String get remVeryFrequentSub => '8+/day';
  String get lunchTimeLabel => 'Time';
  String get lunchDurationLabel => 'Duration';
  String get resParkLabel => 'Park or green space';
  String get resParkSub => 'For lunch-break walks';
  String get resGymLabel => 'Gym or fitness space';
  String get resGymSub => 'At the office or nearby';
  String get resWindowLabel => 'Window with a view';
  String get resWindowSub => 'For the 20-20-20 eye rule';
  String get resQuietLabel => 'Quiet space';
  String get resQuietSub => 'For meditation and deep focus';
  String get distLow => 'Low';
  String get distMedium => 'Medium';
  String get distHigh => 'High';
  String get distVeryHigh => 'Very high';
  String get focusMorning => 'Morning';
  String get focusMidday => 'Midday';
  String get focusAfternoon => 'Afternoon';
  String get focusEvening => 'Evening';
  String get meeting02 => '0-2 / day';
  String get meeting24 => '2-4 / day';
  String get meeting46 => '4-6 / day';
  String get meeting6plus => '6+ / day';
  String get screenTimeWarning => 'We\'ll enable more frequent eye reminders';
  String get crisisTitle => 'You\'re going through a hard time';
  String get crisisBody => 'Be Well is here to support you. If you need immediate help: contact a local helpline.';
  String get qOptional => 'optional';
  String get qBack => '← Back';
  String get qSkipAll => 'Skip all';
  String qOfTotal(int current, int total) => '$current of $total';
  String get planGenTitle => 'Building your plan…';
  String get planGenSub => 'Applying your personalization rules';
  String get planStep1 => 'Analyzing your profile';
  String get planStep2 => 'Configuring reminders';
  String get planStep3 => 'Selecting activities';
  String get planStep4 => 'Setting up your dashboard';
  String get planReadyBadge => '🎉 Plan ready!';
  String get planPreviewTitle => 'Your wellness\nplan';
  String get planPreviewSub => 'Personalized from your answers. You can always change it from Settings.';
  String get planRemindersPerDay => 'reminders/day';
  String get planFocusSessions => 'focus sessions';
  String get planPointsPerDay => 'points/day';
  String get planMorning => '🌅 Morning';
  String get planAfternoon => '☀️ Afternoon';
  String get planEvening => '🌙 Evening';
  String planFromTime(String time) => 'from $time';
  String planConnectCalendar(String name) => 'Connect $name';
  String get planConnectCalendarSub => 'We\'ll ask for permission after you confirm';
  String get planFallbackNote => 'We used a default plan. We\'ll refine it as you use the app.';
  String get planConfirmCta => 'Start with Be Well  ';
  String get planConfirmSub => 'You can change your plan anytime from Settings';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Profile';
  String get accountSection => 'Account';
  String get emailAccountLabel => 'Email account';
  String get supportSection => 'Support';
  String get editNameTitle => 'Edit name';
  String get yourNameHint => 'Your name';
  String get resetTutorialTitle => 'Reset tutorial';
  String get resetTutorialBody => 'Welly will show all tutorial dialogs again as if it were your first time. Useful for testing the flow.';
  String get resetTutorialCta => 'Reset';
  String get resetTutorialSnackbar => 'Tutorial reset ✓';
  String genericError(String msg) => 'Error: $msg';
  String get settingsTitle => 'Settings';
  String get styleCardDesc => 'Content in cards,\nclean typography';
  String get styleAmbientDesc => 'Atmospheric landscape,\neditorial font';
  String get toneSection => 'Tone';
  String get accessibilitySection => 'Accessibility';
  String get contrastDesc => 'Increases text contrast';
  String get textSizeDesc => 'Increases font size';
  String get remindersLabel => 'Activity reminders';
  String get remindersDesc => 'Notifications for planned activities';
  String get comingSoonTitle => 'Coming soon';
  String get comingSoonBody => 'This section isn\'t available yet — it\'s on our roadmap.';
  String get habitMarkDone => 'Done';
  String get slowdownReasonHeavy => 'This habit feels like too much right now';
  String heatmapDaysAgo(int n) => '$n days ago';
  String get heatmapToday => 'today';
  String phaseStarted(String date) => 'started $date';
  String phaseReached(String date) => 'reached $date';
  String get marketAdTitle => 'Help Be Well';
  String get marketAdSubtitle => 'Earn 10 pts by watching a spot';
  String get marketAdDialogBody => 'Watch an ad: you help keep the app free and instantly earn 10 points.';
  String get marketWatchNow => 'Watch now';
  String get dialogGotIt => 'Got it';
  String get marketAdUnavailable => 'Spot not available right now';
  String get referralTitle => 'Invite a friend';
  String get referralSubtitle => 'Earn 50 pts for every friend who signs up';
  String get referralApply => 'Apply';
  String get referralApplied => 'Code applied! Your friend will get the bonus soon. 🎉';
  String get referralErrorInvalid => 'Invalid code';
  String get referralErrorOwn => 'You can\'t use your own code';
  String get referralErrorAlready => 'You\'ve already redeemed a code';
  String get referralErrorNotSignedIn => 'You need to be signed in';
  String get referralErrorGeneric => 'Something went wrong, try again';
  String get referralHint => 'Have an invite code?';
  String premiumPrice(String price) => '$price/month';
  String referralShareButton(String code) => 'Share my code · $code';
  String get referralRetry => 'Couldn\'t generate the code — tap to retry';
  String referralShareMessage(String code) =>
      'I\'m using Be Well to build healthier habits, one day at a time 🌱\n'
      'Download the app and use my invite code "$code" — you\'ll get 50 bonus points as soon as you start!';

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
  String get configuratorTitle => 'Personalize your plan';
  String get configuratorSubtitle => 'Answer a few questions so Be Well can suggest the right habits for you';
  String get configuratorDoneTitle => 'Your plan is personalized';
  String get configuratorDoneSubtitle => 'Tap to update your answers';
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
  String get slowdownMenuSubtitle => 'This pauses new habit suggestions for 2 weeks — this one stays in your plan either way.';
  String get slowdownWellyResponse => 'No problem — new suggestions are paused for 2 weeks. This habit stays in your plan, take the time you need.';
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
  String get tutorialNext => 'Next →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable         => 'points available';
  String get marketplaceTabRewards   => 'Rewards';
  String get marketplaceTabDiscounts => 'Discounts';
  String get marketplaceTabInApp     => 'In-app';
  String get rewardsToRedeem         => 'to redeem';
  String get rewardRedeemed          => 'There it is. You earned it.';
  String get rewardConfirmTitle      => 'Are you sure?';
  String get rewardConfirmBody       => 'X points will be deducted from your balance.';
  String get rewardRedeemFailed => 'Couldn\'t redeem this reward — not enough points, or it\'s no longer available.';
  String get copyCode                => 'Copy code';
  String get codeCopied              => 'Copied';
  String get watchAd                 => 'Watch a spot · +10 pt';
  String get whyAds                  => 'why?';
  String get whyAdsTitle             => 'Be Well is free for everyone';
  String get whyAdsBody              => 'Be Well is a free app to be accessible to everyone. Like any service, it has running costs. By watching ads when you can, you help us keep the service running and improve it for everyone. Thank you.';
  String get discountsActive         => 'active discounts';
  String get discountsNote           => 'Discounts are updated monthly. No points required.';
  String get discountExclusive       => 'exclusive Be Well';
  String get goToSite                => 'Go to site';
  String get affiliateNote           => 'This link supports Be Well';
  String get inAppWelly              => 'welly';
  String get inAppSoundscape         => 'soundscape';
  String get inAppMinigame           => 'minigame';
  String get inAppPercorsi           => 'paths';
  String get unlockItem              => 'Unlock';
  String get itemUnlocked            => 'Unlocked';
  String get premiumAllContent       => 'All in-app content included';
  String get premiumPoints           => '+20% points on every habit';
  String get premiumWelly            => 'Fully customizable Welly';
  String get premiumDiscounts        => 'Exclusive discounts in advance';
  String get premiumTrial            => 'Try 7 days free';
  String get premiumOr               => 'or buy individually with points';

  String get feedbackTitle => 'Leave feedback';
  String get feedbackSubtitle => 'It helps us make Be Well better for you.';
  String get feedbackHint => 'Write your feedback here…';
  String get feedbackSubmit => 'Send feedback';
  String get feedbackThanks => 'Thanks for your feedback!';
  String get feedbackError => 'Couldn\'t send it, try again shortly';
  String get feedbackCategoryBug => 'Bug';
  String get feedbackCategoryIdea => 'Idea';
  String get feedbackCategoryFeature => 'Feature';
  String get feedbackCategoryOther => 'Other';

  String spotlightText(String id) {
    switch (id) {
      // Home tour
      case 'home_welcome':    return 'Welcome! I\'m Welly. Let me show you around so you can start the right way.';
      case 'home_water':      return 'This is your first habit: drinking water. 8 glasses a day is your goal. Simple and powerful.';
      case 'home_add_glass':  return 'Tap here every time you drink a glass. Each tap builds your habit — try it right now!';
      case 'home_welly':      return 'That\'s me — Welly! I change expression based on your progress. The better you do, the more radiant I get.';
      case 'home_phase':      return 'This is your Phase. You start at Seed — Phase 1. Build habits to grow all the way to Phase 5: Radiant.';
      case 'home_nav':        return 'New sections unlock here as you progress. Start with water — everything else opens up from there.';
      // Habits tour
      case 'habits_welcome':  return 'You unlocked the Habits screen! From here you manage all your routines.';
      case 'habits_now':      return 'The \'Right now\' card shows the habit most relevant to this exact moment of your day.';
      case 'habits_list':     return 'All habits are sorted by their best time. Morning habits appear first in the morning — Welly knows your rhythm.';
      case 'habits_ready':      return 'All set! Tap \'Complete\' every day to build your streak. Small actions, done consistently, change everything.';
      // Marketplace tour
      case 'marketplace_welcome': return 'These are your Be Well Rewards! Every glass of water, every habit completed brings you here — where your efforts become real rewards.';
      case 'marketplace_points':  return 'Your points balance is always visible here. It builds automatically as you build habits — nothing extra to do.';
      case 'marketplace_tabs':    return 'Three tabs: Rewards to redeem with points, exclusive Discounts for free, and In-app content to unlock. All earned through your daily habits.';
      case 'marketplace_card':    return 'Each reward has a cost in points. Tap to redeem — you\'ll get a code instantly. The more consistent you are, the more you unlock.';
      // Growth tour
      case 'growth_welcome':      return 'This is your Growth. Not a ranking — a mirror. It shows who you\'re becoming, not just what you\'re doing.';
      case 'growth_phase':        return 'Your phase reflects how deep your habits are rooted. From Phase 1 (Seed) to Phase 5 (Radiant) — each step is a real neurological change, not a game level.';
      case 'growth_heatmap':      return 'This heatmap shows your consistency over time. Science says the pattern matters more than intensity: a few missed days don\'t reset everything.';
      case 'growth_badges':       return 'Badges aren\'t decorations. Each one matches a behaviour you\'ve kept for a measurable period. They\'re proof of your journey.';
      default: return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitStartsTomorrow(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':     return 'Welcome! This is your base. At the top you\'ll always find the most urgent habit for right now. Start there — everything else can wait.';
      case 'home_first_open_2':   return 'Water is the first habit because it\'s the biological foundation for everything else. Without hydration, concentration drops by up to 20% after just 90 minutes.';
      case 'water_tracker_first': return 'The tracker counts glasses from when you open the app each morning. 8 a day is the target — but even hitting 5 is already better than yesterday.';
      case 'first_completion':    return 'Done! Every completion creates a new neural connection. Small, but real. Your brain has just strengthened a circuit.';
      case 'streak_explain':      return 'If you come back tomorrow, your streak begins. The only rule that matters: never skip two days in a row. One stop is human. Two is a new habit — the wrong one.';
      case 'habits_tab_first':    return 'Here you\'ll find all your habits sorted for the best moment in your day. Welly knows your rhythms — morning habits appear in the morning, evening ones in the evening.';
      case 'habit_card_explain':  return 'The circular arc fills each time you complete. At 7 days something interesting happens — your brain starts registering it as a routine.';
      case 'focus_unlocked':      return 'You have the 25-minute Focus available right from the start! The human brain has a natural concentration cycle of about 20–30 minutes — use it for a distraction-free work block.';
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
  String get registerSubtitle => 'Inizia il tuo percorso di benessere';
  String get tosAccept => 'Accetto i ';
  String get tosTerms => 'Termini di Servizio';
  String get tosAnd => ' e la ';
  String get tosPrivacy => 'Privacy Policy';
  String get tosSuffix => ' di Be Well';
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
  String get firstHabitBody1 => 'Bastano il 2% di disidratazione per calare concentrazione e umore — e in pochi bevono a sufficienza.';
  String get firstHabitBody2 => 'Partiamo da qui: 8 bicchieri al giorno. Ti ricorderò io quando bere, poi aggiungeremo nuove abitudini passo dopo passo.';
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
  String get greetingFallbackName => 'a te';
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
  String get notifHabitTitle => '🌱 Be Well';
  String get notifHabitBody => 'È il momento di lavorare alle tue abitudini — anche una piccola azione conta.';
  String get notifHabitChoiceTitle => '✨ Nuova abitudine disponibile';
  String get notifHabitChoiceBody => 'Apri Be Well per scegliere la tua prossima abitudine.';

  String get notifFrequencyLabel => 'Frequenza reminder';
  String get notifFreqOff => 'Nessuna';
  String get notifFreqLow => 'Poche';
  String get notifFreqNormal => 'Normale';
  String get notifFreqHigh => 'Tutte';
  String get notifFreqOffDesc => 'Nessun reminder';
  String get notifFreqLowDesc => '2 al giorno — mattina e sera';
  String get notifFreqNormalDesc => '4 al giorno, distribuiti nella giornata';
  String get notifFreqHighDesc => 'Ogni ~2h nelle ore di veglia';
  String get notifSnoozeLabel => 'Metti in pausa i reminder';
  String notifSnoozeActive(String until) => 'In pausa fino alle $until';
  String get notifSnoozeCancel => 'Riattiva ora';
  String notifSnoozeHours(int h) => '$h h';

  String get navHome => 'Home';
  String get navHabits => 'Abitudini';
  String get navFocus => 'Focus';
  String get navGrowth => 'Crescita';
  String get navPlan => 'Piano';
  String get navRewards => 'Premi';
  String get navProfile => 'Profilo';
  String get navUnlockIn => 'Sblocco tra';
  String get navUnlockHabitsMsg => 'Completa 14 giorni di acqua per sbloccare le abitudini.';
  String get navUnlockGrowthMsg => 'Continua a costruire abitudini per sbloccare la crescita.';
  String get comingSoonHabitsDesc => 'Completa 14 giorni di acqua.\nLa tua prima nuova abitudine si sbloccherà qui.';
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
  String get breathingInhale => 'Inspira';
  String get breathingHold => 'Trattieni';
  String get breathingExhale => 'Espira';
  String get breathingCycles => 'Cicli:';
  String get breathingTapToStart => 'Tocca per\ncominciare';
  String get breathingStart => 'Inizia respirazione';
  String get breathingStop => 'Interrompi';
  String get breathingAgain => 'Di nuovo';
  String get breathingWellDone => '🌿 Ottimo lavoro!';
  String breathingCyclesCompleted(int n) => '$n cicli completati.';
  String breathingPointsEarned(int pts) => '+$pts punti ⭐';

  String get guideTapToStart => 'Tocca per\ncominciare';
  String get guideStart => 'Inizia sequenza';
  String get guideWellDone => '💪 Ottimo lavoro!';
  String guideStepProgress(int i, int total) => 'Passo $i di $total';
  String guideStepsCompleted(int n) => '$n passi completati.';
  String get guideDeskStep1 => 'Rotazione spalle indietro × 5';
  String get guideDeskStep2 => 'Torsione dorsale seduta × 3 per lato';
  String get guideDeskStep3 => 'Cerchi polsi e avambracci × 10';
  String get guideDeskStep4 => 'Inclinazione laterale collo × 3 per lato';
  String get guideDeskStep5 => 'Cat-cow seduto × 5';
  String get guideNeckStep1 => 'Rotazioni lente del collo × 5 per verso';
  String get guideNeckStep2 => 'Alza e rilascia le spalle × 8';
  String get guideNeckStep3 => 'Stretching laterale collo × 3 per lato';
  String get guideStretchStep1 => 'Allungo braccia verso l\'alto × 5';
  String get guideStretchStep2 => 'Flessione laterale busto × 3 per lato';
  String get guideStretchStep3 => 'Cerchi con i fianchi × 8';
  String get guideStretchStep4 => 'Sollevamento polpacci × 10';
  String get guideStretchStep5 => 'Flessione in avanti da in piedi × 20s';

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
  String get badgeRootedName => 'Abitudini radicate';
  String get badgeRootedDesc => 'Abitudini diventate una seconda natura';
  String get badgeTierBronze => 'Bronzo';
  String get badgeTierSilver => 'Argento';
  String get badgeTierGold => 'Oro';
  String get growthNextGoal => 'Prossimo obiettivo';
  String growthHabitsToRoot(int n) => n == 1 ? 'Manca 1 abitudine' : 'Mancano $n abitudini';

  String get habitChoiceTitle => 'È il momento di aggiungere\nqualcosa di nuovo.';
  String get habitChoiceSub => 'Scegli dove concentrarti adesso.';
  String get habitChoiceShowOther => 'mostrami altre opzioni ›';
  String get habitChoiceNotReady => 'Non mi sento pronto/a';
  String get habitChoiceOpen => 'Scegli la prossima abitudine';
  String get habitNotReadySnoozed => 'Nessun problema — te lo richiederò tra una settimana.';
  String get consolidatedTitle => '🏆 Complimenti!';
  String consolidatedBody(String habitName) => 'Hai reso "$habitName" una vera abitudine — il tuo cervello ha costruito un circuito duraturo per lei.';
  String get consolidatedBadge => 'Abitudine consolidata';
  String get consolidatedCta => 'Continua';
  String habitStartsTomorrow(String habitName) => 'Molto bene! Oggi goditi il traguardo — inizieremo a lavorare su "$habitName" da domani.';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'moderato';
  String get habitEffortHigh => 'impegnativo';

  String get errorNetwork => 'Nessuna connessione internet';
  String get errorGeneral => 'Qualcosa è andato storto. Riprova.';
  String get errorInvalidEmail => 'Indirizzo email non valido';
  String get errorWeakPassword => 'La password è troppo debole';
  String get errorEmailInUse => 'Questa email è già in uso';
  String get errorInvalidCredentials => 'Email o password errati';
  String get errorTooManyAttempts => 'Troppi tentativi. Account bloccato temporaneamente';
  String get errorTimeout => 'Il server non risponde. Riprova tra poco';
  String get errorCancelled => 'Accesso annullato';
  String get errorAccountDisabled => 'Account disabilitato. Contatta il supporto';
  String get passwordStrengthWeak => 'Debole';
  String get passwordStrengthMedium => 'Media';
  String get passwordStrengthStrong => 'Forte';
  String get passwordStrengthVeryStrong => 'Molto forte';
  String get validationEmailRequired => 'Inserisci la tua email';
  String get validationPasswordRequired => 'Inserisci una password';
  String get validationPasswordTooShort => 'Minimo 8 caratteri';
  String get validationNameRequired => 'Inserisci il tuo nome';
  String get validationNameTooShort => 'Minimo 2 caratteri';
  String get accountLockedBody => 'Troppi tentativi falliti.\nRiprova tra';
  String get accountLockedEmailSent => 'Hai ricevuto un\'email con le istruzioni.';
  String get offlineLoginRequired => 'Nessuna connessione — il login richiede internet';
  String get forgotCheckEmailTitle => 'Controlla la tua email';
  String forgotEmailSentBody(String email) =>
      'Se esiste un account per $email, riceverai un link per reimpostare la password.';
  String get forgotLinkExpiry => 'Il link scade tra 30 minuti.';
  String get forgotResendLimitReached => 'Limite reinvii raggiunto';
  String forgotResendIn(int seconds) => 'Reinvia tra ${seconds}s';
  String get verifyEmailCta => 'Clicca il link per attivare il tuo account.';
  String get verifyResendCta => 'Reinvia email di verifica';
  String get verifyChecked => 'Ho verificato l\'email';
  String get verifyDifferentEmail => 'Usare un\'email diversa?';
  String get verifySendError => 'Invio non riuscito, riprova tra poco';
  String get welcomeSlide1Title => 'Il tuo piano\ndi benessere personale';
  String get welcomeSlide1Sub => 'Be Well costruisce un piano su misura per te, basato sulle tue abitudini e obiettivi.';
  String get welcomeSlide2Title => 'Reminder che\nconosco il tuo calendario';
  String get welcomeSlide2Sub => 'I promemoria si adattano ai tuoi meeting e orari, così non ti interrompono mai nel momento sbagliato.';
  String get welcomeSlide3Title => 'Trasforma le abitudini\nin premi reali';
  String get welcomeSlide3Sub => 'Guadagna punti completando attività e riscattali per sconti, voucher e molto altro.';
  String get welcomeSkip => 'Salta';
  String get welcomeNext => 'Avanti →';
  String get welcomeStart => 'Inizia la configurazione →';
  String get welcomeConfigureLater => 'Configura dopo';

  String get qProfileTitle => 'Parlaci di te';
  String get qProfileSub => 'Ci aiuta a costruire il piano giusto per te.';
  String get qGoalsTitle => 'Obiettivi & Stress';
  String get qGoalsSub => 'La schermata più importante per personalizzare il tuo piano.';
  String get qHealthTitle => 'Le tue abitudini';
  String get qHealthSub => 'Calibra la frequenza e il tipo di reminder.';
  String get qScheduleTitle => 'Il tuo orario';
  String get qScheduleSub => 'Impostiamo i reminder nei momenti giusti.';
  String get qEnvTitle => 'Ambiente & Produttività';
  String get qEnvSub => 'Gli ultimi dettagli per il tuo piano.';
  String get qBuildPlan => 'Fatto ✓';
  String get q1Label => 'Q1 · Sono principalmente…';
  String get q2Label => 'Q2 · Lavoro/studio principalmente…';
  String get q3Label => 'Q3 · Cosa vuoi migliorare? (più opzioni)';
  String get q4Label => 'Q4 · Livello di stress attuale';
  String get q23Label => 'Q5 · Hai già usato app di benessere?';
  String get q15Label => 'Q6 · Di solito dormo…';
  String get q16Label => 'Q7 · Bevo circa…';
  String get q17Label => 'Q8 · Tempo schermo (svago, escluso lavoro)';
  String get q18Label => 'Q9 · Faccio esercizio fisico…';
  String get q5Label => 'Q10 · Il mio orario è…';
  String get q6Label => 'Q11 · Vuoi sincronizzare il calendario?';
  String get q7Label => 'Q12 · Quanti reminder vuoi al giorno?';
  String get q8Label => 'Q13 · Pausa ideale…';
  String get q9q10Label => 'Q14–Q15 · Pausa pranzo';
  String get q11q14Label => 'Q16–Q19 · Ho accesso a…';
  String get q19Label => 'Q20 · Livello di distrazioni nell\'ambiente';
  String get q20Label => 'Q21 · Quando sei più concentrato?';
  String get q21Label => 'Q22 · Quanto riesci a concentrarti di fila?';
  String get q22Label => 'Q23 · Quanti meeting hai al giorno (in media)?';
  String get q1Student => 'Studente';
  String get q1Employee => 'Dipendente';
  String get q1Freelancer => 'Freelancer';
  String get q1Other => 'Altro';
  String get q1Both => 'Entrambe';
  String get q2Home => 'Da casa';
  String get q2Office => 'In ufficio';
  String get q2Hybrid => 'Ibrido';
  String get q2Varies => 'Varia';
  String get goalStress => 'Ridurre lo stress';
  String get goalFocus => 'Migliorare il focus';
  String get goalHealth => 'Salute generale';
  String get goalSleep => 'Dormire meglio';
  String get goalEnergy => 'Più energia';
  String get goalWeight => 'Forma fisica';
  String get stress1 => 'Molto calmo';
  String get stress2 => 'Abbastanza calmo';
  String get stress3 => 'Normale';
  String get stress4 => 'Un po\' stressato';
  String get stress5 => 'Molto stressato';
  String get stressCalmEnd => 'Calmo';
  String get stressStressedEnd => 'Stressato';
  String get priorNone => 'No, mai';
  String get priorHeadspace => 'Headspace';
  String get priorCalm => 'Calm';
  String get priorMultiple => 'Più di una';
  String get priorOther => 'Altra app';
  String get hydroLow => 'poco';
  String get hydroGreat => 'ottimo';
  String get exNever => 'Mai';
  String get ex12x => '1-2x/settimana';
  String get ex34x => '3-4x/settimana';
  String get exDaily => 'Ogni giorno';
  String get schedFixed => 'Fisso';
  String get schedFlexible => 'Flessibile';
  String get schedShift => 'A turni';
  String get schedIrregular => 'Irregolare';
  String get calNoneLabel => 'No grazie, per ora';
  String get calSyncNote => '✓ Ti chiederemo i permessi dopo aver confermato il piano';
  String get remMinimal => 'Minimi';
  String get remMinimalSub => '~2/giorno';
  String get remModerate => 'Moderati';
  String get remModerateSub => '~4/giorno';
  String get remFrequent => 'Frequenti';
  String get remFrequentSub => '~6/giorno';
  String get remVeryFrequent => 'Molto freq.';
  String get remVeryFrequentSub => '8+/giorno';
  String get lunchTimeLabel => 'Ora';
  String get lunchDurationLabel => 'Durata';
  String get resParkLabel => 'Parco o spazio verde';
  String get resParkSub => 'Per camminate durante la pausa pranzo';
  String get resGymLabel => 'Palestra o spazio fitness';
  String get resGymSub => 'In ufficio o nelle vicinanze';
  String get resWindowLabel => 'Finestra con vista';
  String get resWindowSub => 'Per la regola 20-20-20 degli occhi';
  String get resQuietLabel => 'Spazio tranquillo';
  String get resQuietSub => 'Per meditazione e concentrazione profonda';
  String get distLow => 'Basso';
  String get distMedium => 'Medio';
  String get distHigh => 'Alto';
  String get distVeryHigh => 'Molto alto';
  String get focusMorning => 'Mattina';
  String get focusMidday => 'Mezzogiorno';
  String get focusAfternoon => 'Pomeriggio';
  String get focusEvening => 'Sera';
  String get meeting02 => '0-2 / giorno';
  String get meeting24 => '2-4 / giorno';
  String get meeting46 => '4-6 / giorno';
  String get meeting6plus => '6+ / giorno';
  String get screenTimeWarning => 'Attiveremo i reminder occhi più frequenti';
  String get crisisTitle => 'Stai attraversando un momento difficile';
  String get crisisBody => 'Be Well è qui per supportarti. Se hai bisogno di aiuto immediato: Telefono Amico 02 2327 2327';
  String get qOptional => 'opzionale';
  String get qBack => '← Indietro';
  String get qSkipAll => 'Salta tutto';
  String qOfTotal(int current, int total) => '$current di $total';
  String get planGenTitle => 'Costruendo il tuo piano…';
  String get planGenSub => 'Stiamo applicando le regole di personalizzazione';
  String get planStep1 => 'Analizzo il tuo profilo';
  String get planStep2 => 'Configuro i reminder';
  String get planStep3 => 'Seleziono le attività';
  String get planStep4 => 'Configuro la dashboard';
  String get planReadyBadge => '🎉 Piano pronto!';
  String get planPreviewTitle => 'Il tuo piano\ndi benessere';
  String get planPreviewSub => 'Personalizzato sulle tue risposte. Potrai sempre modificarlo da Impostazioni.';
  String get planRemindersPerDay => 'reminder/giorno';
  String get planFocusSessions => 'sessioni focus';
  String get planPointsPerDay => 'punti/giorno';
  String get planMorning => '🌅 Mattina';
  String get planAfternoon => '☀️ Pomeriggio';
  String get planEvening => '🌙 Sera';
  String planFromTime(String time) => 'dalle $time';
  String planConnectCalendar(String name) => 'Connetti $name';
  String get planConnectCalendarSub => 'Richiederemo il permesso dopo la conferma';
  String get planFallbackNote => 'Abbiamo usato un piano di default. Lo raffineremo man mano che usi l\'app.';
  String get planConfirmCta => 'Inizia con Be Well  ';
  String get planConfirmSub => 'Potrai modificare il piano in qualsiasi momento da Impostazioni';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Profilo';
  String get accountSection => 'Account';
  String get emailAccountLabel => 'Email account';
  String get supportSection => 'Supporto';
  String get editNameTitle => 'Modifica nome';
  String get yourNameHint => 'Il tuo nome';
  String get resetTutorialTitle => 'Reset tutorial';
  String get resetTutorialBody => 'Welly mostrerà di nuovo tutti i dialoghi tutorial come se fosse la prima volta. Utile per testare il flusso.';
  String get resetTutorialCta => 'Reset';
  String get resetTutorialSnackbar => 'Tutorial resettato ✓';
  String genericError(String msg) => 'Errore: $msg';
  String get settingsTitle => 'Impostazioni';
  String get styleCardDesc => 'Contenuti in schede,\ntipografia chiara';
  String get styleAmbientDesc => 'Paesaggio atmosferico,\nfont editoriale';
  String get toneSection => 'Tonalità';
  String get accessibilitySection => 'Accessibilità';
  String get contrastDesc => 'Aumenta il contrasto dei testi';
  String get textSizeDesc => 'Aumenta la dimensione dei caratteri';
  String get remindersLabel => 'Promemoria attività';
  String get remindersDesc => 'Notifiche per le attività pianificate';
  String get comingSoonTitle => 'Prossimamente';
  String get comingSoonBody => 'Questa sezione non è ancora disponibile — è nella nostra roadmap.';
  String get habitMarkDone => 'Fatto';
  String get slowdownReasonHeavy => 'Questa abitudine mi pesa troppo';
  String heatmapDaysAgo(int n) => '$n giorni fa';
  String get heatmapToday => 'oggi';
  String phaseStarted(String date) => 'iniziato $date';
  String phaseReached(String date) => 'raggiunto $date';
  String get marketAdTitle => 'Aiuta Be Well';
  String get marketAdSubtitle => 'Guadagna 10 pt guardando uno spot';
  String get marketAdDialogBody => 'Guarda uno spot pubblicitario: ci aiuti a mantenere l\'app gratuita e guadagni subito 10 punti.';
  String get marketWatchNow => 'Guarda ora';
  String get dialogGotIt => 'Capito';
  String get marketAdUnavailable => 'Spot non disponibile al momento';
  String get referralTitle => 'Invita un amico';
  String get referralSubtitle => 'Guadagna 50 pt per ogni amico che si iscrive';
  String get referralApply => 'Applica';
  String get referralApplied => 'Codice applicato! Il tuo amico riceverà presto il bonus. 🎉';
  String get referralErrorInvalid => 'Codice non valido';
  String get referralErrorOwn => 'Non puoi usare il tuo codice';
  String get referralErrorAlready => 'Hai già riscattato un codice invito';
  String get referralErrorNotSignedIn => 'Devi essere loggato';
  String get referralErrorGeneric => 'Qualcosa è andato storto, riprova';
  String get referralHint => 'Hai un codice invito?';
  String premiumPrice(String price) => '$price/mese';
  String referralShareButton(String code) => 'Condividi il mio codice · $code';
  String get referralRetry => 'Generazione codice non riuscita — tocca per riprovare';
  String referralShareMessage(String code) =>
      'Sto usando Be Well per costruire abitudini più sane, giorno dopo giorno 🌱\n'
      'Scarica l\'app e usa il mio codice invito "$code" — per te 50 punti bonus non appena inizi!';

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
  String get configuratorTitle => 'Personalizza il tuo piano';
  String get configuratorSubtitle => 'Rispondi a qualche domanda: Be Well ti suggerirà le abitudini più adatte a te';
  String get configuratorDoneTitle => 'Il tuo piano è personalizzato';
  String get configuratorDoneSubtitle => 'Tocca per aggiornare le tue risposte';
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
  String get slowdownMenuSubtitle => 'Le nuove proposte di abitudini vengono messe in pausa per 2 settimane — questa resta comunque nel tuo piano.';
  String get slowdownWellyResponse => 'Nessun problema — le nuove proposte sono in pausa per 2 settimane. Questa abitudine resta nel tuo piano, prenditi il tempo che ti serve.';
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
  String get tutorialNext => 'Avanti →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable         => 'punti disponibili';
  String get marketplaceTabRewards   => 'Premi';
  String get marketplaceTabDiscounts => 'Sconti';
  String get marketplaceTabInApp     => 'In-app';
  String get rewardsToRedeem         => 'da riscattare';
  String get rewardRedeemed          => 'Eccolo. Te lo sei guadagnato.';
  String get rewardConfirmTitle      => 'Sei sicuro?';
  String get rewardConfirmBody       => 'Verranno scalati X punti dal tuo saldo.';
  String get rewardRedeemFailed => 'Non è stato possibile riscattare questo premio — punti insufficienti, oppure non è più disponibile.';
  String get copyCode                => 'Copia codice';
  String get codeCopied              => 'Copiato';
  String get watchAd                 => 'Guarda uno spot · +10 pt';
  String get whyAds                  => 'perché?';
  String get whyAdsTitle             => 'Be Well è gratuita per tutti';
  String get whyAdsBody              => 'Be Well è un\'app gratuita per essere accessibile a chiunque. Come ogni servizio, ha costi di gestione. Guardando le inserzioni quando puoi, ci aiuti a tenere il servizio attivo e migliorarlo per tutti. Grazie davvero.';
  String get discountsActive         => 'sconti attivi';
  String get discountsNote           => 'Gli sconti sono aggiornati ogni mese. Nessun punto richiesto.';
  String get discountExclusive       => 'esclusivo Be Well';
  String get goToSite                => 'Vai al sito';
  String get affiliateNote           => 'Questo link supporta Be Well';
  String get inAppWelly              => 'welly';
  String get inAppSoundscape         => 'soundscape';
  String get inAppMinigame           => 'minigame';
  String get inAppPercorsi           => 'percorsi';
  String get unlockItem              => 'Sblocca';
  String get itemUnlocked            => 'Sbloccato';
  String get premiumAllContent       => 'Tutti i contenuti in-app inclusi';
  String get premiumPoints           => '+20% punti su ogni abitudine';
  String get premiumWelly            => 'Welly personalizzabile completo';
  String get premiumDiscounts        => 'Sconti esclusivi in anteprima';
  String get premiumTrial            => 'Prova 7 giorni gratis';
  String get premiumOr               => 'oppure acquista singolarmente con i punti';

  String get feedbackTitle => 'Lascia un feedback';
  String get feedbackSubtitle => 'Ci aiuta a migliorare Be Well per te.';
  String get feedbackHint => 'Scrivi qui il tuo feedback…';
  String get feedbackSubmit => 'Invia feedback';
  String get feedbackThanks => 'Grazie per il tuo feedback!';
  String get feedbackError => 'Invio non riuscito, riprova tra poco';
  String get feedbackCategoryBug => 'Bug';
  String get feedbackCategoryIdea => 'Idea';
  String get feedbackCategoryFeature => 'Funzionalità';
  String get feedbackCategoryOther => 'Altro';

  String spotlightText(String id) {
    switch (id) {
      case 'home_welcome':    return 'Benvenuto! Sono Welly. Ti mostro tutto così puoi iniziare nel modo giusto.';
      case 'home_water':      return 'Questa è la tua prima abitudine: bere acqua. 8 bicchieri al giorno è il tuo obiettivo. Semplice e potente.';
      case 'home_add_glass':  return 'Tocca qui ogni volta che bevi un bicchiere. Ogni tap costruisce la tua abitudine — prova subito!';
      case 'home_welly':      return 'Questo sono io — Welly! Cambio espressione in base ai tuoi progressi. Più vai bene, più sono raggiante.';
      case 'home_phase':      return 'Questa è la tua Fase. Parti da Seme — Fase 1. Costruisci abitudini per crescere fino alla Fase 5: Fiorente.';
      case 'home_nav':        return 'Nuove sezioni si sbloccano qui man mano che progredisci. Parti dall\'acqua — tutto il resto si apre da lì.';
      case 'habits_welcome':  return 'Hai sbloccato la schermata Abitudini! Da qui gestisci tutte le tue routine.';
      case 'habits_now':      return 'La card \'Adesso\' mostra l\'abitudine più rilevante per questo preciso momento della tua giornata.';
      case 'habits_list':     return 'Tutte le abitudini sono ordinate per l\'orario migliore. Quelle mattutine compaiono prime al mattino — Welly conosce il tuo ritmo.';
      case 'habits_ready':      return 'Pronto! Tocca \'Completa\' ogni giorno per costruire la tua streak. Piccole azioni, fatte con costanza, cambiano tutto.';
      // Marketplace tour
      case 'marketplace_welcome': return 'Questi sono i tuoi Premi Be Well! Ogni bicchiere d\'acqua, ogni abitudine completata ti porta qui — dove i tuoi sforzi diventano ricompense reali.';
      case 'marketplace_points':  return 'Il tuo saldo punti è sempre visibile qui. Si accumula automaticamente mentre costruisci le abitudini — senza fare niente di extra.';
      case 'marketplace_tabs':    return 'Tre tab: Premi da riscattare con i punti, Sconti gratuiti, e contenuti In-app da sbloccare. Tutto guadagnato con le tue abitudini quotidiane.';
      case 'marketplace_card':    return 'Ogni premio ha un costo in punti. Tocca per riscattare — ricevi un codice subito. Più sei costante, più sblocchi.';
      // Growth tour
      case 'growth_welcome':      return 'Questa è la tua Crescita. Non è una classifica — è uno specchio. Mostra chi stai diventando, non solo cosa fai.';
      case 'growth_phase':        return 'La tua fase riflette quanto le abitudini sono radicate. Dalla Fase 1 (Seme) alla Fase 5 (Radioso) — ogni passo è un cambiamento neurologico reale, non un livello di gioco.';
      case 'growth_heatmap':      return 'Questa heatmap mostra la tua consistenza nel tempo. La scienza dice che il pattern conta più dell\'intensità: qualche giorno mancato non azzera tutto.';
      case 'growth_badges':       return 'I badge non sono decorazioni. Ognuno corrisponde a un comportamento mantenuto per un periodo misurabile. Sono prove concrete del tuo percorso.';
      default: return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitStartsTomorrow(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':     return 'Benvenuto! Questa è la tua base. In cima trovi sempre l\'abitudine più urgente per adesso. Inizia sempre da lì — il resto può aspettare.';
      case 'home_first_open_2':   return 'L\'acqua è la prima abitudine perché è la base biologica di tutto il resto. Senza idratazione, la concentrazione cala fino al 20% già dopo 90 minuti.';
      case 'water_tracker_first': return 'Il tracker conta i bicchieri da quando apri l\'app ogni mattina. 8 al giorno è il target — ma anche arrivare a 5 è già meglio di ieri.';
      case 'first_completion':    return 'Fatto! Ogni completamento crea una connessione neurale nuova. Piccola, ma reale. Il tuo cervello ha appena rinforzato un circuito.';
      case 'streak_explain':      return 'Se torni domani, inizia la tua streak. L\'unica regola che conta: non saltare mai due giorni di fila. Uno stop è umano. Due sono un\'abitudine nuova — quella sbagliata.';
      case 'habits_tab_first':    return 'Qui trovi tutte le abitudini ordinate per il momento migliore della tua giornata. Welly conosce i tuoi ritmi — le abitudini mattutine si mostrano di mattina, quelle serali di sera.';
      case 'habit_card_explain':  return 'L\'arco circolare in basso a sinistra si riempie ogni volta che completi. A 7 giorni scatta qualcosa di interessante — il tuo cervello inizia a registrarla come routina.';
      case 'focus_unlocked':      return 'Hai a disposizione il Focus da 25 minuti fin da subito! Il cervello umano ha un ciclo naturale di concentrazione di circa 20–30 minuti — usalo per un blocco di lavoro senza distrazioni.';
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
  String get registerSubtitle => 'Commencez votre parcours bien-être';
  String get tosAccept => 'J\'accepte les ';
  String get tosTerms => 'Conditions d\'utilisation';
  String get tosAnd => ' et la ';
  String get tosPrivacy => 'Politique de confidentialité';
  String get tosSuffix => ' de Be Well';
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
  String get firstHabitBody1 => 'Seulement 2% de déshydratation suffisent à réduire la concentration et l\'humeur.';
  String get firstHabitBody2 => 'On commence ici : 8 verres par jour. Je vous rappellerai quand boire, puis nous ajouterons de nouvelles habitudes pas à pas.';
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
  String get greetingFallbackName => 'à toi';
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
  String get notifHabitTitle => '🌱 Be Well';
  String get notifHabitBody => 'C\'est le moment de travailler tes habitudes — même une petite action compte.';
  String get notifHabitChoiceTitle => '✨ Nouvelle habitude disponible';
  String get notifHabitChoiceBody => 'Ouvre Be Well pour choisir ta prochaine habitude.';

  String get notifFrequencyLabel => 'Fréquence des rappels';
  String get notifFreqOff => 'Aucun';
  String get notifFreqLow => 'Peu';
  String get notifFreqNormal => 'Normal';
  String get notifFreqHigh => 'Tous';
  String get notifFreqOffDesc => 'Aucun rappel';
  String get notifFreqLowDesc => '2 par jour — matin et soir';
  String get notifFreqNormalDesc => '4 par jour, répartis dans la journée';
  String get notifFreqHighDesc => 'Toutes les ~2h aux heures d\'éveil';
  String get notifSnoozeLabel => 'Mettre les rappels en pause';
  String notifSnoozeActive(String until) => 'En pause jusqu\'à $until';
  String get notifSnoozeCancel => 'Reprendre maintenant';
  String notifSnoozeHours(int h) => '$h h';

  String get navHome => 'Accueil';
  String get navHabits => 'Habitudes';
  String get navFocus => 'Focus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Récompenses';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Débloque dans';
  String get navUnlockHabitsMsg => 'Complétez 14 jours d\'eau pour débloquer les habitudes.';
  String get navUnlockGrowthMsg => 'Continuez à construire des habitudes pour débloquer la croissance.';
  String get comingSoonHabitsDesc => 'Complétez 14 jours d\'eau.\nVotre première nouvelle habitude se débloquera ici.';
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
  String get breathingInhale => 'Inspirez';
  String get breathingHold => 'Retenez';
  String get breathingExhale => 'Expirez';
  String get breathingCycles => 'Cycles :';
  String get breathingTapToStart => 'Touchez pour\ncommencer';
  String get breathingStart => 'Commencer';
  String get breathingStop => 'Arrêter';
  String get breathingAgain => 'Encore';
  String get breathingWellDone => '🌿 Bravo !';
  String breathingCyclesCompleted(int n) => '$n cycles terminés.';
  String breathingPointsEarned(int pts) => '+$pts points ⭐';

  String get guideTapToStart => 'Touchez pour\ncommencer';
  String get guideStart => 'Démarrer la séquence';
  String get guideWellDone => '💪 Bravo !';
  String guideStepProgress(int i, int total) => 'Étape $i sur $total';
  String guideStepsCompleted(int n) => '$n étapes terminées.';
  String get guideDeskStep1 => 'Rotations d\'épaules arrière × 5';
  String get guideDeskStep2 => 'Torsion du dos assis × 3 de chaque côté';
  String get guideDeskStep3 => 'Cercles poignets et avant-bras × 10';
  String get guideDeskStep4 => 'Inclinaison latérale du cou × 3 de chaque côté';
  String get guideDeskStep5 => 'Cat-cow assis × 5';
  String get guideNeckStep1 => 'Rotations lentes du cou × 5 dans chaque sens';
  String get guideNeckStep2 => 'Haussements d\'épaules × 8';
  String get guideNeckStep3 => 'Étirement latéral du cou × 3 de chaque côté';
  String get guideStretchStep1 => 'Bras tendus vers le haut × 5';
  String get guideStretchStep2 => 'Flexion latérale du buste × 3 de chaque côté';
  String get guideStretchStep3 => 'Cercles de hanches × 8';
  String get guideStretchStep4 => 'Montées sur pointes × 10';
  String get guideStretchStep5 => 'Flexion avant debout × 20s';

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
  String get badgeRootedName => 'Habitudes enracinées';
  String get badgeRootedDesc => 'Habitudes devenues une seconde nature';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Argent';
  String get badgeTierGold => 'Or';
  String get growthNextGoal => 'Prochain objectif';
  String growthHabitsToRoot(int n) => n == 1 ? 'Encore 1 habitude' : 'Encore $n habitudes';

  String get habitChoiceTitle => 'Il est temps d\'ajouter\nquelque chose de nouveau.';
  String get habitChoiceSub => 'Choisissez où vous concentrer.';
  String get habitChoiceShowOther => 'voir d\'autres options ›';
  String get habitChoiceNotReady => 'Je ne suis pas encore prêt(e)';
  String get habitChoiceOpen => 'Choisir votre prochaine habitude';
  String get habitNotReadySnoozed => 'Pas de souci — je te le redemanderai dans une semaine.';
  String get consolidatedTitle => '🏆 Félicitations !';
  String consolidatedBody(String habitName) => 'Tu as fait de « $habitName » une vraie habitude — ton cerveau a construit un circuit durable pour elle.';
  String get consolidatedBadge => 'Habitude consolidée';
  String get consolidatedCta => 'Continuer';
  String habitStartsTomorrow(String habitName) => 'Très bien ! Profite de ta réussite aujourd\'hui — on commencera à travailler sur « $habitName » demain.';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'modéré';
  String get habitEffortHigh => 'exigeant';

  String get errorNetwork => 'Pas de connexion internet';
  String get errorGeneral => 'Quelque chose s\'est mal passé. Réessayez.';
  String get errorInvalidEmail => 'Adresse email invalide';
  String get errorWeakPassword => 'Le mot de passe est trop faible';
  String get errorEmailInUse => 'Cet email est déjà utilisé';
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect';
  String get errorTooManyAttempts => 'Trop de tentatives. Compte temporairement bloqué';
  String get errorTimeout => 'Le serveur ne répond pas. Réessayez bientôt';
  String get errorCancelled => 'Connexion annulée';
  String get errorAccountDisabled => 'Compte désactivé. Contactez le support';
  String get passwordStrengthWeak => 'Faible';
  String get passwordStrengthMedium => 'Moyen';
  String get passwordStrengthStrong => 'Fort';
  String get passwordStrengthVeryStrong => 'Très fort';
  String get validationEmailRequired => 'Entrez votre email';
  String get validationPasswordRequired => 'Entrez un mot de passe';
  String get validationPasswordTooShort => '8 caractères minimum';
  String get validationNameRequired => 'Entrez votre nom';
  String get validationNameTooShort => '2 caractères minimum';
  String get accountLockedBody => 'Trop de tentatives échouées.\nRéessayez dans';
  String get accountLockedEmailSent => 'Vous avez reçu un email avec les instructions.';
  String get offlineLoginRequired => 'Pas de connexion — la connexion nécessite internet';
  String get forgotCheckEmailTitle => 'Vérifiez votre email';
  String forgotEmailSentBody(String email) =>
      'Si un compte existe pour $email, vous recevrez un lien pour réinitialiser le mot de passe.';
  String get forgotLinkExpiry => 'Le lien expire dans 30 minutes.';
  String get forgotResendLimitReached => 'Limite de renvois atteinte';
  String forgotResendIn(int seconds) => 'Renvoyer dans ${seconds}s';
  String get verifyEmailCta => 'Cliquez sur le lien pour activer votre compte.';
  String get verifyResendCta => 'Renvoyer l\'email de vérification';
  String get verifyChecked => 'J\'ai vérifié mon email';
  String get verifyDifferentEmail => 'Utiliser un autre email ?';
  String get verifySendError => 'Échec de l\'envoi, réessayez bientôt';
  String get welcomeSlide1Title => 'Votre plan de\nbien-être personnel';
  String get welcomeSlide1Sub => 'Be Well construit un plan sur mesure pour vous, basé sur vos habitudes et objectifs.';
  String get welcomeSlide2Title => 'Des rappels qui\nconnaissent votre agenda';
  String get welcomeSlide2Sub => 'Les rappels s\'adaptent à vos réunions et horaires, pour ne jamais vous interrompre au mauvais moment.';
  String get welcomeSlide3Title => 'Transformez vos habitudes\nen récompenses réelles';
  String get welcomeSlide3Sub => 'Gagnez des points en complétant des activités et échangez-les contre des réductions, des bons et plus encore.';
  String get welcomeSkip => 'Passer';
  String get welcomeNext => 'Suivant →';
  String get welcomeStart => 'Commencer la configuration →';
  String get welcomeConfigureLater => 'Configurer plus tard';

  String get qProfileTitle => 'Parlez-nous de vous';
  String get qProfileSub => 'Nous aide à construire le bon plan pour vous.';
  String get qGoalsTitle => 'Objectifs & Stress';
  String get qGoalsSub => 'L\'écran le plus important pour personnaliser votre plan.';
  String get qHealthTitle => 'Vos habitudes';
  String get qHealthSub => 'Calibre la fréquence et le type de rappels.';
  String get qScheduleTitle => 'Votre emploi du temps';
  String get qScheduleSub => 'Nous réglerons les rappels aux bons moments.';
  String get qEnvTitle => 'Environnement & Productivité';
  String get qEnvSub => 'Les derniers détails pour votre plan.';
  String get qBuildPlan => 'Terminé ✓';
  String get q1Label => 'Q1 · Je suis principalement…';
  String get q2Label => 'Q2 · Je travaille/étudie principalement…';
  String get q3Label => 'Q3 · Que voulez-vous améliorer ? (plusieurs choix)';
  String get q4Label => 'Q4 · Niveau de stress actuel';
  String get q23Label => 'Q5 · Avez-vous déjà utilisé des apps de bien-être ?';
  String get q15Label => 'Q6 · Je dors habituellement…';
  String get q16Label => 'Q7 · Je bois environ…';
  String get q17Label => 'Q8 · Temps d\'écran (loisirs, hors travail)';
  String get q18Label => 'Q9 · Je fais de l\'exercice…';
  String get q5Label => 'Q10 · Mon emploi du temps est…';
  String get q6Label => 'Q11 · Voulez-vous synchroniser votre calendrier ?';
  String get q7Label => 'Q12 · Combien de rappels par jour ?';
  String get q8Label => 'Q13 · Pause idéale…';
  String get q9q10Label => 'Q14–Q15 · Pause déjeuner';
  String get q11q14Label => 'Q16–Q19 · J\'ai accès à…';
  String get q19Label => 'Q20 · Niveau de distractions dans votre environnement';
  String get q20Label => 'Q21 · Quand êtes-vous le plus concentré ?';
  String get q21Label => 'Q22 · Combien de temps pouvez-vous vous concentrer d\'affilée ?';
  String get q22Label => 'Q23 · Combien de réunions par jour (en moyenne) ?';
  String get q1Student => 'Étudiant(e)';
  String get q1Employee => 'Salarié(e)';
  String get q1Freelancer => 'Freelance';
  String get q1Other => 'Autre';
  String get q1Both => 'Les deux';
  String get q2Home => 'Depuis la maison';
  String get q2Office => 'Au bureau';
  String get q2Hybrid => 'Hybride';
  String get q2Varies => 'Variable';
  String get goalStress => 'Réduire le stress';
  String get goalFocus => 'Améliorer la concentration';
  String get goalHealth => 'Santé générale';
  String get goalSleep => 'Mieux dormir';
  String get goalEnergy => 'Plus d\'énergie';
  String get goalWeight => 'Forme physique';
  String get stress1 => 'Très calme';
  String get stress2 => 'Assez calme';
  String get stress3 => 'Normal';
  String get stress4 => 'Un peu stressé(e)';
  String get stress5 => 'Très stressé(e)';
  String get stressCalmEnd => 'Calme';
  String get stressStressedEnd => 'Stressé';
  String get priorNone => 'Non, jamais';
  String get priorHeadspace => 'Headspace';
  String get priorCalm => 'Calm';
  String get priorMultiple => 'Plusieurs';
  String get priorOther => 'Autre app';
  String get hydroLow => 'faible';
  String get hydroGreat => 'excellent';
  String get exNever => 'Jamais';
  String get ex12x => '1-2x/semaine';
  String get ex34x => '3-4x/semaine';
  String get exDaily => 'Tous les jours';
  String get schedFixed => 'Fixe';
  String get schedFlexible => 'Flexible';
  String get schedShift => 'Par équipes';
  String get schedIrregular => 'Irrégulier';
  String get calNoneLabel => 'Non merci, pas maintenant';
  String get calSyncNote => '✓ Nous demanderons les permissions après confirmation du plan';
  String get remMinimal => 'Minimaux';
  String get remMinimalSub => '~2/jour';
  String get remModerate => 'Modérés';
  String get remModerateSub => '~4/jour';
  String get remFrequent => 'Fréquents';
  String get remFrequentSub => '~6/jour';
  String get remVeryFrequent => 'Très fréq.';
  String get remVeryFrequentSub => '8+/jour';
  String get lunchTimeLabel => 'Heure';
  String get lunchDurationLabel => 'Durée';
  String get resParkLabel => 'Parc ou espace vert';
  String get resParkSub => 'Pour les marches pendant la pause déjeuner';
  String get resGymLabel => 'Salle de sport';
  String get resGymSub => 'Au bureau ou à proximité';
  String get resWindowLabel => 'Fenêtre avec vue';
  String get resWindowSub => 'Pour la règle 20-20-20 des yeux';
  String get resQuietLabel => 'Espace calme';
  String get resQuietSub => 'Pour la méditation et la concentration profonde';
  String get distLow => 'Faible';
  String get distMedium => 'Moyen';
  String get distHigh => 'Élevé';
  String get distVeryHigh => 'Très élevé';
  String get focusMorning => 'Matin';
  String get focusMidday => 'Midi';
  String get focusAfternoon => 'Après-midi';
  String get focusEvening => 'Soir';
  String get meeting02 => '0-2 / jour';
  String get meeting24 => '2-4 / jour';
  String get meeting46 => '4-6 / jour';
  String get meeting6plus => '6+ / jour';
  String get screenTimeWarning => 'Nous activerons des rappels yeux plus fréquents';
  String get crisisTitle => 'Vous traversez un moment difficile';
  String get crisisBody => 'Be Well est là pour vous soutenir. Si vous avez besoin d\'aide immédiate : contactez une ligne d\'écoute locale.';
  String get qOptional => 'facultatif';
  String get qBack => '← Retour';
  String get qSkipAll => 'Tout passer';
  String qOfTotal(int current, int total) => '$current sur $total';
  String get planGenTitle => 'Construction de votre plan…';
  String get planGenSub => 'Application des règles de personnalisation';
  String get planStep1 => 'Analyse de votre profil';
  String get planStep2 => 'Configuration des rappels';
  String get planStep3 => 'Sélection des activités';
  String get planStep4 => 'Configuration du tableau de bord';
  String get planReadyBadge => '🎉 Plan prêt !';
  String get planPreviewTitle => 'Votre plan\nbien-être';
  String get planPreviewSub => 'Personnalisé selon vos réponses. Vous pourrez toujours le modifier depuis les paramètres.';
  String get planRemindersPerDay => 'rappels/jour';
  String get planFocusSessions => 'sessions focus';
  String get planPointsPerDay => 'points/jour';
  String get planMorning => '🌅 Matin';
  String get planAfternoon => '☀️ Après-midi';
  String get planEvening => '🌙 Soir';
  String planFromTime(String time) => 'dès $time';
  String planConnectCalendar(String name) => 'Connecter $name';
  String get planConnectCalendarSub => 'Nous demanderons la permission après confirmation';
  String get planFallbackNote => 'Nous avons utilisé un plan par défaut. Nous l\'affinerons au fur et à mesure.';
  String get planConfirmCta => 'Commencer avec Be Well  ';
  String get planConfirmSub => 'Vous pouvez modifier votre plan à tout moment depuis les paramètres';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Profil';
  String get accountSection => 'Compte';
  String get emailAccountLabel => 'Email du compte';
  String get supportSection => 'Support';
  String get editNameTitle => 'Modifier le nom';
  String get yourNameHint => 'Votre nom';
  String get resetTutorialTitle => 'Réinitialiser le tutoriel';
  String get resetTutorialBody => 'Welly affichera à nouveau tous les dialogues du tutoriel comme si c\'était la première fois. Utile pour tester le parcours.';
  String get resetTutorialCta => 'Réinitialiser';
  String get resetTutorialSnackbar => 'Tutoriel réinitialisé ✓';
  String genericError(String msg) => 'Erreur : $msg';
  String get settingsTitle => 'Paramètres';
  String get styleCardDesc => 'Contenu en cartes,\ntypographie claire';
  String get styleAmbientDesc => 'Paysage atmosphérique,\npolice éditoriale';
  String get toneSection => 'Tonalité';
  String get accessibilitySection => 'Accessibilité';
  String get contrastDesc => 'Augmente le contraste du texte';
  String get textSizeDesc => 'Augmente la taille du texte';
  String get remindersLabel => 'Rappels d\'activités';
  String get remindersDesc => 'Notifications pour les activités planifiées';
  String get comingSoonTitle => 'Bientôt disponible';
  String get comingSoonBody => 'Cette section n\'est pas encore disponible — elle est sur notre feuille de route.';
  String get habitMarkDone => 'Fait';
  String get slowdownReasonHeavy => 'Cette habitude me pèse trop en ce moment';
  String heatmapDaysAgo(int n) => 'il y a $n jours';
  String get heatmapToday => 'aujourd\'hui';
  String phaseStarted(String date) => 'commencé le $date';
  String phaseReached(String date) => 'atteint le $date';
  String get marketAdTitle => 'Aidez Be Well';
  String get marketAdSubtitle => 'Gagnez 10 pts en regardant une pub';
  String get marketAdDialogBody => 'Regardez une pub : vous nous aidez à garder l\'app gratuite et gagnez immédiatement 10 points.';
  String get marketWatchNow => 'Regarder maintenant';
  String get dialogGotIt => 'Compris';
  String get marketAdUnavailable => 'Pub non disponible pour le moment';
  String get referralTitle => 'Inviter un ami';
  String get referralSubtitle => 'Gagnez 50 pts pour chaque ami qui s\'inscrit';
  String get referralApply => 'Appliquer';
  String get referralApplied => 'Code appliqué ! Votre ami recevra bientôt le bonus. 🎉';
  String get referralErrorInvalid => 'Code invalide';
  String get referralErrorOwn => 'Vous ne pouvez pas utiliser votre propre code';
  String get referralErrorAlready => 'Vous avez déjà utilisé un code d\'invitation';
  String get referralErrorNotSignedIn => 'Vous devez être connecté';
  String get referralErrorGeneric => 'Une erreur est survenue, réessayez';
  String get referralHint => 'Vous avez un code d\'invitation ?';
  String premiumPrice(String price) => '$price/mois';
  String referralShareButton(String code) => 'Partager mon code · $code';
  String get referralRetry => 'Échec de la génération du code — appuyez pour réessayer';
  String referralShareMessage(String code) =>
      'J\'utilise Be Well pour construire des habitudes plus saines, jour après jour 🌱\n'
      'Téléchargez l\'app et utilisez mon code d\'invitation "$code" — vous recevrez 50 points bonus dès votre inscription !';

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
  String get configuratorTitle => 'Personnalise ton plan';
  String get configuratorSubtitle => 'Réponds à quelques questions pour recevoir des suggestions d\'habitudes adaptées';
  String get configuratorDoneTitle => 'Ton plan est personnalisé';
  String get configuratorDoneSubtitle => 'Touche pour mettre à jour tes réponses';
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
  String get slowdownMenuSubtitle => 'Les nouvelles suggestions d\'habitudes sont mises en pause pendant 2 semaines — celle-ci reste dans ton plan.';
  String get slowdownWellyResponse => 'Pas de problème — les nouvelles suggestions sont en pause pendant 2 semaines. Cette habitude reste dans ton plan, prends le temps qu\'il te faut.';
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
  String get tutorialNext => 'Suivant →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable         => 'points disponibles';
  String get marketplaceTabRewards   => 'Récompenses';
  String get marketplaceTabDiscounts => 'Réductions';
  String get marketplaceTabInApp     => 'In-app';
  String get rewardsToRedeem         => 'à échanger';
  String get rewardRedeemed          => 'Le voilà. Tu l\'as mérité.';
  String get rewardConfirmTitle      => 'Êtes-vous sûr ?';
  String get rewardConfirmBody       => 'X points seront déduits de votre solde.';
  String get rewardRedeemFailed => 'Impossible d\'échanger cette récompense — points insuffisants, ou elle n\'est plus disponible.';
  String get copyCode                => 'Copier le code';
  String get codeCopied              => 'Copié';
  String get watchAd                 => 'Regarder une pub · +10 pt';
  String get whyAds                  => 'pourquoi ?';
  String get whyAdsTitle             => 'Be Well est gratuit pour tous';
  String get whyAdsBody              => 'Be Well est une application gratuite pour être accessible à tous. Comme tout service, elle a des coûts de fonctionnement. En regardant les publicités quand vous le pouvez, vous nous aidez à maintenir le service actif et à l\'améliorer pour tous. Merci.';
  String get discountsActive         => 'réductions actives';
  String get discountsNote           => 'Les réductions sont mises à jour chaque mois. Aucun point requis.';
  String get discountExclusive       => 'exclusif Be Well';
  String get goToSite                => 'Aller sur le site';
  String get affiliateNote           => 'Ce lien soutient Be Well';
  String get inAppWelly              => 'welly';
  String get inAppSoundscape         => 'soundscape';
  String get inAppMinigame           => 'minijeu';
  String get inAppPercorsi           => 'parcours';
  String get unlockItem              => 'Débloquer';
  String get itemUnlocked            => 'Débloqué';
  String get premiumAllContent       => 'Tous les contenus in-app inclus';
  String get premiumPoints           => '+20% de points pour chaque habitude';
  String get premiumWelly            => 'Welly entièrement personnalisable';
  String get premiumDiscounts        => 'Réductions exclusives en avant-première';
  String get premiumTrial            => 'Essayez 7 jours gratuits';
  String get premiumOr               => 'ou achetez individuellement avec des points';

  String get feedbackTitle => 'Laisser un avis';
  String get feedbackSubtitle => 'Cela nous aide à améliorer Be Well pour vous.';
  String get feedbackHint => 'Écrivez votre avis ici…';
  String get feedbackSubmit => 'Envoyer';
  String get feedbackThanks => 'Merci pour votre avis !';
  String get feedbackError => 'Échec de l\'envoi, réessayez bientôt';
  String get feedbackCategoryBug => 'Bug';
  String get feedbackCategoryIdea => 'Idée';
  String get feedbackCategoryFeature => 'Fonctionnalité';
  String get feedbackCategoryOther => 'Autre';

  String spotlightText(String id) {
    switch (id) {
      case 'home_welcome':    return 'Bienvenue ! Je suis Welly. Laisse-moi te montrer tout ça pour bien commencer.';
      case 'home_water':      return 'Voici ta première habitude : boire de l\'eau. 8 verres par jour est ton objectif. Simple et puissant.';
      case 'home_add_glass':  return 'Appuie ici chaque fois que tu bois un verre. Chaque tap construit ton habitude — essaie maintenant !';
      case 'home_welly':      return 'C\'est moi — Welly ! Je change d\'expression selon tes progrès. Plus tu avances, plus je rayonne.';
      case 'home_phase':      return 'C\'est ta Phase. Tu commences à Graine — Phase 1. Construis des habitudes pour atteindre la Phase 5 : Radieux.';
      case 'home_nav':        return 'De nouvelles sections se débloquent ici au fil de tes progrès. Commence par l\'eau — tout le reste s\'ouvre à partir de là.';
      case 'habits_welcome':  return 'Tu as débloqué l\'écran Habitudes ! D\'ici tu gères toutes tes routines.';
      case 'habits_now':      return 'La carte \'Maintenant\' montre l\'habitude la plus pertinente pour ce moment précis de ta journée.';
      case 'habits_list':     return 'Toutes les habitudes sont triées par leur meilleur moment. Les habitudes matinales apparaissent en premier le matin — Welly connaît ton rythme.';
      case 'habits_ready':      return 'Prêt ! Appuie sur \'Terminé\' chaque jour pour construire ta série. De petites actions, faites régulièrement, changent tout.';
      // Marketplace tour
      case 'marketplace_welcome': return 'Voici tes Récompenses Be Well ! Chaque verre d\'eau, chaque habitude accomplie t\'amène ici — là où tes efforts deviennent de vraies récompenses.';
      case 'marketplace_points':  return 'Ton solde de points est toujours visible ici. Il s\'accumule automatiquement pendant que tu construis tes habitudes.';
      case 'marketplace_tabs':    return 'Trois onglets : Récompenses à échanger avec des points, Réductions gratuites, et contenus In-app à débloquer. Tout gagné grâce à tes habitudes.';
      case 'marketplace_card':    return 'Chaque récompense a un coût en points. Appuie pour échanger — tu reçois un code instantanément. Plus tu es régulier, plus tu débloque.';
      // Growth tour
      case 'growth_welcome':      return 'Voici ta Croissance. Ce n\'est pas un classement — c\'est un miroir. Il montre qui tu deviens, pas seulement ce que tu fais.';
      case 'growth_phase':        return 'Ta phase reflète à quel point tes habitudes sont enracinées. De la Phase 1 (Graine) à la Phase 5 (Radieux) — chaque étape est un vrai changement neurologique.';
      case 'growth_heatmap':      return 'Cette heatmap montre ta régularité dans le temps. La science dit que le schéma compte plus que l\'intensité : quelques jours manqués ne remettent pas tout à zéro.';
      case 'growth_badges':       return 'Les badges ne sont pas des décorations. Chacun correspond à un comportement maintenu pendant une période mesurable. Ce sont des preuves concrètes de ton parcours.';
      default: return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitStartsTomorrow(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':     return 'Bienvenue ! Voici ta base. En haut, tu trouveras toujours l\'habitude la plus urgente du moment. Commence toujours par là — le reste peut attendre.';
      case 'home_first_open_2':   return 'L\'eau est la première habitude parce que c\'est le fondement biologique de tout le reste. Sans hydratation, la concentration chute jusqu\'à 20 % après seulement 90 minutes.';
      case 'water_tracker_first': return 'Le tracker compte les verres depuis l\'ouverture de l\'app chaque matin. 8 par jour est l\'objectif — mais même atteindre 5, c\'est déjà mieux qu\'hier.';
      case 'first_completion':    return 'Fait ! Chaque accomplissement crée une nouvelle connexion neurale. Petite, mais réelle. Ton cerveau vient de renforcer un circuit.';
      case 'streak_explain':      return 'Si tu reviens demain, ta série commence. La seule règle qui compte : ne jamais sauter deux jours de suite. Un arrêt, c\'est humain. Deux, c\'est une nouvelle habitude — la mauvaise.';
      case 'habits_tab_first':    return 'Ici tu trouves toutes tes habitudes organisées pour le meilleur moment de ta journée. Welly connaît tes rythmes — les habitudes matinales apparaissent le matin, celles du soir le soir.';
      case 'habit_card_explain':  return 'L\'arc circulaire se remplit chaque fois que tu complètes. À 7 jours, quelque chose d\'intéressant se passe — ton cerveau commence à l\'enregistrer comme une routine.';
      case 'focus_unlocked':      return 'Tu as le Focus de 25 minutes disponible dès le départ ! Le cerveau humain a un cycle naturel de concentration d\'environ 20–30 minutes — utilise-le pour un bloc de travail sans distraction.';
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
  String get registerSubtitle => 'Starte deine Wellness-Reise';
  String get tosAccept => 'Ich akzeptiere die ';
  String get tosTerms => 'Nutzungsbedingungen';
  String get tosAnd => ' und die ';
  String get tosPrivacy => 'Datenschutzerklärung';
  String get tosSuffix => ' von Be Well';
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
  String get firstHabitBody1 => 'Schon 2% Dehydrierung senken Konzentration und Stimmung — die meisten trinken zu wenig.';
  String get firstHabitBody2 => 'Wir beginnen hier: 8 Gläser täglich. Ich erinnere dich ans Trinken, dann fügen wir Schritt für Schritt neue Gewohnheiten hinzu.';
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
  String get greetingFallbackName => 'dir';
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
  String get notifHabitTitle => '🌱 Be Well';
  String get notifHabitBody => 'Zeit, an deinen Gewohnheiten zu arbeiten — auch eine kleine Aktion zählt.';
  String get notifHabitChoiceTitle => '✨ Neue Gewohnheit verfügbar';
  String get notifHabitChoiceBody => 'Öffne Be Well, um deine nächste Gewohnheit zu wählen.';

  String get notifFrequencyLabel => 'Erinnerungsfrequenz';
  String get notifFreqOff => 'Aus';
  String get notifFreqLow => 'Wenige';
  String get notifFreqNormal => 'Normal';
  String get notifFreqHigh => 'Alle';
  String get notifFreqOffDesc => 'Keine Erinnerungen';
  String get notifFreqLowDesc => '2 pro Tag — morgens und abends';
  String get notifFreqNormalDesc => '4 pro Tag, über den Tag verteilt';
  String get notifFreqHighDesc => 'Alle ~2h während der Wachzeit';
  String get notifSnoozeLabel => 'Erinnerungen pausieren';
  String notifSnoozeActive(String until) => 'Pausiert bis $until';
  String get notifSnoozeCancel => 'Jetzt fortsetzen';
  String notifSnoozeHours(int h) => '$h h';

  String get navHome => 'Startseite';
  String get navHabits => 'Gewohnheiten';
  String get navFocus => 'Fokus';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Belohnungen';
  String get navProfile => 'Profil';
  String get navUnlockIn => 'Freischalten in';
  String get navUnlockHabitsMsg => 'Schließe 14 Tage Wasser ab, um Gewohnheiten freizuschalten.';
  String get navUnlockGrowthMsg => 'Baue weiter Gewohnheiten auf, um das Wachstum freizuschalten.';
  String get comingSoonHabitsDesc => 'Schließe 14 Wassertage ab.\nDeine erste neue Gewohnheit schaltet sich hier frei.';
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
  String get breathingInhale => 'Einatmen';
  String get breathingHold => 'Halten';
  String get breathingExhale => 'Ausatmen';
  String get breathingCycles => 'Zyklen:';
  String get breathingTapToStart => 'Tippen zum\nStarten';
  String get breathingStart => 'Atmung starten';
  String get breathingStop => 'Stopp';
  String get breathingAgain => 'Nochmal';
  String get breathingWellDone => '🌿 Gut gemacht!';
  String breathingCyclesCompleted(int n) => '$n Zyklen abgeschlossen.';
  String breathingPointsEarned(int pts) => '+$pts Punkte ⭐';

  String get guideTapToStart => 'Tippen zum\nStarten';
  String get guideStart => 'Sequenz starten';
  String get guideWellDone => '💪 Gut gemacht!';
  String guideStepProgress(int i, int total) => 'Schritt $i von $total';
  String guideStepsCompleted(int n) => '$n Schritte abgeschlossen.';
  String get guideDeskStep1 => 'Schulterkreisen rückwärts × 5';
  String get guideDeskStep2 => 'Sitzende Rumpfdrehung × 3 pro Seite';
  String get guideDeskStep3 => 'Handgelenk- und Unterarmkreisen × 10';
  String get guideDeskStep4 => 'Seitliche Nackenneigung × 3 pro Seite';
  String get guideDeskStep5 => 'Sitzende Katze-Kuh × 5';
  String get guideNeckStep1 => 'Langsames Nackenkreisen × 5 pro Richtung';
  String get guideNeckStep2 => 'Schulterheben und Loslassen × 8';
  String get guideNeckStep3 => 'Seitliche Nackendehnung × 3 pro Seite';
  String get guideStretchStep1 => 'Arme nach oben strecken × 5';
  String get guideStretchStep2 => 'Seitliche Rumpfbeuge × 3 pro Seite';
  String get guideStretchStep3 => 'Hüftkreisen × 8';
  String get guideStretchStep4 => 'Wadenheben × 10';
  String get guideStretchStep5 => 'Stehende Vorbeuge × 20s';

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
  String get badgeRootedName => 'Verwurzelte Gewohnheiten';
  String get badgeRootedDesc => 'Gewohnheiten, die zur zweiten Natur wurden';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Silber';
  String get badgeTierGold => 'Gold';
  String get growthNextGoal => 'Nächstes Ziel';
  String growthHabitsToRoot(int n) => n == 1 ? 'Noch 1 Gewohnheit' : 'Noch $n Gewohnheiten';

  String get habitChoiceTitle => 'Zeit für etwas Neues.';
  String get habitChoiceSub => 'Wähle, worauf du dich jetzt konzentrierst.';
  String get habitChoiceShowOther => 'andere Optionen zeigen ›';
  String get habitChoiceNotReady => 'Ich bin noch nicht bereit dafür';
  String get habitChoiceOpen => 'Nächste Gewohnheit wählen';
  String get habitNotReadySnoozed => 'Kein Problem — ich frage in einer Woche noch einmal.';
  String get consolidatedTitle => '🏆 Glückwunsch!';
  String consolidatedBody(String habitName) => 'Du hast „$habitName" zu einer echten Gewohnheit gemacht — dein Gehirn hat dafür einen dauerhaften Schaltkreis aufgebaut.';
  String get consolidatedBadge => 'Gewohnheit gefestigt';
  String get consolidatedCta => 'Weiter';
  String habitStartsTomorrow(String habitName) => 'Sehr gut! Genieße heute deinen Erfolg — wir beginnen morgen mit „$habitName".';
  String get habitEffortLow => 'leicht';
  String get habitEffortMedium => 'moderat';
  String get habitEffortHigh => 'anspruchsvoll';

  String get errorNetwork => 'Keine Internetverbindung';
  String get errorGeneral => 'Etwas ist schiefgelaufen. Versuche es erneut.';
  String get errorInvalidEmail => 'Ungültige E-Mail-Adresse';
  String get errorWeakPassword => 'Das Passwort ist zu schwach';
  String get errorEmailInUse => 'Diese E-Mail wird bereits verwendet';
  String get errorInvalidCredentials => 'Falsche E-Mail oder falsches Passwort';
  String get errorTooManyAttempts => 'Zu viele Versuche. Konto vorübergehend gesperrt';
  String get errorTimeout => 'Der Server antwortet nicht. Versuche es gleich nochmal';
  String get errorCancelled => 'Anmeldung abgebrochen';
  String get errorAccountDisabled => 'Konto deaktiviert. Kontaktiere den Support';
  String get passwordStrengthWeak => 'Schwach';
  String get passwordStrengthMedium => 'Mittel';
  String get passwordStrengthStrong => 'Stark';
  String get passwordStrengthVeryStrong => 'Sehr stark';
  String get validationEmailRequired => 'Gib deine E-Mail ein';
  String get validationPasswordRequired => 'Gib ein Passwort ein';
  String get validationPasswordTooShort => 'Mindestens 8 Zeichen';
  String get validationNameRequired => 'Gib deinen Namen ein';
  String get validationNameTooShort => 'Mindestens 2 Zeichen';
  String get accountLockedBody => 'Zu viele fehlgeschlagene Versuche.\nVersuch es erneut in';
  String get accountLockedEmailSent => 'Du hast eine E-Mail mit den Anweisungen erhalten.';
  String get offlineLoginRequired => 'Keine Verbindung — Anmeldung erfordert Internet';
  String get forgotCheckEmailTitle => 'Überprüfe deine E-Mail';
  String forgotEmailSentBody(String email) =>
      'Falls ein Konto für $email existiert, erhältst du einen Link zum Zurücksetzen des Passworts.';
  String get forgotLinkExpiry => 'Der Link läuft in 30 Minuten ab.';
  String get forgotResendLimitReached => 'Wiederholungslimit erreicht';
  String forgotResendIn(int seconds) => 'Erneut senden in ${seconds}s';
  String get verifyEmailCta => 'Klicke auf den Link, um dein Konto zu aktivieren.';
  String get verifyResendCta => 'Bestätigungs-E-Mail erneut senden';
  String get verifyChecked => 'Ich habe meine E-Mail bestätigt';
  String get verifyDifferentEmail => 'Andere E-Mail verwenden?';
  String get verifySendError => 'Senden fehlgeschlagen, versuch es gleich nochmal';
  String get welcomeSlide1Title => 'Dein persönlicher\nWellness-Plan';
  String get welcomeSlide1Sub => 'Be Well erstellt einen maßgeschneiderten Plan basierend auf deinen Gewohnheiten und Zielen.';
  String get welcomeSlide2Title => 'Erinnerungen, die\ndeinen Kalender kennen';
  String get welcomeSlide2Sub => 'Erinnerungen passen sich deinen Terminen und Zeiten an, damit sie dich nie zur falschen Zeit unterbrechen.';
  String get welcomeSlide3Title => 'Verwandle Gewohnheiten\nin echte Belohnungen';
  String get welcomeSlide3Sub => 'Sammle Punkte durch das Abschließen von Aktivitäten und tausche sie gegen Rabatte, Gutscheine und mehr.';
  String get welcomeSkip => 'Überspringen';
  String get welcomeNext => 'Weiter →';
  String get welcomeStart => 'Einrichtung starten →';
  String get welcomeConfigureLater => 'Später einrichten';

  String get qProfileTitle => 'Erzähl uns von dir';
  String get qProfileSub => 'Hilft uns, den richtigen Plan für dich zu erstellen.';
  String get qGoalsTitle => 'Ziele & Stress';
  String get qGoalsSub => 'Der wichtigste Bildschirm zur Personalisierung deines Plans.';
  String get qHealthTitle => 'Deine Gewohnheiten';
  String get qHealthSub => 'Kalibriert Häufigkeit und Art der Erinnerungen.';
  String get qScheduleTitle => 'Dein Zeitplan';
  String get qScheduleSub => 'Wir setzen Erinnerungen zu den richtigen Zeiten.';
  String get qEnvTitle => 'Umgebung & Produktivität';
  String get qEnvSub => 'Die letzten Details für deinen Plan.';
  String get qBuildPlan => 'Fertig ✓';
  String get q1Label => 'Q1 · Ich bin hauptsächlich…';
  String get q2Label => 'Q2 · Ich arbeite/studiere hauptsächlich…';
  String get q3Label => 'Q3 · Was möchtest du verbessern? (mehrere)';
  String get q4Label => 'Q4 · Aktuelles Stresslevel';
  String get q23Label => 'Q5 · Hast du schon Wellness-Apps genutzt?';
  String get q15Label => 'Q6 · Ich schlafe normalerweise…';
  String get q16Label => 'Q7 · Ich trinke etwa…';
  String get q17Label => 'Q8 · Bildschirmzeit (Freizeit, ohne Arbeit)';
  String get q18Label => 'Q9 · Ich mache Sport…';
  String get q5Label => 'Q10 · Mein Zeitplan ist…';
  String get q6Label => 'Q11 · Möchtest du deinen Kalender synchronisieren?';
  String get q7Label => 'Q12 · Wie viele Erinnerungen pro Tag?';
  String get q8Label => 'Q13 · Ideale Pause…';
  String get q9q10Label => 'Q14–Q15 · Mittagspause';
  String get q11q14Label => 'Q16–Q19 · Ich habe Zugang zu…';
  String get q19Label => 'Q20 · Ablenkungsgrad in deiner Umgebung';
  String get q20Label => 'Q21 · Wann bist du am konzentriertesten?';
  String get q21Label => 'Q22 · Wie lange kannst du dich am Stück konzentrieren?';
  String get q22Label => 'Q23 · Wie viele Meetings hast du täglich (im Schnitt)?';
  String get q1Student => 'Student(in)';
  String get q1Employee => 'Angestellte(r)';
  String get q1Freelancer => 'Freelancer';
  String get q1Other => 'Sonstiges';
  String get q1Both => 'Beides';
  String get q2Home => 'Von zu Hause';
  String get q2Office => 'Im Büro';
  String get q2Hybrid => 'Hybrid';
  String get q2Varies => 'Wechselnd';
  String get goalStress => 'Stress reduzieren';
  String get goalFocus => 'Fokus verbessern';
  String get goalHealth => 'Allgemeine Gesundheit';
  String get goalSleep => 'Besser schlafen';
  String get goalEnergy => 'Mehr Energie';
  String get goalWeight => 'Fitness';
  String get stress1 => 'Sehr ruhig';
  String get stress2 => 'Ziemlich ruhig';
  String get stress3 => 'Normal';
  String get stress4 => 'Etwas gestresst';
  String get stress5 => 'Sehr gestresst';
  String get stressCalmEnd => 'Ruhig';
  String get stressStressedEnd => 'Gestresst';
  String get priorNone => 'Nein, nie';
  String get priorHeadspace => 'Headspace';
  String get priorCalm => 'Calm';
  String get priorMultiple => 'Mehrere';
  String get priorOther => 'Andere App';
  String get hydroLow => 'wenig';
  String get hydroGreat => 'optimal';
  String get exNever => 'Nie';
  String get ex12x => '1-2x/Woche';
  String get ex34x => '3-4x/Woche';
  String get exDaily => 'Täglich';
  String get schedFixed => 'Fest';
  String get schedFlexible => 'Flexibel';
  String get schedShift => 'Schicht';
  String get schedIrregular => 'Unregelmäßig';
  String get calNoneLabel => 'Nein danke, jetzt nicht';
  String get calSyncNote => '✓ Wir fragen nach der Berechtigung, sobald du deinen Plan bestätigt hast';
  String get remMinimal => 'Minimal';
  String get remMinimalSub => '~2/Tag';
  String get remModerate => 'Moderat';
  String get remModerateSub => '~4/Tag';
  String get remFrequent => 'Häufig';
  String get remFrequentSub => '~6/Tag';
  String get remVeryFrequent => 'Sehr häufig';
  String get remVeryFrequentSub => '8+/Tag';
  String get lunchTimeLabel => 'Uhrzeit';
  String get lunchDurationLabel => 'Dauer';
  String get resParkLabel => 'Park oder Grünfläche';
  String get resParkSub => 'Für Spaziergänge in der Mittagspause';
  String get resGymLabel => 'Fitnessstudio oder Sportbereich';
  String get resGymSub => 'Im Büro oder in der Nähe';
  String get resWindowLabel => 'Fenster mit Aussicht';
  String get resWindowSub => 'Für die 20-20-20-Augenregel';
  String get resQuietLabel => 'Ruhiger Ort';
  String get resQuietSub => 'Für Meditation und tiefe Konzentration';
  String get distLow => 'Niedrig';
  String get distMedium => 'Mittel';
  String get distHigh => 'Hoch';
  String get distVeryHigh => 'Sehr hoch';
  String get focusMorning => 'Morgen';
  String get focusMidday => 'Mittag';
  String get focusAfternoon => 'Nachmittag';
  String get focusEvening => 'Abend';
  String get meeting02 => '0-2 / Tag';
  String get meeting24 => '2-4 / Tag';
  String get meeting46 => '4-6 / Tag';
  String get meeting6plus => '6+ / Tag';
  String get screenTimeWarning => 'Wir aktivieren häufigere Augen-Erinnerungen';
  String get crisisTitle => 'Du machst gerade eine schwere Zeit durch';
  String get crisisBody => 'Be Well ist da, um dich zu unterstützen. Bei akutem Bedarf: kontaktiere eine lokale Hilfshotline.';
  String get qOptional => 'optional';
  String get qBack => '← Zurück';
  String get qSkipAll => 'Alles überspringen';
  String qOfTotal(int current, int total) => '$current von $total';
  String get planGenTitle => 'Dein Plan wird erstellt…';
  String get planGenSub => 'Wir wenden deine Personalisierungsregeln an';
  String get planStep1 => 'Analysiere dein Profil';
  String get planStep2 => 'Konfiguriere Erinnerungen';
  String get planStep3 => 'Wähle Aktivitäten aus';
  String get planStep4 => 'Richte dein Dashboard ein';
  String get planReadyBadge => '🎉 Plan bereit!';
  String get planPreviewTitle => 'Dein Wellness-\nPlan';
  String get planPreviewSub => 'Personalisiert nach deinen Antworten. Du kannst ihn jederzeit in den Einstellungen ändern.';
  String get planRemindersPerDay => 'Erinnerungen/Tag';
  String get planFocusSessions => 'Fokus-Sessions';
  String get planPointsPerDay => 'Punkte/Tag';
  String get planMorning => '🌅 Morgen';
  String get planAfternoon => '☀️ Nachmittag';
  String get planEvening => '🌙 Abend';
  String planFromTime(String time) => 'ab $time';
  String planConnectCalendar(String name) => '$name verbinden';
  String get planConnectCalendarSub => 'Wir fragen nach der Berechtigung, sobald du bestätigst';
  String get planFallbackNote => 'Wir haben einen Standardplan verwendet. Wir verfeinern ihn, während du die App nutzt.';
  String get planConfirmCta => 'Mit Be Well starten  ';
  String get planConfirmSub => 'Du kannst deinen Plan jederzeit in den Einstellungen ändern';
  String planMinutes(int n) => '$n Min';
  String get profileTitle => 'Profil';
  String get accountSection => 'Konto';
  String get emailAccountLabel => 'Konto-E-Mail';
  String get supportSection => 'Support';
  String get editNameTitle => 'Namen bearbeiten';
  String get yourNameHint => 'Dein Name';
  String get resetTutorialTitle => 'Tutorial zurücksetzen';
  String get resetTutorialBody => 'Welly zeigt alle Tutorial-Dialoge erneut an, als wäre es das erste Mal. Nützlich zum Testen des Ablaufs.';
  String get resetTutorialCta => 'Zurücksetzen';
  String get resetTutorialSnackbar => 'Tutorial zurückgesetzt ✓';
  String genericError(String msg) => 'Fehler: $msg';
  String get settingsTitle => 'Einstellungen';
  String get styleCardDesc => 'Inhalte in Karten,\nklare Typografie';
  String get styleAmbientDesc => 'Atmosphärische Landschaft,\nredaktionelle Schrift';
  String get toneSection => 'Farbton';
  String get accessibilitySection => 'Barrierefreiheit';
  String get contrastDesc => 'Erhöht den Textkontrast';
  String get textSizeDesc => 'Vergrößert die Schriftgröße';
  String get remindersLabel => 'Aktivitätserinnerungen';
  String get remindersDesc => 'Benachrichtigungen für geplante Aktivitäten';
  String get comingSoonTitle => 'Demnächst verfügbar';
  String get comingSoonBody => 'Dieser Bereich ist noch nicht verfügbar — er steht auf unserer Roadmap.';
  String get habitMarkDone => 'Erledigt';
  String get slowdownReasonHeavy => 'Diese Gewohnheit fühlt sich gerade zu viel an';
  String heatmapDaysAgo(int n) => 'vor $n Tagen';
  String get heatmapToday => 'heute';
  String phaseStarted(String date) => 'begonnen am $date';
  String phaseReached(String date) => 'erreicht am $date';
  String get marketAdTitle => 'Unterstütze Be Well';
  String get marketAdSubtitle => 'Verdiene 10 Pkt. durch einen Werbespot';
  String get marketAdDialogBody => 'Schau dir eine Werbung an: du hilfst uns, die App kostenlos zu halten, und erhältst sofort 10 Punkte.';
  String get marketWatchNow => 'Jetzt ansehen';
  String get dialogGotIt => 'Verstanden';
  String get marketAdUnavailable => 'Spot momentan nicht verfügbar';
  String get referralTitle => 'Freund einladen';
  String get referralSubtitle => 'Verdiene 50 Pkt. für jeden Freund, der sich anmeldet';
  String get referralApply => 'Anwenden';
  String get referralApplied => 'Code angewendet! Dein Freund erhält den Bonus bald. 🎉';
  String get referralErrorInvalid => 'Ungültiger Code';
  String get referralErrorOwn => 'Du kannst deinen eigenen Code nicht verwenden';
  String get referralErrorAlready => 'Du hast bereits einen Code eingelöst';
  String get referralErrorNotSignedIn => 'Du musst angemeldet sein';
  String get referralErrorGeneric => 'Etwas ist schiefgelaufen, versuch es erneut';
  String get referralHint => 'Hast du einen Einladungscode?';
  String premiumPrice(String price) => '$price/Monat';
  String referralShareButton(String code) => 'Meinen Code teilen · $code';
  String get referralRetry => 'Code konnte nicht erstellt werden — zum Wiederholen tippen';
  String referralShareMessage(String code) =>
      'Ich nutze Be Well, um Tag für Tag gesündere Gewohnheiten aufzubauen 🌱\n'
      'Lade die App herunter und nutze meinen Einladungscode "$code" — du erhältst 50 Bonuspunkte, sobald du startest!';

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
  String get configuratorTitle => 'Personalisiere deinen Plan';
  String get configuratorSubtitle => 'Beantworte ein paar Fragen für passende Gewohnheitsvorschläge';
  String get configuratorDoneTitle => 'Dein Plan ist personalisiert';
  String get configuratorDoneSubtitle => 'Tippen, um deine Antworten zu aktualisieren';
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
  String get slowdownMenuSubtitle => 'Neue Gewohnheitsvorschläge werden für 2 Wochen pausiert — diese hier bleibt trotzdem in deinem Plan.';
  String get slowdownWellyResponse => 'Kein Problem — neue Vorschläge sind für 2 Wochen pausiert. Diese Gewohnheit bleibt in deinem Plan, nimm dir die Zeit, die du brauchst.';
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
  String get tutorialNext => 'Weiter →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable         => 'Punkte verfügbar';
  String get marketplaceTabRewards   => 'Prämien';
  String get marketplaceTabDiscounts => 'Rabatte';
  String get marketplaceTabInApp     => 'In-App';
  String get rewardsToRedeem         => 'einzulösen';
  String get rewardRedeemed          => 'Da ist es. Du hast es verdient.';
  String get rewardConfirmTitle      => 'Bist du sicher?';
  String get rewardConfirmBody       => 'X Punkte werden von deinem Guthaben abgezogen.';
  String get rewardRedeemFailed => 'Diese Belohnung konnte nicht eingelöst werden — zu wenig Punkte oder nicht mehr verfügbar.';
  String get copyCode                => 'Code kopieren';
  String get codeCopied              => 'Kopiert';
  String get watchAd                 => 'Spot ansehen · +10 Pt';
  String get whyAds                  => 'warum?';
  String get whyAdsTitle             => 'Be Well ist für alle kostenlos';
  String get whyAdsBody              => 'Be Well ist eine kostenlose App, um für alle zugänglich zu sein. Wie jeder Dienst hat es Betriebskosten. Indem du Werbung ansiehst, wenn du kannst, hilfst du uns, den Dienst am Laufen zu halten und ihn für alle zu verbessern. Danke.';
  String get discountsActive         => 'aktive Rabatte';
  String get discountsNote           => 'Rabatte werden monatlich aktualisiert. Keine Punkte erforderlich.';
  String get discountExclusive       => 'exklusiv Be Well';
  String get goToSite                => 'Zur Website';
  String get affiliateNote           => 'Dieser Link unterstützt Be Well';
  String get inAppWelly              => 'welly';
  String get inAppSoundscape         => 'soundscape';
  String get inAppMinigame           => 'minispiel';
  String get inAppPercorsi           => 'pfade';
  String get unlockItem              => 'Freischalten';
  String get itemUnlocked            => 'Freigeschaltet';
  String get premiumAllContent       => 'Alle In-App-Inhalte inklusive';
  String get premiumPoints           => '+20% Punkte für jede Gewohnheit';
  String get premiumWelly            => 'Vollständig anpassbarer Welly';
  String get premiumDiscounts        => 'Exklusive Rabatte vorab';
  String get premiumTrial            => '7 Tage kostenlos testen';
  String get premiumOr               => 'oder einzeln mit Punkten kaufen';

  String get feedbackTitle => 'Feedback geben';
  String get feedbackSubtitle => 'Hilft uns, Be Well für dich zu verbessern.';
  String get feedbackHint => 'Schreib dein Feedback hier…';
  String get feedbackSubmit => 'Feedback senden';
  String get feedbackThanks => 'Danke für dein Feedback!';
  String get feedbackError => 'Senden fehlgeschlagen, versuch es gleich nochmal';
  String get feedbackCategoryBug => 'Bug';
  String get feedbackCategoryIdea => 'Idee';
  String get feedbackCategoryFeature => 'Funktion';
  String get feedbackCategoryOther => 'Sonstiges';

  String spotlightText(String id) {
    switch (id) {
      case 'home_welcome':    return 'Willkommen! Ich bin Welly. Lass mich dir alles zeigen, damit du richtig starten kannst.';
      case 'home_water':      return 'Das ist deine erste Gewohnheit: Wasser trinken. 8 Gläser pro Tag ist dein Ziel. Einfach und wirkungsvoll.';
      case 'home_add_glass':  return 'Tippe hier jedes Mal, wenn du ein Glas trinkst. Jedes Tippen baut deine Gewohnheit auf — versuch es jetzt!';
      case 'home_welly':      return 'Das bin ich — Welly! Ich ändere meinen Ausdruck je nach deinen Fortschritten. Je besser es läuft, desto strahlender werde ich.';
      case 'home_phase':      return 'Das ist deine Phase. Du beginnst bei Samen — Phase 1. Baue Gewohnheiten auf, um bis Phase 5 zu wachsen: Strahlend.';
      case 'home_nav':        return 'Neue Bereiche schalten sich hier frei, wenn du Fortschritte machst. Beginne mit Wasser — alles andere öffnet sich von dort.';
      case 'habits_welcome':  return 'Du hast den Gewohnheiten-Bildschirm freigeschaltet! Von hier aus verwaltest du alle deine Routinen.';
      case 'habits_now':      return 'Die \'Jetzt\'-Karte zeigt die Gewohnheit, die für diesen genauen Moment deines Tages am relevantesten ist.';
      case 'habits_list':     return 'Alle Gewohnheiten sind nach ihrer besten Zeit sortiert. Morgengewohnheiten erscheinen morgens zuerst — Welly kennt deinen Rhythmus.';
      case 'habits_ready':      return 'Bereit! Tippe täglich auf \'Erledigt\', um deine Serie aufzubauen. Kleine Handlungen, konsequent gemacht, verändern alles.';
      // Marketplace tour
      case 'marketplace_welcome': return 'Das sind deine Be Well Belohnungen! Jedes Glas Wasser, jede abgeschlossene Gewohnheit bringt dich hierher — wo deine Bemühungen zu echten Prämien werden.';
      case 'marketplace_points':  return 'Dein Punktestand ist hier immer sichtbar. Er baut sich automatisch auf, während du Gewohnheiten aufbaust — kein zusätzlicher Aufwand.';
      case 'marketplace_tabs':    return 'Drei Reiter: Prämien gegen Punkte einlösen, kostenlose Rabatte, und In-App-Inhalte freischalten. Alles durch deine täglichen Gewohnheiten verdient.';
      case 'marketplace_card':    return 'Jede Prämie hat Punktekosten. Tippe zum Einlösen — du bekommst sofort einen Code. Je konsequenter du bist, desto mehr schaltest du frei.';
      // Growth tour
      case 'growth_welcome':      return 'Das ist dein Wachstum. Keine Rangliste — ein Spiegel. Er zeigt, wer du wirst, nicht nur, was du tust.';
      case 'growth_phase':        return 'Deine Phase zeigt, wie tief verwurzelt deine Gewohnheiten sind. Von Phase 1 (Saat) bis Phase 5 (Strahlend) — jeder Schritt ist eine echte neurologische Veränderung.';
      case 'growth_heatmap':      return 'Diese Heatmap zeigt deine Beständigkeit über die Zeit. Wissenschaft sagt: Das Muster zählt mehr als die Intensität — ein paar verpasste Tage setzen nicht alles zurück.';
      case 'growth_badges':       return 'Abzeichen sind keine Dekoration. Jedes entspricht einem Verhalten, das du über einen messbaren Zeitraum aufrechterhalten hast. Sie sind Beweise deiner Reise.';
      default: return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitStartsTomorrow(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':     return 'Willkommen! Dies ist deine Basis. Oben findest du immer die dringendste Gewohnheit für den Moment. Fang dort an — der Rest kann warten.';
      case 'home_first_open_2':   return 'Wasser ist die erste Gewohnheit, weil es die biologische Grundlage für alles andere ist. Ohne Flüssigkeit sinkt die Konzentration nach nur 90 Minuten um bis zu 20 %.';
      case 'water_tracker_first': return 'Der Tracker zählt Gläser ab dem Öffnen der App jeden Morgen. 8 pro Tag ist das Ziel — aber schon 5 zu erreichen ist besser als gestern.';
      case 'first_completion':    return 'Geschafft! Jeder Abschluss schafft eine neue neuronale Verbindung. Klein, aber real. Dein Gehirn hat gerade eine Schaltung gestärkt.';
      case 'streak_explain':      return 'Wenn du morgen zurückkommst, beginnt deine Serie. Die einzige Regel: nie zwei Tage hintereinander auslassen. Eine Pause ist menschlich. Zwei sind eine neue Gewohnheit — die falsche.';
      case 'habits_tab_first':    return 'Hier findest du alle Gewohnheiten nach dem besten Moment deines Tages sortiert. Welly kennt deine Rhythmen — Morgengewohnheiten erscheinen morgens, Abendgewohnheiten abends.';
      case 'habit_card_explain':  return 'Der kreisförmige Bogen füllt sich bei jedem Abschluss. Nach 7 Tagen passiert etwas Interessantes — dein Gehirn beginnt, es als Routine zu registrieren.';
      case 'focus_unlocked':      return 'Du hast den 25-Minuten-Fokus von Anfang an zur Verfügung! Das menschliche Gehirn hat einen natürlichen Konzentrationsrhythmus von etwa 20–30 Minuten — nutze ihn für einen ablenkungsfreien Arbeitsblock.';
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
  String get registerSubtitle => 'Empieza tu camino de bienestar';
  String get tosAccept => 'Acepto los ';
  String get tosTerms => 'Términos de Servicio';
  String get tosAnd => ' y la ';
  String get tosPrivacy => 'Política de Privacidad';
  String get tosSuffix => ' de Be Well';
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
  String get firstHabitBody1 => 'Con solo un 2% de deshidratación bajan la concentración y el ánimo.';
  String get firstHabitBody2 => 'Empezamos aquí: 8 vasos al día. Yo te recordaré cuándo beber, luego añadiremos nuevos hábitos paso a paso.';
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
  String get greetingFallbackName => 'a ti';
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
  String get notifHabitTitle => '🌱 Be Well';
  String get notifHabitBody => 'Es hora de trabajar en tus hábitos — hasta una pequeña acción cuenta.';
  String get notifHabitChoiceTitle => '✨ Nuevo hábito disponible';
  String get notifHabitChoiceBody => 'Abre Be Well para elegir tu próximo hábito.';

  String get notifFrequencyLabel => 'Frecuencia de recordatorios';
  String get notifFreqOff => 'Ninguna';
  String get notifFreqLow => 'Pocas';
  String get notifFreqNormal => 'Normal';
  String get notifFreqHigh => 'Todas';
  String get notifFreqOffDesc => 'Sin recordatorios';
  String get notifFreqLowDesc => '2 al día — mañana y noche';
  String get notifFreqNormalDesc => '4 al día, repartidos en la jornada';
  String get notifFreqHighDesc => 'Cada ~2h en horas de vigilia';
  String get notifSnoozeLabel => 'Pausar recordatorios';
  String notifSnoozeActive(String until) => 'En pausa hasta las $until';
  String get notifSnoozeCancel => 'Reanudar ahora';
  String notifSnoozeHours(int h) => '$h h';

  String get navHome => 'Inicio';
  String get navHabits => 'Hábitos';
  String get navFocus => 'Enfoque';
  String get navGrowth => 'Growth';
  String get navPlan => 'Plan';
  String get navRewards => 'Recompensas';
  String get navProfile => 'Perfil';
  String get navUnlockIn => 'Se desbloquea en';
  String get navUnlockHabitsMsg => 'Completa 14 días de agua para desbloquear los hábitos.';
  String get navUnlockGrowthMsg => 'Sigue construyendo hábitos para desbloquear el crecimiento.';
  String get comingSoonHabitsDesc => 'Completa 14 días de agua.\nTu primer nuevo hábito se desbloqueará aquí.';
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
  String get breathingInhale => 'Inhala';
  String get breathingHold => 'Retén';
  String get breathingExhale => 'Exhala';
  String get breathingCycles => 'Ciclos:';
  String get breathingTapToStart => 'Toca para\nempezar';
  String get breathingStart => 'Empezar respiración';
  String get breathingStop => 'Detener';
  String get breathingAgain => 'De nuevo';
  String get breathingWellDone => '🌿 ¡Buen trabajo!';
  String breathingCyclesCompleted(int n) => '$n ciclos completados.';
  String breathingPointsEarned(int pts) => '+$pts puntos ⭐';

  String get guideTapToStart => 'Toca para\nempezar';
  String get guideStart => 'Iniciar secuencia';
  String get guideWellDone => '💪 ¡Buen trabajo!';
  String guideStepProgress(int i, int total) => 'Paso $i de $total';
  String guideStepsCompleted(int n) => '$n pasos completados.';
  String get guideDeskStep1 => 'Rotación de hombros hacia atrás × 5';
  String get guideDeskStep2 => 'Torsión dorsal sentado × 3 por lado';
  String get guideDeskStep3 => 'Círculos de muñecas y antebrazos × 10';
  String get guideDeskStep4 => 'Inclinación lateral del cuello × 3 por lado';
  String get guideDeskStep5 => 'Cat-cow sentado × 5';
  String get guideNeckStep1 => 'Rotaciones lentas de cuello × 5 por sentido';
  String get guideNeckStep2 => 'Encoger y soltar hombros × 8';
  String get guideNeckStep3 => 'Estiramiento lateral de cuello × 3 por lado';
  String get guideStretchStep1 => 'Brazos hacia arriba × 5';
  String get guideStretchStep2 => 'Flexión lateral de tronco × 3 por lado';
  String get guideStretchStep3 => 'Círculos de cadera × 8';
  String get guideStretchStep4 => 'Elevación de talones × 10';
  String get guideStretchStep5 => 'Flexión de pie hacia adelante × 20s';

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
  String get badgeRootedName => 'Hábitos arraigados';
  String get badgeRootedDesc => 'Hábitos que se volvieron una segunda naturaleza';
  String get badgeTierBronze => 'Bronce';
  String get badgeTierSilver => 'Plata';
  String get badgeTierGold => 'Oro';
  String get growthNextGoal => 'Próximo objetivo';
  String growthHabitsToRoot(int n) => n == 1 ? 'Falta 1 hábito' : 'Faltan $n hábitos';

  String get habitChoiceTitle => 'Es hora de agregar\nalgo nuevo.';
  String get habitChoiceSub => 'Elige dónde centrarte ahora.';
  String get habitChoiceShowOther => 'mostrarme otras opciones ›';
  String get habitChoiceNotReady => 'Aún no me siento listo/a';
  String get habitChoiceOpen => 'Elige tu próximo hábito';
  String get habitNotReadySnoozed => 'No hay problema — te lo volveré a preguntar dentro de una semana.';
  String get consolidatedTitle => '🏆 ¡Felicidades!';
  String consolidatedBody(String habitName) => 'Has convertido "$habitName" en un hábito real — tu cerebro ha construido un circuito duradero para él.';
  String get consolidatedBadge => 'Hábito consolidado';
  String get consolidatedCta => 'Continuar';
  String habitStartsTomorrow(String habitName) => '¡Muy bien! Disfruta hoy de tu logro — empezaremos a trabajar en "$habitName" mañana.';
  String get habitEffortLow => 'fácil';
  String get habitEffortMedium => 'moderado';
  String get habitEffortHigh => 'desafiante';

  String get errorNetwork => 'Sin conexión a internet';
  String get errorGeneral => 'Algo salió mal. Inténtalo de nuevo.';
  String get errorInvalidEmail => 'Dirección de correo no válida';
  String get errorWeakPassword => 'La contraseña es demasiado débil';
  String get errorEmailInUse => 'Este correo ya está en uso';
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos';
  String get errorTooManyAttempts => 'Demasiados intentos. Cuenta bloqueada temporalmente';
  String get errorTimeout => 'El servidor no responde. Inténtalo de nuevo en breve';
  String get errorCancelled => 'Inicio de sesión cancelado';
  String get errorAccountDisabled => 'Cuenta deshabilitada. Contacta con soporte';
  String get passwordStrengthWeak => 'Débil';
  String get passwordStrengthMedium => 'Media';
  String get passwordStrengthStrong => 'Fuerte';
  String get passwordStrengthVeryStrong => 'Muy fuerte';
  String get validationEmailRequired => 'Introduce tu correo';
  String get validationPasswordRequired => 'Introduce una contraseña';
  String get validationPasswordTooShort => 'Mínimo 8 caracteres';
  String get validationNameRequired => 'Introduce tu nombre';
  String get validationNameTooShort => 'Mínimo 2 caracteres';
  String get accountLockedBody => 'Demasiados intentos fallidos.\nInténtalo de nuevo en';
  String get accountLockedEmailSent => 'Has recibido un correo con las instrucciones.';
  String get offlineLoginRequired => 'Sin conexión — el inicio de sesión requiere internet';
  String get forgotCheckEmailTitle => 'Revisa tu correo';
  String forgotEmailSentBody(String email) =>
      'Si existe una cuenta para $email, recibirás un enlace para restablecer la contraseña.';
  String get forgotLinkExpiry => 'El enlace caduca en 30 minutos.';
  String get forgotResendLimitReached => 'Límite de reenvíos alcanzado';
  String forgotResendIn(int seconds) => 'Reenviar en ${seconds}s';
  String get verifyEmailCta => 'Haz clic en el enlace para activar tu cuenta.';
  String get verifyResendCta => 'Reenviar correo de verificación';
  String get verifyChecked => 'He verificado mi correo';
  String get verifyDifferentEmail => '¿Usar otro correo?';
  String get verifySendError => 'No se pudo enviar, inténtalo de nuevo en breve';
  String get welcomeSlide1Title => 'Tu plan de\nbienestar personal';
  String get welcomeSlide1Sub => 'Be Well crea un plan a tu medida, basado en tus hábitos y objetivos.';
  String get welcomeSlide2Title => 'Recordatorios que\nconocen tu calendario';
  String get welcomeSlide2Sub => 'Los recordatorios se adaptan a tus reuniones y horarios, para no interrumpirte nunca en el momento equivocado.';
  String get welcomeSlide3Title => 'Convierte hábitos\nen recompensas reales';
  String get welcomeSlide3Sub => 'Gana puntos completando actividades y canjéalos por descuentos, vales y mucho más.';
  String get welcomeSkip => 'Saltar';
  String get welcomeNext => 'Siguiente →';
  String get welcomeStart => 'Empezar configuración →';
  String get welcomeConfigureLater => 'Configurar más tarde';

  String get qProfileTitle => 'Cuéntanos sobre ti';
  String get qProfileSub => 'Nos ayuda a crear el plan adecuado para ti.';
  String get qGoalsTitle => 'Objetivos y estrés';
  String get qGoalsSub => 'La pantalla más importante para personalizar tu plan.';
  String get qHealthTitle => 'Tus hábitos';
  String get qHealthSub => 'Calibra la frecuencia y el tipo de recordatorios.';
  String get qScheduleTitle => 'Tu horario';
  String get qScheduleSub => 'Configuraremos los recordatorios en los momentos adecuados.';
  String get qEnvTitle => 'Entorno y productividad';
  String get qEnvSub => 'Los últimos detalles para tu plan.';
  String get qBuildPlan => 'Listo ✓';
  String get q1Label => 'Q1 · Soy principalmente…';
  String get q2Label => 'Q2 · Trabajo/estudio principalmente…';
  String get q3Label => 'Q3 · ¿Qué quieres mejorar? (varias opciones)';
  String get q4Label => 'Q4 · Nivel de estrés actual';
  String get q23Label => 'Q5 · ¿Has usado apps de bienestar antes?';
  String get q15Label => 'Q6 · Normalmente duermo…';
  String get q16Label => 'Q7 · Bebo aproximadamente…';
  String get q17Label => 'Q8 · Tiempo de pantalla (ocio, sin trabajo)';
  String get q18Label => 'Q9 · Hago ejercicio…';
  String get q5Label => 'Q10 · Mi horario es…';
  String get q6Label => 'Q11 · ¿Quieres sincronizar tu calendario?';
  String get q7Label => 'Q12 · ¿Cuántos recordatorios quieres al día?';
  String get q8Label => 'Q13 · Descanso ideal…';
  String get q9q10Label => 'Q14–Q15 · Pausa para comer';
  String get q11q14Label => 'Q16–Q19 · Tengo acceso a…';
  String get q19Label => 'Q20 · Nivel de distracciones en tu entorno';
  String get q20Label => 'Q21 · ¿Cuándo estás más concentrado?';
  String get q21Label => 'Q22 · ¿Cuánto tiempo puedes concentrarte seguido?';
  String get q22Label => 'Q23 · ¿Cuántas reuniones tienes al día (de media)?';
  String get q1Student => 'Estudiante';
  String get q1Employee => 'Empleado/a';
  String get q1Freelancer => 'Autónomo/a';
  String get q1Other => 'Otro';
  String get q1Both => 'Ambos';
  String get q2Home => 'Desde casa';
  String get q2Office => 'En la oficina';
  String get q2Hybrid => 'Híbrido';
  String get q2Varies => 'Varía';
  String get goalStress => 'Reducir el estrés';
  String get goalFocus => 'Mejorar el enfoque';
  String get goalHealth => 'Salud general';
  String get goalSleep => 'Dormir mejor';
  String get goalEnergy => 'Más energía';
  String get goalWeight => 'Forma física';
  String get stress1 => 'Muy tranquilo';
  String get stress2 => 'Bastante tranquilo';
  String get stress3 => 'Normal';
  String get stress4 => 'Algo estresado';
  String get stress5 => 'Muy estresado';
  String get stressCalmEnd => 'Tranquilo';
  String get stressStressedEnd => 'Estresado';
  String get priorNone => 'No, nunca';
  String get priorHeadspace => 'Headspace';
  String get priorCalm => 'Calm';
  String get priorMultiple => 'Más de una';
  String get priorOther => 'Otra app';
  String get hydroLow => 'poco';
  String get hydroGreat => 'óptimo';
  String get exNever => 'Nunca';
  String get ex12x => '1-2x/semana';
  String get ex34x => '3-4x/semana';
  String get exDaily => 'Todos los días';
  String get schedFixed => 'Fijo';
  String get schedFlexible => 'Flexible';
  String get schedShift => 'Por turnos';
  String get schedIrregular => 'Irregular';
  String get calNoneLabel => 'No gracias, por ahora';
  String get calSyncNote => '✓ Te pediremos permisos después de confirmar el plan';
  String get remMinimal => 'Mínimos';
  String get remMinimalSub => '~2/día';
  String get remModerate => 'Moderados';
  String get remModerateSub => '~4/día';
  String get remFrequent => 'Frecuentes';
  String get remFrequentSub => '~6/día';
  String get remVeryFrequent => 'Muy frec.';
  String get remVeryFrequentSub => '8+/día';
  String get lunchTimeLabel => 'Hora';
  String get lunchDurationLabel => 'Duración';
  String get resParkLabel => 'Parque o zona verde';
  String get resParkSub => 'Para caminar durante la pausa del almuerzo';
  String get resGymLabel => 'Gimnasio o zona fitness';
  String get resGymSub => 'En la oficina o cerca';
  String get resWindowLabel => 'Ventana con vistas';
  String get resWindowSub => 'Para la regla 20-20-20 de los ojos';
  String get resQuietLabel => 'Espacio tranquilo';
  String get resQuietSub => 'Para meditación y concentración profunda';
  String get distLow => 'Bajo';
  String get distMedium => 'Medio';
  String get distHigh => 'Alto';
  String get distVeryHigh => 'Muy alto';
  String get focusMorning => 'Mañana';
  String get focusMidday => 'Mediodía';
  String get focusAfternoon => 'Tarde';
  String get focusEvening => 'Noche';
  String get meeting02 => '0-2 / día';
  String get meeting24 => '2-4 / día';
  String get meeting46 => '4-6 / día';
  String get meeting6plus => '6+ / día';
  String get screenTimeWarning => 'Activaremos recordatorios de ojos más frecuentes';
  String get crisisTitle => 'Estás pasando por un momento difícil';
  String get crisisBody => 'Be Well está aquí para apoyarte. Si necesitas ayuda inmediata: contacta con una línea de ayuda local.';
  String get qOptional => 'opcional';
  String get qBack => '← Atrás';
  String get qSkipAll => 'Saltar todo';
  String qOfTotal(int current, int total) => '$current de $total';
  String get planGenTitle => 'Construyendo tu plan…';
  String get planGenSub => 'Aplicando tus reglas de personalización';
  String get planStep1 => 'Analizando tu perfil';
  String get planStep2 => 'Configurando recordatorios';
  String get planStep3 => 'Seleccionando actividades';
  String get planStep4 => 'Configurando el panel';
  String get planReadyBadge => '🎉 ¡Plan listo!';
  String get planPreviewTitle => 'Tu plan de\nbienestar';
  String get planPreviewSub => 'Personalizado según tus respuestas. Podrás modificarlo siempre desde Ajustes.';
  String get planRemindersPerDay => 'recordatorios/día';
  String get planFocusSessions => 'sesiones focus';
  String get planPointsPerDay => 'puntos/día';
  String get planMorning => '🌅 Mañana';
  String get planAfternoon => '☀️ Tarde';
  String get planEvening => '🌙 Noche';
  String planFromTime(String time) => 'desde $time';
  String planConnectCalendar(String name) => 'Conectar $name';
  String get planConnectCalendarSub => 'Pediremos permiso después de confirmar';
  String get planFallbackNote => 'Usamos un plan predeterminado. Lo iremos ajustando a medida que uses la app.';
  String get planConfirmCta => 'Empezar con Be Well  ';
  String get planConfirmSub => 'Puedes modificar tu plan en cualquier momento desde Ajustes';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Perfil';
  String get accountSection => 'Cuenta';
  String get emailAccountLabel => 'Correo de la cuenta';
  String get supportSection => 'Soporte';
  String get editNameTitle => 'Editar nombre';
  String get yourNameHint => 'Tu nombre';
  String get resetTutorialTitle => 'Restablecer tutorial';
  String get resetTutorialBody => 'Welly volverá a mostrar todos los diálogos del tutorial como si fuera la primera vez. Útil para probar el flujo.';
  String get resetTutorialCta => 'Restablecer';
  String get resetTutorialSnackbar => 'Tutorial restablecido ✓';
  String genericError(String msg) => 'Error: $msg';
  String get settingsTitle => 'Ajustes';
  String get styleCardDesc => 'Contenido en tarjetas,\ntipografía clara';
  String get styleAmbientDesc => 'Paisaje atmosférico,\nfuente editorial';
  String get toneSection => 'Tono';
  String get accessibilitySection => 'Accesibilidad';
  String get contrastDesc => 'Aumenta el contraste del texto';
  String get textSizeDesc => 'Aumenta el tamaño del texto';
  String get remindersLabel => 'Recordatorios de actividades';
  String get remindersDesc => 'Notificaciones para actividades planificadas';
  String get comingSoonTitle => 'Próximamente';
  String get comingSoonBody => 'Esta sección aún no está disponible — está en nuestra hoja de ruta.';
  String get habitMarkDone => 'Hecho';
  String get slowdownReasonHeavy => 'Este hábito me pesa demasiado ahora mismo';
  String heatmapDaysAgo(int n) => 'hace $n días';
  String get heatmapToday => 'hoy';
  String phaseStarted(String date) => 'iniciado el $date';
  String phaseReached(String date) => 'alcanzado el $date';
  String get marketAdTitle => 'Ayuda a Be Well';
  String get marketAdSubtitle => 'Gana 10 pt viendo un anuncio';
  String get marketAdDialogBody => 'Mira un anuncio: nos ayudas a mantener la app gratis y ganas 10 puntos al instante.';
  String get marketWatchNow => 'Ver ahora';
  String get dialogGotIt => 'Entendido';
  String get marketAdUnavailable => 'Anuncio no disponible por ahora';
  String get referralTitle => 'Invita a un amigo';
  String get referralSubtitle => 'Gana 50 pt por cada amigo que se registre';
  String get referralApply => 'Aplicar';
  String get referralApplied => '¡Código aplicado! Tu amigo recibirá el bono pronto. 🎉';
  String get referralErrorInvalid => 'Código no válido';
  String get referralErrorOwn => 'No puedes usar tu propio código';
  String get referralErrorAlready => 'Ya has canjeado un código de invitación';
  String get referralErrorNotSignedIn => 'Debes haber iniciado sesión';
  String get referralErrorGeneric => 'Algo salió mal, inténtalo de nuevo';
  String get referralHint => '¿Tienes un código de invitación?';
  String premiumPrice(String price) => '$price/mes';
  String referralShareButton(String code) => 'Compartir mi código · $code';
  String get referralRetry => 'No se pudo generar el código — toca para reintentar';
  String referralShareMessage(String code) =>
      'Estoy usando Be Well para crear hábitos más saludables, día a día 🌱\n'
      '¡Descarga la app y usa mi código de invitación "$code" — recibirás 50 puntos de bono en cuanto empieces!';

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
  String get configuratorTitle => 'Personaliza tu plan';
  String get configuratorSubtitle => 'Responde algunas preguntas para recibir sugerencias de hábitos hechas a tu medida';
  String get configuratorDoneTitle => 'Tu plan está personalizado';
  String get configuratorDoneSubtitle => 'Toca para actualizar tus respuestas';
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
  String get slowdownMenuSubtitle => 'Las nuevas sugerencias de hábitos se pausan durante 2 semanas — este se queda en tu plan de todas formas.';
  String get slowdownWellyResponse => 'Sin problema — las nuevas sugerencias están en pausa durante 2 semanas. Este hábito se queda en tu plan, tómate el tiempo que necesites.';
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
  String get tutorialNext => 'Siguiente →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable         => 'puntos disponibles';
  String get marketplaceTabRewards   => 'Premios';
  String get marketplaceTabDiscounts => 'Descuentos';
  String get marketplaceTabInApp     => 'En la app';
  String get rewardsToRedeem         => 'para canjear';
  String get rewardRedeemed          => 'Ahí está. Te lo ganaste.';
  String get rewardConfirmTitle      => '¿Estás seguro?';
  String get rewardConfirmBody       => 'Se deducirán X puntos de tu saldo.';
  String get rewardRedeemFailed => 'No se pudo canjear esta recompensa — puntos insuficientes, o ya no está disponible.';
  String get copyCode                => 'Copiar código';
  String get codeCopied              => 'Copiado';
  String get watchAd                 => 'Ver un anuncio · +10 pt';
  String get whyAds                  => '¿por qué?';
  String get whyAdsTitle             => 'Be Well es gratuito para todos';
  String get whyAdsBody              => 'Be Well es una aplicación gratuita para ser accesible para todos. Como cualquier servicio, tiene costos operativos. Al ver anuncios cuando puedas, nos ayudas a mantener el servicio activo y mejorarlo para todos. Gracias.';
  String get discountsActive         => 'descuentos activos';
  String get discountsNote           => 'Los descuentos se actualizan mensualmente. No se requieren puntos.';
  String get discountExclusive       => 'exclusivo Be Well';
  String get goToSite                => 'Ir al sitio';
  String get affiliateNote           => 'Este enlace apoya Be Well';
  String get inAppWelly              => 'welly';
  String get inAppSoundscape         => 'soundscape';
  String get inAppMinigame           => 'minijuego';
  String get inAppPercorsi           => 'recorridos';
  String get unlockItem              => 'Desbloquear';
  String get itemUnlocked            => 'Desbloqueado';
  String get premiumAllContent       => 'Todo el contenido in-app incluido';
  String get premiumPoints           => '+20% puntos en cada hábito';
  String get premiumWelly            => 'Welly completamente personalizable';
  String get premiumDiscounts        => 'Descuentos exclusivos por adelantado';
  String get premiumTrial            => 'Prueba 7 días gratis';
  String get premiumOr               => 'o compra individualmente con puntos';

  String get feedbackTitle => 'Enviar comentario';
  String get feedbackSubtitle => 'Nos ayuda a mejorar Be Well para ti.';
  String get feedbackHint => 'Escribe aquí tu comentario…';
  String get feedbackSubmit => 'Enviar comentario';
  String get feedbackThanks => '¡Gracias por tu comentario!';
  String get feedbackError => 'No se pudo enviar, inténtalo de nuevo en breve';
  String get feedbackCategoryBug => 'Error';
  String get feedbackCategoryIdea => 'Idea';
  String get feedbackCategoryFeature => 'Función';
  String get feedbackCategoryOther => 'Otro';

  String spotlightText(String id) {
    switch (id) {
      case 'home_welcome':    return '¡Bienvenido! Soy Welly. Déjame mostrarte todo para que puedas empezar bien.';
      case 'home_water':      return 'Este es tu primer hábito: beber agua. 8 vasos al día es tu objetivo. Simple y poderoso.';
      case 'home_add_glass':  return 'Toca aquí cada vez que bebas un vaso. Cada toque construye tu hábito — ¡pruébalo ahora!';
      case 'home_welly':      return 'Ese soy yo — ¡Welly! Cambio de expresión según tus progresos. Cuanto mejor lo haces, más radiante me vuelvo.';
      case 'home_phase':      return 'Esta es tu Fase. Empiezas en Semilla — Fase 1. Construye hábitos para crecer hasta la Fase 5: Radiante.';
      case 'home_nav':        return 'Nuevas secciones se desbloquean aquí a medida que progresas. Empieza con el agua — todo lo demás se abre desde ahí.';
      case 'habits_welcome':  return '¡Desbloqueaste la pantalla de Hábitos! Desde aquí gestionas todas tus rutinas.';
      case 'habits_now':      return 'La tarjeta \'Ahora\' muestra el hábito más relevante para este preciso momento de tu día.';
      case 'habits_list':     return 'Todos los hábitos están ordenados por su mejor momento. Los hábitos matutinos aparecen primero por la mañana — Welly conoce tu ritmo.';
      case 'habits_ready':      return '¡Listo! Toca \'Completar\' cada día para construir tu racha. Pequeñas acciones, hechas con constancia, cambian todo.';
      // Marketplace tour
      case 'marketplace_welcome': return '¡Estos son tus Premios Be Well! Cada vaso de agua, cada hábito completado te trae aquí — donde tus esfuerzos se convierten en recompensas reales.';
      case 'marketplace_points':  return 'Tu saldo de puntos siempre es visible aquí. Se acumula automáticamente mientras construyes hábitos — sin hacer nada extra.';
      case 'marketplace_tabs':    return 'Tres pestañas: Premios para canjear con puntos, Descuentos gratuitos, y contenido En la app para desbloquear. Todo ganado con tus hábitos diarios.';
      case 'marketplace_card':    return 'Cada premio tiene un costo en puntos. Toca para canjear — recibes un código al instante. Cuanto más constante seas, más desbloqueas.';
      // Growth tour
      case 'growth_welcome':      return 'Este es tu Crecimiento. No es un ranking — es un espejo. Muestra en quién te estás convirtiendo, no solo lo que haces.';
      case 'growth_phase':        return 'Tu fase refleja qué tan arraigados están tus hábitos. De la Fase 1 (Semilla) a la Fase 5 (Radiante) — cada paso es un cambio neurológico real.';
      case 'growth_heatmap':      return 'Este mapa de calor muestra tu consistencia en el tiempo. La ciencia dice que el patrón importa más que la intensidad: unos días perdidos no reinician todo.';
      case 'growth_badges':       return 'Las insignias no son decoración. Cada una corresponde a un comportamiento mantenido durante un período medible. Son pruebas concretas de tu recorrido.';
      default: return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitStartsTomorrow(habitName(hid));
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


