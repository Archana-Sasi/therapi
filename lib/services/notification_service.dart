import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/medication_reminder.dart';

/// Service for managing local push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings (for future use)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();
    
    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Can handle navigation here if needed
  }

  /// Schedule notifications for a medication reminder
  Future<void> scheduleReminder(MedicationReminder reminder) async {
    if (!_isInitialized) await initialize();
    if (!reminder.isEnabled) return;

    // Cancel any existing notifications for this reminder
    await cancelReminder(reminder.id);

    final now = DateTime.now();
    int notificationId = reminder.id.hashCode;

    for (final time in reminder.scheduledTimes) {
      for (final dayOfWeek in reminder.daysOfWeek) {
        // Calculate next occurrence of this day/time
        var scheduledDate = _nextInstanceOfDayTime(dayOfWeek, time);
        
        // Only schedule if in the future
        if (scheduledDate.isAfter(now)) {
          final notifId = notificationId + (dayOfWeek * 100) + time.hour + time.minute;
          
          await _notifications.zonedSchedule(
            notifId,
            '💊 Time for your medication!',
            '${reminder.brandName.isNotEmpty ? reminder.brandName : "Medication"} - ${reminder.dosage}',
            tz.TZDateTime.from(scheduledDate, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'medication_reminders',
                'Medication Reminders',
                channelDescription: 'Notifications for medication reminders',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
                icon: '@mipmap/ic_launcher',
                color: const Color(0xFF2196F3),
                category: AndroidNotificationCategory.reminder,
              ),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: reminder.id,
          );
          
          debugPrint('Scheduled notification for ${reminder.brandName} on day $dayOfWeek at ${time.hour}:${time.minute}');
        }
      }
    }
  }

  DateTime _nextInstanceOfDayTime(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Find the next occurrence of this day of week
    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Cancel all notifications for a reminder
  Future<void> cancelReminder(String reminderId) async {
    // Cancel all possible notification IDs for this reminder
    final baseId = reminderId.hashCode;
    for (int day = 1; day <= 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          await _notifications.cancel(baseId + (day * 100) + hour + minute);
        }
      }
    }
    debugPrint('Cancelled notifications for reminder: $reminderId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();
    
    await _notifications.show(
      0,
      '💊 Test Medication Reminder',
      'This is a test notification with sound and vibration!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3),
        ),
      ),
    );
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
