import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/daily_goals_screen.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  final HealthService _healthService = HealthService();

  // ---------------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------------

  bool _isLoading = true;

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  bool _notificationsEnabled = true;
  bool _waterRemindersEnabled = true;
  bool _activityRemindersEnabled = true;
  bool _goalReminderEnabled = true;

  int _waterStartHour = 9;
  int _waterStartMinute = 0;

  int _waterEndHour = 22;
  int _waterEndMinute = 0;

  int _waterInterval = 2;

  int _activityHour = 17;
  int _activityMinute = 0;

  int _goalHour = 20;
  int _goalMinute = 0;

  bool _isChangingNotifications = false;

  // ---------------------------------------------------------------------------
  // Health Connect
  // ---------------------------------------------------------------------------

  bool _healthAvailable = false;
  bool _healthConnected = false;
  bool _isCheckingHealth = true;
  bool _isConnectingHealth = false;

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ---------------------------------------------------------------------------
  // Load settings
  // ---------------------------------------------------------------------------

  Future<void> _loadSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final notificationSettings = await _notificationService
          .getNotificationSettings();

      if (!mounted) return;

      setState(() {
        _notificationsEnabled =
            notificationSettings['notificationsEnabled'] ?? true;

        _waterRemindersEnabled =
            notificationSettings['waterRemindersEnabled'] ?? true;

        _activityRemindersEnabled =
            notificationSettings['activityRemindersEnabled'] ?? true;

        _goalReminderEnabled =
            notificationSettings['goalReminderEnabled'] ?? true;

        _waterStartHour = notificationSettings['waterStartHour'] ?? 9;

        _waterStartMinute = notificationSettings['waterStartMinute'] ?? 0;

        _waterEndHour = notificationSettings['waterEndHour'] ?? 22;

        _waterEndMinute = notificationSettings['waterEndMinute'] ?? 0;

        _waterInterval = notificationSettings['waterInterval'] ?? 2;

        _activityHour = notificationSettings['activityHour'] ?? 17;

        _activityMinute = notificationSettings['activityMinute'] ?? 0;

        _goalHour = notificationSettings['goalHour'] ?? 20;

        _goalMinute = notificationSettings['goalMinute'] ?? 0;

        _isLoading = false;
      });

      // Keep preferences instance initialized.
      await preferences.getBool('dark_mode');

      await _checkHealthStatus();
    } catch (error) {
      debugPrint('Settings loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isCheckingHealth = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Daily goals
  // ---------------------------------------------------------------------------

  Future<void> _openDailyGoals() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const DailyGoalsScreen()),
    );

    if (!mounted) return;

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Master notifications
  // ---------------------------------------------------------------------------

  Future<void> _changeNotificationsEnabled(bool value) async {
    if (_isChangingNotifications) {
      return;
    }

    setState(() {
      _isChangingNotifications = true;
    });

    try {
      if (value) {
        final permission = await _notificationService.requestPermission();

        if (!permission) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Notification permission is required.'),
            ),
          );

          return;
        }
      }

      await _notificationService.setNotificationsEnabled(value);

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = value;
      });
    } catch (error) {
      debugPrint('Notification master setting error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not update notification settings.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingNotifications = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Water reminders
  // ---------------------------------------------------------------------------

  Future<void> _changeWaterReminders(bool value) async {
    try {
      if (value) {
        final permission = await _notificationService.requestPermission();

        if (!permission) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Notification permission is required.'),
            ),
          );

          return;
        }
      }

      await _notificationService.setWaterRemindersEnabled(value);

      if (!mounted) return;

      setState(() {
        _waterRemindersEnabled = value;
      });
    } catch (error) {
      debugPrint('Water reminder setting error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Activity reminders
  // ---------------------------------------------------------------------------

  Future<void> _changeActivityReminders(bool value) async {
    try {
      if (value) {
        final permission = await _notificationService.requestPermission();

        if (!permission) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Notification permission is required.'),
            ),
          );

          return;
        }
      }

      await _notificationService.setActivityRemindersEnabled(value);

      if (!mounted) return;

      setState(() {
        _activityRemindersEnabled = value;
      });
    } catch (error) {
      debugPrint('Activity reminder setting error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Goal reminder
  // ---------------------------------------------------------------------------

  Future<void> _changeGoalReminder(bool value) async {
    try {
      if (value) {
        final permission = await _notificationService.requestPermission();

        if (!permission) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Notification permission is required.'),
            ),
          );

          return;
        }
      }

      await _notificationService.setGoalReminderEnabled(value);

      if (!mounted) return;

      setState(() {
        _goalReminderEnabled = value;
      });
    } catch (error) {
      debugPrint('Goal reminder setting error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Water reminder settings
  // ---------------------------------------------------------------------------

  Future<void> _changeWaterStartTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _waterStartHour, minute: _waterStartMinute),
    );

    if (selectedTime == null) {
      return;
    }

    final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

    final endMinutes = _waterEndHour * 60 + _waterEndMinute;

    if (startMinutes >= endMinutes) {
      _showMessage('Start time must be before end time.');
      return;
    }

    setState(() {
      _waterStartHour = selectedTime.hour;
      _waterStartMinute = selectedTime.minute;
    });

    await _rescheduleWaterReminders();
  }

  Future<void> _changeWaterEndTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _waterEndHour, minute: _waterEndMinute),
    );

    if (selectedTime == null) {
      return;
    }

    final startMinutes = _waterStartHour * 60 + _waterStartMinute;

    final endMinutes = selectedTime.hour * 60 + selectedTime.minute;

    if (endMinutes <= startMinutes) {
      _showMessage('End time must be after start time.');
      return;
    }

    setState(() {
      _waterEndHour = selectedTime.hour;
      _waterEndMinute = selectedTime.minute;
    });

    await _rescheduleWaterReminders();
  }

  Future<void> _changeWaterInterval(int interval) async {
    setState(() {
      _waterInterval = interval;
    });

    await _rescheduleWaterReminders();
  }

  Future<void> _rescheduleWaterReminders() async {
    try {
      await _notificationService.scheduleWaterReminders(
        startHour: _waterStartHour,
        startMinute: _waterStartMinute,
        endHour: _waterEndHour,
        endMinute: _waterEndMinute,
        intervalHours: _waterInterval,
      );
    } catch (error) {
      debugPrint('Water reminder reschedule error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Activity reminder time
  // ---------------------------------------------------------------------------

  Future<void> _changeActivityTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _activityHour, minute: _activityMinute),
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _activityHour = selectedTime.hour;
      _activityMinute = selectedTime.minute;
    });

    await _notificationService.scheduleActivityReminder(
      hour: _activityHour,
      minute: _activityMinute,
    );
  }

  // ---------------------------------------------------------------------------
  // Goal reminder time
  // ---------------------------------------------------------------------------

  Future<void> _changeGoalTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _goalHour, minute: _goalMinute),
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _goalHour = selectedTime.hour;
      _goalMinute = selectedTime.minute;
    });

    await _notificationService.scheduleDailyGoalReminder(
      hour: _goalHour,
      minute: _goalMinute,
    );
  }

  // ---------------------------------------------------------------------------
  // Health Connect
  // ---------------------------------------------------------------------------

  Future<void> _checkHealthStatus() async {
    if (_isCheckingHealth == false) {
      setState(() {
        _isCheckingHealth = true;
      });
    }

    try {
      final available = await _healthService.isHealthAvailable();

      bool connected = false;

      if (available) {
        connected = await _healthService.hasPermissions();
      }

      if (!mounted) return;

      setState(() {
        _healthAvailable = available;
        _healthConnected = connected;
        _isCheckingHealth = false;
      });
    } catch (error) {
      debugPrint('Health status error: $error');

      if (!mounted) return;

      setState(() {
        _healthAvailable = false;
        _healthConnected = false;
        _isCheckingHealth = false;
      });
    }
  }

  Future<void> _connectHealth() async {
    if (_isConnectingHealth) {
      return;
    }

    setState(() {
      _isConnectingHealth = true;
    });

    try {
      final available = await _healthService.isHealthAvailable();

      if (!available) {
        if (!mounted) return;

        await _showHealthUnavailableDialog();

        return;
      }

      final authorized = await _healthService.requestPermissions();

      if (!mounted) return;

      if (authorized) {
        setState(() {
          _healthAvailable = true;
          _healthConnected = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Health data access connected successfully.'),
          ),
        );
      } else {
        setState(() {
          _healthAvailable = true;
          _healthConnected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Health data permission was not granted.'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Health connection error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not connect to Health Connect.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingHealth = false;
        });
      }
    }
  }

  Future<void> _installHealthConnect() async {
    try {
      await _healthService.installHealthConnect();
    } catch (error) {
      debugPrint('Health Connect installation error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open Health Connect installation.'),
        ),
      );
    }
  }

  Future<void> _showHealthUnavailableDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          icon: Icon(
            Icons.health_and_safety_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Health Connect unavailable'),
          content: const Text(
            'Health Connect is not available on this device. '
            'You can install it and then connect your health data.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _installHealthConnect();
              },
              child: const Text('Install'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  String _formatTime(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);

    return time.format(context);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Manage your app preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          // -------------------------------------------------------------------
          // Appearance
          // -------------------------------------------------------------------
          _buildSectionTitle(context, 'Appearance', Icons.palette_outlined),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: _buildIconContainer(
                context,
                widget.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                widget.isDarkMode
                    ? 'Dark theme is enabled'
                    : 'Light theme is enabled',
              ),
              trailing: Switch(
                value: widget.isDarkMode,
                onChanged: widget.onThemeChanged,
              ),
            ),
          ),

          const SizedBox(height: 26),

          // -------------------------------------------------------------------
          // Daily Goals
          // -------------------------------------------------------------------
          _buildSectionTitle(context, 'Daily Goals', Icons.flag_outlined),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              leading: _buildIconContainer(context, Icons.flag_outlined),
              title: const Text(
                'Steps & Water Goals',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Customize your daily targets'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openDailyGoals,
            ),
          ),

          const SizedBox(height: 26),

          // -------------------------------------------------------------------
          // Notifications
          // -------------------------------------------------------------------
          _buildSectionTitle(
            context,
            'Notifications',
            Icons.notifications_none_rounded,
          ),

          const SizedBox(height: 10),

          // Master switch
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: _buildIconContainer(
                context,
                Icons.notifications_active_outlined,
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _notificationsEnabled
                    ? 'Notifications are enabled'
                    : 'All notifications are disabled',
              ),
              trailing: _isChangingNotifications
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _notificationsEnabled,
                      onChanged: _changeNotificationsEnabled,
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Water
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  leading: _buildIconContainer(
                    context,
                    Icons.water_drop_rounded,
                  ),
                  title: const Text(
                    'Water Reminders',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _waterRemindersEnabled
                        ? '${_formatTime(_waterStartHour, _waterStartMinute)} – '
                              '${_formatTime(_waterEndHour, _waterEndMinute)} • '
                              'Every $_waterInterval h'
                        : 'Water reminders are disabled',
                  ),
                  trailing: Switch(
                    value: _waterRemindersEnabled && _notificationsEnabled,
                    onChanged: _notificationsEnabled
                        ? _changeWaterReminders
                        : null,
                  ),
                ),

                if (_waterRemindersEnabled && _notificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      children: [
                        const Divider(),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: _buildSettingButton(
                                context,
                                icon: Icons.play_arrow_rounded,
                                title: 'Start',
                                value: _formatTime(
                                  _waterStartHour,
                                  _waterStartMinute,
                                ),
                                onTap: _changeWaterStartTime,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: _buildSettingButton(
                                context,
                                icon: Icons.stop_rounded,
                                title: 'End',
                                value: _formatTime(
                                  _waterEndHour,
                                  _waterEndMinute,
                                ),
                                onTap: _changeWaterEndTime,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildIntervalSelector(context),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Activity
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: _buildIconContainer(
                context,
                Icons.directions_walk_rounded,
              ),
              title: const Text(
                'Activity Reminder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _activityRemindersEnabled && _notificationsEnabled
                    ? 'Every day at ${_formatTime(_activityHour, _activityMinute)}'
                    : 'Activity reminders are disabled',
              ),
              trailing: Switch(
                value: _activityRemindersEnabled && _notificationsEnabled,
                onChanged: _notificationsEnabled
                    ? _changeActivityReminders
                    : null,
              ),
              onTap: _activityRemindersEnabled && _notificationsEnabled
                  ? _changeActivityTime
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // Goal reminder
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: _buildIconContainer(context, Icons.flag_circle_outlined),
              title: const Text(
                'Daily Goal Reminder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _goalReminderEnabled && _notificationsEnabled
                    ? 'Every day at ${_formatTime(_goalHour, _goalMinute)}'
                    : 'Goal reminders are disabled',
              ),
              trailing: Switch(
                value: _goalReminderEnabled && _notificationsEnabled,
                onChanged: _notificationsEnabled ? _changeGoalReminder : null,
              ),
              onTap: _goalReminderEnabled && _notificationsEnabled
                  ? _changeGoalTime
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------------------
          // Health Connect
          // -------------------------------------------------------------------
          _buildSectionTitle(
            context,
            'Health & Data',
            Icons.favorite_outline_rounded,
          ),

          const SizedBox(height: 10),

          _buildHealthConnectCard(context),

          const SizedBox(height: 26),

          _buildSectionTitle(context, 'About', Icons.info_outline_rounded),

          const SizedBox(height: 10),

          _buildAboutCard(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interval selector
  // ---------------------------------------------------------------------------

  Widget _buildIntervalSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder interval',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          children: [
            _buildIntervalChip(context, 1),
            _buildIntervalChip(context, 2),
            _buildIntervalChip(context, 3),
            _buildIntervalChip(context, 4),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalChip(BuildContext context, int value) {
    return ChoiceChip(
      label: Text('Every $value h'),
      selected: _waterInterval == value,
      onSelected: (_) => _changeWaterInterval(value),
    );
  }

  // ---------------------------------------------------------------------------
  // Setting button
  // ---------------------------------------------------------------------------

  Widget _buildSettingButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Health Connect card
  // ---------------------------------------------------------------------------

  Widget _buildHealthConnectCard(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    Color statusColor;

    IconData statusIcon;

    String statusTitle;

    String statusSubtitle;

    String buttonText;

    if (_isCheckingHealth) {
      statusColor = colors.primary;

      statusIcon = Icons.sync_rounded;

      statusTitle = 'Checking connection...';

      statusSubtitle = 'Checking Health Connect status';

      buttonText = 'Refresh';
    } else if (!_healthAvailable) {
      statusColor = colors.error;

      statusIcon = Icons.error_outline_rounded;

      statusTitle = 'Health Connect unavailable';

      statusSubtitle = 'Health Connect is not available on this device';

      buttonText = 'Install';
    } else if (!_healthConnected) {
      statusColor = Colors.orange;

      statusIcon = Icons.lock_outline_rounded;

      statusTitle = 'Permission required';

      statusSubtitle = 'Allow access to your step count';

      buttonText = 'Connect';
    } else {
      statusColor = Colors.green;

      statusIcon = Icons.check_circle_outline_rounded;

      statusTitle = 'Health Connect connected';

      statusSubtitle = 'Step data access is enabled';

      buttonText = 'Refresh';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Connect',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        statusTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        statusSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isCheckingHealth ? null : _checkHealthStatus,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isCheckingHealth)
              const LinearProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isConnectingHealth
                      ? null
                      : (!_healthAvailable
                            ? _installHealthConnect
                            : _healthConnected
                            ? _checkHealthStatus
                            : _connectHealth),
                  icon: _isConnectingHealth
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          !_healthAvailable
                              ? Icons.download_rounded
                              : _healthConnected
                              ? Icons.refresh_rounded
                              : Icons.link_rounded,
                        ),
                  label: Text(
                    _isConnectingHealth ? 'Connecting...' : buttonText,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              'Fitness Tracker uses Health Connect to read your daily step count.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),

        const SizedBox(width: 8),

        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Icon container
  // ---------------------------------------------------------------------------

  Widget _buildIconContainer(BuildContext context, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 21),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: _buildIconContainer(context, Icons.info_outline_rounded),
        title: const Text(
          'Fitness Tracker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Version 1.0.0'),
      ),
    );
  }
}
