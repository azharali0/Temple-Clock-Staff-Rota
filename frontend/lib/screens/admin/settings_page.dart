import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../services/settings_service.dart';
import '../../widgets/shared_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  bool _saving = false;

  // Controllers
  final _graceCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _leaveHoursCtrl = TextEditingController();
  final _noticeDaysCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();

  bool _geofenceEnabled = true;
  bool _requireLeaveApproval = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _graceCtrl.dispose();
    _radiusCtrl.dispose();
    _leaveHoursCtrl.dispose();
    _noticeDaysCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _overtimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = Provider.of<SettingsService>(context, listen: false);
      final data = await svc.getSettings();
      if (mounted) {
        setState(() {
          _graceCtrl.text = '${data['gracePeriodMinutes'] ?? 10}';
          _radiusCtrl.text = '${data['geofenceRadius'] ?? 200}';
          _leaveHoursCtrl.text = '${data['annualLeaveHours'] ?? 224}';
          _noticeDaysCtrl.text = '${data['minNoticeDays'] ?? 7}';
          _hourlyRateCtrl.text = '${data['defaultHourlyRate'] ?? 12}';
          _overtimeCtrl.text = '${data['overtimeMultiplier'] ?? 1.5}';
          _geofenceEnabled = data['geofenceEnabled'] ?? true;
          _requireLeaveApproval = data['requireLeaveApproval'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppSnackBar(context, 'Error loading settings: $e', isError: true);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final svc = Provider.of<SettingsService>(context, listen: false);
      await svc.updateSettings({
        'gracePeriodMinutes': int.tryParse(_graceCtrl.text) ?? 10,
        'geofenceEnabled': _geofenceEnabled,
        'geofenceRadius': int.tryParse(_radiusCtrl.text) ?? 200,
        'annualLeaveHours': int.tryParse(_leaveHoursCtrl.text) ?? 224,
        'requireLeaveApproval': _requireLeaveApproval,
        'minNoticeDays': int.tryParse(_noticeDaysCtrl.text) ?? 7,
        'defaultHourlyRate': double.tryParse(_hourlyRateCtrl.text) ?? 12,
        'overtimeMultiplier': double.tryParse(_overtimeCtrl.text) ?? 1.5,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
      });
      if (mounted) showAppSnackBar(context, 'Settings saved successfully');
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.teal, strokeWidth: 2))
            : ListView(
                padding: EdgeInsets.all(pad),
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Settings',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, size: 16),
                        label: const Text('Save Changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _attendanceSection()),
                        const SizedBox(width: 16),
                        Expanded(child: _leaveSection()),
                        const SizedBox(width: 16),
                        Expanded(child: _notificationsSection()),
                      ],
                    )
                  else ...[
                    _attendanceSection(),
                    const SizedBox(height: 16),
                    _leaveSection(),
                    const SizedBox(height: 16),
                    _paySection(),
                    const SizedBox(height: 16),
                    _notificationsSection(),
                  ],

                  if (wide) ...[
                    const SizedBox(height: 16),
                    _paySection(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _attendanceSection() {
    return _section('Attendance', Icons.schedule, [
      _numberField('Grace Period (minutes)', _graceCtrl),
      const SizedBox(height: 12),
      _switchTile('Geofence Enabled', _geofenceEnabled,
          (v) => setState(() => _geofenceEnabled = v)),
      if (_geofenceEnabled) ...[
        const SizedBox(height: 12),
        _numberField('Geofence Radius (meters)', _radiusCtrl),
      ],
    ]);
  }

  Widget _leaveSection() {
    return _section('Leave Management', Icons.beach_access, [
      _numberField('Annual Leave Hours', _leaveHoursCtrl),
      const SizedBox(height: 12),
      _numberField('Min Notice Days', _noticeDaysCtrl),
      const SizedBox(height: 12),
      _switchTile('Require Approval', _requireLeaveApproval,
          (v) => setState(() => _requireLeaveApproval = v)),
    ]);
  }

  Widget _paySection() {
    return _section('Pay & Overtime', Icons.payments, [
      _numberField('Default Hourly Rate (£)', _hourlyRateCtrl, decimal: true),
      const SizedBox(height: 12),
      _numberField('Overtime Multiplier', _overtimeCtrl, decimal: true),
    ]);
  }

  Widget _notificationsSection() {
    return _section('Notifications', Icons.notifications, [
      _switchTile('Email Notifications', _emailNotifications,
          (v) => setState(() => _emailNotifications = v)),
      const SizedBox(height: 8),
      _switchTile('Push Notifications', _pushNotifications,
          (v) => setState(() => _pushNotifications = v)),
    ]);
  }

  Widget _numberField(String label, TextEditingController ctrl,
      {bool decimal = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.teal,
        ),
      ],
    );
  }
}
