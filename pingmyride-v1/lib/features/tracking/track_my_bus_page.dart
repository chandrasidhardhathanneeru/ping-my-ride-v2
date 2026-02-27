import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking.dart';
import '../../core/services/bus_service.dart';
import '../../core/services/auth_service.dart';
import '../student/student_search_page.dart';
import 'bus_tracking_map_page.dart';

class TrackMyBusPage extends StatelessWidget {
  const TrackMyBusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid ?? '';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Track My Bus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BusService>(
        builder: (context, busService, _) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Filter confirmed bookings that belong to the current user and are today or in future
          final activeBookings = busService.confirmedBookings
              .where((b) {
                if (b.userId != currentUserId) return false;
                if (b.status == BookingStatus.cancelled) return false;
                if (b.selectedBookingDate == null) {
                  // Fall back to bookingDate
                  final bd = DateTime(
                      b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
                  return bd.isAtSameMomentAs(today) || bd.isAfter(today);
                }
                final bd = DateTime(b.selectedBookingDate!.year,
                    b.selectedBookingDate!.month, b.selectedBookingDate!.day);
                return bd.isAtSameMomentAs(today) || bd.isAfter(today);
              })
              .toList()
            ..sort((a, b) {
              final da = a.selectedBookingDate ?? a.bookingDate;
              final db = b.selectedBookingDate ?? b.bookingDate;
              return da.compareTo(db);
            });

          if (activeBookings.isEmpty) {
            return _buildEmptyState(context, primary);
          }

          return RefreshIndicator(
            onRefresh: () => busService.fetchBuses(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildInfoBanner(context, primary),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = activeBookings[index];
                        final bus = busService.getBusById(booking.busId);
                        final route = busService.getRouteById(booking.routeId);
                        return _buildBookingTrackCard(
                            context, booking, bus, route, primary, index);
                      },
                      childCount: activeBookings.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, Color primary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.12), primary.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing your confirmed & upcoming trips. Tap "Track Live" to see the bus on map.',
              style: TextStyle(
                fontSize: 12.5,
                color: primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTrackCard(
    BuildContext context,
    Booking booking,
    dynamic bus,
    dynamic route,
    Color primary,
    int index,
  ) {
    final bookingDate = booking.selectedBookingDate ?? booking.bookingDate;
    final now = DateTime.now();
    final isToday = bookingDate.year == now.year &&
        bookingDate.month == now.month &&
        bookingDate.day == now.day;

    final dateLabel = isToday
        ? 'Today'
        : '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: bus number + date badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          booking.busNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Route name
              Text(
                booking.routeName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // From → To
              Row(
                children: [
                  _routeIcon(color: Colors.green, icon: Icons.circle, size: 9),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.pickupLocation,
                      style:
                          const TextStyle(fontSize: 12.5, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3.5),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    color: Colors.grey[300],
                    thickness: 1.5,
                  ),
                ),
              ),
              Row(
                children: [
                  _routeIcon(
                      color: Colors.red, icon: Icons.location_on, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.dropLocation,
                      style:
                          const TextStyle(fontSize: 12.5, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Time slot + seat row
              Row(
                children: [
                  if (booking.selectedTimeSlot != null) ...[
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      booking.selectedTimeSlot!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (booking.seatNumber != null) ...[
                    Icon(Icons.event_seat, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Seat ${booking.seatNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // Track Live button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_on, size: 17),
                  label: const Text(
                    'Track Live',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: isToday
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusTrackingMapPage(
                                busId: booking.busId,
                                routeId: booking.routeId,
                              ),
                            ),
                          );
                        }
                      : null, // disabled for future bookings
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),

              // Disabled note for future bookings
              if (!isToday) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Live tracking available on the day of travel',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeIcon(
      {required Color color, required IconData icon, required double size}) {
    return Icon(icon, size: size, color: color);
  }

  Widget _buildEmptyState(BuildContext context, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_outlined,
                size: 64,
                color: primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Bookings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'You have no confirmed bookings for today or upcoming trips. Book a bus to track it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search & Book a Bus'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const StudentSearchPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
