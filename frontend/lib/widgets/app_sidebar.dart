import 'package:flutter/material.dart';
import '../core/constants.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<SidebarItem> items;
  final void Function(int index) onItemTap;
  final VoidCallback onSignOut;
  final String? userName;
  final String? userRole;
  final Widget? trailing;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemTap,
    required this.onSignOut,
    this.userName,
    this.userRole,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2C59), Color(0xFF0D2550)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Brand header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded,
                        size: 18, color: AppColors.teal),
                  ),
                  const SizedBox(width: 10),
                  const Text('CareShift',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3)),
                ],
              ),
            ),

            // ── User info strip ─────────────────────────────────────────
            if (userName != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.25),
                      child: Text(
                        userName!.isNotEmpty ? userName![0].toUpperCase() : 'A',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName!.split(' ').first,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userRole != null)
                            Text(userRole!,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(color: Color(0x22FFFFFF), height: 1),

            // ── Nav items ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final selected = item.index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onItemTap(item.index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.13)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: selected
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.12))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 16,
                                color: selected
                                    ? AppColors.teal
                                    : Colors.white.withValues(alpha: 0.65),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                              if (selected) ...[
                                const Spacer(),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(color: Color(0x22FFFFFF), height: 1),

            // ── Trailing widget (e.g. notification bell) ────────────────
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: trailing!,
              ),

            // ── Sign out ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onSignOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.65)),
                        const SizedBox(width: 10),
                        Text('Sign Out',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
