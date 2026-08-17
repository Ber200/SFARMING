import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/offline_banner.dart';
import '../../../widgets/farmer_bottom_nav_bar.dart';
import '../../../widgets/farmer_settings_sheet.dart';
import '../../../widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.profile),
      body: Consumer2<AuthProvider, ConnectivityProvider>(
        builder: (context, authProvider, connectivity, _) {
          final user = authProvider.currentUser;
          final isOffline =
              !connectivity.isOnline || authProvider.isOfflineMode;

          return Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: AppTheme.farmCardDecoration(),
                        child: Column(
                          children: [
                            // Profile Picture Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandPrimary.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 54,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.brandLight,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // User Name + offline badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.name ?? l10n.farmer,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandPrimary,
                                          fontSize: 22,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (authProvider.isOfflineMode) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.orange.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.wifi_off_rounded,
                                            size: 12,
                                            color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Offline',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.isOfflineMode
                                  ? 'Offline Mode'
                                  : (user?.email ?? ''),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Consumer<DetectionProvider>(
                              builder: (context, dp, _) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.analytics_rounded, size: 16, color: AppTheme.brandPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Total Scans: ${dp.totalDetections}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.brandPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account Settings Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Account & Preferences',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Edit Profile
                      _buildProfileCard(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: l10n.editProfile,
                        subtitle: isOffline
                            ? 'Not available in offline mode'
                            : l10n.editProfileSubtitle,
                        disabled: isOffline,
                        onTap: isOffline
                            ? () => _showOfflineToast(context)
                            : () => _showEditProfileDialog(context, authProvider),
                      ),
                      const SizedBox(height: 10),

                      // Farm Location
                      _buildProfileCard(
                        context,
                        icon: Icons.location_on_outlined,
                        title: l10n.farmLocation,
                        subtitle: isOffline
                            ? 'Not available in offline mode'
                            : (user?.farmLocation ?? l10n.notSet),
                        disabled: isOffline,
                        onTap: isOffline
                            ? () => _showOfflineToast(context)
                            : () => _showEditProfileDialog(context, authProvider),
                      ),
                      const SizedBox(height: 10),

                      // Settings
                      _buildProfileCard(
                        context,
                        icon: Icons.settings_outlined,
                        title: l10n.settings,
                        subtitle: l10n.settingsSubtitle,
                        onTap: () {
                          FarmerSettingsSheet.show(context);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Language
                      Consumer<LanguageProvider>(
                        builder: (context, langProvider, _) =>
                            _buildProfileCard(
                          context,
                          icon: Icons.language_rounded,
                          title: l10n.language,
                          subtitle: langProvider.language.displayName,
                          onTap: () =>
                              _showLanguageOptions(context, langProvider),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(authProvider.isOfflineMode
                                    ? 'Exit Offline Mode'
                                    : l10n.logout),
                                content: Text(authProvider.isOfflineMode
                                    ? 'Exit offline mode and return to login?'
                                    : l10n.logoutConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: authProvider.isOfflineMode
                                          ? Colors.orange
                                          : Colors.red,
                                    ),
                                    child: Text(authProvider.isOfflineMode
                                        ? 'Exit'
                                        : l10n.logout),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true && context.mounted) {
                              await authProvider.signOut();
                              if (context.mounted) {
                                Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.login);
                              }
                            }
                          },
                          icon: Icon(authProvider.isOfflineMode
                              ? Icons.wifi_off_rounded
                              : Icons.logout_rounded),
                          label: Text(authProvider.isOfflineMode
                              ? 'Exit Offline Mode'
                              : l10n.logout),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: authProvider.isOfflineMode
                                ? Colors.orange
                                : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const FarmerBottomNavBar(currentIndex: 3),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.currentUser?.name ?? '');
    final locationController = TextEditingController(text: authProvider.currentUser?.farmLocation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Farmer Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Farm Location / Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newLocation = locationController.text.trim();
              if (newName.isEmpty) return;

              final ok = await authProvider.updateUserProfile(
                name: newName,
                farmLocation: newLocation.isEmpty ? null : newLocation,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Profile updated successfully!' : 'Failed to update profile.'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showOfflineToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('This feature requires an internet connection.'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageOptions(
      BuildContext context, LanguageProvider langProvider) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.selectLanguage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) => ListTile(
                    leading: Icon(
                      langProvider.language == lang
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: langProvider.language == lang
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    title: Text(lang.displayName),
                    onTap: () {
                      langProvider.setLanguage(lang);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: AppTheme.farmCardDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: disabled
                          ? Colors.grey.shade200
                          : AppTheme.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: disabled ? Colors.grey.shade600 : AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    disabled ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
