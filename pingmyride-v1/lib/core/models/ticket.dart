import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  pending('Pending'),
  active('Active'),
  completed('Completed'),
  cancelled('Cancelled');

  const TicketStatus(this.label);
  final String label;
}

class Ticket {
  final String id;
  final String bookingId;
  final String userId;
  final String busId;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String routeId;
  final String routeName;
  final String pickupLocation;
  final String dropLocation;
  final DateTime travelDate;
  final String timeSlot;
  final TicketStatus status;
  final String qrCode; // Unique QR code for this ticket
  final DateTime? scannedAt; // When the QR was scanned
  final String? scannedBy; // Driver who scanned it
  final DateTime createdAt;
  final DateTime? rideStartedAt;
  final DateTime? rideCompletedAt;

  Ticket({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.busId,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.routeId,
    required this.routeName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.travelDate,
    required this.timeSlot,
    this.status = TicketStatus.pending,
    required this.qrCode,
    this.scannedAt,
    this.scannedBy,
    required this.createdAt,
    this.rideStartedAt,
    this.rideCompletedAt,
  });

  factory Ticket.fromMap(Map<String, dynamic> map, String id) {
    return Ticket(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      busId: map['busId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      dropLocation: map['dropLocation'] ?? '',
      travelDate: (map['travelDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      status: TicketStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => TicketStatus.pending,
      ),
      qrCode: map['qrCode'] ?? '',
      scannedAt: (map['scannedAt'] as Timestamp?)?.toDate(),
      scannedBy: map['scannedBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rideStartedAt: (map['rideStartedAt'] as Timestamp?)?.toDate(),
      rideCompletedAt: (map['rideCompletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'busId': busId,
      'busNumber': busNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'routeId': routeId,
      'routeName': routeName,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'travelDate': Timestamp.fromDate(travelDate),
      'timeSlot': timeSlot,
      'status': status.name,
      'qrCode': qrCode,
      'scannedAt': scannedAt != null ? Timestamp.fromDate(scannedAt!) : null,
      'scannedBy': scannedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'rideStartedAt': rideStartedAt != null ? Timestamp.fromDate(rideStartedAt!) : null,
      'rideCompletedAt': rideCompletedAt != null ? Timestamp.fromDate(rideCompletedAt!) : null,
    };
  }

  Ticket copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? busId,
    String? busNumber,
    String? driverName,
    String? driverPhone,
    String? routeId,
    String? routeName,
    String? pickupLocation,
    String? dropLocation,
    DateTime? travelDate,
    String? timeSlot,
    TicketStatus? status,
    String? qrCode,
    DateTime? scannedAt,
    String? scannedBy,
    DateTime? createdAt,
    DateTime? rideStartedAt,
    DateTime? rideCompletedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      travelDate: travelDate ?? this.travelDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedBy: scannedBy ?? this.scannedBy,
      createdAt: createdAt ?? this.createdAt,
      rideStartedAt: rideStartedAt ?? this.rideStartedAt,
      rideCompletedAt: rideCompletedAt ?? this.rideCompletedAt,
    );
  }
}
