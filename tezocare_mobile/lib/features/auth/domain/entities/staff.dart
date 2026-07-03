import 'package:equatable/equatable.dart';

class Staff extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? role;
  final bool isActive;
  final DateTime? createdAt;
  final String? pharmacyId;
  final String? pharmacyName;

  const Staff({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    required this.isActive,
    this.createdAt,
    this.pharmacyId,
    this.pharmacyName,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        isActive,
        createdAt,
        pharmacyId,
        pharmacyName,
      ];
}
