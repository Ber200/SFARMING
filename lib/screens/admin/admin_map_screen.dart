import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage_service.dart';
import '../../models/user_model.dart';
import '../../models/detection_model.dart';
import '../../models/treatment_model.dart';
import '../../utils/field_map_markers.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/detection_details_dialog.dart';
import '../../widgets/treatment_details_dialog.dart';
import '../../analytics/scan_analytics.dart';

/// Time period options for filtering the scanned disease pins on the map.
enum MapFilterType { daily, weekly, monthly, customRange }

/// Result returned by the filter bottom sheet.
class _FilterSheetResult {
  final bool reset;
  final MapFilterType type;
  final DateTime anchor;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const _FilterSheetResult.apply(
    this.type,
    this.anchor, {
    this.rangeStart,
    this.rangeEnd,
  }) : reset = false;

  _FilterSheetResult.reset()
      : reset = true,
        type = MapFilterType.daily,
        anchor = DateTime.now(),
        rangeStart = null,
        rangeEnd = null;
}

/// Computes the inclusive [start, endExclusive) window for a filter period.
(DateTime, DateTime) _filterRange(
  MapFilterType type,
  DateTime anchor, {
  DateTime? rangeStart,
  DateTime? rangeEnd,
}) {
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  switch (type) {
    case MapFilterType.daily:
      return (day, day.add(const Duration(days: 1)));
    case MapFilterType.weekly:
      final weekStart = day.subtract(Duration(days: day.weekday - 1));
      return (weekStart, weekStart.add(const Duration(days: 7)));
    case MapFilterType.monthly:
      return (
        DateTime(anchor.year, anchor.month, 1),
        DateTime(anchor.year, anchor.month + 1, 1),
      );
    case MapFilterType.customRange:
      final s = rangeStart != null
          ? DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
          : day;
      final e = rangeEnd != null
          ? DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day).add(const Duration(days: 1))
          : s.add(const Duration(days: 1));
      return (s, e);
  }
}

/// Human label for a filter period, e.g. "August 17, 2026", "August 2026", or "August 10–17, 2026".
String _filterRangeLabel(
  MapFilterType type,
  DateTime anchor, {
  DateTime? rangeStart,
  DateTime? rangeEnd,
}) {
  final (start, endExclusive) = _filterRange(
    type,
    anchor,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  );
  final end = endExclusive.subtract(const Duration(days: 1));
  switch (type) {
    case MapFilterType.daily:
      return DateFormat('MMMM d, yyyy').format(start);
    case MapFilterType.weekly:
      if (start.month == end.month && start.year == end.year) {
        return '${DateFormat('MMMM').format(start)} ${start.day}–${end.day}, ${end.year}';
      }
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
    case MapFilterType.monthly:
      return DateFormat('MMMM yyyy').format(start);
    case MapFilterType.customRange:
      return '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
  }
}

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final FirebaseService _firebase = FirebaseService();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static const LatLng _defaultCenterLocation = defaultFieldCenter;
  static const List<LatLng> _defaultRiceFieldBoundary = defaultRiceFieldBoundary;

  final Set<Marker> _markers = {};
  bool _loading = true;
  LatLng _center = _defaultCenterLocation;
  final List<LatLng> _polygonPoints = List.from(_defaultRiceFieldBoundary);
  MapType _currentMapType = MapType.hybrid;

  StreamSubscription<List<DetectionModel>>? _detectionsSub;
  StreamSubscription<List<TreatmentModel>>? _treatmentsSub;
  StreamSubscription<List<UserModel>>? _usersSub;
  List<UserModel> _cachedUsers = [];
  List<DetectionModel> _cachedDetections = [];
  List<TreatmentModel> _cachedTreatments = [];

  // ── Filter state ────────────────────────────────────────────────────────
  MapFilterType? _filterType;
  DateTime _filterAnchor = DateTime.now();
  DateTime? _filterRangeStart;
  DateTime? _filterRangeEnd;
  bool _filterActive = false;
  bool _filterLoading = false;
  String? _filterError;
  List<DetectionModel> _filteredDetections = [];

  // ── Selected Marker Popup State ─────────────────────────────────────────
  DetectionModel? _selectedDetection;
  String _selectedFarmerName = '';

  @override
  void initState() {
    super.initState();
    _subscribeToLiveData();
    _loadBoundary();
  }

  @override
  void dispose() {
    _detectionsSub?.cancel();
    _treatmentsSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }

  void _subscribeToLiveData() {
    setState(() => _loading = true);

    _usersSub = _firebase.getAllUsers().listen((users) {
      _cachedUsers = users;
      _rebuildMarkers();
    });

    _listenToAllDetections();

    _treatmentsSub = _firebase.getAllTreatments().listen((treatments) {
      _cachedTreatments = treatments;
      _rebuildMarkers();
    });
  }

  void _listenToAllDetections() {
    _detectionsSub?.cancel();
    _detectionsSub = _firebase.getAllDetections().listen((detections) {
      _cachedDetections = detections;
      _rebuildMarkers();
    });
  }

  Future<void> _loadBoundary() async {
    final saved = LocalStorageService.getAdminMapBoundary();
    final points = (saved != null && saved.isNotEmpty)
        ? saved
        : _defaultRiceFieldBoundary
            .map((e) => {'lat': e.latitude, 'lng': e.longitude})
            .toList();

    if (mounted) {
      setState(() {
        _polygonPoints
          ..clear()
          ..addAll(points.map((p) => LatLng(p['lat']!, p['lng']!)));
        if (points.length == 1) {
          _center = LatLng(points.first['lat']!, points.first['lng']!);
        }
      });
      LocalStorageService.saveAdminMapBoundary(points);
      await _firebase.saveAdminMapBoundary(points);
    }
  }

  final Map<String, Future<BitmapDescriptor>> _markerIconCache = {};

  Future<void> _rebuildMarkers() async {
    final userMap = {for (var u in _cachedUsers) u.id: u.name};
    final detections = _filterActive ? _filteredDetections : _cachedDetections;

    final markers = await buildFieldMarkers(
      detections: detections,
      treatments: _filterActive ? const [] : _cachedTreatments,
      userMap: userMap,
      iconCache: _markerIconCache,
      detectionMaxPinAge: _filterActive ? null : const Duration(days: 7),
      onDetectionTap: (detection, farmerName) {
        setState(() {
          _selectedDetection = detection;
          _selectedFarmerName = farmerName;
        });
      },
      onTreatmentTap: (treatment, farmerName) {
        _showTreatmentDetails(treatment, farmerName);
      },
    );

    debugPrint('=== MAP MARKER PIPELINE DEBUG ===');
    debugPrint('Filter active: $_filterActive (Type: $_filterType, Anchor: $_filterAnchor)');
    debugPrint('Matching detections in scope: ${detections.length}');
    debugPrint('Valid scan records: ${validScanRecords(detections).length}');
    debugPrint('Total markers created: ${markers.length}');
    debugPrint('=================================');

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _loading = false;
        _filterLoading = false;
      });
    }

    if (_filterActive) {
      await _fitToDetectionBounds();
    }
  }

  Future<void> _fitToDetectionBounds() async {
    final withCoords = validScanRecords(_filteredDetections)
        .where((d) => d.latitude != null && d.longitude != null)
        .toList();
    if (withCoords.isEmpty) return;

    final controller = await _mapController.future;
    if (!mounted) return;

    if (withCoords.length == 1) {
      final d = withCoords.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(d.latitude!, d.longitude!), 18.5),
      );
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    for (final d in withCoords) {
      final lat = d.latitude!;
      final lng = d.longitude!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    if ((maxLat - minLat).abs() < 0.0001 && (maxLng - minLng).abs() < 0.0001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 18.5),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }


  Future<void> _applyFilter(
    MapFilterType type,
    DateTime anchor, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    setState(() {
      _filterType = type;
      _filterAnchor = anchor;
      _filterRangeStart = rangeStart;
      _filterRangeEnd = rangeEnd;
      _filterActive = true;
      _filteredDetections = [];
      _filterError = null;
      _filterLoading = true;
      _selectedDetection = null;
    });

    final (start, endExclusive) = _filterRange(
      type,
      anchor,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    final startMs = start.millisecondsSinceEpoch;
    final endMs = endExclusive.millisecondsSinceEpoch - 1;

    await _detectionsSub?.cancel();
    if (!mounted) return;

    _detectionsSub = _firebase.getDetectionsInRange(startMs, endMs).listen(
      (detections) {
        if (!mounted) return;
        _filteredDetections = detections;
        _rebuildMarkers();
      },
      onError: (Object e) {
        debugPrint('[AdminMap] Filter query failed: $e');
        if (!mounted) return;
        setState(() {
          _filterLoading = false;
          _filterError = 'Could not load scans for this period. Showing live map.';
        });
      },
    );
  }

  Future<void> _resetFilter() async {
    setState(() {
      _filterActive = false;
      _filterType = null;
      _filterRangeStart = null;
      _filterRangeEnd = null;
      _filteredDetections = [];
      _filterError = null;
      _filterLoading = true;
      _selectedDetection = null;
    });

    await _detectionsSub?.cancel();
    if (!mounted) return;

    _detectionsSub = _firebase.getAllDetections().listen((detections) {
      if (!mounted) return;
      _cachedDetections = detections;
      _rebuildMarkers();
    });
  }

  void _refreshCurrentData() {
    if (_filterActive && _filterType != null) {
      _applyFilter(
        _filterType!,
        _filterAnchor,
        rangeStart: _filterRangeStart,
        rangeEnd: _filterRangeEnd,
      );
    } else {
      _subscribeToLiveData();
    }
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapFilterSheet(
        initialType: _filterActive ? _filterType : null,
        initialAnchor: _filterActive ? _filterAnchor : DateTime.now(),
        initialRangeStart: _filterRangeStart,
        initialRangeEnd: _filterRangeEnd,
      ),
    );
    if (result == null || !mounted) return;
    if (result.reset) {
      await _resetFilter();
    } else {
      await _applyFilter(
        result.type,
        result.anchor,
        rangeStart: result.rangeStart,
        rangeEnd: result.rangeEnd,
      );
    }
  }

  Future<void> _showTreatmentDetails(TreatmentModel treatment, String farmerName) {
    return TreatmentDetailsDialog.show(context, treatment, farmerName, canDelete: true);
  }

  Widget _buildSummaryBar() {
    final validScans = validScanRecords(_filteredDetections);
    final count = validScans.length;
    final pinnedCount = _markers.length;
    final label = _filterRangeLabel(
      _filterType!,
      _filterAnchor,
      rangeStart: _filterRangeStart,
      rangeEnd: _filterRangeEnd,
    );
    final summaryTitle = (pinnedCount == count)
        ? 'Showing $count disease detection${count == 1 ? '' : 's'} · $label'
        : 'Showing $count disease detection${count == 1 ? '' : 's'} ($pinnedCount with GPS on map) · $label';

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 18, color: AppTheme.adminPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _resetFilter,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: AppTheme.adminTextSecondary),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: AppTheme.adminCardDecoration(),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 44, color: AppTheme.adminTextMuted),
              SizedBox(height: 12),
              Text(
                'No disease detections found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'There are no disease detection pins recorded for this selected period.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Could not load scans for this period. Showing live map.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionPopupCard() {
    if (_selectedDetection == null) return const SizedBox.shrink();
    final d = _selectedDetection!;
    final spec = markerSpecForDisease(d.disease);
    final formattedDate = DateFormat('MMMM d, yyyy').format(d.timestamp);
    final formattedTime = DateFormat('h:mm a').format(d.timestamp);

    return Positioned(
      bottom: 24,
      left: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: AppTheme.adminBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: spec.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: spec.color.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.disease,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.adminTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedDetection = null),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: AppTheme.adminTextMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _popupInfoRow('Detected:', formattedDate),
              _popupInfoRow('Time:', formattedTime),
              _popupInfoRow('Farmer:', _selectedFarmerName),
              _popupInfoRow(
                'Confidence:',
                '${(d.confidence * 100).toStringAsFixed(0)}%',
                valueColor: Colors.green.shade700,
                isBold: true,
              ),
              if (d.latitude != null && d.longitude != null) ...[
                _popupInfoRow(
                  'GPS:',
                  '${d.latitude!.toStringAsFixed(6)}, ${d.longitude!.toStringAsFixed(6)}',
                ),
                _popupInfoRow(
                  'Status:',
                  d.isInsideFarm ? 'Inside Registered Farm' : 'Outside Registered Farm',
                  valueColor: d.isInsideFarm ? Colors.teal.shade700 : Colors.deepOrange.shade700,
                ),
              ] else
                _popupInfoRow('Status:', 'No GPS Recorded', valueColor: Colors.grey.shade600),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () {
                    DetectionDetailsDialog.show(
                      context,
                      d,
                      _selectedFarmerName,
                      canDelete: true,
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text(
                    'View Detection',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppTheme.adminTextPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showEmptyState = _filterActive &&
        _filterError == null &&
        !_filterLoading &&
        !_loading &&
        validScanRecords(_filteredDetections).isEmpty;

    return AdminScaffold(
      title: 'GIS Farm Outbreak Map',
      subtitle: 'Geospatial rice field plot boundaries, outbreak hotspot pins & farm perimeter telemetry',
      activeRoute: AppRoutes.adminMap,
      actions: [
        IconButton(
          onPressed: _refreshCurrentData,
          tooltip: 'Refresh map markers',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFilterSheet,
        backgroundColor: _filterActive ? const Color(0xFFD97706) : AppTheme.adminPrimary,
        icon: Icon(
          _filterActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          color: Colors.white,
        ),
        label: Text(_filterActive ? 'Filter Active' : 'Filter Dates', style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          if (_filterActive) _buildSummaryBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _loading
                      ? Container(
                          margin: const EdgeInsets.all(22),
                          decoration: AppTheme.adminCardDecoration(),
                          child: const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary)),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(22),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                GoogleMap(
                                  mapType: _currentMapType,
                                  initialCameraPosition: CameraPosition(target: _center, zoom: 18),
                                  markers: _markers,
                                  polygons: _polygonPoints.isNotEmpty
                                      ? {
                                          Polygon(
                                            polygonId: const PolygonId('field_boundary'),
                                            points: _polygonPoints,
                                            strokeColor: const Color(0xFFFBBF24),
                                            strokeWidth: 3,
                                            fillColor: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                                          )
                                        }
                                      : {},
                                  circles: const {},
                                  myLocationEnabled: false,
                                  myLocationButtonEnabled: false,
                                  onTap: (_) => setState(() => _selectedDetection = null),
                                  onMapCreated: (controller) {
                                    if (!_mapController.isCompleted) {
                                      _mapController.complete(controller);
                                    }
                                    controller.animateCamera(
                                      CameraUpdate.newLatLngZoom(_center, 18),
                                    );
                                  },
                                ),
                                // Floating Map Layer Switcher
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _mapTypeButton('Hybrid', MapType.hybrid),
                                        _mapTypeButton('Satellite', MapType.satellite),
                                        _mapTypeButton('Normal', MapType.normal),
                                      ],
                                    ),
                                  ),
                                ),
                                // Active Marker Count Pill
                                Positioned(
                                  top: 14,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.adminPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_markers.length} Pinned Outbreaks',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                            color: AppTheme.adminTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Selected Detection Floating Popup Card
                                _buildDetectionPopupCard(),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_filterLoading)
                  const Positioned(
                    top: 0,
                    left: 22,
                    right: 22,
                    child: LinearProgressIndicator(minHeight: 3, color: AppTheme.adminPrimary),
                  ),
                if (_filterError != null) Positioned(top: 0, left: 0, right: 0, child: _buildErrorBanner()),
                if (showEmptyState) Positioned.fill(child: _buildEmptyState()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapTypeButton(String label, MapType type) {
    final isSelected = _currentMapType == type;
    return InkWell(
      onTap: () => setState(() => _currentMapType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.adminPrimaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.adminPrimary : AppTheme.adminTextSecondary,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with Day, Week, Month, and Custom Date Range filter options.
class _MapFilterSheet extends StatefulWidget {
  final MapFilterType? initialType;
  final DateTime initialAnchor;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;

  const _MapFilterSheet({
    required this.initialType,
    required this.initialAnchor,
    this.initialRangeStart,
    this.initialRangeEnd,
  });

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late MapFilterType _type;
  late DateTime _anchor;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  bool get _hasActiveFilter => widget.initialType != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? MapFilterType.daily;
    _anchor = widget.initialAnchor;
    _rangeStart = widget.initialRangeStart ?? DateTime.now().subtract(const Duration(days: 7));
    _rangeEnd = widget.initialRangeEnd ?? DateTime.now();
  }

  void _shiftPeriod(int step) {
    setState(() {
      switch (_type) {
        case MapFilterType.daily:
          _anchor = _anchor.add(Duration(days: step));
          break;
        case MapFilterType.weekly:
          _anchor = _anchor.add(Duration(days: 7 * step));
          break;
        case MapFilterType.monthly:
          _anchor = DateTime(_anchor.year, _anchor.month + step, 1);
          break;
        case MapFilterType.customRange:
          if (_rangeStart != null && _rangeEnd != null) {
            final span = _rangeEnd!.difference(_rangeStart!).inDays;
            _rangeStart = _rangeStart!.add(Duration(days: (span + 1) * step));
            _rangeEnd = _rangeEnd!.add(Duration(days: (span + 1) * step));
          }
          break;
      }
    });
  }

  Future<void> _pickSingleDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.adminPrimary,
            onPrimary: Colors.white,
            onSurface: AppTheme.adminTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _anchor = picked;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _rangeStart ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _rangeEnd ?? DateTime.now(),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.adminPrimary,
            onPrimary: Colors.white,
            onSurface: AppTheme.adminTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  void _goToCurrentPeriod() {
    setState(() {
      _anchor = DateTime.now();
      _rangeStart = DateTime.now().subtract(const Duration(days: 7));
      _rangeEnd = DateTime.now();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _FilterSheetResult.apply(
        _type,
        _anchor,
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
      ),
    );
  }

  void _reset() {
    Navigator.of(context).pop(_FilterSheetResult.reset());
  }

  @override
  Widget build(BuildContext context) {
    final label = _filterRangeLabel(
      _type,
      _anchor,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
    );

    final currentPeriodLabel = switch (_type) {
      MapFilterType.daily => 'Today',
      MapFilterType.weekly => 'This Week',
      MapFilterType.monthly => 'This Month',
      MapFilterType.customRange => 'Last 7 Days',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter Disease Scans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Show disease detection markers matching a specific day, month, or range.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<MapFilterType>(
                    segments: const [
                      ButtonSegment(
                        value: MapFilterType.daily,
                        label: Text('Day'),
                        icon: Icon(Icons.today_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MapFilterType.monthly,
                        label: Text('Month'),
                        icon: Icon(Icons.calendar_month_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MapFilterType.weekly,
                        label: Text('Week'),
                        icon: Icon(Icons.date_range_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MapFilterType.customRange,
                        label: Text('Range'),
                        icon: Icon(Icons.tune_rounded, size: 16),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() => _type = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftPeriod(-1),
                      tooltip: 'Previous',
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.adminTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftPeriod(1),
                      tooltip: 'Next',
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_type == MapFilterType.daily)
                      TextButton.icon(
                        onPressed: _pickSingleDay,
                        icon: const Icon(Icons.calendar_today_rounded, size: 14),
                        label: const Text('Pick Specific Day', style: TextStyle(fontSize: 12)),
                      ),
                    if (_type == MapFilterType.customRange)
                      TextButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range_rounded, size: 14),
                        label: const Text('Choose Date Range', style: TextStyle(fontSize: 12)),
                      ),
                    TextButton(
                      onPressed: _goToCurrentPeriod,
                      child: Text(currentPeriodLabel, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _hasActiveFilter ? _reset : null,
                        child: const Text('Reset Filter'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.adminPrimary,
                        ),
                        onPressed: _apply,
                        child: const Text('Apply Filter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
