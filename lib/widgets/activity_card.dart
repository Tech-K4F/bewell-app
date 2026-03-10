// activity_card.dart
import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../theme/app_theme.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isCompleted;
  final VoidCallback onComplete;
  final bool showCategory;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isCompleted,
    required this.onComplete,
    this.showCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = activity.color;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCompleted ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BwColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? color.withOpacity(.35)
                : BwColors.panelBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(.25)),
              ),
              child: Center(
                child: Text(activity.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? Colors.white.withOpacity(.4)
                          : Colors.white,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white.withOpacity(.3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${activity.durationMinutes} min',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(.3))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BwColors.amberLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('+${activity.points} pt',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: BwColors.amber)),
                      ),
                      if (showCategory) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activity.category.split(' ').first,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isCompleted ? null : onComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color:
                      isCompleted ? BwColors.tealLight : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? BwColors.teal
                        : Colors.white.withOpacity(.15),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check,
                        color: BwColors.teal, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
