import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/goal_service.dart';
import '../services/health_service.dart';
import '../services/water_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final HealthService _healthService = HealthService();
  final WaterService _waterService = WaterService();
  final GoalService _goalService = GoalService();

  Map<String, int> _stepsHistory = {};
  Map<String, int> _waterHistory = {};

  int _stepsGoal = GoalService.defaultStepsGoal;
  int _waterGoal = GoalService.defaultWaterGoal;

  int _todaySteps = 0;
  int _todayWater = 0;

  bool _isLoading = true;

  Timer? _tooltipTimer;

  String? _activeTooltipChart;
  int? _activeTooltipIndex;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      /*
       * IMPORTANT:
       * Get today's values directly from the same services
       * used by HomeScreen.
       *
       * This makes Progress and Home show exactly the same
       * current numbers.
       */
      final todayStepsFuture = _healthService.getTodaySteps();

      final todayWaterFuture = _waterService.getTodayWater();

      final goalsFuture = Future.wait([
        _goalService.getStepsGoal(),
        _goalService.getWaterGoal(),
      ]);

      final todaySteps = await todayStepsFuture;
      final todayWater = await todayWaterFuture;

      final goals = await goalsFuture;

      /*
       * Read history AFTER getting today's values.
       *
       * Both HealthService and WaterService save today's
       * current value to history when they update it.
       */
      final stepsHistory = await _healthService.getStepsHistory();

      final waterHistory = await _waterService.getWaterHistory();

      /*
       * Make absolutely sure today's history entry matches
       * the current value shown on Home.
       */
      final todayKey = _dateKey(DateTime.now());

      stepsHistory[todayKey] = todaySteps;
      waterHistory[todayKey] = todayWater;

      if (!mounted) return;

      setState(() {
        _todaySteps = todaySteps;
        _todayWater = todayWater;

        _stepsHistory = stepsHistory;
        _waterHistory = waterHistory;

        _stepsGoal = goals[0];
        _waterGoal = goals[1];

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Progress loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTooltip(String chartId, int index) {
    _tooltipTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _activeTooltipChart = chartId;
      _activeTooltipIndex = index;
    });

    _tooltipTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _activeTooltipChart = null;
        _activeTooltipIndex = null;
      });
    });
  }

  List<DateTime> _lastSevenDays() {
    final today = DateTime.now();

    return List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index)),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  List<int> _getStepsValues() {
    final days = _lastSevenDays();

    return days.map((day) {
      return _stepsHistory[_dateKey(day)] ?? 0;
    }).toList();
  }

  List<int> _getWaterValues() {
    final days = _lastSevenDays();

    return days.map((day) {
      return _waterHistory[_dateKey(day)] ?? 0;
    }).toList();
  }

  int _completedDays(List<int> values, int goal) {
    if (goal <= 0) return 0;

    return values.where((value) => value >= goal).length;
  }

  double _average(List<int> values) {
    if (values.isEmpty) return 0;

    final total = values.fold<int>(0, (sum, value) => sum + value);

    return total / values.length;
  }

  Map<String, double> _getChartScale({
    required List<int> values,
    required int goal,
    required String unit,
  }) {
    final highestValue = values.fold<int>(goal, (maximum, value) {
      return value > maximum ? value : maximum;
    });

    if (highestValue <= 0) {
      if (unit == 'steps') {
        return {'max': 2500, 'interval': 500};
      }

      return {'max': 500, 'interval': 100};
    }

    double interval;

    if (unit == 'steps') {
      if (highestValue <= 2500) {
        interval = 500;
      } else if (highestValue <= 5000) {
        interval = 1000;
      } else if (highestValue <= 10000) {
        interval = 2000;
      } else if (highestValue <= 25000) {
        interval = 5000;
      } else if (highestValue <= 50000) {
        interval = 10000;
      } else {
        interval = 20000;
      }
    } else {
      if (highestValue <= 500) {
        interval = 100;
      } else if (highestValue <= 1000) {
        interval = 250;
      } else if (highestValue <= 2500) {
        interval = 500;
      } else if (highestValue <= 5000) {
        interval = 1000;
      } else if (highestValue <= 10000) {
        interval = 1000;
      } else if (highestValue <= 20000) {
        interval = 2000;
      } else {
        interval = 5000;
      }
    }

    final maxY = (highestValue / interval).ceil() * interval;

    final paddedMax = maxY + interval;

    return {'max': paddedMax.toDouble(), 'interval': interval};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final stepsValues = _getStepsValues();

    final waterValues = _getWaterValues();

    final days = _lastSevenDays();

    /*
     * Use the exact current values loaded
     * from the services instead of depending
     * on the history list for today's numbers.
     */
    final todaySteps = _todaySteps;
    final todayWater = _todayWater;

    final stepsCompletedDays = _completedDays(stepsValues, _stepsGoal);

    final waterCompletedDays = _completedDays(waterValues, _waterGoal);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'See how you are doing this week.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              _buildOverviewCard(context, todaySteps, todayWater, colors),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      icon: Icons.directions_walk_rounded,
                      title: 'Step Goal',
                      value: '$stepsCompletedDays/7',
                      subtitle: 'days completed',
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildMiniStat(
                      context,
                      icon: Icons.water_drop_rounded,
                      title: 'Water Goal',
                      value: '$waterCompletedDays/7',
                      subtitle: 'days completed',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildChartCard(
                context,
                chartId: 'steps',
                title: 'Steps',
                subtitle: 'Your daily movement this week',
                icon: Icons.directions_walk_rounded,
                color: colors.primary,
                values: stepsValues,
                goal: _stepsGoal,
                days: days,
                unit: 'steps',
              ),

              const SizedBox(height: 20),

              _buildChartCard(
                context,
                chartId: 'water',
                title: 'Water',
                subtitle: 'Your daily hydration this week',
                icon: Icons.water_drop_rounded,
                color: Colors.blue,
                values: waterValues,
                goal: _waterGoal,
                days: days,
                unit: 'ml',
              ),

              const SizedBox(height: 20),

              _buildWeeklyAverage(context, stepsValues, waterValues, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    int todaySteps,
    int todayWater,
    ColorScheme colors,
  ) {
    final theme = Theme.of(context);

    final stepsProgress = _stepsGoal > 0
        ? (todaySteps / _stepsGoal).clamp(0.0, 1.0)
        : 0.0;

    final waterProgress = _waterGoal > 0
        ? (todayWater / _waterGoal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Overview",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildOverviewMetric(
                    context,
                    icon: Icons.directions_walk_rounded,
                    title: 'Steps',
                    value: _formatNumber(todaySteps),
                    progress: stepsProgress,
                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: _buildOverviewMetric(
                    context,
                    icon: Icons.water_drop_rounded,
                    title: 'Water',
                    value: '${_formatNumber(todayWater)}ml',
                    progress: waterProgress,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetric(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String chartId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<int> values,
    required int goal,
    required List<DateTime> days,
    required String unit,
  }) {
    final theme = Theme.of(context);

    final scale = _getChartScale(values: values, goal: goal, unit: unit);

    final chartMax = scale['max']!;

    final chartInterval = scale['interval']!;

    final spots = List.generate(values.length, (index) {
      return FlSpot(index.toDouble(), values[index].toDouble());
    });

    final chartBar = LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: 3,
      color: color,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final isSelected =
              _activeTooltipChart == chartId && _activeTooltipIndex == index;

          return FlDotCirclePainter(
            radius: isSelected ? 6 : 4,
            color: color,
            strokeWidth: isSelected ? 3 : 2,
            strokeColor: theme.colorScheme.surface,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.01),
          ],
        ),
      ),
    );

    final showingTooltip =
        _activeTooltipChart == chartId && _activeTooltipIndex != null
        ? [
            ShowingTooltipIndicators([
              LineBarSpot(chartBar, 0, spots[_activeTooltipIndex!]),
            ]),
          ]
        : <ShowingTooltipIndicators>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMax,
                  showingTooltipIndicators: showingTooltip,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchSpotThreshold: 60,
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response != null &&
                          response.lineBarSpots != null &&
                          response.lineBarSpots!.isNotEmpty) {
                        final index = response.lineBarSpots!.first.x.round();

                        if (index >= 0 && index < values.length) {
                          _showTooltip(chartId, index);
                        }
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipColor: (_) {
                        return theme.colorScheme.inverseSurface;
                      },
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.round()} $unit',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: chartInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAxisValue(value, unit),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= days.length) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _dayLabel(days[index]),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [chartBar],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(Icons.flag_outlined, size: 17, color: color),

                const SizedBox(width: 6),

                Text(
                  'Daily Goal: $goal $unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverage(
    BuildContext context,
    List<int> stepsValues,
    List<int> waterValues,
    ColorScheme colors,
  ) {
    final theme = Theme.of(context);

    final stepsAverage = _average(stepsValues);

    final waterAverage = _average(waterValues);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: colors.primary),

                const SizedBox(width: 8),

                Text(
                  'Weekly Averages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _averageItem(
                    context,
                    title: 'Steps',
                    value: '${stepsAverage.round()}',
                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _averageItem(
                    context,
                    title: 'Water',
                    value: '${waterAverage.round()} ml',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _averageItem(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAxisValue(double value, String unit) {
    final rounded = value.round();

    if (unit == 'steps' && rounded >= 1000) {
      final thousands = rounded / 1000;

      if (thousands == thousands.roundToDouble()) {
        return '${thousands.round()}k';
      }

      return '${thousands.toStringAsFixed(1)}k';
    }

    if (unit == 'ml' && rounded >= 1000) {
      final liters = rounded / 1000;

      if (liters == liters.roundToDouble()) {
        return '${liters.round()}L';
      }

      return '${liters.toStringAsFixed(1)}L';
    }

    return '$rounded';
  }

  String _dayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return days[date.weekday - 1];
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
