import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/treatment_model.dart';
import '../providers/treatment_provider.dart';

class TreatmentDetailsDialog extends StatelessWidget {
  final TreatmentModel treatment;
  final String farmerName;
  final bool canDelete;

  const TreatmentDetailsDialog({
    super.key,
    required this.treatment,
    required this.farmerName,
    this.canDelete = false,
  });

  static Future<void> show(
    BuildContext context,
    TreatmentModel treatment,
    String farmerName, {
    bool canDelete = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => TreatmentDetailsDialog(
        treatment: treatment,
        farmerName: farmerName,
        canDelete: canDelete,
      ),
    );
  }

  Widget _alertInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isFertilization = treatment.type == 'fertilization';
    final completedLabel = treatment.completedAt != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(treatment.completedAt!)
        : '—';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Icon(isFertilization ? Icons.grass : Icons.healing, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFertilization
                  ? 'Fertilization Completed'
                  : 'Treatment: ${treatment.disease.isEmpty ? 'Completed' : treatment.disease}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (treatment.photoProofUrl != null &&
                  treatment.photoProofUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    treatment.photoProofUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Photo preview unavailable',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _alertInfoRow('Farmer', farmerName),
              _alertInfoRow('Type', isFertilization ? 'Fertilization' : 'Treatment'),
              if (!isFertilization) _alertInfoRow('Disease', treatment.disease),
              if (treatment.remedy != null && treatment.remedy!.isNotEmpty)
                _alertInfoRow('Remedy', treatment.remedy!),
              _alertInfoRow('Completed', completedLabel),
              const Divider(height: 28),
              const Row(
                children: [
                  Icon(Icons.pin_drop, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Work Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Latitude:  ${treatment.latitude!.toStringAsFixed(6)}\n'
                  'Longitude: ${treatment.longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (canDelete)
          Consumer<TreatmentProvider>(
            builder: (context, tp, _) => OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove Pin'),
                    content: const Text(
                        'This permanently deletes the treatment record and its map pin. This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove Pin'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await tp.removeTreatment(treatment.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Remove Pin'),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
