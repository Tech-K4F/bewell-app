import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/smart_reminders.dart';

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

  /// Ultima lingua nota, mantenuta anche fuori dall'istanza — usata come
  /// fallback da [LocaleContext.sL]/[LocaleContext.s] quando il lookup del
  /// Provider fallisce (context ricostruito tra la schedulazione di un
  /// postFrameCallback e la sua esecuzione, tipico dei popup/tutorial
  /// mostrati subito dopo un cambio di stato). Prima il fallback tornava
  /// sempre a inglese: un utente italiano vedeva a tratti popup in inglese
  /// senza che nulla fosse davvero rotto nelle traduzioni.
  static BwLocale _cachedLocale = BwLocale.en;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    _locale = BwLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => BwLocale.en,
    );
    _cachedLocale = _locale;
    _scheduleNotifications();
    notifyListeners();
  }

  Future<void> setLocale(BwLocale locale) async {
    _locale = locale;
    _cachedLocale = locale;
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

/// Ripianifica i promemoria intelligenti (vedi SmartReminders) — chiamabile
/// senza BuildContext da [LocaleProvider] (cambio lingua) e
/// [SettingsProvider] (cambio frequenza/pausa): legge tutto da
/// SharedPreferences, incluso l'ultimo stato delle abitudini salvato.
Future<void> rescheduleBwReminders() => SmartReminders.replan();

// ── Stringhe app ──────────────────────────────────────────────────────────────
abstract class BwStrings {
  static BwStrings of(BwLocale locale) {
    switch (locale) {
      case BwLocale.it:
        return _It();
      case BwLocale.fr:
        return _Fr();
      case BwLocale.de:
        return _De();
      case BwLocale.es:
        return _Es();
      case BwLocale.en:
        return _En();
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
  String get previewDiscountTitle;
  String get previewDiscountSub;
  String get previewCoffeeTitle;
  String get previewCoffeeSub;
  String get previewPremiumTitle;
  String get previewPremiumSub;
  String get previewSurpriseTitle;
  String get previewSurpriseSub;
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
  String get goodAfternoon;
  String get goodEvening;
  String get greetingFallbackName;
  String get phase;
  String get waterToday;
  String get waterGlasses;
  String get waterTrackedInHome;
  String get waterZero;
  String get habitsEmptyTitle;
  String get habitsEmptySubtitle;
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
  String get phase1;
  String get phase2;
  String get phase3;
  String get phase4;
  String get phase5;

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
  String get focusStartSession;
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
  String get notifMiddayTitle;
  String get notifMiddayBody;
  String get notifLunchTitle;
  String get notifLunchBody;
  String get notifAfternoonTitle;
  String get notifAfternoonBody;
  String get notifHabitChoiceTitle;
  String get notifHabitChoiceBody;

  // ── Impostazioni notifiche ────────────────────────────────────────────────
  String get notifFocusTitle;
  String get notifFocusBody;
  String get notifBundleTitle;
  String notifBundleMorningBody(String list);
  String notifBundleBreakBody(String list);
  String notifBundleEveningBody(String list);
  String get notifFocusDoneTitle;
  String notifFocusDoneBody(String list);
  String get notifFocusDoneBodyPlain;
  String get notifAndWord;

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
  String get habitWaterName;
  String get habitWaterDesc;
  String get habitFocus25Name;
  String get habitFocus25Desc;
  String get habitEyes2020Name;
  String get habitEyes2020Desc;
  String get habitNeckName;
  String get habitNeckDesc;
  String get habitBreathingBoxName;
  String get habitBreathingBoxDesc;
  String get habitWalkLunchName;
  String get habitWalkLunchDesc;
  String get habitDeskExName;
  String get habitDeskExDesc;
  String get habitWaterMornName;
  String get habitWaterMornDesc;
  String get habitPostureName;
  String get habitPostureDesc;
  String get habitLunchParkName;
  String get habitLunchParkDesc;
  String get habitBreathing478Name;
  String get habitBreathing478Desc;
  String get habitStretchName;
  String get habitStretchDesc;
  String get habitSnackName;
  String get habitSnackDesc;
  String get habitLunchNoScreenName;
  String get habitLunchNoScreenDesc;
  String get habitFocus50Name;
  String get habitFocus50Desc;
  String get habitMeditationName;
  String get habitMeditationDesc;
  String get habitStairsName;
  String get habitStairsDesc;
  String get habitSleepName;
  String get habitSleepDesc;
  String get habitWakeName;
  String get habitWakeDesc;
  String get habitNapName;
  String get habitNapDesc;
  String get habitFocusPhoneName;
  String get habitFocusPhoneDesc;
  String get habitMicroWalkName;
  String get habitMicroWalkDesc;
  String get habitDigitalSunsetName;
  String get habitDigitalSunsetDesc;

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
  String get guideDeskStep1;
  String get guideDeskStep2;
  String get guideDeskStep3;
  String get guideDeskStep4;
  String get guideDeskStep5;
  // neck_stretch
  String get guideNeckStep1;
  String get guideNeckStep2;
  String get guideNeckStep3;
  // stretching_active
  String get guideStretchStep1;
  String get guideStretchStep2;
  String get guideStretchStep3;
  String get guideStretchStep4;
  String get guideStretchStep5;
  // sub-phase verbs, reused across exercises so each guided movement is
  // narrated in real time (hold/lower/switch side) instead of one flat timer

  String get guideHowShoulderRoll;
  String get guideHowSpinalTwist;
  String get guideHowWrist;
  String get guideHowNeckTilt;
  String get guideHowCatCow;
  String get guideHowNeckRoll;
  String get guideHowShrug;
  String get guideHowArmReach;
  String get guideHowSideBend;
  String get guideHowHips;
  String get guideHowCalf;
  String get guideHowFold;
  String get guideSafetyNote;

  String get guidePhaseMove;
  String get guidePhaseRest;
  String get guidePhaseRightHold;
  String get guidePhaseCenter;
  String get guidePhaseLeftHold;
  String get guidePhaseClockwise;
  String get guidePhaseCounterClockwise;
  String get guidePhaseArchCow;
  String get guidePhaseRoundCat;
  String get guidePhaseRaiseHold;
  String get guidePhaseLowerRelease;
  String get guidePhaseReachHold;
  String get guidePhaseLowerSlowly;
  String get guidePhaseFoldHold;
  String get guidePhaseRiseSlowly;

  // ── Coach messages ────────────────────────────────────────────────────────
  String get coachDay1;
  String get coachDay3;
  String get coachDay7;
  String get coachDay14;
  String get coachGeneral;

  // ── Badges ────────────────────────────────────────────────────────────────
  String get badgeFirstStep;
  String get badgeFirstStepDesc;
  String get badgeOneWeek;
  String get badgeOneWeekDesc;
  String get badgeThreeWeeks;
  String get badgeThreeWeeksDesc;
  String get badgeSixWeeks;
  String get badgeSixWeeksDesc;
  String get badgeThreeMonths;
  String get badgeThreeMonthsDesc;
  String get badgeInSync;
  String get badgeInSyncDesc;
  String get badgeMultihabit;
  String get badgeMultihabitDesc;
  String get badgeHydrated;
  String get badgeHydratedDesc;
  String get badgeFocused;
  String get badgeFocusedDesc;
  String get badgeWalker;
  String get badgeWalkerDesc;
  String get badgeBreath;
  String get badgeBreathDesc;
  String get badgeRootedName;
  String get badgeRootedDesc;
  String get badgeTierBronze;
  String get badgeTierSilver;
  String get badgeTierGold;
  String get growthNextGoal;
  String growthHabitsToRoot(int n);

  // ── Habit intro sheet ────────────────────────────────────────────────────
  String get habitChoiceTitle;
  String get habitChoiceSub;
  String get habitChoiceShowOther;
  String get habitChoiceNotReady;
  String get habitChoiceOpen;
  String get habitNotReadySnoozed;
  String get habitNotReadyMeanwhile;
  String habitMatchesGoal(String goal);
  String get consolidatedTitle;
  String consolidatedBody(String habitName);
  String get consolidatedBadge;
  String get consolidatedCta;
  String get consolidatedCtaNext;
  String get automaticTitle;
  String automaticBody(String habitName);
  String get automaticBadge;
  String get calendarTowardAssimilated;
  String get calendarTowardAutomatic;
  String get calendarMilestoneSoon;
  String calendarMilestoneInDays(int days);
  String get calendarAssimilatedTitle;
  String get calendarAssimilatedSub;
  String get calendarAutomaticTitle;
  String get calendarAutomaticSub;
  String get calendarLongArcNote;
  String get calendarDoneTitle;
  String calendarDoneSub(int points);
  String get dailyObjectivesTitle;
  String dailyObjectivesSub(int done, int total);
  String get badgeUnlockedTitle;
  String get badgeUnlockedCta;
  String get newMissionLabel;
  String get missionStartCta;
  String get missionStreakStart;
  String get missionStreakGoal;
  String streakMilestoneTitle(int days);
  String get streakMilestoneBadge;
  String habitStartsTomorrow(String habitName);
  // Dialogo di scelta abitudine — a differenza di habitStartsTomorrow (che
  // serve anche da testo di notifica, deve restare breve) spiega il
  // percorso a tappe che l'utente vedrà sulla card: prima volta → routine
  // → assimilata a 7 giorni → automatica a 66.
  String habitChosenIntro(String habitName);
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
  String get errorRequiresRecentLogin;
  String get deleteAccount;
  String get deleteAccountConfirmTitle;
  String get deleteAccountConfirmBody;
  String get deleteAccountCta;
  String get deleteAccountDone;
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
  String get welcomeSlide1Footer;
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
  // Obiettivo esplicito verso l'assimilazione — "stile videogioco":
  // un traguardo chiaro alla volta, con numero, invece di un anello di
  // progresso muto senza etichetta.
  String get habitGoalFirstTime;
  // Progresso parziale di oggi non ancora sufficiente per il primo giorno
  // assimilato (es. acqua: alcuni bicchieri bevuti, non ancora tutti) —
  // senza questo, la card mostrava "falla per la prima volta" anche con
  // un po' di progresso già fatto oggi, contraddicendo la Home.
  String habitGoalInProgressToday(int count, int target);
  String habitGoalBuilding(int days, int target);
  String habitGoalBonus(int days, int target);
  String get habitGoalMastered;
  String get slowdownReasonHeavy;
  String heatmapDaysAgo(int n);
  String get heatmapToday;
  String phaseStarted(String date);
  String phaseReached(String date);
  String get marketAdTitle;
  String get marketAdSubtitle;
  String marketAdRemaining(int n);
  String get marketAdCapReached;
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
  String get focusThenBreak;
  String get containerSize;
  String focusTimerSpoken(int m, int s);
  String waterGlassAnnounce(int n, int t);
  String habitRingSpoken(int n);
  String get passwordShow;
  String get passwordHide;
  String get waterAlmost;
  String get reduceMotion;
  String get reduceMotionDesc;
  String get accessibilityHint;
  String get leaveSessionTitle;
  String get leaveSessionBody;
  String get leaveSessionStay;
  String get leaveSessionLeave;
  String waterNextGlassIn(String time);
  String get workScheduleStart;
  String get workScheduleEnd;
  String get workScheduleTime;
  String get workScheduleDays;
  String get workScheduleInviteTitle;
  String get workScheduleInviteBody;
  String get workScheduleInviteSet;
  String get workScheduleInviteLater;
  String get wdMon;
  String get wdTue;
  String get wdWed;
  String get wdThu;
  String get wdFri;
  String get wdSat;
  String get wdSun;
  String get notifInviteTitle;
  String get notifInviteBody;
  String get notifInviteAction;
  String get notifInviteLater;
  String get notifComebackTitle1;
  String get notifComebackBody1;
  String get notifComebackTitle2;
  String get notifComebackBody2;
  String get notifComebackTitle3;
  String get notifComebackBody3;
  String get notifComebackTitle4;
  String get notifComebackBody4;
  String get resetAllTitle;
  String get resetAllSubtitle;
  String get resetAllConfirmTitle;
  String get resetAllConfirmBody;
  String get resetAllConfirmButton;
  String get notifFocusRunningTitle;
  String get notifFocusRunningBody;
  String get notifFocusPausedTitle;
  String get notifFocusPausedBody;
  String get dayOne;
  String get wellyMsgMorning;
  String get wellyMsgAfternoon;
  String get wellyMsgEvening;
  String get wellyMsgAllDone;
  String get wellyMsgWaterDone;
  String wellyMsgWaterProgress(int n, int t);

  // ── Tutorial Welly ────────────────────────────────────────────────────────
  String get tutorialOk;
  String get tutorialMore;
  String get tutorialSkip;
  String get tutorialShowSource;
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
  String get passwordForgotSub =>
      'Enter your email and we\'ll send you a reset link';
  String get sendResetEmail => 'Send reset email';
  String get backToLogin => 'Back to login';
  String get emailSent => 'Email sent';

  String get wellyHi => 'Hi, I\'m Welly.';
  String get wellyIntro =>
      'Be Well is the first app that guides you step by step in building healthy habits — and rewards you as you do. I\'m not asking you to change everything in one day. Just start with one small thing, with me.';
  String get letsGo => 'Let\'s go';
  String get wellyNameQuestion =>
      'First things first: what do you want to call me?';
  String get wellyNameSub =>
      'My name is Welly, but you can give me your own name if you prefer.';
  String get perfect => 'Perfect';
  String get firstHabitTitle => 'First habit: water.';
  String get firstHabitBody1 =>
      'Just 2% dehydration lowers focus and mood — yet most people drink far too little.';
  String get firstHabitBody2 =>
      'We start here: 8 glasses a day. I\'ll remind you when to drink, then we\'ll add new habits step by step.';
  String get drinkFirstGlass => 'Drink the first glass now';
  String get rewardTitle => 'Perfect. One.';
  String get rewardBody =>
      'Every time you complete something, you earn Be Well points. You\'ll accumulate them without thinking — and you can use them for discount vouchers, gift cards, accessories, premium app features and much more.';
  String get goToHome => 'Go to your home';
  String get rewardLocked => 'Unlocked with points';
  @override
  String get previewDiscountTitle => 'Discount voucher';
  @override
  String get previewDiscountSub => '10% at selected partners';
  @override
  String get previewCoffeeTitle => 'Coffee voucher';
  @override
  String get previewCoffeeSub => 'A free drink';
  @override
  String get previewPremiumTitle => 'Premium';
  @override
  String get previewPremiumSub => 'Advanced features';
  @override
  String get previewSurpriseTitle => 'Surprises';
  @override
  String get previewSurpriseSub => 'And much more...';
  String get notifPermTitle => 'One last thing.';
  String get notifPermBody =>
      'To help you stay consistent, Welly sends a few gentle reminders at the right moments of your day. No spam, no pressure — you decide how many, anytime, from Settings.';
  String get notifPermAllow => 'Yes, enable notifications';
  String get notifPermSkip => 'Not now';
  String get waterUndo => 'Undo last';
  String get waterCooldown => 'Wait a moment…';
  String get waterContainerBtn => 'Container';

  String get goodMorning => 'Good morning,';
  @override
  String get goodAfternoon => 'Good afternoon,';
  @override
  String get goodEvening => 'Good evening,';
  String get greetingFallbackName => 'there';
  String get phase => 'Phase';
  String get waterToday => 'Water today';
  String get waterGlasses => 'glasses';
  String get waterTrackedInHome => '💧 tracked in Home';
  String get waterZero => 'Start with the first glass.';
  @override
  String get habitsEmptyTitle => 'One habit at a time';
  @override
  String get habitsEmptySubtitle =>
      'Water is your starting point today. The next one unlocks on its own once this one feels automatic — no rush.';
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
  String get phase1 => 'Seed';
  String get phase2 => 'Sprout';
  String get phase3 => 'Young';
  String get phase4 => 'Mature';
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
  @override
  String get focusStartSession => 'Start session';
  String get focusNewSession => 'New session';
  String get focusDone => 'Session complete!';
  String get focusRemaining => 'remaining';
  String get focusSessions => 'sessions';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'streak';
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min left';
  String get focusBlockOf4 => 'of 4';
  String get focusThenBreak => 'then a 5-minute break';
  String get containerSize => 'Size';
  String focusTimerSpoken(int m, int s) => '$m minutes $s seconds remaining';
  String waterGlassAnnounce(int n, int t) => 'Glass $n of $t logged';
  String habitRingSpoken(int n) => '$n days completed in total';
  String get passwordShow => 'Show password';
  String get passwordHide => 'Hide password';
  String get waterAlmost => 'Almost there — just a little more.';
  String get reduceMotion => 'Reduce motion';
  String get reduceMotionDesc => 'Calms animations and moving elements';
  String get accessibilityHint => 'These settings apply to the whole app. Be Well also follows the text size and animation settings of your phone.';
  String get leaveSessionTitle => 'Leave this session?';
  String get leaveSessionBody => 'If you leave now this session won\'t be counted and you\'ll start again from the beginning. Want to keep going?';
  String get leaveSessionStay => 'Keep going';
  String get leaveSessionLeave => 'Leave anyway';
  String waterNextGlassIn(String time) => 'Next glass in $time';
  String get workScheduleStart => 'Start';
  String get workScheduleEnd => 'End';
  String get workScheduleTime => 'Time';
  String get workScheduleDays => 'Work or study days';
  String get workScheduleInviteTitle => 'Tell me your days and hours';
  String get workScheduleInviteBody => 'I\'ll time your reminders around when you work or study, and keep them lighter on your days off. You can always change it from Habits.';
  String get workScheduleInviteSet => 'Set it now';
  String get workScheduleInviteLater => 'Later';
  String get wdMon => 'Mon';
  String get wdTue => 'Tue';
  String get wdWed => 'Wed';
  String get wdThu => 'Thu';
  String get wdFri => 'Fri';
  String get wdSat => 'Sat';
  String get wdSun => 'Sun';
  String get notifInviteTitle => 'Reminders are off';
  String get notifInviteBody => 'Small nudges at the right moments are one of the best helps for turning actions into habits. Turn them on — you decide how many in Settings.';
  String get notifInviteAction => 'Turn on';
  String get notifInviteLater => 'Not now';
  String get notifComebackTitle1 => 'I\'m here when you\'re ready 🌱';
  String get notifComebackBody1 => 'It\'s been a few days. One glass of water is enough to start again — no rush.';
  String get notifComebackTitle2 => 'No pressure';
  String get notifComebackBody2 => 'Even a tiny step counts. Pick up whenever you like — your progress is safe.';
  String get notifComebackTitle3 => 'Welly is thinking of you';
  String get notifComebackBody3 => 'Your habits are waiting exactly where you left them.';
  String get notifComebackTitle4 => 'Starting again is easy';
  String get notifComebackBody4 => 'One glass of water and you\'ve already begun again.';
  String get resetAllTitle => 'Start over from scratch';
  String get resetAllSubtitle => 'Erase all progress and begin again';
  String get resetAllConfirmTitle => 'Start over?';
  String get resetAllConfirmBody => 'This erases your habits, days, streak, points and settings from this phone and from your account in the cloud. You\'ll go through the welcome again as if it were your first time. This can\'t be undone.';
  String get resetAllConfirmButton => 'Erase everything';
  String get notifFocusRunningTitle => '🎯 Focus in progress';
  String get notifFocusRunningBody => 'One thing at a time. Tap to get back to the timer.';
  String get notifFocusPausedTitle => '⏸ Focus paused';
  String get notifFocusPausedBody => 'Take your time — pick it up whenever you\x27re ready.';
  String get dayOne => 'day';
  String get wellyMsgMorning => 'Good morning! A glass of water and your day starts on the right foot.';
  String get wellyMsgAfternoon => 'Still with me? A sip of water and a short pause will do you good.';
  String get wellyMsgEvening => 'The day is winding down, and that\x27s fine. If you like, one last glass, then rest.';
  String get wellyMsgAllDone => 'You did everything you needed today. Enjoy the rest of your day.';
  String get wellyMsgWaterDone => 'Water done, great rhythm. Anything more is a bonus.';
  String wellyMsgWaterProgress(int n, int t) => 'Nice: $n of $t glasses. No rush.';

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
  String get notifWaterBody =>
      'Your first glass of water is a good place to start the day.';
  String get notifMiddayTitle => '🧘 Be Well';
  String get notifMiddayBody =>
      'Two minutes to stretch or breathe — your focus will thank you later.';
  String get notifLunchTitle => '🍃 Be Well';
  String get notifLunchBody =>
      'A real break helps: put the screen down for a few minutes while you eat.';
  String get notifAfternoonTitle => '👀 Be Well';
  String get notifAfternoonBody =>
      'Eyes tired from the screen? 20 seconds looking into the distance actually helps.';
  String get notifEveningTitle => 'Be Well 🌙';
  String get notifEveningBody =>
      'Still time for one more habit today, if you feel like it — otherwise, see you tomorrow.';
  String get notifHabitChoiceTitle => '✨ New habit available';
  String get notifHabitChoiceBody => 'Open Be Well to choose your next habit.';

  @override
  String get notifFocusTitle => '🎯 Focus time';
  @override
  String get notifFocusBody =>
      'Whenever you\'re ready: one focused block, no rush.';
  @override
  String get notifBundleTitle => '🌿 Be Well';
  @override
  String notifBundleMorningBody(String list) => 'To start well: $list.';
  @override
  String notifBundleBreakBody(String list) => 'A gentle break: $list.';
  @override
  String notifBundleEveningBody(String list) => 'To close the day well: $list.';
  @override
  String get notifFocusDoneTitle => '✨ Block complete';
  @override
  String notifFocusDoneBody(String list) => 'Nice work. Take a moment: $list.';
  @override
  String get notifFocusDoneBodyPlain => 'Nice work. Take a moment to breathe.';
  @override
  String get notifAndWord => 'and';

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
  String get navUnlockHabitsMsg =>
      'Complete 14 days of water to unlock habits.';
  String get navUnlockGrowthMsg =>
      'Growth opens after 14 days of consistency with a habit — you\'re already building it.';
  String get comingSoonHabitsDesc =>
      'Complete 14 days of water.\nYour first new habit will unlock here.';
  String get comingSoonGrowthDesc =>
      'Keep building your habits.\nThe growth screen will unlock soon.';
  String get achievementUnlocked => 'Achievement unlocked!';
  String get newHabitUnlocked => 'New habit unlocked!';

  String get rewards => 'Rewards';
  String get rewardsPoints => 'Be Well points';
  String get rewardsLocked => 'Rewards are coming';
  String get rewardsLockedDesc => 'Keep building habits to unlock your rewards';
  String get rewardsHeader => 'Your rewards';
  String get rewardsHeaderSub => 'Collect what you\'ve earned';

  String get habitWaterName => 'Drink water';
  String get habitWaterDesc => '8 glasses throughout the day';
  String get habitFocus25Name => 'Focus session 25 min';
  String get habitFocus25Desc => 'One distraction-free Pomodoro';
  String get habitEyes2020Name => '20-20-20 rule';
  String get habitEyes2020Desc => 'Every 20 min, look 20ft away for 20 sec';
  String get habitNeckName => 'Neck stretch';
  String get habitNeckDesc => '2 min neck and shoulder stretch every hour';
  String get habitBreathingBoxName => 'Box breathing';
  String get habitBreathingBoxDesc => '4s inhale, 4s hold, 4s exhale, 4s hold';
  String get habitWalkLunchName => 'Lunch walk';
  String get habitWalkLunchDesc => 'A 15-minute walk during your lunch break';
  String get habitDeskExName => 'Desk exercises';
  String get habitDeskExDesc => '5 min of active stretching every 2 hours';
  String get habitWaterMornName => 'Morning water';
  String get habitWaterMornDesc =>
      'A glass of water first thing in the morning';
  String get habitPostureName => 'Posture check';
  String get habitPostureDesc => 'Check and correct posture every hour';
  String get habitLunchParkName => 'Lunch at the park';
  String get habitLunchParkDesc => 'Eat outdoors, away from screens';
  String get habitBreathing478Name => '4-7-8 breathing';
  String get habitBreathing478Desc =>
      'Anti-anxiety: inhale 4s, hold 7s, exhale 8s';
  String get habitStretchName => 'Active stretching';
  String get habitStretchDesc => '5 minutes of full body movement';
  String get habitSnackName => 'Healthy snack';
  String get habitSnackDesc => 'A nutritious snack mid-morning';
  String get habitLunchNoScreenName => 'Screen-free lunch';
  String get habitLunchNoScreenDesc => 'Lunch without phone or computer';
  String get habitFocus50Name => 'Deep focus 50 min';
  String get habitFocus50Desc => 'An uninterrupted deep work session';
  String get habitMeditationName => 'Micro-meditation';
  String get habitMeditationDesc => '3 minutes of mindful presence';
  String get habitStairsName => 'Take the stairs';
  String get habitStairsDesc => 'Choose stairs over the lift';
  String get habitSleepName => 'Pre-sleep routine';
  String get habitSleepDesc => '30 minutes screen-free before bed';
  String get habitWakeName => 'Consistent wake time';
  String get habitWakeDesc => 'Wake at the same time every day';
  String get habitNapName => 'Power nap 20 min';
  String get habitNapDesc => 'A short intentional rest in the afternoon';
  String get habitFocusPhoneName => 'Focus without phone';
  String get habitFocusPhoneDesc => 'Phone face-down during focus sessions';
  String get habitMicroWalkName => '5-min micro walk';
  String get habitMicroWalkDesc =>
      '5 minutes walking every 90 minutes — ultradian cycle';
  String get habitDigitalSunsetName => 'Digital sunset';
  String get habitDigitalSunsetDesc =>
      'No social media in the hour before sleep';
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
  @override
  String get guideHowShoulderRoll =>
      'Sit tall with your arms relaxed. Lift your shoulders toward your ears, roll them back and then down in a slow circle. Your chest opens and your neck stays soft.';
  @override
  String get guideHowSpinalTwist =>
      'Sit tall. Turn your torso to the right, left hand on your right knee and right hand on the back of the chair. Look over your shoulder without forcing it, then repeat on the other side.';
  @override
  String get guideHowWrist =>
      'Lift your forearms in front of you, elbows resting. Keep your hands soft and draw slow circles with your wrists, one way and then the other.';
  @override
  String get guideHowNeckTilt =>
      'Sit tall with your shoulders low. Tilt your head toward your right shoulder, ear coming closer, without lifting the shoulder. Hold, breathe, then switch sides.';
  @override
  String get guideHowCatCow =>
      'Hands on your knees. As you breathe in, arch your back and open your chest, gaze slightly up. As you breathe out, round your back and bring your chin toward your chest.';
  @override
  String get guideHowNeckRoll =>
      'Sit tall with relaxed shoulders. Bring your chin toward your chest, then slowly roll your head in a wide, soft circle. If it feels tight, make the circle smaller.';
  @override
  String get guideHowShrug =>
      'With your arms relaxed at your sides, lift both shoulders toward your ears, hold for a moment, then let them drop. Feel your neck let go.';
  @override
  String get guideHowArmReach =>
      'Stand with your feet hip-width apart. Join your hands and reach your arms up, as if growing a little taller. Look slightly up, then lower slowly.';
  @override
  String get guideHowSideBend =>
      'Stand with your feet apart. Raise one arm overhead and bend your torso to the opposite side, other hand on your hip. Keep your hips still, breathe long, then switch sides.';
  @override
  String get guideHowHips =>
      'Hands on your hips, feet wide, knees soft. Draw a slow, wide circle with your pelvis while your upper body stays calm. Halfway through, reverse direction.';
  @override
  String get guideHowCalf =>
      'Stand holding a chair for balance. Rise onto the toes of both feet, hold for a second, then lower slowly. Keep your legs straight.';
  @override
  String get guideHowFold =>
      'Feet hip-width apart, knees soft. Fold forward from the hips, letting your head and arms hang. Don\'t force it: stay where you feel only a gentle stretch, then rise slowly.';
  @override
  String get guideSafetyNote =>
      'Move slowly and never force it: if something hurts, stop.';

  @override
  String get guidePhaseMove => 'Move';
  @override
  String get guidePhaseRest => 'Rest';
  @override
  String get guidePhaseRightHold => 'Turn right, hold';
  @override
  String get guidePhaseCenter => 'Back to center';
  @override
  String get guidePhaseLeftHold => 'Turn left, hold';
  @override
  String get guidePhaseClockwise => 'Clockwise';
  @override
  String get guidePhaseCounterClockwise => 'Counter-clockwise';
  @override
  String get guidePhaseArchCow => 'Arch your back (cow)';
  @override
  String get guidePhaseRoundCat => 'Round your back (cat)';
  @override
  String get guidePhaseRaiseHold => 'Raise, hold';
  @override
  String get guidePhaseLowerRelease => 'Lower and release';
  @override
  String get guidePhaseReachHold => 'Reach up, hold';
  @override
  String get guidePhaseLowerSlowly => 'Lower slowly';
  @override
  String get guidePhaseFoldHold => 'Fold forward, hold';
  @override
  String get guidePhaseRiseSlowly => 'Rise slowly';

  String get neverMissTwiceTitle => 'Don\'t miss two days in a row.';
  String get neverMissTwiceBody =>
      'One small action counts. Even a glass of water.';
  String get neverMissTwiceCta => '💧 Add a glass of water';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Triple points this round 🎉';

  String get coachDay1 => 'First day. The most important one.';
  String get coachDay3 => '3 days. Your body is starting to register it.';
  String get coachDay7 => '7 days. You\'re building something.';
  String get coachDay14 => '2 weeks. This habit is yours now.';
  String get coachGeneral => 'Every day counts. Even the hard ones.';

  String get badgeFirstStep => 'First step';
  String get badgeFirstStepDesc => 'First day completed';
  String get badgeOneWeek => 'One week';
  String get badgeOneWeekDesc => '7 days of habits';
  String get badgeThreeWeeks => 'Three weeks';
  String get badgeThreeWeeksDesc => '21 days completed';
  String get badgeSixWeeks => 'Six weeks';
  String get badgeSixWeeksDesc => '42 days completed';
  String get badgeThreeMonths => 'Three months';
  String get badgeThreeMonthsDesc => '90 days of growth';
  String get badgeInSync => 'In sync';
  String get badgeInSyncDesc => '2 active habits';
  String get badgeMultihabit => 'Multihabit';
  String get badgeMultihabitDesc => '4 active habits';
  String get badgeHydrated => 'Well hydrated';
  String get badgeHydratedDesc => 'Water consolidated';
  String get badgeFocused => 'In focus';
  String get badgeFocusedDesc => 'Focus 25 consolidated';
  String get badgeWalker => 'Walker';
  String get badgeWalkerDesc => 'Lunch walk consolidated';
  String get badgeBreath => 'Breath';
  String get badgeBreathDesc => 'Breathing consolidated';
  String get badgeRootedName => 'Rooted habits';
  String get badgeRootedDesc => 'Habits that became second nature';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Silver';
  String get badgeTierGold => 'Gold';
  String get growthNextGoal => 'Next goal';
  String growthHabitsToRoot(int n) =>
      n == 1 ? '1 habit to go' : '$n habits to go';

  String get habitChoiceTitle => 'Time to add something new.';
  String get habitChoiceSub => 'Choose where to focus next.';
  String get habitChoiceShowOther => 'show me other options ›';
  String get habitChoiceNotReady => 'I\'m not ready for this yet';
  String get habitChoiceOpen => 'Choose your next habit';
  String get habitNotReadySnoozed => 'No problem — I\'ll ask again in a week.';
  @override
  String get habitNotReadyMeanwhile => 'Try breathing instead';
  @override
  String habitMatchesGoal(String goal) => 'Matches your goal: $goal';
  String get consolidatedTitle => '🏆 Congratulations!';
  String consolidatedBody(String habitName) =>
      'You\'ve made "$habitName" a real habit — your brain has built a lasting circuit for it.';
  String get consolidatedBadge => 'Habit consolidated';
  String get consolidatedCta => 'Continue';
  @override
  String get consolidatedCtaNext => 'Choose your next habit →';
  @override
  String get automaticTitle => '💚 Automatic!';
  @override
  String automaticBody(String habitName) =>
      'You no longer have to think about "$habitName" — your brain runs it on its own now. This is the real finish line.';
  @override
  String get automaticBadge => 'Habit automatic';
  @override
  String get calendarTowardAssimilated => 'Toward becoming a habit';
  @override
  String get calendarTowardAutomatic => 'Toward automatic';
  @override
  String get calendarMilestoneSoon => 'ALMOST THERE';
  @override
  String calendarMilestoneInDays(int days) => 'IN $days DAYS';
  @override
  String get calendarAssimilatedTitle => 'Habit assimilated';
  @override
  String get calendarAssimilatedSub =>
      'Your brain starts registering it as routine — the chest opens.';
  @override
  String get calendarAutomaticTitle => 'Automatic habit';
  @override
  String get calendarAutomaticSub =>
      'The biggest milestone: you stop needing to think about it.';
  @override
  String get calendarLongArcNote =>
      'You\'re past the hardest part. Each day from here strengthens the automatic habit.';
  @override
  String get calendarDoneTitle => 'Automatic — well done';
  @override
  String calendarDoneSub(int points) =>
      'This habit now runs on its own. +$points points earned along the way.';
  @override
  String get dailyObjectivesTitle => 'Today\'s objectives';
  @override
  String dailyObjectivesSub(int done, int total) => done >= total && total > 0
      ? 'All done for today'
      : '$done of $total done today';
  @override
  String get badgeUnlockedTitle => '🏆 Badge unlocked!';
  @override
  String get badgeUnlockedCta => 'Awesome!';
  @override
  String get newMissionLabel => 'New mission';
  @override
  String get missionStartCta => 'Let\'s go!';
  @override
  String get missionStreakStart => 'Your streak starts right here.';
  @override
  String get missionStreakGoal =>
      '7 days to make it a habit, 66 to make it automatic.';
  @override
  String streakMilestoneTitle(int days) => '🔥 $days days in a row!';
  @override
  String get streakMilestoneBadge => 'Streak milestone';
  String habitStartsTomorrow(String habitName) =>
      'Great! Enjoy today\'s win — we\'ll start working on "$habitName" tomorrow.';
  @override
  String habitChosenIntro(String habitName) =>
      'Great! Enjoy today\'s win — "$habitName" starts tomorrow. Do it once, then keep it going: in 7 days it\'s yours, on autopilot after 66. You\'ll see the goal right on its card, every step of the way.';
  String get habitEffortLow => 'easy';
  String get habitEffortMedium => 'moderate';
  String get habitEffortHigh => 'challenging';

  String get errorNetwork => 'No internet connection';
  String get errorGeneral => 'Something went wrong. Try again.';
  String get errorInvalidEmail => 'Invalid email address';
  String get errorWeakPassword => 'Password is too weak';
  String get errorEmailInUse => 'This email is already in use';
  String get errorInvalidCredentials => 'Incorrect email or password';
  String get errorTooManyAttempts =>
      'Too many attempts. Account temporarily locked';
  String get errorTimeout => 'The server isn\'t responding. Try again shortly';
  String get errorCancelled => 'Sign-in cancelled';
  String get errorAccountDisabled => 'Account disabled. Contact support';
  @override
  String get errorRequiresRecentLogin =>
      'For your security, please sign in again before deleting your account.';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';
  @override
  String get deleteAccountConfirmBody =>
      'This permanently deletes your account and all your data — habits, streaks, points, badges. This can\'t be undone.';
  @override
  String get deleteAccountCta => 'Yes, delete everything';
  @override
  String get deleteAccountDone => 'Your account has been deleted.';
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
  String get accountLockedEmailSent =>
      'You\'ve received an email with instructions.';
  String get offlineLoginRequired =>
      'No connection — sign in requires internet';
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
  String get welcomeSlide1Sub =>
      'Be Well builds a plan tailored to you, based on your habits and goals.';
  @override
  String get welcomeSlide1Footer =>
      'Join everyone else already building healthier habits, one day at a time.';
  String get welcomeSlide2Title => 'Reminders that\nknow your calendar';
  String get welcomeSlide2Sub =>
      'Reminders adapt to your meetings and schedule, so they never interrupt you at the wrong time.';
  String get welcomeSlide3Title => 'Turn habits\ninto real rewards';
  String get welcomeSlide3Sub =>
      'Earn points by completing activities and redeem them for discounts, vouchers and more.';
  String get welcomeSkip => 'Skip';
  String get welcomeNext => 'Next →';
  String get welcomeStart => 'Start setup →';
  String get welcomeConfigureLater => 'Set up later';

  String get qProfileTitle => 'Tell us about you';
  String get qProfileSub => 'Helps us build the right plan for you.';
  String get qGoalsTitle => 'Goals & Stress';
  String get qGoalsSub =>
      'The most important screen for personalizing your plan.';
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
  String get calSyncNote =>
      '✓ We\'ll ask for permissions after you confirm your plan';
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
  String get crisisBody =>
      'Be Well is here to support you. If you need immediate help: contact a local helpline.';
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
  String get planPreviewSub =>
      'Personalized from your answers. You can always change it from Settings.';
  String get planRemindersPerDay => 'reminders/day';
  String get planFocusSessions => 'focus sessions';
  String get planPointsPerDay => 'points/day';
  String get planMorning => '🌅 Morning';
  String get planAfternoon => '☀️ Afternoon';
  String get planEvening => '🌙 Evening';
  String planFromTime(String time) => 'from $time';
  String planConnectCalendar(String name) => 'Connect $name';
  String get planConnectCalendarSub =>
      'We\'ll ask for permission after you confirm';
  String get planFallbackNote =>
      'We used a default plan. We\'ll refine it as you use the app.';
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
  String get resetTutorialBody =>
      'Welly will show all tutorial dialogs again as if it were your first time. Useful for testing the flow.';
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
  String get comingSoonBody =>
      'This section isn\'t available yet — it\'s on our roadmap.';
  String get habitMarkDone => 'Done';
  @override
  String get habitGoalFirstTime => '🎯 Goal: do it for the first time';
  @override
  String habitGoalInProgressToday(int count, int target) =>
      '🎯 $count/$target glasses today — finish them all for your first full day';
  @override
  String habitGoalBuilding(int days, int target) =>
      '🎯 Goal: build the routine — $days/$target days';
  @override
  String habitGoalBonus(int days, int target) =>
      '🌳 Habit set! Bonus goal: make it automatic — $days/$target days';
  @override
  String get habitGoalMastered => '💚 Automatic — goal reached';
  String get slowdownReasonHeavy => 'This habit feels like too much right now';
  String heatmapDaysAgo(int n) => '$n days ago';
  String get heatmapToday => 'today';
  String phaseStarted(String date) => 'started $date';
  String phaseReached(String date) => 'reached $date';
  String get marketAdTitle => 'Help Be Well';
  String get marketAdSubtitle => 'Earn 10 pts by watching a spot';
  @override
  String marketAdRemaining(int n) => '$n left today';
  @override
  String get marketAdCapReached =>
      'You\'ve reached today\'s limit — come back tomorrow';
  String get marketAdDialogBody =>
      'Watch an ad: you help keep the app free and instantly earn 10 points.';
  String get marketWatchNow => 'Watch now';
  String get dialogGotIt => 'Got it';
  String get marketAdUnavailable => 'Spot not available right now';
  String get referralTitle => 'Invite a friend';
  String get referralSubtitle => 'Earn 50 pts for every friend who signs up';
  String get referralApply => 'Apply';
  String get referralApplied =>
      'Code applied! Your friend will get the bonus soon. 🎉';
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
  String get waterGoalCalc =>
      'You need about N containers for your 2 litres a day';

  String get habitsMorningTitle => 'Start the day well.';
  String get habitsMiddayTitle => 'In the right moment.';
  String get habitsAfternoonTitle => 'Good afternoon.';
  String get habitsEveningTitle => 'How did it go today?';
  String get habitsNowLabel => 'Right now';
  String get habitsComingSoon => 'Coming up';
  String get configuratorTitle => 'Personalize your plan';
  String get configuratorSubtitle =>
      'Answer a few questions so Be Well can suggest the right habits for you';
  String get configuratorDoneTitle => 'Your plan is personalized';
  String get configuratorDoneSubtitle => 'Tap to update your answers';
  String get habitsAllDone => 'All good for now. Welly is with you.';
  String get habitsToday => 'Your rhythm today';
  String get completedToday => 'completed today';

  String get timeMorning => 'Morning';
  String get timeMidday => 'Mid-morning';
  String get timeLunch => 'Lunch break';
  String get timeAfternoon => 'Afternoon';
  String get timeEvening => 'Evening';

  String get onboardingUserTypeTitle => 'And how do you spend your days?';
  String get onboardingStudent => 'Study';
  String get onboardingWorker => 'Work';

  String get workScheduleBanner =>
      'I\'ve set standard days and hours (Mon–Fri, 9–13 / 14–18). Is that right for you?';
  String get workScheduleConfirm => 'That\'s fine';
  String get workScheduleEdit => 'Edit';
  String get workScheduleTitle => 'Your working hours';
  String get workScheduleMorning => 'Morning';
  String get workScheduleAfternoon => 'Afternoon';
  String get workScheduleLunch => 'I have a fixed lunch break';
  String get workScheduleSave => 'Save';

  String get slowdownPrompt =>
      'I noticed you\'re finding it a bit hard to keep the pace. Want to slow down a little?';
  String get slowdownYes => 'Yes, let\'s slow down';
  String get slowdownNo => 'No, I\'ll keep going';
  String get slowdownHabitMenu => 'I need more time with this one';
  String get slowdownMenuSubtitle =>
      'This pauses new habit suggestions for 2 weeks — this one stays in your plan either way.';
  String get slowdownWellyResponse =>
      'No problem — new suggestions are paused for 2 weeks. This habit stays in your plan, take the time you need.';
  String get speedupPrompt =>
      'You\'re doing really well — are you ready for something new ahead of schedule?';
  String get speedupYes => 'Yes, I\'m ready';
  String get speedupNo => 'No, I\'ll stay here';

  String get calendarTitle => 'Coming up today';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Break';
  String get calendarLongBreak => 'Long break';

  String get tutorialOk => 'Got it!';
  String get tutorialMore => 'Tell me more →';
  String get tutorialSkip => 'Skip';
  @override
  String get tutorialShowSource => 'Show source';
  String get tutorialNext => 'Next →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable => 'points available';
  String get marketplaceTabRewards => 'Rewards';
  String get marketplaceTabDiscounts => 'Discounts';
  String get marketplaceTabInApp => 'In-app';
  String get rewardsToRedeem => 'to redeem';
  String get rewardRedeemed => 'There it is. You earned it.';
  String get rewardConfirmTitle => 'Are you sure?';
  String get rewardConfirmBody =>
      'X points will be deducted from your balance.';
  String get rewardRedeemFailed =>
      'Couldn\'t redeem this reward — not enough points, or it\'s no longer available.';
  String get copyCode => 'Copy code';
  String get codeCopied => 'Copied';
  String get watchAd => 'Watch a spot · +10 pt';
  String get whyAds => 'why?';
  String get whyAdsTitle => 'Be Well is free for everyone';
  String get whyAdsBody =>
      'Be Well is a free app to be accessible to everyone. Like any service, it has running costs. By watching ads when you can, you help us keep the service running and improve it for everyone. Thank you.';
  String get discountsActive => 'active discounts';
  String get discountsNote =>
      'Discounts are updated monthly. No points required.';
  String get discountExclusive => 'exclusive Be Well';
  String get goToSite => 'Go to site';
  String get affiliateNote => 'This link supports Be Well';
  String get inAppWelly => 'welly';
  String get inAppSoundscape => 'soundscape';
  String get inAppMinigame => 'minigame';
  String get inAppPercorsi => 'paths';
  String get unlockItem => 'Unlock';
  String get itemUnlocked => 'Unlocked';
  String get premiumAllContent => 'All in-app content included';
  String get premiumPoints => '+20% points on every habit';
  String get premiumWelly => 'Fully customizable Welly';
  String get premiumDiscounts => 'Exclusive discounts in advance';
  String get premiumTrial => 'Try 7 days free';
  String get premiumOr => 'or buy individually with points';

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
      case 'home_welcome':
        return 'Welcome! I\'m Welly. Let me show you around so you can start the right way.';
      case 'home_water':
        return 'This is your first habit: drinking water. 8 glasses a day is your goal. Simple and powerful.';
      case 'home_add_glass':
        return 'Tap here every time you drink a glass. Each tap builds your habit — try it right now!';
      case 'home_welly':
        return 'That\'s me — Welly! I change expression based on your progress. The better you do, the more radiant I get.';
      case 'home_phase':
        return 'This is your Phase. You start at Seed — Phase 1. Build habits to grow all the way to Phase 5: Radiant.';
      case 'home_nav':
        return 'This is your navigation. Habits already has the 25-minute Focus ready to use; Growth opens after 14 days of consistency.';
      // Habits tour
      case 'habits_welcome':
        return 'From here you manage all your routines.';
      case 'habits_now':
        return 'The \'Right now\' card shows the habit most relevant to this exact moment of your day.';
      case 'habits_now_arc':
        return 'That number in the middle is how many days you\'ve completed this habit in total — not just today. Zero means you haven\'t done it even once yet: do it today and it becomes 1. Tap it anytime to see this again.';
      case 'habits_list':
        return 'All habits are sorted by their best time. Morning habits appear first in the morning — Welly knows your rhythm.';
      case 'habits_ready':
        return 'All set! Tap \'Complete\' every day to build your streak. Small actions, done consistently, change everything.';
      case 'habits_progression':
        return 'Your next habit unlocks on its own, once you\'ve truly made the current ones yours — not before. Each habit\'s card shows exactly where you stand: first time, building the routine, assimilated at 7 days, automatic at 66. No rush, no pressure: you set the pace.';
      // Marketplace tour
      case 'marketplace_welcome':
        return 'These are your Be Well Rewards! Every glass of water, every habit completed brings you here — where your efforts become real rewards.';
      case 'marketplace_points':
        return 'Your points balance is always visible here. It builds automatically as you build habits — nothing extra to do.';
      case 'marketplace_tabs':
        return 'Three tabs: Rewards to redeem with points; Discounts, exclusive offers that are always free, no points needed, refreshed monthly; and In-app, where you spend points on things inside Be Well itself — Welly outfits, soundscapes, mini-games, guided paths.';
      case 'marketplace_card':
        return 'Each reward has a cost in points. Tap to redeem — you\'ll get a code instantly. The more consistent you are, the more you unlock.';
      // Growth tour
      case 'growth_welcome':
        return 'This is your Growth. Not a ranking — a mirror. It shows who you\'re becoming, not just what you\'re doing.';
      case 'growth_phase':
        return 'Your phase reflects how deep your habits are rooted. From Phase 1 (Seed) to Phase 5 (Radiant) — each step is a real neurological change, not a game level.';
      case 'growth_heatmap':
        return 'This heatmap shows your consistency over time. Science says the pattern matters more than intensity: a few missed days don\'t reset everything.';
      case 'growth_badges':
        return 'Badges aren\'t decorations. Each one matches a behaviour you\'ve kept for a measurable period. They\'re proof of your journey.';
      default:
        return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitChosenIntro(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':
        return 'Welcome! This is your base. At the top you\'ll always find the most urgent habit for right now. Start there — everything else can wait.';
      case 'home_first_open_2':
        return 'Water is the first habit because it\'s the biological foundation for everything else. Without hydration, concentration drops by up to 20% after just 90 minutes.';
      case 'water_tracker_first':
        return 'The tracker counts glasses from when you open the app each morning. 8 a day is the target — but even hitting 5 is already better than yesterday.';
      case 'water_goal_intro':
        return 'Your next objective: drink all 8 glasses today for your first full day. Repeat it for 7 days total and the habit is assimilated, 66 makes it automatic. You\'ll always see it written on the card, one step at a time.';
      case 'first_completion':
        return 'Done! Every completion creates a new neural connection. Small, but real. Your brain has just strengthened a circuit.';
      case 'streak_explain':
        return 'If you come back tomorrow, your streak begins. The only rule that matters: never skip two days in a row. One stop is human. Two is a new habit — the wrong one.';
      case 'habits_tab_first':
        return 'Here you\'ll find all your habits sorted for the best moment in your day. Welly knows your rhythms — morning habits appear in the morning, evening ones in the evening.';
      case 'habit_card_explain':
        return 'The arc and the goal under the habit\'s name update every time you complete it. The target is spelled out: 7 days to make it a habit, 66 to make it automatic — no guessing, it\'s right there.';
      case 'focus_unlocked':
        return 'You have the 25-minute Focus available right from the start! The human brain has a natural concentration cycle of about 20–30 minutes — use it for a distraction-free work block.';
      case 'focus_unlocked_2':
        return 'Golden rule of Focus: when the timer starts, the phone goes face-down. Even Welly goes quiet. The notification you\'re waiting for can wait 25 minutes — I promise.';
      case 'calendar_appears':
        return 'New! The contextual calendar shows only the coming hours, not the whole day. Less to see = more mental space to act. The distant future isn\'t your problem yet.';
      case 'growth_first_visit':
        return 'This section shows who you\'re becoming, not just what you\'re doing. The phases aren\'t rewards — they\'re real descriptions of your neurological change. Science, not motivation, guides the journey.';
      case 'phase2_reached':
        return '🌱 Phase 2: Beginning! From here, Growth tracks your journey phase by phase. Your next habit unlocks only when you\'re ready — no rush, no pressure: you set the pace, and it\'s always fine to take more time.';
      case 'phase3_reached':
        return '🌿 Phase 3: Growth! Three habits consolidated. Your routine truly exists now — it\'s no longer an effort, it\'s a structure. The hardest part is behind you.';
      case 'phase4_reached':
        return '🌳 Phase 4: Roots. Seven habits absorbed — your routine has become a lifestyle. Most people never get here. You\'ve done it through consistency, not willpower.';
      case 'phase5_reached':
        return '🌸 Flourishing. You\'ve arrived. It doesn\'t mean it\'s over — it means you\'ve become someone who builds habits. That\'s the real result. Not the individual habits, but the ability.';
      case 'milestone_7_days':
        return '7 consecutive days! Science says that after this threshold, 90% of those who continue will reach 21. You\'re in the zone where change becomes much more likely.';
      case 'milestone_21_days':
        return '21 days! The old myth said 3 weeks was enough to form a habit. The truth: 21 days builds only the initial groove. Now starts the part where it truly becomes yours.';
      case 'milestone_66_days':
        return '66 days! This is the magic number from Phillippa Lally\'s UCL study. Officially, according to science, you\'ve formed a habit. You\'re not building it — you have it.';
      case 'streak_broken':
        return 'No problem. The rule is simple: never skip two days in a row. You\'re already back today — the streak restarts from now. Welly doesn\'t count the days you missed.';
      case 'no_completion_3days':
        return 'Welly is still here. No judgement. Coming back is easier than you think — even a single glass of water counts. One small act reactivates the loop.';
      case 'perfect_week':
        return 'Perfect week! 7 out of 7 completions. Your brain received 7 consecutive reinforcement signals. From a neurological standpoint, this week counted triple.';
      case 'rewards_first_visit':
        return 'Badges aren\'t fake points. Each badge corresponds to a real behaviour you\'ve maintained for a measurable period. They\'re snapshots of your progress, not decorations.';
      default:
        return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':
        return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first':
        return 'EFSA: daily water requirement 2.0–2.5 L for adults under normal conditions.';
      case 'first_completion':
        return 'Hebb (1949): "neurons that fire together, wire together" — each repetition strengthens the synapse.';
      case 'streak_explain':
        return 'James Clear, Atomic Habits: "Never miss twice" is the most effective rule for maintaining a habit.';
      case 'habit_card_explain':
        return 'Phillippa Lally (UCL, 2010): automaticity begins on average between 18 and 66 days, with the biggest growth in the first weeks.';
      case 'focus_unlocked':
        return 'Kleitman (1963): ultradian cycles of 90 min with attention peaks of 20–30 min. Pomodoro techniques leverage this rhythm.';
      case 'calendar_appears':
        return 'Sweller (1988): Cognitive Load Theory — fewer simultaneously visible pieces of information = better decisions.';
      case 'growth_first_visit':
        return 'Wood & Neal (2007): identity changes when behaviours become automatic. Identity precedes action.';
      case 'phase2_reached':
        return 'Gardner (2012): automaticity = execution without conscious intention. The first automatism is always the hardest.';
      case 'phase3_reached':
        return 'Lally et al. (2010): with 3 consolidated habits, long-term compliance rises significantly compared to just 1.';
      case 'phase4_reached':
        return 'Duhigg (2012): consolidated routines require almost zero conscious deliberation — the prefrontal cortex delegates to the basal ganglia.';
      case 'milestone_7_days':
        return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: automaticity grows most rapidly in the first weeks — initial consistency is the strongest predictor of long-term maintenance.';
      case 'milestone_21_days':
        return 'Maltz (1960): the "21 days" was a surgical observation, not a scientific study. Lally (2010) estimates 66 days on average.';
      case 'milestone_66_days':
        return 'Lally et al. (2010), UCL: average of 66 days (range 18–254) to reach behavioural automaticity.';
      case 'no_completion_3days':
        return 'Fogg (2020): Tiny Habits — even a minimal action keeps the habit neural loop alive.';
      case 'perfect_week':
        return 'Schultz et al. (1997): the dopaminergic system responds to the consistency of reinforcement — consecutive sequences amplify the effect.';
      default:
        return null;
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
  String get passwordForgotSub =>
      'Inserisci la tua email e ti invieremo un link di reset';
  String get sendResetEmail => 'Invia email di reset';
  String get backToLogin => 'Torna al login';
  String get emailSent => 'Email inviata';

  String get wellyHi => 'Ciao, sono Welly.';
  String get wellyIntro =>
      'Be Well è la prima app che ti guida passo passo nel costruire abitudini sane — e ti premia mentre lo fai. Non ti chiedo di cambiare tutto in un giorno. Ti chiedo solo di iniziare da una cosa piccola, e di farlo con me.';
  String get letsGo => 'Iniziamo';
  String get wellyNameQuestion => 'Prima di tutto: come vuoi chiamarmi?';
  String get wellyNameSub =>
      'Il mio nome è Welly, ma se preferisci puoi darmi un nome tutto tuo.';
  String get perfect => 'Perfetto';
  String get firstHabitTitle => 'Prima abitudine: l\'acqua.';
  String get firstHabitBody1 =>
      'Basta il 2% di disidratazione per calare concentrazione e umore — e in pochi bevono a sufficienza.';
  String get firstHabitBody2 =>
      'Partiamo da qui: 8 bicchieri al giorno. Ti ricorderò io quando bere, poi aggiungeremo nuove abitudini passo dopo passo.';
  String get drinkFirstGlass => 'Bevi il primo bicchiere adesso';
  String get rewardTitle => 'Perfetto. Uno.';
  String get rewardBody =>
      'Ogni volta che completi qualcosa, guadagni punti Be Well. Li accumulerai senza pensarci — e potrai usarli per buoni sconto, voucher, accessori, funzionalità premium nell\'app e molto altro ancora.';
  String get goToHome => 'Vai alla tua home';
  String get rewardLocked => 'Si sbloccano con i punti';
  @override
  String get previewDiscountTitle => 'Buono sconto';
  @override
  String get previewDiscountSub => '10% su partner selezionati';
  @override
  String get previewCoffeeTitle => 'Voucher caffè';
  @override
  String get previewCoffeeSub => 'Bevanda gratuita';
  @override
  String get previewPremiumTitle => 'Premium';
  @override
  String get previewPremiumSub => 'Funzioni avanzate';
  @override
  String get previewSurpriseTitle => 'Sorprese';
  @override
  String get previewSurpriseSub => 'E molto altro...';
  String get notifPermTitle => 'Un\'ultima cosa.';
  String get notifPermBody =>
      'Per aiutarti a restare costante, Welly ti manda qualche promemoria gentile nei momenti giusti della giornata. Niente spam, niente pressioni: quanti riceverne lo decidi tu, quando vuoi, dalle impostazioni.';
  String get notifPermAllow => 'Sì, attiva le notifiche';
  String get notifPermSkip => 'Magari dopo';
  String get waterUndo => 'Annulla ultimo';
  String get waterCooldown => 'Aspetta un attimo…';
  String get waterContainerBtn => 'Contenitore';

  String get goodMorning => 'Buongiorno,';
  @override
  String get goodAfternoon => 'Buon pomeriggio,';
  @override
  String get goodEvening => 'Buonasera,';
  String get greetingFallbackName => 'a te';
  String get phase => 'Fase';
  String get waterToday => 'Acqua oggi';
  String get waterGlasses => 'bicchieri';
  String get waterTrackedInHome => '💧 tracciata in Home';
  String get waterZero => 'Inizia con il primo bicchiere.';
  @override
  String get habitsEmptyTitle => 'Un\'abitudine alla volta';
  @override
  String get habitsEmptySubtitle =>
      'L\'acqua è il tuo punto di partenza oggi. La prossima si sblocca da sola quando questa ti sembrerà automatica — senza fretta.';
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
  String get noBadgesYet =>
      'I tuoi badge appariranno qui man mano che progredisci.';
  String get todayCompleted => 'Completato oggi';
  String get phase1 => 'Seme';
  String get phase2 => 'Germoglio';
  String get phase3 => 'Giovane';
  String get phase4 => 'Maturo';
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
  @override
  String get focusStartSession => 'Inizia la sessione';
  String get focusNewSession => 'Nuova sessione';
  String get focusDone => 'Sessione completata!';
  String get focusRemaining => 'rimanenti';
  String get focusSessions => 'sessioni';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'streak';
  String get focusDeepWork => 'Deep Work';
  String get focusMinRemaining => 'min rimasti';
  String get focusBlockOf4 => 'di 4';
  String get focusThenBreak => 'poi una pausa di 5 minuti';
  String get containerSize => 'Dimensione';
  String focusTimerSpoken(int m, int s) => '$m minuti $s secondi rimanenti';
  String waterGlassAnnounce(int n, int t) => 'Bicchiere $n di $t registrato';
  String habitRingSpoken(int n) => '$n giorni completati in totale';
  String get passwordShow => 'Mostra password';
  String get passwordHide => 'Nascondi password';
  String get waterAlmost => 'Ci sei quasi, ancora un poco.';
  String get reduceMotion => 'Riduci i movimenti';
  String get reduceMotionDesc => 'Rende più calme animazioni ed elementi in movimento';
  String get accessibilityHint => 'Queste impostazioni valgono per tutta l\'app. Be Well segue anche la dimensione del testo e le animazioni impostate nel telefono.';
  String get leaveSessionTitle => 'Uscire dalla sessione?';
  String get leaveSessionBody => 'Se esci adesso questa sessione non verrà conteggiata e dovrai ricominciare dall\'inizio. Vuoi continuare?';
  String get leaveSessionStay => 'Continua';
  String get leaveSessionLeave => 'Esci comunque';
  String waterNextGlassIn(String time) => 'Prossimo bicchiere tra $time';
  String get workScheduleStart => 'Inizio';
  String get workScheduleEnd => 'Fine';
  String get workScheduleTime => 'Orario';
  String get workScheduleDays => 'Giorni di lavoro o studio';
  String get workScheduleInviteTitle => 'Dimmi i tuoi giorni e orari';
  String get workScheduleInviteBody => 'Così sistemo i promemoria intorno a quando lavori o studi e li tengo più leggeri nei giorni liberi. Puoi cambiarli sempre da Abitudini.';
  String get workScheduleInviteSet => 'Imposta ora';
  String get workScheduleInviteLater => 'Più tardi';
  String get wdMon => 'Lun';
  String get wdTue => 'Mar';
  String get wdWed => 'Mer';
  String get wdThu => 'Gio';
  String get wdFri => 'Ven';
  String get wdSat => 'Sab';
  String get wdSun => 'Dom';
  String get notifInviteTitle => 'I promemoria sono spenti';
  String get notifInviteBody => 'Piccoli promemoria nei momenti giusti sono uno degli aiuti migliori per trasformare le azioni in abitudini. Riattivali: quanti riceverne lo decidi tu nelle Impostazioni.';
  String get notifInviteAction => 'Riattiva';
  String get notifInviteLater => 'Non ora';
  String get notifComebackTitle1 => 'Ti aspetto quando vuoi 🌱';
  String get notifComebackBody1 => 'Sono passati un po\' di giorni. Basta un bicchiere d\'acqua per ripartire, senza fretta.';
  String get notifComebackTitle2 => 'Nessuna pressione';
  String get notifComebackBody2 => 'Anche un passo piccolo conta. Riprendi quando ti va: i tuoi progressi sono al sicuro.';
  String get notifComebackTitle3 => 'Welly pensa a te';
  String get notifComebackBody3 => 'Le tue abitudini ti aspettano esattamente dove le hai lasciate.';
  String get notifComebackTitle4 => 'Ripartire è semplice';
  String get notifComebackBody4 => 'Un bicchiere d\'acqua e hai già ricominciato.';
  String get resetAllTitle => 'Ricomincia da zero';
  String get resetAllSubtitle => 'Cancella tutti i progressi e riparti';
  String get resetAllConfirmTitle => 'Ricominciare da zero?';
  String get resetAllConfirmBody => 'Cancelliamo abitudini, giorni, streak, punti e impostazioni da questo telefono e dal tuo account nel cloud. Rivedrai l\'accoglienza come se fosse la prima volta. Non si può annullare.';
  String get resetAllConfirmButton => 'Cancella tutto';
  String get notifFocusRunningTitle => '🎯 Focus in corso';
  String get notifFocusRunningBody => 'Una cosa alla volta. Tocca per tornare al timer.';
  String get notifFocusPausedTitle => '⏸ Focus in pausa';
  String get notifFocusPausedBody => 'Con calma: riprendi quando vuoi.';
  String get dayOne => 'giorno';
  String get wellyMsgMorning => 'Buongiorno! Un bicchiere d\x27acqua e la giornata parte col piede giusto.';
  String get wellyMsgAfternoon => 'Ci sei ancora? Un sorso d\x27acqua e una piccola pausa ti faranno bene.';
  String get wellyMsgEvening => 'La giornata sta finendo, va bene così. Se ti va, un ultimo bicchiere e poi riposa.';
  String get wellyMsgAllDone => 'Oggi hai fatto tutto quello che serviva. Goditi il resto della giornata.';
  String get wellyMsgWaterDone => 'Acqua completata, ottimo ritmo. Il resto è un di più.';
  String wellyMsgWaterProgress(int n, int t) => 'Bene così: $n su $t bicchieri. Senza fretta.';

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
  String get notifWaterBody =>
      'Il primo bicchiere d\'acqua è un buon modo per iniziare la giornata.';
  String get notifMiddayTitle => '🧘 Be Well';
  String get notifMiddayBody =>
      'Due minuti per stirarti o respirare — la concentrazione ti ringrazierà dopo.';
  String get notifLunchTitle => '🍃 Be Well';
  String get notifLunchBody =>
      'Una pausa vera aiuta: metti giù lo schermo qualche minuto mentre mangi.';
  String get notifAfternoonTitle => '👀 Be Well';
  String get notifAfternoonBody =>
      'Occhi stanchi dallo schermo? 20 secondi a guardare lontano aiutano davvero.';
  String get notifEveningTitle => 'Be Well 🌙';
  String get notifEveningBody =>
      'C\'è ancora tempo per un\'ultima abitudine oggi, se ti va — altrimenti a domani.';
  String get notifHabitChoiceTitle => '✨ Nuova abitudine disponibile';
  String get notifHabitChoiceBody =>
      'Apri Be Well per scegliere la tua prossima abitudine.';

  @override
  String get notifFocusTitle => '🎯 Momento di Focus';
  @override
  String get notifFocusBody =>
      'Quando vuoi: un blocco di concentrazione, senza fretta.';
  @override
  String get notifBundleTitle => '🌿 Be Well';
  @override
  String notifBundleMorningBody(String list) => 'Per iniziare bene: $list.';
  @override
  String notifBundleBreakBody(String list) => 'Una pausa gentile: $list.';
  @override
  String notifBundleEveningBody(String list) =>
      'Per chiudere bene la giornata: $list.';
  @override
  String get notifFocusDoneTitle => '✨ Blocco completato';
  @override
  String notifFocusDoneBody(String list) =>
      'Ottimo lavoro. Ora respira un attimo: $list.';
  @override
  String get notifFocusDoneBodyPlain => 'Ottimo lavoro. Ora respira un attimo.';
  @override
  String get notifAndWord => 'e';

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
  String get navUnlockHabitsMsg =>
      'Completa 14 giorni di acqua per sbloccare le abitudini.';
  String get navUnlockGrowthMsg =>
      'Crescita si apre dopo 14 giorni di costanza con un\'abitudine: la stai già costruendo.';
  String get comingSoonHabitsDesc =>
      'Completa 14 giorni di acqua.\nLa tua prima nuova abitudine si sbloccherà qui.';
  String get comingSoonGrowthDesc =>
      'Continua a costruire le tue abitudini.\nLa schermata di crescita si sbloccherà presto.';
  String get achievementUnlocked => 'Achievement sbloccato!';
  String get newHabitUnlocked => 'Nuova abitudine sbloccata!';

  String get rewards => 'Premi';
  String get rewardsPoints => 'Punti Be Well';
  String get rewardsLocked => 'I premi stanno arrivando';
  String get rewardsLockedDesc =>
      'Continua a costruire abitudini per sbloccare i tuoi premi';
  String get rewardsHeader => 'I tuoi premi';
  String get rewardsHeaderSub => 'Raccogli quello che hai seminato';

  String get habitWaterName => 'Bevi acqua';
  String get habitWaterDesc => '8 bicchieri durante la giornata';
  String get habitFocus25Name => 'Sessione focus 25 min';
  String get habitFocus25Desc => 'Un Pomodoro senza distrazioni';
  String get habitEyes2020Name => 'Regola 20-20-20';
  String get habitEyes2020Desc => 'Ogni 20 min, guarda a 6m per 20 sec';
  String get habitNeckName => 'Stretching collo';
  String get habitNeckDesc => '2 min di stretching collo e spalle ogni ora';
  String get habitBreathingBoxName => 'Respirazione box';
  String get habitBreathingBoxDesc =>
      '4s inspira, 4s trattieni, 4s espira, 4s trattieni';
  String get habitWalkLunchName => 'Passeggiata pausa pranzo';
  String get habitWalkLunchDesc => 'Una camminata di 15 min durante la pausa';
  String get habitDeskExName => 'Esercizi alla scrivania';
  String get habitDeskExDesc => '5 min di stretching attivo ogni 2 ore';
  String get habitWaterMornName => 'Acqua appena svegli';
  String get habitWaterMornDesc => 'Un bicchiere d\'acqua come prima cosa';
  String get habitPostureName => 'Check postura';
  String get habitPostureDesc => 'Controlla e correggi la postura ogni ora';
  String get habitLunchParkName => 'Pranzo al parco';
  String get habitLunchParkDesc => 'Mangia fuori, all\'aperto, senza schermo';
  String get habitBreathing478Name => 'Respirazione 4-7-8';
  String get habitBreathing478Desc =>
      'Anti-ansia: inspira 4s, trattieni 7s, espira 8s';
  String get habitStretchName => 'Stretching attivo';
  String get habitStretchDesc => '5 minuti di movimento globale del corpo';
  String get habitSnackName => 'Spuntino sano';
  String get habitSnackDesc => 'Un piccolo spuntino nutriente a metà mattina';
  String get habitLunchNoScreenName => 'Pranzo senza schermo';
  String get habitLunchNoScreenDesc =>
      'Il pranzo lontano da telefono e computer';
  String get habitFocus50Name => 'Focus profondo 50 min';
  String get habitFocus50Desc =>
      'Una sessione di lavoro profondo senza interruzioni';
  String get habitMeditationName => 'Micro-meditazione';
  String get habitMeditationDesc => '3 minuti di presenza consapevole';
  String get habitStairsName => 'Scala invece ascensore';
  String get habitStairsDesc => 'Scegli le scale ogni volta che puoi';
  String get habitSleepName => 'Routine pre-sonno';
  String get habitSleepDesc => '30 minuti senza schermi prima di dormire';
  String get habitWakeName => 'Sveglia costante';
  String get habitWakeDesc => 'Alzati sempre alla stessa ora';
  String get habitNapName => 'Power nap 20 min';
  String get habitNapDesc => 'Un riposo breve e intenzionale nel pomeriggio';
  String get habitFocusPhoneName => 'Focus senza telefono';
  String get habitFocusPhoneDesc => 'Telefono capovolto durante il focus';
  String get habitMicroWalkName => 'Micro-camminata 5 min';
  String get habitMicroWalkDesc =>
      '5 minuti di camminata ogni 90 minuti — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Digital sunset';
  String get habitDigitalSunsetDesc =>
      'Niente social media nell\'ora prima di dormire';
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
  @override
  String get guideHowShoulderRoll =>
      'Siediti con la schiena dritta e le braccia rilassate. Solleva le spalle verso le orecchie, portale indietro e poi giù, in un cerchio lento. Il petto si apre, il collo resta morbido.';
  @override
  String get guideHowSpinalTwist =>
      'Seduto, con la schiena dritta. Ruota il busto verso destra, con la mano sinistra sul ginocchio destro e la destra sullo schienale. Guarda oltre la spalla senza forzare, poi ripeti dall\'altro lato.';
  @override
  String get guideHowWrist =>
      'Solleva gli avambracci davanti a te, con i gomiti appoggiati. Lascia le mani morbide e disegna cerchi lenti con i polsi, prima in un verso, poi nell\'altro.';
  @override
  String get guideHowNeckTilt =>
      'Siediti dritto con le spalle basse. Inclina la testa verso la spalla destra, avvicinando l\'orecchio, senza alzare la spalla. Tieni, respira, poi cambia lato.';
  @override
  String get guideHowCatCow =>
      'Mani sulle ginocchia. Inspirando, arcua la schiena e apri il petto, con lo sguardo leggermente in alto. Espirando, arrotonda la schiena e porta il mento verso il petto.';
  @override
  String get guideHowNeckRoll =>
      'Siediti dritto con le spalle rilassate. Porta il mento verso il petto, poi ruota lentamente la testa in un cerchio ampio e morbido. Se senti tensione, fai il cerchio più piccolo.';
  @override
  String get guideHowShrug =>
      'Con le braccia rilassate lungo i fianchi, solleva entrambe le spalle verso le orecchie, tieni un attimo e poi lasciale cadere. Senti il collo che si scioglie.';
  @override
  String get guideHowArmReach =>
      'In piedi, con i piedi alla larghezza dei fianchi. Unisci le mani e allunga le braccia verso l\'alto, come per crescere di qualche centimetro. Guarda leggermente in su, poi abbassa piano.';
  @override
  String get guideHowSideBend =>
      'In piedi, gambe aperte. Alza un braccio sopra la testa e inclina il busto dal lato opposto, con l\'altra mano sul fianco. Bacino fermo, respiro lungo, poi cambia lato.';
  @override
  String get guideHowHips =>
      'Mani sui fianchi, piedi larghi e ginocchia morbide. Disegna con il bacino un cerchio lento e ampio, mentre il busto resta calmo. A metà ripetizioni, inverti il verso.';
  @override
  String get guideHowCalf =>
      'In piedi, con le mani appoggiate a una sedia per l\'equilibrio. Sollevati sulle punte di entrambi i piedi, tieni un secondo e scendi piano. Le gambe restano dritte.';
  @override
  String get guideHowFold =>
      'Piedi alla larghezza dei fianchi, ginocchia morbide. Piegati in avanti dai fianchi lasciando cadere testa e braccia. Non forzare: fermati dove senti solo un leggero allungamento e risali piano.';
  @override
  String get guideSafetyNote =>
      'Muoviti piano e senza forzare: se senti dolore, fermati.';

  @override
  String get guidePhaseMove => 'Muovi';
  @override
  String get guidePhaseRest => 'Riposa';
  @override
  String get guidePhaseRightHold => 'Gira a destra, tieni';
  @override
  String get guidePhaseCenter => 'Torna al centro';
  @override
  String get guidePhaseLeftHold => 'Gira a sinistra, tieni';
  @override
  String get guidePhaseClockwise => 'Senso orario';
  @override
  String get guidePhaseCounterClockwise => 'Senso antiorario';
  @override
  String get guidePhaseArchCow => 'Inarca la schiena (mucca)';
  @override
  String get guidePhaseRoundCat => 'Arrotonda la schiena (gatto)';
  @override
  String get guidePhaseRaiseHold => 'Alza, tieni';
  @override
  String get guidePhaseLowerRelease => 'Abbassa e rilascia';
  @override
  String get guidePhaseReachHold => 'Allunga verso l\'alto, tieni';
  @override
  String get guidePhaseLowerSlowly => 'Abbassa lentamente';
  @override
  String get guidePhaseFoldHold => 'Piega in avanti, tieni';
  @override
  String get guidePhaseRiseSlowly => 'Risali lentamente';

  String get neverMissTwiceTitle => 'Stai per saltare due giorni di fila.';
  String get neverMissTwiceBody =>
      'Una sola azione conta. Anche un bicchiere d\'acqua.';
  String get neverMissTwiceCta => '💧 Aggiungi un bicchiere d\'acqua';
  String get wellyBonusTitle => 'Welly Bonus!';
  String get wellyBonusBody => 'Punti tripli questo giro 🎉';

  String get coachDay1 => 'Primo giorno. Il più importante.';
  String get coachDay3 => '3 giorni. Il corpo inizia a registrarlo.';
  String get coachDay7 => '7 giorni. Stai costruendo qualcosa.';
  String get coachDay14 => '2 settimane. Questa abitudine è tua adesso.';
  String get coachGeneral => 'Ogni giorno conta. Anche i giorni difficili.';

  String get badgeFirstStep => 'Primo passo';
  String get badgeFirstStepDesc => 'Primo giorno completato';
  String get badgeOneWeek => 'Una settimana';
  String get badgeOneWeekDesc => '7 giorni di abitudini';
  String get badgeThreeWeeks => 'Tre settimane';
  String get badgeThreeWeeksDesc => '21 giorni completati';
  String get badgeSixWeeks => 'Un mese e mezzo';
  String get badgeSixWeeksDesc => '42 giorni completati';
  String get badgeThreeMonths => 'Tre mesi';
  String get badgeThreeMonthsDesc => '90 giorni di crescita';
  String get badgeInSync => 'In sincronia';
  String get badgeInSyncDesc => '2 abitudini attive';
  String get badgeMultihabit => 'Multihabit';
  String get badgeMultihabitDesc => '4 abitudini attive';
  String get badgeHydrated => 'Ben idratato';
  String get badgeHydratedDesc => 'Acqua consolidata';
  String get badgeFocused => 'In focus';
  String get badgeFocusedDesc => 'Focus 25 min consolidato';
  String get badgeWalker => 'Camminatore';
  String get badgeWalkerDesc => 'Passeggiata pranzo consolidata';
  String get badgeBreath => 'Respiro';
  String get badgeBreathDesc => 'Respirazione consolidata';
  String get badgeRootedName => 'Abitudini radicate';
  String get badgeRootedDesc => 'Abitudini diventate una seconda natura';
  String get badgeTierBronze => 'Bronzo';
  String get badgeTierSilver => 'Argento';
  String get badgeTierGold => 'Oro';
  String get growthNextGoal => 'Prossimo obiettivo';
  String growthHabitsToRoot(int n) =>
      n == 1 ? 'Manca 1 abitudine' : 'Mancano $n abitudini';

  String get habitChoiceTitle =>
      'È il momento di aggiungere\nqualcosa di nuovo.';
  String get habitChoiceSub => 'Scegli dove concentrarti adesso.';
  String get habitChoiceShowOther => 'mostrami altre opzioni ›';
  String get habitChoiceNotReady => 'Non mi sento pronto/a';
  String get habitChoiceOpen => 'Scegli la prossima abitudine';
  String get habitNotReadySnoozed =>
      'Nessun problema — te lo richiederò tra una settimana.';
  @override
  String get habitNotReadyMeanwhile => 'Prova il respiro, intanto';
  @override
  String habitMatchesGoal(String goal) => 'In linea con: $goal';
  String get consolidatedTitle => '🏆 Complimenti!';
  String consolidatedBody(String habitName) =>
      'Hai reso "$habitName" una vera abitudine — il tuo cervello ha costruito un circuito duraturo per lei.';
  String get consolidatedBadge => 'Abitudine consolidata';
  String get consolidatedCta => 'Continua';
  @override
  String get consolidatedCtaNext => 'Scegli la prossima abitudine →';
  @override
  String get automaticTitle => '💚 Automatica!';
  @override
  String automaticBody(String habitName) =>
      'Non devi più pensarci: "$habitName" ormai la fa il tuo cervello da solo. Questo è il vero traguardo finale.';
  @override
  String get automaticBadge => 'Abitudine automatica';
  @override
  String get calendarTowardAssimilated => 'Verso l\'abitudine';
  @override
  String get calendarTowardAutomatic => 'Verso l\'automatismo';
  @override
  String get calendarMilestoneSoon => 'CI SEI QUASI';
  @override
  String calendarMilestoneInDays(int days) => 'TRA $days GIORNI';
  @override
  String get calendarAssimilatedTitle => 'Abitudine assimilata';
  @override
  String get calendarAssimilatedSub =>
      'Il cervello la registra come routine — il forziere si apre.';
  @override
  String get calendarAutomaticTitle => 'Abitudine automatica';
  @override
  String get calendarAutomaticSub =>
      'Il traguardo più grande: non devi più pensarci.';
  @override
  String get calendarLongArcNote =>
      'Hai superato la parte più difficile. Ogni giorno da qui in poi rafforza l\'automatismo.';
  @override
  String get calendarDoneTitle => 'Automatica — ce l\'hai fatta';
  @override
  String calendarDoneSub(int points) =>
      'Ormai questa abitudine va avanti da sola. +$points punti guadagnati lungo il percorso.';
  @override
  String get dailyObjectivesTitle => 'Obiettivi di oggi';
  @override
  String dailyObjectivesSub(int done, int total) => done >= total && total > 0
      ? 'Tutto fatto per oggi'
      : '$done su $total fatti oggi';
  @override
  String get badgeUnlockedTitle => '🏆 Badge sbloccato!';
  @override
  String get badgeUnlockedCta => 'Fantastico!';
  @override
  String get newMissionLabel => 'Nuova missione';
  @override
  String get missionStartCta => 'Si comincia!';
  @override
  String get missionStreakStart => 'La tua streak parte da qui.';
  @override
  String get missionStreakGoal =>
      '7 giorni per assimilarla, 66 per renderla automatica.';
  @override
  String streakMilestoneTitle(int days) => '🔥 $days giorni di fila!';
  @override
  String get streakMilestoneBadge => 'Traguardo streak';
  String habitStartsTomorrow(String habitName) =>
      'Molto bene! Oggi goditi il traguardo — inizieremo a lavorare su "$habitName" da domani.';
  @override
  String habitChosenIntro(String habitName) =>
      'Molto bene! Oggi goditi il traguardo — "$habitName" comincia domani. Falla una volta, poi tienila viva: a 7 giorni è assimilata, a 66 diventa automatica. Vedrai l\'obiettivo direttamente sulla sua card, passo dopo passo.';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'moderato';
  String get habitEffortHigh => 'impegnativo';

  String get errorNetwork => 'Nessuna connessione internet';
  String get errorGeneral => 'Qualcosa è andato storto. Riprova.';
  String get errorInvalidEmail => 'Indirizzo email non valido';
  String get errorWeakPassword => 'La password è troppo debole';
  String get errorEmailInUse => 'Questa email è già in uso';
  String get errorInvalidCredentials => 'Email o password errati';
  String get errorTooManyAttempts =>
      'Troppi tentativi. Account bloccato temporaneamente';
  String get errorTimeout => 'Il server non risponde. Riprova tra poco';
  String get errorCancelled => 'Accesso annullato';
  String get errorAccountDisabled =>
      'Account disabilitato. Contatta il supporto';
  @override
  String get errorRequiresRecentLogin =>
      'Per sicurezza, accedi di nuovo prima di eliminare il tuo account.';
  @override
  String get deleteAccount => 'Elimina account';
  @override
  String get deleteAccountConfirmTitle => 'Eliminare il tuo account?';
  @override
  String get deleteAccountConfirmBody =>
      'Elimina definitivamente il tuo account e tutti i tuoi dati — abitudini, streak, punti, badge. Non si può annullare.';
  @override
  String get deleteAccountCta => 'Sì, elimina tutto';
  @override
  String get deleteAccountDone => 'Il tuo account è stato eliminato.';
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
  String get accountLockedEmailSent =>
      'Hai ricevuto un\'email con le istruzioni.';
  String get offlineLoginRequired =>
      'Nessuna connessione — il login richiede internet';
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
  String get welcomeSlide1Sub =>
      'Be Well costruisce un piano su misura per te, basato sulle tue abitudini e obiettivi.';
  @override
  String get welcomeSlide1Footer =>
      'Ti unisci a chi sta già costruendo abitudini più sane, un giorno alla volta.';
  String get welcomeSlide2Title => 'Reminder che\nconosco il tuo calendario';
  String get welcomeSlide2Sub =>
      'I promemoria si adattano ai tuoi meeting e orari, così non ti interrompono mai nel momento sbagliato.';
  String get welcomeSlide3Title => 'Trasforma le abitudini\nin premi reali';
  String get welcomeSlide3Sub =>
      'Guadagna punti completando attività e riscattali per sconti, voucher e molto altro.';
  String get welcomeSkip => 'Salta';
  String get welcomeNext => 'Avanti →';
  String get welcomeStart => 'Inizia la configurazione →';
  String get welcomeConfigureLater => 'Configura dopo';

  String get qProfileTitle => 'Parlaci di te';
  String get qProfileSub => 'Ci aiuta a costruire il piano giusto per te.';
  String get qGoalsTitle => 'Obiettivi & Stress';
  String get qGoalsSub =>
      'La schermata più importante per personalizzare il tuo piano.';
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
  String get calSyncNote =>
      '✓ Ti chiederemo i permessi dopo aver confermato il piano';
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
  String get crisisBody =>
      'Be Well è qui per supportarti. Se hai bisogno di aiuto immediato: Telefono Amico 02 2327 2327';
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
  String get planPreviewSub =>
      'Personalizzato sulle tue risposte. Potrai sempre modificarlo da Impostazioni.';
  String get planRemindersPerDay => 'reminder/giorno';
  String get planFocusSessions => 'sessioni focus';
  String get planPointsPerDay => 'punti/giorno';
  String get planMorning => '🌅 Mattina';
  String get planAfternoon => '☀️ Pomeriggio';
  String get planEvening => '🌙 Sera';
  String planFromTime(String time) => 'dalle $time';
  String planConnectCalendar(String name) => 'Connetti $name';
  String get planConnectCalendarSub =>
      'Richiederemo il permesso dopo la conferma';
  String get planFallbackNote =>
      'Abbiamo usato un piano di default. Lo raffineremo man mano che usi l\'app.';
  String get planConfirmCta => 'Inizia con Be Well  ';
  String get planConfirmSub =>
      'Potrai modificare il piano in qualsiasi momento da Impostazioni';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Profilo';
  String get accountSection => 'Account';
  String get emailAccountLabel => 'Email account';
  String get supportSection => 'Supporto';
  String get editNameTitle => 'Modifica nome';
  String get yourNameHint => 'Il tuo nome';
  String get resetTutorialTitle => 'Reset tutorial';
  String get resetTutorialBody =>
      'Welly mostrerà di nuovo tutti i dialoghi tutorial come se fosse la prima volta. Utile per testare il flusso.';
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
  String get comingSoonBody =>
      'Questa sezione non è ancora disponibile — è nella nostra roadmap.';
  String get habitMarkDone => 'Fatto';
  @override
  String get habitGoalFirstTime => '🎯 Obiettivo: falla per la prima volta';
  @override
  String habitGoalInProgressToday(int count, int target) =>
      '🎯 $count/$target bicchieri oggi — completali tutti per il primo giorno pieno';
  @override
  String habitGoalBuilding(int days, int target) =>
      '🎯 Obiettivo: costruisci la routine — $days/$target giorni';
  @override
  String habitGoalBonus(int days, int target) =>
      '🌳 Abitudine assimilata! Obiettivo bonus: rendila automatica — $days/$target giorni';
  @override
  String get habitGoalMastered => '💚 Automatica — obiettivo raggiunto';
  String get slowdownReasonHeavy => 'Questa abitudine mi pesa troppo';
  String heatmapDaysAgo(int n) => '$n giorni fa';
  String get heatmapToday => 'oggi';
  String phaseStarted(String date) => 'iniziato $date';
  String phaseReached(String date) => 'raggiunto $date';
  String get marketAdTitle => 'Aiuta Be Well';
  String get marketAdSubtitle => 'Guadagna 10 pt guardando uno spot';
  @override
  String marketAdRemaining(int n) => 'Ancora $n oggi';
  @override
  String get marketAdCapReached =>
      'Hai raggiunto il limite di oggi — torna domani';
  String get marketAdDialogBody =>
      'Guarda uno spot pubblicitario: ci aiuti a mantenere l\'app gratuita e guadagni subito 10 punti.';
  String get marketWatchNow => 'Guarda ora';
  String get dialogGotIt => 'Capito';
  String get marketAdUnavailable => 'Spot non disponibile al momento';
  String get referralTitle => 'Invita un amico';
  String get referralSubtitle => 'Guadagna 50 pt per ogni amico che si iscrive';
  String get referralApply => 'Applica';
  String get referralApplied =>
      'Codice applicato! Il tuo amico riceverà presto il bonus. 🎉';
  String get referralErrorInvalid => 'Codice non valido';
  String get referralErrorOwn => 'Non puoi usare il tuo codice';
  String get referralErrorAlready => 'Hai già riscattato un codice invito';
  String get referralErrorNotSignedIn => 'Devi essere loggato';
  String get referralErrorGeneric => 'Qualcosa è andato storto, riprova';
  String get referralHint => 'Hai un codice invito?';
  String premiumPrice(String price) => '$price/mese';
  String referralShareButton(String code) => 'Condividi il mio codice · $code';
  String get referralRetry =>
      'Generazione codice non riuscita — tocca per riprovare';
  String referralShareMessage(String code) =>
      'Sto usando Be Well per costruire abitudini più sane, giorno dopo giorno 🌱\n'
      'Scarica l\'app e usa il mio codice invito "$code" — per te 50 punti bonus non appena inizi!';

  String get waterContainerGlass => 'bicchiere';
  String get waterContainerBottle => 'borraccia';
  String get waterContainerSettings => 'Come stai tracciando l\'acqua?';
  String get waterGoalCalc =>
      'Ci vogliono circa N contenitori per i tuoi 2 litri al giorno';

  String get habitsMorningTitle => 'Inizia bene la giornata.';
  String get habitsMiddayTitle => 'Nel momento giusto.';
  String get habitsAfternoonTitle => 'Buon pomeriggio.';
  String get habitsEveningTitle => 'Come è andata oggi?';
  String get habitsNowLabel => 'Adesso';
  String get habitsComingSoon => 'Prossimamente';
  String get configuratorTitle => 'Personalizza il tuo piano';
  String get configuratorSubtitle =>
      'Rispondi a qualche domanda: Be Well ti suggerirà le abitudini più adatte a te';
  String get configuratorDoneTitle => 'Il tuo piano è personalizzato';
  String get configuratorDoneSubtitle => 'Tocca per aggiornare le tue risposte';
  String get habitsAllDone => 'Tutto sotto controllo per ora. Welly è con te.';
  String get habitsToday => 'Il tuo ritmo oggi';
  String get completedToday => 'completate oggi';

  String get timeMorning => 'Mattina';
  String get timeMidday => 'Metà mattina';
  String get timeLunch => 'Pausa pranzo';
  String get timeAfternoon => 'Pomeriggio';
  String get timeEvening => 'Sera';

  String get onboardingUserTypeTitle => 'E come passi le tue giornate?';
  String get onboardingStudent => 'Studio';
  String get onboardingWorker => 'Lavoro';

  String get workScheduleBanner =>
      'Ho messo orari standard (lun–ven, 9-13 / 14-18). Vanno bene per te?';
  String get workScheduleConfirm => 'Va bene così';
  String get workScheduleEdit => 'Modifica';
  String get workScheduleTitle => 'I tuoi orari di lavoro';
  String get workScheduleMorning => 'Mattina';
  String get workScheduleAfternoon => 'Pomeriggio';
  String get workScheduleLunch => 'Ho una pausa pranzo fissa';
  String get workScheduleSave => 'Salva';

  String get slowdownPrompt =>
      'Ho notato che stai trovando un po\' difficile mantenere il ritmo. Vuoi che rallentiamo un po\'?';
  String get slowdownYes => 'Sì, rallentiamo';
  String get slowdownNo => 'No, continuo';
  String get slowdownHabitMenu => 'Ho bisogno di più tempo con questa';
  String get slowdownMenuSubtitle =>
      'Le nuove proposte di abitudini vengono messe in pausa per 2 settimane — questa resta comunque nel tuo piano.';
  String get slowdownWellyResponse =>
      'Nessun problema — le nuove proposte sono in pausa per 2 settimane. Questa abitudine resta nel tuo piano, prenditi il tempo che ti serve.';
  String get speedupPrompt =>
      'Stai andando molto bene — sei pronto per qualcosa di nuovo prima del previsto?';
  String get speedupYes => 'Sì, sono pronto';
  String get speedupNo => 'No, resto qui';

  String get calendarTitle => 'Le prossime ore';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pausa';
  String get calendarLongBreak => 'Pausa lunga';

  String get tutorialOk => 'Capito!';
  String get tutorialMore => 'Di più →';
  String get tutorialSkip => 'Salta';
  @override
  String get tutorialShowSource => 'Mostra la fonte';
  String get tutorialNext => 'Avanti →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable => 'punti disponibili';
  String get marketplaceTabRewards => 'Premi';
  String get marketplaceTabDiscounts => 'Sconti';
  String get marketplaceTabInApp => 'In-app';
  String get rewardsToRedeem => 'da riscattare';
  String get rewardRedeemed => 'Eccolo. Te lo sei guadagnato.';
  String get rewardConfirmTitle => 'Sei sicuro?';
  String get rewardConfirmBody => 'Verranno scalati X punti dal tuo saldo.';
  String get rewardRedeemFailed =>
      'Non è stato possibile riscattare questo premio — punti insufficienti, oppure non è più disponibile.';
  String get copyCode => 'Copia codice';
  String get codeCopied => 'Copiato';
  String get watchAd => 'Guarda uno spot · +10 pt';
  String get whyAds => 'perché?';
  String get whyAdsTitle => 'Be Well è gratuita per tutti';
  String get whyAdsBody =>
      'Be Well è un\'app gratuita per essere accessibile a chiunque. Come ogni servizio, ha costi di gestione. Guardando le inserzioni quando puoi, ci aiuti a tenere il servizio attivo e migliorarlo per tutti. Grazie davvero.';
  String get discountsActive => 'sconti attivi';
  String get discountsNote =>
      'Gli sconti sono aggiornati ogni mese. Nessun punto richiesto.';
  String get discountExclusive => 'esclusivo Be Well';
  String get goToSite => 'Vai al sito';
  String get affiliateNote => 'Questo link supporta Be Well';
  String get inAppWelly => 'welly';
  String get inAppSoundscape => 'soundscape';
  String get inAppMinigame => 'minigame';
  String get inAppPercorsi => 'percorsi';
  String get unlockItem => 'Sblocca';
  String get itemUnlocked => 'Sbloccato';
  String get premiumAllContent => 'Tutti i contenuti in-app inclusi';
  String get premiumPoints => '+20% punti su ogni abitudine';
  String get premiumWelly => 'Welly personalizzabile completo';
  String get premiumDiscounts => 'Sconti esclusivi in anteprima';
  String get premiumTrial => 'Prova 7 giorni gratis';
  String get premiumOr => 'oppure acquista singolarmente con i punti';

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
      case 'home_welcome':
        return 'Benvenuto! Sono Welly. Ti mostro tutto così puoi iniziare nel modo giusto.';
      case 'home_water':
        return 'Questa è la tua prima abitudine: bere acqua. 8 bicchieri al giorno è il tuo obiettivo. Semplice e potente.';
      case 'home_add_glass':
        return 'Tocca qui ogni volta che bevi un bicchiere. Ogni tap costruisce la tua abitudine — prova subito!';
      case 'home_welly':
        return 'Questo sono io — Welly! Cambio espressione in base ai tuoi progressi. Più vai bene, più sono raggiante.';
      case 'home_phase':
        return 'Questa è la tua Fase. Parti da Seme — Fase 1. Costruisci abitudini per crescere fino alla Fase 5: Fiorente.';
      case 'home_nav':
        return 'Questa è la tua navigazione. In Abitudini trovi già pronto il Focus da 25 minuti; Crescita si apre dopo 14 giorni di costanza.';
      case 'habits_welcome':
        return 'Da qui gestisci tutte le tue routine.';
      case 'habits_now':
        return 'La card \'Adesso\' mostra l\'abitudine più rilevante per questo preciso momento della tua giornata.';
      case 'habits_now_arc':
        return 'Quel numero al centro è quanti giorni hai già completato questa abitudine, in totale — non solo oggi. Zero vuol dire che non l\'hai ancora fatta nemmeno una volta: falla oggi e diventa 1. Toccalo quando vuoi per rivederlo.';
      case 'habits_list':
        return 'Tutte le abitudini sono ordinate per l\'orario migliore. Quelle mattutine compaiono prime al mattino — Welly conosce il tuo ritmo.';
      case 'habits_ready':
        return 'Pronto! Tocca \'Completa\' ogni giorno per costruire la tua streak. Piccole azioni, fatte con costanza, cambiano tutto.';
      case 'habits_progression':
        return 'La prossima abitudine si sblocca da sola, quando avrai davvero fatto tue quelle attuali — non prima. Ogni card mostra esattamente a che punto sei: prima volta, routine in costruzione, assimilata a 7 giorni, automatica a 66. Nessuna fretta, nessuno stress: il ritmo lo decidi tu.';
      // Marketplace tour
      case 'marketplace_welcome':
        return 'Questi sono i tuoi Premi Be Well! Ogni bicchiere d\'acqua, ogni abitudine completata ti porta qui — dove i tuoi sforzi diventano ricompense reali.';
      case 'marketplace_points':
        return 'Il tuo saldo punti è sempre visibile qui. Si accumula automaticamente mentre costruisci le abitudini — senza fare niente di extra.';
      case 'marketplace_tabs':
        return 'Tre tab: Premi da riscattare con i punti; Sconti, offerte esclusive sempre gratuite, senza punti, aggiornate ogni mese; e In-app, dove spendi punti su cose dentro Be Well stesso — outfit per Welly, soundscape, mini-giochi, percorsi guidati.';
      case 'marketplace_card':
        return 'Ogni premio ha un costo in punti. Tocca per riscattare — ricevi un codice subito. Più sei costante, più sblocchi.';
      // Growth tour
      case 'growth_welcome':
        return 'Questa è la tua Crescita. Non è una classifica — è uno specchio. Mostra chi stai diventando, non solo cosa fai.';
      case 'growth_phase':
        return 'La tua fase riflette quanto le abitudini sono radicate. Dalla Fase 1 (Seme) alla Fase 5 (Radioso) — ogni passo è un cambiamento neurologico reale, non un livello di gioco.';
      case 'growth_heatmap':
        return 'Questa heatmap mostra la tua consistenza nel tempo. La scienza dice che il pattern conta più dell\'intensità: qualche giorno mancato non azzera tutto.';
      case 'growth_badges':
        return 'I badge non sono decorazioni. Ognuno corrisponde a un comportamento mantenuto per un periodo misurabile. Sono prove concrete del tuo percorso.';
      default:
        return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitChosenIntro(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':
        return 'Benvenuto! Questa è la tua base. In cima trovi sempre l\'abitudine più urgente per adesso. Inizia sempre da lì — il resto può aspettare.';
      case 'home_first_open_2':
        return 'L\'acqua è la prima abitudine perché è la base biologica di tutto il resto. Senza idratazione, la concentrazione cala fino al 20% già dopo 90 minuti.';
      case 'water_tracker_first':
        return 'Il tracker conta i bicchieri da quando apri l\'app ogni mattina. 8 al giorno è il target — ma anche arrivare a 5 è già meglio di ieri.';
      case 'water_goal_intro':
        return 'Il tuo prossimo obiettivo: bevi tutti gli 8 bicchieri oggi per il tuo primo giorno pieno. Ripetilo per 7 giorni totali e l\'abitudine è assimilata, per 66 diventa automatica. Lo vedrai sempre scritto sulla card, un passo alla volta.';
      case 'first_completion':
        return 'Fatto! Ogni completamento crea una connessione neurale nuova. Piccola, ma reale. Il tuo cervello ha appena rinforzato un circuito.';
      case 'streak_explain':
        return 'Se torni domani, inizia la tua streak. L\'unica regola che conta: non saltare mai due giorni di fila. Uno stop è umano. Due sono un\'abitudine nuova — quella sbagliata.';
      case 'habits_tab_first':
        return 'Qui trovi tutte le abitudini ordinate per il momento migliore della tua giornata. Welly conosce i tuoi ritmi — le abitudini mattutine si mostrano di mattina, quelle serali di sera.';
      case 'habit_card_explain':
        return 'L\'arco e l\'obiettivo sotto il nome dell\'abitudine si aggiornano ogni volta che completi. Il traguardo è scritto chiaro: 7 giorni per assimilarla, 66 per renderla automatica — nessuna supposizione, lo vedi lì.';
      case 'focus_unlocked':
        return 'Hai a disposizione il Focus da 25 minuti fin da subito! Il cervello umano ha un ciclo naturale di concentrazione di circa 20–30 minuti — usalo per un blocco di lavoro senza distrazioni.';
      case 'focus_unlocked_2':
        return 'Regola d\'oro del Focus: quando il timer parte, il telefono va a faccia in giù. Anche Welly tace. La notifica che aspetti può aspettare 25 minuti — lo prometto.';
      case 'calendar_appears':
        return 'Nuovo! Il calendario contestuale mostra solo le prossime ore, non l\'intera giornata. Meno cose da vedere = più spazio mentale per agire. Il futuro lontano non è ancora il tuo problema.';
      case 'growth_first_visit':
        return 'Questa scheda mostra chi stai diventando, non solo cosa stai facendo. Le fasi non sono premi — sono descrizioni reali del tuo cambiamento neurologico. La scienza, non la motivazione, guida il percorso.';
      case 'phase2_reached':
        return '🌱 Fase 2: Inizio! Da qui in poi Crescita traccia il tuo percorso, fase dopo fase. La prossima abitudine si sblocca solo quando sarai pronto — senza fretta, senza pressione: decidi tu i tempi, ed è sempre giusto prendersi ancora un po\' di tempo.';
      case 'phase3_reached':
        return '🌿 Fase 3: Crescita! Tre abitudini consolidate. A questo punto la tua routine esiste davvero — non è più uno sforzo, è una struttura. Il più duro è alle spalle.';
      case 'phase4_reached':
        return '🌳 Fase 4: Radici. Sette abitudini assimilate — la tua routine è diventata stile di vita. La maggior parte delle persone non arriva qui. Tu l\'hai fatto con costanza, non con forza di volontà.';
      case 'phase5_reached':
        return '🌸 Fioritura. Sei arrivato. Non vuol dire che finisce — vuol dire che sei diventato qualcuno che costruisce abitudini. Questo è il vero risultato. Non le singole abitudini, ma la capacità.';
      case 'milestone_7_days':
        return '7 giorni consecutivi! La scienza dice che dopo questa soglia il 90% di chi continua arriverà a 21. Sei nella zona in cui il cambiamento diventa molto più probabile.';
      case 'milestone_21_days':
        return '21 giorni! Il vecchio mito diceva che bastano 3 settimane per formare un\'abitudine. La verità: 21 giorni costruiscono solo il groove iniziale. Ora inizia la parte in cui diventa davvero tua.';
      case 'milestone_66_days':
        return '66 giorni! Questo è il numero magico dello studio di Phillippa Lally all\'UCL. Ufficialmente, secondo la scienza, hai formato un\'abitudine. Non la stai costruendo — la hai.';
      case 'streak_broken':
        return 'Nessun problema. La regola è semplice: mai saltare due giorni di fila. Oggi sei già tornato — la streak riparte da adesso. Welly non conta i giorni saltati.';
      case 'no_completion_3days':
        return 'Welly è ancora qui. Nessun giudizio. Rientrare è più facile di quanto pensi — anche solo un bicchiere d\'acqua conta. Un atto minimo riattiva il loop.';
      case 'perfect_week':
        return 'Settimana perfetta! 7 completamenti su 7. Il tuo cervello ha ricevuto 7 segnali di rinforzo consecutivi. Dal punto di vista neurologico, questa settimana ha contato triplo.';
      case 'rewards_first_visit':
        return 'I badge non sono punti finti. Ogni badge corrisponde a un comportamento reale che hai mantenuto per un periodo misurabile. Sono snapshot del tuo progresso, non decorazioni.';
      default:
        return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':
        return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first':
        return 'EFSA: fabbisogno idrico giornaliero 2,0–2,5 L per adulti in condizioni normali.';
      case 'first_completion':
        return 'Hebb (1949): "neurons that fire together, wire together" — ogni repetizione rafforza la sinapsi.';
      case 'streak_explain':
        return 'James Clear, Atomic Habits: "Never miss twice" è la regola più efficace per mantenere un\'abitudine.';
      case 'habit_card_explain':
        return 'Phillippa Lally (UCL, 2010): l\'automaticità inizia in media tra i 18 e i 66 giorni, con il picco di crescita nelle prime settimane.';
      case 'focus_unlocked':
        return 'Kleitman (1963): cicli ultradiani di 90 min con picchi di attenzione da 20–30 min. Tecniche Pomodoro sfruttano questo ritmo.';
      case 'calendar_appears':
        return 'Sweller (1988): Cognitive Load Theory — meno informazioni visibili simultaneamente = migliori decisioni.';
      case 'growth_first_visit':
        return 'Wood & Neal (2007): l\'identità cambia quando i comportamenti diventano automatici. Identity precedes action.';
      case 'phase2_reached':
        return 'Gardner (2012): automaticità = esecuzione senza intenzione conscia. Il primo automatismo è sempre il più difficile.';
      case 'phase3_reached':
        return 'Lally et al. (2010): con 3 abitudini consolidate, la compliance a lungo termine sale significativamente rispetto a 1 sola.';
      case 'phase4_reached':
        return 'Duhigg (2012): routine consolidate richiedono quasi zero deliberazione conscia — la corteccia prefrontale delega ai gangli basali.';
      case 'milestone_7_days':
        return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: l\'automaticità cresce più rapidamente nelle prime settimane — la consistenza iniziale è il predittore più forte del mantenimento.';
      case 'milestone_21_days':
        return 'Maltz (1960): il "21 giorni" era un\'osservazione chirurgica, non uno studio scientifico. Lally (2010) stima 66 gg in media.';
      case 'milestone_66_days':
        return 'Lally et al. (2010), UCL: media di 66 giorni (range 18–254) per raggiungere l\'automaticità comportamentale.';
      case 'no_completion_3days':
        return 'Fogg (2020): Tiny Habits — anche un\'azione minima mantiene vivo il loop neurale dell\'abitudine.';
      case 'perfect_week':
        return 'Schultz et al. (1997): il sistema dopaminergico risponde alla coerenza del rinforzo — sequenze consecutive amplificano l\'effetto.';
      default:
        return null;
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
  String get passwordForgotSub =>
      'Entrez votre email et nous vous enverrons un lien';
  String get sendResetEmail => 'Envoyer l\'email';
  String get backToLogin => 'Retour à la connexion';
  String get emailSent => 'Email envoyé';

  String get wellyHi => 'Salut, je suis Welly.';
  String get wellyIntro =>
      'Be Well est la première app qui vous guide pas à pas dans la création de bonnes habitudes — et vous récompense en chemin. Je ne vous demande pas de tout changer en un jour. Juste de commencer par une petite chose, avec moi.';
  String get letsGo => 'Allons-y';
  String get wellyNameQuestion =>
      'Avant tout : comment voulez-vous m\'appeler ?';
  String get wellyNameSub =>
      'Mon nom est Welly, mais vous pouvez me donner un nom qui vous plaît.';
  String get perfect => 'Parfait';
  String get firstHabitTitle => 'Première habitude : l\'eau.';
  String get firstHabitBody1 =>
      'Seulement 2% de déshydratation suffisent à réduire la concentration et l\'humeur.';
  String get firstHabitBody2 =>
      'On commence ici : 8 verres par jour. Je vous rappellerai quand boire, puis nous ajouterons de nouvelles habitudes pas à pas.';
  String get drinkFirstGlass => 'Boire le premier verre maintenant';
  String get rewardTitle => 'Parfait. Un.';
  String get rewardBody =>
      'Chaque fois que vous terminez quelque chose, vous gagnez des points Be Well. Vous les accumulerez sans y penser — et pourrez les utiliser pour des bons de réduction, vouchers, accessoires, fonctionnalités premium et bien plus encore.';
  String get goToHome => 'Aller à votre accueil';
  String get rewardLocked => 'Débloqués avec les points';
  @override
  String get previewDiscountTitle => 'Bon de réduction';
  @override
  String get previewDiscountSub => '10 % chez des partenaires sélectionnés';
  @override
  String get previewCoffeeTitle => 'Bon café';
  @override
  String get previewCoffeeSub => 'Une boisson gratuite';
  @override
  String get previewPremiumTitle => 'Premium';
  @override
  String get previewPremiumSub => 'Fonctionnalités avancées';
  @override
  String get previewSurpriseTitle => 'Surprises';
  @override
  String get previewSurpriseSub => 'Et bien plus encore...';
  String get notifPermTitle => 'Une dernière chose.';
  String get notifPermBody =>
      'Pour vous aider à rester régulier, Welly vous envoie quelques rappels doux aux bons moments de la journée. Pas de spam, pas de pression : vous décidez combien, quand vous voulez, dans les réglages.';
  String get notifPermAllow => 'Oui, activer les notifications';
  String get notifPermSkip => 'Pas maintenant';
  String get waterUndo => 'Annuler le dernier';
  String get waterCooldown => 'Attendez un instant…';
  String get waterContainerBtn => 'Contenant';

  String get goodMorning => 'Bonjour,';
  @override
  String get goodAfternoon => 'Bon après-midi,';
  @override
  String get goodEvening => 'Bonsoir,';
  String get greetingFallbackName => 'à toi';
  String get phase => 'Phase';
  String get waterToday => 'Eau aujourd\'hui';
  String get waterGlasses => 'verres';
  String get waterTrackedInHome => '💧 suivi dans Accueil';
  String get waterZero => 'Commencez par le premier verre.';
  @override
  String get habitsEmptyTitle => 'Une habitude à la fois';
  @override
  String get habitsEmptySubtitle =>
      'L\'eau est ton point de départ aujourd\'hui. La suivante se débloque d\'elle-même quand celle-ci te semblera automatique — sans hâte.';
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
  String get noBadgesYet =>
      'Vos badges apparaîtront ici au fil de votre progression.';
  String get todayCompleted => 'Complété aujourd\'hui';
  String get phase1 => 'Graine';
  String get phase2 => 'Pousse';
  String get phase3 => 'Jeune';
  String get phase4 => 'Mature';
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
  @override
  String get focusStartSession => 'Commencer la session';
  String get focusNewSession => 'Nouvelle session';
  String get focusDone => 'Session terminée !';
  String get focusRemaining => 'restantes';
  String get focusSessions => 'sessions';
  String get focusMinutes => 'min focus';
  String get focusStreak => 'série';
  String get focusDeepWork => 'Travail profond';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'sur 4';
  String get focusThenBreak => 'puis une pause de 5 minutes';
  String get containerSize => 'Taille';
  String focusTimerSpoken(int m, int s) => '$m minutes $s secondes restantes';
  String waterGlassAnnounce(int n, int t) => 'Verre $n sur $t enregistré';
  String habitRingSpoken(int n) => '$n jours accomplis au total';
  String get passwordShow => 'Afficher le mot de passe';
  String get passwordHide => 'Masquer le mot de passe';
  String get waterAlmost => 'Presque là, encore un petit effort.';
  String get reduceMotion => 'Réduire les animations';
  String get reduceMotionDesc => 'Calme les animations et les éléments en mouvement';
  String get accessibilityHint => 'Ces réglages valent pour toute l\'app. Be Well suit aussi la taille du texte et les animations réglées sur ton téléphone.';
  String get leaveSessionTitle => 'Quitter cette séance ?';
  String get leaveSessionBody => 'Si tu quittes maintenant, cette séance ne sera pas comptée et tu recommenceras depuis le début. Tu veux continuer ?';
  String get leaveSessionStay => 'Continuer';
  String get leaveSessionLeave => 'Quitter quand même';
  String waterNextGlassIn(String time) => 'Prochain verre dans $time';
  String get workScheduleStart => 'Début';
  String get workScheduleEnd => 'Fin';
  String get workScheduleTime => 'Heure';
  String get workScheduleDays => 'Jours de travail ou d\'étude';
  String get workScheduleInviteTitle => 'Dis-moi tes jours et tes horaires';
  String get workScheduleInviteBody => 'Je place tes rappels autour de tes heures de travail ou d\'étude et je les allège les jours de repos. Tu peux toujours modifier depuis Habitudes.';
  String get workScheduleInviteSet => 'Régler maintenant';
  String get workScheduleInviteLater => 'Plus tard';
  String get wdMon => 'Lun';
  String get wdTue => 'Mar';
  String get wdWed => 'Mer';
  String get wdThu => 'Jeu';
  String get wdFri => 'Ven';
  String get wdSat => 'Sam';
  String get wdSun => 'Dim';
  String get notifInviteTitle => 'Les rappels sont désactivés';
  String get notifInviteBody => 'De petits rappels aux bons moments aident beaucoup à transformer les actions en habitudes. Réactive-les : tu choisis combien dans les Réglages.';
  String get notifInviteAction => 'Réactiver';
  String get notifInviteLater => 'Pas maintenant';
  String get notifComebackTitle1 => 'Je suis là quand tu veux 🌱';
  String get notifComebackBody1 => 'Ça fait quelques jours. Un verre d\'eau suffit pour repartir, sans pression.';
  String get notifComebackTitle2 => 'Aucune pression';
  String get notifComebackBody2 => 'Même un tout petit pas compte. Reprends quand tu veux : tes progrès sont en sécurité.';
  String get notifComebackTitle3 => 'Welly pense à toi';
  String get notifComebackBody3 => 'Tes habitudes t\'attendent exactement là où tu les as laissées.';
  String get notifComebackTitle4 => 'Reprendre est simple';
  String get notifComebackBody4 => 'Un verre d\'eau et tu as déjà recommencé.';
  String get resetAllTitle => 'Repartir de zéro';
  String get resetAllSubtitle => 'Efface tous tes progrès et recommence';
  String get resetAllConfirmTitle => 'Repartir de zéro ?';
  String get resetAllConfirmBody => 'Nous effaçons tes habitudes, jours, série, points et réglages de ce téléphone et de ton compte dans le cloud. Tu reverras l\'accueil comme la toute première fois. Cette action est irréversible.';
  String get resetAllConfirmButton => 'Tout effacer';
  String get notifFocusRunningTitle => '🎯 Focus en cours';
  String get notifFocusRunningBody => 'Une chose à la fois. Touche pour revenir au minuteur.';
  String get notifFocusPausedTitle => '⏸ Focus en pause';
  String get notifFocusPausedBody => 'Prends ton temps : reprends quand tu veux.';
  String get dayOne => 'jour';
  String get wellyMsgMorning => 'Bonjour ! Un verre d\x27eau et la journée démarre du bon pied.';
  String get wellyMsgAfternoon => 'Toujours là ? Une gorgée d\x27eau et une petite pause te feront du bien.';
  String get wellyMsgEvening => 'La journée touche à sa fin, c\x27est très bien ainsi. Si tu veux, un dernier verre, puis repose-toi.';
  String get wellyMsgAllDone => 'Tu as fait tout ce qu\x27il fallait aujourd\x27hui. Profite du reste de la journée.';
  String get wellyMsgWaterDone => 'Eau terminée, beau rythme. Le reste est un bonus.';
  String wellyMsgWaterProgress(int n, int t) => 'Bien : $n verres sur $t. Sans se presser.';

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
  String get notifWaterBody =>
      'Le premier verre d\'eau est une bonne façon de commencer la journée.';
  String get notifMiddayTitle => '🧘 Be Well';
  String get notifMiddayBody =>
      'Deux minutes pour t\'étirer ou respirer — ta concentration te remerciera ensuite.';
  String get notifLunchTitle => '🍃 Be Well';
  String get notifLunchBody =>
      'Une vraie pause aide : pose l\'écran quelques minutes pendant que tu manges.';
  String get notifAfternoonTitle => '👀 Be Well';
  String get notifAfternoonBody =>
      'Les yeux fatigués par l\'écran ? 20 secondes à regarder au loin, ça aide vraiment.';
  String get notifEveningTitle => 'Be Well 🌙';
  String get notifEveningBody =>
      'Il reste du temps pour une dernière habitude aujourd\'hui, si tu veux — sinon à demain.';
  String get notifHabitChoiceTitle => '✨ Nouvelle habitude disponible';
  String get notifHabitChoiceBody =>
      'Ouvre Be Well pour choisir ta prochaine habitude.';

  @override
  String get notifFocusTitle => '🎯 Moment de Focus';
  @override
  String get notifFocusBody =>
      'Quand tu veux : un bloc de concentration, sans te presser.';
  @override
  String get notifBundleTitle => '🌿 Be Well';
  @override
  String notifBundleMorningBody(String list) => 'Pour bien commencer : $list.';
  @override
  String notifBundleBreakBody(String list) => 'Une pause douce : $list.';
  @override
  String notifBundleEveningBody(String list) =>
      'Pour bien finir la journée : $list.';
  @override
  String get notifFocusDoneTitle => '✨ Bloc terminé';
  @override
  String notifFocusDoneBody(String list) =>
      'Beau travail. Prends un instant : $list.';
  @override
  String get notifFocusDoneBodyPlain =>
      'Beau travail. Prends un instant pour respirer.';
  @override
  String get notifAndWord => 'et';

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
  String get navUnlockHabitsMsg =>
      'Complétez 14 jours d\'eau pour débloquer les habitudes.';
  String get navUnlockGrowthMsg =>
      'Croissance s\'ouvre après 14 jours de régularité avec une habitude : vous la construisez déjà.';
  String get comingSoonHabitsDesc =>
      'Complétez 14 jours d\'eau.\nVotre première nouvelle habitude se débloquera ici.';
  String get comingSoonGrowthDesc =>
      'Continuez à construire vos habitudes.\nL\'écran de croissance se débloquera bientôt.';
  String get achievementUnlocked => 'Achievement débloqué !';
  String get newHabitUnlocked => 'Nouvelle habitude débloquée !';

  String get rewards => 'Récompenses';
  String get rewardsPoints => 'Points Be Well';
  String get rewardsLocked => 'Les récompenses arrivent';
  String get rewardsLockedDesc =>
      'Continuez à construire des habitudes pour débloquer vos récompenses';
  String get rewardsHeader => 'Vos récompenses';
  String get rewardsHeaderSub => 'Récoltez ce que vous avez semé';

  String get habitWaterName => 'Boire de l\'eau';
  String get habitWaterDesc => '8 verres tout au long de la journée';
  String get habitFocus25Name => 'Session focus 25 min';
  String get habitFocus25Desc => 'Un Pomodoro sans distractions';
  String get habitEyes2020Name => 'Règle 20-20-20';
  String get habitEyes2020Desc => 'Toutes les 20 min, regarder au loin 20 sec';
  String get habitNeckName => 'Étirement du cou';
  String get habitNeckDesc => '2 min d\'étirements cou et épaules par heure';
  String get habitBreathingBoxName => 'Respiration en boîte';
  String get habitBreathingBoxDesc =>
      '4s inspirer, 4s tenir, 4s expirer, 4s tenir';
  String get habitWalkLunchName => 'Marche du déjeuner';
  String get habitWalkLunchDesc =>
      'Une marche de 15 min pendant la pause déjeuner';
  String get habitDeskExName => 'Exercices au bureau';
  String get habitDeskExDesc =>
      '5 min d\'étirements actifs toutes les 2 heures';
  String get habitWaterMornName => 'Eau au réveil';
  String get habitWaterMornDesc => 'Un verre d\'eau dès le réveil';
  String get habitPostureName => 'Contrôle posture';
  String get habitPostureDesc => 'Vérifier et corriger la posture chaque heure';
  String get habitLunchParkName => 'Déjeuner au parc';
  String get habitLunchParkDesc => 'Manger dehors, sans écran';
  String get habitBreathing478Name => 'Respiration 4-7-8';
  String get habitBreathing478Desc =>
      'Anti-anxiété : inspirer 4s, tenir 7s, expirer 8s';
  String get habitStretchName => 'Étirement actif';
  String get habitStretchDesc => '5 minutes de mouvement global du corps';
  String get habitSnackName => 'Collation saine';
  String get habitSnackDesc =>
      'Une petite collation nutritive en milieu de matinée';
  String get habitLunchNoScreenName => 'Déjeuner sans écran';
  String get habitLunchNoScreenDesc => 'Déjeuner sans téléphone ni ordinateur';
  String get habitFocus50Name => 'Focus profond 50 min';
  String get habitFocus50Desc =>
      'Une session de travail profond sans interruption';
  String get habitMeditationName => 'Micro-méditation';
  String get habitMeditationDesc => '3 minutes de présence consciente';
  String get habitStairsName => 'Prendre les escaliers';
  String get habitStairsDesc => 'Choisir les escaliers plutôt que l\'ascenseur';
  String get habitSleepName => 'Routine pré-sommeil';
  String get habitSleepDesc => '30 minutes sans écran avant de dormir';
  String get habitWakeName => 'Réveil constant';
  String get habitWakeDesc => 'Se lever à la même heure chaque jour';
  String get habitNapName => 'Sieste 20 min';
  String get habitNapDesc => 'Un court repos intentionnel l\'après-midi';
  String get habitFocusPhoneName => 'Focus sans téléphone';
  String get habitFocusPhoneDesc =>
      'Téléphone retourné pendant les sessions focus';
  String get habitMicroWalkName => 'Micro-marche 5 min';
  String get habitMicroWalkDesc =>
      '5 minutes de marche toutes les 90 minutes — cycle ultradien';
  String get habitDigitalSunsetName => 'Coucher digital';
  String get habitDigitalSunsetDesc =>
      'Pas de réseaux sociaux dans l\'heure avant de dormir';
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
  String get guideStretchStep2 =>
      'Flexion latérale du buste × 3 de chaque côté';
  String get guideStretchStep3 => 'Cercles de hanches × 8';
  String get guideStretchStep4 => 'Montées sur pointes × 10';
  String get guideStretchStep5 => 'Flexion avant debout × 20s';
  @override
  String get guideHowShoulderRoll =>
      'Assieds-toi le dos droit, les bras détendus. Monte les épaules vers les oreilles, roule-les vers l\'arrière puis vers le bas, en un cercle lent. La poitrine s\'ouvre, la nuque reste souple.';
  @override
  String get guideHowSpinalTwist =>
      'Assis, le dos droit. Tourne le buste vers la droite, la main gauche sur le genou droit et la main droite sur le dossier. Regarde par-dessus l\'épaule sans forcer, puis change de côté.';
  @override
  String get guideHowWrist =>
      'Lève les avant-bras devant toi, coudes appuyés. Garde les mains souples et dessine de lents cercles avec les poignets, dans un sens puis dans l\'autre.';
  @override
  String get guideHowNeckTilt =>
      'Assieds-toi droit, les épaules basses. Incline la tête vers l\'épaule droite, l\'oreille se rapproche, sans lever l\'épaule. Tiens, respire, puis change de côté.';
  @override
  String get guideHowCatCow =>
      'Mains sur les genoux. En inspirant, cambre le dos et ouvre la poitrine, le regard légèrement vers le haut. En expirant, arrondis le dos et rapproche le menton de la poitrine.';
  @override
  String get guideHowNeckRoll =>
      'Assieds-toi droit, les épaules détendues. Rapproche le menton de la poitrine, puis fais rouler lentement la tête en un grand cercle doux. Si tu sens de la tension, fais un cercle plus petit.';
  @override
  String get guideHowShrug =>
      'Les bras détendus le long du corps, monte les deux épaules vers les oreilles, tiens un instant puis laisse-les retomber. Sens la nuque se relâcher.';
  @override
  String get guideHowArmReach =>
      'Debout, pieds écartés à la largeur des hanches. Joins les mains et allonge les bras vers le haut, comme pour grandir un peu. Regarde légèrement vers le haut, puis redescends doucement.';
  @override
  String get guideHowSideBend =>
      'Debout, jambes écartées. Lève un bras au-dessus de la tête et incline le buste du côté opposé, l\'autre main sur la hanche. Bassin stable, respiration longue, puis change de côté.';
  @override
  String get guideHowHips =>
      'Mains sur les hanches, pieds écartés, genoux souples. Dessine avec le bassin un cercle lent et large, le haut du corps reste calme. À mi-parcours, inverse le sens.';
  @override
  String get guideHowCalf =>
      'Debout, les mains sur une chaise pour l\'équilibre. Monte sur la pointe des deux pieds, tiens une seconde puis redescends lentement. Les jambes restent droites.';
  @override
  String get guideHowFold =>
      'Pieds à la largeur des hanches, genoux souples. Penche-toi en avant depuis les hanches, tête et bras relâchés. Ne force pas : reste là où tu sens un léger étirement, puis remonte doucement.';
  @override
  String get guideSafetyNote =>
      'Bouge lentement, sans forcer : en cas de douleur, arrête-toi.';

  @override
  String get guidePhaseMove => 'Bouge';
  @override
  String get guidePhaseRest => 'Repos';
  @override
  String get guidePhaseRightHold => 'Tourne à droite, tiens';
  @override
  String get guidePhaseCenter => 'Reviens au centre';
  @override
  String get guidePhaseLeftHold => 'Tourne à gauche, tiens';
  @override
  String get guidePhaseClockwise => 'Sens horaire';
  @override
  String get guidePhaseCounterClockwise => 'Sens antihoraire';
  @override
  String get guidePhaseArchCow => 'Creuse le dos (vache)';
  @override
  String get guidePhaseRoundCat => 'Arrondis le dos (chat)';
  @override
  String get guidePhaseRaiseHold => 'Lève, tiens';
  @override
  String get guidePhaseLowerRelease => 'Baisse et relâche';
  @override
  String get guidePhaseReachHold => 'Tends le bras vers le haut, tiens';
  @override
  String get guidePhaseLowerSlowly => 'Baisse lentement';
  @override
  String get guidePhaseFoldHold => 'Plie vers l\'avant, tiens';
  @override
  String get guidePhaseRiseSlowly => 'Relève-toi lentement';

  String get neverMissTwiceTitle => 'Ne ratez pas deux jours de suite.';
  String get neverMissTwiceBody =>
      'Une seule action compte. Même un verre d\'eau.';
  String get neverMissTwiceCta => '💧 Ajouter un verre d\'eau';
  String get wellyBonusTitle => 'Bonus Welly !';
  String get wellyBonusBody => 'Points triplés ce tour 🎉';

  String get coachDay1 => 'Premier jour. Le plus important.';
  String get coachDay3 => '3 jours. Votre corps commence à l\'enregistrer.';
  String get coachDay7 => '7 jours. Vous construisez quelque chose.';
  String get coachDay14 =>
      '2 semaines. Cette habitude est la vôtre maintenant.';
  String get coachGeneral => 'Chaque jour compte. Même les jours difficiles.';

  String get badgeFirstStep => 'Premier pas';
  String get badgeFirstStepDesc => 'Premier jour complété';
  String get badgeOneWeek => 'Une semaine';
  String get badgeOneWeekDesc => '7 jours d\'habitudes';
  String get badgeThreeWeeks => 'Trois semaines';
  String get badgeThreeWeeksDesc => '21 jours complétés';
  String get badgeSixWeeks => 'Six semaines';
  String get badgeSixWeeksDesc => '42 jours complétés';
  String get badgeThreeMonths => 'Trois mois';
  String get badgeThreeMonthsDesc => '90 jours de croissance';
  String get badgeInSync => 'En synchronie';
  String get badgeInSyncDesc => '2 habitudes actives';
  String get badgeMultihabit => 'Multihabitude';
  String get badgeMultihabitDesc => '4 habitudes actives';
  String get badgeHydrated => 'Bien hydraté';
  String get badgeHydratedDesc => 'Eau consolidée';
  String get badgeFocused => 'En focus';
  String get badgeFocusedDesc => 'Focus 25 min consolidé';
  String get badgeWalker => 'Marcheur';
  String get badgeWalkerDesc => 'Marche déjeuner consolidée';
  String get badgeBreath => 'Souffle';
  String get badgeBreathDesc => 'Respiration consolidée';
  String get badgeRootedName => 'Habitudes enracinées';
  String get badgeRootedDesc => 'Habitudes devenues une seconde nature';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Argent';
  String get badgeTierGold => 'Or';
  String get growthNextGoal => 'Prochain objectif';
  String growthHabitsToRoot(int n) =>
      n == 1 ? 'Encore 1 habitude' : 'Encore $n habitudes';

  String get habitChoiceTitle =>
      'Il est temps d\'ajouter\nquelque chose de nouveau.';
  String get habitChoiceSub => 'Choisissez où vous concentrer.';
  String get habitChoiceShowOther => 'voir d\'autres options ›';
  String get habitChoiceNotReady => 'Je ne suis pas encore prêt(e)';
  String get habitChoiceOpen => 'Choisir votre prochaine habitude';
  String get habitNotReadySnoozed =>
      'Pas de souci — je te le redemanderai dans une semaine.';
  @override
  String get habitNotReadyMeanwhile => 'Essaie plutôt la respiration';
  @override
  String habitMatchesGoal(String goal) => 'En lien avec : $goal';
  String get consolidatedTitle => '🏆 Félicitations !';
  String consolidatedBody(String habitName) =>
      'Tu as fait de « $habitName » une vraie habitude — ton cerveau a construit un circuit durable pour elle.';
  String get consolidatedBadge => 'Habitude consolidée';
  String get consolidatedCta => 'Continuer';
  @override
  String get consolidatedCtaNext => 'Choisir la prochaine habitude →';
  @override
  String get automaticTitle => '💚 Automatique !';
  @override
  String automaticBody(String habitName) =>
      'Tu n\'as plus besoin d\'y penser : "$habitName" est maintenant gérée par ton cerveau tout seul. C\'est la vraie ligne d\'arrivée.';
  @override
  String get automaticBadge => 'Habitude automatique';
  @override
  String get calendarTowardAssimilated => 'Vers l\'habitude';
  @override
  String get calendarTowardAutomatic => 'Vers l\'automatisme';
  @override
  String get calendarMilestoneSoon => 'PRESQUE Y EST';
  @override
  String calendarMilestoneInDays(int days) => 'DANS $days JOURS';
  @override
  String get calendarAssimilatedTitle => 'Habitude assimilée';
  @override
  String get calendarAssimilatedSub =>
      'Ton cerveau commence à l\'enregistrer comme une routine — le coffre s\'ouvre.';
  @override
  String get calendarAutomaticTitle => 'Habitude automatique';
  @override
  String get calendarAutomaticSub =>
      'Le plus grand palier : tu n\'as plus besoin d\'y penser.';
  @override
  String get calendarLongArcNote =>
      'Tu as passé la partie la plus difficile. Chaque jour renforce désormais l\'automatisme.';
  @override
  String get calendarDoneTitle => 'Automatique — bravo';
  @override
  String calendarDoneSub(int points) =>
      'Cette habitude tourne maintenant toute seule. +$points points gagnés en chemin.';
  @override
  String get dailyObjectivesTitle => 'Objectifs du jour';
  @override
  String dailyObjectivesSub(int done, int total) => done >= total && total > 0
      ? 'Tout est fait pour aujourd\'hui'
      : '$done sur $total faits aujourd\'hui';
  @override
  String get badgeUnlockedTitle => '🏆 Badge débloqué !';
  @override
  String get badgeUnlockedCta => 'Génial !';
  @override
  String get newMissionLabel => 'Nouvelle mission';
  @override
  String get missionStartCta => 'C\'est parti !';
  @override
  String get missionStreakStart => 'Ta série commence ici.';
  @override
  String get missionStreakGoal =>
      '7 jours pour en faire une habitude, 66 pour l\'automatiser.';
  @override
  String streakMilestoneTitle(int days) => '🔥 $days jours d\'affilée !';
  @override
  String get streakMilestoneBadge => 'Étape de série';
  String habitStartsTomorrow(String habitName) =>
      'Très bien ! Profite de ta réussite aujourd\'hui — on commencera à travailler sur « $habitName » demain.';
  @override
  String habitChosenIntro(String habitName) =>
      'Très bien ! Profite de ta réussite aujourd\'hui — « $habitName » commence demain. Fais-la une fois, puis garde le rythme : assimilée en 7 jours, automatique après 66. Tu verras l\'objectif directement sur sa carte, à chaque étape.';
  String get habitEffortLow => 'facile';
  String get habitEffortMedium => 'modéré';
  String get habitEffortHigh => 'exigeant';

  String get errorNetwork => 'Pas de connexion internet';
  String get errorGeneral => 'Quelque chose s\'est mal passé. Réessayez.';
  String get errorInvalidEmail => 'Adresse email invalide';
  String get errorWeakPassword => 'Le mot de passe est trop faible';
  String get errorEmailInUse => 'Cet email est déjà utilisé';
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect';
  String get errorTooManyAttempts =>
      'Trop de tentatives. Compte temporairement bloqué';
  String get errorTimeout => 'Le serveur ne répond pas. Réessayez bientôt';
  String get errorCancelled => 'Connexion annulée';
  String get errorAccountDisabled => 'Compte désactivé. Contactez le support';
  @override
  String get errorRequiresRecentLogin =>
      'Pour ta sécurité, reconnecte-toi avant de supprimer ton compte.';
  @override
  String get deleteAccount => 'Supprimer le compte';
  @override
  String get deleteAccountConfirmTitle => 'Supprimer ton compte ?';
  @override
  String get deleteAccountConfirmBody =>
      'Supprime définitivement ton compte et toutes tes données — habitudes, séries, points, badges. Action irréversible.';
  @override
  String get deleteAccountCta => 'Oui, tout supprimer';
  @override
  String get deleteAccountDone => 'Ton compte a été supprimé.';
  String get passwordStrengthWeak => 'Faible';
  String get passwordStrengthMedium => 'Moyen';
  String get passwordStrengthStrong => 'Fort';
  String get passwordStrengthVeryStrong => 'Très fort';
  String get validationEmailRequired => 'Entrez votre email';
  String get validationPasswordRequired => 'Entrez un mot de passe';
  String get validationPasswordTooShort => '8 caractères minimum';
  String get validationNameRequired => 'Entrez votre nom';
  String get validationNameTooShort => '2 caractères minimum';
  String get accountLockedBody =>
      'Trop de tentatives échouées.\nRéessayez dans';
  String get accountLockedEmailSent =>
      'Vous avez reçu un email avec les instructions.';
  String get offlineLoginRequired =>
      'Pas de connexion — la connexion nécessite internet';
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
  String get welcomeSlide1Sub =>
      'Be Well construit un plan sur mesure pour vous, basé sur vos habitudes et objectifs.';
  @override
  String get welcomeSlide1Footer =>
      'Rejoins celles et ceux qui construisent déjà de meilleures habitudes, un jour à la fois.';
  String get welcomeSlide2Title => 'Des rappels qui\nconnaissent votre agenda';
  String get welcomeSlide2Sub =>
      'Les rappels s\'adaptent à vos réunions et horaires, pour ne jamais vous interrompre au mauvais moment.';
  String get welcomeSlide3Title =>
      'Transformez vos habitudes\nen récompenses réelles';
  String get welcomeSlide3Sub =>
      'Gagnez des points en complétant des activités et échangez-les contre des réductions, des bons et plus encore.';
  String get welcomeSkip => 'Passer';
  String get welcomeNext => 'Suivant →';
  String get welcomeStart => 'Commencer la configuration →';
  String get welcomeConfigureLater => 'Configurer plus tard';

  String get qProfileTitle => 'Parlez-nous de vous';
  String get qProfileSub => 'Nous aide à construire le bon plan pour vous.';
  String get qGoalsTitle => 'Objectifs & Stress';
  String get qGoalsSub =>
      'L\'écran le plus important pour personnaliser votre plan.';
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
  String get q19Label =>
      'Q20 · Niveau de distractions dans votre environnement';
  String get q20Label => 'Q21 · Quand êtes-vous le plus concentré ?';
  String get q21Label =>
      'Q22 · Combien de temps pouvez-vous vous concentrer d\'affilée ?';
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
  String get calSyncNote =>
      '✓ Nous demanderons les permissions après confirmation du plan';
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
  String get screenTimeWarning =>
      'Nous activerons des rappels yeux plus fréquents';
  String get crisisTitle => 'Vous traversez un moment difficile';
  String get crisisBody =>
      'Be Well est là pour vous soutenir. Si vous avez besoin d\'aide immédiate : contactez une ligne d\'écoute locale.';
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
  String get planPreviewSub =>
      'Personnalisé selon vos réponses. Vous pourrez toujours le modifier depuis les paramètres.';
  String get planRemindersPerDay => 'rappels/jour';
  String get planFocusSessions => 'sessions focus';
  String get planPointsPerDay => 'points/jour';
  String get planMorning => '🌅 Matin';
  String get planAfternoon => '☀️ Après-midi';
  String get planEvening => '🌙 Soir';
  String planFromTime(String time) => 'dès $time';
  String planConnectCalendar(String name) => 'Connecter $name';
  String get planConnectCalendarSub =>
      'Nous demanderons la permission après confirmation';
  String get planFallbackNote =>
      'Nous avons utilisé un plan par défaut. Nous l\'affinerons au fur et à mesure.';
  String get planConfirmCta => 'Commencer avec Be Well  ';
  String get planConfirmSub =>
      'Vous pouvez modifier votre plan à tout moment depuis les paramètres';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Profil';
  String get accountSection => 'Compte';
  String get emailAccountLabel => 'Email du compte';
  String get supportSection => 'Support';
  String get editNameTitle => 'Modifier le nom';
  String get yourNameHint => 'Votre nom';
  String get resetTutorialTitle => 'Réinitialiser le tutoriel';
  String get resetTutorialBody =>
      'Welly affichera à nouveau tous les dialogues du tutoriel comme si c\'était la première fois. Utile pour tester le parcours.';
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
  String get comingSoonBody =>
      'Cette section n\'est pas encore disponible — elle est sur notre feuille de route.';
  String get habitMarkDone => 'Fait';
  @override
  String get habitGoalFirstTime =>
      '🎯 Objectif : fais-la pour la première fois';
  @override
  String habitGoalInProgressToday(int count, int target) =>
      '🎯 $count/$target verres aujourd\'hui — termine-les pour ta première journée complète';
  @override
  String habitGoalBuilding(int days, int target) =>
      '🎯 Objectif : construis la routine — $days/$target jours';
  @override
  String habitGoalBonus(int days, int target) =>
      '🌳 Habitude assimilée ! Objectif bonus : la rendre automatique — $days/$target jours';
  @override
  String get habitGoalMastered => '💚 Automatique — objectif atteint';
  String get slowdownReasonHeavy => 'Cette habitude me pèse trop en ce moment';
  String heatmapDaysAgo(int n) => 'il y a $n jours';
  String get heatmapToday => 'aujourd\'hui';
  String phaseStarted(String date) => 'commencé le $date';
  String phaseReached(String date) => 'atteint le $date';
  String get marketAdTitle => 'Aidez Be Well';
  String get marketAdSubtitle => 'Gagnez 10 pts en regardant une pub';
  @override
  String marketAdRemaining(int n) => '$n restantes aujourd\'hui';
  @override
  String get marketAdCapReached =>
      'Tu as atteint la limite du jour — reviens demain';
  String get marketAdDialogBody =>
      'Regardez une pub : vous nous aidez à garder l\'app gratuite et gagnez immédiatement 10 points.';
  String get marketWatchNow => 'Regarder maintenant';
  String get dialogGotIt => 'Compris';
  String get marketAdUnavailable => 'Pub non disponible pour le moment';
  String get referralTitle => 'Inviter un ami';
  String get referralSubtitle => 'Gagnez 50 pts pour chaque ami qui s\'inscrit';
  String get referralApply => 'Appliquer';
  String get referralApplied =>
      'Code appliqué ! Votre ami recevra bientôt le bonus. 🎉';
  String get referralErrorInvalid => 'Code invalide';
  String get referralErrorOwn =>
      'Vous ne pouvez pas utiliser votre propre code';
  String get referralErrorAlready =>
      'Vous avez déjà utilisé un code d\'invitation';
  String get referralErrorNotSignedIn => 'Vous devez être connecté';
  String get referralErrorGeneric => 'Une erreur est survenue, réessayez';
  String get referralHint => 'Vous avez un code d\'invitation ?';
  String premiumPrice(String price) => '$price/mois';
  String referralShareButton(String code) => 'Partager mon code · $code';
  String get referralRetry =>
      'Échec de la génération du code — appuyez pour réessayer';
  String referralShareMessage(String code) =>
      'J\'utilise Be Well pour construire des habitudes plus saines, jour après jour 🌱\n'
      'Téléchargez l\'app et utilisez mon code d\'invitation "$code" — vous recevrez 50 points bonus dès votre inscription !';

  String get waterContainerGlass => 'verre';
  String get waterContainerBottle => 'gourde';
  String get waterContainerSettings =>
      'Comment suis-tu ta consommation d\'eau ?';
  String get waterGoalCalc =>
      'Il te faut environ N contenants pour tes 2 litres par jour';

  String get habitsMorningTitle => 'Bien commencer la journée.';
  String get habitsMiddayTitle => 'Au bon moment.';
  String get habitsAfternoonTitle => 'Bon après-midi.';
  String get habitsEveningTitle => 'Comment s\'est passée ta journée ?';
  String get habitsNowLabel => 'Maintenant';
  String get habitsComingSoon => 'À venir';
  String get configuratorTitle => 'Personnalise ton plan';
  String get configuratorSubtitle =>
      'Réponds à quelques questions pour recevoir des suggestions d\'habitudes adaptées';
  String get configuratorDoneTitle => 'Ton plan est personnalisé';
  String get configuratorDoneSubtitle =>
      'Touche pour mettre à jour tes réponses';
  String get habitsAllDone =>
      'Tout est bon pour l\'instant. Welly est avec toi.';
  String get habitsToday => 'Ton rythme aujourd\'hui';
  String get completedToday => 'complétées aujourd\'hui';

  String get timeMorning => 'Matin';
  String get timeMidday => 'Milieu de matinée';
  String get timeLunch => 'Pause déjeuner';
  String get timeAfternoon => 'Après-midi';
  String get timeEvening => 'Soir';

  String get onboardingUserTypeTitle => 'Et comment passes-tu tes journées ?';
  String get onboardingStudent => 'Études';
  String get onboardingWorker => 'Travail';

  String get workScheduleBanner =>
      'J\'ai mis des horaires standard (lun–ven, 9-13 / 14-18). Ça te convient ?';
  String get workScheduleConfirm => 'C\'est bon';
  String get workScheduleEdit => 'Modifier';
  String get workScheduleTitle => 'Tes horaires de travail';
  String get workScheduleMorning => 'Matin';
  String get workScheduleAfternoon => 'Après-midi';
  String get workScheduleLunch => 'J\'ai une pause déjeuner fixe';
  String get workScheduleSave => 'Enregistrer';

  String get slowdownPrompt =>
      'J\'ai remarqué que tu as du mal à maintenir le rythme. Tu veux qu\'on ralentisse un peu ?';
  String get slowdownYes => 'Oui, ralentissons';
  String get slowdownNo => 'Non, je continue';
  String get slowdownHabitMenu => 'J\'ai besoin de plus de temps avec celle-ci';
  String get slowdownMenuSubtitle =>
      'Les nouvelles suggestions d\'habitudes sont mises en pause pendant 2 semaines — celle-ci reste dans ton plan.';
  String get slowdownWellyResponse =>
      'Pas de problème — les nouvelles suggestions sont en pause pendant 2 semaines. Cette habitude reste dans ton plan, prends le temps qu\'il te faut.';
  String get speedupPrompt =>
      'Tu vas très bien — es-tu prêt pour quelque chose de nouveau avant le temps prévu ?';
  String get speedupYes => 'Oui, je suis prêt';
  String get speedupNo => 'Non, je reste ici';

  String get calendarTitle => 'Les prochaines heures';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pause';
  String get calendarLongBreak => 'Grande pause';

  String get tutorialOk => 'Compris !';
  String get tutorialMore => 'En savoir plus →';
  String get tutorialSkip => 'Passer';
  @override
  String get tutorialShowSource => 'Voir la source';
  String get tutorialNext => 'Suivant →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable => 'points disponibles';
  String get marketplaceTabRewards => 'Récompenses';
  String get marketplaceTabDiscounts => 'Réductions';
  String get marketplaceTabInApp => 'In-app';
  String get rewardsToRedeem => 'à échanger';
  String get rewardRedeemed => 'Le voilà. Tu l\'as mérité.';
  String get rewardConfirmTitle => 'Êtes-vous sûr ?';
  String get rewardConfirmBody => 'X points seront déduits de votre solde.';
  String get rewardRedeemFailed =>
      'Impossible d\'échanger cette récompense — points insuffisants, ou elle n\'est plus disponible.';
  String get copyCode => 'Copier le code';
  String get codeCopied => 'Copié';
  String get watchAd => 'Regarder une pub · +10 pt';
  String get whyAds => 'pourquoi ?';
  String get whyAdsTitle => 'Be Well est gratuit pour tous';
  String get whyAdsBody =>
      'Be Well est une application gratuite pour être accessible à tous. Comme tout service, elle a des coûts de fonctionnement. En regardant les publicités quand vous le pouvez, vous nous aidez à maintenir le service actif et à l\'améliorer pour tous. Merci.';
  String get discountsActive => 'réductions actives';
  String get discountsNote =>
      'Les réductions sont mises à jour chaque mois. Aucun point requis.';
  String get discountExclusive => 'exclusif Be Well';
  String get goToSite => 'Aller sur le site';
  String get affiliateNote => 'Ce lien soutient Be Well';
  String get inAppWelly => 'welly';
  String get inAppSoundscape => 'soundscape';
  String get inAppMinigame => 'minijeu';
  String get inAppPercorsi => 'parcours';
  String get unlockItem => 'Débloquer';
  String get itemUnlocked => 'Débloqué';
  String get premiumAllContent => 'Tous les contenus in-app inclus';
  String get premiumPoints => '+20% de points pour chaque habitude';
  String get premiumWelly => 'Welly entièrement personnalisable';
  String get premiumDiscounts => 'Réductions exclusives en avant-première';
  String get premiumTrial => 'Essayez 7 jours gratuits';
  String get premiumOr => 'ou achetez individuellement avec des points';

  String get feedbackTitle => 'Laisser un avis';
  String get feedbackSubtitle =>
      'Cela nous aide à améliorer Be Well pour vous.';
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
      case 'home_welcome':
        return 'Bienvenue ! Je suis Welly. Laisse-moi te montrer tout ça pour bien commencer.';
      case 'home_water':
        return 'Voici ta première habitude : boire de l\'eau. 8 verres par jour est ton objectif. Simple et puissant.';
      case 'home_add_glass':
        return 'Appuie ici chaque fois que tu bois un verre. Chaque tap construit ton habitude — essaie maintenant !';
      case 'home_welly':
        return 'C\'est moi — Welly ! Je change d\'expression selon tes progrès. Plus tu avances, plus je rayonne.';
      case 'home_phase':
        return 'C\'est ta Phase. Tu commences à Graine — Phase 1. Construis des habitudes pour atteindre la Phase 5 : Radieux.';
      case 'home_nav':
        return 'Voici ta navigation. Dans Habitudes, le Focus de 25 minutes est déjà prêt ; Croissance s\'ouvre après quelques jours de régularité.';
      case 'habits_welcome':
        return 'D\'ici tu gères toutes tes routines.';
      case 'habits_now':
        return 'La carte \'Maintenant\' montre l\'habitude la plus pertinente pour ce moment précis de ta journée.';
      case 'habits_now_arc':
        return 'Ce chiffre au centre, c\'est le nombre total de jours où tu as complété cette habitude — pas seulement aujourd\'hui. Zéro veut dire que tu ne l\'as pas encore faite une seule fois : fais-la aujourd\'hui et ça devient 1. Touche-le à tout moment pour le revoir.';
      case 'habits_list':
        return 'Toutes les habitudes sont triées par leur meilleur moment. Les habitudes matinales apparaissent en premier le matin — Welly connaît ton rythme.';
      case 'habits_ready':
        return 'Prêt ! Appuie sur \'Terminé\' chaque jour pour construire ta série. De petites actions, faites régulièrement, changent tout.';
      case 'habits_progression':
        return 'Ta prochaine habitude se débloque toute seule, une fois que tu as vraiment fait tiennes celles d\'aujourd\'hui — pas avant. Chaque carte montre exactement où tu en es : première fois, routine en construction, assimilée à 7 jours, automatique à 66. Pas de précipitation, pas de pression : c\'est toi qui fixes le rythme.';
      // Marketplace tour
      case 'marketplace_welcome':
        return 'Voici tes Récompenses Be Well ! Chaque verre d\'eau, chaque habitude accomplie t\'amène ici — là où tes efforts deviennent de vraies récompenses.';
      case 'marketplace_points':
        return 'Ton solde de points est toujours visible ici. Il s\'accumule automatiquement pendant que tu construis tes habitudes.';
      case 'marketplace_tabs':
        return 'Trois onglets : Récompenses à échanger avec des points ; Réductions, des offres exclusives toujours gratuites, sans points, mises à jour chaque mois ; et In-app, où tu dépenses tes points sur des choses à l\'intérieur de Be Well — tenues pour Welly, ambiances sonores, mini-jeux, parcours guidés.';
      case 'marketplace_card':
        return 'Chaque récompense a un coût en points. Appuie pour échanger — tu reçois un code instantanément. Plus tu es régulier, plus tu débloque.';
      // Growth tour
      case 'growth_welcome':
        return 'Voici ta Croissance. Ce n\'est pas un classement — c\'est un miroir. Il montre qui tu deviens, pas seulement ce que tu fais.';
      case 'growth_phase':
        return 'Ta phase reflète à quel point tes habitudes sont enracinées. De la Phase 1 (Graine) à la Phase 5 (Radieux) — chaque étape est un vrai changement neurologique.';
      case 'growth_heatmap':
        return 'Cette heatmap montre ta régularité dans le temps. La science dit que le schéma compte plus que l\'intensité : quelques jours manqués ne remettent pas tout à zéro.';
      case 'growth_badges':
        return 'Les badges ne sont pas des décorations. Chacun correspond à un comportement maintenu pendant une période mesurable. Ce sont des preuves concrètes de ton parcours.';
      default:
        return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitChosenIntro(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':
        return 'Bienvenue ! Voici ta base. En haut, tu trouveras toujours l\'habitude la plus urgente du moment. Commence toujours par là — le reste peut attendre.';
      case 'home_first_open_2':
        return 'L\'eau est la première habitude parce que c\'est le fondement biologique de tout le reste. Sans hydratation, la concentration chute jusqu\'à 20 % après seulement 90 minutes.';
      case 'water_tracker_first':
        return 'Le tracker compte les verres depuis l\'ouverture de l\'app chaque matin. 8 par jour est l\'objectif — mais même atteindre 5, c\'est déjà mieux qu\'hier.';
      case 'water_goal_intro':
        return 'Ton prochain objectif : bois tous les 8 verres aujourd\'hui pour ta première journée complète. Répète-le pendant 7 jours au total et l\'habitude est assimilée, à 66 elle devient automatique. Tu le verras toujours écrit sur la carte, étape par étape.';
      case 'first_completion':
        return 'Fait ! Chaque accomplissement crée une nouvelle connexion neurale. Petite, mais réelle. Ton cerveau vient de renforcer un circuit.';
      case 'streak_explain':
        return 'Si tu reviens demain, ta série commence. La seule règle qui compte : ne jamais sauter deux jours de suite. Un arrêt, c\'est humain. Deux, c\'est une nouvelle habitude — la mauvaise.';
      case 'habits_tab_first':
        return 'Ici tu trouves toutes tes habitudes organisées pour le meilleur moment de ta journée. Welly connaît tes rythmes — les habitudes matinales apparaissent le matin, celles du soir le soir.';
      case 'habit_card_explain':
        return 'L\'arc et l\'objectif sous le nom de l\'habitude se mettent à jour à chaque fois que tu la complètes. Le but est écrit noir sur blanc : 7 jours pour l\'assimiler, 66 pour la rendre automatique — pas besoin de deviner.';
      case 'focus_unlocked':
        return 'Tu as le Focus de 25 minutes disponible dès le départ ! Le cerveau humain a un cycle naturel de concentration d\'environ 20–30 minutes — utilise-le pour un bloc de travail sans distraction.';
      case 'focus_unlocked_2':
        return 'Règle d\'or du Focus : quand le minuteur part, le téléphone est posé face en bas. Même Welly se tait. La notification que tu attends peut attendre 25 minutes — promis.';
      case 'calendar_appears':
        return 'Nouveau ! Le calendrier contextuel montre uniquement les prochaines heures, pas toute la journée. Moins à voir = plus d\'espace mental pour agir. Le futur lointain n\'est pas encore ton problème.';
      case 'growth_first_visit':
        return 'Cette section montre qui tu deviens, pas seulement ce que tu fais. Les phases ne sont pas des récompenses — ce sont de vraies descriptions de ton changement neurologique. La science, pas la motivation, guide le parcours.';
      case 'phase2_reached':
        return '🌱 Phase 2 : Début ! À partir d\'ici, Croissance suit ton parcours, étape par étape. Ta prochaine habitude ne se débloque que lorsque tu es prêt — sans hâte, sans pression : c\'est toi qui fixes le rythme, et prendre encore un peu de temps est toujours une bonne option.';
      case 'phase3_reached':
        return '🌿 Phase 3 : Croissance ! Trois habitudes consolidées. Ta routine existe vraiment maintenant — ce n\'est plus un effort, c\'est une structure. Le plus dur est derrière toi.';
      case 'phase4_reached':
        return '🌳 Phase 4 : Racines. Sept habitudes assimilées — ta routine est devenue un mode de vie. La plupart des gens n\'arrivent pas là. Tu l\'as fait par constance, pas par volonté.';
      case 'phase5_reached':
        return '🌸 Épanouissement. Tu es arrivé. Ça ne veut pas dire que c\'est fini — ça veut dire que tu es devenu quelqu\'un qui construit des habitudes. C\'est le vrai résultat.';
      case 'milestone_7_days':
        return '7 jours consécutifs ! La science dit qu\'après ce seuil, 90 % de ceux qui continuent atteindront 21. Tu es dans la zone où le changement devient beaucoup plus probable.';
      case 'milestone_21_days':
        return '21 jours ! L\'ancien mythe disait que 3 semaines suffisent pour former une habitude. La vérité : 21 jours ne construisent que le sillon initial. Maintenant commence la partie où elle devient vraiment tienne.';
      case 'milestone_66_days':
        return '66 jours ! C\'est le chiffre magique de l\'étude de Phillippa Lally à l\'UCL. Officiellement, selon la science, tu as formé une habitude. Tu ne la construis pas — tu l\'as.';
      case 'streak_broken':
        return 'Aucun problème. La règle est simple : ne jamais sauter deux jours de suite. Tu es déjà revenu aujourd\'hui — la série repart de maintenant. Welly ne compte pas les jours manqués.';
      case 'no_completion_3days':
        return 'Welly est toujours là. Sans jugement. Revenir est plus facile que tu ne le penses — même un seul verre d\'eau compte. Un acte minimal réactive la boucle.';
      case 'perfect_week':
        return 'Semaine parfaite ! 7 complétions sur 7. Ton cerveau a reçu 7 signaux de renforcement consécutifs. D\'un point de vue neurologique, cette semaine a compté triple.';
      case 'rewards_first_visit':
        return 'Les badges ne sont pas de faux points. Chaque badge correspond à un comportement réel que tu as maintenu pendant une période mesurable. Ce sont des instantanés de tes progrès, pas des décorations.';
      default:
        return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':
        return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first':
        return 'EFSA: apport quotidien en eau recommandé 2,0–2,5 L pour un adulte en conditions normales.';
      case 'first_completion':
        return 'Hebb (1949): "neurons that fire together, wire together" — chaque répétition renforce la synapse.';
      case 'streak_explain':
        return 'James Clear, Atomic Habits: "Never miss twice" est la règle la plus efficace pour maintenir une habitude.';
      case 'habit_card_explain':
        return 'Phillippa Lally (UCL, 2010): l\'automaticité débute en moyenne entre 18 et 66 jours, avec la plus forte croissance dans les premières semaines.';
      case 'focus_unlocked':
        return 'Kleitman (1963): cycles ultradiens de 90 min avec des pics d\'attention de 20–30 min. Les techniques Pomodoro exploitent ce rythme.';
      case 'calendar_appears':
        return 'Sweller (1988): Cognitive Load Theory — moins d\'informations visibles simultanément = meilleures décisions.';
      case 'growth_first_visit':
        return 'Wood & Neal (2007): l\'identité change lorsque les comportements deviennent automatiques. Identity precedes action.';
      case 'phase2_reached':
        return 'Gardner (2012): automaticité = exécution sans intention consciente. Le premier automatisme est toujours le plus difficile.';
      case 'phase3_reached':
        return 'Lally et al. (2010): avec 3 habitudes consolidées, la compliance à long terme augmente significativement par rapport à 1 seule.';
      case 'phase4_reached':
        return 'Duhigg (2012): les routines consolidées nécessitent presque zéro délibération consciente — le cortex préfrontal délègue aux ganglions de la base.';
      case 'milestone_7_days':
        return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: l\'automaticité croît le plus rapidement dans les premières semaines — la cohérence initiale est le meilleur prédicteur du maintien à long terme.';
      case 'milestone_21_days':
        return 'Maltz (1960): les "21 jours" étaient une observation chirurgicale, pas une étude scientifique. Lally (2010) estime 66 jours en moyenne.';
      case 'milestone_66_days':
        return 'Lally et al. (2010), UCL: moyenne de 66 jours (plage 18–254) pour atteindre l\'automaticité comportementale.';
      case 'no_completion_3days':
        return 'Fogg (2020): Tiny Habits — même une action minimale maintient vivant le loop neuronal de l\'habitude.';
      case 'perfect_week':
        return 'Schultz et al. (1997): le système dopaminergique répond à la cohérence du renforcement — les séquences consécutives amplifient l\'effet.';
      default:
        return null;
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
  String get passwordForgotSub =>
      'Gib deine E-Mail ein und wir senden dir einen Link';
  String get sendResetEmail => 'Reset-E-Mail senden';
  String get backToLogin => 'Zurück zur Anmeldung';
  String get emailSent => 'E-Mail gesendet';

  String get wellyHi => 'Hallo, ich bin Welly.';
  String get wellyIntro =>
      'Be Well ist die erste App, die dich Schritt für Schritt beim Aufbau gesunder Gewohnheiten begleitet — und dich dabei belohnt. Ich bitte dich nicht, alles an einem Tag zu ändern. Nur mit einer kleinen Sache zu beginnen, mit mir.';
  String get letsGo => 'Los geht\'s';
  String get wellyNameQuestion => 'Zuerst: Wie möchtest du mich nennen?';
  String get wellyNameSub =>
      'Mein Name ist Welly, aber du kannst mir auch einen eigenen Namen geben.';
  String get perfect => 'Perfekt';
  String get firstHabitTitle => 'Erste Gewohnheit: Wasser.';
  String get firstHabitBody1 =>
      'Schon 2% Dehydrierung senken Konzentration und Stimmung — die meisten trinken zu wenig.';
  String get firstHabitBody2 =>
      'Wir beginnen hier: 8 Gläser täglich. Ich erinnere dich ans Trinken, dann fügen wir Schritt für Schritt neue Gewohnheiten hinzu.';
  String get drinkFirstGlass => 'Erstes Glas jetzt trinken';
  String get rewardTitle => 'Perfekt. Eins.';
  String get rewardBody =>
      'Jedes Mal, wenn du etwas abschließt, verdienst du Be Well-Punkte. Du sammelst sie, ohne nachzudenken — und kannst sie für Rabattgutscheine, Voucher, Zubehör, Premium-Funktionen und vieles mehr einlösen.';
  String get goToHome => 'Zur Startseite';
  String get rewardLocked => 'Mit Punkten freischalten';
  @override
  String get previewDiscountTitle => 'Rabattgutschein';
  @override
  String get previewDiscountSub => '10 % bei ausgewählten Partnern';
  @override
  String get previewCoffeeTitle => 'Kaffeegutschein';
  @override
  String get previewCoffeeSub => 'Ein kostenloses Getränk';
  @override
  String get previewPremiumTitle => 'Premium';
  @override
  String get previewPremiumSub => 'Erweiterte Funktionen';
  @override
  String get previewSurpriseTitle => 'Überraschungen';
  @override
  String get previewSurpriseSub => 'Und vieles mehr...';
  String get notifPermTitle => 'Noch eine Sache.';
  String get notifPermBody =>
      'Um dir zu helfen, konsequent zu bleiben, schickt Welly dir ein paar sanfte Erinnerungen zu den passenden Momenten des Tages. Kein Spam, kein Druck: Wie viele, entscheidest du – jederzeit in den Einstellungen.';
  String get notifPermAllow => 'Ja, Benachrichtigungen aktivieren';
  String get notifPermSkip => 'Nicht jetzt';
  String get waterUndo => 'Letztes rückgängig';
  String get waterCooldown => 'Einen Moment warten…';
  String get waterContainerBtn => 'Behälter';

  String get goodMorning => 'Guten Morgen,';
  @override
  String get goodAfternoon => 'Guten Tag,';
  @override
  String get goodEvening => 'Guten Abend,';
  String get greetingFallbackName => 'dir';
  String get phase => 'Phase';
  String get waterToday => 'Wasser heute';
  String get waterGlasses => 'Gläser';
  String get waterTrackedInHome => '💧 in Home erfasst';
  String get waterZero => 'Beginne mit dem ersten Glas.';
  @override
  String get habitsEmptyTitle => 'Eine Gewohnheit nach der anderen';
  @override
  String get habitsEmptySubtitle =>
      'Wasser ist heute dein Ausgangspunkt. Die nächste schaltet sich von selbst frei, sobald diese sich automatisch anfühlt — ohne Eile.';
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
  String get noBadgesYet =>
      'Deine Abzeichen erscheinen hier, wenn du Fortschritte machst.';
  String get todayCompleted => 'Heute abgeschlossen';
  String get phase1 => 'Samen';
  String get phase2 => 'Keim';
  String get phase3 => 'Jung';
  String get phase4 => 'Reif';
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
  @override
  String get focusStartSession => 'Session starten';
  String get focusNewSession => 'Neue Sitzung';
  String get focusDone => 'Sitzung abgeschlossen!';
  String get focusRemaining => 'verbleibend';
  String get focusSessions => 'Sitzungen';
  String get focusMinutes => 'Min Fokus';
  String get focusStreak => 'Serie';
  String get focusDeepWork => 'Tiefe Arbeit';
  String get focusMinRemaining => 'Min verbleibend';
  String get focusBlockOf4 => 'von 4';
  String get focusThenBreak => 'danach 5 Minuten Pause';
  String get containerSize => 'Größe';
  String focusTimerSpoken(int m, int s) => 'Noch $m Minuten $s Sekunden';
  String waterGlassAnnounce(int n, int t) => 'Glas $n von $t erfasst';
  String habitRingSpoken(int n) => '$n Tage insgesamt abgeschlossen';
  String get passwordShow => 'Passwort anzeigen';
  String get passwordHide => 'Passwort verbergen';
  String get waterAlmost => 'Fast geschafft – noch ein bisschen.';
  String get reduceMotion => 'Bewegung reduzieren';
  String get reduceMotionDesc => 'Beruhigt Animationen und bewegte Elemente';
  String get accessibilityHint => 'Diese Einstellungen gelten für die ganze App. Be Well folgt auch der Textgröße und den Animationseinstellungen deines Handys.';
  String get leaveSessionTitle => 'Sitzung verlassen?';
  String get leaveSessionBody => 'Wenn du jetzt gehst, wird diese Sitzung nicht gezählt und du beginnst von vorn. Möchtest du weitermachen?';
  String get leaveSessionStay => 'Weitermachen';
  String get leaveSessionLeave => 'Trotzdem verlassen';
  String waterNextGlassIn(String time) => 'Nächstes Glas in $time';
  String get workScheduleStart => 'Beginn';
  String get workScheduleEnd => 'Ende';
  String get workScheduleTime => 'Uhrzeit';
  String get workScheduleDays => 'Arbeits- oder Lerntage';
  String get workScheduleInviteTitle => 'Sag mir deine Tage und Zeiten';
  String get workScheduleInviteBody => 'Ich lege deine Erinnerungen um deine Arbeits- oder Lernzeiten und halte sie an freien Tagen leichter. Du kannst es jederzeit unter Gewohnheiten ändern.';
  String get workScheduleInviteSet => 'Jetzt einstellen';
  String get workScheduleInviteLater => 'Später';
  String get wdMon => 'Mo';
  String get wdTue => 'Di';
  String get wdWed => 'Mi';
  String get wdThu => 'Do';
  String get wdFri => 'Fr';
  String get wdSat => 'Sa';
  String get wdSun => 'So';
  String get notifInviteTitle => 'Erinnerungen sind aus';
  String get notifInviteBody => 'Kleine Erinnerungen zur richtigen Zeit helfen enorm, aus Handlungen Gewohnheiten zu machen. Schalte sie ein – wie viele, entscheidest du in den Einstellungen.';
  String get notifInviteAction => 'Einschalten';
  String get notifInviteLater => 'Nicht jetzt';
  String get notifComebackTitle1 => 'Ich bin da, wenn du so weit bist 🌱';
  String get notifComebackBody1 => 'Es ist ein paar Tage her. Ein Glas Wasser genügt, um wieder anzufangen – ganz ohne Druck.';
  String get notifComebackTitle2 => 'Kein Druck';
  String get notifComebackBody2 => 'Auch ein kleiner Schritt zählt. Mach weiter, wann du willst – dein Fortschritt ist sicher.';
  String get notifComebackTitle3 => 'Welly denkt an dich';
  String get notifComebackBody3 => 'Deine Gewohnheiten warten genau dort, wo du sie verlassen hast.';
  String get notifComebackTitle4 => 'Neu anfangen ist leicht';
  String get notifComebackBody4 => 'Ein Glas Wasser und du hast schon wieder angefangen.';
  String get resetAllTitle => 'Ganz von vorn beginnen';
  String get resetAllSubtitle => 'Alle Fortschritte löschen und neu starten';
  String get resetAllConfirmTitle => 'Neu beginnen?';
  String get resetAllConfirmBody => 'Wir löschen deine Gewohnheiten, Tage, Serie, Punkte und Einstellungen von diesem Handy und aus deinem Cloud-Konto. Du siehst die Begrüßung wie beim allerersten Mal. Das lässt sich nicht rückgängig machen.';
  String get resetAllConfirmButton => 'Alles löschen';
  String get notifFocusRunningTitle => '🎯 Fokus läuft';
  String get notifFocusRunningBody => 'Eins nach dem anderen. Tippe, um zum Timer zurückzukehren.';
  String get notifFocusPausedTitle => '⏸ Fokus pausiert';
  String get notifFocusPausedBody => 'Lass dir Zeit – mach weiter, wenn du bereit bist.';
  String get dayOne => 'Tag';
  String get wellyMsgMorning => 'Guten Morgen! Ein Glas Wasser und der Tag startet gut.';
  String get wellyMsgAfternoon => 'Noch da? Ein Schluck Wasser und eine kleine Pause tun dir gut.';
  String get wellyMsgEvening => 'Der Tag neigt sich dem Ende, und das ist in Ordnung. Wenn du magst, ein letztes Glas, dann ruh dich aus.';
  String get wellyMsgAllDone => 'Du hast heute alles erledigt. Genieß den Rest des Tages.';
  String get wellyMsgWaterDone => 'Wasser geschafft, toller Rhythmus. Alles weitere ist ein Bonus.';
  String wellyMsgWaterProgress(int n, int t) => 'Gut: $n von $t Gläsern. Kein Stress.';

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
  String get themeAmbientDesc =>
      'Atmosphärische Landschaft,\nredaktionelle Schrift';
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
  String get notifWaterBody =>
      'Das erste Glas Wasser ist ein guter Start in den Tag.';
  String get notifMiddayTitle => '🧘 Be Well';
  String get notifMiddayBody =>
      'Zwei Minuten Dehnen oder Atmen — deine Konzentration dankt es dir später.';
  String get notifLunchTitle => '🍃 Be Well';
  String get notifLunchBody =>
      'Eine echte Pause hilft: Leg den Bildschirm beim Essen für ein paar Minuten weg.';
  String get notifAfternoonTitle => '👀 Be Well';
  String get notifAfternoonBody =>
      'Augen müde vom Bildschirm? 20 Sekunden in die Ferne schauen hilft wirklich.';
  String get notifEveningTitle => 'Be Well 🌙';
  String get notifEveningBody =>
      'Es ist noch Zeit für eine letzte Gewohnheit heute, wenn du magst — sonst bis morgen.';
  String get notifHabitChoiceTitle => '✨ Neue Gewohnheit verfügbar';
  String get notifHabitChoiceBody =>
      'Öffne Be Well, um deine nächste Gewohnheit zu wählen.';

  @override
  String get notifFocusTitle => '🎯 Fokuszeit';
  @override
  String get notifFocusBody =>
      'Wenn du magst: ein konzentrierter Block, ohne Eile.';
  @override
  String get notifBundleTitle => '🌿 Be Well';
  @override
  String notifBundleMorningBody(String list) => 'Für einen guten Start: $list.';
  @override
  String notifBundleBreakBody(String list) => 'Eine sanfte Pause: $list.';
  @override
  String notifBundleEveningBody(String list) =>
      'Für einen guten Tagesabschluss: $list.';
  @override
  String get notifFocusDoneTitle => '✨ Block geschafft';
  @override
  String notifFocusDoneBody(String list) =>
      'Gut gemacht. Nimm dir einen Moment: $list.';
  @override
  String get notifFocusDoneBodyPlain =>
      'Gut gemacht. Nimm dir einen Moment zum Durchatmen.';
  @override
  String get notifAndWord => 'und';

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
  String get navUnlockHabitsMsg =>
      'Schließe 14 Tage Wasser ab, um Gewohnheiten freizuschalten.';
  String get navUnlockGrowthMsg =>
      'Wachstum öffnet sich nach 14 Tagen Konstanz bei einer Gewohnheit – du baust sie bereits auf.';
  String get comingSoonHabitsDesc =>
      'Schließe 14 Wassertage ab.\nDeine erste neue Gewohnheit schaltet sich hier frei.';
  String get comingSoonGrowthDesc =>
      'Baue weiter deine Gewohnheiten auf.\nDer Wachstumsbildschirm wird bald freigeschaltet.';
  String get achievementUnlocked => 'Achievement freigeschaltet!';
  String get newHabitUnlocked => 'Neue Gewohnheit freigeschaltet!';

  String get rewards => 'Belohnungen';
  String get rewardsPoints => 'Be Well-Punkte';
  String get rewardsLocked => 'Belohnungen kommen';
  String get rewardsLockedDesc =>
      'Baue weiter Gewohnheiten auf, um deine Belohnungen freizuschalten';
  String get rewardsHeader => 'Deine Belohnungen';
  String get rewardsHeaderSub => 'Ernte, was du gesät hast';

  String get habitWaterName => 'Wasser trinken';
  String get habitWaterDesc => '8 Gläser über den Tag verteilt';
  String get habitFocus25Name => 'Fokus-Sitzung 25 Min';
  String get habitFocus25Desc => 'Ein Pomodoro ohne Ablenkungen';
  String get habitEyes2020Name => '20-20-20-Regel';
  String get habitEyes2020Desc => 'Alle 20 Min in die Ferne schauen für 20 Sek';
  String get habitNeckName => 'Nackendehnung';
  String get habitNeckDesc => '2 Min Nacken- und Schulterdehnung pro Stunde';
  String get habitBreathingBoxName => 'Box-Atmung';
  String get habitBreathingBoxDesc =>
      '4s einatmen, 4s halten, 4s ausatmen, 4s halten';
  String get habitWalkLunchName => 'Mittagsspaziergang';
  String get habitWalkLunchDesc =>
      'Ein 15-minütiger Spaziergang in der Mittagspause';
  String get habitDeskExName => 'Schreibtischübungen';
  String get habitDeskExDesc => '5 Min aktives Dehnen alle 2 Stunden';
  String get habitWaterMornName => 'Morgenwasser';
  String get habitWaterMornDesc => 'Ein Glas Wasser als erstes am Morgen';
  String get habitPostureName => 'Haltungscheck';
  String get habitPostureDesc =>
      'Haltung jede Stunde überprüfen und korrigieren';
  String get habitLunchParkName => 'Mittagessen im Park';
  String get habitLunchParkDesc => 'Draußen essen, ohne Bildschirm';
  String get habitBreathing478Name => '4-7-8-Atmung';
  String get habitBreathing478Desc =>
      'Anti-Angst: 4s einatmen, 7s halten, 8s ausatmen';
  String get habitStretchName => 'Aktives Dehnen';
  String get habitStretchDesc => '5 Minuten Ganzkörperbewegung';
  String get habitSnackName => 'Gesunder Snack';
  String get habitSnackDesc => 'Ein kleiner nahrhafter Snack am Vormittag';
  String get habitLunchNoScreenName => 'Mittagessen ohne Bildschirm';
  String get habitLunchNoScreenDesc => 'Mittagessen ohne Telefon oder Computer';
  String get habitFocus50Name => 'Tiefes Fokus 50 Min';
  String get habitFocus50Desc => 'Eine ununterbrochene Tiefarbeits-Sitzung';
  String get habitMeditationName => 'Mikro-Meditation';
  String get habitMeditationDesc => '3 Minuten achtsame Präsenz';
  String get habitStairsName => 'Treppe statt Aufzug';
  String get habitStairsDesc => 'Wann immer möglich die Treppe nehmen';
  String get habitSleepName => 'Vor-Schlaf-Routine';
  String get habitSleepDesc => '30 Minuten ohne Bildschirm vor dem Schlafen';
  String get habitWakeName => 'Konstante Aufwachzeit';
  String get habitWakeDesc => 'Jeden Tag zur gleichen Zeit aufstehen';
  String get habitNapName => 'Power-Nap 20 Min';
  String get habitNapDesc => 'Eine kurze intentionale Ruhe am Nachmittag';
  String get habitFocusPhoneName => 'Fokus ohne Telefon';
  String get habitFocusPhoneDesc => 'Telefon während Fokus-Sitzungen umgedreht';
  String get habitMicroWalkName => 'Mikro-Spaziergang 5 Min';
  String get habitMicroWalkDesc =>
      '5 Minuten Gehen alle 90 Minuten — Ultradianischer Zyklus';
  String get habitDigitalSunsetName => 'Digitaler Sonnenuntergang';
  String get habitDigitalSunsetDesc =>
      'Kein Social Media in der Stunde vor dem Schlafen';
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
  @override
  String get guideHowShoulderRoll =>
      'Sitz aufrecht, die Arme locker. Zieh die Schultern zu den Ohren, rolle sie nach hinten und dann nach unten, in einem langsamen Kreis. Die Brust öffnet sich, der Nacken bleibt weich.';
  @override
  String get guideHowSpinalTwist =>
      'Sitz aufrecht. Dreh den Oberkörper nach rechts, die linke Hand am rechten Knie, die rechte an der Rückenlehne. Schau über die Schulter, ohne zu forcieren, dann Seitenwechsel.';
  @override
  String get guideHowWrist =>
      'Heb die Unterarme vor dich, die Ellbogen aufgestützt. Halte die Hände locker und kreise langsam mit den Handgelenken, erst in die eine, dann in die andere Richtung.';
  @override
  String get guideHowNeckTilt =>
      'Sitz aufrecht, die Schultern tief. Neig den Kopf zur rechten Schulter, das Ohr nähert sich, ohne die Schulter zu heben. Halten, atmen, dann Seite wechseln.';
  @override
  String get guideHowCatCow =>
      'Hände auf den Knien. Beim Einatmen den Rücken wölben, die Brust öffnen, der Blick geht leicht nach oben. Beim Ausatmen den Rücken runden und das Kinn zur Brust führen.';
  @override
  String get guideHowNeckRoll =>
      'Sitz aufrecht mit lockeren Schultern. Führ das Kinn zur Brust, dann roll den Kopf langsam in einem weiten, weichen Kreis. Bei Spannung den Kreis kleiner machen.';
  @override
  String get guideHowShrug =>
      'Die Arme locker an den Seiten, zieh beide Schultern zu den Ohren, halte kurz und lass sie dann fallen. Spür, wie sich der Nacken löst.';
  @override
  String get guideHowArmReach =>
      'Steh hüftbreit. Leg die Hände zusammen und streck die Arme nach oben, als würdest du ein Stück wachsen. Schau leicht nach oben, dann langsam senken.';
  @override
  String get guideHowSideBend =>
      'Steh mit gespreizten Beinen. Heb einen Arm über den Kopf und neig den Oberkörper zur Gegenseite, die andere Hand an der Hüfte. Becken ruhig, tief atmen, dann Seitenwechsel.';
  @override
  String get guideHowHips =>
      'Hände an den Hüften, Füße breit, Knie weich. Zeichne mit dem Becken einen langsamen, weiten Kreis, der Oberkörper bleibt ruhig. Zur Hälfte die Richtung wechseln.';
  @override
  String get guideHowCalf =>
      'Steh und halt dich zur Balance an einem Stuhl fest. Heb dich auf die Zehenspitzen beider Füße, halte eine Sekunde, dann langsam senken. Die Beine bleiben gerade.';
  @override
  String get guideHowFold =>
      'Füße hüftbreit, Knie weich. Beug dich aus der Hüfte nach vorn, Kopf und Arme hängen locker. Nicht forcieren: nur so weit, dass du eine sanfte Dehnung spürst, dann langsam aufrichten.';
  @override
  String get guideSafetyNote =>
      'Beweg dich langsam und ohne Zwang: Bei Schmerzen aufhören.';

  @override
  String get guidePhaseMove => 'Bewege dich';
  @override
  String get guidePhaseRest => 'Ruhe';
  @override
  String get guidePhaseRightHold => 'Nach rechts drehen, halten';
  @override
  String get guidePhaseCenter => 'Zurück zur Mitte';
  @override
  String get guidePhaseLeftHold => 'Nach links drehen, halten';
  @override
  String get guidePhaseClockwise => 'Im Uhrzeigersinn';
  @override
  String get guidePhaseCounterClockwise => 'Gegen den Uhrzeigersinn';
  @override
  String get guidePhaseArchCow => 'Rücken hohl machen (Kuh)';
  @override
  String get guidePhaseRoundCat => 'Rücken runden (Katze)';
  @override
  String get guidePhaseRaiseHold => 'Heben, halten';
  @override
  String get guidePhaseLowerRelease => 'Senken und lösen';
  @override
  String get guidePhaseReachHold => 'Nach oben strecken, halten';
  @override
  String get guidePhaseLowerSlowly => 'Langsam senken';
  @override
  String get guidePhaseFoldHold => 'Nach vorne beugen, halten';
  @override
  String get guidePhaseRiseSlowly => 'Langsam aufrichten';

  String get neverMissTwiceTitle => 'Nicht zwei Tage hintereinander auslassen.';
  String get neverMissTwiceBody =>
      'Eine kleine Aktion zählt. Sogar ein Glas Wasser.';
  String get neverMissTwiceCta => '💧 Ein Glas Wasser hinzufügen';
  String get wellyBonusTitle => 'Welly-Bonus!';
  String get wellyBonusBody => 'Dreifache Punkte diese Runde 🎉';

  String get coachDay1 => 'Erster Tag. Der wichtigste.';
  String get coachDay3 => '3 Tage. Dein Körper beginnt es zu registrieren.';
  String get coachDay7 => '7 Tage. Du baust etwas auf.';
  String get coachDay14 => '2 Wochen. Diese Gewohnheit gehört dir jetzt.';
  String get coachGeneral => 'Jeder Tag zählt. Auch die schwierigen.';

  String get badgeFirstStep => 'Erster Schritt';
  String get badgeFirstStepDesc => 'Erster Tag abgeschlossen';
  String get badgeOneWeek => 'Eine Woche';
  String get badgeOneWeekDesc => '7 Tage Gewohnheiten';
  String get badgeThreeWeeks => 'Drei Wochen';
  String get badgeThreeWeeksDesc => '21 Tage abgeschlossen';
  String get badgeSixWeeks => 'Sechs Wochen';
  String get badgeSixWeeksDesc => '42 Tage abgeschlossen';
  String get badgeThreeMonths => 'Drei Monate';
  String get badgeThreeMonthsDesc => '90 Tage Wachstum';
  String get badgeInSync => 'Im Einklang';
  String get badgeInSyncDesc => '2 aktive Gewohnheiten';
  String get badgeMultihabit => 'Multigewohnheit';
  String get badgeMultihabitDesc => '4 aktive Gewohnheiten';
  String get badgeHydrated => 'Gut hydriert';
  String get badgeHydratedDesc => 'Wasser gefestigt';
  String get badgeFocused => 'Im Fokus';
  String get badgeFocusedDesc => 'Fokus 25 Min gefestigt';
  String get badgeWalker => 'Spaziergänger';
  String get badgeWalkerDesc => 'Mittagsspaziergang gefestigt';
  String get badgeBreath => 'Atem';
  String get badgeBreathDesc => 'Atmung gefestigt';
  String get badgeRootedName => 'Verwurzelte Gewohnheiten';
  String get badgeRootedDesc => 'Gewohnheiten, die zur zweiten Natur wurden';
  String get badgeTierBronze => 'Bronze';
  String get badgeTierSilver => 'Silber';
  String get badgeTierGold => 'Gold';
  String get growthNextGoal => 'Nächstes Ziel';
  String growthHabitsToRoot(int n) =>
      n == 1 ? 'Noch 1 Gewohnheit' : 'Noch $n Gewohnheiten';

  String get habitChoiceTitle => 'Zeit für etwas Neues.';
  String get habitChoiceSub => 'Wähle, worauf du dich jetzt konzentrierst.';
  String get habitChoiceShowOther => 'andere Optionen zeigen ›';
  String get habitChoiceNotReady => 'Ich bin noch nicht bereit dafür';
  String get habitChoiceOpen => 'Nächste Gewohnheit wählen';
  String get habitNotReadySnoozed =>
      'Kein Problem — ich frage in einer Woche noch einmal.';
  @override
  String get habitNotReadyMeanwhile => 'Probier stattdessen Atmen';
  @override
  String habitMatchesGoal(String goal) => 'Passt zu: $goal';
  String get consolidatedTitle => '🏆 Glückwunsch!';
  String consolidatedBody(String habitName) =>
      'Du hast „$habitName" zu einer echten Gewohnheit gemacht — dein Gehirn hat dafür einen dauerhaften Schaltkreis aufgebaut.';
  String get consolidatedBadge => 'Gewohnheit gefestigt';
  String get consolidatedCta => 'Weiter';
  @override
  String get consolidatedCtaNext => 'Nächste Gewohnheit wählen →';
  @override
  String get automaticTitle => '💚 Automatisch!';
  @override
  String automaticBody(String habitName) =>
      'Du musst nicht mehr daran denken — "$habitName" läuft jetzt von allein, dein Gehirn übernimmt. Das ist die echte Ziellinie.';
  @override
  String get automaticBadge => 'Gewohnheit automatisch';
  @override
  String get calendarTowardAssimilated => 'Auf dem Weg zur Gewohnheit';
  @override
  String get calendarTowardAutomatic => 'Auf dem Weg zur Automatik';
  @override
  String get calendarMilestoneSoon => 'GLEICH GESCHAFFT';
  @override
  String calendarMilestoneInDays(int days) => 'IN $days TAGEN';
  @override
  String get calendarAssimilatedTitle => 'Gewohnheit verankert';
  @override
  String get calendarAssimilatedSub =>
      'Dein Gehirn beginnt, es als Routine zu speichern — die Truhe öffnet sich.';
  @override
  String get calendarAutomaticTitle => 'Automatische Gewohnheit';
  @override
  String get calendarAutomaticSub =>
      'Der größte Meilenstein: du musst nicht mehr daran denken.';
  @override
  String get calendarLongArcNote =>
      'Der schwierigste Teil liegt hinter dir. Jeder weitere Tag festigt die Automatik.';
  @override
  String get calendarDoneTitle => 'Automatisch — geschafft';
  @override
  String calendarDoneSub(int points) =>
      'Diese Gewohnheit läuft jetzt von allein. +$points Punkte unterwegs gesammelt.';
  @override
  String get dailyObjectivesTitle => 'Heutige Ziele';
  @override
  String dailyObjectivesSub(int done, int total) => done >= total && total > 0
      ? 'Heute alles erledigt'
      : '$done von $total heute erledigt';
  @override
  String get badgeUnlockedTitle => '🏆 Abzeichen freigeschaltet!';
  @override
  String get badgeUnlockedCta => 'Großartig!';
  @override
  String get newMissionLabel => 'Neue Mission';
  @override
  String get missionStartCta => 'Los geht\'s!';
  @override
  String get missionStreakStart => 'Deine Serie beginnt genau hier.';
  @override
  String get missionStreakGoal =>
      '7 Tage, um es zur Gewohnheit zu machen, 66 für Automatismus.';
  @override
  String streakMilestoneTitle(int days) => '🔥 $days Tage in Folge!';
  @override
  String get streakMilestoneBadge => 'Streak-Meilenstein';
  String habitStartsTomorrow(String habitName) =>
      'Sehr gut! Genieße heute deinen Erfolg — wir beginnen morgen mit „$habitName".';
  @override
  String habitChosenIntro(String habitName) =>
      'Sehr gut! Genieße heute deinen Erfolg — „$habitName" beginnt morgen. Mach sie einmal, dann bleib dran: in 7 Tagen ist sie verankert, nach 66 automatisch. Das Ziel siehst du direkt auf ihrer Karte, Schritt für Schritt.';
  String get habitEffortLow => 'leicht';
  String get habitEffortMedium => 'moderat';
  String get habitEffortHigh => 'anspruchsvoll';

  String get errorNetwork => 'Keine Internetverbindung';
  String get errorGeneral => 'Etwas ist schiefgelaufen. Versuche es erneut.';
  String get errorInvalidEmail => 'Ungültige E-Mail-Adresse';
  String get errorWeakPassword => 'Das Passwort ist zu schwach';
  String get errorEmailInUse => 'Diese E-Mail wird bereits verwendet';
  String get errorInvalidCredentials => 'Falsche E-Mail oder falsches Passwort';
  String get errorTooManyAttempts =>
      'Zu viele Versuche. Konto vorübergehend gesperrt';
  String get errorTimeout =>
      'Der Server antwortet nicht. Versuche es gleich nochmal';
  String get errorCancelled => 'Anmeldung abgebrochen';
  String get errorAccountDisabled =>
      'Konto deaktiviert. Kontaktiere den Support';
  @override
  String get errorRequiresRecentLogin =>
      'Melde dich zu deiner Sicherheit erneut an, bevor du dein Konto löschst.';
  @override
  String get deleteAccount => 'Konto löschen';
  @override
  String get deleteAccountConfirmTitle => 'Dein Konto löschen?';
  @override
  String get deleteAccountConfirmBody =>
      'Löscht dein Konto und alle deine Daten endgültig — Gewohnheiten, Streaks, Punkte, Abzeichen. Das lässt sich nicht rückgängig machen.';
  @override
  String get deleteAccountCta => 'Ja, alles löschen';
  @override
  String get deleteAccountDone => 'Dein Konto wurde gelöscht.';
  String get passwordStrengthWeak => 'Schwach';
  String get passwordStrengthMedium => 'Mittel';
  String get passwordStrengthStrong => 'Stark';
  String get passwordStrengthVeryStrong => 'Sehr stark';
  String get validationEmailRequired => 'Gib deine E-Mail ein';
  String get validationPasswordRequired => 'Gib ein Passwort ein';
  String get validationPasswordTooShort => 'Mindestens 8 Zeichen';
  String get validationNameRequired => 'Gib deinen Namen ein';
  String get validationNameTooShort => 'Mindestens 2 Zeichen';
  String get accountLockedBody =>
      'Zu viele fehlgeschlagene Versuche.\nVersuch es erneut in';
  String get accountLockedEmailSent =>
      'Du hast eine E-Mail mit den Anweisungen erhalten.';
  String get offlineLoginRequired =>
      'Keine Verbindung — Anmeldung erfordert Internet';
  String get forgotCheckEmailTitle => 'Überprüfe deine E-Mail';
  String forgotEmailSentBody(String email) =>
      'Falls ein Konto für $email existiert, erhältst du einen Link zum Zurücksetzen des Passworts.';
  String get forgotLinkExpiry => 'Der Link läuft in 30 Minuten ab.';
  String get forgotResendLimitReached => 'Wiederholungslimit erreicht';
  String forgotResendIn(int seconds) => 'Erneut senden in ${seconds}s';
  String get verifyEmailCta =>
      'Klicke auf den Link, um dein Konto zu aktivieren.';
  String get verifyResendCta => 'Bestätigungs-E-Mail erneut senden';
  String get verifyChecked => 'Ich habe meine E-Mail bestätigt';
  String get verifyDifferentEmail => 'Andere E-Mail verwenden?';
  String get verifySendError =>
      'Senden fehlgeschlagen, versuch es gleich nochmal';
  String get welcomeSlide1Title => 'Dein persönlicher\nWellness-Plan';
  String get welcomeSlide1Sub =>
      'Be Well erstellt einen maßgeschneiderten Plan basierend auf deinen Gewohnheiten und Zielen.';
  @override
  String get welcomeSlide1Footer =>
      'Reih dich ein bei allen, die schon jetzt gesündere Gewohnheiten aufbauen, Tag für Tag.';
  String get welcomeSlide2Title => 'Erinnerungen, die\ndeinen Kalender kennen';
  String get welcomeSlide2Sub =>
      'Erinnerungen passen sich deinen Terminen und Zeiten an, damit sie dich nie zur falschen Zeit unterbrechen.';
  String get welcomeSlide3Title =>
      'Verwandle Gewohnheiten\nin echte Belohnungen';
  String get welcomeSlide3Sub =>
      'Sammle Punkte durch das Abschließen von Aktivitäten und tausche sie gegen Rabatte, Gutscheine und mehr.';
  String get welcomeSkip => 'Überspringen';
  String get welcomeNext => 'Weiter →';
  String get welcomeStart => 'Einrichtung starten →';
  String get welcomeConfigureLater => 'Später einrichten';

  String get qProfileTitle => 'Erzähl uns von dir';
  String get qProfileSub =>
      'Hilft uns, den richtigen Plan für dich zu erstellen.';
  String get qGoalsTitle => 'Ziele & Stress';
  String get qGoalsSub =>
      'Der wichtigste Bildschirm zur Personalisierung deines Plans.';
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
  String get q21Label =>
      'Q22 · Wie lange kannst du dich am Stück konzentrieren?';
  String get q22Label =>
      'Q23 · Wie viele Meetings hast du täglich (im Schnitt)?';
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
  String get calSyncNote =>
      '✓ Wir fragen nach der Berechtigung, sobald du deinen Plan bestätigt hast';
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
  String get crisisBody =>
      'Be Well ist da, um dich zu unterstützen. Bei akutem Bedarf: kontaktiere eine lokale Hilfshotline.';
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
  String get planPreviewSub =>
      'Personalisiert nach deinen Antworten. Du kannst ihn jederzeit in den Einstellungen ändern.';
  String get planRemindersPerDay => 'Erinnerungen/Tag';
  String get planFocusSessions => 'Fokus-Sessions';
  String get planPointsPerDay => 'Punkte/Tag';
  String get planMorning => '🌅 Morgen';
  String get planAfternoon => '☀️ Nachmittag';
  String get planEvening => '🌙 Abend';
  String planFromTime(String time) => 'ab $time';
  String planConnectCalendar(String name) => '$name verbinden';
  String get planConnectCalendarSub =>
      'Wir fragen nach der Berechtigung, sobald du bestätigst';
  String get planFallbackNote =>
      'Wir haben einen Standardplan verwendet. Wir verfeinern ihn, während du die App nutzt.';
  String get planConfirmCta => 'Mit Be Well starten  ';
  String get planConfirmSub =>
      'Du kannst deinen Plan jederzeit in den Einstellungen ändern';
  String planMinutes(int n) => '$n Min';
  String get profileTitle => 'Profil';
  String get accountSection => 'Konto';
  String get emailAccountLabel => 'Konto-E-Mail';
  String get supportSection => 'Support';
  String get editNameTitle => 'Namen bearbeiten';
  String get yourNameHint => 'Dein Name';
  String get resetTutorialTitle => 'Tutorial zurücksetzen';
  String get resetTutorialBody =>
      'Welly zeigt alle Tutorial-Dialoge erneut an, als wäre es das erste Mal. Nützlich zum Testen des Ablaufs.';
  String get resetTutorialCta => 'Zurücksetzen';
  String get resetTutorialSnackbar => 'Tutorial zurückgesetzt ✓';
  String genericError(String msg) => 'Fehler: $msg';
  String get settingsTitle => 'Einstellungen';
  String get styleCardDesc => 'Inhalte in Karten,\nklare Typografie';
  String get styleAmbientDesc =>
      'Atmosphärische Landschaft,\nredaktionelle Schrift';
  String get toneSection => 'Farbton';
  String get accessibilitySection => 'Barrierefreiheit';
  String get contrastDesc => 'Erhöht den Textkontrast';
  String get textSizeDesc => 'Vergrößert die Schriftgröße';
  String get remindersLabel => 'Aktivitätserinnerungen';
  String get remindersDesc => 'Benachrichtigungen für geplante Aktivitäten';
  String get comingSoonTitle => 'Demnächst verfügbar';
  String get comingSoonBody =>
      'Dieser Bereich ist noch nicht verfügbar — er steht auf unserer Roadmap.';
  String get habitMarkDone => 'Erledigt';
  @override
  String get habitGoalFirstTime => '🎯 Ziel: mach es zum ersten Mal';
  @override
  String habitGoalInProgressToday(int count, int target) =>
      '🎯 $count/$target Gläser heute — schließ sie ab für deinen ersten vollen Tag';
  @override
  String habitGoalBuilding(int days, int target) =>
      '🎯 Ziel: die Routine aufbauen — $days/$target Tage';
  @override
  String habitGoalBonus(int days, int target) =>
      '🌳 Gewohnheit verankert! Bonusziel: sie automatisch machen — $days/$target Tage';
  @override
  String get habitGoalMastered => '💚 Automatisch — Ziel erreicht';
  String get slowdownReasonHeavy =>
      'Diese Gewohnheit fühlt sich gerade zu viel an';
  String heatmapDaysAgo(int n) => 'vor $n Tagen';
  String get heatmapToday => 'heute';
  String phaseStarted(String date) => 'begonnen am $date';
  String phaseReached(String date) => 'erreicht am $date';
  String get marketAdTitle => 'Unterstütze Be Well';
  String get marketAdSubtitle => 'Verdiene 10 Pkt. durch einen Werbespot';
  @override
  String marketAdRemaining(int n) => 'Heute noch $n übrig';
  @override
  String get marketAdCapReached =>
      'Du hast das Tageslimit erreicht — komm morgen wieder';
  String get marketAdDialogBody =>
      'Schau dir eine Werbung an: du hilfst uns, die App kostenlos zu halten, und erhältst sofort 10 Punkte.';
  String get marketWatchNow => 'Jetzt ansehen';
  String get dialogGotIt => 'Verstanden';
  String get marketAdUnavailable => 'Spot momentan nicht verfügbar';
  String get referralTitle => 'Freund einladen';
  String get referralSubtitle =>
      'Verdiene 50 Pkt. für jeden Freund, der sich anmeldet';
  String get referralApply => 'Anwenden';
  String get referralApplied =>
      'Code angewendet! Dein Freund erhält den Bonus bald. 🎉';
  String get referralErrorInvalid => 'Ungültiger Code';
  String get referralErrorOwn =>
      'Du kannst deinen eigenen Code nicht verwenden';
  String get referralErrorAlready => 'Du hast bereits einen Code eingelöst';
  String get referralErrorNotSignedIn => 'Du musst angemeldet sein';
  String get referralErrorGeneric =>
      'Etwas ist schiefgelaufen, versuch es erneut';
  String get referralHint => 'Hast du einen Einladungscode?';
  String premiumPrice(String price) => '$price/Monat';
  String referralShareButton(String code) => 'Meinen Code teilen · $code';
  String get referralRetry =>
      'Code konnte nicht erstellt werden — zum Wiederholen tippen';
  String referralShareMessage(String code) =>
      'Ich nutze Be Well, um Tag für Tag gesündere Gewohnheiten aufzubauen 🌱\n'
      'Lade die App herunter und nutze meinen Einladungscode "$code" — du erhältst 50 Bonuspunkte, sobald du startest!';

  String get waterContainerGlass => 'Glas';
  String get waterContainerBottle => 'Flasche';
  String get waterContainerSettings => 'Wie verfolgst du dein Wasser?';
  String get waterGoalCalc =>
      'Du brauchst etwa N Behälter für deine 2 Liter am Tag';

  String get habitsMorningTitle => 'Starte gut in den Tag.';
  String get habitsMiddayTitle => 'Im richtigen Moment.';
  String get habitsAfternoonTitle => 'Guten Nachmittag.';
  String get habitsEveningTitle => 'Wie war dein Tag?';
  String get habitsNowLabel => 'Jetzt';
  String get habitsComingSoon => 'Demnächst';
  String get configuratorTitle => 'Personalisiere deinen Plan';
  String get configuratorSubtitle =>
      'Beantworte ein paar Fragen für passende Gewohnheitsvorschläge';
  String get configuratorDoneTitle => 'Dein Plan ist personalisiert';
  String get configuratorDoneSubtitle =>
      'Tippen, um deine Antworten zu aktualisieren';
  String get habitsAllDone => 'Alles gut für jetzt. Welly ist bei dir.';
  String get habitsToday => 'Dein Rhythmus heute';
  String get completedToday => 'heute erledigt';

  String get timeMorning => 'Morgen';
  String get timeMidday => 'Vormittag';
  String get timeLunch => 'Mittagspause';
  String get timeAfternoon => 'Nachmittag';
  String get timeEvening => 'Abend';

  String get onboardingUserTypeTitle => 'Und wie verbringst du deine Tage?';
  String get onboardingStudent => 'Studium';
  String get onboardingWorker => 'Arbeit';

  String get workScheduleBanner =>
      'Ich habe Standardzeiten eingestellt (Mo–Fr, 9-13 / 14-18). Passt das für dich?';
  String get workScheduleConfirm => 'Passt so';
  String get workScheduleEdit => 'Bearbeiten';
  String get workScheduleTitle => 'Deine Arbeitszeiten';
  String get workScheduleMorning => 'Morgen';
  String get workScheduleAfternoon => 'Nachmittag';
  String get workScheduleLunch => 'Ich habe eine feste Mittagspause';
  String get workScheduleSave => 'Speichern';

  String get slowdownPrompt =>
      'Ich habe bemerkt, dass du Schwierigkeiten hast, das Tempo zu halten. Sollen wir ein wenig langsamer werden?';
  String get slowdownYes => 'Ja, langsamer';
  String get slowdownNo => 'Nein, ich mache weiter';
  String get slowdownHabitMenu => 'Ich brauche mehr Zeit mit dieser';
  String get slowdownMenuSubtitle =>
      'Neue Gewohnheitsvorschläge werden für 2 Wochen pausiert — diese hier bleibt trotzdem in deinem Plan.';
  String get slowdownWellyResponse =>
      'Kein Problem — neue Vorschläge sind für 2 Wochen pausiert. Diese Gewohnheit bleibt in deinem Plan, nimm dir die Zeit, die du brauchst.';
  String get speedupPrompt =>
      'Du machst das sehr gut — bist du bereit für etwas Neues vor dem geplanten Zeitpunkt?';
  String get speedupYes => 'Ja, ich bin bereit';
  String get speedupNo => 'Nein, ich bleibe hier';

  String get calendarTitle => 'Die nächsten Stunden';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pause';
  String get calendarLongBreak => 'Lange Pause';

  String get tutorialOk => 'Verstanden!';
  String get tutorialMore => 'Mehr →';
  String get tutorialSkip => 'Überspringen';
  @override
  String get tutorialShowSource => 'Quelle anzeigen';
  String get tutorialNext => 'Weiter →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable => 'Punkte verfügbar';
  String get marketplaceTabRewards => 'Prämien';
  String get marketplaceTabDiscounts => 'Rabatte';
  String get marketplaceTabInApp => 'In-App';
  String get rewardsToRedeem => 'einzulösen';
  String get rewardRedeemed => 'Da ist es. Du hast es verdient.';
  String get rewardConfirmTitle => 'Bist du sicher?';
  String get rewardConfirmBody =>
      'X Punkte werden von deinem Guthaben abgezogen.';
  String get rewardRedeemFailed =>
      'Diese Belohnung konnte nicht eingelöst werden — zu wenig Punkte oder nicht mehr verfügbar.';
  String get copyCode => 'Code kopieren';
  String get codeCopied => 'Kopiert';
  String get watchAd => 'Spot ansehen · +10 Pt';
  String get whyAds => 'warum?';
  String get whyAdsTitle => 'Be Well ist für alle kostenlos';
  String get whyAdsBody =>
      'Be Well ist eine kostenlose App, um für alle zugänglich zu sein. Wie jeder Dienst hat es Betriebskosten. Indem du Werbung ansiehst, wenn du kannst, hilfst du uns, den Dienst am Laufen zu halten und ihn für alle zu verbessern. Danke.';
  String get discountsActive => 'aktive Rabatte';
  String get discountsNote =>
      'Rabatte werden monatlich aktualisiert. Keine Punkte erforderlich.';
  String get discountExclusive => 'exklusiv Be Well';
  String get goToSite => 'Zur Website';
  String get affiliateNote => 'Dieser Link unterstützt Be Well';
  String get inAppWelly => 'welly';
  String get inAppSoundscape => 'soundscape';
  String get inAppMinigame => 'minispiel';
  String get inAppPercorsi => 'pfade';
  String get unlockItem => 'Freischalten';
  String get itemUnlocked => 'Freigeschaltet';
  String get premiumAllContent => 'Alle In-App-Inhalte inklusive';
  String get premiumPoints => '+20% Punkte für jede Gewohnheit';
  String get premiumWelly => 'Vollständig anpassbarer Welly';
  String get premiumDiscounts => 'Exklusive Rabatte vorab';
  String get premiumTrial => '7 Tage kostenlos testen';
  String get premiumOr => 'oder einzeln mit Punkten kaufen';

  String get feedbackTitle => 'Feedback geben';
  String get feedbackSubtitle => 'Hilft uns, Be Well für dich zu verbessern.';
  String get feedbackHint => 'Schreib dein Feedback hier…';
  String get feedbackSubmit => 'Feedback senden';
  String get feedbackThanks => 'Danke für dein Feedback!';
  String get feedbackError =>
      'Senden fehlgeschlagen, versuch es gleich nochmal';
  String get feedbackCategoryBug => 'Bug';
  String get feedbackCategoryIdea => 'Idee';
  String get feedbackCategoryFeature => 'Funktion';
  String get feedbackCategoryOther => 'Sonstiges';

  String spotlightText(String id) {
    switch (id) {
      case 'home_welcome':
        return 'Willkommen! Ich bin Welly. Lass mich dir alles zeigen, damit du richtig starten kannst.';
      case 'home_water':
        return 'Das ist deine erste Gewohnheit: Wasser trinken. 8 Gläser pro Tag ist dein Ziel. Einfach und wirkungsvoll.';
      case 'home_add_glass':
        return 'Tippe hier jedes Mal, wenn du ein Glas trinkst. Jedes Tippen baut deine Gewohnheit auf — versuch es jetzt!';
      case 'home_welly':
        return 'Das bin ich — Welly! Ich ändere meinen Ausdruck je nach deinen Fortschritten. Je besser es läuft, desto strahlender werde ich.';
      case 'home_phase':
        return 'Das ist deine Phase. Du beginnst bei Samen — Phase 1. Baue Gewohnheiten auf, um bis Phase 5 zu wachsen: Strahlend.';
      case 'home_nav':
        return 'Das ist deine Navigation. Bei Gewohnheiten ist der 25-Minuten-Fokus schon einsatzbereit; Wachstum öffnet sich nach 14 Tagen Konstanz.';
      case 'habits_welcome':
        return 'Von hier aus verwaltest du alle deine Routinen.';
      case 'habits_now':
        return 'Die \'Jetzt\'-Karte zeigt die Gewohnheit, die für diesen genauen Moment deines Tages am relevantesten ist.';
      case 'habits_now_arc':
        return 'Die Zahl in der Mitte zeigt, an wie vielen Tagen du diese Gewohnheit insgesamt schon erledigt hast — nicht nur heute. Null heißt, du hast sie noch kein einziges Mal gemacht: mach sie heute, dann wird daraus 1. Tippe jederzeit darauf, um es erneut zu sehen.';
      case 'habits_list':
        return 'Alle Gewohnheiten sind nach ihrer besten Zeit sortiert. Morgengewohnheiten erscheinen morgens zuerst — Welly kennt deinen Rhythmus.';
      case 'habits_ready':
        return 'Bereit! Tippe täglich auf \'Erledigt\', um deine Serie aufzubauen. Kleine Handlungen, konsequent gemacht, verändern alles.';
      case 'habits_progression':
        return 'Deine nächste Gewohnheit schaltet sich von selbst frei, sobald du die aktuellen wirklich verinnerlicht hast — nicht vorher. Jede Karte zeigt genau, wo du stehst: erstes Mal, Routine im Aufbau, verankert nach 7 Tagen, automatisch nach 66. Keine Eile, kein Druck: du bestimmst das Tempo.';
      // Marketplace tour
      case 'marketplace_welcome':
        return 'Das sind deine Be Well Belohnungen! Jedes Glas Wasser, jede abgeschlossene Gewohnheit bringt dich hierher — wo deine Bemühungen zu echten Prämien werden.';
      case 'marketplace_points':
        return 'Dein Punktestand ist hier immer sichtbar. Er baut sich automatisch auf, während du Gewohnheiten aufbaust — kein zusätzlicher Aufwand.';
      case 'marketplace_tabs':
        return 'Drei Reiter: Prämien gegen Punkte einlösen; Rabatte, exklusive Angebote, die immer kostenlos sind, ohne Punkte, monatlich aktualisiert; und In-App, wo du Punkte für Dinge innerhalb von Be Well ausgibst — Welly-Outfits, Klanglandschaften, Minispiele, geführte Programme.';
      case 'marketplace_card':
        return 'Jede Prämie hat Punktekosten. Tippe zum Einlösen — du bekommst sofort einen Code. Je konsequenter du bist, desto mehr schaltest du frei.';
      // Growth tour
      case 'growth_welcome':
        return 'Das ist dein Wachstum. Keine Rangliste — ein Spiegel. Er zeigt, wer du wirst, nicht nur, was du tust.';
      case 'growth_phase':
        return 'Deine Phase zeigt, wie tief verwurzelt deine Gewohnheiten sind. Von Phase 1 (Saat) bis Phase 5 (Strahlend) — jeder Schritt ist eine echte neurologische Veränderung.';
      case 'growth_heatmap':
        return 'Diese Heatmap zeigt deine Beständigkeit über die Zeit. Wissenschaft sagt: Das Muster zählt mehr als die Intensität — ein paar verpasste Tage setzen nicht alles zurück.';
      case 'growth_badges':
        return 'Abzeichen sind keine Dekoration. Jedes entspricht einem Verhalten, das du über einen messbaren Zeitraum aufrechterhalten hast. Sie sind Beweise deiner Reise.';
      default:
        return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitChosenIntro(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':
        return 'Willkommen! Dies ist deine Basis. Oben findest du immer die dringendste Gewohnheit für den Moment. Fang dort an — der Rest kann warten.';
      case 'home_first_open_2':
        return 'Wasser ist die erste Gewohnheit, weil es die biologische Grundlage für alles andere ist. Ohne Flüssigkeit sinkt die Konzentration nach nur 90 Minuten um bis zu 20 %.';
      case 'water_tracker_first':
        return 'Der Tracker zählt Gläser ab dem Öffnen der App jeden Morgen. 8 pro Tag ist das Ziel — aber schon 5 zu erreichen ist besser als gestern.';
      case 'water_goal_intro':
        return 'Dein nächstes Ziel: trink heute alle 8 Gläser für deinen ersten vollen Tag. Wiederhole es 7 Tage insgesamt, dann ist die Gewohnheit verinnerlicht, ab 66 wird sie automatisch. Du siehst es immer auf der Karte, Schritt für Schritt.';
      case 'first_completion':
        return 'Geschafft! Jeder Abschluss schafft eine neue neuronale Verbindung. Klein, aber real. Dein Gehirn hat gerade eine Schaltung gestärkt.';
      case 'streak_explain':
        return 'Wenn du morgen zurückkommst, beginnt deine Serie. Die einzige Regel: nie zwei Tage hintereinander auslassen. Eine Pause ist menschlich. Zwei sind eine neue Gewohnheit — die falsche.';
      case 'habits_tab_first':
        return 'Hier findest du alle Gewohnheiten nach dem besten Moment deines Tages sortiert. Welly kennt deine Rhythmen — Morgengewohnheiten erscheinen morgens, Abendgewohnheiten abends.';
      case 'habit_card_explain':
        return 'Der Bogen und das Ziel unter dem Namen aktualisieren sich bei jedem Abschluss. Das Ziel steht klar da: 7 Tage bis zur Gewohnheit, 66 bis zur Automatik — kein Rätselraten.';
      case 'focus_unlocked':
        return 'Du hast den 25-Minuten-Fokus von Anfang an zur Verfügung! Das menschliche Gehirn hat einen natürlichen Konzentrationsrhythmus von etwa 20–30 Minuten — nutze ihn für einen ablenkungsfreien Arbeitsblock.';
      case 'focus_unlocked_2':
        return 'Goldene Regel des Fokus: Wenn der Timer läuft, kommt das Handy mit dem Display nach unten. Sogar Welly schweigt. Die Benachrichtigung, auf die du wartest, kann 25 Minuten warten — versprochen.';
      case 'calendar_appears':
        return 'Neu! Der kontextuelle Kalender zeigt nur die nächsten Stunden, nicht den ganzen Tag. Weniger zu sehen = mehr mentaler Raum zum Handeln. Die ferne Zukunft ist noch nicht dein Problem.';
      case 'growth_first_visit':
        return 'Dieser Bereich zeigt, wer du wirst, nicht nur was du tust. Die Phasen sind keine Belohnungen — sie sind echte Beschreibungen deiner neurologischen Veränderung. Wissenschaft, nicht Motivation, leitet den Weg.';
      case 'phase2_reached':
        return '🌱 Phase 2: Anfang! Ab jetzt verfolgt Wachstum deinen Weg, Phase für Phase. Deine nächste Gewohnheit schaltet sich erst frei, wenn du bereit bist — ohne Eile, ohne Druck: du bestimmst das Tempo, und dir noch etwas mehr Zeit zu lassen ist immer in Ordnung.';
      case 'phase3_reached':
        return '🌿 Phase 3: Wachstum! Drei Gewohnheiten gefestigt. Deine Routine existiert wirklich jetzt — sie ist keine Anstrengung mehr, sie ist eine Struktur. Das Schwerste liegt hinter dir.';
      case 'phase4_reached':
        return '🌳 Phase 4: Wurzeln. Sieben Gewohnheiten verinnerlicht — deine Routine ist zum Lebensstil geworden. Die meisten Menschen kommen nicht hierher. Du hast es durch Beständigkeit erreicht, nicht durch Willenskraft.';
      case 'phase5_reached':
        return '🌸 Aufblühen. Du bist angekommen. Das bedeutet nicht, dass es vorbei ist — es bedeutet, dass du jemand geworden bist, der Gewohnheiten aufbaut. Das ist das wahre Ergebnis.';
      case 'milestone_7_days':
        return '7 aufeinanderfolgende Tage! Die Wissenschaft sagt, dass nach dieser Schwelle 90 % derer, die weitermachen, 21 Tage erreichen werden. Du bist in der Zone, in der Veränderung viel wahrscheinlicher wird.';
      case 'milestone_21_days':
        return '21 Tage! Der alte Mythos besagte, dass 3 Wochen ausreichen, um eine Gewohnheit zu bilden. Die Wahrheit: 21 Tage bilden nur die erste Rille. Jetzt beginnt der Teil, wo sie wirklich deine wird.';
      case 'milestone_66_days':
        return '66 Tage! Das ist die magische Zahl aus der UCL-Studie von Phillippa Lally. Offiziell, laut Wissenschaft, hast du eine Gewohnheit gebildet. Du baust sie nicht — du hast sie.';
      case 'streak_broken':
        return 'Kein Problem. Die Regel ist einfach: nie zwei Tage hintereinander auslassen. Du bist heute schon zurück — die Serie beginnt von jetzt an. Welly zählt die verpassten Tage nicht.';
      case 'no_completion_3days':
        return 'Welly ist noch hier. Kein Urteil. Zurückzukehren ist einfacher als du denkst — sogar ein einziges Glas Wasser zählt. Ein minimaler Akt reaktiviert die Schleife.';
      case 'perfect_week':
        return 'Perfekte Woche! 7 von 7 Abschlüssen. Dein Gehirn empfing 7 aufeinanderfolgende Verstärkungssignale. Aus neurologischer Sicht hat diese Woche dreifach gezählt.';
      case 'rewards_first_visit':
        return 'Abzeichen sind keine falschen Punkte. Jedes Abzeichen entspricht einem echten Verhalten, das du über einen messbaren Zeitraum aufrechterhalten hast. Es sind Momentaufnahmen deines Fortschritts, keine Dekorationen.';
      default:
        return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':
        return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first':
        return 'EFSA: täglicher Wasserbedarf 2,0–2,5 L für Erwachsene unter normalen Bedingungen.';
      case 'first_completion':
        return 'Hebb (1949): "neurons that fire together, wire together" — jede Wiederholung stärkt die Synapse.';
      case 'streak_explain':
        return 'James Clear, Atomic Habits: "Never miss twice" ist die wirksamste Regel zur Aufrechterhaltung einer Gewohnheit.';
      case 'habit_card_explain':
        return 'Phillippa Lally (UCL, 2010): Automatizität beginnt im Durchschnitt zwischen 18 und 66 Tagen, mit dem stärksten Wachstum in den ersten Wochen.';
      case 'focus_unlocked':
        return 'Kleitman (1963): ultradianer Rhythmus von 90 min mit Aufmerksamkeitsspitzen von 20–30 min. Pomodoro-Techniken nutzen diesen Rhythmus.';
      case 'calendar_appears':
        return 'Sweller (1988): Cognitive Load Theory — weniger gleichzeitig sichtbare Informationen = bessere Entscheidungen.';
      case 'growth_first_visit':
        return 'Wood & Neal (2007): Identität verändert sich, wenn Verhaltensweisen automatisch werden. Identity precedes action.';
      case 'phase2_reached':
        return 'Gardner (2012): Automatizität = Ausführung ohne bewusste Absicht. Der erste Automatismus ist immer der schwierigste.';
      case 'phase3_reached':
        return 'Lally et al. (2010): Mit 3 gefestigten Gewohnheiten steigt die langfristige Compliance deutlich gegenüber nur 1.';
      case 'phase4_reached':
        return 'Duhigg (2012): Konsolidierte Routinen erfordern fast null bewusste Überlegung — der präfrontale Kortex delegiert an die Basalganglien.';
      case 'milestone_7_days':
        return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: Die Automatizität nimmt in den ersten Wochen am stärksten zu — frühe Konsequenz ist der stärkste Prädiktor für langfristige Beibehaltung.';
      case 'milestone_21_days':
        return 'Maltz (1960): Die "21 Tage" waren eine chirurgische Beobachtung, keine wissenschaftliche Studie. Lally (2010) schätzt im Durchschnitt 66 Tage.';
      case 'milestone_66_days':
        return 'Lally et al. (2010), UCL: Durchschnitt von 66 Tagen (Bereich 18–254), um Verhaltensautomatizität zu erreichen.';
      case 'no_completion_3days':
        return 'Fogg (2020): Tiny Habits — selbst eine minimale Handlung hält die neuronale Schleife der Gewohnheit am Leben.';
      case 'perfect_week':
        return 'Schultz et al. (1997): Das dopaminerge System reagiert auf die Konsistenz der Verstärkung — aufeinanderfolgende Sequenzen verstärken den Effekt.';
      default:
        return null;
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
  String get wellyIntro =>
      'Be Well es la primera app que te guía paso a paso en la creación de hábitos saludables — y te premia mientras lo haces. No te pido que lo cambies todo en un día. Solo que empieces por una cosa pequeña, conmigo.';
  String get letsGo => 'Empecemos';
  String get wellyNameQuestion => 'Antes que nada: ¿cómo quieres llamarme?';
  String get wellyNameSub =>
      'Mi nombre es Welly, pero puedes darme el nombre que prefieras.';
  String get perfect => 'Perfecto';
  String get firstHabitTitle => 'Primer hábito: el agua.';
  String get firstHabitBody1 =>
      'Con solo un 2% de deshidratación bajan la concentración y el ánimo.';
  String get firstHabitBody2 =>
      'Empezamos aquí: 8 vasos al día. Yo te recordaré cuándo beber, luego añadiremos nuevos hábitos paso a paso.';
  String get drinkFirstGlass => 'Beber el primer vaso ahora';
  String get rewardTitle => 'Perfecto. Uno.';
  String get rewardBody =>
      'Cada vez que completas algo, ganas puntos Be Well. Los acumularás sin pensarlo — y podrás usarlos para descuentos, vouchers, accesorios, funciones premium y mucho más.';
  String get goToHome => 'Ir a tu inicio';
  String get rewardLocked => 'Se desbloquean con puntos';
  @override
  String get previewDiscountTitle => 'Vale de descuento';
  @override
  String get previewDiscountSub => '10% en partners seleccionados';
  @override
  String get previewCoffeeTitle => 'Vale de café';
  @override
  String get previewCoffeeSub => 'Una bebida gratis';
  @override
  String get previewPremiumTitle => 'Premium';
  @override
  String get previewPremiumSub => 'Funciones avanzadas';
  @override
  String get previewSurpriseTitle => 'Sorpresas';
  @override
  String get previewSurpriseSub => 'Y mucho más...';
  String get notifPermTitle => 'Una última cosa.';
  String get notifPermBody =>
      'Para ayudarte a ser constante, Welly te envía unos pocos recordatorios suaves en los momentos adecuados del día. Sin spam, sin presión: tú decides cuántos, cuando quieras, desde los ajustes.';
  String get notifPermAllow => 'Sí, activar notificaciones';
  String get notifPermSkip => 'Ahora no';
  String get waterUndo => 'Deshacer último';
  String get waterCooldown => 'Espera un momento…';
  String get waterContainerBtn => 'Recipiente';

  String get goodMorning => 'Buenos días,';
  @override
  String get goodAfternoon => 'Buenas tardes,';
  @override
  String get goodEvening => 'Buenas noches,';
  String get greetingFallbackName => 'a ti';
  String get phase => 'Fase';
  String get waterToday => 'Agua hoy';
  String get waterGlasses => 'vasos';
  String get waterTrackedInHome => '💧 registrado en Inicio';
  String get waterZero => 'Empieza con el primer vaso.';
  @override
  String get habitsEmptyTitle => 'Un hábito a la vez';
  @override
  String get habitsEmptySubtitle =>
      'El agua es tu punto de partida hoy. El siguiente se desbloquea solo cuando este te resulte automático — sin prisa.';
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
  String get noBadgesYet =>
      'Tus insignias aparecerán aquí a medida que progreses.';
  String get todayCompleted => 'Completado hoy';
  String get phase1 => 'Semilla';
  String get phase2 => 'Brote';
  String get phase3 => 'Joven';
  String get phase4 => 'Maduro';
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
  @override
  String get focusStartSession => 'Empezar sesión';
  String get focusNewSession => 'Nueva sesión';
  String get focusDone => '¡Sesión completada!';
  String get focusRemaining => 'restantes';
  String get focusSessions => 'sesiones';
  String get focusMinutes => 'min enfoque';
  String get focusStreak => 'racha';
  String get focusDeepWork => 'Trabajo profundo';
  String get focusMinRemaining => 'min restantes';
  String get focusBlockOf4 => 'de 4';
  String get focusThenBreak => 'luego una pausa de 5 minutos';
  String get containerSize => 'Tamaño';
  String focusTimerSpoken(int m, int s) => 'Quedan $m minutos $s segundos';
  String waterGlassAnnounce(int n, int t) => 'Vaso $n de $t registrado';
  String habitRingSpoken(int n) => '$n días completados en total';
  String get passwordShow => 'Mostrar contraseña';
  String get passwordHide => 'Ocultar contraseña';
  String get waterAlmost => 'Casi lo logras, un poco más.';
  String get reduceMotion => 'Reducir movimiento';
  String get reduceMotionDesc => 'Calma las animaciones y los elementos en movimiento';
  String get accessibilityHint => 'Estos ajustes valen para toda la app. Be Well también sigue el tamaño de texto y las animaciones de tu móvil.';
  String get leaveSessionTitle => '¿Salir de la sesión?';
  String get leaveSessionBody => 'Si sales ahora, esta sesión no se contará y empezarás desde el principio. ¿Quieres seguir?';
  String get leaveSessionStay => 'Seguir';
  String get leaveSessionLeave => 'Salir igualmente';
  String waterNextGlassIn(String time) => 'Siguiente vaso en $time';
  String get workScheduleStart => 'Inicio';
  String get workScheduleEnd => 'Fin';
  String get workScheduleTime => 'Hora';
  String get workScheduleDays => 'Días de trabajo o estudio';
  String get workScheduleInviteTitle => 'Cuéntame tus días y horarios';
  String get workScheduleInviteBody => 'Ajusto tus recordatorios a cuando trabajas o estudias y los suavizo en tus días libres. Siempre puedes cambiarlo desde Hábitos.';
  String get workScheduleInviteSet => 'Configurar ahora';
  String get workScheduleInviteLater => 'Más tarde';
  String get wdMon => 'Lun';
  String get wdTue => 'Mar';
  String get wdWed => 'Mié';
  String get wdThu => 'Jue';
  String get wdFri => 'Vie';
  String get wdSat => 'Sáb';
  String get wdSun => 'Dom';
  String get notifInviteTitle => 'Los recordatorios están desactivados';
  String get notifInviteBody => 'Pequeños recordatorios en los momentos justos ayudan mucho a convertir acciones en hábitos. Actívalos: cuántos recibir lo decides tú en Ajustes.';
  String get notifInviteAction => 'Activar';
  String get notifInviteLater => 'Ahora no';
  String get notifComebackTitle1 => 'Aquí estoy cuando quieras 🌱';
  String get notifComebackBody1 => 'Han pasado unos días. Un vaso de agua basta para retomarlo, sin prisa.';
  String get notifComebackTitle2 => 'Sin presión';
  String get notifComebackBody2 => 'Hasta un paso pequeño cuenta. Retómalo cuando quieras: tu progreso está a salvo.';
  String get notifComebackTitle3 => 'Welly piensa en ti';
  String get notifComebackBody3 => 'Tus hábitos te esperan exactamente donde los dejaste.';
  String get notifComebackTitle4 => 'Retomar es fácil';
  String get notifComebackBody4 => 'Un vaso de agua y ya has vuelto a empezar.';
  String get resetAllTitle => 'Empezar de cero';
  String get resetAllSubtitle => 'Borra todo el progreso y vuelve a empezar';
  String get resetAllConfirmTitle => '¿Empezar de cero?';
  String get resetAllConfirmBody => 'Borramos tus hábitos, días, racha, puntos y ajustes de este móvil y de tu cuenta en la nube. Volverás a ver la bienvenida como la primera vez. No se puede deshacer.';
  String get resetAllConfirmButton => 'Borrar todo';
  String get notifFocusRunningTitle => '🎯 Foco en curso';
  String get notifFocusRunningBody => 'Una cosa a la vez. Toca para volver al temporizador.';
  String get notifFocusPausedTitle => '⏸ Foco en pausa';
  String get notifFocusPausedBody => 'Con calma: retómalo cuando quieras.';
  String get dayOne => 'día';
  String get wellyMsgMorning => '¡Buenos días! Un vaso de agua y el día empieza con buen pie.';
  String get wellyMsgAfternoon => '¿Sigues ahí? Un sorbo de agua y una pequeña pausa te sentarán bien.';
  String get wellyMsgEvening => 'El día se acaba y está bien así. Si quieres, un último vaso y a descansar.';
  String get wellyMsgAllDone => 'Hoy has hecho todo lo necesario. Disfruta del resto del día.';
  String get wellyMsgWaterDone => 'Agua completada, buen ritmo. Lo demás es un extra.';
  String wellyMsgWaterProgress(int n, int t) => 'Bien: $n de $t vasos. Sin prisa.';

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
  String get notifWaterBody =>
      'El primer vaso de agua es una buena forma de empezar el día.';
  String get notifMiddayTitle => '🧘 Be Well';
  String get notifMiddayBody =>
      'Dos minutos para estirarte o respirar — tu concentración te lo agradecerá después.';
  String get notifLunchTitle => '🍃 Be Well';
  String get notifLunchBody =>
      'Una pausa de verdad ayuda: deja la pantalla unos minutos mientras comes.';
  String get notifAfternoonTitle => '👀 Be Well';
  String get notifAfternoonBody =>
      '¿Ojos cansados de la pantalla? 20 segundos mirando a lo lejos ayudan de verdad.';
  String get notifEveningTitle => 'Be Well 🌙';
  String get notifEveningBody =>
      'Todavía hay tiempo para un último hábito hoy, si te apetece — si no, hasta mañana.';
  String get notifHabitChoiceTitle => '✨ Nuevo hábito disponible';
  String get notifHabitChoiceBody =>
      'Abre Be Well para elegir tu próximo hábito.';

  @override
  String get notifFocusTitle => '🎯 Momento de Focus';
  @override
  String get notifFocusBody =>
      'Cuando quieras: un bloque de concentración, sin prisa.';
  @override
  String get notifBundleTitle => '🌿 Be Well';
  @override
  String notifBundleMorningBody(String list) => 'Para empezar bien: $list.';
  @override
  String notifBundleBreakBody(String list) => 'Una pausa amable: $list.';
  @override
  String notifBundleEveningBody(String list) =>
      'Para cerrar bien el día: $list.';
  @override
  String get notifFocusDoneTitle => '✨ Bloque completado';
  @override
  String notifFocusDoneBody(String list) =>
      'Buen trabajo. Tómate un momento: $list.';
  @override
  String get notifFocusDoneBodyPlain =>
      'Buen trabajo. Tómate un momento para respirar.';
  @override
  String get notifAndWord => 'y';

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
  String get navUnlockHabitsMsg =>
      'Completa 14 días de agua para desbloquear los hábitos.';
  String get navUnlockGrowthMsg =>
      'Crecimiento se abre tras 14 días de constancia con un hábito: ya lo estás construyendo.';
  String get comingSoonHabitsDesc =>
      'Completa 14 días de agua.\nTu primer nuevo hábito se desbloqueará aquí.';
  String get comingSoonGrowthDesc =>
      'Sigue construyendo tus hábitos.\nLa pantalla de crecimiento se desbloqueará pronto.';
  String get achievementUnlocked => '¡Logro desbloqueado!';
  String get newHabitUnlocked => '¡Nuevo hábito desbloqueado!';

  String get rewards => 'Recompensas';
  String get rewardsPoints => 'Puntos Be Well';
  String get rewardsLocked => 'Las recompensas están llegando';
  String get rewardsLockedDesc =>
      'Sigue construyendo hábitos para desbloquear tus recompensas';
  String get rewardsHeader => 'Tus recompensas';
  String get rewardsHeaderSub => 'Recoge lo que has sembrado';

  String get habitWaterName => 'Beber agua';
  String get habitWaterDesc => '8 vasos durante el día';
  String get habitFocus25Name => 'Sesión de enfoque 25 min';
  String get habitFocus25Desc => 'Un Pomodoro sin distracciones';
  String get habitEyes2020Name => 'Regla 20-20-20';
  String get habitEyes2020Desc => 'Cada 20 min, mirar lejos 20 seg';
  String get habitNeckName => 'Estiramiento de cuello';
  String get habitNeckDesc =>
      '2 min de estiramiento de cuello y hombros por hora';
  String get habitBreathingBoxName => 'Respiración en caja';
  String get habitBreathingBoxDesc =>
      '4s inhalar, 4s retener, 4s exhalar, 4s retener';
  String get habitWalkLunchName => 'Paseo del almuerzo';
  String get habitWalkLunchDesc => 'Un paseo de 15 min durante el almuerzo';
  String get habitDeskExName => 'Ejercicios en el escritorio';
  String get habitDeskExDesc => '5 min de estiramientos activos cada 2 horas';
  String get habitWaterMornName => 'Agua al despertar';
  String get habitWaterMornDesc => 'Un vaso de agua nada más levantarse';
  String get habitPostureName => 'Control de postura';
  String get habitPostureDesc => 'Verificar y corregir la postura cada hora';
  String get habitLunchParkName => 'Almuerzo en el parque';
  String get habitLunchParkDesc => 'Comer al aire libre, sin pantallas';
  String get habitBreathing478Name => 'Respiración 4-7-8';
  String get habitBreathing478Desc =>
      'Antiansiedad: inhalar 4s, retener 7s, exhalar 8s';
  String get habitStretchName => 'Estiramiento activo';
  String get habitStretchDesc => '5 minutos de movimiento corporal global';
  String get habitSnackName => 'Snack saludable';
  String get habitSnackDesc => 'Un pequeño snack nutritivo a media mañana';
  String get habitLunchNoScreenName => 'Almuerzo sin pantalla';
  String get habitLunchNoScreenDesc => 'Almorzar sin teléfono ni ordenador';
  String get habitFocus50Name => 'Enfoque profundo 50 min';
  String get habitFocus50Desc =>
      'Una sesión de trabajo profundo sin interrupciones';
  String get habitMeditationName => 'Micro-meditación';
  String get habitMeditationDesc => '3 minutos de presencia consciente';
  String get habitStairsName => 'Escaleras en vez del ascensor';
  String get habitStairsDesc => 'Elegir las escaleras siempre que puedas';
  String get habitSleepName => 'Rutina pre-sueño';
  String get habitSleepDesc => '30 minutos sin pantallas antes de dormir';
  String get habitWakeName => 'Despertar constante';
  String get habitWakeDesc => 'Levantarse a la misma hora cada día';
  String get habitNapName => 'Siesta de 20 min';
  String get habitNapDesc => 'Un breve descanso intencional por la tarde';
  String get habitFocusPhoneName => 'Enfoque sin teléfono';
  String get habitFocusPhoneDesc =>
      'Teléfono boca abajo durante las sesiones de enfoque';
  String get habitMicroWalkName => 'Micro-caminata 5 min';
  String get habitMicroWalkDesc =>
      '5 minutos caminando cada 90 minutos — ciclo ultradiano';
  String get habitDigitalSunsetName => 'Atardecer digital';
  String get habitDigitalSunsetDesc =>
      'Sin redes sociales en la hora antes de dormir';
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
  @override
  String get guideHowShoulderRoll =>
      'Siéntate con la espalda recta y los brazos relajados. Sube los hombros hacia las orejas, llévalos hacia atrás y luego hacia abajo, en un círculo lento. El pecho se abre y el cuello queda suelto.';
  @override
  String get guideHowSpinalTwist =>
      'Siéntate con la espalda recta. Gira el torso hacia la derecha, con la mano izquierda en la rodilla derecha y la derecha en el respaldo. Mira por encima del hombro sin forzar y repite hacia el otro lado.';
  @override
  String get guideHowWrist =>
      'Levanta los antebrazos frente a ti, con los codos apoyados. Mantén las manos sueltas y dibuja círculos lentos con las muñecas, primero en un sentido y luego en el otro.';
  @override
  String get guideHowNeckTilt =>
      'Siéntate recto con los hombros bajos. Inclina la cabeza hacia el hombro derecho, acercando la oreja, sin subir el hombro. Mantén, respira y cambia de lado.';
  @override
  String get guideHowCatCow =>
      'Manos en las rodillas. Al inspirar, arquea la espalda y abre el pecho, con la mirada ligeramente arriba. Al espirar, redondea la espalda y acerca la barbilla al pecho.';
  @override
  String get guideHowNeckRoll =>
      'Siéntate recto con los hombros relajados. Lleva la barbilla al pecho y luego rueda la cabeza despacio en un círculo amplio y suave. Si notas tensión, haz el círculo más pequeño.';
  @override
  String get guideHowShrug =>
      'Con los brazos relajados a los lados, sube ambos hombros hacia las orejas, mantén un instante y déjalos caer. Siente cómo se suelta el cuello.';
  @override
  String get guideHowArmReach =>
      'De pie, con los pies a la anchura de las caderas. Junta las manos y estira los brazos hacia arriba, como para crecer un poco. Mira ligeramente hacia arriba y baja despacio.';
  @override
  String get guideHowSideBend =>
      'De pie, con las piernas abiertas. Levanta un brazo sobre la cabeza e inclina el torso hacia el lado contrario, con la otra mano en la cadera. Cadera quieta, respiración larga y cambia de lado.';
  @override
  String get guideHowHips =>
      'Manos en las caderas, pies separados y rodillas suaves. Dibuja con la pelvis un círculo lento y amplio, mientras el torso queda tranquilo. A mitad, cambia de sentido.';
  @override
  String get guideHowCalf =>
      'De pie, apoyando las manos en una silla para el equilibrio. Sube sobre las puntas de ambos pies, mantén un segundo y baja despacio. Las piernas quedan rectas.';
  @override
  String get guideHowFold =>
      'Pies a la anchura de las caderas, rodillas suaves. Inclínate hacia delante desde las caderas, con la cabeza y los brazos sueltos. No fuerces: quédate donde sientas solo un estiramiento suave y sube despacio.';
  @override
  String get guideSafetyNote =>
      'Muévete despacio y sin forzar: si algo duele, para.';

  @override
  String get guidePhaseMove => 'Muévete';
  @override
  String get guidePhaseRest => 'Descansa';
  @override
  String get guidePhaseRightHold => 'Gira a la derecha, mantén';
  @override
  String get guidePhaseCenter => 'Vuelve al centro';
  @override
  String get guidePhaseLeftHold => 'Gira a la izquierda, mantén';
  @override
  String get guidePhaseClockwise => 'Sentido horario';
  @override
  String get guidePhaseCounterClockwise => 'Sentido antihorario';
  @override
  String get guidePhaseArchCow => 'Arquea la espalda (vaca)';
  @override
  String get guidePhaseRoundCat => 'Redondea la espalda (gato)';
  @override
  String get guidePhaseRaiseHold => 'Sube, mantén';
  @override
  String get guidePhaseLowerRelease => 'Baja y relaja';
  @override
  String get guidePhaseReachHold => 'Estira hacia arriba, mantén';
  @override
  String get guidePhaseLowerSlowly => 'Baja lentamente';
  @override
  String get guidePhaseFoldHold => 'Dobla hacia adelante, mantén';
  @override
  String get guidePhaseRiseSlowly => 'Levántate lentamente';

  String get neverMissTwiceTitle => 'No faltes dos días seguidos.';
  String get neverMissTwiceBody =>
      'Una sola acción cuenta. Incluso un vaso de agua.';
  String get neverMissTwiceCta => '💧 Añadir un vaso de agua';
  String get wellyBonusTitle => '¡Bonus Welly!';
  String get wellyBonusBody => 'Puntos triplicados esta vez 🎉';

  String get coachDay1 => 'Primer día. El más importante.';
  String get coachDay3 => '3 días. Tu cuerpo empieza a registrarlo.';
  String get coachDay7 => '7 días. Estás construyendo algo.';
  String get coachDay14 => '2 semanas. Este hábito es tuyo ahora.';
  String get coachGeneral => 'Cada día cuenta. Incluso los días difíciles.';

  String get badgeFirstStep => 'Primer paso';
  String get badgeFirstStepDesc => 'Primer día completado';
  String get badgeOneWeek => 'Una semana';
  String get badgeOneWeekDesc => '7 días de hábitos';
  String get badgeThreeWeeks => 'Tres semanas';
  String get badgeThreeWeeksDesc => '21 días completados';
  String get badgeSixWeeks => 'Seis semanas';
  String get badgeSixWeeksDesc => '42 días completados';
  String get badgeThreeMonths => 'Tres meses';
  String get badgeThreeMonthsDesc => '90 días de crecimiento';
  String get badgeInSync => 'En sincronía';
  String get badgeInSyncDesc => '2 hábitos activos';
  String get badgeMultihabit => 'Multihábito';
  String get badgeMultihabitDesc => '4 hábitos activos';
  String get badgeHydrated => 'Bien hidratado';
  String get badgeHydratedDesc => 'Agua consolidada';
  String get badgeFocused => 'En foco';
  String get badgeFocusedDesc => 'Focus 25 min consolidado';
  String get badgeWalker => 'Caminante';
  String get badgeWalkerDesc => 'Caminata almuerzo consolidada';
  String get badgeBreath => 'Respiración';
  String get badgeBreathDesc => 'Respiración consolidada';
  String get badgeRootedName => 'Hábitos arraigados';
  String get badgeRootedDesc =>
      'Hábitos que se volvieron una segunda naturaleza';
  String get badgeTierBronze => 'Bronce';
  String get badgeTierSilver => 'Plata';
  String get badgeTierGold => 'Oro';
  String get growthNextGoal => 'Próximo objetivo';
  String growthHabitsToRoot(int n) =>
      n == 1 ? 'Falta 1 hábito' : 'Faltan $n hábitos';

  String get habitChoiceTitle => 'Es hora de agregar\nalgo nuevo.';
  String get habitChoiceSub => 'Elige dónde centrarte ahora.';
  String get habitChoiceShowOther => 'mostrarme otras opciones ›';
  String get habitChoiceNotReady => 'Aún no me siento listo/a';
  String get habitChoiceOpen => 'Elige tu próximo hábito';
  String get habitNotReadySnoozed =>
      'No hay problema — te lo volveré a preguntar dentro de una semana.';
  @override
  String get habitNotReadyMeanwhile => 'Prueba la respiración, mientras tanto';
  @override
  String habitMatchesGoal(String goal) => 'Encaja con: $goal';
  String get consolidatedTitle => '🏆 ¡Felicidades!';
  String consolidatedBody(String habitName) =>
      'Has convertido "$habitName" en un hábito real — tu cerebro ha construido un circuito duradero para él.';
  String get consolidatedBadge => 'Hábito consolidado';
  String get consolidatedCta => 'Continuar';
  @override
  String get consolidatedCtaNext => 'Elige tu próximo hábito →';
  @override
  String get automaticTitle => '💚 ¡Automático!';
  @override
  String automaticBody(String habitName) =>
      'Ya no tienes que pensarlo — "$habitName" ahora la lleva tu cerebro solo. Esta es la meta de verdad.';
  @override
  String get automaticBadge => 'Hábito automático';
  @override
  String get calendarTowardAssimilated => 'Hacia el hábito';
  @override
  String get calendarTowardAutomatic => 'Hacia lo automático';
  @override
  String get calendarMilestoneSoon => 'YA CASI';
  @override
  String calendarMilestoneInDays(int days) => 'EN $days DÍAS';
  @override
  String get calendarAssimilatedTitle => 'Hábito asimilado';
  @override
  String get calendarAssimilatedSub =>
      'Tu cerebro empieza a registrarlo como rutina — el cofre se abre.';
  @override
  String get calendarAutomaticTitle => 'Hábito automático';
  @override
  String get calendarAutomaticSub =>
      'La meta más grande: ya no necesitas pensarlo.';
  @override
  String get calendarLongArcNote =>
      'Ya pasaste la parte más difícil. Cada día desde aquí refuerza el automatismo.';
  @override
  String get calendarDoneTitle => 'Automático — lo lograste';
  @override
  String calendarDoneSub(int points) =>
      'Este hábito ya funciona solo. +$points puntos ganados en el camino.';
  @override
  String get dailyObjectivesTitle => 'Objetivos de hoy';
  @override
  String dailyObjectivesSub(int done, int total) => done >= total && total > 0
      ? 'Todo hecho por hoy'
      : '$done de $total hechos hoy';
  @override
  String get badgeUnlockedTitle => '🏆 ¡Insignia desbloqueada!';
  @override
  String get badgeUnlockedCta => '¡Genial!';
  @override
  String get newMissionLabel => 'Nueva misión';
  @override
  String get missionStartCta => '¡Vamos!';
  @override
  String get missionStreakStart => 'Tu racha empieza justo aquí.';
  @override
  String get missionStreakGoal =>
      '7 días para hacerlo un hábito, 66 para automatizarlo.';
  @override
  String streakMilestoneTitle(int days) => '🔥 ¡$days días seguidos!';
  @override
  String get streakMilestoneBadge => 'Hito de racha';
  String habitStartsTomorrow(String habitName) =>
      '¡Muy bien! Disfruta hoy de tu logro — empezaremos a trabajar en "$habitName" mañana.';
  @override
  String habitChosenIntro(String habitName) =>
      '¡Muy bien! Disfruta hoy de tu logro — "$habitName" empieza mañana. Hazlo una vez, luego mantenlo: en 7 días está asimilado, automático a partir de 66. Verás el objetivo directamente en su tarjeta, paso a paso.';
  String get habitEffortLow => 'fácil';
  String get habitEffortMedium => 'moderado';
  String get habitEffortHigh => 'desafiante';

  String get errorNetwork => 'Sin conexión a internet';
  String get errorGeneral => 'Algo salió mal. Inténtalo de nuevo.';
  String get errorInvalidEmail => 'Dirección de correo no válida';
  String get errorWeakPassword => 'La contraseña es demasiado débil';
  String get errorEmailInUse => 'Este correo ya está en uso';
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos';
  String get errorTooManyAttempts =>
      'Demasiados intentos. Cuenta bloqueada temporalmente';
  String get errorTimeout =>
      'El servidor no responde. Inténtalo de nuevo en breve';
  String get errorCancelled => 'Inicio de sesión cancelado';
  String get errorAccountDisabled =>
      'Cuenta deshabilitada. Contacta con soporte';
  @override
  String get errorRequiresRecentLogin =>
      'Por tu seguridad, vuelve a iniciar sesión antes de eliminar tu cuenta.';
  @override
  String get deleteAccount => 'Eliminar cuenta';
  @override
  String get deleteAccountConfirmTitle => '¿Eliminar tu cuenta?';
  @override
  String get deleteAccountConfirmBody =>
      'Elimina definitivamente tu cuenta y todos tus datos — hábitos, rachas, puntos, insignias. No se puede deshacer.';
  @override
  String get deleteAccountCta => 'Sí, eliminar todo';
  @override
  String get deleteAccountDone => 'Tu cuenta ha sido eliminada.';
  String get passwordStrengthWeak => 'Débil';
  String get passwordStrengthMedium => 'Media';
  String get passwordStrengthStrong => 'Fuerte';
  String get passwordStrengthVeryStrong => 'Muy fuerte';
  String get validationEmailRequired => 'Introduce tu correo';
  String get validationPasswordRequired => 'Introduce una contraseña';
  String get validationPasswordTooShort => 'Mínimo 8 caracteres';
  String get validationNameRequired => 'Introduce tu nombre';
  String get validationNameTooShort => 'Mínimo 2 caracteres';
  String get accountLockedBody =>
      'Demasiados intentos fallidos.\nInténtalo de nuevo en';
  String get accountLockedEmailSent =>
      'Has recibido un correo con las instrucciones.';
  String get offlineLoginRequired =>
      'Sin conexión — el inicio de sesión requiere internet';
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
  String get verifySendError =>
      'No se pudo enviar, inténtalo de nuevo en breve';
  String get welcomeSlide1Title => 'Tu plan de\nbienestar personal';
  String get welcomeSlide1Sub =>
      'Be Well crea un plan a tu medida, basado en tus hábitos y objetivos.';
  @override
  String get welcomeSlide1Footer =>
      'Te unes a quienes ya están construyendo hábitos más sanos, un día a la vez.';
  String get welcomeSlide2Title => 'Recordatorios que\nconocen tu calendario';
  String get welcomeSlide2Sub =>
      'Los recordatorios se adaptan a tus reuniones y horarios, para no interrumpirte nunca en el momento equivocado.';
  String get welcomeSlide3Title => 'Convierte hábitos\nen recompensas reales';
  String get welcomeSlide3Sub =>
      'Gana puntos completando actividades y canjéalos por descuentos, vales y mucho más.';
  String get welcomeSkip => 'Saltar';
  String get welcomeNext => 'Siguiente →';
  String get welcomeStart => 'Empezar configuración →';
  String get welcomeConfigureLater => 'Configurar más tarde';

  String get qProfileTitle => 'Cuéntanos sobre ti';
  String get qProfileSub => 'Nos ayuda a crear el plan adecuado para ti.';
  String get qGoalsTitle => 'Objetivos y estrés';
  String get qGoalsSub =>
      'La pantalla más importante para personalizar tu plan.';
  String get qHealthTitle => 'Tus hábitos';
  String get qHealthSub => 'Calibra la frecuencia y el tipo de recordatorios.';
  String get qScheduleTitle => 'Tu horario';
  String get qScheduleSub =>
      'Configuraremos los recordatorios en los momentos adecuados.';
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
  String get calSyncNote =>
      '✓ Te pediremos permisos después de confirmar el plan';
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
  String get screenTimeWarning =>
      'Activaremos recordatorios de ojos más frecuentes';
  String get crisisTitle => 'Estás pasando por un momento difícil';
  String get crisisBody =>
      'Be Well está aquí para apoyarte. Si necesitas ayuda inmediata: contacta con una línea de ayuda local.';
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
  String get planPreviewSub =>
      'Personalizado según tus respuestas. Podrás modificarlo siempre desde Ajustes.';
  String get planRemindersPerDay => 'recordatorios/día';
  String get planFocusSessions => 'sesiones focus';
  String get planPointsPerDay => 'puntos/día';
  String get planMorning => '🌅 Mañana';
  String get planAfternoon => '☀️ Tarde';
  String get planEvening => '🌙 Noche';
  String planFromTime(String time) => 'desde $time';
  String planConnectCalendar(String name) => 'Conectar $name';
  String get planConnectCalendarSub => 'Pediremos permiso después de confirmar';
  String get planFallbackNote =>
      'Usamos un plan predeterminado. Lo iremos ajustando a medida que uses la app.';
  String get planConfirmCta => 'Empezar con Be Well  ';
  String get planConfirmSub =>
      'Puedes modificar tu plan en cualquier momento desde Ajustes';
  String planMinutes(int n) => '$n min';
  String get profileTitle => 'Perfil';
  String get accountSection => 'Cuenta';
  String get emailAccountLabel => 'Correo de la cuenta';
  String get supportSection => 'Soporte';
  String get editNameTitle => 'Editar nombre';
  String get yourNameHint => 'Tu nombre';
  String get resetTutorialTitle => 'Restablecer tutorial';
  String get resetTutorialBody =>
      'Welly volverá a mostrar todos los diálogos del tutorial como si fuera la primera vez. Útil para probar el flujo.';
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
  String get comingSoonBody =>
      'Esta sección aún no está disponible — está en nuestra hoja de ruta.';
  String get habitMarkDone => 'Hecho';
  @override
  String get habitGoalFirstTime => '🎯 Objetivo: hazlo por primera vez';
  @override
  String habitGoalInProgressToday(int count, int target) =>
      '🎯 $count/$target vasos hoy — complétalos todos para tu primer día completo';
  @override
  String habitGoalBuilding(int days, int target) =>
      '🎯 Objetivo: construye la rutina — $days/$target días';
  @override
  String habitGoalBonus(int days, int target) =>
      '🌳 ¡Hábito asimilado! Objetivo extra: hacerlo automático — $days/$target días';
  @override
  String get habitGoalMastered => '💚 Automático — objetivo alcanzado';
  String get slowdownReasonHeavy => 'Este hábito me pesa demasiado ahora mismo';
  String heatmapDaysAgo(int n) => 'hace $n días';
  String get heatmapToday => 'hoy';
  String phaseStarted(String date) => 'iniciado el $date';
  String phaseReached(String date) => 'alcanzado el $date';
  String get marketAdTitle => 'Ayuda a Be Well';
  String get marketAdSubtitle => 'Gana 10 pt viendo un anuncio';
  @override
  String marketAdRemaining(int n) => 'Quedan $n hoy';
  @override
  String get marketAdCapReached =>
      'Has llegado al límite de hoy — vuelve mañana';
  String get marketAdDialogBody =>
      'Mira un anuncio: nos ayudas a mantener la app gratis y ganas 10 puntos al instante.';
  String get marketWatchNow => 'Ver ahora';
  String get dialogGotIt => 'Entendido';
  String get marketAdUnavailable => 'Anuncio no disponible por ahora';
  String get referralTitle => 'Invita a un amigo';
  String get referralSubtitle => 'Gana 50 pt por cada amigo que se registre';
  String get referralApply => 'Aplicar';
  String get referralApplied =>
      '¡Código aplicado! Tu amigo recibirá el bono pronto. 🎉';
  String get referralErrorInvalid => 'Código no válido';
  String get referralErrorOwn => 'No puedes usar tu propio código';
  String get referralErrorAlready => 'Ya has canjeado un código de invitación';
  String get referralErrorNotSignedIn => 'Debes haber iniciado sesión';
  String get referralErrorGeneric => 'Algo salió mal, inténtalo de nuevo';
  String get referralHint => '¿Tienes un código de invitación?';
  String premiumPrice(String price) => '$price/mes';
  String referralShareButton(String code) => 'Compartir mi código · $code';
  String get referralRetry =>
      'No se pudo generar el código — toca para reintentar';
  String referralShareMessage(String code) =>
      'Estoy usando Be Well para crear hábitos más saludables, día a día 🌱\n'
      '¡Descarga la app y usa mi código de invitación "$code" — recibirás 50 puntos de bono en cuanto empieces!';

  String get waterContainerGlass => 'vaso';
  String get waterContainerBottle => 'botella';
  String get waterContainerSettings => '¿Cómo estás registrando tu agua?';
  String get waterGoalCalc =>
      'Necesitas unos N recipientes para tus 2 litros al día';

  String get habitsMorningTitle => 'Empieza bien el día.';
  String get habitsMiddayTitle => 'En el momento justo.';
  String get habitsAfternoonTitle => 'Buenas tardes.';
  String get habitsEveningTitle => '¿Cómo te fue hoy?';
  String get habitsNowLabel => 'Ahora';
  String get habitsComingSoon => 'Próximamente';
  String get configuratorTitle => 'Personaliza tu plan';
  String get configuratorSubtitle =>
      'Responde algunas preguntas para recibir sugerencias de hábitos hechas a tu medida';
  String get configuratorDoneTitle => 'Tu plan está personalizado';
  String get configuratorDoneSubtitle => 'Toca para actualizar tus respuestas';
  String get habitsAllDone => 'Todo bien por ahora. Welly está contigo.';
  String get habitsToday => 'Tu ritmo hoy';
  String get completedToday => 'completadas hoy';

  String get timeMorning => 'Mañana';
  String get timeMidday => 'Media mañana';
  String get timeLunch => 'Pausa del almuerzo';
  String get timeAfternoon => 'Tarde';
  String get timeEvening => 'Noche';

  String get onboardingUserTypeTitle => '¿Y cómo pasas tus días?';
  String get onboardingStudent => 'Estudio';
  String get onboardingWorker => 'Trabajo';

  String get workScheduleBanner =>
      'He puesto un horario estándar (lun–vie, 9-13 / 14-18). ¿Te va bien?';
  String get workScheduleConfirm => 'Está bien';
  String get workScheduleEdit => 'Editar';
  String get workScheduleTitle => 'Tus horarios de trabajo';
  String get workScheduleMorning => 'Mañana';
  String get workScheduleAfternoon => 'Tarde';
  String get workScheduleLunch => 'Tengo una pausa para el almuerzo fija';
  String get workScheduleSave => 'Guardar';

  String get slowdownPrompt =>
      'He notado que te está costando mantener el ritmo. ¿Quieres que vayamos más despacio?';
  String get slowdownYes => 'Sí, vamos más despacio';
  String get slowdownNo => 'No, sigo adelante';
  String get slowdownHabitMenu => 'Necesito más tiempo con este hábito';
  String get slowdownMenuSubtitle =>
      'Las nuevas sugerencias de hábitos se pausan durante 2 semanas — este se queda en tu plan de todas formas.';
  String get slowdownWellyResponse =>
      'Sin problema — las nuevas sugerencias están en pausa durante 2 semanas. Este hábito se queda en tu plan, tómate el tiempo que necesites.';
  String get speedupPrompt =>
      'Lo estás haciendo muy bien — ¿estás listo para algo nuevo antes de lo previsto?';
  String get speedupYes => 'Sí, estoy listo';
  String get speedupNo => 'No, me quedo aquí';

  String get calendarTitle => 'Las próximas horas';
  String get calendarFocus => 'Focus';
  String get calendarBreak => 'Pausa';
  String get calendarLongBreak => 'Pausa larga';

  String get tutorialOk => '¡Entendido!';
  String get tutorialMore => 'Más →';
  String get tutorialSkip => 'Saltar';
  @override
  String get tutorialShowSource => 'Ver la fuente';
  String get tutorialNext => 'Siguiente →';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get pointsAvailable => 'puntos disponibles';
  String get marketplaceTabRewards => 'Premios';
  String get marketplaceTabDiscounts => 'Descuentos';
  String get marketplaceTabInApp => 'En la app';
  String get rewardsToRedeem => 'para canjear';
  String get rewardRedeemed => 'Ahí está. Te lo ganaste.';
  String get rewardConfirmTitle => '¿Estás seguro?';
  String get rewardConfirmBody => 'Se deducirán X puntos de tu saldo.';
  String get rewardRedeemFailed =>
      'No se pudo canjear esta recompensa — puntos insuficientes, o ya no está disponible.';
  String get copyCode => 'Copiar código';
  String get codeCopied => 'Copiado';
  String get watchAd => 'Ver un anuncio · +10 pt';
  String get whyAds => '¿por qué?';
  String get whyAdsTitle => 'Be Well es gratuito para todos';
  String get whyAdsBody =>
      'Be Well es una aplicación gratuita para ser accesible para todos. Como cualquier servicio, tiene costos operativos. Al ver anuncios cuando puedas, nos ayudas a mantener el servicio activo y mejorarlo para todos. Gracias.';
  String get discountsActive => 'descuentos activos';
  String get discountsNote =>
      'Los descuentos se actualizan mensualmente. No se requieren puntos.';
  String get discountExclusive => 'exclusivo Be Well';
  String get goToSite => 'Ir al sitio';
  String get affiliateNote => 'Este enlace apoya Be Well';
  String get inAppWelly => 'welly';
  String get inAppSoundscape => 'soundscape';
  String get inAppMinigame => 'minijuego';
  String get inAppPercorsi => 'recorridos';
  String get unlockItem => 'Desbloquear';
  String get itemUnlocked => 'Desbloqueado';
  String get premiumAllContent => 'Todo el contenido in-app incluido';
  String get premiumPoints => '+20% puntos en cada hábito';
  String get premiumWelly => 'Welly completamente personalizable';
  String get premiumDiscounts => 'Descuentos exclusivos por adelantado';
  String get premiumTrial => 'Prueba 7 días gratis';
  String get premiumOr => 'o compra individualmente con puntos';

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
      case 'home_welcome':
        return '¡Bienvenido! Soy Welly. Déjame mostrarte todo para que puedas empezar bien.';
      case 'home_water':
        return 'Este es tu primer hábito: beber agua. 8 vasos al día es tu objetivo. Simple y poderoso.';
      case 'home_add_glass':
        return 'Toca aquí cada vez que bebas un vaso. Cada toque construye tu hábito — ¡pruébalo ahora!';
      case 'home_welly':
        return 'Ese soy yo — ¡Welly! Cambio de expresión según tus progresos. Cuanto mejor lo haces, más radiante me vuelvo.';
      case 'home_phase':
        return 'Esta es tu Fase. Empiezas en Semilla — Fase 1. Construye hábitos para crecer hasta la Fase 5: Radiante.';
      case 'home_nav':
        return 'Esta es tu navegación. En Hábitos ya tienes listo el Foco de 25 minutos; Crecimiento se abre tras 14 días de constancia.';
      case 'habits_welcome':
        return 'Desde aquí gestionas todas tus rutinas.';
      case 'habits_now':
        return 'La tarjeta \'Ahora\' muestra el hábito más relevante para este preciso momento de tu día.';
      case 'habits_now_arc':
        return 'Ese número en el centro es cuántos días has completado este hábito en total, no solo hoy. Cero significa que aún no lo has hecho ni una sola vez: hazlo hoy y se convierte en 1. Tócalo cuando quieras para volver a verlo.';
      case 'habits_list':
        return 'Todos los hábitos están ordenados por su mejor momento. Los hábitos matutinos aparecen primero por la mañana — Welly conoce tu ritmo.';
      case 'habits_ready':
        return '¡Listo! Toca \'Completar\' cada día para construir tu racha. Pequeñas acciones, hechas con constancia, cambian todo.';
      case 'habits_progression':
        return 'Tu próximo hábito se desbloquea solo, cuando de verdad hayas hecho tuyos los actuales — no antes. Cada tarjeta muestra exactamente en qué punto estás: primera vez, rutina en construcción, asimilado a los 7 días, automático a los 66. Sin prisa, sin presión: tú marcas el ritmo.';
      // Marketplace tour
      case 'marketplace_welcome':
        return '¡Estos son tus Premios Be Well! Cada vaso de agua, cada hábito completado te trae aquí — donde tus esfuerzos se convierten en recompensas reales.';
      case 'marketplace_points':
        return 'Tu saldo de puntos siempre es visible aquí. Se acumula automáticamente mientras construyes hábitos — sin hacer nada extra.';
      case 'marketplace_tabs':
        return 'Tres pestañas: Premios para canjear con puntos; Descuentos, ofertas exclusivas siempre gratuitas, sin puntos, actualizadas cada mes; y En la app, donde gastas puntos en cosas dentro de Be Well — outfits para Welly, paisajes sonoros, minijuegos, rutas guiadas.';
      case 'marketplace_card':
        return 'Cada premio tiene un costo en puntos. Toca para canjear — recibes un código al instante. Cuanto más constante seas, más desbloqueas.';
      // Growth tour
      case 'growth_welcome':
        return 'Este es tu Crecimiento. No es un ranking — es un espejo. Muestra en quién te estás convirtiendo, no solo lo que haces.';
      case 'growth_phase':
        return 'Tu fase refleja qué tan arraigados están tus hábitos. De la Fase 1 (Semilla) a la Fase 5 (Radiante) — cada paso es un cambio neurológico real.';
      case 'growth_heatmap':
        return 'Este mapa de calor muestra tu consistencia en el tiempo. La ciencia dice que el patrón importa más que la intensidad: unos días perdidos no reinician todo.';
      case 'growth_badges':
        return 'Las insignias no son decoración. Cada una corresponde a un comportamiento mantenido durante un período medible. Son pruebas concretas de tu recorrido.';
      default:
        return '';
    }
  }

  String tutorialText(String id) {
    if (id.startsWith('habit_chosen_')) {
      final hid = id.substring('habit_chosen_'.length);
      return habitChosenIntro(habitName(hid));
    }
    switch (id) {
      case 'home_first_open':
        return '¡Bienvenido! Esta es tu base. En la parte superior siempre encontrarás el hábito más urgente para ahora. Empieza siempre por ahí — el resto puede esperar.';
      case 'home_first_open_2':
        return 'El agua es el primer hábito porque es la base biológica de todo lo demás. Sin hidratación, la concentración cae hasta un 20 % después de solo 90 minutos.';
      case 'water_tracker_first':
        return 'El tracker cuenta los vasos desde que abres la app cada mañana. 8 al día es el objetivo — pero llegar a 5 ya es mejor que ayer.';
      case 'water_goal_intro':
        return 'Tu próximo objetivo: bebe los 8 vasos hoy para tu primer día completo. Repítelo durante 7 días en total y el hábito queda asimilado, a los 66 se vuelve automático. Siempre lo verás escrito en la tarjeta, paso a paso.';
      case 'first_completion':
        return '¡Hecho! Cada completación crea una nueva conexión neuronal. Pequeña, pero real. Tu cerebro acaba de reforzar un circuito.';
      case 'streak_explain':
        return 'Si vuelves mañana, empieza tu racha. La única regla que importa: nunca saltes dos días seguidos. Una pausa es humana. Dos es un nuevo hábito — el equivocado.';
      case 'habits_tab_first':
        return 'Aquí encuentras todos tus hábitos ordenados para el mejor momento de tu día. Welly conoce tus ritmos — los hábitos matutinos aparecen por la mañana, los nocturnos por la noche.';
      case 'habit_card_explain':
        return 'El arco y el objetivo bajo el nombre del hábito se actualizan cada vez que lo completas. La meta está escrita claramente: 7 días para asimilarlo, 66 para hacerlo automático — sin adivinar.';
      case 'focus_unlocked':
        return '¡Has desbloqueado el Foco de 25 minutos! El cerebro humano tiene un ciclo natural de concentración de unos 20–30 minutos. Has ganado esta habilidad construyendo el hábito del agua.';
      case 'focus_unlocked_2':
        return 'Regla de oro del Foco: cuando arranca el temporizador, el teléfono va boca abajo. Incluso Welly se calla. La notificación que esperas puede esperar 25 minutos — te lo prometo.';
      case 'calendar_appears':
        return '¡Nuevo! El calendario contextual muestra solo las próximas horas, no todo el día. Menos que ver = más espacio mental para actuar. El futuro lejano aún no es tu problema.';
      case 'growth_first_visit':
        return 'Esta sección muestra en quién te estás convirtiendo, no solo lo que estás haciendo. Las fases no son premios — son descripciones reales de tu cambio neurológico. La ciencia, no la motivación, guía el camino.';
      case 'phase2_reached':
        return '🌱 Fase 2: ¡Inicio! Desde aquí, Crecimiento sigue tu camino, fase a fase. Tu próximo hábito se desbloquea solo cuando estés listo — sin prisa, sin presión: tú marcas el ritmo, y siempre está bien tomarte un poco más de tiempo.';
      case 'phase3_reached':
        return '🌿 Fase 3: ¡Crecimiento! Tres hábitos consolidados. Tu rutina existe de verdad ahora — ya no es un esfuerzo, es una estructura. Lo más difícil quedó atrás.';
      case 'phase4_reached':
        return '🌳 Fase 4: Raíces. Siete hábitos asimilados — tu rutina se ha convertido en estilo de vida. La mayoría de las personas no llegan aquí. Lo has logrado con constancia, no con fuerza de voluntad.';
      case 'phase5_reached':
        return '🌸 Florecimiento. Has llegado. No significa que termina — significa que te has convertido en alguien que construye hábitos. Ese es el verdadero resultado.';
      case 'milestone_7_days':
        return '¡7 días consecutivos! La ciencia dice que tras este umbral, el 90 % de los que continúan llegarán a 21. Estás en la zona donde el cambio se vuelve mucho más probable.';
      case 'milestone_21_days':
        return '¡21 días! El viejo mito decía que 3 semanas bastan para formar un hábito. La verdad: 21 días solo construyen el surco inicial. Ahora empieza la parte donde se vuelve verdaderamente tuyo.';
      case 'milestone_66_days':
        return '¡66 días! Este es el número mágico del estudio de Phillippa Lally en la UCL. Oficialmente, según la ciencia, has formado un hábito. No lo estás construyendo — lo tienes.';
      case 'streak_broken':
        return 'Ningún problema. La regla es simple: nunca saltes dos días seguidos. Ya has vuelto hoy — la racha empieza de nuevo desde ahora. Welly no cuenta los días que faltaste.';
      case 'no_completion_3days':
        return 'Welly sigue aquí. Sin juicios. Volver es más fácil de lo que crees — incluso un solo vaso de agua cuenta. Un acto mínimo reactiva el bucle.';
      case 'perfect_week':
        return '¡Semana perfecta! 7 de 7 completaciones. Tu cerebro recibió 7 señales de refuerzo consecutivas. Desde el punto de vista neurológico, esta semana contó el triple.';
      case 'rewards_first_visit':
        return 'Las insignias no son puntos falsos. Cada insignia corresponde a un comportamiento real que has mantenido durante un período medible. Son instantáneas de tu progreso, no decoraciones.';
      default:
        return '';
    }
  }

  String? tutorialFact(String id) {
    if (id.startsWith('habit_chosen_')) return null;
    switch (id) {
      case 'home_first_open_2':
        return 'Adan et al. (2012): dehydration reduces cognitive performance significantly after just 90 min.';
      case 'water_tracker_first':
        return 'EFSA: necesidad diaria de agua 2,0–2,5 L para adultos en condiciones normales.';
      case 'first_completion':
        return 'Hebb (1949): "neurons that fire together, wire together" — cada repetición refuerza la sinapsis.';
      case 'streak_explain':
        return 'James Clear, Atomic Habits: "Never miss twice" es la regla más eficaz para mantener un hábito.';
      case 'habit_card_explain':
        return 'Phillippa Lally (UCL, 2010): la automaticidad comienza en promedio entre los 18 y los 66 días, con el mayor crecimiento en las primeras semanas.';
      case 'focus_unlocked':
        return 'Kleitman (1963): ciclos ultradianos de 90 min con picos de atención de 20–30 min. Las técnicas Pomodoro aprovechan este ritmo.';
      case 'calendar_appears':
        return 'Sweller (1988): Cognitive Load Theory — menos información visible simultáneamente = mejores decisiones.';
      case 'growth_first_visit':
        return 'Wood & Neal (2007): la identidad cambia cuando los comportamientos se vuelven automáticos. Identity precedes action.';
      case 'phase2_reached':
        return 'Gardner (2012): automaticidad = ejecución sin intención consciente. El primer automatismo es siempre el más difícil.';
      case 'phase3_reached':
        return 'Lally et al. (2010): con 3 hábitos consolidados, el cumplimiento a largo plazo aumenta significativamente respecto a solo 1.';
      case 'phase4_reached':
        return 'Duhigg (2012): las rutinas consolidadas requieren casi cero deliberación consciente — la corteza prefrontal delega a los ganglios basales.';
      case 'milestone_7_days':
        return 'Gardner, Lally & Wardle (2012), British Journal of General Practice: la automaticidad crece más rápidamente en las primeras semanas — la consistencia inicial es el predictor más fuerte del mantenimiento a largo plazo.';
      case 'milestone_21_days':
        return 'Maltz (1960): los "21 días" eran una observación quirúrgica, no un estudio científico. Lally (2010) estima 66 días en promedio.';
      case 'milestone_66_days':
        return 'Lally et al. (2010), UCL: promedio de 66 días (rango 18–254) para alcanzar la automaticidad conductual.';
      case 'no_completion_3days':
        return 'Fogg (2020): Tiny Habits — incluso una acción mínima mantiene vivo el bucle neuronal del hábito.';
      case 'perfect_week':
        return 'Schultz et al. (1997): el sistema dopaminérgico responde a la consistencia del refuerzo — las secuencias consecutivas amplían el efecto.';
      default:
        return null;
    }
  }
}

// ── Extension utility per nomi e descrizioni abitudini ───────────────────────
extension BwStringsHabitUtils on BwStrings {
  String habitName(String id) {
    switch (id) {
      case 'water':
        return habitWaterName;
      case 'focus_25':
        return habitFocus25Name;
      case 'eyes_20_20_20':
        return habitEyes2020Name;
      case 'neck_stretch':
        return habitNeckName;
      case 'breathing_box':
        return habitBreathingBoxName;
      case 'walk_lunch':
        return habitWalkLunchName;
      case 'desk_exercise':
        return habitDeskExName;
      case 'water_morning':
        return habitWaterMornName;
      case 'posture':
        return habitPostureName;
      case 'lunch_park':
        return habitLunchParkName;
      case 'breathing_478':
        return habitBreathing478Name;
      case 'stretching_active':
        return habitStretchName;
      case 'snack':
        return habitSnackName;
      case 'lunch_no_screen':
        return habitLunchNoScreenName;
      case 'focus_50':
        return habitFocus50Name;
      case 'meditation':
        return habitMeditationName;
      case 'stairs':
        return habitStairsName;
      case 'sleep_routine':
        return habitSleepName;
      case 'wake_consistent':
        return habitWakeName;
      case 'nap':
        return habitNapName;
      case 'focus_no_phone':
        return habitFocusPhoneName;
      case 'micro_walk':
        return habitMicroWalkName;
      case 'digital_sunset':
        return habitDigitalSunsetName;
      default:
        return id;
    }
  }

  String habitDesc(String id) {
    switch (id) {
      case 'water':
        return habitWaterDesc;
      case 'focus_25':
        return habitFocus25Desc;
      case 'eyes_20_20_20':
        return habitEyes2020Desc;
      case 'neck_stretch':
        return habitNeckDesc;
      case 'breathing_box':
        return habitBreathingBoxDesc;
      case 'walk_lunch':
        return habitWalkLunchDesc;
      case 'desk_exercise':
        return habitDeskExDesc;
      case 'water_morning':
        return habitWaterMornDesc;
      case 'posture':
        return habitPostureDesc;
      case 'lunch_park':
        return habitLunchParkDesc;
      case 'breathing_478':
        return habitBreathing478Desc;
      case 'stretching_active':
        return habitStretchDesc;
      case 'snack':
        return habitSnackDesc;
      case 'lunch_no_screen':
        return habitLunchNoScreenDesc;
      case 'focus_50':
        return habitFocus50Desc;
      case 'meditation':
        return habitMeditationDesc;
      case 'stairs':
        return habitStairsDesc;
      case 'sleep_routine':
        return habitSleepDesc;
      case 'wake_consistent':
        return habitWakeDesc;
      case 'nap':
        return habitNapDesc;
      case 'focus_no_phone':
        return habitFocusPhoneDesc;
      case 'micro_walk':
        return habitMicroWalkDesc;
      case 'digital_sunset':
        return habitDigitalSunsetDesc;
      default:
        return coachGeneral;
    }
  }
}

// ── Extension per accesso rapido dal context ──────────────────────────────────
extension LocaleContext on BuildContext {
  BwStrings get s {
    try {
      return Provider.of<LocaleProvider>(this, listen: false).s;
    } catch (_) {
      // Fallback all'ultima lingua nota, non a inglese fisso: un lookup
      // fallito (context ricostruito tra la schedulazione di un
      // postFrameCallback e la sua esecuzione) non deve mai far apparire
      // testo in inglese a un utente che ha scelto italiano.
      return BwStrings.of(LocaleProvider._cachedLocale);
    }
  }

  BwStrings get sL {
    try {
      return Provider.of<LocaleProvider>(this, listen: true).s;
    } catch (_) {
      return BwStrings.of(LocaleProvider._cachedLocale);
    }
  }
}
