import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthService {
  final Health _health = Health();

  static const List<HealthDataType> _types = [HealthDataType.STEPS];

  static const List<HealthDataAccess> _permissions = [HealthDataAccess.READ];

  static const String _historyKey = 'steps_history';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _health.configure();

      _isInitialized = true;
    } catch (error) {
      debugPrint('Health initialization error: $error');

      rethrow;
    }
  }

  Future<bool> hasPermissions() async {
    await initialize();

    try {
      final activityPermission = await Permission.activityRecognition.status;

      if (!activityPermission.isGranted) {
        return false;
      }

      final healthPermission =
          await _health.hasPermissions(_types, permissions: _permissions) ??
          false;

      return healthPermission;
    } catch (error) {
      debugPrint('Health permission check error: $error');

      return false;
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();

    try {
      final activityPermission = await Permission.activityRecognition.request();

      if (!activityPermission.isGranted) {
        debugPrint('Activity recognition permission denied.');

        return false;
      }

      final alreadyGranted =
          await _health.hasPermissions(_types, permissions: _permissions) ??
          false;

      if (alreadyGranted) {
        return true;
      }

      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );

      debugPrint('Health authorization result: $authorized');

      return authorized;
    } catch (error) {
      debugPrint('Health permission request error: $error');

      return false;
    }
  }

  Future<bool> isHealthAvailable() async {
    await initialize();

    try {
      final status = await _health.getHealthConnectSdkStatus();

      debugPrint('Health Connect status: $status');

      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (error) {
      debugPrint('Health Connect availability error: $error');

      return false;
    }
  }

  Future<int> initializeAndGetTodaySteps() async {
    await initialize();

    final authorized = await requestPermissions();

    if (!authorized) {
      return 0;
    }

    return getTodaySteps();
  }

  Future<int> getTodaySteps() async {
    await initialize();

    final authorized = await hasPermissions();

    if (!authorized) {
      debugPrint('Cannot read steps: permission not granted.');

      return 0;
    }

    final now = DateTime.now();

    final midnight = DateTime(now.year, now.month, now.day);

    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now);

      final totalSteps = steps ?? 0;

      await saveTodaySteps(totalSteps);

      return totalSteps;
    } catch (error) {
      debugPrint('Health Connect steps error: $error');

      return 0;
    }
  }

  Future<void> saveTodaySteps(int steps) async {
    final preferences = await SharedPreferences.getInstance();

    final history = preferences.getStringList(_historyKey) ?? [];

    final today = _getTodayKey();

    final newEntry = '$today|$steps';

    final updatedHistory = <String>[];

    bool updated = false;

    for (final item in history) {
      if (item.startsWith('$today|')) {
        updatedHistory.add(newEntry);

        updated = true;
      } else {
        updatedHistory.add(item);
      }
    }

    if (!updated) {
      updatedHistory.add(newEntry);
    }

    await preferences.setStringList(_historyKey, updatedHistory);
  }

  Future<Map<String, int>> getStepsHistory() async {
    final preferences = await SharedPreferences.getInstance();

    final history = preferences.getStringList(_historyKey) ?? [];

    final result = <String, int>{};

    for (final item in history) {
      final parts = item.split('|');

      if (parts.length != 2) {
        continue;
      }

      final date = parts[0];

      final steps = int.tryParse(parts[1]);

      if (steps == null) {
        continue;
      }

      result[date] = steps;
    }

    return result;
  }

  Future<void> installHealthConnect() async {
    await initialize();

    await _health.installHealthConnect();
  }

  String _getTodayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
