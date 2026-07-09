import 'package:equatable/equatable.dart';

class Pharmacy extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        address,
        isActive,
        createdAt,
        updatedAt,
      ];
}
