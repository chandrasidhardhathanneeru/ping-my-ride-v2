import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Service to handle Firebase Cloud Messaging for push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Request Android notification permission (API 33+)
  Future<bool> _requestAndroidNotificationPermission() async {
    try {
      // Only request for Android devices
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.notification.status;
        
        if (status.isGranted) {
          debugPrint('FCM: Android notification permission already granted');
          return true;
        }
        
        if (status.isDenied) {
          final result = await Permission.notification.request();
          
          if (result.isGranted) {
            debugPrint('FCM: Android notification permission granted');
            return true;
          } else if (result.isDenied) {
            debugPrint('FCM: Android notification permission denied - continuing without notifications');
            return false;
          } else if (result.isPermanentlyDenied) {
            debugPrint('FCM: Android notification permission permanently denied - user needs to enable in settings');
            return false;
          }
        }
        
        if (status.isPermanentlyDenied) {
          debugPrint('FCM: Android notification permission permanently denied - user needs to enable in settings');
          return false;
        }
      }
      
      // For iOS, web, and other platforms, return true
      return true;
    } catch (e) {
      debugPrint('FCM: Error requesting Android notification permission: $e');
      // Continue without blocking even if permission check fails
      return false;
    }
  }

  /// Initialize FCM and request notification permissions
  Future<void> initialize() async {
    try {
      // First, request Android notification permission (API 33+)
      await _requestAndroidNotificationPermission();
      
      // Request permission for iOS and web
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('FCM: User granted permission');
        await _retrieveToken();
      } else {
        debugPrint('FCM: User declined or has not accepted permission - app will continue without notifications');
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM: Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('FCM: Error initializing: $e - app will continue without notifications');
    }
  }

  /// Retrieve the FCM token
  Future<String?> _retrieveToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM: Token retrieved: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('FCM: Error retrieving token: $e');
      return null;
    }
  }

  /// Store FCM token in Firestore for the logged-in user
  Future<void> storeFCMToken(String userId, String userType) async {
    try {
      if (_fcmToken == null) {
        await _retrieveToken();
      }

      if (_fcmToken != null) {
        // Determine the collection based on user type
        String collection;
        switch (userType.toLowerCase()) {
          case 'student':
            collection = 'students';
            break;
          case 'driver':
            collection = 'drivers';
            break;
          case 'admin':
            collection = 'admins';
            break;
          default:
            debugPrint('FCM: Unknown user type: $userType - skipping token storage');
            return;
        }

        // Store token in user's document
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .set({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('FCM: Token stored for user $userId in $collection');
      } else {
        debugPrint('FCM: No token available to store - user may have denied notification permission');
      }
    } catch (e) {
      debugPrint('FCM: Error storing token: $e - app will continue without notification storage');
    }
  }

  /// Remove FCM token from Firestore when user logs out
  Future<void> removeFCMToken(String userId, String userType) async {
    try {
      // Determine the collection based on user type
      String collection;
      switch (userType.toLowerCase()) {
        case 'student':
          collection = 'students';
          break;
        case 'driver':
          collection = 'drivers';
          break;
        case 'admin':
          collection = 'admins';
          break;
        default:
          debugPrint('FCM: Unknown user type: $userType');
          return;
      }

      // Remove token from user's document
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      debugPrint('FCM: Token removed for user $userId');
    } catch (e) {
      debugPrint('FCM: Error removing token: $e');
    }
  }

  /// Setup foreground message handler
  void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        debugPrint('FCM: Received foreground message');
        debugPrint('FCM: Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('FCM: Title: ${message.notification?.title}');
          debugPrint('FCM: Body: ${message.notification?.body}');
        }
      } catch (e) {
        debugPrint('FCM: Error handling foreground message: $e');
      }
    });
  }

  /// Setup background message handler
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      debugPrint('FCM: Handling background message: ${message.messageId}');
      debugPrint('FCM: Message data: ${message.data}');
    } catch (e) {
      debugPrint('FCM: Error handling background message: $e');
      // Silently fail - don't crash the app
    }
  }

  /// Request permission after login (for better UX)
  Future<bool> requestPermissionAfterLogin() async {
    try {
      // First, request Android notification permission (API 33+)
      final androidPermissionGranted = await _requestAndroidNotificationPermission();
      
      // Request permission for iOS and web
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      bool isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // For Android, we need both permissions
      if (!kIsWeb && Platform.isAndroid) {
        isAuthorized = isAuthorized && androidPermissionGranted;
      }

      if (isAuthorized) {
        await _retrieveToken();
        debugPrint('FCM: Notification permissions granted successfully');
      } else {
        debugPrint('FCM: Notification permissions not granted - app will continue without notifications');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('FCM: Error requesting permission: $e - app will continue without notifications');
      return false;
    }
  }

  /// Send trip start notification to students
  /// Creates notification records in Firestore for students to receive
  Future<void> notifyStudentsOfTripStart({
    required String busId,
    required String routeId,
    required String timeSlot,
    required String busNumber,
    required String routeName,
    required String driverName,
    required DateTime travelDate,
  }) async {
    try {
      debugPrint('FCM: Notifying students of trip start for bus $busNumber');

      // Get all confirmed bookings for this specific trip
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('busId', isEqualTo: busId)
          .where('routeId', isEqualTo: routeId)
          .where('selectedTimeSlot', isEqualTo: timeSlot)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        debugPrint('FCM: No confirmed bookings found for this trip');
        return;
      }

      // Filter bookings for the specific travel date
      final dateStr = '${travelDate.year}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}';
      final relevantBookings = bookingsSnapshot.docs.where((doc) {
        final bookingData = doc.data();
        final selectedDate = bookingData['selectedBookingDate'];
        if (selectedDate == null) return false;
        
        final bookingDate = (selectedDate as Timestamp).toDate();
        final bookingDateStr = '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
        return bookingDateStr == dateStr;
      }).toList();

      debugPrint('FCM: Found ${relevantBookings.length} students to notify');

      int successCount = 0;
      int failCount = 0;

      // Create notification records for each student
      for (var bookingDoc in relevantBookings) {
        try {
          final userId = bookingDoc.data()['userId'];
          if (userId == null || userId.isEmpty) {
            debugPrint('FCM: Skipping booking with no userId');
            failCount++;
            continue;
          }

          // Get student's FCM token
          String? fcmToken;
          try {
            final studentDoc = await FirebaseFirestore.instance
                .collection('students')
                .doc(userId)
                .get();
            
            if (studentDoc.exists) {
              fcmToken = studentDoc.data()?['fcmToken'];
            }
          } catch (e) {
            debugPrint('FCM: Could not retrieve token for student $userId: $e');
          }

          // Create notification record
          await FirebaseFirestore.instance
              .collection('notifications')
              .add({
            'userId': userId,
            'fcmToken': fcmToken, // Store token for backend processing
            'type': 'trip_started',
            'title': '🚌 Your Bus is on the way!',
            'body': '$driverName has started the $routeName route (Bus $busNumber) for $timeSlot.',
            'data': {
              'busId': busId,
              'busNumber': busNumber,
              'routeId': routeId,
              'routeName': routeName,
              'timeSlot': timeSlot,
              'driverName': driverName,
              'travelDate': dateStr,
            },
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          successCount++;
        } catch (e) {
          debugPrint('FCM: Error creating notification for booking ${bookingDoc.id}: $e');
          failCount++;
        }
      }

      debugPrint('FCM: Trip start notifications created - Success: $successCount, Failed: $failCount');
    } catch (e) {
      debugPrint('FCM: Error notifying students of trip start: $e');
    }
  }
}
