class BusRoute {
  final String id;
  final String routeName;
  final String pickupLocation;
  final String dropLocation;
  final List<BusStop> intermediateStops;
  final String estimatedDuration; // e.g., "45 minutes"
  final double distance; // in kilometers
  final double baseFare; // Full route fare (₹) from start to end
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusRoute({
    required this.id,
    required this.routeName,
    required this.pickupLocation,
    required this.dropLocation,
    this.intermediateStops = const [],
    required this.estimatedDuration,
    required this.distance,
    this.baseFare = 50.0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusRoute.fromMap(Map<String, dynamic> map, String id) {
    return BusRoute(
      id: id,
      routeName: map['routeName'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      dropLocation: map['dropLocation'] ?? '',
      intermediateStops: (map['intermediateStops'] as List<dynamic>?)
              ?.map((stop) => BusStop.fromMap(stop))
              .toList() ??
          [],
      estimatedDuration: map['estimatedDuration'] ?? '',
      distance: (map['distance'] ?? 0).toDouble(),
      baseFare: (map['baseFare'] ?? 50.0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'intermediateStops': intermediateStops.map((stop) => stop.toMap()).toList(),
      'estimatedDuration': estimatedDuration,
      'distance': distance,
      'baseFare': baseFare,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  BusRoute copyWith({
    String? id,
    String? routeName,
    String? pickupLocation,
    String? dropLocation,
    List<BusStop>? intermediateStops,
    String? estimatedDuration,
    double? distance,
    double? baseFare,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      intermediateStops: intermediateStops ?? this.intermediateStops,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      distance: distance ?? this.distance,
      baseFare: baseFare ?? this.baseFare,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BusStop {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String estimatedTime; // e.g., "10:30 AM"
  final int order; // Stop order in the route
  final double fare; // Fare from THIS stop to the destination (₹)

  BusStop({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedTime,
    required this.order,
    this.fare = 0.0,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      estimatedTime: map['estimatedTime'] ?? '',
      order: map['order'] ?? 0,
      fare: (map['fare'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedTime': estimatedTime,
      'order': order,
      'fare': fare,
    };
  }

  BusStop copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? estimatedTime,
    int? order,
    double? fare,
  }) {
    return BusStop(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      order: order ?? this.order,
      fare: fare ?? this.fare,
    );
  }
}