import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../analytics/scan_analytics.dart';
import '../core/theme/app_theme.dart';
import '../models/detection_model.dart';
import '../models/user_model.dart';
import '../services/analytics_pdf_service.dart';
import 'admin_stat_card.dart';

/// Admin analytics dashboard: system overview, scan summary cards, disease
/// distribution, disease trends, and key insights.
class AdminDashboardCharts extends StatelessWidget {
  final AnalyticsPeriod period;
  final bool isLoading;
  final bool hasLoaded;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;
  final int totalUsers;
  final int activeFarmers;
  final int pendingSchedules;
  final int completedSchedules;
  final int archivedRecords;
  final List<DetectionModel> detections;
  final List<UserModel> farmers;
  final String? selectedFarmerId;
  final ValueChanged<String?> onFarmerChanged;
  final DateTime? lastUpdated;

  const AdminDashboardCharts({
    super.key,
    required this.period,
    required this.isLoading,
    required this.hasLoaded,
    required this.onPeriodChanged,
    required this.totalUsers,
    required this.activeFarmers,
    required this.pendingSchedules,
    required this.completedSchedules,
    required this.archivedRecords,
    required this.detections,
    required this.farmers,
    required this.selectedFarmerId,
    required this.onFarmerChanged,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 5-Card System KPI Grid ──
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final int crossAxisCount = w >= 1200 ? 5 : (w >= 760 ? 3 : 2);
            final double aspectRatio = w >= 1200 ? 1.85 : (w >= 760 ? 2.0 : 1.75);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: [
                AdminStatCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  icon: Icons.group_rounded,
                  iconColor: const Color(0xFF0284C7),
                  accentColor: const Color(0xFFE0F2FE),
                  subtitle: 'Registered accounts',
                ),
                AdminStatCard(
                  title: 'Active Farmers',
                  value: '$activeFarmers',
                  icon: Icons.agriculture_rounded,
                  iconColor: AppTheme.brandPrimary,
                  accentColor: AppTheme.adminPrimaryLight,
                  subtitle: 'With field records',
                ),
                AdminStatCard(
                  title: 'Pending Approvals',
                  value: '$pendingSchedules',
                  icon: Icons.pending_actions_rounded,
                  iconColor: const Color(0xFFD97706),
                  accentColor: const Color(0xFFFEF3C7),
                  subtitle: 'Awaiting review',
                ),
                AdminStatCard(
                  title: 'Completed',
                  value: '$completedSchedules',
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF16A34A),
                  accentColor: const Color(0xFFDCFCE7),
                  subtitle: 'Finished tasks',
                ),
                AdminStatCard(
                  title: 'Archived Vault',
                  value: '$archivedRecords',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF64748B),
                  accentColor: const Color(0xFFF1F5F9),
                  subtitle: 'Stored history',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Analytics Filter & Action Bar ──
        _buildAnalyticsHeader(context),
        const SizedBox(height: 12),
        _buildFilterBar(context),
        const SizedBox(height: 18),

        if (isLoading || !hasLoaded)
          _buildLoadingState()
        else if (ScanAnalytics.fromDetections(
                    _scopedDetections(),
                    period: period,
                  ).totalValidScans ==
                0)
          _buildEmptyState()
        else
          _buildAnalyticsBody(context),
      ],
    );
  }

  List<DetectionModel> _scopedDetections() {
    if (selectedFarmerId == null) return detections;
    return detections.where((d) => d.userId == selectedFarmerId).toList();
  }

  String? _scopeName() {
    if (selectedFarmerId == null) return null;
    for (final f in farmers) {
      if (f.id == selectedFarmerId) return f.name;
    }
    return 'Selected Farm';
  }

  // ── Header / Filters ────────────────────────────────────────────────────

  Widget _buildAnalyticsHeader(BuildContext context) {
    final scope = _scopeName();
    final scopeLabel = scope ?? 'All Farms';
    final timeLabel = analyticsPeriodLabel(period, DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, size: 18, color: AppTheme.adminPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Crop Health & Outbreak Analytics',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.adminTextPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Scope: $scopeLabel • Period: $timeLabel',
                style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary),
              ),
            ],
          ),
        ),
        if (lastUpdated != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.adminSurfaceSubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Synced ${DateFormat('h:mm a').format(lastUpdated!)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.adminTextMuted),
            ),
          ),
          const SizedBox(width: 10),
        ],
        _DownloadPdfButton(
          detections: detections,
          selectedFarmerId: selectedFarmerId,
          period: period,
          scopeLabel: scopeLabel,
          totalUsers: totalUsers,
          activeFarmers: activeFarmers,
          pendingSchedules: pendingSchedules,
          completedSchedules: completedSchedules,
          archivedRecords: archivedRecords,
          hasLoaded: hasLoaded,
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          // Period Segmented Buttons
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final p in AnalyticsPeriod.values)
                  ChoiceChip(
                    label: Text(_chipLabel(p)),
                    selected: p == period,
                    onSelected: (_) => onPeriodChanged(p),
                    selectedColor: AppTheme.adminPrimaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: p == period ? FontWeight.bold : FontWeight.w500,
                      color: p == period ? AppTheme.adminPrimary : AppTheme.adminTextSecondary,
                    ),
                    side: BorderSide(
                      color: p == period
                          ? AppTheme.adminPrimary.withValues(alpha: 0.4)
                          : AppTheme.adminBorder,
                    ),
                  ),
              ],
            ),
          ),
          // Farmer Selector
          if (farmers.isNotEmpty) ...[
            Container(
              height: 28,
              width: 1,
              color: AppTheme.adminBorder,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.adminBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.adminBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedFarmerId,
                  isExpanded: true,
                  hint: const Text('All Farmers / Plots', style: TextStyle(fontSize: 12.5)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Farmers / Plots', style: TextStyle(fontSize: 12.5)),
                    ),
                    for (final f in farmers)
                      if (f.isFarmer)
                        DropdownMenuItem<String?>(
                          value: f.id,
                          child: Text(
                            f.name,
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: onFarmerChanged,
                ),
              ),
            ),
          ],
        ],
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

  // ── Loading / Empty states ──────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: List.generate(5, (_) => _skeletonCard()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _skeletonCard(height: 260)),
            const SizedBox(width: 14),
            Expanded(child: _skeletonCard(height: 260)),
          ],
        ),
      ],
    );
  }

  Widget _skeletonCard({double height = 100}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
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
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.adminPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.biotech_rounded, size: 40, color: AppTheme.adminPrimary),
          ),
          const SizedBox(height: 14),
          const Text(
            'No valid scan records in this period',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan records submitted by farmers will automatically appear here in real time.',
            style: TextStyle(fontSize: 13, color: AppTheme.adminTextSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Invalid scan records are automatically filtered out from all analytics.',
            style: TextStyle(fontSize: 11, color: AppTheme.adminTextMuted),
          ),
        ],
      ),
    );
  }

  // ── Analytics body ──────────────────────────────────────────────────────

  Widget _buildAnalyticsBody(BuildContext context) {
    final analytics = ScanAnalytics.fromDetections(_scopedDetections(), period: period);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w >= 1200 ? 5 : (w >= 640 ? 3 : 2);
            final cards = [
              _summaryCard(
                'Total Valid Scans',
                analytics.totalValidScans,
                null,
                Icons.qr_code_scanner_rounded,
                AppTheme.brandPrimary,
                'Verified crop detections',
                hasPrev: analytics.previousTotalValid > 0,
                delta: analytics.totalValidScans - analytics.previousTotalValid,
              ),
              for (final c in kAnalyticsCategories)
                _summaryCard(
                  c,
                  analytics.counts[c] ?? 0,
                  analytics.percentageOf(c),
                  _iconFor(c),
                  analyticsColorFor(c, kAnalyticsCategories.indexOf(c)),
                  '${_roundPct(analytics.percentageOf(c))} of all scans',
                  hasPrev: analytics.previousTotalValid > 0,
                  delta: analytics.deltaOf(c),
                ),
            ];
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: w >= 640 ? 1.75 : 1.5,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 18),

        // Distribution & Trends Charts Row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 980) {
              return Column(
                children: [
                  _distributionCard(context, analytics),
                  const SizedBox(height: 14),
                  _trendCard(context, analytics),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _distributionCard(context, analytics)),
                const SizedBox(width: 14),
                Expanded(flex: 6, child: _trendCard(context, analytics)),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // Key Insights Card
        _insightsCard(context, analytics),
      ],
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Healthy':
        return Icons.eco_rounded;
      case 'Brown Spot':
        return Icons.grain_rounded;
      case 'Sheath Blight':
        return Icons.water_drop_rounded;
      default:
        return Icons.coronavirus_rounded;
    }
  }

  Widget _summaryCard(
    String label,
    int count,
    double? pct,
    IconData icon,
    Color color,
    String subtitle, {
    required bool hasPrev,
    required int delta,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.adminCardDecoration(
        accentColor: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.adminTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppTheme.adminTextPrimary,
                ),
              ),
              if (pct != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    _roundPct(pct),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasPrev && delta != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: delta > 0 ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 11,
                        color: delta > 0 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                      Text(
                        '${delta.abs()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: delta > 0 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.adminTextMuted),
          ),
        ],
      ),
    );
  }

  // ── Distribution Donut ──────────────────────────────────────────────────

  Widget _distributionCard(BuildContext context, ScanAnalytics analytics) {
    final entries = kAnalyticsCategories
        .map((c) => MapEntry(c, analytics.counts[c] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disease Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.adminTextPrimary),
              ),
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppTheme.adminTextSecondary),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Proportion of valid scans across canonical classes',
            style: TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary),
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 190,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    sections: entries.asMap().entries.map((me) {
                      final idx = me.key;
                      final entry = me.value;
                      final color = analyticsColorFor(entry.key, idx);
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: _roundPct(analytics.percentageOf(entry.key)),
                        color: color,
                        radius: 46,
                        titleStyle: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${analytics.totalValidScans}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.adminTextPrimary,
                    ),
                  ),
                  const Text(
                    'Scans',
                    style: TextStyle(fontSize: 10, color: AppTheme.adminTextMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.adminBorderLight),
          const SizedBox(height: 10),
          ...entries.map((e) {
            final color = analyticsColorFor(e.key, kAnalyticsCategories.indexOf(e.key));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${e.value} (${_roundPct(analytics.percentageOf(e.key))})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Trend Line Chart ───────────────────────────────────────────────────

  String _trendUnit(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return '4-hour interval';
      case AnalyticsPeriod.week:
        return 'day';
      case AnalyticsPeriod.month:
        return '5-day interval';
      case AnalyticsPeriod.year:
        return 'month';
    }
  }

  Widget _trendCard(BuildContext context, ScanAnalytics analytics) {
    final spots = <FlSpot>[];
    final labels = analytics.trendLabels;
    var idx = 0;
    var maxY = 5.0;

    final farmerMap = {for (final f in farmers) f.id: f.name};

    for (final label in labels) {
      final count = analytics.trendCounts[label] ?? 0;
      if (count.toDouble() > maxY) {
        maxY = (count + 2).toDouble();
      }
      spots.add(FlSpot(idx.toDouble(), count.toDouble()));
      idx++;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outbreak Trend Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.adminTextPrimary),
              ),
              Icon(Icons.show_chart_rounded, size: 18, color: AppTheme.adminTextSecondary),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Scans per ${_trendUnit(period)} in this period',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: AppTheme.adminBorderLight,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF0F172A),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    maxContentWidth: 290,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        if (i < 0 || i >= labels.length) return null;
                        final label = labels[i];
                        final list = analytics.trendDetections[label] ?? const <DetectionModel>[];
                        final total = list.length;

                        final children = <TextSpan>[];

                        children.add(
                          TextSpan(
                            text: '$total scan${total == 1 ? '' : 's'}\n\n',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );

                        if (total == 0) {
                          children.add(
                            const TextSpan(
                              text: 'No scans recorded during this period.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        } else {
                          const maxVisible = 5;
                          final visibleList = list.take(maxVisible).toList();

                          for (var j = 0; j < visibleList.length; j++) {
                            final d = visibleList[j];
                            final cat = analyticsCategoryFor(d.disease) ?? d.disease;
                            final color = kAnalyticsCategoryColors[cat] ?? const Color(0xFF38BDF8);
                            final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(d.timestamp);
                            final farmerName = farmerMap[d.userId];

                            children.add(
                              TextSpan(
                                text: '• ${d.disease}\n',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                            if (farmerName != null && farmerName.isNotEmpty) {
                              children.add(
                                TextSpan(
                                  text: '  Farmer: $farmerName\n',
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }

                            final confStr = d.confidence > 0
                                ? ' • ${(d.confidence * 100).toStringAsFixed(0)}%'
                                : '';
                            children.add(
                              TextSpan(
                                text: '  $dateStr$confStr\n',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                ),
                              ),
                            );

                            if (j < visibleList.length - 1) {
                              children.add(const TextSpan(text: '\n'));
                            }
                          }

                          if (total > maxVisible) {
                            final remaining = total - maxVisible;
                            children.add(
                              TextSpan(
                                text: '\n+ $remaining more scan${remaining == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        }

                        return LineTooltipItem(
                          '$label\n',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                          children: children,
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppTheme.adminTextMuted),
                      ),
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
                            style: const TextStyle(fontSize: 10, color: AppTheme.adminTextSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.adminPrimary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeColor: AppTheme.adminPrimary,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.adminPrimary.withValues(alpha: 0.22),
                          AppTheme.adminPrimary.withValues(alpha: 0.01),
                        ],
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


  // ── Insights Card ───────────────────────────────────────────────────────

  Widget _insightsCard(BuildContext context, ScanAnalytics analytics) {
    final insights = generateScanInsights(analytics);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Key Agronomy & Field Insights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF15803D)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
                    child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF166534))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roundPct(double v) => '${v.toStringAsFixed(1)}%';
}

/// Compact "Download PDF" action that renders the currently visible analytics
/// scope to a PDF and saves it (browser blob on web, file on native).
class _DownloadPdfButton extends StatefulWidget {
  const _DownloadPdfButton({
    required this.detections,
    required this.selectedFarmerId,
    required this.period,
    required this.scopeLabel,
    required this.totalUsers,
    required this.activeFarmers,
    required this.pendingSchedules,
    required this.completedSchedules,
    required this.archivedRecords,
    required this.hasLoaded,
  });

  final List<DetectionModel> detections;
  final String? selectedFarmerId;
  final AnalyticsPeriod period;
  final String scopeLabel;
  final int totalUsers;
  final int activeFarmers;
  final int pendingSchedules;
  final int completedSchedules;
  final int archivedRecords;
  final bool hasLoaded;

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _exporting = false;

  Future<void> _download() async {
    if (_exporting) return;
    final now = DateTime.now();
    setState(() => _exporting = true);
    try {
      final scoped = widget.selectedFarmerId == null
          ? widget.detections
          : widget.detections
              .where((d) => d.userId == widget.selectedFarmerId)
              .toList();
      final analytics =
          ScanAnalytics.fromDetections(scoped, period: widget.period, now: now);
      final bytes = await AnalyticsPdfService.buildAnalyticsPdf(
        analytics: analytics,
        period: widget.period,
        scopeLabel: widget.scopeLabel,
        generatedAt: now,
        totalUsers: widget.totalUsers,
        activeFarmers: widget.activeFarmers,
        pendingSchedules: widget.pendingSchedules,
        completedSchedules: widget.completedSchedules,
        archivedRecords: widget.archivedRecords,
      );
      if (!mounted) return;
      await AnalyticsPdfService.downloadAnalyticsPdf(
        context: context,
        bytes: bytes,
        fileName: _fileName(now),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF report: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fileName(DateTime now) {
    final scope =
        widget.scopeLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(now);
    return 'sfarm_scan_analytics_${scope}_${widget.period.name}_$stamp.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: widget.hasLoaded && !_exporting ? _download : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      icon: _exporting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
      label: const Text('Download PDF'),
    );
  }
}
