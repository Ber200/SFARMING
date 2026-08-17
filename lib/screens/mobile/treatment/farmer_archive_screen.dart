import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/treatment_provider.dart';
import '../../../models/treatment_model.dart';
import '../../../core/routes/app_routes.dart';

enum FarmerArchiveSortBy { date, disease, treatment }

/// Farmer Archive: view own archived treatments with search, sort, filter.
class FarmerArchiveScreen extends StatefulWidget {
  const FarmerArchiveScreen({super.key});

  @override
  State<FarmerArchiveScreen> createState() => _FarmerArchiveScreenState();
}

class _FarmerArchiveScreenState extends State<FarmerArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  FarmerArchiveSortBy _sortBy = FarmerArchiveSortBy.date;
  bool _sortAscending = false;
  String? _filterTreatment;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TreatmentModel> _filterAndSort(List<TreatmentModel> list) {
    var result = list;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((t) => t.disease.toLowerCase().contains(q))
          .toList();
    }
    if (_filterTreatment != null && _filterTreatment!.isNotEmpty) {
      result = result.where((t) => t.type == _filterTreatment).toList();
    }
    result = List<TreatmentModel>.from(result);
    switch (_sortBy) {
      case FarmerArchiveSortBy.date:
        result.sort((a, b) => _sortAscending
            ? a.scheduleDate.compareTo(b.scheduleDate)
            : b.scheduleDate.compareTo(a.scheduleDate));
        break;
      case FarmerArchiveSortBy.disease:
        result.sort((a, b) {
          final cmp = a.disease.compareTo(b.disease);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case FarmerArchiveSortBy.treatment:
        result.sort((a, b) {
          final cmp = a.type.compareTo(b.type);
          return _sortAscending ? cmp : -cmp;
        });
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(AppLocalizations.of(context)!.archivedRecords),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context),
          Expanded(
            child: Consumer2<AuthProvider, TreatmentProvider>(
              builder: (context, auth, tp, _) {
                final userId = auth.currentUser?.id ?? '';
                if (userId.isEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!.pleaseSignIn));
                }

                final archived = tp.archivedTreatments
                    .where((t) => t.userId == userId)
                    .toList();
                final filtered = _filterAndSort(archived);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.trim().isNotEmpty
                                ? AppLocalizations.of(context)!.noMatchingRecords
                                : AppLocalizations.of(context)!.noArchivedRecords,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.archivedTreatmentsHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.treatmentCalendar),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(AppLocalizations.of(context)!.viewSchedule),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      Provider.of<TreatmentProvider>(context, listen: false)
                          .loadTreatments(userId),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _ArchiveCard(treatment: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchByDisease,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sort, size: 20),
              const SizedBox(width: 8),
              DropdownButton<FarmerArchiveSortBy>(
                value: _sortBy,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                      value: FarmerArchiveSortBy.date,
                      child: Text(AppLocalizations.of(context)!.date)),
                  DropdownMenuItem(
                      value: FarmerArchiveSortBy.disease,
                      child: Text(AppLocalizations.of(context)!.disease)),
                  DropdownMenuItem(
                      value: FarmerArchiveSortBy.treatment,
                      child: Text(AppLocalizations.of(context)!.treatment)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortBy = v);
                },
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _sortAscending = !_sortAscending),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _filterTreatment,
                hint: Text(AppLocalizations.of(context)!.filter),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(AppLocalizations.of(context)!.all)),
                  DropdownMenuItem(
                      value: 'treatment',
                      child: Text(AppLocalizations.of(context)!.treatment)),
                  DropdownMenuItem(
                      value: 'fertilization',
                      child: Text(AppLocalizations.of(context)!.fertilization)),
                ],
                onChanged: (v) => setState(() => _filterTreatment = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final TreatmentModel treatment;

  const _ArchiveCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: treatment.type == 'treatment'
              ? Colors.orange.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          child: Icon(
            treatment.type == 'treatment'
                ? Icons.medical_services
                : Icons.eco,
            color: treatment.type == 'treatment' ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(
          treatment.disease,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${treatment.type} • ${treatment.status}'),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(treatment.scheduleDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (treatment.remedy != null && treatment.remedy!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  treatment.remedy!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(treatment.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            treatment.status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _statusColor(treatment.status),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
