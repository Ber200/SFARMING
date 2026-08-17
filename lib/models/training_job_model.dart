/// A training job. The actual training runs in Google Colab; the Admin Panel
/// records the configuration here and captures the real results that Colab
/// prints (no fabricated metrics).
class TrainingJobModel {
  final String id;
  final String status; // draft | ready | training | completed | failed
  final String datasetId;
  final int epochs;
  final int batchSize;
  final double learningRate;
  final double validationSplit;

  final double? accuracy;
  final double? validationAccuracy;
  final double? loss;
  final double? validationLoss;
  final double? precision;
  final double? recall;
  final double? f1Score;
  final String? confusionMatrix;
  final String? classificationReport;
  final List<String> classes;

  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const TrainingJobModel({
    required this.id,
    required this.status,
    required this.datasetId,
    required this.epochs,
    required this.batchSize,
    required this.learningRate,
    required this.validationSplit,
    this.accuracy,
    this.validationAccuracy,
    this.loss,
    this.validationLoss,
    this.precision,
    this.recall,
    this.f1Score,
    this.confusionMatrix,
    this.classificationReport,
    this.classes = const [],
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory TrainingJobModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainingJobModel(
      id: id,
      status: map['status'] as String? ?? 'draft',
      datasetId: map['datasetId'] as String? ?? '',
      epochs: (map['epochs'] as num?)?.toInt() ?? 20,
      batchSize: (map['batchSize'] as num?)?.toInt() ?? 32,
      learningRate: (map['learningRate'] as num?)?.toDouble() ?? 0.001,
      validationSplit: (map['validationSplit'] as num?)?.toDouble() ?? 0.2,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      validationAccuracy: (map['validationAccuracy'] as num?)?.toDouble(),
      loss: (map['loss'] as num?)?.toDouble(),
      validationLoss: (map['validationLoss'] as num?)?.toDouble(),
      precision: (map['precision'] as num?)?.toDouble(),
      recall: (map['recall'] as num?)?.toDouble(),
      f1Score: (map['f1Score'] as num?)?.toDouble(),
      confusionMatrix: map['confusionMatrix'] as String?,
      classificationReport: map['classificationReport'] as String?,
      classes: (map['classes'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      completedAt: map['completedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'datasetId': datasetId,
      'epochs': epochs,
      'batchSize': batchSize,
      'learningRate': learningRate,
      'validationSplit': validationSplit,
      'accuracy': accuracy,
      'validationAccuracy': validationAccuracy,
      'loss': loss,
      'validationLoss': validationLoss,
      'precision': precision,
      'recall': recall,
      'f1Score': f1Score,
      'confusionMatrix': confusionMatrix,
      'classificationReport': classificationReport,
      'classes': classes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
    };
  }

  TrainingJobModel copyWith({
    String? status,
    double? accuracy,
    double? validationAccuracy,
    double? loss,
    double? validationLoss,
    double? precision,
    double? recall,
    double? f1Score,
    String? confusionMatrix,
    String? classificationReport,
    List<String>? classes,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return TrainingJobModel(
      id: id,
      status: status ?? this.status,
      datasetId: datasetId,
      epochs: epochs,
      batchSize: batchSize,
      learningRate: learningRate,
      validationSplit: validationSplit,
      accuracy: accuracy ?? this.accuracy,
      validationAccuracy: validationAccuracy ?? this.validationAccuracy,
      loss: loss ?? this.loss,
      validationLoss: validationLoss ?? this.validationLoss,
      precision: precision ?? this.precision,
      recall: recall ?? this.recall,
      f1Score: f1Score ?? this.f1Score,
      confusionMatrix: confusionMatrix ?? this.confusionMatrix,
      classificationReport: classificationReport ?? this.classificationReport,
      classes: classes ?? this.classes,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
