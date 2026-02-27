import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/trip_service.dart';
import '../../core/services/bus_service.dart';
import '../../core/models/trip.dart';
import '../../core/models/bus_route.dart';
import '../bookings/seat_selection_page.dart';

/// Student Search Page - RedBus-style search interface
/// Students search for trips by boarding point, dropping point, and date
class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key});

  @override
  State<StudentSearchPage> createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Trip> _searchResults = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search form
          _buildSearchForm(),
          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Buses',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // From field
                TextFormField(
                  controller: _fromController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'From (Boarding point)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.trip_origin, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter boarding point';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // To field
                TextFormField(
                  controller: _toController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'To (Dropping point)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.location_on, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter dropping point';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Date selector
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEE, MMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Search button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Search Buses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your journey details',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_filled,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No buses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different locations or dates',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final trip = _searchResults[index];
        return _buildBusCard(trip);
      },
    );
  }

  Widget _buildBusCard(Trip trip) {
    final busService = Provider.of<BusService>(context, listen: false);
    final route = busService.getRouteById(trip.routeId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectTrip(trip, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Bus image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/campus_express.png.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.routeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.busNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Route details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.departureTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[400]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route?.estimatedDuration ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Seats info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.availableSeats} seats available',
                        style: TextStyle(
                          color: trip.hasAvailableSeats ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Select',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _performSearch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
    });

    final tripService = Provider.of<TripService>(context, listen: false);
    final busService = Provider.of<BusService>(context, listen: false);

    // Search trips
    final results = tripService.searchTrips(
      fromStop: _fromController.text.trim(),
      toStop: _toController.text.trim(),
      date: _selectedDate,
      routes: busService.routes,
    );

    setState(() {
      _searchResults = results;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  void _selectTrip(Trip trip, BusRoute? route) {
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to stop selection page (we'll create this next)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopSelectionPage(
          trip: trip,
          route: route,
          fromQuery: _fromController.text.trim(),
          toQuery: _toController.text.trim(),
        ),
      ),
    );
  }
}

/// Stop Selection Page - Student selects exact boarding and dropping stops
class StopSelectionPage extends StatefulWidget {
  final Trip trip;
  final BusRoute route;
  final String fromQuery;
  final String toQuery;

  const StopSelectionPage({
    super.key,
    required this.trip,
    required this.route,
    required this.fromQuery,
    required this.toQuery,
  });

  @override
  State<StopSelectionPage> createState() => _StopSelectionPageState();
}

class _StopSelectionPageState extends State<StopSelectionPage> {
  String? _selectedBoardingStop;
  String? _selectedDropStop;
  String? _boardingTime;
  String? _dropTime;

  List<Map<String, String>> _allStops = [];

  @override
  void initState() {
    super.initState();
    _buildStopsList();
  }

  void _buildStopsList() {
    _allStops = [];
    
    // Add start stop
    _allStops.add({
      'name': widget.route.pickupLocation,
      'time': widget.trip.departureTime,
    });

    // Add intermediate stops
    for (final stop in widget.route.intermediateStops) {
      _allStops.add({
        'name': stop.name,
        'time': stop.estimatedTime,
      });
    }

    // Add end stop
    _allStops.add({
      'name': widget.route.dropLocation,
      'time': '', // Can be calculated based on duration
    });

    // Try to auto-select based on search query
    for (final stop in _allStops) {
      if (stop['name']!.toLowerCase().contains(widget.fromQuery.toLowerCase())) {
        _selectedBoardingStop = stop['name'];
        _boardingTime = stop['time'];
      }
      if (stop['name']!.toLowerCase().contains(widget.toQuery.toLowerCase())) {
        _selectedDropStop = stop['name'];
        _dropTime = stop['time'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Stops'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.trip.busNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.trip.routeName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Boarding stop selection
                  Text(
                    'Select Boarding Stop',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._allStops.map((stop) {
                    final isSelected = _selectedBoardingStop == stop['name'];
                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                      child: RadioListTile<String>(
                        title: Text(stop['name']!),
                        subtitle: Text('Departure: ${stop['time']}'),
                        value: stop['name']!,
                        groupValue: _selectedBoardingStop,
                        onChanged: (value) {
                          setState(() {
                            _selectedBoardingStop = value;
                            _boardingTime = stop['time'];
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Dropping stop selection
                  Text(
                    'Select Dropping Stop',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._allStops.map((stop) {
                    final isSelected = _selectedDropStop == stop['name'];
                    final boardingIndex = _allStops.indexWhere((s) => s['name'] == _selectedBoardingStop);
                    final currentIndex = _allStops.indexOf(stop);
                    final isEnabled = _selectedBoardingStop == null || currentIndex > boardingIndex;

                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                      child: RadioListTile<String>(
                        title: Text(
                          stop['name']!,
                          style: TextStyle(
                            color: isEnabled ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          'Arrival: ${stop['time'] ?? 'TBD'}',
                          style: TextStyle(
                            color: isEnabled ? null : Colors.grey,
                          ),
                        ),
                        value: stop['name']!,
                        groupValue: _selectedDropStop,
                        onChanged: isEnabled
                            ? (value) {
                                setState(() {
                                  _selectedDropStop = value;
                                  _dropTime = stop['time'];
                                });
                              }
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Continue button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedBoardingStop != null && _selectedDropStop != null
                    ? _continueToSeatSelection
                    : null,
                child: const Text(
                  'Continue to Seat Selection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueToSeatSelection() {
    // Navigate to seat selection with boarding/drop info
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionPage(
          trip: widget.trip,
          route: widget.route,
          boardingStop: _selectedBoardingStop!,
          dropStop: _selectedDropStop!,
          boardingTime: _boardingTime ?? '',
          dropTime: _dropTime ?? '',
        ),
      ),
    );
  }
}
