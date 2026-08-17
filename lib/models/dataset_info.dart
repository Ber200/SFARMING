/// Per-disease training dataset stored under `datasets/{diseaseKey}`.
class DatasetInfo {
  final String diseaseId;
  final int imageCount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// fileName -> download URL for every uploaded image.
  final Map<String, String> images;

  const DatasetInfo({
    required this.diseaseId,
    this.imageCount = 0,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.images = const {},
  });

  factory DatasetInfo.fromMap(Map<String, dynamic> map, String diseaseId) {
    final images = <String, String>{};
    final raw = map['images'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key != null && value != null) {
          images[key.toString()] = value.toString();
        }
      });
    }
    return DatasetInfo(
      diseaseId: diseaseId,
      imageCount: (map['imageCount'] as num?)?.toInt() ?? images.length,
      status: map['status'] as String? ?? 'draft',
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      images: images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diseaseId': diseaseId,
      'imageCount': imageCount,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'images': images,
    };
  }

  DatasetInfo copyWith({
    int? imageCount,
    String? status,
    DateTime? updatedAt,
    Map<String, String>? images,
  }) {
    return DatasetInfo(
      diseaseId: diseaseId,
      imageCount: imageCount ?? this.imageCount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }
}
