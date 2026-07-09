import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/staff_member.dart';
import '../repositories/pharmacy_repository.dart';

class CreateStaffParams {
  final String name;
  final String email;
  final String password;
  final String role;

  const CreateStaffParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class CreateStaffUseCase {
  final PharmacyRepository repository;

  CreateStaffUseCase({required this.repository});

  Future<Either<Failure, StaffMember>> call(CreateStaffParams params) {
    return repository.createStaff(
      name: params.name,
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}
