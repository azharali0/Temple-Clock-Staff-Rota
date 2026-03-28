import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/leave_model.dart';
import '../../models/user_model.dart';
import '../../services/leave_service.dart';
import '../../widgets/shared_widgets.dart';

class StaffLeavePage extends StatefulWidget {
  final UserModel user;

  const StaffLeavePage({super.key, required this.user});

  @override
  State<StaffLeavePage> createState() => _StaffLeavePageState();
}

class _StaffLeavePageState extends State<StaffLeavePage> {
  static const _leaveTypes = [
    'annual',
    'sick',
    'maternity',
    'paternity',
    'shared_parental',
    'adoption',
    'parental',
    'dependants',
    'compassionate',
    'neonatal',
    'carers',
    'public_duties',
    'study',
    'unpaid',
  ];

  bool _loading = true;
  bool _submitting = false;

  List<LeaveRequest> _requests = const [];
  Map<String, dynamic>? _balance;

  String _selectedType = 'annual';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      final data = await Future.wait([
        leaveService.getLeaveRequests(),
        leaveService.getLeaveBalance(widget.user.id),
      ]);

      if (!mounted) return;
      setState(() {
        _requests = data[0] as List<LeaveRequest>;
        _balance = data[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final base = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? base,
      firstDate: base,
      lastDate: base.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) {
      showAppSnackBar(context, 'Please select start and end date', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final leaveService = Provider.of<LeaveService>(context, listen: false);
      await leaveService.createLeaveRequest(
        leaveType: _selectedType,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      showAppSnackBar(context, 'Leave request submitted');
      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final annualEntitlement = (_balance?['annualEntitlement'] ?? 224).toDouble();
    final annualUsed = (_balance?['annualUsed'] ?? 0).toDouble();
    final annualPending = (_balance?['annualPending'] ?? 0).toDouble();
    final annualBalance = (_balance?['annualLeaveBalance'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.teal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(
                title: 'Leave Management',
                subtitle: 'Submit leave requests and track approvals',
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _balanceCard(annualEntitlement, annualUsed, annualPending, annualBalance),
              const SizedBox(height: 14),
              _requestForm(),
              const SizedBox(height: 18),
              const SectionHeader(title: 'My Leave Requests'),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_requests.isEmpty)
                _emptyState()
              else
                ..._requests.map(_requestTile),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(double entitlement, double used, double pending, double balance) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Annual Leave (Hours)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Entitlement', entitlement.toStringAsFixed(1))),
              Expanded(child: _miniStat('Used', used.toStringAsFixed(1))),
              Expanded(child: _miniStat('Pending', pending.toStringAsFixed(1))),
              Expanded(child: _miniStat('Balance', balance.toStringAsFixed(1), valueColor: AppColors.tealDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }

  Widget _requestForm() {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Leave Type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _leaveTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.replaceAll('_', ' ')),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.event_available),
                  label: Text(_startDate == null
                      ? 'Start Date'
                      : dateFormat.format(_startDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event),
                  label: Text(_endDate == null
                      ? 'End Date'
                      : dateFormat.format(_endDate!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitRequest,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestTile(LeaveRequest req) {
    final range = '${DateFormat('dd MMM').format(req.startDate)} - ${DateFormat('dd MMM yyyy').format(req.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  req.leaveType.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(req.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(range, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text('Hours: ${req.totalHours.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
          if (req.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(req.reason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (req.status == LeaveStatus.pending) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancel(req.id),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(String leaveId) async {
    final leaveService = Provider.of<LeaveService>(context, listen: false);
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel Request',
      message: 'Do you want to cancel this leave request?',
      confirmLabel: 'Cancel Request',
      isDestructive: true,
    );

    if (!ok || !mounted) return;

    try {
      await leaveService.cancelLeave(leaveId);
      if (!mounted) return;
      showAppSnackBar(context, 'Leave request cancelled');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
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

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox, size: 34, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('No leave requests yet', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
