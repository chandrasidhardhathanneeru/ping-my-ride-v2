import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/bus_service.dart';
import '../../core/models/bus_timing.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class BusTimingPage extends StatefulWidget {
  const BusTimingPage({super.key});

  @override
  State<BusTimingPage> createState() => _BusTimingPageState();
}

class _BusTimingPageState extends State<BusTimingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusService>(context, listen: false).fetchBusTimings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Timings'),
        elevation: 0,
      ),
      body: Consumer<BusService>(
        builder: (context, busService, child) {
          if (busService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bus Timings (${busService.busTimings.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTimingDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Timing'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: busService.busTimings.isEmpty
                    ? const Center(
                        child: Text(
                          'No bus timings added yet.\nTap "Add Timing" to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: busService.busTimings.length,
                        itemBuilder: (context, index) {
                          final timing = busService.busTimings[index];
                          return _buildTimingCard(context, timing);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimingCard(BuildContext context, BusTiming timing) {
    final busService = Provider.of<BusService>(context, listen: false);
    final bus = busService.getBusById(timing.busId);
    final route = busService.getRouteById(timing.routeId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus?.busNumber ?? 'Unknown Bus',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route?.routeName ?? 'Unknown Route',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTimingDialog(context, timing);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, timing);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Timings:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...timing.timings.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('${entry.stopName}: ${entry.time}'),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: timing.daysOfWeek.map((day) => Chip(
                label: Text(
                  day.substring(0, 3),
                  style: const TextStyle(fontSize: 12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTimingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimingDialog(),
    );
  }

  void _showEditTimingDialog(BuildContext context, BusTiming timing) {
    showDialog(
      context: context,
      builder: (context) => AddTimingDialog(timing: timing),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BusTiming timing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timing'),
        content: const Text('Are you sure you want to delete this bus timing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final busService = Provider.of<BusService>(context, listen: false);
              final success = await busService.deleteBusTiming(timing.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Timing deleted successfully' : 'Failed to delete timing'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddTimingDialog extends StatefulWidget {
  final BusTiming? timing;

  const AddTimingDialog({super.key, this.timing});

  @override
  State<AddTimingDialog> createState() => _AddTimingDialogState();
}

class _AddTimingDialogState extends State<AddTimingDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBusId;
  String? _selectedRouteId;
  final List<TimingEntryController> _timingControllers = [];
  final List<String> _selectedDays = [];
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.timing != null) {
      _selectedBusId = widget.timing!.busId;
      _selectedRouteId = widget.timing!.routeId;
      _selectedDays.addAll(widget.timing!.daysOfWeek);
      for (var entry in widget.timing!.timings) {
        _timingControllers.add(TimingEntryController(
          stopName: entry.stopName,
          time: entry.time,
        ));
      }
    } else {
      // Add default timing entry
      _addTimingEntry();
    }
  }

  void _addTimingEntry() {
    setState(() {
      _timingControllers.add(TimingEntryController());
    });
  }

  void _removeTimingEntry(int index) {
    if (_timingControllers.length > 1) {
      setState(() {
        _timingControllers[index].dispose();
        _timingControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _timingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.timing == null ? 'Add Bus Timing' : 'Edit Bus Timing'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<BusService>(
                  builder: (context, busService, child) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Bus',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedBusId,
                      items: busService.buses.map((bus) {
                        return DropdownMenuItem(
                          value: bus.id,
                          child: Text('${bus.busNumber} - ${bus.driverName}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBusId = value;
                          final bus = busService.getBusById(value!);
                          if (bus != null) {
                            _selectedRouteId = bus.routeId;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a bus';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Days of Operation',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _daysOfWeek.map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _selectedDays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Timing Entries',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      onPressed: _addTimingEntry,
                      icon: const Icon(Icons.add_circle),
                      tooltip: 'Add timing entry',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._timingControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return _buildTimingEntryField(index, controller);
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: widget.timing == null ? 'Add Timing' : 'Update Timing',
          onPressed: _isLoading ? () {} : _handleSubmit,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildTimingEntryField(int index, TimingEntryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stop ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                if (_timingControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeTimingEntry(index),
                    tooltip: 'Remove entry',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Stop Name',
              hint: 'e.g., Main Gate, College Stop',
              controller: controller.stopNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectTime(context, controller),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  controller.time.isEmpty ? 'Select time' : controller.time,
                  style: TextStyle(
                    color: controller.time.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, TimingEntryController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.time = picked.format(context);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_timingControllers.any((c) => c.time.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select time for all entries'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final busService = Provider.of<BusService>(context, listen: false);
    
    final timings = _timingControllers.asMap().entries.map((entry) {
      return TimingEntry(
        stopName: entry.value.stopNameController.text.trim(),
        time: entry.value.time,
        order: entry.key,
      );
    }).toList();

    bool success;

    if (widget.timing == null) {
      // Add new timing
      success = await busService.addBusTiming(
        busId: _selectedBusId!,
        routeId: _selectedRouteId!,
        timings: timings,
        daysOfWeek: _selectedDays,
      );
    } else {
      // Update existing timing
      final updatedTiming = widget.timing!.copyWith(
        busId: _selectedBusId!,
        routeId: _selectedRouteId!,
        timings: timings,
        daysOfWeek: _selectedDays,
        updatedAt: DateTime.now(),
      );
      success = await busService.updateBusTiming(updatedTiming);
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '${widget.timing == null ? 'Timing added' : 'Timing updated'} successfully' 
            : 'Failed to ${widget.timing == null ? 'add' : 'update'} timing'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class TimingEntryController {
  final TextEditingController stopNameController;
  String time;

  TimingEntryController({String? stopName, String? time})
      : stopNameController = TextEditingController(text: stopName ?? ''),
        time = time ?? '';

  void dispose() {
    stopNameController.dispose();
  }
}
