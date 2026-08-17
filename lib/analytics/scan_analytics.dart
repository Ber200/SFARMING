import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection_model.dart';

/// Time periods shared by Admin and Farmer analytics.
enum AnalyticsPeriod { today, week, month, year }

/// Canonical disease categories that contribute to analytics.
///
/// `Invalid` and any unrecognized label are deliberately excluded so they
/// never affect totals, percentages, charts, or insights.
const List<String> kAnalyticsCategories = [
  'Healthy',
  'Brown Spot',
  'Sheath Blight',
  'Bacterial Leaf Blight',
];

/// Consistent visual identity for each category across cards and charts.
const Map<String, Color> kAnalyticsCategoryColors = {
  'Healthy': Color(0xFF43A047),
  'Brown Spot': Color(0xFFFB8C00),
  'Sheath Blight': Color(0xFF1E88E5),
  'Bacterial Leaf Blight': Color(0xFFE53935),
};

const List<Color> _fallbackColors = [
  Color(0xFF6D4C41),
  Color(0xFF8E24AA),
  Color(0xFF00897B),
];

Color analyticsColorFor(String category, int index) {
  return kAnalyticsCategoryColors[category] ??
      _fallbackColors[index % _fallbackColors.length];
}

/// Maps a stored disease label to a canonical category, or returns null for
/// Invalid / empty / unknown labels (which must never appear in analytics).
String? analyticsCategoryFor(String disease) {
  final d = disease.trim().toLowerCase();
  if (d.isEmpty) return null;
  if (d.contains('bacterial leaf blight')) return 'Bacterial Leaf Blight';
  if (d.contains('brown spot')) return 'Brown Spot';
  if (d.contains('sheath blight')) return 'Sheath Blight';
  if (d.contains('healthy')) return 'Healthy';
  return null;
}

/// Returns only the records that count toward analytics:
/// non-archived scans with a recognized (non-Invalid) category.
List<DetectionModel> validScanRecords(List<DetectionModel> detections) {
  return detections
      .where((d) => !d.isArchived && analyticsCategoryFor(d.disease) != null)
      .toList();
}

String analyticsPeriodLabel(AnalyticsPeriod period, DateTime now) {
  switch (period) {
    case AnalyticsPeriod.today:
      return 'Today';
    case AnalyticsPeriod.week:
      return 'This Week';
    case AnalyticsPeriod.month:
      return DateFormat('MMMM yyyy').format(now);
    case AnalyticsPeriod.year:
      return '${now.year}';
  }
}

/// Inclusive start and exclusive end of the current [period] window at [now].
/// Used by reports to describe the exact date range being summarized.
(DateTime, DateTime) analyticsPeriodRange(
  AnalyticsPeriod period,
  DateTime now,
) {
  final window = _Window._current(period, now);
  return (window.start, window.end);
}

/// Bucket labels used by the trend charts for each period.
List<String> analyticsTrendLabels(AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.today:
      return ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
    case AnalyticsPeriod.week:
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    case AnalyticsPeriod.month:
      return [
        'Day 1-5',
        'Day 6-10',
        'Day 11-15',
        'Day 16-20',
        'Day 21-25',
        'Day 26+',
      ];
    case AnalyticsPeriod.year:
      return const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
  }
}

/// Zero-filled counts per trend bucket for [times] that fall inside the
/// current [period] window. Used by both scan trends and schedule statistics.
Map<String, int> bucketTimestamps(
  Iterable<DateTime> times,
  AnalyticsPeriod period,
  DateTime now,
) {
  final labels = analyticsTrendLabels(period);
  final counts = <String, int>{for (final l in labels) l: 0};
  final window = _Window._current(period, now);
  for (final t in times) {
    if (!t.isBefore(window.start) && t.isBefore(window.end)) {
      final idx = _trendIndex(t, period);
      counts[labels[idx]] = counts[labels[idx]]! + 1;
    }
  }
  return counts;
}

class _Window {
  final DateTime start;
  final DateTime end;

  const _Window(this.start, this.end);

  factory _Window._current(AnalyticsPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case AnalyticsPeriod.today:
        return _Window(today, today.add(const Duration(days: 1)));
      case AnalyticsPeriod.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return _Window(monday, monday.add(const Duration(days: 7)));
      case AnalyticsPeriod.month:
        return _Window(
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 1),
        );
      case AnalyticsPeriod.year:
        return _Window(
          DateTime(today.year, 1, 1),
          DateTime(today.year + 1, 1, 1),
        );
    }
  }

  _Window get previous {
    final span = end.difference(start);
    return _Window(start.subtract(span), start);
  }
}

int _trendIndex(DateTime t, AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.today:
      return (t.hour ~/ 4).clamp(0, 5);
    case AnalyticsPeriod.week:
      return (t.weekday - 1).clamp(0, 6);
    case AnalyticsPeriod.month:
      final day = t.day;
      if (day <= 5) return 0;
      if (day <= 10) return 1;
      if (day <= 15) return 2;
      if (day <= 20) return 3;
      if (day <= 25) return 4;
      return 5;
    case AnalyticsPeriod.year:
      return (t.month - 1).clamp(0, 11);
  }
}

/// Public accessor for calculating the trend bucket index of a timestamp.
int trendIndexFor(DateTime t, AnalyticsPeriod period) => _trendIndex(t, period);

/// Formats a trend bucket label into a human-readable calendar date range
/// (e.g. 'August 6–10, 2026' or 'Monday, Aug 10, 2026').
String trendBucketDateRange(String label, AnalyticsPeriod period, DateTime now) {
  final monthName = DateFormat('MMMM').format(now);
  final year = now.year;
  switch (period) {
    case AnalyticsPeriod.month:
      if (label == 'Day 1-5') return '$monthName 1–5, $year';
      if (label == 'Day 6-10') return '$monthName 6–10, $year';
      if (label == 'Day 11-15') return '$monthName 11–15, $year';
      if (label == 'Day 16-20') return '$monthName 16–20, $year';
      if (label == 'Day 21-25') return '$monthName 21–25, $year';
      if (label == 'Day 26+') {
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        return '$monthName 26–$lastDay, $year';
      }
      return label;
    case AnalyticsPeriod.week:
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final idx = days.indexOf(label);
      if (idx >= 0) {
        final d = monday.add(Duration(days: idx));
        return DateFormat('EEEE, MMM d, yyyy').format(d);
      }
      return label;
    case AnalyticsPeriod.today:
      final dateStr = DateFormat('MMM d, yyyy').format(now);
      if (label == '00:00') return '$dateStr • 12:00 AM – 3:59 AM';
      if (label == '04:00') return '$dateStr • 4:00 AM – 7:59 AM';
      if (label == '08:00') return '$dateStr • 8:00 AM – 11:59 AM';
      if (label == '12:00') return '$dateStr • 12:00 PM – 3:59 PM';
      if (label == '16:00') return '$dateStr • 4:00 PM – 7:59 PM';
      if (label == '20:00') return '$dateStr • 8:00 PM – 11:59 PM';
      return '$dateStr • $label';
    case AnalyticsPeriod.year:
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final idx = months.indexOf(label);
      if (idx >= 0) {
        final m = DateTime(now.year, idx + 1, 1);
        return DateFormat('MMMM yyyy').format(m);
      }
      return '$label $year';
  }
}


/// Immutable snapshot of scan analytics for a single time period.
///
/// Both Admin and Farmer analytics are built from this class so the numbers
/// are guaranteed to be identical for the same data scope.
class ScanAnalytics {
  final int totalValidScans;
  final Map<String, int> counts;
  final Map<String, int> previousCounts;
  final int previousTotalValid;
  final List<String> trendLabels;
  final Map<String, int> trendCounts;
  final Map<String, List<DetectionModel>> trendDetections;
  final String? mostFrequentDisease;

  const ScanAnalytics({
    required this.totalValidScans,
    required this.counts,
    required this.previousCounts,
    required this.previousTotalValid,
    required this.trendLabels,
    required this.trendCounts,
    this.trendDetections = const {},
    required this.mostFrequentDisease,
  });

  factory ScanAnalytics.fromDetections(
    List<DetectionModel> detections, {
    AnalyticsPeriod period = AnalyticsPeriod.month,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final valid = validScanRecords(detections);
    final window = _Window._current(period, ref);
    final prevWindow = window.previous;

    final counts = <String, int>{for (final c in kAnalyticsCategories) c: 0};
    final prevCounts = <String, int>{for (final c in kAnalyticsCategories) c: 0};

    for (final d in valid) {
      final category = analyticsCategoryFor(d.disease)!;
      if (!d.timestamp.isBefore(window.start) &&
          d.timestamp.isBefore(window.end)) {
        counts[category] = counts[category]! + 1;
      } else if (!d.timestamp.isBefore(prevWindow.start) &&
          d.timestamp.isBefore(prevWindow.end)) {
        prevCounts[category] = prevCounts[category]! + 1;
      }
    }

    final prevTotal = prevCounts.values.fold<int>(0, (s, v) => s + v);
    final labels = analyticsTrendLabels(period);
    final trend = <String, int>{for (final l in labels) l: 0};
    final trendDetections = <String, List<DetectionModel>>{
      for (final l in labels) l: <DetectionModel>[],
    };

    for (final d in valid) {
      if (!d.timestamp.isBefore(window.start) &&
          d.timestamp.isBefore(window.end)) {
        final idx = _trendIndex(d.timestamp, period);
        final label = labels[idx];
        trend[label] = trend[label]! + 1;
        trendDetections[label]!.add(d);
      }
    }

    // Sort scans in each bucket chronologically (earliest to latest)
    for (final list in trendDetections.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    String? mostFrequent;
    var mostCount = 0;
    for (final c in kAnalyticsCategories) {
      if (c == 'Healthy') continue;
      if (counts[c]! > mostCount) {
        mostCount = counts[c]!;
        mostFrequent = c;
      }
    }
    if (mostCount == 0) mostFrequent = null;

    return ScanAnalytics(
      totalValidScans: counts.values.fold<int>(0, (s, v) => s + v),
      counts: counts,
      previousCounts: prevCounts,
      previousTotalValid: prevTotal,
      trendLabels: labels,
      trendCounts: trend,
      trendDetections: trendDetections,
      mostFrequentDisease: mostFrequent,
    );
  }


  double percentageOf(String category) {
    if (totalValidScans == 0) return 0;
    return (counts[category] ?? 0) / totalValidScans * 100;
  }

  /// Real change vs the previous period (0 when there is no previous data).
  int deltaOf(String category) {
    return (counts[category] ?? 0) - (previousCounts[category] ?? 0);
  }

  int get maxTrendValue =>
      trendCounts.values.fold<int>(0, (m, v) => v > m ? v : m);
}

/// Understandable, dynamically generated summary statements derived entirely
/// from [analytics]. Never hardcoded.
List<String> generateScanInsights(ScanAnalytics analytics) {
  final t = analytics.totalValidScans;
  if (t == 0) {
    return [
      'No valid scan data yet. Start scanning rice leaves to see your analytics.',
    ];
  }

  final healthy = analytics.counts['Healthy'] ?? 0;
  final insights = <String>[
    'Healthy scans represent ${_roundPct(analytics.percentageOf('Healthy'))} '
        'of $t valid scans ($healthy of $t).',
  ];

  for (final c in kAnalyticsCategories) {
    if (c == 'Healthy') continue;
    final n = analytics.counts[c] ?? 0;
    if (n == 0) continue;
    insights.add(
      '$c was detected in $n of $t valid scans '
      '(${_roundPct(analytics.percentageOf(c))}).',
    );
  }

  if (t - healthy == 0) {
    insights.add('All valid scans were classified as Healthy.');
  } else if (analytics.mostFrequentDisease != null) {
    insights.add(
      '${analytics.mostFrequentDisease} is currently the most frequently '
      'detected disease.',
    );
  }

  return insights;
}

String _roundPct(double value) => '${value.toStringAsFixed(0)}%';
