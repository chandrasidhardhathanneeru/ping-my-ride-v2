import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/bus.dart';
import '../../core/models/bus_route.dart';
import '../../core/models/trip_qr.dart';
import '../../core/services/bus_service.dart';
import '../../core/services/trip_qr_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_manager.dart';
import '../../core/theme/app_theme.dart';
import 'driver_trip_qr_page.dart';
import 'driver_student_list_page.dart';

/// Main driver home page with route management
class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final busService = Provider.of<BusService>(context, listen: false);
    final tripQRService = Provider.of<TripQRService>(context, listen: false);
    
    await busService.initialize();
    await tripQRService.fetchDriverTripQRs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<BusService, TripQRService>(
        builder: (context, busService, tripQRService, child) {
          if (busService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get driver's buses
          final authService = Provider.of<AuthService>(context, listen: false);
          final driverEmail = authService.currentUser?.email;
          
          final driverBuses = busService.buses
              .where((bus) => bus.driverEmail == driverEmail && bus.isActive)
              .toList();

          if (driverBuses.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWelcomeCard(driverBuses.first),
                const SizedBox(height: 24),
                _buildActiveTripSection(tripQRService),
                const SizedBox(height: 24),
                _buildBusesSection(driverBuses, busService, tripQRService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bus assigned',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact admin to get assigned to a bus',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(Bus bus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Bus',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bus.busNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.airline_seat_recline_normal, '${bus.capacity} seats'),
              const SizedBox(width: 12),
              _buildInfoChip(
                bus.isActive ? Icons.check_circle : Icons.cancel,
                bus.isActive ? 'Active' : 'Inactive',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripSection(TripQRService tripQRService) {
    final activeTrips = tripQRService.activeTripQRs;

    if (activeTrips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Trips',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...activeTrips.map((trip) => _buildActiveTripCard(trip)),
      ],
    );
  }

  Widget _buildActiveTripCard(TripQR tripQR) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTripQRPage(tripQR: tripQR),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripQR.routeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tripQR.timeSlot,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tripQR.scannedCount} boarded',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(tripQR.travelDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${DateFormat('h:mm a').format(tripQR.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusesSection(
    List<Bus> buses,
    BusService busService,
    TripQRService tripQRService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Routes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...buses.map((bus) => _buildBusCard(bus, busService, tripQRService)),
      ],
    );
  }

  Widget _buildBusCard(
    Bus bus,
    BusService busService,
    TripQRService tripQRService,
  ) {
    final route = busService.getRouteById(bus.routeId);
    final busTiming = busService.getTimingByBusId(bus.id);
    final nextTimeSlot = _getNextTimeSlot(busTiming);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (route != null)
                        Text(
                          route.routeName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (nextTimeSlot != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Time Slot',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextTimeSlot['time'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          if (nextTimeSlot['stopName'] != null && nextTimeSlot['stopName'].isNotEmpty)
                            Text(
                              nextTimeSlot['stopName'],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${nextTimeSlot['bookings']} students',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No upcoming time slots for today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: nextTimeSlot != null
                        ? () => _startRoute(bus, route, nextTimeSlot, busService, tripQRService)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStudents(bus, route, busService),
                    icon: const Icon(Icons.people),
                    label: const Text('Students'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getNextTimeSlot(dynamic busTiming) {
    if (busTiming == null || busTiming.timings.isEmpty) return null;

    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    final currentDayName = _getDayOfWeek(now.weekday);

    // Check if bus operates today
    if (!busTiming.daysOfWeek.contains(currentDayName)) {
      return null;
    }

    // Find next time slot
    for (var timing in busTiming.timings) {
      final timeParts = timing.time.split(':');
      if (timeParts.length < 2) continue;

      try {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1].split(' ')[0]);
        final isPM = timing.time.toUpperCase().contains('PM');
        
        final timeHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
        final timeSlot = TimeOfDay(hour: timeHour, minute: minute);

        if (_isTimeAfter(timeSlot, currentTime)) {
          // Get bookings count for this time slot
          final busService = Provider.of<BusService>(context, listen: false);
          final bookingsCount = busService.confirmedBookings
              .where((b) =>
                  b.busId == busTiming.busId &&
                  b.selectedTimeSlot == timing.time &&
                  b.selectedBookingDate != null &&
                  _isToday(b.selectedBookingDate!))
              .length;

          return {
            'time': timing.time,
            'stopName': timing.stopName,
            'bookings': bookingsCount,
          };
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) return true;
    if (time1.hour < time2.hour) return false;
    return time1.minute > time2.minute;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Future<void> _startRoute(
    Bus bus,
    BusRoute? route,
    Map<String, dynamic> timeSlot,
    BusService busService,
    TripQRService tripQRService,
  ) async {
    if (route == null) return;

    // Check if QR already exists for this time slot today
    final existingQR = tripQRService.driverTripQRs.firstWhere(
      (qr) =>
          qr.busId == bus.id &&
          qr.timeSlot == timeSlot['time'] &&
          _isToday(qr.travelDate) &&
          qr.isActive,
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
        isActive: false,
      ),
    );

    if (existingQR.id.isNotEmpty) {
      // QR already exists, navigate to it
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverTripQRPage(tripQR: existingQR),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bus: ${bus.busNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Route: ${route.routeName}'),
            const SizedBox(height: 8),
            Text('Time: ${timeSlot['time']}'),
            const SizedBox(height: 8),
            Text('Students: ${timeSlot['bookings']}'),
            const SizedBox(height: 16),
            const Text('This will generate a QR code for students to scan and board the bus.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Generate QR code
    final tripQR = await tripQRService.generateTripQR(
      busId: bus.id,
      busNumber: bus.busNumber,
      routeId: route.id,
      routeName: route.routeName,
      travelDate: DateTime.now(),
      timeSlot: timeSlot['time'],
    );

    if (tripQR != null && mounted) {
      // Start location tracking when trip begins
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      await locationManager.initialize();
      await locationManager.startTracking(busId: bus.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started! Location tracking is active.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Navigate to QR page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTripQRPage(tripQR: tripQR),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate QR code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewStudents(Bus bus, BusRoute? route, BusService busService) {
    if (route == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverStudentListPage(
          bus: bus,
          route: route,
        ),
      ),
    );
  }
}
