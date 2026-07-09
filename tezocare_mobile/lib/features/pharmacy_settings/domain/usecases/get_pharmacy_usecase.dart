import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/pharmacy.dart';
import '../repositories/pharmacy_repository.dart';

class GetPharmacyUseCase implements UseCase<Pharmacy, NoParams> {
  final PharmacyRepository repository;

  GetPharmacyUseCase({required this.repository});

  @override
  Future<Either<Failure, Pharmacy>> call(NoParams params) {
    return repository.getPharmacy();
  }
}
