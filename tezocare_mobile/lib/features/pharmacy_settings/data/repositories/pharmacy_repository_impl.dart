import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_helper.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../datasources/pharmacy_remote_datasource.dart';

class PharmacyRepositoryImpl implements PharmacyRepository {
  final PharmacyRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PharmacyRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Pharmacy>> getPharmacy() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final pharmacy = await remoteDataSource.getPharmacy();
      return Right(pharmacy);
    } catch (e) {
      return handleException(e);
    }
  }

  @override
  Future<Either<Failure, Pharmacy>> updatePharmacy({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final pharmacy = await remoteDataSource.updatePharmacy(
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      return Right(pharmacy);
    } catch (e) {
      return handleException(e);
    }
  }

  @override
  Future<Either<Failure, List<StaffMember>>> listStaff() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final staffList = await remoteDataSource.listStaff();
      return Right(staffList);
    } catch (e) {
      return handleException(e);
    }
  }

  @override
  Future<Either<Failure, StaffMember>> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final staff = await remoteDataSource.createStaff(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return Right(staff);
    } catch (e) {
      return handleException(e);
    }
  }

  @override
  Future<Either<Failure, StaffMember>> updateStaff(
    String staffId, {
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      final staff = await remoteDataSource.updateStaff(
        staffId,
        name: name,
        email: email,
        role: role,
        isActive: isActive,
      );
      return Right(staff);
    } catch (e) {
      return handleException(e);
    }
  }

  @override
  Future<Either<Failure, void>> deactivateStaff(String staffId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
    try {
      await remoteDataSource.deactivateStaff(staffId);
      return const Right(null);
    } catch (e) {
      return handleException(e);
    }
  }
}
