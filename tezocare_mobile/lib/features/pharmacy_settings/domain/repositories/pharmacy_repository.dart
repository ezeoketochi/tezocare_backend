import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pharmacy.dart';
import '../entities/staff_member.dart';

abstract class PharmacyRepository {
  Future<Either<Failure, Pharmacy>> getPharmacy();
  Future<Either<Failure, Pharmacy>> updatePharmacy({
    String? name,
    String? email,
    String? phone,
    String? address,
  });
  Future<Either<Failure, List<StaffMember>>> listStaff();
  Future<Either<Failure, StaffMember>> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<Either<Failure, void>> deactivateStaff(String staffId);
  Future<Either<Failure, StaffMember>> updateStaff(
    String staffId, {
    String? name,
    String? email,
    String? role,
    bool? isActive,
  });
}
