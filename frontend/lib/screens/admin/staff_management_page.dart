import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/shared_widgets.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  List<UserModel> _staff = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final users = await userService.getUsers();
      if (mounted) {
        setState(() {
          _staff = users;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppSnackBar(context, 'Error loading staff: $e', isError: true);
      }
    }
  }

  void _applyFilter() {
    if (_search.isEmpty) {
      _filtered = List.from(_staff);
    } else {
      final q = _search.toLowerCase();
      _filtered = _staff
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.department ?? '').toLowerCase().contains(q))
          .toList();
    }
  }

  void _showStaffDialog({UserModel? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final rateCtrl = TextEditingController(
        text: existing?.hourlyRate?.toStringAsFixed(2) ?? '12.00');
    String role = existing?.role ?? 'staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(isEdit ? 'Edit Staff' : 'Add New Staff',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Full Name', nameCtrl),
                  const SizedBox(height: 12),
                  _field('Email', emailCtrl, type: TextInputType.emailAddress),
                  if (!isEdit) ...[
                    const SizedBox(height: 12),
                    _field('Password', passwordCtrl, obscure: true),
                  ],
                  const SizedBox(height: 12),
                  _field('Phone', phoneCtrl, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Department', deptCtrl),
                  const SizedBox(height: 12),
                  _field('Hourly Rate (£)', rateCtrl,
                      type: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setDState(() => role = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveStaff(
                ctx,
                existing: existing,
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                password: passwordCtrl.text,
                phone: phoneCtrl.text.trim(),
                department: deptCtrl.text.trim(),
                hourlyRate: double.tryParse(rateCtrl.text) ?? 0,
                role: role,
              ),
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStaff(
    BuildContext ctx, {
    UserModel? existing,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String department,
    required double hourlyRate,
    required String role,
  }) async {
    if (name.isEmpty || email.isEmpty) {
      showAppSnackBar(context, 'Name and email are required', isError: true);
      return;
    }
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      if (existing != null) {
        await userService.updateUser(existing.id, {
          'name': name,
          'email': email,
          'phone': phone,
          'department': department,
          'hourlyRate': hourlyRate,
          'role': role,
        });
      } else {
        if (password.isEmpty) {
          showAppSnackBar(context, 'Password is required', isError: true);
          return;
        }
        await userService.createUser(
          name: name,
          email: email,
          password: password,
          phone: phone,
          department: department,
          hourlyRate: hourlyRate,
          role: role,
        );
      }
      if (ctx.mounted) Navigator.pop(ctx);
      if (mounted) {
        showAppSnackBar(context,
            existing != null ? 'Staff updated' : 'Staff created');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  Future<void> _deactivateStaff(UserModel user) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deactivate Staff',
      message: 'Deactivate ${user.name}? They will no longer be able to log in.',
      confirmLabel: 'Deactivate',
      isDestructive: true,
    );
    if (ok == true) {
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        await userService.deleteUser(user.id);
        if (mounted) {
          showAppSnackBar(context, '${user.name} deactivated');
          _load();
        }
      } catch (e) {
        if (mounted) showAppSnackBar(context, '$e', isError: true);
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? type, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    final cols = Responsive.gridColumns(context, mobile: 1, tablet: 2, desktop: 3);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Staff Management',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        Text('${_staff.length} active employees',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showStaffDialog(),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add Staff'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search
              TextField(
                onChanged: (v) => setState(() {
                  _search = v;
                  _applyFilter();
                }),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or department...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Staff grid
              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      color: AppColors.teal, strokeWidth: 2),
                ))
              else if (_filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      _search.isNotEmpty
                          ? 'No staff matching "$_search"'
                          : 'No staff found',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 2.8 : 1.6,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _StaffCard(
                    user: _filtered[i],
                    onEdit: () => _showStaffDialog(existing: _filtered[i]),
                    onDeactivate: () => _deactivateStaff(_filtered[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _StaffCard({
    required this.user,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'deactivate') onDeactivate();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Deactivate',
                          style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _chip(user.role == 'admin' ? 'Admin' : 'Staff',
                  user.role == 'admin' ? AppColors.navy : AppColors.teal),
              if (user.department != null && user.department!.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chip(user.department!, Colors.blueGrey),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text('£${user.hourlyRate?.toStringAsFixed(2) ?? '0.00'}/hr',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
