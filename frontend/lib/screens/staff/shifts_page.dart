import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/rota_model.dart';
import '../../models/user_model.dart';
import '../../services/rota_service.dart';
import '../../core/constants.dart';

class StaffShiftsPage extends StatefulWidget {
  final UserModel user;
  const StaffShiftsPage({super.key, required this.user});

  @override
  State<StaffShiftsPage> createState() => _StaffShiftsPageState();
}

class _StaffShiftsPageState extends State<StaffShiftsPage> {
  static const _tabs = ['All', 'Scheduled', 'Completed', 'Cancelled'];
  static const _tabIcons = [
    Icons.list_alt_rounded,
    Icons.schedule_rounded,
    Icons.check_circle_outline_rounded,
    Icons.cancel_outlined,
  ];

  int _selectedTab = 0;
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

  List<RotaShift> _filtered(int tabIndex) {
    if (_shifts == null) return [];
    if (tabIndex == 0) return _shifts!;
    final status = _tabs[tabIndex].toLowerCase();
    return _shifts!.where((s) => s.status.toLowerCase() == status).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'scheduled':
        return const Color(0xFF2563EB);
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'scheduled':
        return const Color(0xFFDBEAFE);
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'scheduled':
        return Icons.schedule_rounded;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 500;

    return Column(
      children: [
        // ── Filter chips ──
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 20,
            vertical: 12,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _selectedTab == i;
                final count = _filtered(i).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: Icon(
                      _tabIcons[i],
                      size: 16,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    label: Text(
                      '${_tabs[i]}${_shifts != null ? ' ($count)' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onSelected: (_) => setState(() => _selectedTab = i),
                  ),
                );
              }),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // ── Content ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final list = _filtered(_selectedTab);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tabIcons[_selectedTab], size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              _selectedTab == 0
                  ? 'No shifts scheduled'
                  : 'No ${_tabs[_selectedTab].toLowerCase()} shifts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final hPad = width > 900 ? 32.0 : (width > 600 ? 20.0 : 12.0);

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: _fetchShifts,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
        itemCount: list.length,
        itemBuilder: (context, index) => _shiftCard(list[index]),
      ),
    );
  }

  Widget _shiftCard(RotaShift shift) {
    final df = DateFormat("EEE, MMM d, yyyy");
    final tf = DateFormat("HH:mm");
    final statusClr = _statusColor(shift.status);
    final statusBgClr = _statusBg(shift.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusBgClr,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon(shift.status), color: statusClr, size: 22),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    df.format(shift.startTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        "${tf.format(shift.startTime)} – ${tf.format(shift.endTime)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBgClr,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shift.status[0].toUpperCase() + shift.status.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusClr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
