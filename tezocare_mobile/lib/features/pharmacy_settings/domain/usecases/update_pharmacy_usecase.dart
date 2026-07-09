import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pharmacy.dart';
import '../repositories/pharmacy_repository.dart';

class UpdatePharmacyParams {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;

  const UpdatePharmacyParams({
    this.name,
    this.email,
    this.phone,
    this.address,
  });
}

class UpdatePharmacyUseCase {
  final PharmacyRepository repository;

  UpdatePharmacyUseCase({required this.repository});

  Future<Either<Failure, Pharmacy>> call(UpdatePharmacyParams params) {
    return repository.updatePharmacy(
      name: params.name,
      email: params.email,
      phone: params.phone,
      address: params.address,
    );
  }
}
