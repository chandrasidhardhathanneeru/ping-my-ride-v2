

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
import '../bookings/seat_selection_page.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.displayName ?? 'Student';
    
    return Consumer<BusService>(
      builder: (context, busService, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Book a Ride Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Book a Ride',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildBusRoutesSection(busService),
              
              const SizedBox(height: 24),
              
              // Upcoming Trips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Upcoming Trips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildUpcomingTripsSection(busService),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusRoutesSection(BusService busService) {
    if (busService.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (busService.buses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.directions_bus_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No buses available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please check back later',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: busService.buses.length,
        itemBuilder: (context, index) {
          final bus = busService.buses[index];
          final route = busService.getRouteById(bus.routeId);
          return _buildBusRouteCard(bus, route, busService);
        },
      ),
    );
  }

  Widget _buildBusRouteCard(Bus bus, BusRoute? route, BusService busService) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: bus.hasAvailableSeats
              ? () => _showBookingConfirmationDialog(bus, route, busService)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    // Bus image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        'assets/icons/campus_express.png.png',
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(
                                Icons.directions_bus,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Capacity badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bus.hasAvailableSeats 
                              ? Colors.green 
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bus.hasAvailableSeats 
                              ? '${bus.capacity - bus.bookedSeats} seats' 
                              : 'Full',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bus details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bus.busNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          bus.hasAvailableSeats ? Icons.arrow_forward : Icons.block,
                          size: 18,
                          color: bus.hasAvailableSeats 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                    if (route != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        route.routeName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTripsSection(BusService busService) {
    final upcomingBookings = busService.confirmedBookings
        .where((booking) {
          if (booking.selectedBookingDate == null) return false;
          final bookingDate = booking.selectedBookingDate!;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tripDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          return tripDate.isAtSameMomentAs(today) || tripDate.isAfter(today);
        })
        .take(3)
        .toList();

    if (upcomingBookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No upcoming trips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Book a ride to see your trips here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: upcomingBookings.map((booking) {
        final bus = busService.getBusById(booking.busId);
        final route = bus != null ? busService.getRouteById(bus.routeId) : null;
        return _buildUpcomingTripCard(booking, bus, route);
      }).toList(),
    );
  }

  Widget _buildUpcomingTripCard(Booking booking, Bus? bus, BusRoute? route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route?.routeName ?? 'Route',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(booking.selectedBookingDate!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.selectedTimeSlot ?? 'N/A',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

        final availableDates = getAvailableDates();
        DateTime selectedDate = availableDates.isNotEmpty 
            ? availableDates.first 
            : normalizeDate(DateTime.now());
        
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
                    }),
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
                      }),
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
                        _navigateToSeatSelection(bus, route, busService, selectedTimeSlot!, selectedDate);
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

  Future<void> _navigateToSeatSelection(Bus bus, BusRoute? route, BusService busService, String selectedTimeSlot, DateTime selectedDate) async {
    final seatResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionPage(
          bus: bus,
          route: route,
          selectedTimeSlot: selectedTimeSlot,
          selectedBookingDate: selectedDate,
        ),
      ),
    );

    if (seatResult != null && seatResult is Map<String, dynamic>) {
      // Show final confirmation with seat details
      _showFinalBookingConfirmation(
        bus, 
        route, 
        busService, 
        selectedTimeSlot, 
        selectedDate,
        seatResult['seat']?.seatNumber as String?,
        seatResult['gender'] as String?,
      );
    }
  }

  void _showFinalBookingConfirmation(
    Bus bus, 
    BusRoute? route, 
    BusService busService, 
    String selectedTimeSlot, 
    DateTime selectedDate,
    [String? seatNumber,
    String? gender]
  ) {
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
                      if (seatNumber != null) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.airline_seat_recline_normal, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seat Number',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    seatNumber,
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
                _navigateToPayment(bus, route, selectedTimeSlot, selectedDate, seatNumber, gender);
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

  Future<void> _navigateToPayment(Bus bus, BusRoute? route, String selectedTimeSlot, DateTime selectedDate, [String? seatNumber, String? gender]) async {
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
          seatNumber: seatNumber,
          gender: gender,
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