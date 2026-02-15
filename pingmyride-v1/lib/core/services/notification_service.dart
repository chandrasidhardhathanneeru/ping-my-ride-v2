import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service to handle local notifications for booking confirmations
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
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

      _isInitialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Error initializing: $e');
    }
  }

  /// Handle notification tap - safely logs tap without forced navigation
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('NotificationService: Notification tapped: ${response.payload}');
      debugPrint('NotificationService: Action ID: ${response.actionId}');
      // App opens normally - no forced navigation to maintain existing flow
    } catch (e) {
      debugPrint('NotificationService: Error handling notification tap: $e');
      // Silently fail - don't crash the app
    }
  }

  /// Show booking confirmation notification
  Future<void> showBookingConfirmation({
    required String routeName,
    required String time,
    required String busNumber,
  }) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'booking_channel', // channel ID
        'Booking Confirmations', // channel name
        channelDescription: 'Notifications for bus booking confirmations',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        '🎉 Booking Confirmed!',
        'Your bus booking is confirmed for $routeName at $time',
        notificationDetails,
        payload: 'booking_$busNumber',
      );

      debugPrint('NotificationService: Booking confirmation sent for $routeName at $time');
    } catch (e) {
      debugPrint('NotificationService: Error showing notification: $e');
      // Don't throw - notifications are not critical
    }
  }

  /// Show trip start notification to student
  Future<void> showTripStartNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Ensure the plugin is initialized
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'trip_channel', // channel ID
        'Trip Updates', // channel name
        channelDescription: 'Notifications for trip start and updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
        ticker: 'Trip Started',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        title,
        body,
        notificationDetails,
        payload: 'trip_start',
      );

      debugPrint('NotificationService: Trip start notification sent');
    } catch (e) {
      debugPrint('NotificationService: Error showing trip notification: $e');
      // Don't throw - notifications are not critical
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('NotificationService: All notifications cancelled');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling notifications: $e');
    }
  }
}
