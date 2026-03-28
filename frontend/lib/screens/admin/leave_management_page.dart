import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminLeaveManagementPage extends StatefulWidget {
  const AdminLeaveManagementPage({super.key});

  @override
  State<AdminLeaveManagementPage> createState() => _AdminLeaveManagementPageState();
}

class _AdminLeaveManagementPageState extends State<AdminLeaveManagementPage> {
  bool _loading = true;
  String _statusFilter = 'pending';
  List<LeaveRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      final requests = await leaveService.getLeaveRequests(
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _approve(LeaveRequest req) async {
    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      await leaveService.approveLeave(req.id);
      if (!mounted) return;
      showAppSnackBar(context, 'Leave approved');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _reject(LeaveRequest req) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      await leaveService.rejectLeave(req.id, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      showAppSnackBar(context, 'Leave rejected');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Leave Management'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'all', child: Text('All')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _statusFilter = value);
                        _load();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(child: Text('No leave requests found'))
                      : ListView.builder(
                          itemCount: _requests.length,
                          itemBuilder: (_, i) => _requestCard(_requests[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(LeaveRequest req) {
    final range = '${DateFormat('dd MMM').format(req.startDate)} - ${DateFormat('dd MMM yyyy').format(req.endDate)}';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req.staffName.isEmpty ? req.staffId : req.staffName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(req.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(req.leaveType.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)),
            Text(range, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text('Hours: ${req.totalHours.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
            if (req.reason.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(req.reason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (req.status == LeaveStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(req),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(req),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(LeaveStatus status) {
    late final Color color;
    late final String label;

    switch (status) {
      case LeaveStatus.approved:
        color = AppColors.success;
        label = 'Approved';
        break;
      case LeaveStatus.rejected:
        color = AppColors.error;
        label = 'Rejected';
        break;
      case LeaveStatus.cancelled:
        color = AppColors.textMuted;
        label = 'Cancelled';
        break;
      case LeaveStatus.pending:
        color = const Color(0xFFF9A825);
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
