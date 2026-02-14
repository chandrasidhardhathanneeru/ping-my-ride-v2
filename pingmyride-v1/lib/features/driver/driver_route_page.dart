import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/bus.dart';
import '../../core/models/bus_route.dart';
import '../../core/services/bus_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

/// Dedicated driver route page showing assigned route details
class DriverRoutePage extends StatefulWidget {
  const DriverRoutePage({super.key});

  @override
  State<DriverRoutePage> createState() => _DriverRoutePageState();
}

class _DriverRoutePageState extends State<DriverRoutePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final busService = Provider.of<BusService>(context, listen: false);
    await busService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<BusService>(
        builder: (context, busService, child) {
          if (busService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get driver's bus
          final authService = Provider.of<AuthService>(context, listen: false);
          final driverEmail = authService.currentUser?.email;
          
          final driverBuses = busService.buses
              .where((bus) => bus.driverEmail == driverEmail && bus.isActive)
              .toList();

          if (driverBuses.isEmpty) {
            return _buildEmptyState('No Bus Assigned', 
                'You are not currently assigned to any bus. Contact admin for bus assignment.');
          }

          // Get route for the first bus (assuming driver has one bus)
          final bus = driverBuses.first;
          final route = busService.getRouteById(bus.routeId);

          if (route == null) {
            return _buildEmptyState('No Route Assigned', 
                'Your bus (${bus.busNumber}) does not have an assigned route yet.');
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBusCard(bus),
                const SizedBox(height: 16),
                _buildRouteOverview(route),
                const SizedBox(height: 16),
                _buildRouteStops(route),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    return Card(
      elevation: 2,
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
                  child: Icon(
                    Icons.directions_bus,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${bus.busNumber}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your assigned vehicle',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBusInfoRow(Icons.airline_seat_recline_normal, 
                'Capacity', '${bus.availableSeats}/${bus.capacity} available'),
            const SizedBox(height: 8),
            _buildBusInfoRow(Icons.person, 'Driver', bus.driverName),
          ],
        ),
      ),
    );
  }

  Widget _buildBusInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteOverview(BusRoute route) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Route Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              route.routeName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRouteInfoRow(Icons.location_on, 'Pickup', route.pickupLocation),
            const SizedBox(height: 8),
            _buildRouteInfoRow(Icons.flag, 'Drop', route.dropLocation),
            const SizedBox(height: 8),
            _buildRouteInfoRow(Icons.access_time, 'Duration', route.estimatedDuration),
            const SizedBox(height: 8),
            _buildRouteInfoRow(Icons.straighten, 'Distance', '${route.distance.toStringAsFixed(1)} km'),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStops(BusRoute route) {
    final allStops = [
      {'name': route.pickupLocation, 'type': 'pickup', 'time': null},
      ...route.intermediateStops.map((stop) => {
            'name': stop.name,
            'type': 'intermediate',
            'time': stop.estimatedTime,
          }),
      {'name': route.dropLocation, 'type': 'drop', 'time': null},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pin_drop, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Route Stops',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${allStops.length} stops',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...allStops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final isLast = index == allStops.length - 1;
              
              return _buildStopItem(
                stop['name'] as String,
                stop['type'] as String,
                stop['time'],
                isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStopItem(String name, String type, String? time, bool isLast) {
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'pickup':
        icon = Icons.trip_origin;
        iconColor = Colors.green;
        break;
      case 'drop':
        icon = Icons.location_on;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.circle;
        iconColor = Colors.blue;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
