import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarming/analytics/scan_analytics.dart';
import 'package:smartfarming/models/detection_model.dart';
import 'package:smartfarming/services/analytics_pdf_service.dart';

DetectionModel _scan(String disease, DateTime timestamp) {
  return DetectionModel(
    id: 'id_${disease}_${timestamp.millisecondsSinceEpoch}',
    userId: 'farmer_1',
    imageUrl: '',
    disease: disease,
    confidence: 0.9,
    timestamp: timestamp,
  );
}

List<DetectionModel> _analyticsMdDataset() {
  return <DetectionModel>[
    for (var i = 0; i < 40; i++)
      _scan('Healthy Rice Leaf', DateTime(2026, 8, 10)),
    for (var i = 0; i < 20; i++)
      _scan('Brown Spot', DateTime(2026, 8, 11)),
    for (var i = 0; i < 25; i++)
      _scan('Sheath Blight', DateTime(2026, 8, 12)),
    for (var i = 0; i < 15; i++)
      _scan('Bacterial Leaf Blight', DateTime(2026, 8, 13)),
    for (var i = 0; i < 30; i++)
      _scan('Invalid', DateTime(2026, 8, 9)),
  ];
}

Future<Uint8List> _buildReport(ScanAnalytics analytics, DateTime now) {
  return AnalyticsPdfService.buildAnalyticsPdf(
    analytics: analytics,
    period: AnalyticsPeriod.month,
    scopeLabel: 'All Farms',
    generatedAt: now,
    totalUsers: 10,
    activeFarmers: 5,
    pendingSchedules: 3,
    completedSchedules: 8,
    archivedRecords: 2,
  );
}

void main() {
  final now = DateTime(2026, 8, 14, 12, 0);

  test('produces a valid PDF for the analytics.md §26 dataset', () async {
    final analytics = ScanAnalytics.fromDetections(
      _analyticsMdDataset(),
      period: AnalyticsPeriod.month,
      now: now,
    );
    expect(analytics.totalValidScans, 100);

    final bytes = await _buildReport(analytics, now);
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
  });

  test('produces a valid PDF even when there is no valid data', () async {
    final analytics = ScanAnalytics.fromDetections(
      [_scan('Invalid', DateTime(2026, 8, 9))],
      period: AnalyticsPeriod.month,
      now: now,
    );
    expect(analytics.totalValidScans, 0);

    final bytes = await _buildReport(analytics, now);
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
  });

  test('produces a valid PDF for every analytics period', () async {
    for (final period in AnalyticsPeriod.values) {
      final analytics = ScanAnalytics.fromDetections(
        _analyticsMdDataset(),
        period: period,
        now: now,
      );
      final bytes = await AnalyticsPdfService.buildAnalyticsPdf(
        analytics: analytics,
        period: period,
        scopeLabel: 'Farmer Maria',
        generatedAt: now,
        totalUsers: 10,
        activeFarmers: 5,
        pendingSchedules: 3,
        completedSchedules: 8,
        archivedRecords: 2,
      );
      expect(bytes, isNotEmpty, reason: 'PDF empty for $period');
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-',
          reason: 'Invalid header for $period');
    }
  });
}
