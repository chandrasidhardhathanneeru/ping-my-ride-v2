import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_qr.dart';
import '../../core/services/trip_qr_service.dart';
import '../../core/services/location_manager.dart';
import '../../core/theme/app_theme.dart';

/// Driver page to display trip QR code for students to scan
class DriverTripQRPage extends StatelessWidget {
  final TripQR tripQR;

  const DriverTripQRPage({super.key, required this.tripQR});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip QR Code'),
        actions: [
          if (tripQR.isActive)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'End Trip',
              onPressed: () => _endTrip(context),
            ),
        ],
      ),
      body: StreamBuilder<TripQR?>(
        stream: Provider.of<TripQRService>(context, listen: false)
            .streamTripQR(tripQR.id),
        builder: (context, snapshot) {
          final currentTripQR = snapshot.data ?? tripQR;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status indicator
                _buildStatusCard(currentTripQR),
                const SizedBox(height: 24),

                // QR Code
                _buildQRCode(currentTripQR),
                const SizedBox(height: 24),

                // Trip details
                _buildTripDetails(context, currentTripQR),
                const SizedBox(height: 24),

                // Scanned students count
                _buildScanStats(context, currentTripQR),
                const SizedBox(height: 24),

                // Instructions
                _buildInstructions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(TripQR tripQR) {
    final isExpired = tripQR.isExpired;
    final isActive = tripQR.isActive;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'Expired';
      statusIcon = Icons.timer_off;
    } else if (!isActive) {
      statusColor = Colors.orange;
      statusText = 'Ended';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.green;
      statusText = 'Active';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(TripQR tripQR) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.accentColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: tripQR.qrCode,
              version: QrVersions.auto,
              size: 280,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Show this QR code to students',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(BuildContext context, TripQR tripQR) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _buildDetailRow(context, Icons.directions_bus, 'Bus', tripQR.busNumber),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.route, 'Route', tripQR.routeName),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Date',
              DateFormat('MMM dd, yyyy').format(tripQR.travelDate),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.access_time, 'Time', tripQR.timeSlot),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.timer,
              'Expires',
              DateFormat('h:mm a').format(tripQR.expiresAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildScanStats(BuildContext context, TripQR tripQR) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 32, color: Colors.blue[700]),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tripQR.scannedCount}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Students Boarded',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[900]),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(context, '1. Keep this screen visible for students'),
          _buildInstructionItem(context, '2. Students scan this QR to board the bus'),
          _buildInstructionItem(context, '3. Watch the counter to track boardings'),
          _buildInstructionItem(context, '4. Tap "End Trip" when journey is complete'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endTrip(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end this trip? The QR code will be deactivated and location tracking will stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final tripQRService = Provider.of<TripQRService>(context, listen: false);
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      
      // Stop location tracking
      await locationManager.stopTracking();
      
      // Deactivate trip QR
      final success = await tripQRService.deactivateTripQR(tripQR.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip ended successfully. Location tracking stopped.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to end trip'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
