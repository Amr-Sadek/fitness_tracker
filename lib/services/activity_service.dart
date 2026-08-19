import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Activity {
  final String id;
  final String type;
  final int duration;
  final int calories;
  final DateTime date;
  final String notes;

  Activity({
    required this.id,
    required this.type,
    required this.duration,
    required this.calories,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'duration': duration,
      'calories': calories,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: json['type'] as String,
      duration: json['duration'] as int,
      calories: json['calories'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ActivityService {
  static const String _activitiesKey = 'activities';

  Future<List<Activity>> getActivities() async {
    final preferences = await SharedPreferences.getInstance();

    final savedActivities = preferences.getStringList(_activitiesKey) ?? [];

    return savedActivities.map((item) {
      final json = jsonDecode(item) as Map<String, dynamic>;

      return Activity.fromJson(json);
    }).toList();
  }

  Future<void> addActivity(Activity activity) async {
    final preferences = await SharedPreferences.getInstance();

    final activities = await getActivities();

    activities.insert(0, activity);

    await _saveActivities(preferences, activities);
  }

  Future<void> updateActivity(Activity updatedActivity) async {
    final preferences = await SharedPreferences.getInstance();

    final activities = await getActivities();

    final index = activities.indexWhere(
      (activity) => activity.id == updatedActivity.id,
    );

    if (index == -1) {
      return;
    }

    activities[index] = updatedActivity;

    await _saveActivities(preferences, activities);
  }

  Future<void> deleteActivity(String id) async {
    final preferences = await SharedPreferences.getInstance();

    final activities = await getActivities();

    activities.removeWhere((activity) => activity.id == id);

    await _saveActivities(preferences, activities);
  }

  Future<void> _saveActivities(
    SharedPreferences preferences,
    List<Activity> activities,
  ) async {
    final data = activities.map((item) {
      return jsonEncode(item.toJson());
    }).toList();

    await preferences.setStringList(_activitiesKey, data);
  }
}
