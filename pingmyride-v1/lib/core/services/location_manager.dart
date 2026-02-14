import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LocationManager extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Position? _currentPosition;
  bool _isTracking = false;
  bool _locationServiceEnabled = false;
  LocationPermission? _permission;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;
  
  // Configuration
  static const int updateIntervalSeconds = 30; // Update location every 30 seconds
  static const double distanceFilterMeters = 10; // Only update if moved 10 meters
  
  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get locationServiceEnabled => _locationServiceEnabled;
  LocationPermission? get permission => _permission;
  
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  double? get altitude => _currentPosition?.altitude;
  double? get accuracy => _currentPosition?.accuracy;
  double? get speed => _currentPosition?.speed;
  double? get heading => _currentPosition?.heading;
  
  /// Initialize location manager and check permissions
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!_locationServiceEnabled) {
        debugPrint('LocationManager: Location services are disabled');
        Fluttertoast.showToast(
          msg: 'Please enable location services',
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      }
      
      // Check location permissions
      _permission = await Geolocator.checkPermission();
      
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
        
        if (_permission == LocationPermission.denied) {
          debugPrint('LocationManager: Location permissions are denied');
          Fluttertoast.showToast(
            msg: 'Location permissions are required',
            toastLength: Toast.LENGTH_LONG,
          );
          return false;
        }
      }
      
      if (_permission == LocationPermission.deniedForever) {
        debugPrint('LocationManager: Location permissions are permanently denied');
        Fluttertoast.showToast(
          msg: 'Please enable location permissions in app settings',
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      }
      
      // Get initial position
      await _getCurrentLocation();
      
      debugPrint('LocationManager: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('LocationManager: Error during initialization: $e');
      return false;
    }
  }
  
  /// Get current location once
  Future<Position?> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      debugPrint(
        'LocationManager: Current position - '
        'Lat: ${_currentPosition?.latitude}, '
        'Lng: ${_currentPosition?.longitude}, '
        'Accuracy: ${_currentPosition?.accuracy}m'
      );
      
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint('LocationManager: Error getting current location: $e');
      return null;
    }
  }
  
  /// Start tracking location and updating to Firebase
  Future<void> startTracking({String? busId}) async {
    if (_isTracking) {
      debugPrint('LocationManager: Already tracking');
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('LocationManager: User not authenticated');
      return;
    }
    
    // Initialize if not already done
    if (!_locationServiceEnabled || _permission == null) {
      final initialized = await initialize();
      if (!initialized) {
        return;
      }
    }
    
    _isTracking = true;
    notifyListeners();
    
    debugPrint('LocationManager: Starting location tracking for user ${user.uid}');
    
    // Set up location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    // Listen to position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        notifyListeners();
        
        debugPrint(
          'LocationManager: Position updated - '
          'Lat: ${position.latitude}, '
          'Lng: ${position.longitude}, '
          'Speed: ${position.speed}m/s'
        );
      },
      onError: (error) {
        debugPrint('LocationManager: Error in position stream: $error');
      },
    );
    
    // Set up periodic Firebase updates
    _updateTimer = Timer.periodic(
      const Duration(seconds: updateIntervalSeconds),
      (timer) => _updateLocationToFirebase(busId: busId),
    );
    
    // Initial update
    await _updateLocationToFirebase(busId: busId);
    
    Fluttertoast.showToast(
      msg: 'Location tracking started',
      toastLength: Toast.LENGTH_SHORT,
    );
  }
  
  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }
    
    _isTracking = false;
    
    // Cancel the position stream subscription
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    // Cancel the update timer
    _updateTimer?.cancel();
    _updateTimer = null;
    
    notifyListeners();
    
    debugPrint('LocationManager: Location tracking stopped');
    
    Fluttertoast.showToast(
      msg: 'Location tracking stopped',
      toastLength: Toast.LENGTH_SHORT,
    );
  }
  
  /// Update location to Firebase
  Future<void> _updateLocationToFirebase({String? busId}) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }
    
    if (_currentPosition == null) {
      debugPrint('LocationManager: No position available to update');
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('LocationManager: User not authenticated');
      return;
    }
    
    try {
      final locationData = {
        'userId': user.uid,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'altitude': _currentPosition!.altitude,
        'accuracy': _currentPosition!.accuracy,
        'speed': _currentPosition!.speed,
        'heading': _currentPosition!.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (busId != null) {
        locationData['busId'] = busId;
        
        // Update bus location in buses collection
        await _firestore.collection('buses').doc(busId).update({
          'currentLocation': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          'lastLocationUpdate': FieldValue.serverTimestamp(),
          'speed': _currentPosition!.speed,
          'heading': _currentPosition!.heading,
        });
        
        debugPrint('LocationManager: Updated bus $busId location');
      }
      
      // Save to location_history collection for tracking
      await _firestore.collection('location_history').add(locationData);
      
      // Update user's current location
      await _firestore.collection('users').doc(user.uid).update({
        'currentLocation': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      
      debugPrint(
        'LocationManager: Updated location to Firebase - '
        'Lat: ${_currentPosition!.latitude}, '
        'Lng: ${_currentPosition!.longitude}'
      );
    } catch (e) {
      debugPrint('LocationManager: Error updating location to Firebase: $e');
    }
  }
  
  /// Manually update location to Firebase (can be called on demand)
  Future<void> updateLocation({String? busId}) async {
    await _getCurrentLocation();
    await _updateLocationToFirebase(busId: busId);
  }
  
  /// Get distance between two coordinates in meters
  double getDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  /// Get bearing between two coordinates
  double getBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  /// Stream bus location updates
  Stream<DocumentSnapshot> streamBusLocation(String busId) {
    return _firestore.collection('buses').doc(busId).snapshots();
  }
  
  /// Get location history for a user or bus
  Future<List<Map<String, dynamic>>> getLocationHistory({
    String? userId,
    String? busId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('location_history');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (busId != null) {
        query = query.where('busId', isEqualTo: busId);
      }
      
      query = query.orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('LocationManager: Error getting location history: $e');
      return [];
    }
  }
  
  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
  
  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
