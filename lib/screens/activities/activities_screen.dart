import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/activity_card.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: era BeWellColors.darkPanel → corretto in context.read<ThemeProvider>().paletteData.bg
      backgroundColor: context.read<ThemeProvider>().paletteData.bg,
      appBar: AppBar(title: Text('Il mio Piano')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final activities = provider.todayPlan;
          return ListView.builder(
            padding: EdgeInsets.all(20),
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



