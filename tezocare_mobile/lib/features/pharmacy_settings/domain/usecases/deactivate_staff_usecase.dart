import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/pharmacy_repository.dart';

class DeactivateStaffUseCase {
  final PharmacyRepository repository;

  DeactivateStaffUseCase({required this.repository});

  Future<Either<Failure, void>> call(String staffId) {
    return repository.deactivateStaff(staffId);
  }
}
