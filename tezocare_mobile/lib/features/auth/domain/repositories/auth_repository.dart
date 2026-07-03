import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/staff.dart';
import '../entities/token.dart';

abstract class AuthRepository {
  Future<Either<Failure, Token>> login(String email, String password);
  Future<Either<Failure, Staff>> getCurrentUser();
  Future<Either<Failure, Token>> refreshToken(String refreshToken);
  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> register({
    required String name,
    required String email,
    required String password,
  });
  Future<Either<Failure, void>> registerPharmacy({
    required String pharmacyName,
    required String pharmacyEmail,
    String? pharmacyPhone,
    String? pharmacyAddress,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  });
  Future<Either<Failure, void>> forgotPassword({required String email});
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
  });
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
