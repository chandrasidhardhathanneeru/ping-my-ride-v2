import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_manager.dart';
import '../../core/theme/app_theme.dart';

class LocationTrackingPage extends StatefulWidget {
  final String? busId;
  
  const LocationTrackingPage({super.key, this.busId});

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationManager = Provider.of<LocationManager>(context, listen: false);
    await locationManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        elevation: 0,
      ),
      body: Consumer<LocationManager>(
        builder: (context, locationManager, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                _buildStatusCard(locationManager),
                
                const SizedBox(height: 16),
                
                // Location Info Card
                _buildLocationInfoCard(locationManager),
                
                const SizedBox(height: 16),
                
                // Controls
                _buildControlsCard(locationManager),
                
                const SizedBox(height: 16),
                
                // Location History
                _buildHistoryCard(locationManager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(LocationManager locationManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Tracking',
              locationManager.isTracking,
              locationManager.isTracking ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Location Services',
              locationManager.locationServiceEnabled,
              locationManager.locationServiceEnabled ? Icons.location_on : Icons.location_off,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              'Permission',
              (locationManager.permission?.toString().contains('always') ?? false) ||
                  (locationManager.permission?.toString().contains('whileInUse') ?? false),
              Icons.security,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: isActive ? Colors.green : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfoCard(LocationManager locationManager) {
    final position = locationManager.currentPosition;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (position != null) ...[
              _buildInfoRow('Latitude', '${position.latitude.toStringAsFixed(6)}°'),
              const SizedBox(height: 8),
              _buildInfoRow('Longitude', '${position.longitude.toStringAsFixed(6)}°'),
              const SizedBox(height: 8),
              _buildInfoRow('Altitude', '${position.altitude.toStringAsFixed(2)} m'),
              const SizedBox(height: 8),
              _buildInfoRow('Accuracy', '${position.accuracy.toStringAsFixed(2)} m'),
              const SizedBox(height: 8),
              _buildInfoRow('Speed', '${(position.speed * 3.6).toStringAsFixed(2)} km/h'),
              const SizedBox(height: 8),
              _buildInfoRow('Heading', '${position.heading.toStringAsFixed(2)}°'),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Time',
                '${position.timestamp.hour}:${position.timestamp.minute.toString().padLeft(2, '0')}:${position.timestamp.second.toString().padLeft(2, '0')}',
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No location data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsCard(LocationManager locationManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (!locationManager.isTracking) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await locationManager.startTracking(busId: widget.busId);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await locationManager.stopTracking();
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await locationManager.updateLocation(busId: widget.busId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Update Now'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await locationManager.openLocationSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Location Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(LocationManager locationManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    _showLocationHistory(locationManager);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Location updates are saved every 30 seconds while tracking is active.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'History is stored in Firebase for analytics and route optimization.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
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

  void _showLocationHistory(LocationManager locationManager) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final history = await locationManager.getLocationHistory(
      busId: widget.busId,
      limit: 20,
    );
    
    if (!mounted) return;
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Location History'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No history available'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final location = history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${location['latitude']?.toStringAsFixed(6)}, ${location['longitude']?.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        location['updatedAt'] ?? 'Unknown time',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        '${(location['speed'] * 3.6).toStringAsFixed(1)} km/h',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
