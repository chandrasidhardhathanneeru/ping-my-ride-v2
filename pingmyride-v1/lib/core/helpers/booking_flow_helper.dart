import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../services/bus_service.dart';
import '../theme/app_theme.dart';
import '../../features/bookings/seat_selection_page.dart';
import '../../features/payment/payment_page.dart';

/// Shared booking flow: time-slot dialog → seat selection → confirmation → payment.
/// Call [BookingFlowHelper.start] from any page to launch the full flow.
class BookingFlowHelper {
  BookingFlowHelper._();

  static void start(
    BuildContext context,
    Bus bus,
    BusRoute? route,
  ) {
    final busService = Provider.of<BusService>(context, listen: false);
    _showTimeSlotDialog(context, bus, route, busService);
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  static String _dayOfWeek(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday >= 1 && weekday <= 7 ? days[weekday] : 'Unknown';
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── step 1: time-slot dialog ─────────────────────────────────────────────────

  static void _showTimeSlotDialog(
    BuildContext context,
    Bus bus,
    BusRoute? route,
    BusService busService,
  ) {
    final busTiming = busService.getTimingByBusId(bus.id);

    if (busTiming == null || busTiming.timings.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Timings Available'),
          content: const Text(
              'This bus has no scheduled timings. Please contact the administrator or try a different bus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Build list of available dates (next 14 days matching schedule)
    List<DateTime> buildAvailableDates() {
      final dates = <DateTime>[];
      final now = _normalize(DateTime.now());
      for (int i = 0; i < 14; i++) {
        final date = now.add(Duration(days: i));
        if (busTiming.daysOfWeek.contains(_dayOfWeek(date.weekday))) {
          dates.add(date);
        }
      }
      return dates;
    }

    Set<String> bookedSlotsFor(DateTime date) {
      final nd = _normalize(date);
      final slots = <String>{};
      for (final b in busService.confirmedBookings) {
        if (b.busId == bus.id &&
            b.selectedBookingDate != null &&
            b.selectedTimeSlot != null) {
          if (_normalize(b.selectedBookingDate!) == nd) {
            slots.add(b.selectedTimeSlot!);
          }
        }
      }
      return slots;
    }

    final availableDates = buildAvailableDates();
    DateTime selectedDate =
        availableDates.isNotEmpty ? availableDates.first : _normalize(DateTime.now());
    String? selectedTimeSlot;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final dayName = _dayOfWeek(selectedDate.weekday);
            final running = busTiming.daysOfWeek.contains(dayName);
            final bookedSlots = bookedSlotsFor(selectedDate);
            final available =
                busTiming.timings.where((t) => !bookedSlots.contains(t.time)).toList();

            return AlertDialog(
              title: const Text('Select Date & Time'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus: ${bus.busNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (route != null) ...[
                      Text('Route: ${route.routeName}'),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Select Date:',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
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
                                  Icon(Icons.calendar_today,
                                      size: 16,
                                      color: _isToday(date)
                                          ? AppTheme.primaryColor
                                          : Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatDate(date)} (${_dayOfWeek(date.weekday)})',
                                    style: TextStyle(
                                      fontWeight: _isToday(date)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _isToday(date)
                                          ? AppTheme.primaryColor
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (DateTime? newDate) {
                            if (newDate != null) {
                              setState(() {
                                selectedDate =
                                    _normalize(newDate);
                                selectedTimeSlot = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!running) ...[
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
                                'Bus not scheduled for $dayName',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('Operating Days:',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(busTiming.daysOfWeek.join(', ')),
                    const SizedBox(height: 16),
                    Text('Available Time Slots:',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (available.isEmpty) ...[
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
                                'No available time slots for this date.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...available.map((timing) {
                        final isSelected = selectedTimeSlot == timing.time;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : null,
                          child: InkWell(
                            onTap: () =>
                                setState(() => selectedTimeSlot = timing.time),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          timing.time,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : null,
                                          ),
                                        ),
                                        if (timing.stopName.isNotEmpty)
                                          Text(
                                            timing.stopName,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
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
                    if (bookedSlots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Already Booked:',
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ...bookedSlots.map((slot) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(slot,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          decoration:
                                              TextDecoration.lineThrough,
                                        )),
                                  ),
                                  Text('BOOKED',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          )),
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedTimeSlot == null
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                          _showBoardingStopDialog(
                            context,
                            bus,
                            route,
                            busService,
                            selectedTimeSlot!,
                            selectedDate,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedTimeSlot == null
                        ? Colors.grey
                        : AppTheme.primaryColor,
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

  // ── step 1b: boarding stop selection ──────────────────────────────────────

  static void _showBoardingStopDialog(
    BuildContext context,
    Bus bus,
    BusRoute? route,
    BusService busService,
    String selectedTimeSlot,
    DateTime selectedDate,
  ) {
    // Build stop list: start + intermediate stops (sorted by order)
    final stops = <_StopChoice>[];
    if (route != null) {
      stops.add(_StopChoice(
        name: route.pickupLocation,
        time: selectedTimeSlot,
        fare: route.baseFare,
        isStart: true,
      ));
      final sorted = List.of(route.intermediateStops)
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final s in sorted) {
        stops.add(_StopChoice(
          name: s.name,
          time: s.estimatedTime,
          fare: s.fare > 0 ? s.fare : route.baseFare,
        ));
      }
    } else {
      // No route info — skip straight to seat selection
      _goToSeatSelection(context, bus, route, busService, selectedTimeSlot,
          selectedDate, route?.pickupLocation, route?.baseFare);
      return;
    }

    // If only the start point exists (no intermediate stops), skip this dialog
    if (stops.length == 1) {
      _goToSeatSelection(context, bus, route, busService, selectedTimeSlot,
          selectedDate, stops[0].name, stops[0].fare);
      return;
    }

    String selectedStop = stops[0].name;
    double selectedFare = stops[0].fare;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Select Boarding Stop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose where you will board the bus',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ...stops.map((stop) {
                  final isSelected = selectedStop == stop.name;
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedStop = stop.name;
                      selectedFare = stop.fare;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (stop.isStart)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'START',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        stop.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stop.time,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '\u20b9${stop.fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _goToSeatSelection(context, bus, route, busService,
                    selectedTimeSlot, selectedDate, selectedStop, selectedFare);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  // ── step 2: seat selection ───────────────────────────────────────────────────

  static Future<void> _goToSeatSelection(
    BuildContext context,
    Bus bus,
    BusRoute? route,
    BusService busService,
    String selectedTimeSlot,
    DateTime selectedDate,
    String? boardingStop,
    double? fare,
  ) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionPage(
          bus: bus,
          route: route,
          selectedTimeSlot: selectedTimeSlot,
          selectedBookingDate: selectedDate,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      _showFinalConfirmation(
        context,
        bus,
        route,
        busService,
        selectedTimeSlot,
        selectedDate,
        result['seat']?.seatNumber as String?,
        result['gender'] as String?,
        boardingStop,
        fare,
      );
    }
  }

  // ── step 3: final confirmation ───────────────────────────────────────────────

  static void _showFinalConfirmation(
    BuildContext context,
    Bus bus,
    BusRoute? route,
    BusService busService,
    String selectedTimeSlot,
    DateTime selectedDate, [
    String? seatNumber,
    String? gender,
    String? boardingStop,
    double? fare,
  ]) {
    final effectiveFare = fare ?? route?.baseFare ?? 50.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bus: ${bus.busNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (route != null) ...[
                Text('Route: ${route.routeName}'),
                Text('Duration: ${route.estimatedDuration}'),
                const SizedBox(height: 8),
              ],
              Text('Driver: ${bus.driverName}'),
              Text('Available Seats: ${bus.availableSeats}'),
              if (boardingStop != null) ...[                
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Boarding: $boardingStop',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
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
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Booking Date',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(selectedDate)} (${_dayOfWeek(selectedDate.weekday)})',
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
                        const Icon(Icons.access_time,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup Time',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
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
                          const Icon(Icons.airline_seat_recline_normal,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Seat Number',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
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
              Text('Fare: ₹${effectiveFare.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _goToPayment(context, bus, route, selectedTimeSlot, selectedDate,
                  seatNumber, gender, boardingStop, effectiveFare);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  // ── step 4: payment page ─────────────────────────────────────────────────────

  static Future<void> _goToPayment(
    BuildContext context,
    Bus bus,
    BusRoute? route,
    String selectedTimeSlot,
    DateTime selectedDate, [
    String? seatNumber,
    String? gender,
    String? boardingStop,
    double? fare,
  ]) async {
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route information not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          bus: bus,
          route: route,
          selectedTimeSlot: selectedTimeSlot,
          selectedDate: selectedDate,
          seatNumber: seatNumber,
          gender: gender,
          boardingStop: boardingStop,
          fare: fare,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Check your bookings page.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Internal model for representing a boarding stop choice in the selection dialog.
class _StopChoice {
  final String name;
  final String time;
  final double fare;
  final bool isStart;

  _StopChoice({
    required this.name,
    required this.time,
    required this.fare,
    this.isStart = false,
  });
}
