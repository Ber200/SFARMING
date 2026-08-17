import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/detection_model.dart';
import '../models/disease_info_model.dart';
import '../providers/detection_provider.dart';
import '../services/photo_download_service.dart';

class DetectionDetailsDialog extends StatelessWidget {
  final DetectionModel detection;
  final String farmerName;
  final bool canDelete;

  const DetectionDetailsDialog({
    super.key,
    required this.detection,
    required this.farmerName,
    this.canDelete = false,
  });

  static Future<void> show(
    BuildContext context,
    DetectionModel detection,
    String farmerName, {
    bool canDelete = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => DetectionDetailsDialog(
        detection: detection,
        farmerName: farmerName,
        canDelete: canDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = DiseaseInfoModel.getDiseaseInfo(detection.disease);
    final isArchived = detection.isArchived;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Expanded(
            child: Text(
              detection.disease.isEmpty ? 'Detection Details' : detection.disease,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isArchived ? Colors.grey.shade200 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isArchived ? Colors.grey.shade400 : Colors.green.shade300,
              ),
            ),
            child: Text(
              isArchived ? 'Archived' : 'Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isArchived ? Colors.grey.shade700 : Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (detection.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    detection.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image preview unavailable', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.person, 'Farmer Name', farmerName),
              _buildInfoRow(Icons.badge_outlined, 'Farmer ID', detection.userId.isEmpty ? 'N/A' : detection.userId),
              _buildInfoRow(Icons.eco_outlined, 'Crop Type', detection.crop),
              _buildInfoRow(
                Icons.analytics_outlined,
                'Confidence Score',
                '${(detection.confidence * 100).toStringAsFixed(1)}%',
                valueColor: Colors.green.shade700,
                isBold: true,
              ),
              _buildInfoRow(
                Icons.task_alt_rounded,
                'Detection Status',
                detection.status,
                valueColor: Colors.blue.shade700,
                isBold: true,
              ),
              _buildInfoRow(Icons.calendar_today, 'Scan Date & Time',
                  DateFormat('MMM dd, yyyy • HH:mm').format(detection.timestamp)),
              _buildInfoRow(
                detection.isInsideFarm ? Icons.location_on : Icons.wrong_location,
                'Farm Location Status',
                detection.locationStatus,
              ),
              if (detection.latitude != null && detection.longitude != null)
                _buildInfoRow(
                  Icons.pin_drop_outlined,
                  'Coordinates',
                  '${detection.latitude!.toStringAsFixed(6)}, ${detection.longitude!.toStringAsFixed(6)}',
                ),
              if (detection.notes != null && detection.notes!.isNotEmpty)
                _buildInfoRow(Icons.note_outlined, 'Notes', detection.notes!),

              const Divider(height: 28),

              if (info != null) ...[
                _sectionHeader('Disease Description'),
                Text(info.description, style: TextStyle(color: Colors.grey[800], height: 1.3)),
                const SizedBox(height: 14),
                _sectionHeader('Symptoms'),
                ...info.symptoms.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(s, style: TextStyle(color: Colors.grey[800]))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _sectionHeader('Treatment Protocol'),
                Text(info.treatmentProtocol, style: TextStyle(color: Colors.grey[800], height: 1.3)),
              ] else ...[
                const Text(
                  'No additional disease info database record found.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                PhotoDownloadService.downloadPhoto(
                  context: context,
                  imageUrl: detection.imageUrl,
                  fileName: 'detection_${detection.disease.replaceAll(' ', '_')}_${detection.id}.jpg',
                );
              },
              icon: const Icon(Icons.image, size: 16),
              label: const Text('Download Image'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                PhotoDownloadService.downloadDetectionReport(
                  context: context,
                  detection: detection,
                  farmerName: farmerName,
                );
              },
              icon: const Icon(Icons.description, size: 16),
              label: const Text('Download Report'),
            ),
            Consumer<DetectionProvider>(
              builder: (context, dp, _) => ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(detection.isArchived ? 'Restore Detection' : 'Archive Detection'),
                      content: Text(
                        detection.isArchived
                            ? 'Move this detection record back to active list?'
                            : 'Move this detection record to archive?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(detection.isArchived ? 'Restore' : 'Archive'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    if (detection.isArchived) {
                      await dp.unarchiveDetection(detection.id);
                    } else {
                      await dp.archiveDetection(detection.id);
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: Icon(detection.isArchived ? Icons.unarchive : Icons.archive, size: 16),
                label: Text(detection.isArchived ? 'Restore' : 'Archive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: detection.isArchived ? Colors.blue : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (canDelete)
              Consumer<DetectionProvider>(
                builder: (context, dp, _) => OutlinedButton.icon(
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
                            'This permanently deletes the detection record and its map pin. This cannot be undone.'),
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
                      await dp.deleteDetection(detection.id);
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
        ),
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
      );

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? Colors.black87,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
}
