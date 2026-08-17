// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — SpotlightOverlay
//  Sistema tutorial unico: Welly che parla (avatar + testo + azioni) su
//  sfondo scurito con "faro" animato sul widget target, quando presente.
//  Copre sia i tour guidati multi-step (prima visita di una schermata) sia
//  i dialoghi contestuali a evento singolo (streak, sblocchi, milestone…).
//
//  Uso — tour guidato:
//    1. Registra SpotlightController nel MultiProvider di main.dart.
//    2. Avvolgi la radice di HomeShell con SpotlightOverlay.
//    3. Avvolgi i widget da illuminare con SpotlightTarget(id: '...').
//    4. Da initState, chiama ctrl.startTutorial('id', steps).
//
//  Uso — dialogo contestuale: vedi TutorialProvider, che costruisce gli step
//  con testo/fact/azioni già risolti e li passa allo stesso controller.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

// ── Forma del faro ────────────────────────────────────────────────────────────
enum SpotlightShape { circle, roundedRect }

// ── Singola azione nel footer della bolla ─────────────────────────────────────
class SpotlightAction {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const SpotlightAction({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
}

// ── Singolo step del tutorial ─────────────────────────────────────────────────
class SpotlightStep {
  /// ID per il testo localizzato via sL.spotlightText(id) — usato dai tour
  /// guidati statici. Alternativa a [text] (uno dei due è richiesto).
  final String? textId;

  /// Testo già risolto/localizzato — usato dai dialoghi contestuali di Welly.
  final String? text;

  /// Fatto scientifico opzionale, già localizzato.
  final String? fact;

  /// Emoji umore mostrata accanto al nome "Welly" (solo dialoghi contestuali).
  final String? moodEmoji;

  /// ID del widget SpotlightTarget da illuminare.
  /// null = overlay pieno senza foro, bolla centrata (dialoghi contestuali
  /// e step intro/outro dei tour).
  final String? targetId;

  /// Padding extra aggiunto intorno al rettangolo del target.
  final double padding;

  /// Forma del faro (rettangolo arrotondato o cerchio).
  final SpotlightShape shape;

  /// Stile speciale per le celebrazioni (bordo/glow dorato sulla card).
  final bool celebrating;

  /// Azioni custom (dialoghi contestuali, 1-2 pulsanti). Se null, viene
  /// mostrato il footer di default dei tour guidati: Avanti/Ho capito con
  /// indicatori di step (la chiusura rapida resta sempre disponibile
  /// tramite la X in alto, che sostituisce lo "Skip" separato).
  final List<SpotlightAction>? actions;

  /// Chiamato quando l'utente chiude con la X in alto. Se null, chiude
  /// semplicemente il tutorial (controller.skip()) — usato dai tour guidati.
  /// I dialoghi contestuali passano una callback che aggiorna anche la loro
  /// persistenza "già visto" prima di chiudere l'overlay.
  final VoidCallback? onClose;

  /// Se impostato, il "buco" del faro sul target diventa realmente
  /// cliccabile: il tap esegue [onTargetTap] (l'azione vera, es. aggiungere
  /// un bicchiere d'acqua) e poi avanza automaticamente al passo successivo.
  /// Serve per gli step "prova ora" — senza questo l'utente doveva capire
  /// da solo che il pulsante sotto il faro non faceva nulla e usare invece
  /// "Avanti", tutt'altro che intuitivo.
  final VoidCallback? onTargetTap;

  const SpotlightStep({
    this.textId,
    this.text,
    this.fact,
    this.moodEmoji,
    this.targetId,
    this.padding = 16.0,
    this.shape = SpotlightShape.roundedRect,
    this.celebrating = false,
    this.actions,
    this.onClose,
    this.onTargetTap,
  }) : assert(textId != null || text != null,
            'SpotlightStep richiede textId oppure text');
}

// ── SpotlightController ───────────────────────────────────────────────────────
class SpotlightController extends ChangeNotifier {
  final Map<String, BuildContext> _targets = {};

  List<SpotlightStep> _steps = [];
  int _index = 0;
  bool _isActive = false;
  String _tutorialId = '';
  bool _persistOnFinish = true;

  /// Nome scelto dall'utente per il companion in onboarding — salvato ma
  /// mai davvero usato: la bolla del tutorial diceva sempre "Welly" a
  /// prescindere. Caricato una volta (vedi [loadCompanionName]).
  String companionName = 'Welly';

  Future<void> loadCompanionName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('welly_name');
    if (saved != null && saved.trim().isNotEmpty) {
      companionName = saved;
      notifyListeners();
    }
  }

  bool get isActive => _isActive;
  int get currentIndex => _index;
  int get totalSteps => _steps.length;
  bool get isLastStep => _index >= _steps.length - 1;

  SpotlightStep? get currentStep =>
      _isActive && _index < _steps.length ? _steps[_index] : null;

  // ── Registrazione target ──────────────────────────────────────────────────

  void registerTarget(String id, BuildContext ctx) => _targets[id] = ctx;

  /// Restituisce il Rect in coordinate globali del target con [id].
  /// null se il target non è registrato o non è visibile.
  Rect? targetRect(String? id) {
    if (id == null) return null;
    final ctx = _targets[id];
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    try {
      final pos = box.localToGlobal(Offset.zero);
      final rect = pos & box.size;
      // Ignora rect fuori schermo (widget scrollato via)
      if (rect.top < -box.size.height || rect.top > 4000) return null;
      return rect;
    } catch (_) {
      return null;
    }
  }

  // ── Persistenza (solo tour guidati statici) ────────────────────────────────

  Future<bool> hasSeenTutorial(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('spotlight_$id') ?? false;
  }

  Future<void> _markSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spotlight_$id', true);
  }

  Future<void> debugReset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotlight_$id');
  }

  // ── Avvio / navigazione ───────────────────────────────────────────────────

  /// Avvia (o sostituisce, se già attivo — usato per le catene di dialoghi
  /// contestuali) il tutorial [id] con gli [steps] forniti.
  /// [persist] = false per i dialoghi contestuali, la cui persistenza "già
  /// visto" è gestita da TutorialProvider con una propria chiave — evita
  /// una doppia fonte di verità sullo stesso concetto.
  void startTutorial(String id, List<SpotlightStep> steps, {bool persist = true}) {
    _tutorialId = id;
    _steps = steps;
    _index = 0;
    _isActive = true;
    _persistOnFinish = persist;
    notifyListeners();
  }

  void next() {
    if (!_isActive) return;
    if (!isLastStep) {
      _index++;
      notifyListeners();
    } else {
      _finish();
    }
  }

  void skip() => _finish();

  void _finish() {
    _isActive = false;
    if (_persistOnFinish) _markSeen(_tutorialId);
    notifyListeners();
  }
}

// ── SpotlightTarget ───────────────────────────────────────────────────────────
/// Wrapper leggero: registra il proprio BuildContext nello SpotlightController
/// ad ogni build. Nessuna modifica visiva al widget figlio.
class SpotlightTarget extends StatelessWidget {
  final String id;
  final Widget child;

  const SpotlightTarget({
    required this.id,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          context.read<SpotlightController>().registerTarget(id, context);
        } catch (_) {}
      }
    });
    return child;
  }
}

// ── SpotlightOverlay ──────────────────────────────────────────────────────────
/// Avvolge l'app (tipicamente in HomeShell) e mostra l'overlay tutorial
/// quando SpotlightController.isActive == true.
class SpotlightOverlay extends StatefulWidget {
  final Widget child;
  const SpotlightOverlay({required this.child, super.key});

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  // Usato per gestire il fade-out dopo la fine del tutorial
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotlightController>(
      builder: (context, ctrl, _) {
        // Fade in all'attivazione, fade out alla fine
        if (ctrl.isActive && !_wasActive) {
          _wasActive = true;
          _fadeCtrl.forward();
        } else if (!ctrl.isActive && _wasActive) {
          _fadeCtrl.reverse().then((_) {
            if (mounted) setState(() => _wasActive = false);
          });
        }

        final bool showLayer = ctrl.isActive || _fadeCtrl.value > 0;
        final step = ctrl.currentStep;

        return Stack(
          children: [
            widget.child,
            if (showLayer)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnim, _pulseAnim]),
                  builder: (ctx, _) {
                    if (_fadeCtrl.value == 0) return const SizedBox.shrink();

                    final Rect? targetRaw = step != null
                        ? ctrl.targetRect(step.targetId)
                        : null;
                    final Rect? targetRect = targetRaw?.inflate(step!.padding);
                    final shape =
                        step?.shape ?? SpotlightShape.roundedRect;

                    return Stack(
                      children: [
                        // 1. Overlay scuro + buco spotlight (se c'è un target)
                        CustomPaint(
                          painter: _SpotlightPainter(
                            spotlightRect: targetRect,
                            overlayOpacity: _fadeAnim.value,
                            pulseValue: _pulseAnim.value,
                            shape: shape,
                          ),
                          size: MediaQuery.of(ctx).size,
                        ),
                        // 1b. Hotspot cliccabile sul buco, se lo step lo richiede:
                        // il faro è già visivamente sopra il pulsante reale, questo
                        // lo rende anche funzionalmente il pulsante reale.
                        if (step?.onTargetTap != null && targetRect != null)
                          Positioned.fromRect(
                            rect: targetRect,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                step!.onTargetTap!();
                                ctrl.next();
                              },
                            ),
                          ),
                        // 2. Bolla Welly con testo e navigazione
                        if (step != null && _fadeAnim.value > 0.15)
                          _SpotlightBubble(
                            step: step,
                            controller: ctrl,
                            targetRect: targetRect,
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────
/// Disegna l'overlay scuro con:
///  • un buco trasparente sul target (BlendMode.clear su saveLayer)
///  • un bordo luminoso fisso attorno al buco
///  • un anello pulsante (effetto videogame "coach mark")
/// Se non c'è un target (dialoghi contestuali senza widget da indicare),
/// disegna solo l'overlay scuro pieno.
class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final double overlayOpacity;
  final double pulseValue;
  final SpotlightShape shape;

  const _SpotlightPainter({
    required this.spotlightRect,
    required this.overlayOpacity,
    required this.pulseValue,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.80 * overlayOpacity);

    if (spotlightRect == null) {
      // Dialogo contestuale / step intro-outro: overlay pieno senza buco
      canvas.drawRect(fullRect, overlayPaint);
      return;
    }

    // Salva layer per il trucco del blend-mode clear
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, overlayPaint);

    // Buco trasparente sul target
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    _drawShape(canvas, spotlightRect!, clearPaint);
    canvas.restore();

    // Bordo luminoso fisso (indica chiaramente il target)
    _drawShapeBorder(
      canvas,
      spotlightRect!.inflate(2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.60 * overlayOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Anello pulsante (effetto videogame)
    final pulseExpand = 4.0 + 12.0 * pulseValue;
    _drawShapeBorder(
      canvas,
      spotlightRect!.inflate(pulseExpand),
      Paint()
        ..color = Colors.white
            .withValues(alpha: (0.45 - 0.45 * pulseValue) * overlayOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawShape(Canvas canvas, Rect rect, Paint paint) {
    if (shape == SpotlightShape.circle) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        paint,
      );
    }
  }

  void _drawShapeBorder(Canvas canvas, Rect rect, Paint paint) {
    if (shape == SpotlightShape.circle) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlightRect != spotlightRect ||
      old.overlayOpacity != overlayOpacity ||
      old.pulseValue != pulseValue;
}

// ── SpotlightBubble ───────────────────────────────────────────────────────────
/// Bolla con Welly + testo + fatto opzionale + navigazione.
/// Con target: si posiziona sopra o sotto di esso.
/// Senza target: centrata verticalmente, come un vero modal.
class _SpotlightBubble extends StatelessWidget {
  final SpotlightStep step;
  final SpotlightController controller;
  final Rect? targetRect;

  const _SpotlightBubble({
    required this.step,
    required this.controller,
    required this.targetRect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final p = theme.paletteData;
    final isAmb = theme.isAmbient;
    final s = context.sL;
    final size = MediaQuery.of(context).size;

    final displayText = step.text ?? s.spotlightText(step.textId!);

    final card = _BubbleCard(
      text: displayText,
      fact: step.fact,
      moodEmoji: step.moodEmoji,
      celebrating: step.celebrating,
      p: p,
      isAmb: isAmb,
      s: s,
      controller: controller,
      actions: step.actions,
      onClose: step.onClose,
    );

    // ── Senza target: bolla centrata come un modal ────────────────────────
    if (targetRect == null) {
      return Positioned.fill(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: card,
          ),
        ),
      );
    }

    // ── Con target: sopra o sotto, in base allo spazio disponibile ────────
    const double estimatedBubbleHeight = 220.0;
    const double gap = 20.0;
    const double hPad = 20.0;

    double? top;
    double? bottom;

    final spaceBelow = size.height - targetRect!.bottom;
    final spaceAbove = targetRect!.top;
    if (spaceBelow >= estimatedBubbleHeight + gap) {
      top = targetRect!.bottom + gap;
    } else if (spaceAbove >= estimatedBubbleHeight + gap) {
      bottom = size.height - targetRect!.top + gap;
    } else {
      top = (targetRect!.bottom + gap)
          .clamp(0.0, size.height - estimatedBubbleHeight - 8);
    }

    final positioned = Container(
      margin: const EdgeInsets.symmetric(horizontal: hPad),
      child: card,
    );

    if (top != null) {
      return Positioned(top: top, left: 0, right: 0, child: positioned);
    } else {
      return Positioned(bottom: bottom!, left: 0, right: 0, child: positioned);
    }
  }
}

// ── BubbleCard ────────────────────────────────────────────────────────────────
/// Il corpo visivo della bolla: avatar Welly, testo, fatto opzionale,
/// footer di navigazione (default per i tour) o azioni custom (dialoghi).
class _BubbleCard extends StatelessWidget {
  final String text;
  final String? fact;
  final String? moodEmoji;
  final bool celebrating;
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  final SpotlightController controller;
  final List<SpotlightAction>? actions;
  final VoidCallback? onClose;

  const _BubbleCard({
    required this.text,
    required this.fact,
    required this.moodEmoji,
    required this.celebrating,
    required this.p,
    required this.isAmb,
    required this.s,
    required this.controller,
    required this.actions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = p.primary;

    return Container(
      decoration: BoxDecoration(
        color: celebrating ? Color.lerp(p.bg, p.primaryLight, 0.4) : p.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: celebrating ? accent.withValues(alpha: 0.55) : p.cardBorder,
          width: celebrating ? 1.5 : 1,
        ),
        boxShadow: [
          if (celebrating)
            BoxShadow(
              color: accent.withValues(alpha: 0.30),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + nome + mood + chiudi ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/companion/companion_base.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(moodEmoji ?? '🌿', style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        controller.companionName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: isAmb ? 'CormorantGaramond' : null,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (moodEmoji != null) ...[
                        const SizedBox(width: 6),
                        Text(moodEmoji!, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose ?? controller.skip,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: p.textMut),
                  ),
                ),
              ],
            ),
          ),

          // ── Testo principale ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isAmb ? 15.5 : 14.5,
                fontFamily: isAmb ? 'CormorantGaramond' : null,
                color: p.text,
                height: 1.55,
              ),
            ),
          ),

          // ── Fatto scientifico ────────────────────────────────────────────────
          if (fact != null && fact!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.accent.withValues(alpha: 0.15), width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔬', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fact!,
                        style: TextStyle(fontSize: 11, color: p.textSec, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Footer: step dots (solo tour) + azioni ──────────────────────────
          if (actions == null && controller.totalSteps > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(controller.totalSteps, (i) {
                  final isActive = i == controller.currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? p.primary : p.textMut.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: actions != null
                ? Row(
                    children: [
                      for (int i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: actions![i].label,
                            isPrimary: actions![i].isPrimary,
                            p: p,
                            accent: accent,
                            isAmb: isAmb,
                            onTap: actions![i].onTap,
                          ),
                        ),
                      ],
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: _ActionButton(
                      label: controller.isLastStep ? s.tutorialOk : s.tutorialNext,
                      isPrimary: true,
                      p: p,
                      accent: accent,
                      isAmb: isAmb,
                      onTap: controller.next,
                      compact: true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsante azione ───────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final BwPaletteData p;
  final Color accent;
  final bool isAmb;
  final bool compact;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.p,
    required this.accent,
    required this.isAmb,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 22) : null,
        decoration: BoxDecoration(
          color: isPrimary ? p.btn : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: p.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
              color: isPrimary ? p.btnText : p.textSec,
              letterSpacing: isPrimary ? 0.2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
