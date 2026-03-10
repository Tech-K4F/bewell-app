import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Activity {
  final String id;
  final String category;
  final String name;
  final int durationMinutes;
  final String? startTime;
  final String? endTime;
  final String frequency;
  final int? intervalMinutes;
  final String notificationType;
  final String? trigger;
  final String importance;
  final int points;
  final String pointsCategory;
  final String? badgeUnlock;
  final String contentType;
  final String? contentMedia;
  final int difficulty;
  final String? prerequisites;
  final List<String> tags;
  final List<String> aiPersonalizationFactors;
  final bool b2bRelevant;
  final String? inclusivityNotes;

  const Activity({
    required this.id,
    required this.category,
    required this.name,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    required this.frequency,
    this.intervalMinutes,
    required this.notificationType,
    this.trigger,
    required this.importance,
    required this.points,
    required this.pointsCategory,
    this.badgeUnlock,
    required this.contentType,
    this.contentMedia,
    required this.difficulty,
    this.prerequisites,
    required this.tags,
    required this.aiPersonalizationFactors,
    required this.b2bRelevant,
    this.inclusivityNotes,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    int parseDuration(dynamic d) {
      if (d == null) return 5;
      final s = d.toString();
      if (s.toLowerCase() == 'instant' || s.toLowerCase() == 'alert') return 1;
      final match = RegExp(r'\d+').firstMatch(s);
      return match != null ? int.parse(match.group(0)!) : 5;
    }

    return Activity(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      name: json['activity']?.toString() ?? '',
      durationMinutes: parseDuration(json['duration']),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      frequency: json['frequency']?.toString() ?? '',
      intervalMinutes: json['intervalMinutes'] as int?,
      notificationType: json['notificationType']?.toString() ?? 'Soft',
      trigger: json['trigger']?.toString(),
      importance: json['importance']?.toString() ?? 'Optional',
      points: (json['points'] as num?)?.toInt() ?? 0,
      pointsCategory: json['pointsCategory']?.toString() ?? 'base',
      badgeUnlock: json['badgeUnlock']?.toString(),
      contentType: json['contentType']?.toString() ?? 'reminder_text',
      contentMedia: json['contentMedia']?.toString(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      prerequisites: json['prerequisites']?.toString(),
      tags: List<String>.from(json['tags'] ?? []),
      aiPersonalizationFactors:
          List<String>.from(json['aiPersonalizationFactors'] ?? []),
      b2bRelevant: json['b2bRelevant'] as bool? ?? false,
      inclusivityNotes: json['inclusivityNotes']?.toString(),
    );
  }

  String get emoji => BwColors.categoryEmoji(category);
  Color get color => BwColors.categoryColor(category);
  bool get isEssential => importance == 'Essential';
  bool get isTimerBased => contentType == 'timer' || id.startsWith('FOC');
  bool get isBreathing =>
      contentType == 'guided_breathing' || tags.contains('breathing');
}
