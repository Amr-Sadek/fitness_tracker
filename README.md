# 🏃 Fitness Tracker

A Flutter-based fitness tracking application designed to help users monitor their daily health and fitness habits in one place.

The app focuses on tracking daily steps, water intake, physical activities, and personal fitness goals, with progress visualization and health reminders.

---

## 📱 Features

### 👟 Daily Steps
- Track daily steps using Android Health Connect.
- Display the current step count.
- Set and customize a daily steps goal.
- Track progress toward the daily target.

### 💧 Water Tracking
- Track daily water intake.
- Quickly add common water amounts.
- Add a custom amount.
- Remove water if an incorrect amount was added.
- Reset the daily water intake.
- Automatically start a new daily record.

### 🏋️ Activity Tracking
- Log physical activities.
- Record activity type.
- Record duration.
- Record calories burned.
- Add optional notes.
- View today's activity summary from the Home screen.
- View detailed activity history from the Activity section.
- Delete recorded activities.

### 📊 Progress Tracking
- Visualize fitness progress using charts.
- Track steps and water intake over time.
- Review historical activity data.

### 🎯 Daily Goals
- Customize daily steps goal.
- Customize daily water goal.
- Track progress toward personal targets.

### 🔔 Health Reminders
- Water reminders throughout the day.
- Activity reminders.
- Daily goal reminders.
- Customizable reminder times.
- Customizable water reminder interval.
- Test notification option.

### ⚙️ Settings
- Dark Mode.
- Notification controls.
- Health Connect connection.
- Daily Goals management.
- About section.

### 👤 Profile
- Personal profile information.
- Profile image selection.
- Local profile data storage.

---

## 🛠️ Technologies

- **Flutter**
- **Dart**
- **Android Health Connect**
- **SharedPreferences**
- **Flutter Local Notifications**
- **fl_chart**
- **permission_handler**
- **image_picker**
- **path_provider**

---

## 📂 Project Structure

```text
lib/
├── screens/
│   ├── home_screen.dart
│   ├── progress_screen.dart
│   ├── activity_screen.dart
│   ├── settings_screen.dart
│   └── daily_goals_screen.dart
│
├── services/
│   ├── health_service.dart
│   ├── water_service.dart
│   ├── activity_service.dart
│   ├── goal_service.dart
│   └── notification_service.dart
│
└── theme/
    └── app_theme.dart
