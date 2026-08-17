class TreatmentModel {
  final String id;
  final String userId;
  final String disease;
  /// Recommended remedy/medicine for the disease
  final String? remedy;
  final DateTime scheduleDate;
  /// 'pending' = farmer submitted, awaiting admin approval
  /// 'approved' = admin approved, ready for treatment
  /// 'completed' = farmer marked done with photo proof
  /// 'cancelled' = admin disapproved or rescheduled
  final String status;
  final String? notes;
  final String type; // 'treatment' or 'fertilization'
  final DateTime createdAt;
  /// URL of photo proof when farmer marks treatment as completed
  final String? photoProofUrl;
  /// GPS coordinates where the treatment/fertilization was performed.
  final double? latitude;
  final double? longitude;
  /// When the farmer actually completed the task (with photo proof).
  final DateTime? completedAt;
  /// True when archived (no delete, archive only)
  final bool archived;
  final bool synced;

  TreatmentModel({
    required this.id,
    required this.userId,
    required this.disease,
    this.remedy,
    required this.scheduleDate,
    required this.status,
    this.notes,
    required this.type,
    required this.createdAt,
    this.photoProofUrl,
    this.latitude,
    this.longitude,
    this.completedAt,
    this.archived = false,
    this.synced = true,
  });

  factory TreatmentModel.fromMap(Map<String, dynamic> map, String id) {
    return TreatmentModel(
      id: id,
      userId: map['userId'] ?? '',
      disease: map['disease'] ?? '',
      remedy: map['remedy'],
      scheduleDate: map['scheduleDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduleDate'])
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      type: map['type'] ?? 'treatment',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      photoProofUrl: map['photoProofUrl'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      archived: map['archived'] as bool? ?? false,
      synced: map['synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'disease': disease,
      'remedy': remedy,
      'scheduleDate': scheduleDate.millisecondsSinceEpoch,
      'status': status,
      'notes': notes,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'photoProofUrl': photoProofUrl,
      'latitude': latitude,
      'longitude': longitude,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'archived': archived,
      'synced': synced,
    };
  }

  TreatmentModel copyWith({
    String? id,
    String? userId,
    String? disease,
    String? remedy,
    DateTime? scheduleDate,
    String? status,
    String? notes,
    String? type,
    DateTime? createdAt,
    String? photoProofUrl,
    double? latitude,
    double? longitude,
    DateTime? completedAt,
    bool? archived,
    bool? synced,
  }) {
    return TreatmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      disease: disease ?? this.disease,
      remedy: remedy ?? this.remedy,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      photoProofUrl: photoProofUrl ?? this.photoProofUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      completedAt: completedAt ?? this.completedAt,
      archived: archived ?? this.archived,
      synced: synced ?? this.synced,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  String get cropName => 'Rice Field';
}
