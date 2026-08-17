import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

/// Celebrazione a schermo intero quando un'abitudine viene assimilata
/// (status → consolidated/automatic): il progresso deve sentirsi
/// guadagnato, non un cambio di stato silenzioso in un batch notturno.
class HabitConsolidatedDialog {
  static Future<void> show(BuildContext context, String habitId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _CelebrationDialog(habitId: habitId),
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  final String habitId;
  const _CelebrationDialog({required this.habitId});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final isAmb = context.read<ThemeProvider>().isAmbient;
    final s = context.sL;
    final habitName = s.habitName(widget.habitId);

    return ScaleTransition(
      scale: _scale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.35),
                blurRadius: 48,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    p.primary.withValues(alpha: .5),
                    p.primary.withValues(alpha: .1),
                  ]),
                  boxShadow: [
                    BoxShadow(color: p.primary.withValues(alpha: .4), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
                child: const Center(child: Text('🏆', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 20),
              Text(
                s.consolidatedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isAmb ? 24 : 21,
                  fontWeight: isAmb ? FontWeight.w300 : FontWeight.w800,
                  fontFamily: isAmb ? 'CormorantGaramond' : null,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.consolidatedBody(habitName),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.textSec, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: p.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.consolidatedBadge,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.primaryText),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.btn,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    s.consolidatedCta,
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.btnText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
