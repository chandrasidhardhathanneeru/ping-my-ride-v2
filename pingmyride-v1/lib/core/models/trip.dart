/// Trip model - represents a scheduled bus trip on a specific date
/// This allows admin to create multiple trips per bus (e.g., morning, evening)
class Trip {
  final String id;
  final String busId;
  final String routeId;
  final String busNumber; // Denormalized for easier display
  final String routeName; // Denormalized for easier display
  final DateTime tripDate; // Date of the trip
  final String departureTime; // e.g., "08:30 AM"
  final int totalSeats;
  final int bookedSeats;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.busId,
    required this.routeId,
    required this.busNumber,
    required this.routeName,
    required this.tripDate,
    required this.departureTime,
    required this.totalSeats,
    this.bookedSeats = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  int get availableSeats => totalSeats - bookedSeats;
  bool get hasAvailableSeats => availableSeats > 0;

  factory Trip.fromMap(Map<String, dynamic> map, String id) {
    return Trip(
      id: id,
      busId: map['busId'] ?? '',
      routeId: map['routeId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeName: map['routeName'] ?? '',
      tripDate: map['tripDate']?.toDate() ?? DateTime.now(),
      departureTime: map['departureTime'] ?? '',
      totalSeats: map['totalSeats'] ?? 0,
      bookedSeats: map['bookedSeats'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'routeId': routeId,
      'busNumber': busNumber,
      'routeName': routeName,
      'tripDate': tripDate,
      'departureTime': departureTime,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Trip copyWith({
    String? id,
    String? busId,
    String? routeId,
    String? busNumber,
    String? routeName,
    DateTime? tripDate,
    String? departureTime,
    int? totalSeats,
    int? bookedSeats,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      busNumber: busNumber ?? this.busNumber,
      routeName: routeName ?? this.routeName,
      tripDate: tripDate ?? this.tripDate,
      departureTime: departureTime ?? this.departureTime,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
