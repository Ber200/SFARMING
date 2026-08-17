import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../models/detection_model.dart';
import '../models/treatment_model.dart';
import 'marker_icon_utils.dart';


/// Default registered rice field center + boundary shared by the admin map
/// and the farmer "My Detection Locations" map.
const LatLng defaultFieldCenter = LatLng(7.330315123397189, 125.67865727432635);

const List<LatLng> defaultRiceFieldBoundary = [
  LatLng(7.330700250052051, 125.67823349471458),
  LatLng(7.330719799619558, 125.67866318753023),
  LatLng(7.33072761944632, 125.67911850422941),
  LatLng(7.3304558803857995, 125.6790830250061),
  LatLng(7.330297528770478, 125.67906528539444),
  LatLng(7.329886987283392, 125.67896673199634),
  LatLng(7.329863527758415, 125.67864544791858),
  LatLng(7.329867437679334, 125.67826306073401),
  LatLng(7.330229105215577, 125.67823349471458),
  LatLng(7.330467610132843, 125.67822758151068),
];

/// True for scan results that must never appear on the map (invalid / empty).
bool isNonPinDisease(String disease) {
  final d = disease.toLowerCase().trim();
  return d.contains('invalid') || d.isEmpty;
}

/// Disease -> (label, color) used for the unique map pin.
({String label, Color color}) markerSpecForDisease(String disease) {
  final d = disease.toLowerCase();
  if (d.contains('bacterial leaf blight')) {
    return (label: 'BLB', color: const Color(0xFFE53935));
  } else if (d.contains('brown spot')) {
    return (label: 'BS', color: const Color(0xFFFB8C00));
  } else if (d.contains('sheath blight')) {
    return (label: 'SB', color: const Color(0xFF1E88E5));
  } else if (d.contains('healthy')) {
    return (label: 'H', color: const Color(0xFF43A047));
  }
  return (label: '?', color: const Color(0xFF757575));
}

/// Builds the set of minimal disease markers for every GPS-tagged detection,
/// and circular task dots for completed treatments/fertilizations.
///
/// NOTE: The default location pin is completely removed.
/// Healthy / invalid scans are handled appropriately. Records older than [maxPinAge]
/// (default: 7 days) are automatically hidden from the map (unless filtered).
Future<Set<Marker>> buildFieldMarkers({
  required List<DetectionModel> detections,
  required List<TreatmentModel> treatments,
  required Map<String, String> userMap,
  required Map<String, Future<BitmapDescriptor>> iconCache,
  Duration maxPinAge = const Duration(days: 7),
  Duration? detectionMaxPinAge = const Duration(days: 7),
  required void Function(DetectionModel detection, String farmerName)
      onDetectionTap,
  required void Function(TreatmentModel treatment, String farmerName)
      onTreatmentTap,
}) async {
  final markers = <Marker>{};
  final now = DateTime.now();
  final cutoff = now.subtract(maxPinAge);
  final detectionCutoff =
      detectionMaxPinAge == null ? null : now.subtract(detectionMaxPinAge);

  Future<BitmapDescriptor> circleDotIcon(String key, Color color) {
    return iconCache.putIfAbsent(key, () async {
      try {
        return await MarkerIconUtils.buildCircleDotMarker(color: color);
      } catch (_) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      }
    });
  }

  // 1. Filter out archived, invalid, and detections without recorded GPS coordinates
  final validDetections = <DetectionModel>[];
  for (final detection in detections) {
    if (detection.isArchived || isNonPinDisease(detection.disease)) continue;
    if (detectionCutoff != null && detection.timestamp.isBefore(detectionCutoff)) {
      continue;
    }
    // Only map detections that have actual recorded scan coordinates!
    if (detection.latitude == null || detection.longitude == null) {
      continue; // Never place detections without GPS at the farm center!
    }
    validDetections.add(detection);
  }

  // 2. Group detections by exact coordinate to slightly offset co-located scans
  final groupedDetections = <String, List<DetectionModel>>{};
  for (final d in validDetections) {
    final lat = d.latitude!;
    final lng = d.longitude!;
    final key = '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    (groupedDetections[key] ??= []).add(d);
  }

  // 3. Generate distinct, visible circular markers at exact recorded locations
  for (final entry in groupedDetections.entries) {
    final group = entry.value;
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final detection = group[i];
      final exactLat = detection.latitude!;
      final exactLng = detection.longitude!;

      LatLng markerPos;
      if (count == 1) {
        markerPos = LatLng(exactLat, exactLng);
      } else {
        // Subtle offset only if multiple scans occurred at the exact same GPS coordinate
        const double radius = 0.00003;
        final double angle = (2 * math.pi * i) / count - (math.pi / 2);
        final double latOffset = radius * math.sin(angle);
        final double lngOffset = radius * math.cos(angle) / math.cos(exactLat * (math.pi / 180));
        markerPos = LatLng(exactLat + latOffset, exactLng + lngOffset);
      }

      final spec = markerSpecForDisease(detection.disease);
      final icon = await circleDotIcon('circle_dot_${spec.label}', spec.color);
      final farmerName = userMap[detection.userId] ??
          (detection.userId.isNotEmpty ? detection.userId : 'Farmer');

      markers.add(
        Marker(
          markerId: MarkerId('detection_${detection.id}_$i'),
          position: markerPos,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: '${detection.disease} • ${(detection.confidence * 100).toStringAsFixed(1)}%',
            snippet: 'Farmer: $farmerName • ${DateFormat('MMM d, yyyy • h:mm a').format(detection.timestamp)}',
          ),
          onTap: () => onDetectionTap(detection, farmerName),
        ),
      );
    }
  }



  // Add pins for completed treatments/fertilizations with photo proof + GPS.
  for (final treatment in treatments) {
    if (!treatment.isCompleted) continue;
    if (treatment.latitude == null || treatment.longitude == null) continue;
    if (treatment.photoProofUrl == null || treatment.photoProofUrl!.isEmpty) {
      continue;
    }
    final pinDate = treatment.completedAt ?? treatment.createdAt;
    if (pinDate.isBefore(cutoff)) continue;

    final latLng = LatLng(treatment.latitude!, treatment.longitude!);
    final isFertilization = treatment.type == 'fertilization';
    final taskColor = isFertilization ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final icon = await circleDotIcon('task_dot_${isFertilization ? 'F' : 'T'}', taskColor);
    final farmerName = userMap[treatment.userId] ??
        (treatment.userId.isNotEmpty ? treatment.userId : 'Farmer');
    final completedLabel = treatment.completedAt != null
        ? DateFormat('MMM dd, yyyy').format(treatment.completedAt!)
        : '';

    markers.add(
      Marker(
        markerId: MarkerId('treatment_${treatment.id}'),
        position: latLng,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: isFertilization
              ? 'Fertilization Completed'
              : 'Treatment: ${treatment.disease.isEmpty ? 'Completed' : treatment.disease}',
          snippet: 'Farmer: $farmerName • $completedLabel',
        ),
        onTap: () => onTreatmentTap(treatment, farmerName),
      ),
    );
  }

  return markers;
}

