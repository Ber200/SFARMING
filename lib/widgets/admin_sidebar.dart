import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/treatment_provider.dart';
import 'add_schedule_dialog.dart';

class AdminNavItem {
  final String label;
  final IconData icon;
  final String route;
  final String category;
  final bool isAction;
  final bool hasBadge;

  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.category,
    this.isAction = false,
    this.hasBadge = false,
  });
}

class AdminSidebar extends StatelessWidget {
  final bool collapsed;
  final String activeRoute;
  final ValueChanged<bool> onToggleCollapse;
  final VoidCallback? onCloseMobile;

  const AdminSidebar({
    super.key,
    required this.collapsed,
    required this.activeRoute,
    required this.onToggleCollapse,
    this.onCloseMobile,
  });

  static const List<AdminNavItem> items = [
    // Overview
    AdminNavItem(category: 'OVERVIEW', label: 'Dashboard', icon: Icons.grid_view_rounded, route: AppRoutes.adminDashboard),
    AdminNavItem(category: 'OVERVIEW', label: 'Field GIS Map', icon: Icons.map_rounded, route: AppRoutes.adminMap),
    
    // Operations & Field Management
    AdminNavItem(category: 'OPERATIONS', label: 'Add Schedule', icon: Icons.add_circle_outline_rounded, route: '', isAction: true),
    AdminNavItem(category: 'OPERATIONS', label: 'Farmers', icon: Icons.people_alt_rounded, route: AppRoutes.farmerManagement),
    AdminNavItem(category: 'OPERATIONS', label: 'Scan Records', icon: Icons.center_focus_strong_rounded, route: AppRoutes.detectionRecords),
    AdminNavItem(category: 'OPERATIONS', label: 'Schedules', icon: Icons.event_note_rounded, route: AppRoutes.adminCalendar, hasBadge: true),
    AdminNavItem(category: 'OPERATIONS', label: 'Soil & Weather', icon: Icons.cloud_outlined, route: AppRoutes.adminSoilWeather),
    AdminNavItem(category: 'OPERATIONS', label: 'Model Trainer', icon: Icons.psychology_rounded, route: AppRoutes.adminModelTrainer),
    
    // System & Data
    AdminNavItem(category: 'SYSTEM', label: 'Announcements', icon: Icons.campaign_rounded, route: AppRoutes.adminAnnouncement),
    AdminNavItem(category: 'SYSTEM', label: 'Archive Vault', icon: Icons.inventory_2_outlined, route: AppRoutes.adminArchive),
    AdminNavItem(category: 'SYSTEM', label: 'Admin Profile', icon: Icons.manage_accounts_rounded, route: AppRoutes.adminProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 80.0 : 256.0;
    final categories = ['OVERVIEW', 'OPERATIONS', 'SYSTEM'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.adminPrimaryDark,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF044C29),
            Color(0xFF03381E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Sidebar Brand Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: collapsed
                  ? Center(
                      child: Tooltip(
                        message: 'Expand sidebar',
                        child: InkWell(
                          onTap: () => onToggleCollapse(false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_open_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPrimary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandPrimary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMARTFARMING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Command Portal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Collapse sidebar',
                          onPressed: () => onToggleCollapse(true),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // ── Categorized Nav Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: categories.map((cat) {
                  final catItems = items.where((i) => i.category == cat).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!collapsed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 16, 6),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                      ...catItems.map((item) {
                        final active = activeRoute == item.route;
                        return _NavTile(
                          item: item,
                          active: active,
                          collapsed: collapsed,
                          onTap: () {
                            if (item.isAction) {
                              showAddScheduleDialog(context);
                            } else if (ModalRoute.of(context)?.settings.name != item.route) {
                              Navigator.of(context).pushReplacementNamed(item.route);
                            }
                            onCloseMobile?.call();
                          },
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),

            // ── Footer Admin User Profile ──
            const Divider(color: Colors.white10, height: 1),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: collapsed
                      ? Center(
                          child: Tooltip(
                            message: '${user?.name ?? 'Admin'} (Click to view profile)',
                            child: InkWell(
                              onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProfile),
                              borderRadius: BorderRadius.circular(10),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: Colors.white.withValues(alpha: 0.18),
                                child: Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.brandPrimary,
                                child: Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'System Admin',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Super Admin',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                                tooltip: 'Logout',
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Sign Out'),
                                      content: const Text('Are you sure you want to sign out of the Admin Portal?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sign Out'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    await auth.signOut();
                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final AdminNavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 12,
              vertical: 9,
            ),
            child: Row(
              mainAxisAlignment:
                  collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  color: active ? Colors.white : Colors.white70,
                  size: 19,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (item.hasBadge)
                    Consumer<TreatmentProvider>(
                      builder: (context, tp, _) {
                        final pending = tp.pendingTreatments.length;
                        if (pending == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pending',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  if (active && !item.hasBadge)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.adminAccent,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: tileContent,
      );
    }
    return tileContent;
  }
}

