/// A rice leaf disease that can be included in a training dataset and model.
class DiseaseModel {
  final String id;
  final String name;
  final String description;
  final String treatment;
  final String prevention;
  final String status;
  final int sortOrder;
  final DateTime createdAt;

  const DiseaseModel({
    required this.id,
    required this.name,
    this.description = '',
    this.treatment = '',
    this.prevention = '',
    this.status = 'active',
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory DiseaseModel.fromMap(Map<String, dynamic> map, String id) {
    return DiseaseModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      treatment: map['treatment'] as String? ?? '',
      prevention: map['prevention'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'treatment': treatment,
      'prevention': prevention,
      'status': status,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
