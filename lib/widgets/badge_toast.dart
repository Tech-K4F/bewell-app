import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_model.dart' as bw;
import '../providers/theme_provider.dart';

/// Banner non invasivo che scende dall'alto per notificare achievement/sblocchi.
/// Usa i colori del tema corrente.
class BwBanner {
  static void showBadge(BuildContext context, String badgeId) {
    final badge = bw.allBadges.where((b) => b.id == badgeId).firstOrNull;
    if (badge == null) return;
    _show(
      context,
      emoji: badge.emoji,
      label: context.sL.achievementUnlocked,
      title: badge.name,
      subtitle: badge.description,
      isHabitUnlock: false,
    );
  }

  static void showHabitUnlock(BuildContext context, {
    required String emoji,
    required String habitName,
    required String coachIntro,
  }) {
    _show(
      context,
      emoji: emoji,
      label: context.sL.newHabitUnlocked,
      title: habitName,
      subtitle: coachIntro,
      isHabitUnlock: true,
    );
  }

  static void _show(
    BuildContext context, {
    required String emoji,
    required String label,
    required String title,
    required String subtitle,
    required bool isHabitUnlock,
  }) {
    final overlay = Overlay.of(context);
    final p = context.read<ThemeProvider>().paletteData;
    final isAmb = context.read<ThemeProvider>().isAmbient;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _BwBannerWidget(
        emoji: emoji,
        label: label,
        title: title,
        subtitle: subtitle,
        p: p,
        isAmb: isAmb,
        isHabitUnlock: isHabitUnlock,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

// ── Widget banner ─────────────────────────────────────────────────────────────
class _BwBannerWidget extends StatefulWidget {
  final String emoji;
  final String label;
  final String title;
  final String subtitle;
  final BwPaletteData p;
  final bool isAmb;
  final bool isHabitUnlock;
  final VoidCallback onDismiss;

  const _BwBannerWidget({
    required this.emoji,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.p,
    required this.isAmb,
    required this.isHabitUnlock,
    required this.onDismiss,
  });

  @override
  State<_BwBannerWidget> createState() => _BwBannerWidgetState();
}

class _BwBannerWidgetState extends State<_BwBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isHabitUnlock ? 460 : 380),
    );

    _slide = Tween<Offset>(begin: const Offset(0, -1.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Habit unlock: spring "pop" da 0.82. Badge: scala neutra.
    _scale = widget.isHabitUnlock
        ? Tween<double>(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
          )
        : Tween<double>(begin: 1.0, end: 1.0).animate(_ctrl);

    _ctrl.forward();
    _timer = Timer(
      Duration(seconds: widget.isHabitUnlock ? 5 : 4),
      _dismiss,
    );
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    final p = widget.p;
    final isUnlock = widget.isHabitUnlock;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUnlock
                        ? Color.lerp(p.card, p.primaryLight, 0.35)
                        : p.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: p.primary.withValues(alpha: isUnlock ? 0.55 : 0.35),
                      width: isUnlock ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.primary.withValues(alpha: isUnlock ? 0.32 : 0.18),
                        blurRadius: isUnlock ? 32 : 20,
                        spreadRadius: isUnlock ? 3 : 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Emoji container — circolare con glow per habit unlock
                      Container(
                        width: isUnlock ? 56 : 52,
                        height: isUnlock ? 56 : 52,
                        decoration: BoxDecoration(
                          color: p.primaryLight,
                          borderRadius: BorderRadius.circular(isUnlock ? 28 : 14),
                          boxShadow: isUnlock
                              ? [
                                  BoxShadow(
                                    color: p.primary.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            widget.emoji,
                            style: TextStyle(fontSize: isUnlock ? 28 : 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: p.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: widget.isAmb ? 16 : (isUnlock ? 15 : 14),
                                fontWeight: widget.isAmb
                                    ? FontWeight.w300
                                    : FontWeight.w700,
                                fontFamily: widget.isAmb ? 'CormorantGaramond' : null,
                                color: p.text,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSec,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, size: 14, color: p.textMut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Alias retrocompatibile — usa BwBanner.showBadge()
class BadgeToast {
  static void show(BuildContext context, String badgeId) =>
      BwBanner.showBadge(context, badgeId);
}
