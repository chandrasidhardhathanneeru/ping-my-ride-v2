import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/bus.dart';
import '../../core/models/bus_route.dart';
import '../../core/models/booking.dart';
import '../../core/models/trip_qr.dart';
import '../../core/services/bus_service.dart';
import '../../core/services/trip_qr_service.dart';
import '../../core/theme/app_theme.dart';

enum StudentFilter { all, scanned, notScanned }

/// Driver page to view students who booked the bus
class DriverStudentListPage extends StatefulWidget {
  final Bus bus;
  final BusRoute route;

  const DriverStudentListPage({
    super.key,
    required this.bus,
    required this.route,
  });

  @override
  State<DriverStudentListPage> createState() => _DriverStudentListPageState();
}

class _DriverStudentListPageState extends State<DriverStudentListPage> {
  StudentFilter _selectedFilter = StudentFilter.all;
  String? _selectedTimeSlot;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer2<BusService, TripQRService>(
        builder: (context, busService, tripQRService, child) {
          final busTiming = busService.getTimingByBusId(widget.bus.id);
          
          return Column(
            children: [
              _buildHeader(),
              _buildTimeSlotSelector(busTiming, busService),
              _buildFilterChips(tripQRService),
              Expanded(
                child: _buildStudentList(busService, tripQRService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bus.busNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.route.routeName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelector(dynamic busTiming, BusService busService) {
    if (busTiming == null || busTiming.timings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text('No time slots available'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select Time Slot',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTimeSlotChip('All', null, busService),
              ...busTiming.timings.map<Widget>((timing) {
                return _buildTimeSlotChip(timing.time, timing.time, busService);
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(String label, String? value, BusService busService) {
    final isSelected = _selectedTimeSlot == value;
    
    // Count bookings for this time slot
    final bookingsCount = value == null
        ? _getBookingsForDate(busService).length
        : _getBookingsForDate(busService)
            .where((b) => b.selectedTimeSlot == value)
            .length;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$bookingsCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeSlot = value;
        });
      },
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterChips(TripQRService tripQRService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: StudentFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = _getFilterCount(filter, tripQRService);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getFilterLabel(filter)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(BusService busService, TripQRService tripQRService) {
    final filteredBookings = _getFilteredBookings(busService, tripQRService);

    if (filteredBookings.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        final hasScanned = _hasStudentScanned(booking, tripQRService);
        
        return _buildStudentCard(booking, hasScanned);
      },
    );
  }

  Widget _buildStudentCard(Booking booking, bool hasScanned) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasScanned
                    ? Colors.green.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasScanned ? Icons.check_circle : Icons.person,
                color: hasScanned
                    ? Colors.green
                    : Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.userId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.selectedTimeSlot ?? 'No time slot',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.pickupLocation,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasScanned
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasScanned ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasScanned ? Icons.done : Icons.pending,
                    size: 14,
                    color: hasScanned ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasScanned ? 'Boarded' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasScanned ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case StudentFilter.scanned:
        return 'No students have scanned the QR code yet';
      case StudentFilter.notScanned:
        return 'All students have boarded the bus';
      case StudentFilter.all:
        return 'No bookings for the selected date and time';
    }
  }

  List<Booking> _getBookingsForDate(BusService busService) {
    return busService.confirmedBookings.where((booking) {
      if (booking.busId != widget.bus.id) return false;
      if (booking.selectedBookingDate == null) return false;
      
      final bookingDate = booking.selectedBookingDate!;
      return bookingDate.year == _selectedDate.year &&
          bookingDate.month == _selectedDate.month &&
          bookingDate.day == _selectedDate.day;
    }).toList();
  }

  List<Booking> _getFilteredBookings(BusService busService, TripQRService tripQRService) {
    var bookings = _getBookingsForDate(busService);

    // Filter by time slot
    if (_selectedTimeSlot != null) {
      bookings = bookings.where((b) => b.selectedTimeSlot == _selectedTimeSlot).toList();
    }

    // Filter by scan status
    switch (_selectedFilter) {
      case StudentFilter.scanned:
        bookings = bookings.where((b) => _hasStudentScanned(b, tripQRService)).toList();
        break;
      case StudentFilter.notScanned:
        bookings = bookings.where((b) => !_hasStudentScanned(b, tripQRService)).toList();
        break;
      case StudentFilter.all:
        break;
    }

    // Sort by time slot
    bookings.sort((a, b) {
      final timeA = a.selectedTimeSlot ?? '';
      final timeB = b.selectedTimeSlot ?? '';
      return timeA.compareTo(timeB);
    });

    return bookings;
  }

  bool _hasStudentScanned(Booking booking, TripQRService tripQRService) {
    // Find active trip QR for this time slot and date
    final tripQR = tripQRService.driverTripQRs.firstWhere(
      (qr) =>
          qr.busId == widget.bus.id &&
          qr.timeSlot == booking.selectedTimeSlot &&
          qr.travelDate.year == _selectedDate.year &&
          qr.travelDate.month == _selectedDate.month &&
          qr.travelDate.day == _selectedDate.day,
      orElse: () => TripQR(
        id: '',
        busId: '',
        busNumber: '',
        driverId: '',
        driverName: '',
        routeId: '',
        routeName: '',
        travelDate: DateTime.now(),
        timeSlot: '',
        qrCode: '',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
        scannedByUsers: const [],
      ),
    );

    if (tripQR.id.isEmpty) return false;

    return tripQR.scannedByUsers.contains(booking.userId);
  }

  int _getFilterCount(StudentFilter filter, TripQRService tripQRService) {
    final busService = Provider.of<BusService>(context, listen: false);
    var bookings = _getBookingsForDate(busService);

    if (_selectedTimeSlot != null) {
      bookings = bookings.where((b) => b.selectedTimeSlot == _selectedTimeSlot).toList();
    }

    switch (filter) {
      case StudentFilter.all:
        return bookings.length;
      case StudentFilter.scanned:
        return bookings.where((b) => _hasStudentScanned(b, tripQRService)).length;
      case StudentFilter.notScanned:
        return bookings.where((b) => !_hasStudentScanned(b, tripQRService)).length;
    }
  }

  String _getFilterLabel(StudentFilter filter) {
    switch (filter) {
      case StudentFilter.all:
        return 'All';
      case StudentFilter.scanned:
        return 'Boarded';
      case StudentFilter.notScanned:
        return 'Pending';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showFilterDialog() {
    // Additional filtering options can be added here
  }
}
