import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking.dart';
import '../../core/services/bus_service.dart';

class BookingsListPage extends StatelessWidget {
  final String title;
  final List<Booking> bookings;
  final Color accentColor;

  const BookingsListPage({
    super.key,
    required this.title,
    required this.bookings,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final busService = Provider.of<BusService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await busService.fetchUserBookings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bookings refreshed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: bookings.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildBookingCard(context, booking, busService);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your booking history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, BusService busService) {
    final bus = busService.getBusById(booking.busId);
    final route = bus != null ? busService.getRouteById(bus.routeId) : null;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking, busService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bus number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.busNumber,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.routeName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(booking.status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      booking.status.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(booking.status),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Route details
              _buildInfoRow(
                context,
                Icons.location_on,
                'Route',
                '${booking.pickupLocation} → ${booking.dropLocation}',
              ),
              const SizedBox(height: 12),

              // Booking date
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'Booked',
                _formatDate(booking.createdAt),
              ),

              // Cancellation info
              if (booking.status.name == 'cancelled' && booking.cancelledAt != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.event_busy,
                  'Cancelled',
                  _formatDate(booking.cancelledAt!),
                  color: Colors.red,
                ),
              ],

              // Payment info
              if (booking.amount != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.payment,
                  'Amount Paid',
                  '₹${booking.amount!.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ],

              // Duration
              if (route != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'Duration',
                  route.estimatedDuration,
                ),
              ],

              // Tap to view more indicator
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color ?? Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking, BusService busService) {
    final bus = busService.getBusById(booking.busId);
    final route = bus != null ? busService.getRouteById(bus.routeId) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Text(
                  'Booking Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Bus Information Section
                _buildDetailSection(
                  context,
                  'Bus Information',
                  [
                    _DetailItem('Bus Number', booking.busNumber, Icons.directions_bus),
                    _DetailItem('Driver', booking.driverName, Icons.person),
                    _DetailItem('Contact', booking.driverPhone, Icons.phone),
                  ],
                ),

                const SizedBox(height: 24),

                // Route Information Section
                _buildDetailSection(
                  context,
                  'Route Information',
                  [
                    _DetailItem('Route Name', booking.routeName, Icons.route),
                    _DetailItem('Pickup', booking.pickupLocation, Icons.location_on),
                    _DetailItem('Drop-off', booking.dropLocation, Icons.flag),
                    if (route != null)
                      _DetailItem('Duration', route.estimatedDuration, Icons.access_time),
                    if (route != null)
                      _DetailItem('Distance', '${route.distance.toStringAsFixed(1)} km', Icons.straighten),
                  ],
                ),

                const SizedBox(height: 24),

                // Booking Information Section
                _buildDetailSection(
                  context,
                  'Booking Information',
                  [
                    _DetailItem('Booking Date', _formatDate(booking.createdAt), Icons.calendar_today),
                    _DetailItem('Status', booking.status.label, Icons.info, 
                        valueColor: _getStatusColor(booking.status)),
                    if (booking.cancelledAt != null)
                      _DetailItem('Cancelled On', _formatDate(booking.cancelledAt!), Icons.event_busy,
                          valueColor: Colors.red),
                  ],
                ),

                const SizedBox(height: 24),

                // Payment Information Section
                if (booking.amount != null) ...[
                  _buildDetailSection(
                    context,
                    'Payment Information',
                    [
                      _DetailItem('Amount', '₹${booking.amount!.toStringAsFixed(2)}', Icons.currency_rupee,
                          valueColor: Colors.green),
                      if (booking.paymentId != null)
                        _DetailItem('Payment ID', booking.paymentId!, Icons.receipt_long),
                      if (booking.orderId != null)
                        _DetailItem('Order ID', booking.orderId!, Icons.confirmation_number_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: items.map((item) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  subtitle: Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: item.valueColor,
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  _DetailItem(this.label, this.value, this.icon, {this.valueColor});
}
