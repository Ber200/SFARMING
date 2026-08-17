import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/detection_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/detection_details_dialog.dart';
import '../../../widgets/offline_banner.dart';

class DetectionHistoryScreen extends StatefulWidget {
  const DetectionHistoryScreen({super.key});

  @override
  State<DetectionHistoryScreen> createState() => _DetectionHistoryScreenState();
}

class _DetectionHistoryScreenState extends State<DetectionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    final isOnline = connectivity.isOnline && !authProvider.isOfflineMode;

    if (userId.isNotEmpty) {
      Provider.of<DetectionProvider>(context, listen: false)
          .loadDetections(userId, isOnline: isOnline);
    }
  }

  List<DetectionModel> _filtered(List<DetectionModel> all) {
    final list = all.where((d) => d.isArchived == _showArchived).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((d) =>
            d.disease.toLowerCase().contains(q) ||
            d.status.toLowerCase().contains(q) ||
            d.crop.toLowerCase().contains(q))
        .toList();
  }

  String get _farmerName {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name;
    return name != null && name.isNotEmpty ? name : 'Farmer';
  }

  Future<void> _showDetails(DetectionModel detection) async {
    await DetectionDetailsDialog.show(context, detection, _farmerName);
    if (mounted) _loadData();
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return const Color(0xFF2E7D32);
    if (confidence >= 0.65) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.brandMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCardAction(String action, DetectionModel detection) async {
    if (!detection.synced) {
      _showSnack('This record was created offline. Connect to the internet to manage it.', isError: true);
      return;
    }

    final dp = Provider.of<DetectionProvider>(context, listen: false);

    if (action == 'archive' || action == 'restore') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(detection.isArchived ? 'Restore Detection' : 'Archive Detection'),
          content: Text(
            detection.isArchived
                ? 'Move "${detection.disease}" back to the active list?'
                : 'Move "${detection.disease}" to the archive?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: detection.isArchived ? Colors.blue : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(detection.isArchived ? 'Restore' : 'Archive'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      final ok = detection.isArchived
          ? await dp.unarchiveDetection(detection.id)
          : await dp.archiveDetection(detection.id);
      _showSnack(ok
          ? (detection.isArchived ? 'Detection restored.' : 'Detection archived.')
          : 'Failed to update detection. Please try again.');
      if (ok && mounted) _loadData();
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Detection'),
          content: Text('Permanently delete "${detection.disease}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      final ok = await dp.deleteDetection(detection.id);
      _showSnack(ok ? 'Detection deleted.' : 'Failed to delete detection. Please try again.');
      if (ok && mounted) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Detection History'),
        elevation: 0,
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.detectionHistory),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.brandPrimary,
              Color(0xFF0B6B43),
              Color(0xFFF5FAF7),
            ],
            stops: [0.0, 0.12, 0.35],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: Consumer<DetectionProvider>(
                  builder: (context, dp, _) {
                    final all = dp.detections;
                    return Column(
                      children: [
                        _headerPanel(all),
                        _searchField(),
                        _filterChips(),
                        const SizedBox(height: 8),
                        Expanded(child: _buildBody(dp)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerPanel(List<DetectionModel> all) {
    final total = all.length;
    final active = all.where((d) => !d.isArchived).length;
    final archived = all.where((d) => d.isArchived).length;
    final avg = all.isEmpty
        ? 0.0
        : all.map((d) => d.confidence).reduce((a, b) => a + b) / all.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandPrimary, AppTheme.brandMid],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All your scan results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track every disease detection on your farm in one place.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(total, 'Total'),
              _statItem(active, 'Active'),
              _statItem(archived, 'Archived'),
              _statItem(avg * 100, 'Avg %'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(num value, String label) {
    return Column(
      children: [
        Text(
          value is int ? '$value' : value.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
        ),
      ],
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by disease, status, or crop',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.brandPrimary),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _chip('Active', active: !_showArchived, onTap: () => setState(() => _showArchived = false)),
          const SizedBox(width: 10),
          _chip('Archived', active: _showArchived, onTap: () => setState(() => _showArchived = true)),
        ],
      ),
    );
  }

  Widget _chip(String label, {required bool active, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.brandPrimary.withValues(alpha: 0.12),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: active ? AppTheme.brandPrimary : Colors.grey[600],
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: active ? AppTheme.brandPrimary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBody(DetectionProvider dp) {
    final filtered = _filtered(dp.detections);

    if (dp.isLoading && dp.detections.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandPrimary),
      );
    }

    if (dp.detections.isEmpty) {
      return _emptyState(
        icon: Icons.history_rounded,
        title: 'No detections yet',
        subtitle: 'Capture an image of your rice leaf to run a disease scan.',
        showScanButton: true,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: AppTheme.brandPrimary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: filtered.isEmpty ? 1 : filtered.length,
        itemBuilder: (context, index) {
          if (filtered.isEmpty) {
            return _emptyState(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              subtitle: 'Try a different search term or switch the filter.',
              showScanButton: false,
            );
          }
          return _buildCard(filtered[index]);
        },
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showScanButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.brandMid),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (showScanButton) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cameraDetection),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Scan Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(DetectionModel d) {
    final confidenceColor = _confidenceColor(d.confidence);
    final isArchived = d.isArchived;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.farmCardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetails(d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumbnail(d),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.disease.isEmpty ? 'Unidentified' : d.disease,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (d.isLowConfidence)
                          const Tooltip(
                            message: 'Low confidence result',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _confidenceChip(d.confidence, confidenceColor),
                        const SizedBox(width: 8),
                        _statusChip(isArchived),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(d.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey[700]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) => _onCardAction(v, d),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: isArchived ? 'restore' : 'archive',
                    child: Row(
                      children: [
                        Icon(isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                            size: 18, color: AppTheme.brandMid),
                        const SizedBox(width: 10),
                        Text(isArchived ? 'Restore' : 'Archive'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(DetectionModel d) {
    if (d.imageUrl.isEmpty) return _placeholderThumb();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Image.network(
          d.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 72,
              height: 72,
              color: AppTheme.lightGreen,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.brandMid,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _placeholderThumb(),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandLight, AppTheme.brandMid],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.eco_rounded, size: 30, color: Colors.white),
    );
  }

  Widget _confidenceChip(double confidence, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _statusChip(bool isArchived) {
    final color = isArchived ? Colors.grey : AppTheme.brandMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isArchived ? 'Archived' : 'Active',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
