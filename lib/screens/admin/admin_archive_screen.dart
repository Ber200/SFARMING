import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_localizations.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/detection_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/photo_download_service.dart';
import '../../models/treatment_model.dart';
import '../../models/detection_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/detection_details_dialog.dart';
import '../../analytics/scan_analytics.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/app_feedback.dart';

enum ArchiveSortBy { date, disease, farmer, treatment }

/// Admin Archive page: switchable tabs for Archived Scanned Images & Archived Treatments with search, sort, restore, and permanent delete.
class AdminArchiveScreen extends StatefulWidget {
  const AdminArchiveScreen({super.key});

  @override
  State<AdminArchiveScreen> createState() => _AdminArchiveScreenState();
}

class _AdminArchiveScreenState extends State<AdminArchiveScreen> {
  final FirebaseService _firebase = FirebaseService();
  final TextEditingController _searchController = TextEditingController();

  ArchiveSortBy _sortBy = ArchiveSortBy.date;
  bool _sortAscending = false;
  String? _filterTreatment;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _loadNameCache(List<String> userIds) async {
    final cache = <String, String>{};
    for (final id in userIds) {
      final user = await _firebase.getUserData(id);
      cache[id] = user?.name ?? 'Farmer';
    }
    return cache;
  }

  List<TreatmentModel> _filterAndSortTreatments(
    List<TreatmentModel> list,
    String search,
    Map<String, String> nameCache,
  ) {
    var result = list;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((t) {
        final diseaseMatch = t.disease.toLowerCase().contains(q);
        final farmerName = nameCache[t.userId] ?? '';
        final farmerMatch = farmerName.toLowerCase().contains(q);
        return diseaseMatch || farmerMatch;
      }).toList();
    }
    if (_filterTreatment != null && _filterTreatment!.isNotEmpty) {
      result = result.where((t) => t.type == _filterTreatment).toList();
    }
    result = List<TreatmentModel>.from(result);
    switch (_sortBy) {
      case ArchiveSortBy.date:
        result.sort((a, b) => _sortAscending
            ? a.scheduleDate.compareTo(b.scheduleDate)
            : b.scheduleDate.compareTo(a.scheduleDate));
        break;
      case ArchiveSortBy.disease:
        result.sort((a, b) {
          final cmp = a.disease.compareTo(b.disease);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case ArchiveSortBy.treatment:
        result.sort((a, b) {
          final cmp = a.type.compareTo(b.type);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case ArchiveSortBy.farmer:
        result.sort((a, b) {
          final cmp = (nameCache[a.userId] ?? '').compareTo(nameCache[b.userId] ?? '');
          return _sortAscending ? cmp : -cmp;
        });
        break;
    }
    return result;
  }

  List<DetectionModel> _filterAndSortDetections(
    List<DetectionModel> list,
    String search,
    Map<String, String> nameCache,
  ) {
    var result = list;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((d) {
        final diseaseMatch = d.disease.toLowerCase().contains(q);
        final notesMatch = (d.notes ?? '').toLowerCase().contains(q);
        final farmerName = nameCache[d.userId] ?? '';
        final farmerMatch = farmerName.toLowerCase().contains(q);
        return diseaseMatch || notesMatch || farmerMatch;
      }).toList();
    }
    result = List<DetectionModel>.from(result);
    switch (_sortBy) {
      case ArchiveSortBy.date:
        result.sort((a, b) => _sortAscending
            ? a.timestamp.compareTo(b.timestamp)
            : b.timestamp.compareTo(a.timestamp));
        break;
      case ArchiveSortBy.disease:
        result.sort((a, b) {
          final cmp = a.disease.compareTo(b.disease);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case ArchiveSortBy.farmer:
        result.sort((a, b) {
          final cmp = (nameCache[a.userId] ?? '').compareTo(nameCache[b.userId] ?? '');
          return _sortAscending ? cmp : -cmp;
        });
        break;
      default:
        result.sort((a, b) => _sortAscending
            ? a.timestamp.compareTo(b.timestamp)
            : b.timestamp.compareTo(a.timestamp));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        title: 'Archived Records Vault',
        subtitle: 'Preserved historical crop scans, treatment logs & audit trail data',
        activeRoute: AppRoutes.adminArchive,
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              decoration: AppTheme.adminCardDecoration(),
              child: const TabBar(
                tabs: [
                  Tab(text: 'Archived Scanned Images'),
                  Tab(text: 'Archived Field Tasks'),
                ],
                labelColor: AppTheme.adminPrimary,
                unselectedLabelColor: AppTheme.adminTextSecondary,
                indicatorColor: AppTheme.adminPrimary,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
            _buildSearchAndFilters(context),
            Expanded(
              child: TabBarView(
                children: [
                  _buildArchivedDetectionsTab(),
                  _buildArchivedTreatmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedDetectionsTab() {
    return Consumer<DetectionProvider>(
      builder: (context, dp, _) {
        final archivedDetections =
            validScanRecords(dp.detections).where((d) => d.isArchived).toList();
        final userIds = archivedDetections.map((d) => d.userId).toSet().toList();

        return FutureBuilder<Map<String, String>>(
          future: _loadNameCache(userIds),
          builder: (context, nameSnap) {
            final nameCache = nameSnap.data ?? {};
            final search = _searchController.text;
            final filtered = _filterAndSortDetections(archivedDetections, search, nameCache);

            if (dp.isLoading && archivedDetections.isEmpty) {
              return const ListCardSkeleton(count: 6);
            }

            if (nameSnap.connectionState == ConnectionState.waiting &&
                filtered.isNotEmpty) {
              return const ListCardSkeleton(count: 6);
            }

            if (nameSnap.hasError) {
              return _ArchiveLoadError(
                message: 'Could not load farmer names.',
                onRetry: () => setState(() {}),
              );
            }

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.adminTextMuted),
                      const SizedBox(height: 14),
                      Text(
                        search.isNotEmpty
                            ? 'No archived images match your search.'
                            : 'No archived scanned images in vault.',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminTextSecondary, fontSize: 13.5),
                      ),
                      if (search.isNotEmpty)
                        TextButton(
                          onPressed: () => _searchController.clear(),
                          child: const Text('Clear Search'),
                        ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => dp.loadDetections(''),
              child: ListView.builder(
                padding: const EdgeInsets.all(22),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final detection = filtered[index];
                  return _ArchivedDetectionTile(
                    detection: detection,
                    farmerName: nameCache[detection.userId] ?? 'Farmer',
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArchivedTreatmentsTab() {
    return Consumer<TreatmentProvider>(
      builder: (context, tp, _) {
        final archived = tp.archivedTreatments;
        final userIds = archived.map((t) => t.userId).toSet().toList();
        return FutureBuilder<Map<String, String>>(
          future: _loadNameCache(userIds),
          builder: (context, nameSnap) {
            final nameCache = nameSnap.data ?? {};
            final search = _searchController.text;
            final filtered = _filterAndSortTreatments(archived, search, nameCache);

            if (tp.isLoading && archived.isEmpty) {
              return const ListCardSkeleton(count: 6);
            }

            if (nameSnap.connectionState == ConnectionState.waiting &&
                filtered.isNotEmpty) {
              return const ListCardSkeleton(count: 6);
            }

            if (nameSnap.hasError) {
              return _ArchiveLoadError(
                message: 'Could not load farmer names.',
                onRetry: () => setState(() {}),
              );
            }

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.adminTextMuted),
                      const SizedBox(height: 14),
                      Text(
                        search.isNotEmpty
                            ? 'No archived tasks match your search.'
                            : 'No archived treatment schedules in vault.',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminTextSecondary, fontSize: 13.5),
                      ),
                      if (search.isNotEmpty)
                        TextButton(
                          onPressed: () => _searchController.clear(),
                          child: const Text('Clear Search'),
                        ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => tp.loadTreatments(''),
              child: ListView.builder(
                padding: const EdgeInsets.all(22),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  return _ArchiveTile(
                    treatment: t,
                    farmerName: nameCache[t.userId] ?? 'Farmer',
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.adminSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.adminBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Search archive by disease, notes, or farmer...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.adminTextMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.adminTextSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Icon(Icons.sort_rounded, color: AppTheme.adminPrimary, size: 16),
              DropdownButton<ArchiveSortBy>(
                value: _sortBy,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(fontSize: 12, color: AppTheme.adminTextPrimary),
                items: const [
                  DropdownMenuItem(value: ArchiveSortBy.date, child: Text('Sort by Date')),
                  DropdownMenuItem(value: ArchiveSortBy.disease, child: Text('Sort by Disease')),
                  DropdownMenuItem(value: ArchiveSortBy.farmer, child: Text('Sort by Farmer')),
                  DropdownMenuItem(value: ArchiveSortBy.treatment, child: Text('Sort by Type')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortBy = v);
                },
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16,
                  color: AppTheme.adminPrimary,
                ),
                onPressed: () => setState(() => _sortAscending = !_sortAscending),
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterTreatment,
                hint: const Text('All Task Types', style: TextStyle(fontSize: 12)),
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(fontSize: 12, color: AppTheme.adminTextPrimary),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Task Types')),
                  DropdownMenuItem(value: 'treatment', child: Text('Treatment Only')),
                  DropdownMenuItem(value: 'fertilization', child: Text('Fertilization Only')),
                ],
                onChanged: (v) => setState(() => _filterTreatment = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchivedDetectionTile extends StatelessWidget {
  final DetectionModel detection;
  final String farmerName;

  const _ArchivedDetectionTile({
    required this.detection,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DetectionProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: detection.imageUrl.isNotEmpty
                    ? Image.network(
                        detection.imageUrl,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          width: 120,
                          color: AppTheme.adminSurfaceSubtle,
                          child: const Icon(Icons.broken_image_rounded, size: 36, color: AppTheme.adminTextMuted),
                        ),
                      )
                    : Container(
                        height: 120,
                        width: 120,
                        color: AppTheme.adminSurfaceSubtle,
                        child: const Icon(Icons.camera_alt_rounded, size: 36, color: AppTheme.adminTextMuted),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              detection.disease,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.adminTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AdminStatusBadge.fromStatus('Archived'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farmer: $farmerName',
                        style: const TextStyle(color: AppTheme.adminTextSecondary, fontSize: 12),
                      ),
                      Text(
                        'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      Text(
                        'Scan Date: ${DateFormat('MMM dd, yyyy • HH:mm').format(detection.timestamp)}',
                        style: const TextStyle(color: AppTheme.adminTextMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppTheme.adminBorderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => DetectionDetailsDialog.show(context, detection, farmerName),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 14),
                  label: const Text('Details', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () {
                    PhotoDownloadService.downloadPhoto(
                      context: context,
                      imageUrl: detection.imageUrl,
                      fileName: 'archived_detection_${detection.disease.replaceAll(' ', '_')}_${detection.id}.jpg',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Export', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    final restore = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Restore Image Record'),
                        content: const Text(
                            'Do you want to restore this scanned image back to the active Detection list?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                    if (restore == true && context.mounted) {
                      final ok = await dp.unarchiveDetection(detection.id);
                      if (context.mounted) {
                        if (ok) {
                          AppFeedback.success(context, 'Image record restored to active list.');
                        } else {
                          AppFeedback.error(context, 'Failed to restore image record.');
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.unarchive_rounded, size: 14),
                  label: const Text('Restore', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.adminPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    final delete = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Permanently Delete Image?'),
                          ],
                        ),
                        content: const Text(
                          'This action will permanently delete this scanned image and all associated metadata. This cannot be undone. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Permanently Delete'),
                          ),
                        ],
                      ),
                    );
                    if (delete == true && context.mounted) {
                      final ok = await dp.deleteDetection(detection.id);
                      if (context.mounted) {
                        if (ok) {
                          AppFeedback.success(context, 'Image record permanently deleted.');
                        } else {
                          AppFeedback.error(context, 'Failed to delete image record.');
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 14),
                  label: const Text('Delete', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  final TreatmentModel treatment;
  final String farmerName;

  const _ArchiveTile({
    required this.treatment,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TreatmentProvider>(context, listen: false);
    final isTreatment = treatment.type == 'treatment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.adminCardDecoration(),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTreatment ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isTreatment ? Icons.medical_services_rounded : Icons.eco_rounded,
            color: isTreatment ? const Color(0xFFD97706) : const Color(0xFF0284C7),
            size: 18,
          ),
        ),
        title: Text(
          treatment.disease,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$farmerName • ${treatment.type.toUpperCase()}',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary),
            ),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(treatment.scheduleDate),
              style: const TextStyle(fontSize: 11, color: AppTheme.adminTextMuted),
            ),
            const SizedBox(height: 4),
            AdminStatusBadge.fromStatus('Archived'),
          ],
        ),
        isThreeLine: true,
        trailing: OutlinedButton.icon(
          onPressed: () async {
            final restore = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Restore Schedule Record'),
                content: const Text(
                    'Do you want to unarchive this record and restore it to the active field schedule?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Restore'),
                  ),
                ],
              ),
            );
            if (restore != true) return;
            final ok = await provider.unarchiveTreatment(treatment.id);
            if (!context.mounted) return;
            if (ok) {
              AppFeedback.success(context, 'Record restored successfully.');
            } else {
              AppFeedback.error(context, 'Failed to restore record.');
            }
          },
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          icon: const Icon(Icons.unarchive_outlined, size: 14),
          label: const Text('Restore', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}

class _ArchiveLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ArchiveLoadError({required this.message, required this.onRetry});

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
              'Could not load archived records',
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

