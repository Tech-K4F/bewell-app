import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

/// Chiede conferma prima di uscire da una sessione in corso (Focus, respiro,
/// sequenze guidate): con il tasto indietro o il gesto di sistema si perderebbe
/// tutto senza accorgersene. Se [active] è falso si esce normalmente.
class LeaveSessionGuard extends StatelessWidget {
  final bool active;
  final Widget child;
  const LeaveSessionGuard(
      {super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(context);
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }

  static Future<bool?> _confirm(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text(s.leaveSessionTitle,
            style: TextStyle(color: p.text, fontSize: 17)),
        content: Text(s.leaveSessionBody,
            style: TextStyle(color: p.textSec, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(s.leaveSessionLeave, style: TextStyle(color: p.textSec)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: FilledButton.styleFrom(backgroundColor: p.primary),
            child: Text(s.leaveSessionStay),
          ),
        ],
      ),
    );
  }
}
