import 'package:flutter/material.dart';

class StudentHomePage extends StatefulWidget {
  final String studentName;
  const StudentHomePage({super.key, this.studentName = 'Alex'});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;

  static const _busImagePath = 'assets/images/college_bus.jpg';
  final _busList = const [
    {'title': 'Campus Express', 'subtitle': 'Quick rides between campus buildings'},
    {'title': 'City Connector', 'subtitle': 'Regular routes to the city center'},
    {'title': 'Weekend Wanderer', 'subtitle': 'Special trips for weekend events'},
  ];

  final _upcomingTrips = const [
    {'title': 'Campus Express', 'subtitle': 'Building A to Library', 'time': '10:00 AM', 'when': 'Today'},
    {'title': 'City Connector', 'subtitle': 'Campus to Downtown', 'time': '1:00 PM', 'when': 'Tomorrow'},
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    // UI-only: navigation logic would go here in a full app.
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 6),
              Text(widget.studentName,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Profile',
          splashRadius: 22,
          icon: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildBusCard(BuildContext context, String title, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                _busImagePath,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.directions_bus, size: 40, color: Colors.grey)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripItem(Map<String, String> trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(trip['subtitle'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(trip['time'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(trip['when'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Page body
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            _buildSectionTitle('Book a Ride'),
            // Bus cards
            for (var bus in _busList) _buildBusCard(context, bus['title']!, bus['subtitle']!),
            const SizedBox(height: 6),
            _buildSectionTitle('Upcoming Trips'),
            // Upcoming trips list
            for (var trip in _upcomingTrips) _buildUpcomingTripItem(trip),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num), label: 'My Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Track Bus'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Small runnable scaffold for quick testing.
/// Remove or ignore when integrating into the real app.
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const StudentHomePage(),
  ));
}
