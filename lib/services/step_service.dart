import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepService {
  static const String _baselineKey = 'steps_baseline';
  static const String _dateKey = 'steps_baseline_date';
  static const String _todayStepsKey = 'today_steps';

  StreamSubscription<StepCount>? _stepSubscription;

  final StreamController<int> _stepsController =
      StreamController<int>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;

  int? _baselineSteps;
  int _todaySteps = 0;

  Future<void> startTracking() async {
    final permissionStatus = await Permission.activityRecognition.request();

    if (!permissionStatus.isGranted) {
      _stepsController.addError(
        'Activity recognition permission was not granted.',
      );
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    final today = _getTodayKey();
    final savedDate = preferences.getString(_dateKey);

    if (savedDate == today) {
      _baselineSteps = preferences.getInt(_baselineKey);
      _todaySteps = preferences.getInt(_todayStepsKey) ?? 0;

      // Show the saved value immediately.
      _stepsController.add(_todaySteps);
    } else {
      _baselineSteps = null;
      _todaySteps = 0;

      await preferences.setString(_dateKey, today);
      await preferences.remove(_baselineKey);
      await preferences.remove(_todayStepsKey);

      _stepsController.add(0);
    }

    await _subscribeToStepStream();
  }

  Future<void> refresh() async {
    await _subscribeToStepStream();
  }

  Future<void> _subscribeToStepStream() async {
    await _stepSubscription?.cancel();

    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final totalSteps = event.steps;

    if (_baselineSteps == null) {
      _baselineSteps = totalSteps;

      final preferences = await SharedPreferences.getInstance();

      await preferences.setInt(_baselineKey, totalSteps);
      await preferences.setString(_dateKey, _getTodayKey());

      _todaySteps = 0;

      await preferences.setInt(_todayStepsKey, 0);

      _stepsController.add(0);
      return;
    }

    final calculatedSteps = totalSteps - _baselineSteps!;

    if (calculatedSteps < 0) {
      _baselineSteps = totalSteps;
      _todaySteps = 0;

      final preferences = await SharedPreferences.getInstance();

      await preferences.setInt(_baselineKey, totalSteps);
      await preferences.setInt(_todayStepsKey, 0);

      _stepsController.add(0);
      return;
    }

    _todaySteps = calculatedSteps;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(_todayStepsKey, _todaySteps);

    _stepsController.add(_todaySteps);
  }

  void _onStepCountError(Object error) {
    _stepsController.addError(error);
  }

  String _getTodayKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get currentSteps => _todaySteps;

  void dispose() {
    _stepSubscription?.cancel();
    _stepsController.close();
  }
}
