import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../models/treatment_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_drawer.dart';

class TreatmentCalendarScreen extends StatefulWidget {
  /// When set (deep link from a notification), the calendar auto-selects the
  /// day of the matching treatment and outlines its card. Missing records
  /// degrade gracefully to a normal calendar.
  final String? highlightTreatmentId;

  const TreatmentCalendarScreen({super.key, this.highlightTreatmentId});

  @override
  State<TreatmentCalendarScreen> createState() =>
      _TreatmentCalendarScreenState();
}

class _TreatmentCalendarScreenState extends State<TreatmentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _highlightId;
  bool _highlightApplied = false;

  @override
  void initState() {
    super.initState();
    _highlightId = widget.highlightTreatmentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTreatments();
    });
  }

  void _loadTreatments() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      Provider.of<TreatmentProvider>(context, listen: false)
          .loadTreatments(userId);
    }
  }

  /// Watches the provider and, when the highlighted treatment becomes
  /// available, selects its day once. Runs inside the tree (never mutates
  /// state during build) so deep-linked notifications land on the exact day.
  Widget _applyHighlightWatcher(
      BuildContext context, TreatmentProvider provider, Widget? child) {
    if (_highlightId == null || _highlightApplied) {
      return const SizedBox.shrink();
    }
    if (provider.isLoading) {
      return const SizedBox.shrink();
    }
    _highlightApplied = true;
    TreatmentModel? match;
    for (final t in provider.treatments) {
      if (t.id == _highlightId) {
        match = t;
        break;
      }
    }
    if (match != null) {
      final day = match.scheduleDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDay = day;
            _focusedDay = day;
          });
        }
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _navigateToAddTreatment() async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.addTreatment,
    );
    if (mounted && result == true) {
      _loadTreatments();
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved – Ready';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.treatmentSchedule),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.farmerArchive),
            tooltip: AppLocalizations.of(context)!.archivedRecordsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
            tooltip: AppLocalizations.of(context)!.returnHome,
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.treatmentCalendar),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddTreatment,
        backgroundColor: AppTheme.brandPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Treatment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Consumer<TreatmentProvider>(
            builder: _applyHighlightWatcher,
          ),
          // ── Calendar Container ──
          Consumer<TreatmentProvider>(
            builder: (context, treatmentProvider, _) {
              if (treatmentProvider.isLoading && treatmentProvider.treatments.isEmpty) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: AppTheme.farmCardDecoration(),
                child: TableCalendar<TreatmentModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  enabledDayPredicate: (day) {
                    final d = DateTime(day.year, day.month, day.day);
                    return !d.isBefore(today);
                  },
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) =>
                      treatmentProvider.getTreatmentsForDate(day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: AppTheme.brandPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    titleTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                ),
              );
            },
          ),

          // ── Selected Date Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(_selectedDay),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPrimary,
                      ),
                ),
                Consumer<TreatmentProvider>(
                  builder: (context, provider, _) {
                    final count = provider.getTreatmentsForDate(_selectedDay).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count tasks',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Treatment List ──
          Expanded(
            child: Consumer<TreatmentProvider>(
              builder: (context, treatmentProvider, _) {
                final treatments =
                    treatmentProvider.getTreatmentsForDate(_selectedDay);

                if (treatmentProvider.isLoading &&
                    treatmentProvider.treatments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (treatments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppLocalizations.of(context)!.noTreatmentsScheduled(
                                DateFormat('MMM dd, yyyy').format(_selectedDay)),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: treatments.length,
                  itemBuilder: (context, index) {
                    final treatment = treatments[index];
                    return _buildTreatmentCard(
                      context,
                      treatment,
                      treatmentProvider,
                      highlightId: _highlightId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(
    BuildContext context,
    TreatmentModel treatment,
    TreatmentProvider provider, {
    String? highlightId,
  }) {
    final statusColor = _statusColor(treatment.status);
    final isHighlighted = highlightId != null && treatment.id == highlightId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.farmCardDecoration(),
      foregroundDecoration: isHighlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.brandPrimary, width: 2.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (treatment.type == 'treatment' ? Colors.orange : Colors.blue)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                treatment.type == 'treatment' ? Icons.medical_services_rounded : Icons.eco_rounded,
                color: treatment.type == 'treatment' ? Colors.orange.shade800 : Colors.blue.shade800,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          treatment.disease,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(treatment.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(treatment.scheduleDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.category_outlined, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        treatment.type,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (treatment.notes != null && treatment.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: ${treatment.notes}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (treatment.remedy != null && treatment.remedy!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Remedy: ${treatment.remedy}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.brandPrimary, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            if (treatment.isApproved) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                tooltip: 'Complete Treatment',
                onPressed: () async {
                  final result = await Navigator.of(context).pushNamed(
                    AppRoutes.completeTreatmentPhoto,
                    arguments: treatment,
                  );
                  if (context.mounted && result == true) {
                    _loadTreatments();
                  }
                },
              ),
            ] else if (treatment.isCompleted) ...[
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: Colors.grey),
                tooltip: 'Archive',
                onPressed: () =>
                    _confirmArchiveTreatment(context, treatment, provider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade700;
      case 'approved':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  Future<void> _confirmArchiveTreatment(
    BuildContext context,
    TreatmentModel treatment,
    TreatmentProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.archiveConfirmTitle),
          content: Text(
            l10n.archiveConfirmMessage(treatment.type, treatment.disease),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.archive),
            ),
          ],
        );
      },
    );

    if (ok == true && context.mounted) {
      final success = await provider.archiveTreatment(treatment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.archivedSuccess
                  : provider.errorMessage ??
                      AppLocalizations.of(context)!.failedToArchive,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        _loadTreatments();
      }
    }
  }
}
