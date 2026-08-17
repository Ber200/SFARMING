import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/detection_model.dart';
import '../../../models/treatment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firebase_service.dart';
import '../../../utils/field_map_markers.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/detection_details_dialog.dart';
import '../../../widgets/treatment_details_dialog.dart';

class FarmerMapScreen extends StatefulWidget {
  const FarmerMapScreen({super.key});

  @override
  State<FarmerMapScreen> createState() => _FarmerMapScreenState();
}

class _FarmerMapScreenState extends State<FarmerMapScreen> {
  final FirebaseService _firebase = FirebaseService();

  final Set<Marker> _markers = {};
  bool _loading = true;

  StreamSubscription<List<DetectionModel>>? _detectionsSub;
  StreamSubscription<List<TreatmentModel>>? _treatmentsSub;
  StreamSubscription<List<UserModel>>? _usersSub;
  List<UserModel> _cachedUsers = [];
  List<DetectionModel> _cachedDetections = [];
  List<TreatmentModel> _cachedTreatments = [];

  final Map<String, Future<BitmapDescriptor>> _markerIconCache = {};

  @override
  void initState() {
    super.initState();
    _subscribeToLiveData();
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

    _detectionsSub = _firebase.getAllDetections().listen((detections) {
      _cachedDetections = detections;
      _rebuildMarkers();
    });

    _treatmentsSub = _firebase.getAllTreatments().listen((treatments) {
      _cachedTreatments = treatments;
      _rebuildMarkers();
    });
  }

  Future<void> _rebuildMarkers() async {
    final userMap = {for (var u in _cachedUsers) u.id: u.name};
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';

    final markers = await buildFieldMarkers(
      detections: _cachedDetections,
      treatments: _cachedTreatments,
      userMap: userMap,
      iconCache: _markerIconCache,
      onDetectionTap: (detection, farmerName) {
        DetectionDetailsDialog.show(
          context,
          detection,
          farmerName,
          canDelete: detection.userId == currentUserId,
        );
      },
      onTreatmentTap: (treatment, farmerName) {
        TreatmentDetailsDialog.show(
          context,
          treatment,
          farmerName,
          canDelete: treatment.userId == currentUserId,
        );
      },
    );

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('My Detection Locations'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _subscribeToLiveData,
            tooltip: 'Refresh markers',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.myLocations),
      body: _loading
          ? Container(
              margin: const EdgeInsets.all(12),
              decoration: AppTheme.farmCardDecoration(),
              child: const Center(child: CircularProgressIndicator()),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: const CameraPosition(
                    target: defaultFieldCenter,
                    zoom: 18,
                  ),
                  markers: _markers,
                  polygons: {
                    Polygon(
                      polygonId: const PolygonId('field_boundary'),
                      points: defaultRiceFieldBoundary,
                      strokeColor: Colors.yellow,
                      strokeWidth: 3,
                      fillColor: Colors.yellow.withValues(alpha: 0.35),
                    )
                  },
                  circles: const <Circle>{},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(defaultFieldCenter, 18),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
