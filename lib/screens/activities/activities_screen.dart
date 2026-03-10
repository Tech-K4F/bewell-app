import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_card.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeWellColors.darkPanel,
      appBar: AppBar(title: const Text('Il mio Piano')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final activities = provider.todayPlan;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            itemBuilder: (context, i) {
              final a = activities[i];
              return ActivityCard(
                activity: a,
                isCompleted: provider.completedToday.contains(a.id),
                onComplete: () => provider.completeActivity(a.id),
              );
            },
          );
        },
      ),
    );
  }
}