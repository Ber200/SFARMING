import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/treatment_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/treatment_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/loading_skeletons.dart';

/// Admin calendar: daily/weekly/monthly views, reschedule/cancel/complete treatments.
class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _filterStatus;
  String? _filterType;
  final FirebaseService _firebase = FirebaseService();
  final Map<String, UserModel?> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Provider.of<TreatmentProvider>(context, listen: false).loadTreatments('');
  }

  Future<UserModel?> _getUserName(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    final user = await _firebase.getUserData(userId);
    _userCache[userId] = user;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Field Operations & Treatment Calendar',
      subtitle: 'Schedule timeline, farmer treatment approvals & field intervention tracking',
      activeRoute: AppRoutes.adminCalendar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter & Control Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.adminCardDecoration(),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  const Icon(Icons.tune_rounded, color: AppTheme.adminPrimary, size: 18),
                  const Text(
                    'Filters:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminTextPrimary, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.adminSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.adminBorder),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      hint: const Text('All Statuses', style: TextStyle(fontSize: 12.5)),
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Statuses', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'pending', child: Text('Pending Approval', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.adminSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.adminBorder),
                    ),
                    child: DropdownButton<String>(
                      value: _filterType,
                      hint: const Text('All Types', style: TextStyle(fontSize: 12.5)),
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Task Types', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'treatment', child: Text('Disease Treatment', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'fertilization', child: Text('Fertilization Task', style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: (v) => setState(() => _filterType = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _viewButton('Week View', CalendarFormat.week),
                  _viewButton('2 Weeks', CalendarFormat.twoWeeks),
                  _viewButton('Month View', CalendarFormat.month),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendar Container Card
            Container(
              decoration: AppTheme.adminCardDecoration(),
              padding: const EdgeInsets.all(18),
              child: Consumer<TreatmentProvider>(
                builder: (context, tp, _) {
                  return TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    calendarFormat: _calendarFormat,
                    eventLoader: (d) => _filter(tp.getTreatmentsForDate(d)),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: (d, f) => setState(() {
                      _selectedDay = d;
                      _focusedDay = f;
                    }),
                    onFormatChanged: (f) => setState(() => _calendarFormat = f),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.adminPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminPrimary),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.adminPrimary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        color: AppTheme.adminTextPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // Selected Date Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 18, color: AppTheme.adminPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Schedules for ${DateFormat('MMMM dd, yyyy').format(_selectedDay)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.adminTextPrimary,
                      ),
                    ),
                  ],
                ),
                Consumer<TreatmentProvider>(
                  builder: (context, tp, _) {
                    final count = _filter(tp.getTreatmentsForDate(_selectedDay)).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count tasks',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.adminPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of treatments for selected date
            Consumer<TreatmentProvider>(
              builder: (context, tp, _) {
                final list = _filter(tp.getTreatmentsForDate(_selectedDay));
                if (tp.isLoading && tp.treatments.isEmpty) {
                  return const ListCardSkeleton(count: 3);
                }
                if (list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.adminCardDecoration(),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 36, color: AppTheme.adminTextMuted),
                          const SizedBox(height: 8),
                          const Text(
                            'No treatments or fertilizations scheduled for this date.',
                            style: TextStyle(color: AppTheme.adminTextSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return _TreatmentCard(
                      treatment: t,
                      getUserName: _getUserName,
                      onReschedule: () => _reschedule(t),
                      onApprove: () => _approve(t.id),
                      onDisapprove: () => _disapprove(t.id),
                      onArchive: () => _archive(t.id),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<TreatmentModel> _filter(List<TreatmentModel> list) {
    var r = list;
    if (_filterStatus != null) {
      r = r.where((t) => t.status == _filterStatus).toList();
    }
    if (_filterType != null) {
      r = r.where((t) => t.type == _filterType).toList();
    }
    return r;
  }

  Widget _viewButton(String label, CalendarFormat format) {
    final selected = _calendarFormat == format;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedColor: AppTheme.adminPrimaryLight,
      labelStyle: TextStyle(color: selected ? AppTheme.adminPrimary : AppTheme.adminTextSecondary),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppTheme.adminPrimary : AppTheme.adminBorder),
      onSelected: (_) => setState(() => _calendarFormat = format),
    );
  }

  Future<void> _approve(String id) async {
    try {
      await Provider.of<TreatmentProvider>(context, listen: false).approveTreatment(id);
      if (mounted) {
        AppFeedback.success(context, 'Schedule approved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _disapprove(String id) async {
    try {
      await Provider.of<TreatmentProvider>(context, listen: false).disapproveTreatment(id);
      if (mounted) {
        AppFeedback.success(context, 'Schedule disapproved');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _archive(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive Treatment Record?'),
        content: const Text(
          'This schedule will be archived into the vault. '
          'You can restore it anytime from the Archive screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await Provider.of<TreatmentProvider>(context, listen: false).archiveTreatment(id);
      if (mounted) {
        AppFeedback.success(context, 'Schedule archived successfully');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _reschedule(TreatmentModel t) async {
    final date = await showDatePicker(
      context: context,
      initialDate: t.scheduleDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(t.scheduleDate),
    );
    final newSchedule = time != null
        ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
        : DateTime(date.year, date.month, date.day, t.scheduleDate.hour, t.scheduleDate.minute);
    try {
      await _firebase.updateTreatmentSchedule(t.id, newSchedule);
      if (mounted) {
        Provider.of<TreatmentProvider>(context, listen: false).loadTreatments('');
        AppFeedback.success(context, 'Schedule updated successfully');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    }
  }
}

class _TreatmentCard extends StatelessWidget {
  final TreatmentModel treatment;
  final Future<UserModel?> Function(String) getUserName;
  final VoidCallback onReschedule;
  final VoidCallback onApprove;
  final VoidCallback onDisapprove;
  final VoidCallback onArchive;

  const _TreatmentCard({
    required this.treatment,
    required this.getUserName,
    required this.onReschedule,
    required this.onApprove,
    required this.onDisapprove,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isTreatment = treatment.type == 'treatment';

    return FutureBuilder<UserModel?>(
      future: getUserName(treatment.userId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Farmer';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.adminCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.adminPrimaryLight,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: const TextStyle(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.adminTextPrimary),
                      ),
                    ],
                  ),
                  AdminStatusBadge.fromStatus(treatment.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isTreatment ? Icons.medical_services_rounded : Icons.eco_rounded,
                    size: 15,
                    color: isTreatment ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${treatment.type.toUpperCase()}: ${treatment.disease}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.adminTextPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.adminTextMuted),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(treatment.scheduleDate),
                    style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary),
                  ),
                ],
              ),
              if (treatment.notes != null && treatment.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Notes: ${treatment.notes}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.adminTextSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (treatment.status == 'pending') ...[
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: const Text('Approve', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDisapprove,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.cancel_rounded, size: 14),
                      label: const Text('Disapprove', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onReschedule,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                      label: const Text('Reschedule', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  if (treatment.status == 'approved' ||
                      treatment.status == 'completed' ||
                      treatment.status == 'cancelled') ...[
                    OutlinedButton.icon(
                      onPressed: onArchive,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.archive_rounded, size: 14),
                      label: const Text('Archive', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

