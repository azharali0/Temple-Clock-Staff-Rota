import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/rota_model.dart';
import '../../models/user_model.dart';
import '../../services/rota_service.dart';

class StaffShiftsPage extends StatefulWidget {
  final UserModel user;
  const StaffShiftsPage({super.key, required this.user});

  @override
  State<StaffShiftsPage> createState() => _StaffShiftsPageState();
}

class _StaffShiftsPageState extends State<StaffShiftsPage> {
  List<RotaShift>? _shifts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    try {
      final rotaService = Provider.of<RotaService>(context, listen: false);
      final shifts = await rotaService.getMyShifts();
      if (mounted) {
        setState(() {
          _shifts = shifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching shifts: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_shifts == null || _shifts!.isEmpty) {
      return const Center(child: Text("No shifts scheduled."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts!.length,
      itemBuilder: (context, index) {
        final shift = _shifts![index];
        final df = DateFormat("EEEE, MMM d");
        final tf = DateFormat("HH:mm");
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(df.format(shift.startTime)),
            subtitle: Text("${tf.format(shift.startTime)} - ${tf.format(shift.endTime)}"),
            trailing: Chip(
              label: Text(shift.status),
              backgroundColor: shift.status == "completed" ? Colors.green.shade100 : Colors.blue.shade100,
            ),
          ),
        );
      },
    );
  }
}
