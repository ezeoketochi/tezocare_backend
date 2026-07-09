import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/staff_member.dart';
import '../repositories/pharmacy_repository.dart';

class ListStaffUseCase implements UseCase<List<StaffMember>, NoParams> {
  final PharmacyRepository repository;

  ListStaffUseCase({required this.repository});

  @override
  Future<Either<Failure, List<StaffMember>>> call(NoParams params) {
    return repository.listStaff();
  }
}
