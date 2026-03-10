// stat_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color? color;

  const StatChip({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: BwColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BwColors.panelBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color ?? Colors.white)),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: Colors.white.withOpacity(.35))),
          ],
        ),
      ),
    );
  }
}
