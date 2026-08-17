import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'farmer_settings_sheet.dart';

class AppDrawer extends StatelessWidget {
  final String activeRoute;

  const AppDrawer({
    super.key,
    this.activeRoute = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Farmer';
    final userEmail = user?.email ?? 'farmer@smartfarming.com';
    final farmLocation = user?.farmLocation ?? 'Registered Rice Field';

    return Drawer(
      child: Column(
        children: [
          // ── Drawer Header ──
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.brandPrimary,
                  Color(0xFF0B6B43),
                ],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPrimary,
                ),
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        farmLocation,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Menu Options ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: l10n.dashboard,
                  route: AppRoutes.dashboard,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  route: AppRoutes.profile,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.camera_alt_rounded,
                  title: 'Capture Detection',
                  route: AppRoutes.cameraDetection,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.center_focus_strong_rounded,
                  title: 'Real-Time Scan',
                  route: AppRoutes.realTimeScan,
                  isHighlighted: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Detection History',
                  route: AppRoutes.detectionHistory,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.map_rounded,
                  title: 'My Detection Locations',
                  route: AppRoutes.myLocations,
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Treatment Schedule',
                  route: AppRoutes.treatmentCalendar,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_rounded,
                  title: 'Reports & Analytics',
                  route: AppRoutes.reports,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.grass_rounded,
                  title: l10n.soilMonitoring,
                  route: AppRoutes.soilMonitoring,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.cloud_rounded,
                  title: l10n.weather,
                  route: AppRoutes.weatherDetails,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Farm Assistant',
                  route: AppRoutes.aiAssistant,
                  isHighlighted: true,
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: AppTheme.brandPrimary),
                  title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    FarmerSettingsSheet.show(context);
                  },
                ),
              ],
            ),
          ),

          // ── Logout Action at Bottom ──
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(l10n.logout),
                  content: Text(l10n.logoutConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(l10n.logout),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                Navigator.pop(context); // Close drawer
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                }
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isHighlighted = false,
  }) {
    final isSelected = activeRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.brandPrimary.withValues(alpha: 0.12)
            : (isHighlighted ? Colors.green.shade50 : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected || isHighlighted ? AppTheme.brandPrimary : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected || isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isSelected || isHighlighted ? AppTheme.brandPrimary : Colors.black87,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isSelected) {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }
}
