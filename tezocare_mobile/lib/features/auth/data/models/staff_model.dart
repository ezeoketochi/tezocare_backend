import '../../domain/entities/staff.dart';

class StaffModel extends Staff {
  const StaffModel({
    required super.id,
    required super.name,
    required super.email,
    super.role,
    required super.isActive,
    super.createdAt,
    super.pharmacyId,
    super.pharmacyName,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacy'] as Map<String, dynamic>?;
    return StaffModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      pharmacyId: json['pharmacy_id'] as String?,
      pharmacyName: pharmacy?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'pharmacy_id': pharmacyId,
    };
  }
}
