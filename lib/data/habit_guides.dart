import '../l10n/app_localizations.dart';

/// Un singolo passo di una sequenza guidata (es. "Rotazione spalle × 5").
class GuideStep {
  final String Function(BwStrings s) label;
  final int seconds;
  const GuideStep(this.label, this.seconds);
}

/// Abitudini che si eseguono come sequenza di passi cronometrati, sul
/// modello della respirazione guidata: l'utente non deve indovinare
/// cosa fare — l'app lo guida passo per passo.
class HabitGuides {
  static const Map<String, List<GuideStep>> _guides = {
    'desk_exercise': [
      GuideStep(_deskStep1, 60),
      GuideStep(_deskStep2, 60),
      GuideStep(_deskStep3, 60),
      GuideStep(_deskStep4, 60),
      GuideStep(_deskStep5, 60),
    ],
    'neck_stretch': [
      GuideStep(_neckStep1, 40),
      GuideStep(_neckStep2, 40),
      GuideStep(_neckStep3, 40),
    ],
    'stretching_active': [
      GuideStep(_stretchStep1, 60),
      GuideStep(_stretchStep2, 60),
      GuideStep(_stretchStep3, 60),
      GuideStep(_stretchStep4, 60),
      GuideStep(_stretchStep5, 60),
    ],
  };

  static List<GuideStep>? forHabit(String habitId) => _guides[habitId];

  static bool hasGuide(String habitId) => _guides.containsKey(habitId);

  static String _deskStep1(BwStrings s) => s.guideDeskStep1;
  static String _deskStep2(BwStrings s) => s.guideDeskStep2;
  static String _deskStep3(BwStrings s) => s.guideDeskStep3;
  static String _deskStep4(BwStrings s) => s.guideDeskStep4;
  static String _deskStep5(BwStrings s) => s.guideDeskStep5;

  static String _neckStep1(BwStrings s) => s.guideNeckStep1;
  static String _neckStep2(BwStrings s) => s.guideNeckStep2;
  static String _neckStep3(BwStrings s) => s.guideNeckStep3;

  static String _stretchStep1(BwStrings s) => s.guideStretchStep1;
  static String _stretchStep2(BwStrings s) => s.guideStretchStep2;
  static String _stretchStep3(BwStrings s) => s.guideStretchStep3;
  static String _stretchStep4(BwStrings s) => s.guideStretchStep4;
  static String _stretchStep5(BwStrings s) => s.guideStretchStep5;
}
