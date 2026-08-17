class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'farmer' or 'admin'
  final String? farmLocation;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.farmLocation,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'farmer',
      farmLocation: map['farmLocation'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'farmLocation': farmLocation,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isFarmer => role == 'farmer';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? farmLocation,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      farmLocation: farmLocation ?? this.farmLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
