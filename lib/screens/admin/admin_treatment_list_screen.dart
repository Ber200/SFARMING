import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/treatment_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/treatment_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/app_feedback.dart';

enum TreatmentListMode { pending, upcoming }

/// Full list of pending or upcoming treatments for admin.
class AdminTreatmentListScreen extends StatefulWidget {
  final TreatmentListMode mode;

  const AdminTreatmentListScreen({super.key, required this.mode});

  @override
  State<AdminTreatmentListScreen> createState() => _AdminTreatmentListScreenState();
}

class _AdminTreatmentListScreenState extends State<AdminTreatmentListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.mode == TreatmentListMode.pending;
    final title = isPending ? 'Pending Field Approvals' : 'Scheduled Field Treatments';
    final subtitle = isPending
        ? 'High-priority treatment and fertilization tasks awaiting agronomist review'
        : 'Confirmed and scheduled agronomic treatments across registered farms';

    return AdminScaffold(
      title: title,
      subtitle: subtitle,
      activeRoute: isPending ? AppRoutes.adminPendingList : AppRoutes.adminUpcomingList,
      body: Consumer<TreatmentProvider>(
        builder: (context, tp, _) {
          final allList = isPending ? tp.pendingTreatments : tp.upcomingTreatments;
          if (tp.isLoading && allList.isEmpty) {
            return const ListCardSkeleton(count: 6);
          }
          if (tp.errorMessage != null && allList.isEmpty) {
            return _TreatmentLoadError(
              message: tp.errorMessage!,
              onRetry: () => tp.loadTreatments(''),
            );
          }

          final filteredList = allList.where((t) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return t.disease.toLowerCase().contains(q) ||
                t.type.toLowerCase().contains(q) ||
                (t.notes?.toLowerCase().contains(q) ?? false);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => tp.loadTreatments(''),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Metric Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.adminCardDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.adminSurfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.adminBorder),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: 'Search by disease, task type, or notes...',
                                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.adminTextMuted),
                                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.adminTextSecondary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(bottom: 12),
                                isDense: true,
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 14),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.adminPrimaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filteredList.length} Tasks',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.adminPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filteredList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: AppTheme.adminCardDecoration(),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              isPending ? Icons.pending_actions_rounded : Icons.schedule_rounded,
                              size: 48,
                              color: AppTheme.adminTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isPending
                                  ? 'No pending approval tasks at this time.'
                                  : 'No upcoming treatments match your search.',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminTextSecondary, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, i) => _TreatmentListTile(
                        treatment: filteredList[i],
                        mode: widget.mode,
                        getUserName: (id) => FirebaseService().getUserData(id),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TreatmentListTile extends StatelessWidget {
  final TreatmentModel treatment;
  final TreatmentListMode mode;
  final Future<UserModel?> Function(String) getUserName;

  const _TreatmentListTile({
    required this.treatment,
    required this.mode,
    required this.getUserName,
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
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.adminCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTreatment ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isTreatment ? Icons.medical_services_rounded : Icons.eco_rounded,
                      color: isTreatment ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.adminTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${treatment.type.toUpperCase()} • ${treatment.disease}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  AdminStatusBadge.fromStatus(treatment.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.adminBorderLight),
              const SizedBox(height: 10),
              _DetailRow(
                Icons.event_rounded,
                'Scheduled Date',
                DateFormat('MMM dd, yyyy • HH:mm').format(treatment.scheduleDate),
              ),
              if (treatment.remedy != null && treatment.remedy!.isNotEmpty)
                _DetailRow(Icons.healing_rounded, 'Prescribed Remedy', treatment.remedy!),
              if (treatment.notes != null && treatment.notes!.isNotEmpty)
                _DetailRow(Icons.note_alt_outlined, 'Field Notes', treatment.notes!),
              if (mode == TreatmentListMode.pending) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Provider.of<TreatmentProvider>(context, listen: false).disapproveTreatment(treatment.id);
                        if (context.mounted) {
                          AppFeedback.success(context, 'Schedule rejected');
                        }
                      },
                      icon: const Icon(Icons.cancel_rounded, size: 14),
                      label: const Text('Disapprove', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Provider.of<TreatmentProvider>(context, listen: false).approveTreatment(treatment.id);
                        if (context.mounted) {
                          AppFeedback.success(context, 'Schedule approved successfully');
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: const Text('Approve Schedule', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.adminTextMuted),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: AppTheme.adminTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.adminTextPrimary)),
          ),
        ],
      ),
    );
  }
}

class _TreatmentLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TreatmentLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppTheme.adminTextMuted),
            const SizedBox(height: 14),
            const Text(
              'Could not load treatment schedules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.adminTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.adminTextSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

