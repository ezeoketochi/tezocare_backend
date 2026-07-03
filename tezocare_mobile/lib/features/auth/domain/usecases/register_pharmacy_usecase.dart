import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterPharmacyUseCase
    implements UseCase<void, RegisterPharmacyParams> {
  final AuthRepository repository;

  RegisterPharmacyUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(RegisterPharmacyParams params) {
    return repository.registerPharmacy(
      pharmacyName: params.pharmacyName,
      pharmacyEmail: params.pharmacyEmail,
      pharmacyPhone: params.pharmacyPhone,
      pharmacyAddress: params.pharmacyAddress,
      adminName: params.adminName,
      adminEmail: params.adminEmail,
      adminPassword: params.adminPassword,
    );
  }
}

class RegisterPharmacyParams extends Equatable {
  final String pharmacyName;
  final String pharmacyEmail;
  final String? pharmacyPhone;
  final String? pharmacyAddress;
  final String adminName;
  final String adminEmail;
  final String adminPassword;

  const RegisterPharmacyParams({
    required this.pharmacyName,
    required this.pharmacyEmail,
    this.pharmacyPhone,
    this.pharmacyAddress,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
  });

  @override
  List<Object?> get props => [
        pharmacyName,
        pharmacyEmail,
        pharmacyPhone,
        pharmacyAddress,
        adminName,
        adminEmail,
        adminPassword,
      ];
}
