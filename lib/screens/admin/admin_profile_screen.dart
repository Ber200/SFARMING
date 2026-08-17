import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Administrator Profile & System Settings',
      subtitle: 'Security credentials, platform localization & command settings',
      activeRoute: AppRoutes.adminProfile,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    // Admin Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: AppTheme.adminCardDecoration(),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.adminPrimary, Color(0xFF16A34A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.adminPrimary.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.name ?? 'Admin Officer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.adminTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'admin@smartfarming.com',
                            style: const TextStyle(color: AppTheme.adminTextSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.adminPrimaryLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.adminPrimary.withValues(alpha: 0.2)),
                            ),
                            child: const Text(
                              'SYSTEM ADMINISTRATOR',
                              style: TextStyle(
                                color: AppTheme.adminPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions List
                    _buildProfileCard(
                      context,
                      icon: Icons.language_rounded,
                      title: AppLocalizations.of(context)!.language,
                      subtitle: Provider.of<LanguageProvider>(context).language.displayName,
                      onTap: () => _showLanguageOptions(context, Provider.of<LanguageProvider>(context, listen: false)),
                    ),
                    const SizedBox(height: 10),
                    _buildProfileCard(
                      context,
                      icon: Icons.analytics_rounded,
                      title: 'Live Telemetry & Dashboard Overview',
                      subtitle: 'Access command dashboard charts and agronomy metrics',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminDashboard),
                    ),
                    const SizedBox(height: 10),
                    _buildProfileCard(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Farmer & User Directory',
                      subtitle: 'Manage farmer accounts, permissions and field assignments',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.farmerManagement),
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(l10n.logout),
                                content: Text(l10n.logoutConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(l10n.logout),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldLogout == true && context.mounted) {
                            await authProvider.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
                            }
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.adminCardDecoration(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.adminPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.adminPrimary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.adminTextMuted, size: 20),
      ),
    );
  }

  void _showLanguageOptions(BuildContext context, LanguageProvider langProvider) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.selectLanguage,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.adminTextPrimary),
                ),
              ),
              const SizedBox(height: 12),
              ...AppLanguage.values.map((lang) => ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppTheme.adminPrimary, size: 20),
                    title: Text(lang.displayName, style: const TextStyle(fontSize: 13.5)),
                    trailing: langProvider.language == lang
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.adminPrimary, size: 20)
                        : null,
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
}
