import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'admin_sidebar.dart';

class AdminScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String activeRoute;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.activeRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1080;
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.adminPrimary,
        elevation: 0,
        scrolledUnderElevation: 3,
        shadowColor: Colors.black26,
        titleSpacing: isDesktop ? 20 : 8,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        actions: [
          if (isDesktop) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record_rounded, size: 10, color: Color(0xFF4ADE80)),
                  SizedBox(width: 6),
                  Text(
                    'Live Telemetry',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          ...(widget.actions ?? []),
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 20),
            tooltip: 'Dashboard',
            onPressed: () {
              if (widget.activeRoute != AppRoutes.adminDashboard) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Colors.white, size: 20),
            tooltip: 'Broadcast Announcement',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminAnnouncement),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProfile),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.brandPrimary,
                    child: Text(
                      (currentUser?.name.isNotEmpty == true)
                          ? currentUser!.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 8),
                    Text(
                      currentUser?.name ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                collapsed: false,
                activeRoute: widget.activeRoute,
                onToggleCollapse: (_) {},
                onCloseMobile: () => Navigator.of(context).pop(),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              collapsed: _sidebarCollapsed,
              activeRoute: widget.activeRoute,
              onToggleCollapse: (value) => setState(() => _sidebarCollapsed = value),
            ),
          Expanded(
            child: Container(
              color: AppTheme.adminBackground,
              child: widget.body,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

