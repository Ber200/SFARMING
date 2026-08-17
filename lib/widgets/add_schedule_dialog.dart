import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../models/disease_info_model.dart';
import '../models/treatment_model.dart';
import '../models/user_model.dart';
import '../providers/treatment_provider.dart';
import '../services/firebase_service.dart';
import 'app_feedback.dart';

/// Shared "Add Schedule" dialog used by the admin sidebar and dashboard.
/// Optionally refreshes the [TreatmentProvider] and runs [onComplete] after
/// a schedule is created.
Future<void> showAddScheduleDialog(
  BuildContext context, {
  VoidCallback? onComplete,
}) async {
  String? disease;
  String? remedy;
  String type = 'treatment';
  DateTime scheduleDate = DateTime.now();
  final notesController = TextEditingController();
  String assignMode = 'all';
  List<String> selectedFarmerIds = [];
  late Future<List<UserModel>> farmersFuture;

  final firebase = FirebaseService();

  farmersFuture =
      firebase.getAllUsers().first.then((users) => users.where((u) => u.isFarmer).toList());

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppLocalizations.of(context)!.addTreatmentSchedule),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.assignTo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: assignMode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'all',
                          child: Text(AppLocalizations.of(context)!.allFarmers)),
                      DropdownMenuItem(
                          value: 'specific',
                          child: Text(AppLocalizations.of(context)!.specificFarmer)),
                    ],
                    onChanged: (v) => setDialogState(() {
                      assignMode = v ?? assignMode;
                      if (assignMode == 'all') selectedFarmerIds = [];
                    }),
                  ),
                  if (assignMode == 'specific') ...[
                    const SizedBox(height: 16),
                    FutureBuilder<List<UserModel>>(
                      future: farmersFuture,
                      builder: (c, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final list = snap.data!.where((u) => u.isFarmer).toList();
                        if (list.isEmpty) {
                          return Text(
                              AppLocalizations.of(context)!.noFarmersRegistered);
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedFarmerIds.isEmpty ? null : selectedFarmerIds.first,
                          decoration: const InputDecoration(labelText: 'Farmer'),
                          items: list.map((f) => DropdownMenuItem(
                            value: f.id,
                            child: Text('${f.name} (${f.email})'),
                          )).toList(),
                          onChanged: (v) => setDialogState(() {
                            selectedFarmerIds = v != null ? [v] : [];
                          }),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      DropdownMenuItem(
                          value: 'treatment',
                          child: Text(AppLocalizations.of(context)!.treatment)),
                      DropdownMenuItem(
                          value: 'fertilization',
                          child: Text(AppLocalizations.of(context)!.fertilization)),
                    ],
                    onChanged: (v) => setDialogState(() {
                      type = v ?? type;
                      if (type == 'fertilization') {
                        disease = 'Fertilization';
                        remedy = null;
                      } else if (disease == 'Fertilization') {
                        final diseases = DiseaseInfoModel.getAllDiseasesForTreatment();
                        disease = diseases.isNotEmpty ? diseases.first.name : null;
                        remedy = diseases.isNotEmpty
                            ? DiseaseInfoModel.getDiseaseInfo(disease ?? '')?.treatmentProtocol
                            : null;
                      }
                    }),
                  ),
                  if (type == 'treatment') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: disease,
                      decoration: const InputDecoration(labelText: 'Disease'),
                      items: DiseaseInfoModel.getAllDiseasesForTreatment()
                          .map((d) => DropdownMenuItem(
                                value: d.name,
                                child: Text(d.name),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          disease = v;
                          remedy = DiseaseInfoModel.getDiseaseInfo(v ?? '')?.treatmentProtocol;
                        });
                      },
                    ),
                  ],
                  if (type == 'treatment' && remedy != null && remedy!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              AppLocalizations.of(context)!.recommendedRemedy,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(remedy!, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.dateTime),
                    subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(scheduleDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: scheduleDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(scheduleDate),
                        );
                        if (time != null) {
                          setDialogState(() {
                            scheduleDate = DateTime(
                              date.year, date.month, date.day,
                              time.hour, time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: (type == 'fertilization' || (disease != null && disease!.isNotEmpty))
                    ? ((assignMode == 'specific' && selectedFarmerIds.isEmpty)
                        ? null
                        : () => Navigator.pop(ctx, true))
                    : null,
                child: Text(assignMode == 'all'
                    ? AppLocalizations.of(context)!.addForAllFarmers
                    : AppLocalizations.of(context)!.assignToFarmer),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true) return;

  final diseaseValue = type == 'fertilization' ? 'Fertilization' : (disease ?? '');
  if (diseaseValue.isEmpty) return;

  final template = TreatmentModel(
    id: '',
    userId: '',
    disease: diseaseValue,
    remedy: remedy,
    scheduleDate: scheduleDate,
    status: 'approved',
    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    type: type,
    createdAt: DateTime.now(),
    synced: true,
  );

  try {
    final targetIds = assignMode == 'all' ? <String>[] : selectedFarmerIds;
    await firebase.addTreatmentForFarmers(template, targetIds);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assignMode == 'all'
                ? AppLocalizations.of(context)!.scheduleAddedAll
                : AppLocalizations.of(context)!
                    .scheduleAssignedCount(targetIds.length),
          ),
        ),
      );
    }
    if (context.mounted) {
      Provider.of<TreatmentProvider>(context, listen: false).loadTreatments('');
    }
    onComplete?.call();
  } catch (e) {
    if (context.mounted) {
      AppFeedback.error(context, 'Error: $e');
    }
  }
  notesController.dispose();
}
