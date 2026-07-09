import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/staff_member.dart';
import '../repositories/pharmacy_repository.dart';

class UpdateStaffParams {
  final String staffId;
  final String? name;
  final String? email;
  final String? role;
  final bool? isActive;

  const UpdateStaffParams({
    required this.staffId,
    this.name,
    this.email,
    this.role,
    this.isActive,
  });
}

class UpdateStaffUseCase {
  final PharmacyRepository repository;

  UpdateStaffUseCase({required this.repository});

  Future<Either<Failure, StaffMember>> call(UpdateStaffParams params) {
    return repository.updateStaff(
      params.staffId,
      name: params.name,
      email: params.email,
      role: params.role,
      isActive: params.isActive,
    );
  }
}
