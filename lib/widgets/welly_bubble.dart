// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — WellyBubble
//  Modal tutorial di Welly: centrato a schermo, con scrim scuro.
//  Si comporta come un dialog in primo piano — l'utente lo vede chiaramente
//  e può fare tap fuori per chiuderlo.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/welly_dialog.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';

class WellyBubbleOverlay extends StatefulWidget {
  final WellyDialog dialog;
  final void Function(TutorialAction action) onAction;
  final VoidCallback onDismiss;

  const WellyBubbleOverlay({
    super.key,
    required this.dialog,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<WellyBubbleOverlay> createState() => _WellyBubbleOverlayState();
}

class _WellyBubbleOverlayState extends State<WellyBubbleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scrimFade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Leggero scorrimento verso l'alto — effetto modal, non drawer
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _scrimFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.5, curve: Curves.easeOut)));

    // Scala lieve per l'effetto "pop in" del modal
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();

    // Auto-dismiss se configurato
    if (widget.dialog.autoDismiss != Duration.zero) {
      Future.delayed(widget.dialog.autoDismiss, _handleDismiss);
    }

    // Haptic leggero all'apertura
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Future<void> _handleAction(TutorialAction action) async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final p = theme.paletteData;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          children: [
            // ── Scrim: tap fuori = dismiss ───────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleDismiss,
                child: FadeTransition(
                  opacity: _scrimFade,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.52),
                  ),
                ),
              ),
            ),

            // ── Bubble centrata — vero modal in primo piano ──────────────────
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {}, // blocca propagazione al scrim
                    child: ScaleTransition(
                      scale: _scale,
                      child: SlideTransition(
                        position: _slide,
                        child: FadeTransition(
                          opacity: _fade,
                          child: _BubbleCard(
                            dialog: widget.dialog,
                            p: p,
                            onAction: _handleAction,
                            onDismiss: _handleDismiss,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card interna ──────────────────────────────────────────────────────────────

class _BubbleCard extends StatelessWidget {
  final WellyDialog dialog;
  final BwPaletteData p;
  final void Function(TutorialAction) onAction;
  final VoidCallback onDismiss;

  const _BubbleCard({
    required this.dialog,
    required this.p,
    required this.onAction,
    required this.onDismiss,
  });

  Color get _accentColor {
    switch (dialog.mood) {
      case TutorialMood.celebrating: return p.primary;
      case TutorialMood.excited:     return p.accent;
      default:                        return p.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final isCelebrating = dialog.mood == TutorialMood.celebrating;
    final sL = context.sL;

    // Testo localizzato — fallback al testo italiano nel WellyDialog
    final localizedText = sL.tutorialText(dialog.id);
    final displayText = localizedText.isNotEmpty ? localizedText : dialog.text;
    final localizedFact = sL.tutorialFact(dialog.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: isCelebrating
            ? Color.lerp(p.card, p.primaryLight, 0.4)
            : p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: isCelebrating ? 0.55 : 0.25),
          width: isCelebrating ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isCelebrating ? 0.30 : 0.14),
            blurRadius: isCelebrating ? 36 : 20,
            spreadRadius: isCelebrating ? 4 : 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar Welly + label + chiudi ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Welly — immagine statica del personaggio
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/companion/companion_base.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        dialog.moodEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Label "Welly" + mood badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welly',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    dialog.moodEmoji,
                    style: const TextStyle(fontSize: 11, height: 1.2),
                  ),
                ],
              ),
              const Spacer(),
              // Dismiss X
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: p.textMut),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Testo principale ───────────────────────────────────────────────
          Text(
            displayText,
            style: TextStyle(
              fontSize: 14.5,
              color: p.text,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),

          // ── Fatto scientifico ──────────────────────────────────────────────
          if (localizedFact != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔬', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      localizedFact,
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textSec,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Azioni ────────────────────────────────────────────────────────
          Row(
            children: [
              for (int i = 0; i < dialog.actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: _resolveActionLabel(dialog.actions[i].label, sL),
                    isPrimary: i == 0,
                    p: p,
                    accent: accent,
                    onTap: () => onAction(dialog.actions[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Risolve il tasto di azione dalla chiave ('ok'/'more'/'skip') alla stringa localizzata.
  static String _resolveActionLabel(String key, BwStrings sL) {
    switch (key) {
      case 'ok':   return sL.tutorialOk;
      case 'more': return sL.tutorialMore;
      case 'skip': return sL.tutorialSkip;
      default:     return key;
    }
  }
}

// ── Pulsante azione ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final BwPaletteData p;
  final Color accent;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.p,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? p.btn : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: p.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
              color: isPrimary ? p.btnText : p.textSec,
              letterSpacing: isPrimary ? 0.2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
