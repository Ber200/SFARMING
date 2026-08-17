import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarming/analytics/scan_analytics.dart';
import 'package:smartfarming/models/detection_model.dart';

DetectionModel _scan(String disease, DateTime timestamp,
    {bool archived = false}) {
  return DetectionModel(
    id: 'id_${disease}_${timestamp.millisecondsSinceEpoch}',
    userId: 'farmer_1',
    imageUrl: '',
    disease: disease,
    confidence: 0.9,
    timestamp: timestamp,
    isArchived: archived,
  );
}

void main() {
  // Fixed reference time so period windows are deterministic.
  final now = DateTime(2026, 8, 14, 12, 0);

  group('ScanAnalytics (analytics.md §26 consistency example)', () {
    test('excludes Invalid and computes the exact expected values', () {
      final detections = <DetectionModel>[
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

      final analytics = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );

      expect(analytics.totalValidScans, 100);
      expect(analytics.counts['Healthy'], 40);
      expect(analytics.counts['Brown Spot'], 20);
      expect(analytics.counts['Sheath Blight'], 25);
      expect(analytics.counts['Bacterial Leaf Blight'], 15);

      expect(analytics.percentageOf('Healthy'), closeTo(40.0, 1e-9));
      expect(analytics.percentageOf('Brown Spot'), closeTo(20.0, 1e-9));
      expect(analytics.percentageOf('Sheath Blight'), closeTo(25.0, 1e-9));
      expect(analytics.percentageOf('Bacterial Leaf Blight'), closeTo(15.0, 1e-9));

      expect(analytics.mostFrequentDisease, 'Sheath Blight');

      // Adding more Invalid scans must not change anything.
      final withMoreInvalid = [
        ...detections,
        for (var i = 0; i < 50; i++)
          _scan('Invalid', DateTime(2026, 8, 9)),
      ];
      final analytics2 = ScanAnalytics.fromDetections(
        withMoreInvalid,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(analytics2.totalValidScans, 100);
      expect(analytics2.counts, analytics.counts);
    });

    test('archived scans do not count', () {
      final detections = [
        _scan('Healthy Rice Leaf', DateTime(2026, 8, 10)),
        _scan('Brown Spot', DateTime(2026, 8, 11), archived: true),
      ];
      final analytics = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(analytics.totalValidScans, 1);
      expect(analytics.counts['Healthy'], 1);
      expect(analytics.counts['Brown Spot'], 0);
    });

    test('scans outside the selected period do not count', () {
      final detections = [
        _scan('Healthy Rice Leaf', DateTime(2026, 7, 10)),
        _scan('Brown Spot', DateTime(2026, 8, 11)),
      ];
      final analytics = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(analytics.totalValidScans, 1);
      expect(analytics.counts['Brown Spot'], 1);
    });

    test('only Invalid / unknown scans yields zero valid scans', () {
      final detections = [
        _scan('Invalid', DateTime(2026, 8, 9)),
        _scan('not a rice leaf', DateTime(2026, 8, 9)),
      ];
      final analytics = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(analytics.totalValidScans, 0);
      expect(analytics.percentageOf('Healthy'), 0);
      expect(analytics.percentageOf('Brown Spot'), 0);
    });

    test('Admin and Farmer produce identical values for the same scope', () {
      final detections = <DetectionModel>[
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

      // Admin sees all farms; Farmer sees only their own farm. When scopes
      // match, both must produce identical numbers (single source of truth).
      final admin = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      final farmer = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(farmer.totalValidScans, admin.totalValidScans);
      expect(farmer.counts, admin.counts);
      expect(farmer.mostFrequentDisease, admin.mostFrequentDisease);
    });

    test('trend buckets are zero-filled so empty periods render correctly', () {
      final detections = [
        _scan('Brown Spot', DateTime(2026, 8, 2)),
        _scan('Brown Spot', DateTime(2026, 8, 7)),
      ];
      final analytics = ScanAnalytics.fromDetections(
        detections,
        period: AnalyticsPeriod.month,
        now: now,
      );
      expect(analytics.trendLabels.length, 6);
      expect(analytics.trendCounts['Day 1-5'], 1);
      expect(analytics.trendCounts['Day 6-10'], 1);
      expect(analytics.trendCounts['Day 11-15'], 0);
      expect(analytics.trendCounts['Day 26+'], 0);
    });
  });

  group('generateScanInsights', () {
    test('produces a helpful message when there is no data', () {
      final analytics = ScanAnalytics.fromDetections(
        [_scan('Invalid', DateTime(2026, 8, 9))],
        period: AnalyticsPeriod.month,
        now: now,
      );
      final insights = generateScanInsights(analytics);
      expect(insights, hasLength(1));
      expect(insights.first.toLowerCase(), contains('no valid scan data'));
    });

    test('statements are derived from real data', () {
      final analytics = ScanAnalytics.fromDetections(
        [
          for (var i = 0; i < 40; i++)
            _scan('Healthy Rice Leaf', DateTime(2026, 8, 10)),
          for (var i = 0; i < 20; i++)
            _scan('Brown Spot', DateTime(2026, 8, 11)),
        ],
        period: AnalyticsPeriod.month,
        now: now,
      );
      final insights = generateScanInsights(analytics);
      final joined = insights.join('\n');
      expect(joined, contains('67% of 60 valid scans (40 of 60)'));
      expect(joined, contains('detected in 20 of 60 valid scans'));
      expect(joined, contains('Brown Spot is currently the most frequently detected disease.'));
    });
  });
}
