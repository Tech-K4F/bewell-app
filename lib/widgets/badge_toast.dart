import 'package:flutter/material.dart';
import '../models/badge_model.dart' as bw;
import '../theme/app_theme.dart';

class BadgeToast {
  static void show(BuildContext context, String badgeId) {
    final badge =
        bw.allBadges.where((b) => b.id == badgeId).firstOrNull;
    if (badge == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _BadgeToastWidget(
        badge: badge,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _BadgeToastWidget extends StatefulWidget {
  final bw.BwBadge badge;
  final VoidCallback onDismiss;
  const _BadgeToastWidget({required this.badge, required this.onDismiss});

  @override
  State<_BadgeToastWidget> createState() => _BadgeToastWidgetState();
}

class _BadgeToastWidgetState extends State<_BadgeToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(
            begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _ctrl.reverse().then((_) => widget.onDismiss());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BwColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: BwColors.amber.withOpacity(.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(widget.badge.emoji,
                        style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎉 Badge sbloccato!',
                              style: TextStyle(
                                  color: BwColors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                          Text(widget.badge.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(widget.badge.description,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
