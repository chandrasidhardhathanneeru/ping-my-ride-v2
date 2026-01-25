

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_type.dart';
import '../../core/models/bus.dart';
import '../../core/models/bus_route.dart';
import '../../core/models/booking.dart';
import '../../core/services/bus_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_page.dart';
import '../payment/payment_page.dart';
import '../admin/management_page.dart';
import '../admin/bus_timing_page.dart';
import '../admin/analytics_page.dart';

class HomePage extends StatefulWidget {
  final UserType userType;

  const HomePage({super.key, required this.userType});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showWelcomeCard = true;

  @override
  void initState() {
    super.initState();
    // Initialize bus service data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusService>(context, listen: false).initialize();
    });
    
    // Hide welcome card after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcomeCard = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userType.label} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'theme') {
                    await themeService.toggleTheme();
                  } else if (value == 'logout') {
                    await _showLogoutConfirmationDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          themeService.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                        ),
                        const SizedBox(width: 8),
                        Text(themeService.isDarkMode ? 'Light Mode' : 'Dark Mode'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: widget.userType == UserType.student 
        ? _buildStudentDashboard() 
        : _buildOtherUserDashboard(),
    );
  }

  Widget _buildStudentDashboard() {
    return Consumer<BusService>(
      builder: (context, busService, child) {
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _showWelcomeCard ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: _showWelcomeCard ? _buildWelcomeCard() : const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: _showWelcomeCard ? 16 : 0),
            Expanded(
              child: _buildAvailableBusesTab(busService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableBusesTab(BusService busService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Buses',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await busService.fetchBuses();
                  await busService.fetchRoutes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bus data refreshed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh bus data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: busService.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : busService.buses.isEmpty
                ? const Center(
                    child: Text(
                      'No buses available at the moment.\nPlease check back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: busService.buses.length,
                    itemBuilder: (context, index) {
                      final bus = busService.buses[index];
                      final route = busService.getRouteById(bus.routeId);
                      return _buildBusCard(bus, route, busService);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsTab(BusService busService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Bookings (${busService.confirmedBookings.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await busService.fetchUserBookings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookings refreshed - Found ${busService.confirmedBookings.length} bookings'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh bookings',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: busService.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : busService.confirmedBookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No bookings yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Book a bus to see your tickets here',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => busService.fetchUserBookings(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: busService.confirmedBookings.length,
                    itemBuilder: (context, index) {
                      final booking = busService.confirmedBookings[index];
                      return _buildBookingCard(booking, busService);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherUserDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _showWelcomeCard ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _showWelcomeCard ? _buildWelcomeCard() : const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: _showWelcomeCard ? 24 : 8),
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _getQuickActions(widget.userType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are logged in as ${widget.userType.label}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(Bus bus, BusRoute? route, BusService busService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bus.busNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bus.capacity} seats',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (route != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.routeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${route.estimatedDuration} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.person_outline, 
                  size: 18, 
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  'Driver: ${bus.driverName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showBookingConfirmationDialog(bus, route, busService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, BusService busService) {
    final bus = busService.getBusById(booking.busId);
    final route = bus != null ? busService.getRouteById(bus.routeId) : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bus?.busNumber ?? 'Unknown Bus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toString().split('.').last.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (route != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.routeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${route.estimatedDuration} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today, 
                  size: 18, 
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  'Booked: ${_formatDate(booking.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (booking.selectedBookingDate != null || booking.selectedTimeSlot != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.selectedBookingDate != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDateOnly(booking.selectedBookingDate!)} (${_getDayOfWeek(booking.selectedBookingDate!.weekday)})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (booking.selectedTimeSlot != null) const SizedBox(height: 6),
                    ],
                    if (booking.selectedTimeSlot != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            booking.selectedTimeSlot!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelBookingDialog(booking, busService),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingConfirmationDialog(Bus bus, BusRoute? route, BusService busService) {
    // First show time slot selection
    _showTimeSlotSelectionDialog(bus, route, busService);
  }

  void _showTimeSlotSelectionDialog(Bus bus, BusRoute? route, BusService busService) {
    final busTiming = busService.getTimingByBusId(bus.id);
    
    if (busTiming == null || busTiming.timings.isEmpty) {
      // No timings available, show error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Timings Available'),
            content: const Text('This bus does not have any scheduled timings. Please contact the administrator or try a different bus.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedTimeSlot;
        
        // Normalize date to remove time component
        DateTime normalizeDate(DateTime date) {
          return DateTime(date.year, date.month, date.day);
        }
        
        DateTime selectedDate = normalizeDate(DateTime.now());
        
        // Get available dates (next 14 days that match the bus schedule)
        List<DateTime> getAvailableDates() {
          List<DateTime> dates = [];
          DateTime current = normalizeDate(DateTime.now());
          for (int i = 0; i < 14; i++) {
            DateTime date = current.add(Duration(days: i));
            String dayName = _getDayOfWeek(date.weekday);
            if (busTiming.daysOfWeek.contains(dayName)) {
              dates.add(date);
            }
          }
          return dates;
        }
        
        // Get already booked time slots for the selected date
        Set<String> getBookedTimeSlotsForDate(DateTime date) {
          final normalizedDate = normalizeDate(date);
          final bookedSlots = <String>{};
          
          for (var booking in busService.confirmedBookings) {
            if (booking.busId == bus.id && 
                booking.selectedBookingDate != null &&
                booking.selectedTimeSlot != null) {
              final bookingDate = normalizeDate(booking.selectedBookingDate!);
              if (bookingDate == normalizedDate) {
                bookedSlots.add(booking.selectedTimeSlot!);
              }
            }
          }
          
          return bookedSlots;
        }
        
        final availableDates = getAvailableDates();
        
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedDayName = _getDayOfWeek(selectedDate.weekday);
            final isBusRunningOnSelectedDay = busTiming.daysOfWeek.contains(selectedDayName);
            final bookedTimeSlots = getBookedTimeSlotsForDate(selectedDate);
            final availableTimings = busTiming.timings
                .where((timing) => !bookedTimeSlots.contains(timing.time))
                .toList();
            
            return AlertDialog(
              title: const Text('Select Date & Time'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus: ${bus.busNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (route != null) ...[
                      Text('Route: ${route.routeName}'),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Select Date:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime>(
                          isExpanded: true,
                          value: selectedDate,
                          items: availableDates.map((date) {
                            return DropdownMenuItem<DateTime>(
                              value: date,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: _isToday(date) ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatDateOnly(date)} (${_getDayOfWeek(date.weekday)})',
                                    style: TextStyle(
                                      fontWeight: _isToday(date) ? FontWeight.bold : FontWeight.normal,
                                      color: _isToday(date) ? AppTheme.primaryColor : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (DateTime? newDate) {
                            if (newDate != null) {
                              setState(() {
                                selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
                                selectedTimeSlot = null; // Reset time slot when date changes
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isBusRunningOnSelectedDay) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bus not scheduled for $selectedDayName',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Operating Days:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(busTiming.daysOfWeek.join(', ')),
                    const SizedBox(height: 16),
                    Text(
                      'Available Time Slots:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (availableTimings.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No available time slots for this date. You have already booked all available slots.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...availableTimings.map((timing) {
                      final isSelected = selectedTimeSlot == timing.time;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected 
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : null,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedTimeSlot = timing.time;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timing.time,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected ? AppTheme.primaryColor : null,
                                        ),
                                      ),
                                      if (timing.stopName.isNotEmpty)
                                        Text(
                                          timing.stopName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    ],
                    if (bookedTimeSlots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Already Booked:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...bookedTimeSlots.map((timeSlot) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    timeSlot,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                Text(
                                  'BOOKED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Booking Fee: ₹50.00'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedTimeSlot == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _showFinalBookingConfirmation(bus, route, busService, selectedTimeSlot!, selectedDate);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTimeSlot == null ? Colors.grey : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFinalBookingConfirmation(Bus bus, BusRoute? route, BusService busService, String selectedTimeSlot, DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bus: ${bus.busNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (route != null) ...[
                  Text('Route: ${route.routeName}'),
                  Text('Duration: ${route.estimatedDuration} min'),
                  const SizedBox(height: 8),
                ],
                Text('Driver: ${bus.driverName}'),
                Text('Available Seats: ${bus.availableSeats}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Booking Date',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDateOnly(selectedDate)} (${_getDayOfWeek(selectedDate.weekday)})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pickup Time',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedTimeSlot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Booking Fee: ₹50.00', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Proceed to payment to confirm your booking.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPayment(bus, route, selectedTimeSlot, selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Proceed to Payment'),
            ),
          ],
        );
      },
    );
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showCancelBookingDialog(Booking booking, BusService busService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelBooking(booking, busService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToPayment(Bus bus, BusRoute? route, String selectedTimeSlot, DateTime selectedDate) async {
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route information not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          bus: bus, 
          route: route,
          selectedTimeSlot: selectedTimeSlot,
          selectedDate: selectedDate,
        ),
      ),
    );

    if (result == true) {
      // Payment successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Check your bookings page.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _bookBus(Bus bus, BusService busService, String selectedTimeSlot, DateTime selectedDate) async {
    final route = busService.getRouteById(bus.routeId);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route information not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _showLoadingDialog('Booking bus...');
    
    try {
      final success = await busService.bookBus(
        bus, 
        route, 
        selectedTimeSlot: selectedTimeSlot,
        selectedBookingDate: selectedDate,
      );
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully booked ${bus.busNumber}! Check your bookings page.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a booking for this bus on the selected date and time slot.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book bus: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelBooking(Booking booking, BusService busService) async {
    _showLoadingDialog('Cancelling booking...');
    
    try {
      await busService.cancelBooking(booking);
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      _showLoadingDialog('Logging out...');
      await Provider.of<AuthService>(context, listen: false).logout();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Widget> _getQuickActions(UserType userType) {
    switch (userType) {
      case UserType.student:
        return [
          _buildActionCard('Track Bus', Icons.location_on, Colors.blue, () {}),
          _buildActionCard('Bus Schedule', Icons.schedule, Colors.green, () {}),
          _buildActionCard('Notifications', Icons.notifications, Colors.orange, () {}),
          _buildActionCard('Profile', Icons.person, Colors.purple, () {}),
        ];
      case UserType.driver:
        return [
          _buildActionCard('Start Route', Icons.play_arrow, Colors.green, () {}),
          _buildActionCard('Route Info', Icons.route, Colors.blue, () {}),
          _buildActionCard('Students', Icons.group, Colors.orange, () {}),
          _buildActionCard('Reports', Icons.assessment, Colors.purple, () {}),
        ];
      case UserType.admin:
        return [
          _buildActionCard('Manage Buses', Icons.directions_bus, Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManagementPage(initialTab: 0)),
            );
          }),
          _buildActionCard('Manage Routes', Icons.alt_route, Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManagementPage(initialTab: 1)),
            );
          }),
          _buildActionCard('Bus Timings', Icons.schedule, Colors.orange, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BusTimingPage()),
            );
          }),
          _buildActionCard('Analytics', Icons.analytics, Colors.purple, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsPage()),
            );
          }),
          _buildActionCard('Refresh Data', Icons.refresh, Colors.teal, () async {
            final busService = Provider.of<BusService>(context, listen: false);
            await busService.initialize();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data refreshed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }),
          _buildActionCard('System Info', Icons.info_outline, Colors.indigo, () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('System Information'),
                content: Consumer<BusService>(
                  builder: (context, busService, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Buses: ${busService.buses.length}'),
                        Text('Active Buses: ${busService.buses.where((b) => b.isActive).length}'),
                        Text('Total Routes: ${busService.routes.length}'),
                        Text('Bus Timings: ${busService.busTimings.length}'),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'PingMyRide v1.0.0',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }),
        ];
    }
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      )
        );
  }
}