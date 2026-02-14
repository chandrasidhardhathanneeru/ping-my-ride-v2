enum SeatType {
  window,
  aisle,
  middle,
}

enum SeatGender {
  male,
  female,
  empty,
}

class Seat {
  final String seatNumber;
  final SeatType type;
  final bool isBooked;
  final SeatGender? bookedBy; // Gender of person who booked
  final String? userId; // User ID who booked
  final int row;
  final int column;

  Seat({
    required this.seatNumber,
    required this.type,
    this.isBooked = false,
    this.bookedBy,
    this.userId,
    required this.row,
    required this.column,
  });

  Seat copyWith({
    String? seatNumber,
    SeatType? type,
    bool? isBooked,
    SeatGender? bookedBy,
    String? userId,
    int? row,
    int? column,
  }) {
    return Seat(
      seatNumber: seatNumber ?? this.seatNumber,
      type: type ?? this.type,
      isBooked: isBooked ?? this.isBooked,
      bookedBy: bookedBy ?? this.bookedBy,
      userId: userId ?? this.userId,
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seatNumber': seatNumber,
      'type': type.name,
      'isBooked': isBooked,
      'bookedBy': bookedBy?.name,
      'userId': userId,
      'row': row,
      'column': column,
    };
  }

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      seatNumber: map['seatNumber'] ?? '',
      type: SeatType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => SeatType.middle,
      ),
      isBooked: map['isBooked'] ?? false,
      bookedBy: map['bookedBy'] != null
          ? SeatGender.values.firstWhere(
              (g) => g.name == map['bookedBy'],
              orElse: () => SeatGender.empty,
            )
          : null,
      userId: map['userId'],
      row: map['row'] ?? 0,
      column: map['column'] ?? 0,
    );
  }
}
