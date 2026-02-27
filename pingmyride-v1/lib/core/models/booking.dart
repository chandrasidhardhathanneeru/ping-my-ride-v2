class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String busId;
  final String routeId;
  final String busNumber;
  final String routeName;
  final DateTime bookingDate;
  final String pickupLocation;
  final String dropLocation;
  final String driverName;
  final String driverPhone;
  final BookingStatus status;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  
  // Time slot details
  final String? selectedTimeSlot; // e.g., "08:30 AM"
  final String? selectedPickupTime; // e.g., "08:30 AM"
  final DateTime? selectedBookingDate; // The date for which the booking is made
  
  // Payment details
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final double? amount;
  
  // Seat details
  final String? seatNumber;
  final String? gender; // 'male' or 'female'
  final String? qrCode; // Generated QR code for the booking

  // New fields for trip-based booking with stops
  final String? tripId; // Reference to trip (if using new system)
  final String? boardingStop; // Boarding point name
  final String? dropStop; // Dropping point name
  final String? boardingTime; // Boarding time
  final String? dropTime; // Drop time

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.busId,
    required this.routeId,
    required this.busNumber,
    required this.routeName,
    required this.bookingDate,
    required this.pickupLocation,
    required this.dropLocation,
    required this.driverName,
    required this.driverPhone,
    this.status = BookingStatus.confirmed,
    this.cancelledAt,
    required this.createdAt,
    this.selectedTimeSlot,
    this.selectedPickupTime,
    this.selectedBookingDate,
    this.paymentId,
    this.orderId,
    this.signature,
    this.amount,
    this.seatNumber,
    this.gender,
    this.qrCode,
    this.tripId,
    this.boardingStop,
    this.dropStop,
    this.boardingTime,
    this.dropTime,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      busId: map['busId'] ?? '',
      routeId: map['routeId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeName: map['routeName'] ?? '',
      bookingDate: map['bookingDate']?.toDate() ?? DateTime.now(),
      pickupLocation: map['pickupLocation'] ?? '',
      dropLocation: map['dropLocation'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      status: BookingStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      cancelledAt: map['cancelledAt']?.toDate(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      selectedTimeSlot: map['selectedTimeSlot'],
      selectedPickupTime: map['selectedPickupTime'],
      selectedBookingDate: map['selectedBookingDate']?.toDate(),
      paymentId: map['paymentId'],
      orderId: map['orderId'],
      tripId: map['tripId'],
      boardingStop: map['boardingStop'],
      dropStop: map['dropStop'],
      boardingTime: map['boardingTime'],
      dropTime: map['dropTime'],
      signature: map['signature'],
      amount: map['amount']?.toDouble(),
      seatNumber: map['seatNumber'],
      gender: map['gender'],
      qrCode: map['qrCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'busId': busId,
      'routeId': routeId,
      'busNumber': busNumber,
      'routeName': routeName,
      'bookingDate': bookingDate,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': status.name,
      'cancelledAt': cancelledAt,
      'createdAt': createdAt,
      'selectedTimeSlot': selectedTimeSlot,
      'selectedPickupTime': selectedPickupTime,
      'selectedBookingDate': selectedBookingDate,
      'paymentId': paymentId,
      'orderId': orderId,
      'tripId': tripId,
      'boardingStop': boardingStop,
      'dropStop': dropStop,
      'boardingTime': boardingTime,
      'dropTime': dropTime,
      'signature': signature,
      'amount': amount,
      'seatNumber': seatNumber,
      'gender': gender,
      'qrCode': qrCode,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? busId,
    String? routeId,
    String? busNumber,
    String? routeName,
    DateTime? bookingDate,
    String? pickupLocation,
    String? dropLocation,
    String? driverName,
    String? driverPhone,
    BookingStatus? status,
    DateTime? cancelledAt,
    DateTime? createdAt,
    String? selectedTimeSlot,
    String? selectedPickupTime,
    DateTime? selectedBookingDate,
    String? paymentId,
    String? orderId,
    String? signature,
    double? amount,
    String? seatNumber,
    String? gender,
    String? qrCode,
    String? tripId,
    String? boardingStop,
    String? dropStop,
    String? boardingTime,
    String? dropTime,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      busNumber: busNumber ?? this.busNumber,
      routeName: routeName ?? this.routeName,
      bookingDate: bookingDate ?? this.bookingDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      status: status ?? this.status,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      selectedPickupTime: selectedPickupTime ?? this.selectedPickupTime,
      selectedBookingDate: selectedBookingDate ?? this.selectedBookingDate,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      signature: signature ?? this.signature,
      amount: amount ?? this.amount,
      seatNumber: seatNumber ?? this.seatNumber,
      gender: gender ?? this.gender,
      qrCode: qrCode ?? this.qrCode,
      tripId: tripId ?? this.tripId,
      boardingStop: boardingStop ?? this.boardingStop,
      dropStop: dropStop ?? this.dropStop,
      boardingTime: boardingTime ?? this.boardingTime,
      dropTime: dropTime ?? this.dropTime,
    );
  }
}

enum BookingStatus {
  confirmed('Confirmed'),
  cancelled('Cancelled'),
  completed('Completed');

  const BookingStatus(this.label);
  final String label;
}