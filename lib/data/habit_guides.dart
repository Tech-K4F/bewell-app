import 'package:flutter/painting.dart' show Offset;
import '../l10n/app_localizations.dart';
import '../widgets/guide_pose_image.dart' show GuideArrow;

/// Colore associato a una sotto-fase, sul modello della respirazione
/// guidata: ogni stato del movimento ha un colore leggibile a colpo
/// d'occhio, non solo un numero che scende.
enum GuidePhaseKind { primary, accent, blend }

/// Movimento mostrato dall'animazione durante una fase, pertinente al gesto:
/// un cerchio che si gonfia va bene per respirare, non per ruotare il collo.
/// Le posizioni sono in unità dello spostamento massimo: x positivo a destra,
/// y NEGATIVO verso l'alto.
class GuideMotion {
  final Offset from;
  final Offset to;

  /// 0 = nessuna rotazione, 1 = oraria, -1 = antioraria.
  final int rotation;

  const GuideMotion.slide(this.from, this.to) : rotation = 0;
  const GuideMotion.rotate({bool clockwise = true})
      : from = Offset.zero,
        to = Offset.zero,
        rotation = clockwise ? 1 : -1;

  bool get isCalm => rotation == 0 && from == to;

  /// Respiro lento sul posto (riposo, pause).
  static const calm = GuideMotion.slide(Offset.zero, Offset.zero);
  static const rotateCw = GuideMotion.rotate();
  static const rotateCcw = GuideMotion.rotate(clockwise: false);
  static const rise = GuideMotion.slide(Offset.zero, Offset(0, -1));
  static const lowerToRest = GuideMotion.slide(Offset(0, -1), Offset.zero);
  static const upToDown = GuideMotion.slide(Offset(0, -1), Offset(0, 1));
  static const fold = GuideMotion.slide(Offset.zero, Offset(0, 1));
  static const riseFromFold = GuideMotion.slide(Offset(0, 1), Offset.zero);
  static const toRight = GuideMotion.slide(Offset.zero, Offset(1, 0));
  static const toLeft = GuideMotion.slide(Offset.zero, Offset(-1, 0));
  static const fromRight = GuideMotion.slide(Offset(1, 0), Offset.zero);
  static const fromLeft = GuideMotion.slide(Offset(-1, 0), Offset.zero);
}

/// Una singola sotto-fase cronometrata di un esercizio (es. "Gira a
/// destra, tieni" per 15s). L'utente non deve indovinare i tempi — l'app
/// li detta, fase per fase, invece di mostrare un unico timer con
/// un'etichetta tipo "alza le spalle × 8".
class GuidePhase {
  final String Function(BwStrings s) label;
  final int seconds;
  final GuidePhaseKind kind;
  final GuideMotion motion;
  const GuidePhase(this.label, this.seconds, this.kind,
      {this.motion = GuideMotion.calm});
}

/// Un esercizio della sequenza guidata: un titolo (mostrato nel riepilogo
/// prima di iniziare), le sotto-fasi cronometrate che lo compongono e —
/// per capire COSA fare — l'immagine della posa, le frecce che ne mostrano
/// la direzione e una descrizione a parole. Immagine, frecce e testo si
/// completano: l'immagine mostra la posa, le frecce il movimento, il testo
/// i dettagli (respiro, cosa evitare).
class GuideStep {
  final String Function(BwStrings s) title;
  final List<GuidePhase> phases;
  final String? image;
  final String Function(BwStrings s)? how;
  final List<GuideArrow> arrows;
  const GuideStep(
    this.title,
    this.phases, {
    this.image,
    this.how,
    this.arrows = const [],
  });

  int get totalSeconds => phases.fold(0, (a, p) => a + p.seconds);
}

const _dir = 'assets/images/guides/';

// ── Frecce del movimento (coordinate normalizzate sull'immagine 3:4) ──────────
const _arrowsShoulderRolls = [
  GuideArrow.arc(Offset(0.26, 0.30), 0.08, 0.07, 45, -270),
];
const _arrowsSpinalTwist = [
  GuideArrow.curve(Offset(0.62, 0.16), Offset(0.35, 0.06), Offset(0.14, 0.24)),
];
const _arrowsWrists = [
  GuideArrow.arc(Offset(0.26, 0.35), 0.10, 0.08, 180, 300),
  GuideArrow.arc(Offset(0.73, 0.34), 0.10, 0.08, 0, -300),
];
const _arrowsNeckTilt = [
  GuideArrow.curve(Offset(0.45, 0.09), Offset(0.62, 0.04), Offset(0.74, 0.20)),
];
const _arrowsCatCow = [
  GuideArrow.curve(Offset(0.14, 0.30), Offset(0.10, 0.18), Offset(0.20, 0.09)),
  GuideArrow.curve(Offset(0.70, 0.36), Offset(0.80, 0.30), Offset(0.82, 0.20)),
];
const _arrowsNeckRoll = [
  GuideArrow.arc(Offset(0.50, 0.30), 0.17, 0.13, 200, 250),
];
const _arrowsShrug = [
  GuideArrow.curve(Offset(0.27, 0.46), Offset(0.27, 0.40), Offset(0.27, 0.33)),
  GuideArrow.curve(Offset(0.73, 0.46), Offset(0.73, 0.40), Offset(0.73, 0.33)),
];
const _arrowsArmReach = [
  GuideArrow.curve(Offset(0.34, 0.30), Offset(0.31, 0.18), Offset(0.36, 0.06)),
  GuideArrow.curve(Offset(0.66, 0.30), Offset(0.69, 0.18), Offset(0.64, 0.06)),
];
const _arrowsSideBend = [
  GuideArrow.curve(Offset(0.68, 0.46), Offset(0.68, 0.24), Offset(0.50, 0.10)),
];
const _arrowsHips = [
  GuideArrow.arc(Offset(0.50, 0.43), 0.26, 0.055, 200, 320),
];
const _arrowsCalf = [
  GuideArrow.curve(Offset(0.33, 0.93), Offset(0.33, 0.87), Offset(0.33, 0.80)),
  GuideArrow.curve(Offset(0.62, 0.93), Offset(0.62, 0.87), Offset(0.62, 0.80)),
];
const _arrowsFold = [
  GuideArrow.curve(Offset(0.35, 0.10), Offset(0.70, 0.10), Offset(0.86, 0.30)),
];

/// Abitudini che si eseguono come sequenza di esercizi cronometrati, sul
/// modello della respirazione guidata: l'utente non deve indovinare
/// cosa fare — l'app lo guida fase per fase, dettando i tempi di ogni
/// sotto-movimento (alza/tieni/abbassa, destra/centro/sinistra, ecc.).
class HabitGuides {
  static const Map<String, List<GuideStep>> _guides = {
    'desk_exercise': [
      GuideStep(
        _deskStep1,
        [
          GuidePhase(_move, 30, GuidePhaseKind.primary,
              motion: GuideMotion.rotateCw),
          GuidePhase(_rest, 10, GuidePhaseKind.blend),
        ],
        image: '${_dir}shoulder_rolls.jpg',
        how: _howShoulderRoll,
        arrows: _arrowsShoulderRolls,
      ),
      GuideStep(
        _deskStep2,
        [
          GuidePhase(_rightHold, 15, GuidePhaseKind.primary,
              motion: GuideMotion.toRight),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromRight),
          GuidePhase(_leftHold, 15, GuidePhaseKind.accent,
              motion: GuideMotion.toLeft),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromLeft),
        ],
        image: '${_dir}spinal_twist.jpg',
        how: _howSpinalTwist,
        arrows: _arrowsSpinalTwist,
      ),
      GuideStep(
        _deskStep3,
        [
          GuidePhase(_clockwise, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rotateCw),
          GuidePhase(_counterClockwise, 20, GuidePhaseKind.accent,
              motion: GuideMotion.rotateCcw),
        ],
        image: '${_dir}wrist_circles.jpg',
        how: _howWrist,
        arrows: _arrowsWrists,
      ),
      GuideStep(
        _deskStep4,
        [
          GuidePhase(_rightHold, 15, GuidePhaseKind.primary,
              motion: GuideMotion.toRight),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromRight),
          GuidePhase(_leftHold, 15, GuidePhaseKind.accent,
              motion: GuideMotion.toLeft),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromLeft),
        ],
        image: '${_dir}neck_tilt.jpg',
        how: _howNeckTilt,
        arrows: _arrowsNeckTilt,
      ),
      GuideStep(
        _deskStep5,
        [
          GuidePhase(_archCow, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rise),
          GuidePhase(_roundCat, 20, GuidePhaseKind.accent,
              motion: GuideMotion.upToDown),
        ],
        image: '${_dir}cat_cow.jpg',
        how: _howCatCow,
        arrows: _arrowsCatCow,
      ),
    ],
    'neck_stretch': [
      GuideStep(
        _neckStep1,
        [
          GuidePhase(_clockwise, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rotateCw),
          GuidePhase(_counterClockwise, 20, GuidePhaseKind.accent,
              motion: GuideMotion.rotateCcw),
        ],
        image: '${_dir}neck_roll.jpg',
        how: _howNeckRoll,
        arrows: _arrowsNeckRoll,
      ),
      GuideStep(
        _neckStep2,
        [
          GuidePhase(_raiseHold, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rise),
          GuidePhase(_lowerRelease, 15, GuidePhaseKind.accent,
              motion: GuideMotion.lowerToRest),
        ],
        image: '${_dir}shoulder_shrug.jpg',
        how: _howShrug,
        arrows: _arrowsShrug,
      ),
      GuideStep(
        _neckStep3,
        [
          GuidePhase(_rightHold, 15, GuidePhaseKind.primary,
              motion: GuideMotion.toRight),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromRight),
          GuidePhase(_leftHold, 15, GuidePhaseKind.accent,
              motion: GuideMotion.toLeft),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromLeft),
        ],
        image: '${_dir}neck_tilt.jpg',
        how: _howNeckTilt,
        arrows: _arrowsNeckTilt,
      ),
    ],
    'stretching_active': [
      GuideStep(
        _stretchStep1,
        [
          GuidePhase(_reachHold, 25, GuidePhaseKind.primary,
              motion: GuideMotion.rise),
          GuidePhase(_lowerSlowly, 15, GuidePhaseKind.accent,
              motion: GuideMotion.lowerToRest),
        ],
        image: '${_dir}arm_reach.jpg',
        how: _howArmReach,
        arrows: _arrowsArmReach,
      ),
      GuideStep(
        _stretchStep2,
        [
          GuidePhase(_rightHold, 15, GuidePhaseKind.primary,
              motion: GuideMotion.toRight),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromRight),
          GuidePhase(_leftHold, 15, GuidePhaseKind.accent,
              motion: GuideMotion.toLeft),
          GuidePhase(_center, 5, GuidePhaseKind.blend,
              motion: GuideMotion.fromLeft),
        ],
        image: '${_dir}side_bend.jpg',
        how: _howSideBend,
        arrows: _arrowsSideBend,
      ),
      GuideStep(
        _stretchStep3,
        [
          GuidePhase(_clockwise, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rotateCw),
          GuidePhase(_counterClockwise, 20, GuidePhaseKind.accent,
              motion: GuideMotion.rotateCcw),
        ],
        image: '${_dir}hip_circles.jpg',
        how: _howHips,
        arrows: _arrowsHips,
      ),
      GuideStep(
        _stretchStep4,
        [
          GuidePhase(_raiseHold, 20, GuidePhaseKind.primary,
              motion: GuideMotion.rise),
          GuidePhase(_lowerRelease, 20, GuidePhaseKind.accent,
              motion: GuideMotion.lowerToRest),
        ],
        image: '${_dir}calf_raises.jpg',
        how: _howCalf,
        arrows: _arrowsCalf,
      ),
      GuideStep(
        _stretchStep5,
        [
          GuidePhase(_foldHold, 20, GuidePhaseKind.primary,
              motion: GuideMotion.fold),
          GuidePhase(_riseSlowly, 10, GuidePhaseKind.accent,
              motion: GuideMotion.riseFromFold),
        ],
        image: '${_dir}forward_fold.jpg',
        how: _howFold,
        arrows: _arrowsFold,
      ),
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

  static String _howShoulderRoll(BwStrings s) => s.guideHowShoulderRoll;
  static String _howSpinalTwist(BwStrings s) => s.guideHowSpinalTwist;
  static String _howWrist(BwStrings s) => s.guideHowWrist;
  static String _howNeckTilt(BwStrings s) => s.guideHowNeckTilt;
  static String _howCatCow(BwStrings s) => s.guideHowCatCow;
  static String _howNeckRoll(BwStrings s) => s.guideHowNeckRoll;
  static String _howShrug(BwStrings s) => s.guideHowShrug;
  static String _howArmReach(BwStrings s) => s.guideHowArmReach;
  static String _howSideBend(BwStrings s) => s.guideHowSideBend;
  static String _howHips(BwStrings s) => s.guideHowHips;
  static String _howCalf(BwStrings s) => s.guideHowCalf;
  static String _howFold(BwStrings s) => s.guideHowFold;

  static String _move(BwStrings s) => s.guidePhaseMove;
  static String _rest(BwStrings s) => s.guidePhaseRest;
  static String _rightHold(BwStrings s) => s.guidePhaseRightHold;
  static String _center(BwStrings s) => s.guidePhaseCenter;
  static String _leftHold(BwStrings s) => s.guidePhaseLeftHold;
  static String _clockwise(BwStrings s) => s.guidePhaseClockwise;
  static String _counterClockwise(BwStrings s) => s.guidePhaseCounterClockwise;
  static String _archCow(BwStrings s) => s.guidePhaseArchCow;
  static String _roundCat(BwStrings s) => s.guidePhaseRoundCat;
  static String _raiseHold(BwStrings s) => s.guidePhaseRaiseHold;
  static String _lowerRelease(BwStrings s) => s.guidePhaseLowerRelease;
  static String _reachHold(BwStrings s) => s.guidePhaseReachHold;
  static String _lowerSlowly(BwStrings s) => s.guidePhaseLowerSlowly;
  static String _foldHold(BwStrings s) => s.guidePhaseFoldHold;
  static String _riseSlowly(BwStrings s) => s.guidePhaseRiseSlowly;
}
