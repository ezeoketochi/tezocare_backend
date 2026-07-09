import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? pharmacyId;
  final DateTime? createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.pharmacyId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        isActive,
        pharmacyId,
        createdAt,
      ];
}
