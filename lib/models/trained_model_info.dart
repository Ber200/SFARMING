/// Metadata for a model managed through the Admin Model Trainer.
///
/// Stored in `model_versions/{key}` (full history) and mirrored into
/// `admin_settings/model` as the active pointer used by the Android app.
class TrainedModelInfo {
  final String version;
  final int timestamp;
  final List<String> classes;
  final String modelUrl;
  final String labelsUrl;
  final bool active;

  // Model-management fields.
  final String status; // ready | pending_review | approved | rejected | deployed | archived
  final double? accuracy;
  final double? validationAccuracy;
  final double? precision;
  final double? recall;
  final double? f1Score;
  final String? jobId;
  final String? rejectedReason;
  final int? modelSize;
  final int? labelsSize;
  final int? approvedAt;
  final int? deployedAt;

  const TrainedModelInfo({
    required this.version,
    required this.timestamp,
    required this.classes,
    required this.modelUrl,
    required this.labelsUrl,
    this.active = false,
    this.status = 'ready',
    this.accuracy,
    this.validationAccuracy,
    this.precision,
    this.recall,
    this.f1Score,
    this.jobId,
    this.rejectedReason,
    this.modelSize,
    this.labelsSize,
    this.approvedAt,
    this.deployedAt,
  });

  factory TrainedModelInfo.fromMap(Map<String, dynamic> map, String version) {
    return TrainedModelInfo(
      version: map['version'] as String? ?? version,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      classes: (map['classes'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      modelUrl: map['modelUrl'] as String? ?? '',
      labelsUrl: map['labelsUrl'] as String? ?? '',
      active: map['active'] as bool? ?? map['status'] == 'deployed',
      status: map['status'] as String? ?? 'ready',
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      validationAccuracy: (map['validationAccuracy'] as num?)?.toDouble(),
      precision: (map['precision'] as num?)?.toDouble(),
      recall: (map['recall'] as num?)?.toDouble(),
      f1Score: (map['f1Score'] as num?)?.toDouble(),
      jobId: map['jobId'] as String?,
      rejectedReason: map['rejectedReason'] as String?,
      modelSize: (map['modelSize'] as num?)?.toInt(),
      labelsSize: (map['labelsSize'] as num?)?.toInt(),
      approvedAt: (map['approvedAt'] as num?)?.toInt(),
      deployedAt: (map['deployedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'timestamp': timestamp,
      'classes': classes,
      'modelUrl': modelUrl,
      'labelsUrl': labelsUrl,
      'active': active,
      'status': status,
      'accuracy': accuracy,
      'validationAccuracy': validationAccuracy,
      'precision': precision,
      'recall': recall,
      'f1Score': f1Score,
      'jobId': jobId,
      'rejectedReason': rejectedReason,
      'modelSize': modelSize,
      'labelsSize': labelsSize,
      'approvedAt': approvedAt,
      'deployedAt': deployedAt,
    };
  }
}
