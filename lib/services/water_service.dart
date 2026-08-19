import 'package:shared_preferences/shared_preferences.dart';

class WaterService {
  static const String _amountKey = 'water_amount';
  static const String _dateKey = 'water_date';
  static const String _historyKey = 'water_history';

  Future<int> getTodayWater() async {
    final preferences = await SharedPreferences.getInstance();

    final today = _getTodayKey();
    final savedDate = preferences.getString(_dateKey);

    // New day → start from zero.
    if (savedDate != today) {
      await preferences.setString(_dateKey, today);
      await preferences.setInt(_amountKey, 0);

      await _saveTodayToHistory(preferences, today, 0);

      return 0;
    }

    return preferences.getInt(_amountKey) ?? 0;
  }

  Future<int> addWater(int amount) async {
    if (amount <= 0) {
      return getTodayWater();
    }

    final currentAmount = await getTodayWater();

    final newAmount = currentAmount + amount;

    return _saveTodayWater(newAmount);
  }

  Future<int> removeWater(int amount) async {
    if (amount <= 0) {
      return getTodayWater();
    }

    final currentAmount = await getTodayWater();

    final newAmount = currentAmount - amount;

    // Never allow water to become negative.
    final safeAmount = newAmount < 0 ? 0 : newAmount;

    return _saveTodayWater(safeAmount);
  }

  Future<int> setTodayWater(int amount) async {
    final safeAmount = amount < 0 ? 0 : amount;

    return _saveTodayWater(safeAmount);
  }

  Future<int> _saveTodayWater(int amount) async {
    final preferences = await SharedPreferences.getInstance();

    final today = _getTodayKey();

    await preferences.setString(_dateKey, today);

    await preferences.setInt(_amountKey, amount);

    await _saveTodayToHistory(preferences, today, amount);

    return amount;
  }

  Future<void> resetTodayWater() async {
    await setTodayWater(0);
  }

  Future<Map<String, int>> getWaterHistory() async {
    final preferences = await SharedPreferences.getInstance();

    final history = preferences.getStringList(_historyKey) ?? [];

    final result = <String, int>{};

    for (final item in history) {
      final parts = item.split('|');

      if (parts.length != 2) {
        continue;
      }

      final date = parts[0];

      final amount = int.tryParse(parts[1]);

      if (amount == null) {
        continue;
      }

      result[date] = amount;
    }

    return result;
  }

  Future<void> _saveTodayToHistory(
    SharedPreferences preferences,
    String date,
    int amount,
  ) async {
    final history = preferences.getStringList(_historyKey) ?? [];

    final newEntry = '$date|$amount';

    final updatedHistory = <String>[];

    bool updated = false;

    for (final item in history) {
      if (item.startsWith('$date|')) {
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

  String _getTodayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
