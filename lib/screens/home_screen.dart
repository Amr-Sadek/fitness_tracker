import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/activity_service.dart';
import '../services/goal_service.dart';
import '../services/health_service.dart';
import '../services/water_service.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthService _healthService = HealthService();
  final WaterService _waterService = WaterService();
  final GoalService _goalService = GoalService();
  final ActivityService _activityService = ActivityService();

  List<Activity> _todayActivities = [];

  final TextEditingController _customWaterController = TextEditingController();

  int _stepsGoal = GoalService.defaultStepsGoal;
  int _waterGoal = GoalService.defaultWaterGoal;

  int _steps = 0;
  int _water = 0;

  String? _profileImagePath;

  bool _isLoadingSteps = true;
  bool _isLoadingWater = true;
  bool _isUpdatingWater = false;

  bool _showCustomWater = false;
  bool _customWaterIsAdding = true;
  String? _customWaterError;

  @override
  void initState() {
    super.initState();

    _loadData();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _customWaterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSteps(),
      _loadWater(),
      _loadGoals(),
      _loadActivities(),
    ]);
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getActivities();

      final now = DateTime.now();

      final todayActivities = activities.where((activity) {
        return activity.date.year == now.year &&
            activity.date.month == now.month &&
            activity.date.day == now.day;
      }).toList();

      if (!mounted) return;

      setState(() {
        _todayActivities = todayActivities;
      });
    } catch (error) {
      debugPrint('Activity loading error: $error');
    }
  }

  Future<void> _loadSteps() async {
    if (mounted) {
      setState(() {
        _isLoadingSteps = true;
      });
    }

    try {
      final steps = await _healthService.initializeAndGetTodaySteps();

      if (!mounted) return;

      setState(() {
        _steps = steps;
        _isLoadingSteps = false;
      });
    } catch (error) {
      debugPrint('Health Connect error: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingSteps = false;
      });
    }
  }

  Future<void> _loadWater() async {
    try {
      final water = await _waterService.getTodayWater();

      if (!mounted) return;

      setState(() {
        _water = water;
        _isLoadingWater = false;
      });
    } catch (error) {
      debugPrint('Water loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingWater = false;
      });
    }
  }

  Future<void> _loadGoals() async {
    try {
      final stepsGoal = await _goalService.getStepsGoal();

      final waterGoal = await _goalService.getWaterGoal();

      if (!mounted) return;

      setState(() {
        _stepsGoal = stepsGoal;
        _waterGoal = waterGoal;
      });
    } catch (error) {
      debugPrint('Goal loading error: $error');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final imagePath = preferences.getString('profile_image');

      String? validPath;

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);

        if (await file.exists()) {
          validPath = imagePath;
        }
      }

      if (!mounted) return;

      setState(() {
        _profileImagePath = validPath;
      });
    } catch (error) {
      debugPrint('Profile image loading error: $error');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _refreshSteps(),
      _loadWater(),
      _loadGoals(),
      _loadProfileImage(),
      _loadActivities(),
    ]);
  }

  Future<void> _refreshSteps() async {
    try {
      final steps = await _healthService.getTodaySteps();

      if (!mounted) return;

      setState(() {
        _steps = steps;
      });
    } catch (error) {
      debugPrint('Health Connect refresh error: $error');
    }
  }

  Future<bool> _addWater(int amount) async {
    if (amount <= 0 || _isUpdatingWater) {
      return false;
    }

    setState(() {
      _isUpdatingWater = true;
    });

    try {
      final newAmount = await _waterService.addWater(amount);

      if (!mounted) return false;

      setState(() {
        _water = newAmount;
      });

      return true;
    } catch (error) {
      debugPrint('Water add error: $error');

      if (!mounted) return false;

      _showWaterError();

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingWater = false;
        });
      }
    }
  }

  Future<bool> _removeWater(int amount) async {
    if (amount <= 0 || _isUpdatingWater) {
      return false;
    }

    setState(() {
      _isUpdatingWater = true;
    });

    try {
      final newAmount = await _waterService.removeWater(amount);

      if (!mounted) return false;

      setState(() {
        _water = newAmount;
      });

      return true;
    } catch (error) {
      debugPrint('Water remove error: $error');

      if (!mounted) return false;

      _showWaterError();

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingWater = false;
        });
      }
    }
  }

  void _openCustomWater({required bool isAdding}) {
    setState(() {
      _customWaterIsAdding = isAdding;
      _showCustomWater = true;
      _customWaterError = null;
      _customWaterController.clear();
    });
  }

  void _closeCustomWater() {
    FocusScope.of(context).unfocus();

    setState(() {
      _showCustomWater = false;
      _customWaterError = null;
      _customWaterController.clear();
    });
  }

  Future<void> _applyCustomWater() async {
    if (_isUpdatingWater) {
      return;
    }

    final text = _customWaterController.text.trim();

    final amount = int.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() {
        _customWaterError = 'Please enter a valid amount.';
      });

      return;
    }

    setState(() {
      _customWaterError = null;
    });

    bool success;

    if (_customWaterIsAdding) {
      success = await _addWater(amount);
    } else {
      success = await _removeWater(amount);
    }

    if (!mounted) return;

    /*
     * Close the custom input ONLY when the operation
     * actually succeeds.
     *
     * If an error happens, keep the input visible so
     * the user can try again.
     */
    if (success) {
      _customWaterController.clear();

      setState(() {
        _showCustomWater = false;
        _customWaterError = null;
      });

      FocusScope.of(context).unfocus();
    }
  }

  void _openActivityLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );

    await _loadProfileImage();
  }

  void _showWaterError() {
    if (!mounted) return;

    setState(() {
      _customWaterError = 'Could not update water intake.';
    });
  }

  double get _stepsProgress {
    if (_stepsGoal <= 0) {
      return 0;
    }

    return (_steps / _stepsGoal).clamp(0.0, 1.0);
  }

  double get _waterProgress {
    if (_waterGoal <= 0) {
      return 0;
    }

    return (_water / _waterGoal).clamp(0.0, 1.0);
  }

  int get _stepsRemaining {
    if (_steps >= _stepsGoal) {
      return 0;
    }

    return _stepsGoal - _steps;
  }

  int get _waterRemaining {
    if (_water >= _waterGoal) {
      return 0;
    }

    return _waterGoal - _water;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 24),

              _buildStepsHero(context, colors),

              const SizedBox(height: 18),

              _buildWaterCard(context, colors),

              const SizedBox(height: 24),

              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildActivitySummary(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Let’s make today a healthy day.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openProfile,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildHomeProfileImage(colors),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeProfileImage(ColorScheme colors) {
    final path = _profileImagePath;

    if (path == null || path.isEmpty) {
      return Icon(
        Icons.person_outline_rounded,
        color: colors.primary,
        size: 25,
      );
    }

    final file = File(path);

    if (!file.existsSync()) {
      return Icon(
        Icons.person_outline_rounded,
        color: colors.primary,
        size: 25,
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person_outline_rounded,
          color: colors.primary,
          size: 25,
        );
      },
    );
  }

  Widget _buildStepsHero(BuildContext context, ColorScheme colors) {
    final completed = _steps >= _stepsGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Today’s Activity',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              if (completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Goal reached',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 142,
                      height: 142,
                      child: CircularProgressIndicator(
                        value: _stepsProgress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_walk_rounded,
                          color: Colors.white,
                          size: 27,
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _isLoadingSteps ? '...' : _formatNumber(_steps),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          'steps',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'Great job! 🎉' : 'Keep moving',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      completed
                          ? 'You reached your daily step goal.'
                          : '${_formatNumber(_stepsRemaining)} steps left to reach your goal.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Goal: ${_formatNumber(_stepsGoal)} steps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(BuildContext context, ColorScheme colors) {
    final theme = Theme.of(context);

    final completed = _water >= _waterGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water Intake',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _isLoadingWater
                            ? 'Loading...'
                            : completed
                            ? 'Daily goal completed'
                            : '${_formatNumber(_waterRemaining)} ml remaining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${(_waterProgress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatNumber(_water)} ml',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  '${_formatNumber(_waterGoal)} ml goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _waterProgress,
                minHeight: 9,
                backgroundColor: Colors.blue.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _waterButton(250, isAdding: true),
                const SizedBox(width: 8),
                _waterButton(500, isAdding: true),
                const SizedBox(width: 8),
                _waterButton(750, isAdding: true),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _waterButton(250, isAdding: false),
                const SizedBox(width: 8),
                _waterButton(500, isAdding: false),
                const SizedBox(width: 8),
                _waterButton(750, isAdding: false),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isUpdatingWater
                        ? null
                        : () {
                            if (_showCustomWater && _customWaterIsAdding) {
                              _closeCustomWater();
                            } else {
                              _openCustomWater(isAdding: true);
                            }
                          },
                    icon: Icon(
                      _showCustomWater && _customWaterIsAdding
                          ? Icons.close
                          : Icons.add_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      _showCustomWater && _customWaterIsAdding
                          ? 'Cancel'
                          : 'Add custom',
                    ),
                  ),
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed: _isUpdatingWater
                        ? null
                        : () {
                            if (_showCustomWater && !_customWaterIsAdding) {
                              _closeCustomWater();
                            } else {
                              _openCustomWater(isAdding: false);
                            }
                          },
                    icon: Icon(
                      _showCustomWater && !_customWaterIsAdding
                          ? Icons.close
                          : Icons.remove_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      _showCustomWater && !_customWaterIsAdding
                          ? 'Cancel'
                          : 'Remove custom',
                    ),
                  ),
                ),
              ],
            ),

            if (_showCustomWater) _buildCustomWaterInput(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomWaterInput(BuildContext context, ColorScheme colors) {
    final isAdding = _customWaterIsAdding;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isAdding ? Colors.blue : Colors.orange).withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdding
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                size: 20,
                color: isAdding ? Colors.blue : Colors.orange,
              ),

              const SizedBox(width: 8),

              Text(
                isAdding ? 'Add custom amount' : 'Remove custom amount',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _customWaterController,
                  enabled: !_isUpdatingWater,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _applyCustomWater();
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    suffixText: 'ml',
                    errorText: _customWaterError,
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.outline.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isUpdatingWater ? null : _applyCustomWater,
                  child: _isUpdatingWater
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isAdding ? 'Add' : 'Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(BuildContext context, ColorScheme colors) {
    final theme = Theme.of(context);

    final activityCount = _todayActivities.length;

    final totalDuration = _todayActivities.fold<int>(
      0,
      (total, activity) => total + activity.duration,
    );

    final totalCalories = _todayActivities.fold<int>(
      0,
      (total, activity) => total + activity.calories,
    );

    final lastActivity = _todayActivities.isNotEmpty
        ? _todayActivities.first
        : null;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.deepOrange,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Activity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activityCount == 0
                            ? 'No activities logged today'
                            : '$activityCount ${activityCount == 1 ? 'activity' : 'activities'} today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'View Activity',
                  onPressed: _openActivityLog,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildActivityStat(
                    context,
                    icon: Icons.timer_outlined,
                    value: '$totalDuration',
                    label: 'Minutes',
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildActivityStat(
                    context,
                    icon: Icons.local_fire_department_outlined,
                    value: '$totalCalories',
                    label: 'Calories',
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildActivityStat(
                    context,
                    icon: Icons.fitness_center_outlined,
                    value: '$activityCount',
                    label: 'Activities',
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),

            // Last activity
            if (lastActivity != null) ...[
              const SizedBox(height: 16),

              Divider(color: colors.outline.withValues(alpha: 0.15)),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Last activity',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    lastActivity.type,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Text(
                    '${lastActivity.duration} min',
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(width: 10),

                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    '${lastActivity.calories} kcal',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 19,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        'Log an activity to start tracking your workout today.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // View all button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openActivityLog,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View Activity Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),

          const SizedBox(height: 6),

          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterButton(int amount, {required bool isAdding}) {
    return Expanded(
      child: OutlinedButton(
        onPressed: _isUpdatingWater
            ? null
            : () {
                if (isAdding) {
                  _addWater(amount);
                } else {
                  _removeWater(amount);
                }
              },
        child: Text(
          isAdding ? '+$amount' : '−$amount',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
