import 'package:flutter/material.dart';

import '../services/goal_service.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({super.key});

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen> {
  final GoalService _goalService = GoalService();

  final TextEditingController _stepsController = TextEditingController();

  final TextEditingController _waterController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final stepsGoal = await _goalService.getStepsGoal();

      final waterGoal = await _goalService.getWaterGoal();

      if (!mounted) return;

      _stepsController.text = stepsGoal.toString();

      _waterController.text = waterGoal.toString();

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Goal loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    FocusScope.of(context).unfocus();

    final stepsGoal = int.tryParse(_stepsController.text.trim());

    final waterGoal = int.tryParse(_waterController.text.trim());

    if (stepsGoal == null || stepsGoal <= 0) {
      _showError('Please enter a valid steps goal.');
      return;
    }

    if (waterGoal == null || waterGoal <= 0) {
      _showError('Please enter a valid water goal.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _goalService.setStepsGoal(stepsGoal);

      await _goalService.setWaterGoal(waterGoal);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Goal saving error: $error');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError('Could not save goals. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _waterController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Daily Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),

                  const SizedBox(height: 28),

                  _buildGoalCard(
                    context,
                    controller: _stepsController,
                    icon: Icons.directions_walk_rounded,
                    title: 'Daily Steps',
                    description:
                        'Set the number of steps you want to reach every day.',
                    suffix: 'steps',
                    color: colors.primary,
                  ),

                  const SizedBox(height: 16),

                  _buildGoalCard(
                    context,
                    controller: _waterController,
                    icon: Icons.water_drop_rounded,
                    title: 'Daily Water',
                    description:
                        'Set how much water you want to drink every day.',
                    suffix: 'ml',
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  _buildTipCard(context),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveGoals,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Goals',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Your Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Set targets that match your daily routine.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required TextEditingController controller,
    required IconData icon,
    required String title,
    required String description,
    required String suffix,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),

                const SizedBox(width: 13),

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
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Daily target',
                suffixText: suffix,
                prefixIcon: Icon(icon),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: colors.primary,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'You can change these goals anytime from Settings.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
