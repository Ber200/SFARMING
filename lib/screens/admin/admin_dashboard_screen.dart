import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/detection_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/treatment_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_dashboard_charts.dart';
import '../../widgets/admin_weather_widget.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/app_feedback.dart';
import '../../analytics/scan_analytics.dart';

/// Admin landing page: side nav, farmer activities, treatments, upcoming section.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebase = FirebaseService();
  final Map<String, UserModel?> _userCache = {};
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  String? _selectedFarmerId;
  bool _analyticsLoading = true;
  int _totalUsers = 0;
  List<UserModel> _farmers = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Provider.of<DetectionProvider>(context, listen: false).loadDetections('');
    Provider.of<TreatmentProvider>(context, listen: false).loadTreatments('');
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    try {
      final users = await _firebase.getAllUsers().first;
      if (!mounted) return;
      setState(() {
        _totalUsers = users.length;
        _farmers = users.where((u) => u.isFarmer).toList();
        _analyticsLoading = false;
      });
    } catch (e) {
      debugPrint('[AdminDashboard] Failed to load analytics: $e');
      if (!mounted) return;
      setState(() => _analyticsLoading = false);
    }
  }

  Future<UserModel?> _getUserName(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    final user = await _firebase.getUserData(userId);
    _userCache[userId] = user;
    return user;
  }

  Widget _buildLoadErrorBanner(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.red.shade900),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Command Dashboard',
      subtitle: 'Central operations, live outbreak tracking & field schedules',
      activeRoute: AppRoutes.adminDashboard,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner ──
              _buildHeaderBanner(context),
              const SizedBox(height: 20),

              // ── Weather & Farm Overview ──
              const AdminWeatherWidget(),
              const SizedBox(height: 24),

              // ── Analytics & Stats Section ──
              Consumer2<TreatmentProvider, DetectionProvider>(
                builder: (context, treat, det, _) {
                  if (det.errorMessage != null || treat.errorMessage != null) {
                    return _buildLoadErrorBanner(
                      context,
                      det.errorMessage ?? treat.errorMessage!,
                      () => _loadData(),
                    );
                  }
                  final activeFarmerIds = <String>{
                    for (final t in treat.treatments)
                      if (t.userId.isNotEmpty) t.userId,
                    for (final d in validScanRecords(det.detections))
                      if (d.userId.isNotEmpty) d.userId,
                  };
                  final activeFarmers =
                      _farmers.where((u) => activeFarmerIds.contains(u.id)).length;
                  return AdminDashboardCharts(
                    period: _period,
                    isLoading: _analyticsLoading || treat.isLoading || det.isLoading,
                    hasLoaded: det.hasLoaded,
                    onPeriodChanged: (value) => setState(() => _period = value),
                    totalUsers: _totalUsers,
                    activeFarmers: activeFarmers,
                    pendingSchedules: treat.pendingTreatments.length,
                    completedSchedules: treat.completedTreatments.length,
                    archivedRecords: treat.archivedTreatments.length,
                    detections: det.detections,
                    farmers: _farmers,
                    selectedFarmerId: _selectedFarmerId,
                    onFarmerChanged: (value) => setState(() => _selectedFarmerId = value),
                    lastUpdated: det.lastUpdated,
                  );
                },
              ),

              // ── High-Priority Pending Approvals ──
              const SizedBox(height: 28),
              _buildPendingApprovalSection(context),

              // ── Upcoming Schedules ──
              const SizedBox(height: 28),
              _sectionHeader(
                context,
                title: 'Schedule Coordination',
                icon: Icons.calendar_month_rounded,
                badge: 'FIELD TASKS',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        _buildUpcomingTreatmentsSection(context),
                        const SizedBox(height: 14),
                        _buildUpcomingFertilizationSection(context),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUpcomingTreatmentsSection(context)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildUpcomingFertilizationSection(context)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildScheduleStatisticsCard(context),

              // ── Recent Activity Log ──
              const SizedBox(height: 28),
              _sectionHeader(
                context,
                title: 'Recent Activity Stream',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 12),
              _buildRecentTreatments(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(now);

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: AppTheme.adminCardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.adminPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.waving_hand_rounded, color: AppTheme.adminPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${auth.currentUser?.name ?? 'Admin'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.adminTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.adminTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Text(
                      'All Systems Synced',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
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

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.adminPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.adminTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.adminPrimaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.adminPrimary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpcomingTreatmentsSection(BuildContext context) {
    return Consumer<TreatmentProvider>(
      builder: (context, treat, _) {
        final upcoming = treat.upcomingTreatments
            .where((t) => t.isApproved && t.type == 'treatment')
            .take(6)
            .toList();
        return Container(
          decoration: AppTheme.adminCardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Upcoming Disease Treatments',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminUpcomingList),
                    child: Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.noUpcomingTreatmentsList,
                    style: const TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5),
                  ),
                )
              else
                ...upcoming.map((t) => _upcomingTile(context, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingFertilizationSection(BuildContext context) {
    return Consumer<TreatmentProvider>(
      builder: (context, treat, _) {
        final upcoming = treat.upcomingTreatments
            .where((t) => t.isApproved && t.type == 'fertilization')
            .take(6)
            .toList();
        return Container(
          decoration: AppTheme.adminCardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Upcoming Fertilization Tasks',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminUpcomingList),
                    child: Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text(
                    'No upcoming fertilization schedules.',
                    style: TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5),
                  ),
                )
              else
                ...upcoming.map((t) => _upcomingTile(context, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _upcomingTile(BuildContext context, TreatmentModel t) {
    return FutureBuilder<UserModel?>(
      future: _getUserName(t.userId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Farmer';
        final isTreatment = t.type == 'treatment';
        final color = isTreatment ? const Color(0xFFD97706) : const Color(0xFF0284C7);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTreatment ? Icons.medical_services_rounded : Icons.eco_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name • ${t.disease}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.adminTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(t.scheduleDate),
                      style: const TextStyle(fontSize: 11, color: AppTheme.adminTextSecondary),
                    ),
                  ],
                ),
              ),
              AdminStatusBadge.fromStatus(t.status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingApprovalSection(BuildContext context) {
    return Consumer<TreatmentProvider>(
      builder: (context, treat, _) {
        final pending = treat.pendingTreatments;
        if (pending.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'High-Priority Pending Approvals (${pending.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminPendingList),
                    child: Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...pending.take(4).map((t) => _pendingTile(context, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _pendingTile(BuildContext context, TreatmentModel t) {
    return FutureBuilder<UserModel?>(
      future: _getUserName(t.userId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Farmer';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name • ${t.disease}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.type.toUpperCase()} • Target: ${DateFormat('MMM dd, yyyy').format(t.scheduleDate)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.adminTextSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                    tooltip: 'Approve Schedule',
                    onPressed: () async {
                      await Provider.of<TreatmentProvider>(context, listen: false).approveTreatment(t.id);
                      if (context.mounted) {
                        AppFeedback.success(context, 'Schedule approved successfully');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
                    tooltip: 'Disapprove / Reject',
                    onPressed: () async {
                      await Provider.of<TreatmentProvider>(context, listen: false).disapproveTreatment(t.id);
                      if (context.mounted) {
                        AppFeedback.success(context, 'Schedule disapproved');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTreatments(BuildContext context) {
    return Consumer<TreatmentProvider>(
      builder: (context, treat, _) {
        final all = treat.treatments.where((t) => !t.archived).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recent = all.take(6).toList();
        return Container(
          decoration: AppTheme.adminCardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recent.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.noTreatmentsYet,
                    style: const TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5),
                  ),
                )
              else
                ...recent.map((t) => _recentTile(context, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _recentTile(BuildContext context, TreatmentModel t) {
    return FutureBuilder<UserModel?>(
      future: _getUserName(t.userId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Farmer';
        final isTreatment = t.type == 'treatment';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.adminBorderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTreatment ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTreatment ? Icons.medical_services_rounded : Icons.eco_rounded,
                  color: isTreatment ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name • ${t.disease}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.type.toUpperCase()} • ${DateFormat('MMM dd, yyyy').format(t.scheduleDate)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.adminTextSecondary),
                    ),
                  ],
                ),
              ),
              AdminStatusBadge.fromStatus(t.status),
              if (t.isCompleted || t.isApproved || t.status == 'cancelled') ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.archive_outlined, size: 17, color: AppTheme.adminTextMuted),
                  tooltip: 'Archive Record',
                  onPressed: () async {
                    final shouldArchive = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Archive Record'),
                        content: const Text('Archive this treatment record? You can restore it later from the archive vault.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive')),
                        ],
                      ),
                    );
                    if (shouldArchive != true || !context.mounted) return;
                    await Provider.of<TreatmentProvider>(context, listen: false).archiveTreatment(t.id);
                    if (context.mounted) {
                      AppFeedback.success(context, AppLocalizations.of(context)!.archivedSuccess);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleStatisticsCard(BuildContext context) {
    return Consumer<TreatmentProvider>(
      builder: (context, treat, _) {
        final now = DateTime.now();
        final stats = bucketTimestamps(
          treat.treatments.map((t) => t.scheduleDate),
          _period,
          now,
        );
        final labels = stats.keys.toList();
        final values = stats.values.toList();
        final isEmpty = values.every((v) => v == 0);
        final maxY = values.isEmpty ? 4.0 : (values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

        final (windowStart, windowEnd) = analyticsPeriodRange(_period, now);
        final trendTreatments = <String, List<TreatmentModel>>{
          for (final l in labels) l: <TreatmentModel>[],
        };

        for (final t in treat.treatments) {
          if (!t.scheduleDate.isBefore(windowStart) && t.scheduleDate.isBefore(windowEnd)) {
            final idx = trendIndexFor(t.scheduleDate, _period);
            if (idx >= 0 && idx < labels.length) {
              trendTreatments[labels[idx]]!.add(t);
            }
          }
        }

        for (final list in trendTreatments.values) {
          list.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
        }

        return Container(
          decoration: AppTheme.adminCardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule Workload Volume',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.adminTextPrimary),
                  ),
                  Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.adminTextSecondary),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Number of field schedules per ${_scheduleUnit(_period)}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.adminTextSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 200,
                child: treat.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : isEmpty
                        ? const Center(
                            child: Text(
                              'No field schedules recorded for this period.',
                              style: TextStyle(color: AppTheme.adminTextMuted, fontSize: 12.5),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: const Color(0xFF0F172A),
                                  tooltipRoundedRadius: 10,
                                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  tooltipMargin: 8,
                                  maxContentWidth: 280,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final idx = group.x.toInt();
                                    if (idx < 0 || idx >= labels.length) return null;
                                    final label = labels[idx];
                                    final count = values[idx];
                                    final dateRange = trendBucketDateRange(label, _period, now);
                                    final list = trendTreatments[label] ?? const <TreatmentModel>[];

                                    final children = <TextSpan>[];

                                    // 1. Period / Date Range header
                                    children.add(
                                      TextSpan(
                                        text: '$dateRange\n',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );

                                    // 2. Schedule Count description
                                    children.add(
                                      TextSpan(
                                        text: '$count field schedule${count == 1 ? '' : 's'}\n',
                                        style: const TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );

                                    // 3. Itemized Task breakdown or Empty state
                                    if (count == 0) {
                                      children.add(
                                        const TextSpan(
                                          text: '\nNo tasks scheduled for this period.',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      );
                                    } else {
                                      const maxVisible = 4;
                                      final visible = list.take(maxVisible).toList();

                                      for (final t in visible) {
                                        final isFert = t.type == 'fertilization';
                                        final title = isFert
                                            ? (t.remedy != null && t.remedy!.isNotEmpty ? t.remedy! : 'Fertilization')
                                            : (t.disease.isNotEmpty ? t.disease : 'Crop Treatment');

                                        final status = t.isCompleted ? '✓ Completed' : 'Pending';
                                        final color = isFert ? const Color(0xFF6EE7B7) : const Color(0xFF93C5FD);
                                        final dateStr = DateFormat('MMM d • h:mm a').format(t.scheduleDate);
                                        final farmerName = _userCache[t.userId]?.name;

                                        children.add(
                                          TextSpan(
                                            text: '\n• $title ($status)\n',
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                        children.add(
                                          TextSpan(
                                            text: '  Scheduled: $dateStr${farmerName != null && farmerName.isNotEmpty ? ' • Farmer: $farmerName' : ''}',
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }

                                      if (list.length > maxVisible) {
                                        final more = list.length - maxVisible;
                                        children.add(
                                          TextSpan(
                                            text: '\n+ $more more field task${more == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              color: Color(0xFFFBBF24),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    return BarTooltipItem(
                                      '',
                                      const TextStyle(),
                                      children: children,
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: AppTheme.adminBorderLight,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
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
                              barGroups: List.generate(values.length, (index) {
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[index].toDouble(),
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: AppTheme.primaryGradient,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }


  String _scheduleUnit(AnalyticsPeriod p) {
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
}

