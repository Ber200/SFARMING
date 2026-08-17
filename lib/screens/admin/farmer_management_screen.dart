import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_data_table.dart';
import '../../widgets/app_feedback.dart';

class FarmerManagementScreen extends StatefulWidget {
  const FarmerManagementScreen({super.key});

  @override
  State<FarmerManagementScreen> createState() => _FarmerManagementScreenState();
}

class _FarmerManagementScreenState extends State<FarmerManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchCtrl = TextEditingController();
  String? _errorMessage;
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'farmer', 'admin'

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _firebaseService.isCurrentUserAdmin();
      if (!isAdmin && mounted) {
        setState(() {
          _errorMessage = 'Access denied. Admin privileges required.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to verify admin access: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Farmer & User Directory',
      subtitle: 'Manage agricultural stakeholders, field personnel, and access privileges',
      activeRoute: AppRoutes.farmerManagement,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddFarmerDialog(context),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Register User', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.adminPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ],
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_person_rounded, size: 54, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<List<UserModel>>(
              stream: _firebaseService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 54, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(fontSize: 14, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _errorMessage = null);
                              _checkAdminAccess();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final filteredUsers = allUsers.where((u) {
                  final matchesSearch = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (u.farmLocation ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesRole = _roleFilter == 'all' ||
                      (_roleFilter == 'farmer' && u.isFarmer) ||
                      (_roleFilter == 'admin' && u.isAdmin);
                  return matchesSearch && matchesRole;
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search & Filter Header Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.adminCardDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.adminSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.adminBorder),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search user name, email, or farm location...',
                                    hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextMuted),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.adminTextSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(bottom: 10),
                                    isDense: true,
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 14),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Wrap(
                              spacing: 8,
                              children: [
                                _filterChip('All (${allUsers.length})', 'all'),
                                _filterChip('Farmers (${allUsers.where((u) => u.isFarmer).length})', 'farmer'),
                                _filterChip('Admins (${allUsers.where((u) => u.isAdmin).length})', 'admin'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Users List / Responsive Table
                      if (filteredUsers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(48),
                          decoration: AppTheme.adminCardDecoration(),
                          child: Column(
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.adminTextMuted),
                              const SizedBox(height: 14),
                              const Text(
                                'No registered users match your search criteria.',
                                style: TextStyle(color: AppTheme.adminTextSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 800) {
                              return _buildDesktopTable(context, filteredUsers);
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) => _buildMobileCard(context, filteredUsers[index]),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<UserModel> users) {
    return Container(
      decoration: AppTheme.adminCardDecoration(),
      child: AdminDataTable(
        columns: const [
          AdminTableColumn(title: 'FARMER / USER', flex: true),
          AdminTableColumn(title: 'ROLE', width: 120),
          AdminTableColumn(title: 'FARM LOCATION', flex: true),
          AdminTableColumn(title: 'CONTACT EMAIL', flex: true),
          AdminTableColumn(title: 'ACTIONS', width: 80, alignment: Alignment.centerRight),
        ],
        rows: users.map((user) {
          final isAdm = user.isAdmin;
          return [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isAdm ? const Color(0xFFF3E8FF) : AppTheme.adminPrimaryLight,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: isAdm ? const Color(0xFF7C3AED) : AppTheme.adminPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary),
                  ),
                ),
              ],
            ),
            AdminStatusBadge(
              label: user.role.toUpperCase(),
              type: isAdm ? AdminStatusType.info : AdminStatusType.success,
              icon: isAdm ? Icons.shield_rounded : Icons.grass_rounded,
            ),
            Text(
              user.farmLocation?.isNotEmpty == true ? user.farmLocation! : 'Not specified',
              style: TextStyle(
                fontSize: 12.5,
                color: user.farmLocation?.isNotEmpty == true ? AppTheme.adminTextPrimary : AppTheme.adminTextMuted,
              ),
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.adminTextSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') _showEditFarmerDialog(context, user);
                if (val == 'delete') _showDeleteConfirmation(context, user);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Account', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Account', style: TextStyle(fontSize: 12.5, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: user.isAdmin ? const Color(0xFFF3E8FF) : AppTheme.adminPrimaryLight,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: user.isAdmin ? const Color(0xFF7C3AED) : AppTheme.adminPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
                        ),
                        const SizedBox(width: 8),
                        AdminStatusBadge(
                          label: user.role.toUpperCase(),
                          type: user.isAdmin ? AdminStatusType.info : AdminStatusType.success,
                          icon: user.isAdmin ? Icons.shield_rounded : Icons.grass_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 13, color: AppTheme.adminTextMuted),
                        const SizedBox(width: 4),
                        Text(user.email, style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary)),
                      ],
                    ),
                    if (user.farmLocation != null && user.farmLocation!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.adminTextMuted),
                          const SizedBox(width: 4),
                          Text(user.farmLocation!, style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.adminBorderLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditFarmerDialog(context, user),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, user),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text('Delete', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _roleFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.adminTextPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.adminPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.adminPrimary : AppTheme.adminBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _roleFilter = value),
    );
  }

  void _showAddFarmerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = 'farmer';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Register New User / Farmer'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Account Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Farm Location / Barangay',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _firebaseService.registerWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          nameController.text.trim(),
                          selectedRole,
                          locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          AppFeedback.success(context, 'Account registered successfully!');
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          AppFeedback.error(context, 'Failed to add user: $e');
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Register User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFarmerDialog(BuildContext context, UserModel farmer) {
    final nameController = TextEditingController(text: farmer.name);
    final locationController = TextEditingController(text: farmer.farmLocation ?? '');
    final formKey = GlobalKey<FormState>();
    String selectedRole = farmer.role;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Profile: ${farmer.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Account Role'),
                    items: const [
                      DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Farm Location / Barangay',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _firebaseService.updateUserData(farmer.id, {
                          'name': nameController.text.trim(),
                          'role': selectedRole,
                          'farmLocation': locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                        });
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          AppFeedback.success(context, 'Account details updated successfully!');
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          AppFeedback.error(context, 'Failed to update user.');
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel farmer) {
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete User Account'),
          content: Text('Are you sure you want to delete ${farmer.name} (${farmer.email})? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _firebaseService.deleteUserData(farmer.id);
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          AppFeedback.success(context, 'Account deleted successfully!');
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          AppFeedback.error(context, 'Failed to delete account.');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

