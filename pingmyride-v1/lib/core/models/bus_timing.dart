class BusTiming {
  final String id;
  final String busId;
  final String routeId;
  final List<TimingEntry> timings;
  final List<String> daysOfWeek; // ['Monday', 'Tuesday', etc.]
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusTiming({
    required this.id,
    required this.busId,
    required this.routeId,
    required this.timings,
    required this.daysOfWeek,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusTiming.fromMap(Map<String, dynamic> map, String id) {
    return BusTiming(
      id: id,
      busId: map['busId'] ?? '',
      routeId: map['routeId'] ?? '',
      timings: (map['timings'] as List<dynamic>?)
              ?.map((timing) => TimingEntry.fromMap(timing))
              .toList() ??
          [],
      daysOfWeek: List<String>.from(map['daysOfWeek'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'routeId': routeId,
      'timings': timings.map((timing) => timing.toMap()).toList(),
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  BusTiming copyWith({
    String? id,
    String? busId,
    String? routeId,
    List<TimingEntry>? timings,
    List<String>? daysOfWeek,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusTiming(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      timings: timings ?? this.timings,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimingEntry {
  final String stopName; // Could be 'Pickup' or a stop name
  final String time; // e.g., "08:30 AM"
  final int order; // Order of the timing entry

  TimingEntry({
    required this.stopName,
    required this.time,
    required this.order,
  });

  factory TimingEntry.fromMap(Map<String, dynamic> map) {
    return TimingEntry(
      stopName: map['stopName'] ?? '',
      time: map['time'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'time': time,
      'order': order,
    };
  }

  TimingEntry copyWith({
    String? stopName,
    String? time,
    int? order,
  }) {
    return TimingEntry(
      stopName: stopName ?? this.stopName,
      time: time ?? this.time,
      order: order ?? this.order,
    );
  }
}
