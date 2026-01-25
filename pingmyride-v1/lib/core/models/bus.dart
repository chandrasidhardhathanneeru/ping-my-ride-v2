import 'package:cloud_firestore/cloud_firestore.dart';

class Bus {
  final String id;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String driverEmail;
  final int capacity;
  final int bookedSeats;
  final String routeId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final GeoPoint? currentLocation;
  final DateTime? lastLocationUpdate;
  final double? speed;
  final double? heading;

  Bus({
    required this.id,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.driverEmail,
    required this.capacity,
    this.bookedSeats = 0,
    required this.routeId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.currentLocation,
    this.lastLocationUpdate,
    this.speed,
    this.heading,
  });

  int get availableSeats => capacity - bookedSeats;
  bool get hasAvailableSeats => availableSeats > 0;

  factory Bus.fromMap(Map<String, dynamic> map, String id) {
    return Bus(
      id: id,
      busNumber: map['busNumber'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      driverEmail: map['driverEmail'] ?? '',
      capacity: map['capacity'] ?? 0,
      bookedSeats: map['bookedSeats'] ?? 0,
      routeId: map['routeId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      currentLocation: map['currentLocation'],
      lastLocationUpdate: map['lastLocationUpdate']?.toDate(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'capacity': capacity,
      'bookedSeats': bookedSeats,
      'routeId': routeId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (currentLocation != null) 'currentLocation': currentLocation,
      if (lastLocationUpdate != null) 'lastLocationUpdate': lastLocationUpdate,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }

  Bus copyWith({
    String? id,
    String? busNumber,
    String? driverName,
    String? driverPhone,
    String? driverEmail,
    int? capacity,
    int? bookedSeats,
    String? routeId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? currentLocation,
    DateTime? lastLocationUpdate,
    double? speed,
    double? heading,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverEmail: driverEmail ?? this.driverEmail,
      capacity: capacity ?? this.capacity,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      routeId: routeId ?? this.routeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentLocation: currentLocation ?? this.currentLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
  
  // Get latitude from currentLocation
  double? get latitude => currentLocation?.latitude;
  
  // Get longitude from currentLocation
  double? get longitude => currentLocation?.longitude;
  
  // Check if bus has recent location data (updated in last 5 minutes)
  bool get hasRecentLocation {
    if (lastLocationUpdate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastLocationUpdate!);
    return difference.inMinutes <= 5;
  }
}