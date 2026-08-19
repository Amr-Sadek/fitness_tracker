import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  static const String _stepsGoalKey = 'steps_goal';
  static const String _waterGoalKey = 'water_goal';

  static const int defaultStepsGoal = 10000;
  static const int defaultWaterGoal = 2500;

  Future<int> getStepsGoal() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getInt(_stepsGoalKey) ?? defaultStepsGoal;
  }

  Future<int> getWaterGoal() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getInt(_waterGoalKey) ?? defaultWaterGoal;
  }

  Future<void> setStepsGoal(int goal) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(_stepsGoalKey, goal);
  }

  Future<void> setWaterGoal(int goal) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(_waterGoalKey, goal);
  }
}
