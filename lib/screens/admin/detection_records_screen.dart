import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/detection_provider.dart';
import '../../models/detection_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/photo_download_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/detection_details_dialog.dart';
import '../../analytics/scan_analytics.dart';
import '../../widgets/app_feedback.dart';

class DetectionRecordsScreen extends StatefulWidget {
  const DetectionRecordsScreen({super.key});

  @override
  State<DetectionRecordsScreen> createState() => _DetectionRecordsScreenState();
}

class _DetectionRecordsScreenState extends State<DetectionRecordsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedDiseaseFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        title: 'Crop AI Disease Diagnosis Vault',
        subtitle: 'Audited visual scan records, confidence ratings & geolocation diagnostics',
        activeRoute: AppRoutes.detectionRecords,
        body: Column(
          children: [
            // ── Tab Bar & Filter Controls ──
            Container(
              margin: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppTheme.adminCardDecoration(),
              child: Row(
                children: [
                  const Expanded(
                    child: TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Active Detections'),
                        Tab(text: 'Archived Vault'),
                      ],
                      labelColor: AppTheme.adminPrimary,
                      unselectedLabelColor: AppTheme.adminTextSecondary,
                      indicatorColor: AppTheme.adminPrimary,
                      indicatorWeight: 3,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.adminSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.adminBorder),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Search disease, farmer...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppTheme.adminTextMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.adminTextSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 12),
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
                ],
              ),
            ),

            // ── Disease Filter Chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All'),
                    _filterChip('Healthy'),
                    _filterChip('Brown Spot'),
                    _filterChip('Sheath Blight'),
                    _filterChip('Bacterial Leaf Blight'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Consumer<DetectionProvider>(
                builder: (context, dp, _) {
                  if (dp.errorMessage != null && dp.detections.isEmpty) {
                    return _DetectionLoadError(
                      message: dp.errorMessage!,
                      onRetry: () => dp.loadDetections(''),
                    );
                  }

                  if (dp.isLoading && dp.detections.isEmpty) {
                    return const ListCardSkeleton(count: 6);
                  }

                  final valid = validScanRecords(dp.detections);
                  final active = _applyFilter(valid.where((d) => !d.isArchived).toList());
                  final archived = _applyFilter(valid.where((d) => d.isArchived).toList());

                  return TabBarView(
                    children: [
                      _DetectionRecordList(detections: active, dp: dp, isArchivedList: false),
                      _DetectionRecordList(detections: archived, dp: dp, isArchivedList: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedDiseaseFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        onSelected: (val) {
          setState(() {
            _selectedDiseaseFilter = val ? label : 'All';
          });
        },
      ),
    );
  }

  List<DetectionModel> _applyFilter(List<DetectionModel> list) {
    return list.where((d) {
      if (_selectedDiseaseFilter != 'All') {
        if (!d.disease.toLowerCase().contains(_selectedDiseaseFilter.toLowerCase())) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDisease = d.disease.toLowerCase().contains(q);
        final matchLoc = d.locationStatus.toLowerCase().contains(q);
        final matchCrop = d.crop.toLowerCase().contains(q);
        if (!matchDisease && !matchLoc && !matchCrop) return false;
      }
      return true;
    }).toList();
  }
}

class _DetectionRecordList extends StatelessWidget {
  final List<DetectionModel> detections;
  final DetectionProvider dp;
  final bool isArchivedList;

  const _DetectionRecordList({
    required this.detections,
    required this.dp,
    required this.isArchivedList,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.adminSurfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isArchivedList ? Icons.archive_outlined : Icons.camera_alt_outlined,
                  size: 44,
                  color: AppTheme.adminTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isArchivedList ? 'No archived detection records found' : 'No detection records match criteria',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.adminTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => dp.loadDetections(''),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive 2-column or 1-column layout
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return GridView.builder(
              padding: const EdgeInsets.all(22),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemCount: detections.length,
              itemBuilder: (context, index) => _DetectionCard(detection: detections[index], isHorizontal: true),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(22),
            itemCount: detections.length,
            itemBuilder: (context, index) => _DetectionCard(detection: detections[index], isHorizontal: false),
          );
        },
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final DetectionModel detection;
  final bool isHorizontal;

  const _DetectionCard({required this.detection, this.isHorizontal = false});

  Color _diseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('healthy')) return const Color(0xFF16A34A);
    if (d.contains('brown spot')) return const Color(0xFFD97706);
    if (d.contains('sheath blight')) return const Color(0xFFEA580C);
    if (d.contains('bacterial')) return const Color(0xFFDC2626);
    return AppTheme.adminPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _diseaseColor(detection.disease);

    return FutureBuilder<UserModel?>(
      future: FirebaseService().getUserData(detection.userId),
      builder: (context, snap) {
        final farmerName = snap.data?.name ?? 'Farmer';

        if (isHorizontal) {
          // Horizontal compact card for grid layout
          return Container(
            decoration: AppTheme.adminCardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail
                Container(
                  width: 170,
                  color: AppTheme.adminSurfaceSubtle,
                  child: detection.imageUrl.isNotEmpty
                      ? Image.network(
                          detection.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 36, color: AppTheme.adminTextMuted),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported_rounded, size: 36, color: AppTheme.adminTextMuted),
                        ),
                ),
                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    detection.disease,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(detection.confidence * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _miniRow(Icons.person_outline_rounded, farmerName),
                            _miniRow(
                              detection.isInsideFarm ? Icons.location_on_outlined : Icons.wrong_location_outlined,
                              detection.locationStatus,
                            ),
                            _miniRow(
                              Icons.calendar_today_outlined,
                              DateFormat('MMM dd, yyyy • HH:mm').format(detection.timestamp),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => DetectionDetailsDialog.show(context, detection, farmerName),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.info_outline_rounded, size: 14),
                              label: const Text('View', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            _DownloadMenu(detection: detection, farmerName: farmerName),
                            const Spacer(),
                            _ArchiveButton(detection: detection),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Full vertical card for single-column mobile/compact layout
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.adminCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detection.imageUrl.isNotEmpty)
                Image.network(
                  detection.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.adminSurfaceSubtle,
                    child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: AppTheme.adminTextMuted)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            detection.disease,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(detection.confidence * 100).toStringAsFixed(1)}% Confidence',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _miniRow(Icons.person_outline_rounded, 'Farmer: $farmerName'),
                    _miniRow(
                      detection.isInsideFarm ? Icons.location_on_outlined : Icons.wrong_location_outlined,
                      'Location: ${detection.locationStatus}',
                    ),
                    if (detection.latitude != null && detection.longitude != null)
                      _miniRow(
                        Icons.pin_drop_outlined,
                        'Coordinates: ${detection.latitude!.toStringAsFixed(5)}, ${detection.longitude!.toStringAsFixed(5)}',
                      ),
                    _miniRow(
                      Icons.calendar_today_outlined,
                      'Date: ${DateFormat('MMM dd, yyyy • HH:mm').format(detection.timestamp)}',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => DetectionDetailsDialog.show(context, detection, farmerName),
                          icon: const Icon(Icons.info_outline_rounded, size: 16),
                          label: const Text('View Diagnostics'),
                        ),
                        const SizedBox(width: 8),
                        _DownloadMenu(detection: detection, farmerName: farmerName),
                        const Spacer(),
                        _ArchiveButton(detection: detection),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.adminTextSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.adminTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadMenu extends StatelessWidget {
  final DetectionModel detection;
  final String farmerName;

  const _DownloadMenu({required this.detection, required this.farmerName});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'photo') {
          PhotoDownloadService.downloadPhoto(
            context: context,
            imageUrl: detection.imageUrl,
            fileName: 'detection_${detection.disease.replaceAll(' ', '_')}_${detection.id}.jpg',
          );
        } else if (val == 'report') {
          PhotoDownloadService.downloadDetectionReport(
            context: context,
            detection: detection,
            farmerName: farmerName,
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'photo',
          child: Row(
            children: [
              Icon(Icons.image_rounded, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Save Image', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text('Download PDF Report', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        icon: const Icon(Icons.download_rounded, size: 14),
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export', style: TextStyle(fontSize: 11)),
            Icon(Icons.arrow_drop_down_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ArchiveButton extends StatefulWidget {
  final DetectionModel detection;

  const _ArchiveButton({required this.detection});

  @override
  State<_ArchiveButton> createState() => _ArchiveButtonState();
}

class _ArchiveButtonState extends State<_ArchiveButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    final detection = widget.detection;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(detection.isArchived ? 'Restore Detection' : 'Archive Detection'),
        content: Text(
          detection.isArchived
              ? 'Restore this detection record back to active list?'
              : 'Archive this detection record? Metadata will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(detection.isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final dp = Provider.of<DetectionProvider>(context, listen: false);
    bool success;
    try {
      success = detection.isArchived
          ? await dp.unarchiveDetection(detection.id)
          : await dp.archiveDetection(detection.id);
    } catch (e) {
      success = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      AppFeedback.success(
        context,
        detection.isArchived
            ? 'Detection restored to active list.'
            : 'Detection archived successfully.',
      );
    } else {
      AppFeedback.error(
        context,
        'Unable to update detection. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detection = widget.detection;
    return ElevatedButton.icon(
      onPressed: _busy ? null : _handleTap,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(detection.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, size: 14),
      label: Text(
        _busy
            ? (detection.isArchived ? 'Restoring...' : 'Archiving...')
            : (detection.isArchived ? 'Restore' : 'Archive'),
        style: const TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: detection.isArchived ? AppTheme.adminPrimary : const Color(0xFFD97706),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _DetectionLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetectionLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppTheme.adminTextMuted),
            const SizedBox(height: 14),
            const Text(
              'Could not load detection records',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.adminTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

