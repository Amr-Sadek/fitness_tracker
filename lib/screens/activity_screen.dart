import 'package:flutter/material.dart';

import '../services/activity_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityService _activityService = ActivityService();

  List<Activity> _activities = [];

  bool _isLoading = true;

  final List<String> _activityTypes = [
    'Walking',
    'Running',
    'Cycling',
    'Gym',
    'Swimming',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getActivities();

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Activity loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showActivityDialog({Activity? activity}) async {
    final isEditing = activity != null;

    String selectedType = activity?.type ?? _activityTypes.first;

    String durationText = activity?.duration.toString() ?? '';

    String notes = activity?.notes ?? '';

    DateTime selectedDate = activity?.date ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);

            final colors = theme.colorScheme;

            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Activity' : 'Add Activity',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Activity',
                        prefixIcon: Icon(_getActivityIcon(selectedType)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: _activityTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _getActivityIcon(type),
                                size: 20,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: TextEditingController(text: durationText),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        durationText = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        hintText: 'Example: 30',
                        suffixText: 'min',
                        prefixIcon: const Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (date == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(selectedDate),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      maxLines: 3,
                      controller: TextEditingController(text: notes),
                      onChanged: (value) {
                        notes = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        hintText: 'How was your workout?',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    final duration = int.tryParse(durationText.trim());

                    if (duration == null || duration <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid duration.'),
                        ),
                      );

                      return;
                    }

                    final calories = _calculateCalories(selectedType, duration);

                    final updatedActivity = Activity(
                      id:
                          activity?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      type: selectedType,
                      duration: duration,
                      calories: calories,
                      date: selectedDate,
                      notes: notes.trim(),
                    );

                    try {
                      if (isEditing) {
                        await _activityService.updateActivity(updatedActivity);
                      } else {
                        await _activityService.addActivity(updatedActivity);
                      }

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext);

                      await _loadActivities();
                    } catch (error) {
                      debugPrint('Activity save error: $error');

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Could not update activity.'
                                : 'Could not add activity.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isEditing ? Icons.save_rounded : Icons.check_rounded,
                  ),
                  label: Text(isEditing ? 'Save Changes' : 'Add Activity'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _calculateCalories(String type, int duration) {
    double caloriesPerMinute;

    switch (type) {
      case 'Walking':
        caloriesPerMinute = 4.0;
        break;

      case 'Running':
        caloriesPerMinute = 10.0;
        break;

      case 'Cycling':
        caloriesPerMinute = 8.0;
        break;

      case 'Gym':
        caloriesPerMinute = 7.0;
        break;

      case 'Swimming':
        caloriesPerMinute = 9.0;
        break;

      default:
        caloriesPerMinute = 5.0;
    }

    return (duration * caloriesPerMinute).round();
  }

  Future<void> _deleteActivity(Activity activity) async {
    try {
      await _activityService.deleteActivity(activity.id);

      await _loadActivities();
    } catch (error) {
      debugPrint('Activity delete error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete activity.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Activity?'),
          content: Text(
            'Are you sure you want to delete this ${activity.type.toLowerCase()} activity?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteActivity(activity);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  int get _totalCalories {
    return _activities.fold(0, (sum, activity) => sum + activity.calories);
  }

  int get _totalMinutes {
    return _activities.fold(0, (sum, activity) => sum + activity.duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadActivities,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(child: _buildHeader(context)),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildSummaryCard(context),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Your Activities',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_activities.isNotEmpty)
                              Text(
                                '${_activities.length} ${_activities.length == 1 ? 'activity' : 'activities'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_activities.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList.builder(
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActivityCard(context, activity),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActivityDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Activity'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep track of your workouts and movement',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your recorded movement',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  value: '${_activities.length}',
                  label: 'Activities',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  value: '$_totalMinutes',
                  label: 'Minutes',
                  icon: Icons.timer_outlined,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  value: '$_totalCalories',
                  label: 'Calories',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 19),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.20),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final activityColor = _getActivityColor(context, activity.type);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: activityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _getActivityIcon(activity.type),
                color: activityColor,
                size: 27,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.type,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.duration} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.calories} kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(activity.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (activity.notes.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      activity.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showActivityDialog(activity: activity);
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {
                    _confirmDelete(context, activity);
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_run_rounded,
                size: 48,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No activities yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start recording your workouts and daily activities to build your fitness history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showActivityDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Activity'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(BuildContext context, String type) {
    final colors = Theme.of(context).colorScheme;

    switch (type) {
      case 'Walking':
        return colors.primary;

      case 'Running':
        return colors.tertiary;

      case 'Cycling':
        return Colors.teal;

      case 'Gym':
        return Colors.deepPurple;

      case 'Swimming':
        return Colors.cyan;

      default:
        return colors.secondary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Walking':
        return Icons.directions_walk_rounded;

      case 'Running':
        return Icons.directions_run_rounded;

      case 'Cycling':
        return Icons.directions_bike_rounded;

      case 'Gym':
        return Icons.fitness_center_rounded;

      case 'Swimming':
        return Icons.pool_rounded;

      default:
        return Icons.sports_rounded;
    }
  }
}
