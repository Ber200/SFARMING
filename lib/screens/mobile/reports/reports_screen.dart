import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/detection_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/soil_provider.dart';
import '../../../models/weather_forecast_model.dart';
import '../../../models/disease_info_model.dart';
import '../../../models/detection_model.dart';
import '../../../widgets/detection_details_dialog.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_drawer.dart';
import '../../../analytics/scan_analytics.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        Provider.of<DetectionProvider>(context, listen: false).loadDetections(userId);
        Provider.of<TreatmentProvider>(context, listen: false).loadTreatments(userId);
        Provider.of<WeatherProvider>(context, listen: false).loadFarmWeather();
        Provider.of<SoilProvider>(context, listen: false).loadSoilData(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Farm Reports & Analytics'),
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.reports),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final userId = authProvider.currentUser?.id ?? '';
          if (userId.isNotEmpty) {
            Provider.of<DetectionProvider>(context, listen: false)
                .loadDetections(userId);
            Provider.of<TreatmentProvider>(context, listen: false)
                .loadTreatments(userId);
            Provider.of<WeatherProvider>(context, listen: false)
                .loadFarmWeather();
            Provider.of<SoilProvider>(context, listen: false)
                .loadSoilData(userId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Intro Banner
              _buildAnalyticsHeaderBanner(context),
              const SizedBox(height: 16),

              // Scan Analytics (shared logic with Admin)
              Consumer<DetectionProvider>(
                builder: (context, dp, _) =>
                    _buildScanAnalyticsSection(context, dp),
              ),
              const SizedBox(height: 16),

              // Treatment Statistics Card
              Consumer<TreatmentProvider>(
                builder: (context, tp, _) =>
                    _buildTreatmentStatisticsSection(context, tp),
              ),
              const SizedBox(height: 16),

              // Smart Treatment Coordination Advisory
              _buildTreatmentCoordination(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan analytics section ──────────────────────────────────────────────

  Widget _buildScanAnalyticsSection(
      BuildContext context, DetectionProvider dp) {
    final analytics = ScanAnalytics.fromDetections(
      dp.detections,
      period: _period,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPeriodFilter(),
        const SizedBox(height: 12),
        _buildScopeLabel(context, dp),
        const SizedBox(height: 14),
        if (!dp.hasLoaded)
          _buildLoadingState()
        else if (analytics.totalValidScans == 0)
          _buildEmptyState()
        else ...[
          _buildSummaryCards(analytics),
          const SizedBox(height: 14),
          _buildDistributionCard(context, analytics),
          const SizedBox(height: 14),
          _buildTrendCard(context, analytics),
          const SizedBox(height: 14),
          _buildInsightsCard(analytics),
        ],
        const SizedBox(height: 8),
        Text(
          'Percentages are based on valid scans only. Invalid scans are excluded.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsPeriod.values.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_chipLabel(p)),
              selected: selected,
              onSelected: (_) => setState(() => _period = p),
              selectedColor: AppTheme.brandPrimary.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? AppTheme.brandPrimary : Colors.grey[600],
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected ? AppTheme.brandPrimary : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _chipLabel(AnalyticsPeriod p) {
    switch (p) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.week:
        return 'This Week';
      case AnalyticsPeriod.month:
        return 'This Month';
      case AnalyticsPeriod.year:
        return 'This Year';
    }
  }

  Widget _buildScopeLabel(BuildContext context, DetectionProvider dp) {
    final scope =
        'Showing statistics for My Farm · ${analyticsPeriodLabel(_period, DateTime.now())}';
    String updated = '';
    if (dp.lastUpdated != null) {
      final diff = DateTime.now().difference(dp.lastUpdated!);
      updated = diff.inSeconds < 60
          ? 'Updated just now'
          : 'Last updated: ${DateFormat('h:mm a').format(dp.lastUpdated!)}';
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            scope,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        if (updated.isNotEmpty)
          Text(
            updated,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _skeletonBox(height: 76),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _skeletonBox(height: 110)),
            const SizedBox(width: 12),
            Expanded(child: _skeletonBox(height: 110)),
          ],
        ),
        const SizedBox(height: 12),
        _skeletonBox(height: 220),
      ],
    );
  }

  Widget _skeletonBox({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        children: [
          Icon(Icons.biotech_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No valid scan data yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Start scanning rice leaves to see your analytics.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Summary cards ───────────────────────────────────────────────────────

  Widget _buildSummaryCards(ScanAnalytics analytics) {
    return Column(
      children: [
        _summaryCard(
          label: 'Total Valid Scans',
          count: analytics.totalValidScans,
          pct: null,
          icon: Icons.qr_code_scanner_rounded,
          color: AppTheme.brandPrimary,
          subtitle: 'All valid disease-detection scans',
          hero: true,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 4 : 2;
            final cards = [
              for (final c in kAnalyticsCategories)
                _summaryCard(
                  label: c,
                  count: analytics.counts[c] ?? 0,
                  pct: analytics.percentageOf(c),
                  icon: _iconFor(c),
                  color: analyticsColorFor(c, kAnalyticsCategories.indexOf(c)),
                  subtitle:
                      '${_roundPct(analytics.percentageOf(c))} of valid scans',
                ),
            ];
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.7 : 1.6,
              children: cards,
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required double? pct,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool hero = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: hero
          ? Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.14),
                      child: Icon(icon, color: color, size: 15),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  pct != null ? _roundPct(pct) : subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
    );
    return Container(
      decoration: AppTheme.farmCardDecoration(),
      child: content,
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Healthy':
        return Icons.eco_rounded;
      case 'Brown Spot':
        return Icons.grain_rounded;
      case 'Sheath Blight':
        return Icons.agriculture_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  // ── Distribution ────────────────────────────────────────────────────────

  Widget _buildDistributionCard(BuildContext context, ScanAnalytics analytics) {
    final entries = kAnalyticsCategories
        .map((c) => MapEntry(c, analytics.counts[c] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dp = Provider.of<DetectionProvider>(context, listen: false);
    final farmerName = authProvider.currentUser?.name ?? 'Farmer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded,
                  color: AppTheme.brandPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disease Distribution',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What percentage of valid scans belong to each category?',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent &&
                        pieTouchResponse != null &&
                        pieTouchResponse.touchedSection != null) {
                      final idx =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (idx >= 0 && idx < entries.length) {
                        final name = entries[idx].key;
                        final count = entries[idx].value;
                        _showDiseaseDetailsModal(
                          context,
                          name,
                          count,
                          analytics.totalValidScans,
                          analytics.percentageOf(name),
                          analytics: analytics,
                          detections: dp.detections,
                          farmerName: farmerName,
                        );
                      }
                    }
                  },
                ),
                sections: entries.asMap().entries.map((me) {
                  final entry = me.value;
                  final color = analyticsColorFor(
                    entry.key,
                    kAnalyticsCategories.indexOf(entry.key),
                  );
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    color: color,
                    radius: 54,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final color = analyticsColorFor(
              e.key,
              kAnalyticsCategories.indexOf(e.key),
            );
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showDiseaseDetailsModal(
                    context,
                    e.key,
                    e.value,
                    analytics.totalValidScans,
                    analytics.percentageOf(e.key),
                    analytics: analytics,
                    detections: dp.detections,
                    farmerName: farmerName,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${e.value} · ${_roundPct(analytics.percentageOf(e.key))}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap any chart slice or category to view symptoms & treatment advice',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Trend ───────────────────────────────────────────────────────────────

  Widget _buildTrendCard(BuildContext context, ScanAnalytics analytics) {
    final labels = analytics.trendLabels;
    final maxY = (analytics.maxTrendValue + 1).toDouble();
    final spots = <FlSpot>[
      for (var i = 0; i < labels.length; i++)
        FlSpot(
            i.toDouble(), (analytics.trendCounts[labels[i]] ?? 0).toDouble()),
    ];

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmerName = authProvider.currentUser?.name ?? 'Farmer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  color: AppTheme.brandPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Disease Trend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valid scans per ${_trendUnit(_period)} · ${analyticsPeriodLabel(_period, DateTime.now())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent &&
                        touchResponse != null &&
                        touchResponse.lineBarSpots != null &&
                        touchResponse.lineBarSpots!.isNotEmpty) {
                      final spot = touchResponse.lineBarSpots!.first;
                      final i = spot.x.toInt();
                      if (i >= 0 && i < labels.length) {
                        final label = labels[i];
                        _showTrendPeriodDetailsModal(
                          context,
                          label: label,
                          period: _period,
                          analytics: analytics,
                          detections: analytics.trendDetections[label] ?? const <DetectionModel>[],
                          farmerName: farmerName,
                        );
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF0F172A),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        if (i < 0 || i >= labels.length) return null;
                        final label = labels[i];
                        final list = analytics.trendDetections[label] ?? const <DetectionModel>[];
                        final total = list.length;
                        final dateStr = trendBucketDateRange(label, _period, DateTime.now());

                        return LineTooltipItem(
                          '$label ($dateStr)\n$total valid scan${total == 1 ? '' : 's'}\nTap for breakdown',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: _leftTitle,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: labels.length > 8 ? 2 : 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppTheme.brandPrimary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap any chart point to view disease breakdown & scan timeline',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _trendUnit(AnalyticsPeriod p) {
    switch (p) {
      case AnalyticsPeriod.today:
        return '4-hour window';
      case AnalyticsPeriod.week:
        return 'day';
      case AnalyticsPeriod.month:
        return '5-day period';
      case AnalyticsPeriod.year:
        return 'month';
    }
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  // ── Insights ────────────────────────────────────────────────────────────

  Widget _buildInsightsCard(ScanAnalytics analytics) {
    final insights = generateScanInsights(analytics);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppTheme.brandPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Key Insights',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roundPct(double v) => '${v.toStringAsFixed(0)}%';

  // ── Header banner ───────────────────────────────────────────────────────

  Widget _buildAnalyticsHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.adminPrimary, AppTheme.adminPrimary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Health & Disease Insights',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Understand what your farm metrics mean and how to act.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Disease details modal ───────────────────────────────────────────────

  void _showDiseaseDetailsModal(
    BuildContext context,
    String diseaseName,
    int count,
    int total,
    double percentage, {
    ScanAnalytics? analytics,
    List<DetectionModel> detections = const [],
    String farmerName = 'Farmer',
  }) {
    final diseaseInfo = DiseaseInfoModel.getDiseaseInfo(diseaseName);
    final isHealthy = diseaseName.toLowerCase().contains('healthy');
    final color = kAnalyticsCategoryColors[diseaseName] ??
        (isHealthy ? const Color(0xFF43A047) : const Color(0xFFE53935));

    // Find the most recent detection in this category
    DateTime? latestDate;
    final categoryDetections = <DetectionModel>[];
    for (final d in detections) {
      if (d.isArchived) continue;
      if (analyticsCategoryFor(d.disease) == diseaseName) {
        categoryDetections.add(d);
        if (latestDate == null || d.timestamp.isAfter(latestDate)) {
          latestDate = d.timestamp;
        }
      }
    }
    categoryDetections.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // AI Weather advisory for this disease if available
    final wp = Provider.of<WeatherProvider>(context, listen: false);
    final aiAnalysis = wp.aiAnalysis;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHealthy
                          ? Icons.eco_rounded
                          : Icons.coronavirus_rounded,
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          isHealthy
                              ? 'Optimal Crop Vitality'
                              : 'Foliar Disease Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Key Stats Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _modalMetricCol(
                          title: 'Scans',
                          value: '$count',
                          color: color,
                        ),
                        Container(height: 28, width: 1, color: color.withValues(alpha: 0.2)),
                        _modalMetricCol(
                          title: 'Share of Valid',
                          value: '${percentage.toStringAsFixed(1)}%',
                          color: color,
                        ),
                        Container(height: 28, width: 1, color: color.withValues(alpha: 0.2)),
                        _modalMetricCol(
                          title: 'Total In View',
                          value: '$total',
                          color: const Color(0xFF475569),
                        ),
                      ],
                    ),
                    if (latestDate != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Last recorded: ${DateFormat('MMMM d, yyyy • h:mm a').format(latestDate)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Status / Summary
              _modalSectionHeader('Status & Overview', Icons.info_outline_rounded),
              const SizedBox(height: 8),
              Text(
                isHealthy
                    ? 'No pathogenic lesions detected in these $count scans. The leaf tissue demonstrates optimal chlorophyll density and healthy crop growth.'
                    : (diseaseInfo?.description ?? 'Detections identified for $diseaseName. Timely containment is recommended.'),
                style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
              ),

              // Symptoms
              if (diseaseInfo != null && diseaseInfo.symptoms.isNotEmpty) ...[
                const SizedBox(height: 18),
                _modalSectionHeader('Identified Symptoms', Icons.visibility_outlined),
                const SizedBox(height: 8),
                ...diseaseInfo.symptoms.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[800], height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Recommended Action
              if (diseaseInfo != null && diseaseInfo.treatmentProtocol.isNotEmpty) ...[
                const SizedBox(height: 18),
                _modalSectionHeader('Recommended Action & Management', Icons.medical_services_outlined),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppTheme.brandPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          diseaseInfo.treatmentProtocol,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey[850], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Contextual AI Advisory
              if (aiAnalysis != null && aiAnalysis.overallSummary.isNotEmpty) ...[
                const SizedBox(height: 18),
                _modalSectionHeader('AI Farm Weather Context', Icons.auto_awesome_rounded),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.smart_toy_outlined, color: AppTheme.brandPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHealthy
                                  ? 'Current forecast conditions support steady crop health. ${aiAnalysis.overallSummary}'
                                  : 'Weather factors relevant to $diseaseName: ${aiAnalysis.overallSummary}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.35),
                            ),
                            if (aiAnalysis.bestActionWindow.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Recommended window: ${aiAnalysis.bestActionWindow}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Recent Scans in this Category
              if (categoryDetections.isNotEmpty) ...[
                const SizedBox(height: 20),
                _modalSectionHeader('Recorded Scans (${categoryDetections.length})', Icons.photo_library_outlined),
                const SizedBox(height: 8),
                ...categoryDetections.take(5).map((d) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: color.withValues(alpha: 0.14),
                        child: Icon(Icons.qr_code_scanner_rounded, size: 15, color: color),
                      ),
                      title: Text(
                        d.disease,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(d.timestamp),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: d.confidence > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(d.confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () {
                        DetectionDetailsDialog.show(context, d, farmerName);
                      },
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Trend period details modal ──────────────────────────────────────────

  void _showTrendPeriodDetailsModal(
    BuildContext context, {
    required String label,
    required AnalyticsPeriod period,
    required ScanAnalytics analytics,
    required List<DetectionModel> detections,
    String farmerName = 'Farmer',
  }) {
    final dateRangeStr = trendBucketDateRange(label, period, DateTime.now());
    final total = detections.length;

    // Disease breakdown for this bucket
    final breakdown = <String, int>{for (final c in kAnalyticsCategories) c: 0};
    for (final d in detections) {
      final cat = analyticsCategoryFor(d.disease);
      if (cat != null) {
        breakdown[cat] = (breakdown[cat] ?? 0) + 1;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      color: AppTheme.brandPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trend Period: $label',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          dateRangeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Period Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppTheme.brandPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$total Valid Scan${total == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.brandPrimary,
                            ),
                          ),
                          Text(
                            analytics.totalValidScans > 0
                                ? '${((total / analytics.totalValidScans) * 100).toStringAsFixed(1)}% of all valid scans in this report'
                                : 'No scans recorded in this window',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Disease Breakdown Grid
              _modalSectionHeader('Disease Breakdown', Icons.pie_chart_outline_rounded),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAnalyticsCategories.map((cat) {
                  final count = breakdown[cat] ?? 0;
                  final catColor = kAnalyticsCategoryColors[cat] ?? const Color(0xFF64748B);
                  final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: count > 0 ? catColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: count > 0 ? catColor.withValues(alpha: 0.3) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$cat: $count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? const Color(0xFF1E293B) : Colors.grey[500],
                          ),
                        ),
                        if (total > 0 && count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($pct%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Scan History List
              _modalSectionHeader('Scans in this Window ($total)', Icons.format_list_bulleted_rounded),
              const SizedBox(height: 8),
              if (detections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text(
                          'No scans recorded during $label',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...detections.map((d) {
                  final cat = analyticsCategoryFor(d.disease) ?? d.disease;
                  final catColor = kAnalyticsCategoryColors[cat] ?? const Color(0xFF38BDF8);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: catColor.withValues(alpha: 0.14),
                        child: Icon(
                          cat == 'Healthy' ? Icons.eco_rounded : Icons.coronavirus_rounded,
                          size: 18,
                          color: catColor,
                        ),
                      ),
                      title: Text(
                        d.disease,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        DateFormat('MMMM d, yyyy • h:mm a').format(d.timestamp),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (d.confidence > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(d.confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                      onTap: () {
                        DetectionDetailsDialog.show(context, d, farmerName);
                      },
                    ),
                  );
                }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalMetricCol({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _modalSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.brandPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }


  // ── Treatment statistics ────────────────────────────────────────────────

  Widget _buildTreatmentStatisticsSection(BuildContext context, TreatmentProvider tp) {
    final pending = tp.pendingTreatments.length;
    final completed = tp.completedTreatments.length;
    final total = pending + completed;
    final completionRate = total > 0 ? (completed / total) : 0.0;


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppTheme.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Treatment Progress & Completion',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Track scheduled field treatment progress',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '${(completionRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandPrimary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Tasks', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        '$pending',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text('Awaiting application', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Completed Tasks', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        '$completed',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text('Successfully treated', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Treatment coordination ──────────────────────────────────────────────

  Widget _buildTreatmentCoordination(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.farmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: AppTheme.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Weather & Treatment Coordination',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Smart advisory matching weather forecasts with treatment schedules',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Consumer<WeatherProvider>(
            builder: (context, weatherProvider, _) {
              return Consumer<SoilProvider>(
                builder: (context, soilProvider, _) {
                  return Consumer<TreatmentProvider>(
                    builder: (context, treatmentProvider, _) {
                      final weather = weatherProvider.currentWeather;
                      final soilData = soilProvider.soilData;
                      final upcomingTreatments = treatmentProvider
                          .pendingTreatments
                        ..sort(
                            (a, b) => a.scheduleDate.compareTo(b.scheduleDate));

                      if (upcomingTreatments.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'No upcoming treatments to coordinate.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      final nextTreatment = upcomingTreatments.first;
                      final treatmentDate = nextTreatment.scheduleDate;
                      final daysUntil =
                          treatmentDate.difference(DateTime.now()).inDays;

                      WeatherForecastModel? forecastForDate;
                      try {
                        forecastForDate = weatherProvider.forecast.firstWhere(
                          (f) =>
                              f.date.day == treatmentDate.day &&
                              f.date.month == treatmentDate.month,
                        );
                      } catch (e) {
                        if (weatherProvider.forecast.isNotEmpty) {
                          forecastForDate = weatherProvider.forecast.first;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Task: ${nextTreatment.disease}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.brandPrimary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Scheduled: ${DateFormat('MMM dd, yyyy').format(treatmentDate)} ($daysUntil days away)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (weather != null || forecastForDate != null) ...[
                            _buildCoordinationItem(
                              context,
                              'Weather Forecast',
                              weather != null
                                  ? weather.status
                                  : (forecastForDate != null
                                      ? forecastForDate.status
                                      : 'Unknown'),
                              _getStatusColor(weather != null
                                  ? weather.status
                                  : (forecastForDate != null
                                      ? forecastForDate.status
                                      : '')),
                              weather != null && weather.isGoodForSpraying
                                  ? '✅ Weather is suitable for treatment application.'
                                  : '⚠️ Weather conditions may not be ideal. Consider rescheduling.',
                            ),
                            const SizedBox(height: 10),
                            if (weather != null &&
                                weather.rainProbability > 60)
                              _buildCoordinationItem(
                                context,
                                'Rain Warning',
                                '${weather.rainProbability.toStringAsFixed(0)}% probability',
                                Colors.red,
                                '⚠️ High rain probability. Avoid spraying treatments on this date.',
                              ),
                          ],
                          const SizedBox(height: 10),
                          if (soilData != null) ...[
                            _buildCoordinationItem(
                              context,
                              'Soil Condition',
                              soilData.calculatedStatus,
                              _getSoilStatusColor(soilData.moisture),
                              _getSoilCoordinationMessage(soilData),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_rounded,
                                    color: Colors.green.shade800, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getOverallRecommendation(
                                      weather,
                                      forecastForDate,
                                      soilData,
                                      nextTreatment,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinationItem(
    BuildContext context,
    String title,
    String status,
    Color statusColor,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BAD':
        return Colors.red.shade700;
      case 'WARNING':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  Color _getSoilStatusColor(double? moisture) {
    if (moisture == null) return Colors.grey;
    if (moisture < 30) return Colors.orange.shade700;
    if (moisture > 70) return Colors.blue.shade700;
    return Colors.green.shade700;
  }

  String _getSoilCoordinationMessage(soilData) {
    if (soilData.moisture == null) {
      return 'Soil data not available. Update soil readings for better coordination.';
    }
    if (soilData.moisture! < 30) {
      return '⚠️ Low soil moisture detected. Ensure adequate irrigation before treatment application.';
    } else if (soilData.moisture! > 70) {
      return '⚠️ High soil moisture. Wait for better drainage conditions before applying treatments.';
    }
    return '✅ Soil conditions are optimal for treatment application.';
  }

  String _getOverallRecommendation(
      weather, forecastForDate, soilData, nextTreatment) {
    final issues = <String>[];

    if (weather != null && !weather.isGoodForSpraying) {
      issues.add('weather conditions');
    }
    if (forecastForDate != null &&
        forecastForDate.rainProbability != null &&
        forecastForDate.rainProbability! > 60) {
      issues.add('high rain probability');
    }
    if (soilData != null && soilData.moisture != null) {
      if (soilData.moisture! < 30) {
        issues.add('low soil moisture');
      } else if (soilData.moisture! > 70) {
        issues.add('high soil moisture');
      }
    }

    if (issues.isEmpty) {
      return '✅ All conditions are optimal for the scheduled treatment. Proceed as planned.';
    } else {
      return '⚠️ Consider rescheduling treatment due to: ${issues.join(', ')}. Coordinate with optimal weather and soil conditions for best results.';
    }
  }
}
