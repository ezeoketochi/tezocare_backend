import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/staff_model.dart';
import '../models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenModel> login(String email, String password);
  Future<TokenModel> refreshToken(String refreshToken);
  Future<StaffModel> getCurrentUser();
  Future<void> logout();

  Future<void> register(String name, String email, String password);
  Future<void> registerPharmacy({
    required String pharmacyName,
    required String pharmacyEmail,
    String? pharmacyPhone,
    String? pharmacyAddress,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  });
  Future<void> forgotPassword(String email);
  Future<void> verifyOtp(String email, String otp);
  Future<void> resetPassword(String email, String otp, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  AuthRemoteDataSourceImpl({
    required this.dioClient,
    required this.secureStorage,
  });

  @override
  Future<TokenModel> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      debugPrint(
        'Login response: ${response}',
      ); // Debug print for response data
      final tokenModel = TokenModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      await secureStorage.write(
        key: ApiConstants.accessTokenKey,
        value: tokenModel.accessToken,
      );
      await secureStorage.write(
        key: ApiConstants.refreshTokenKey,
        value: tokenModel.refreshToken,
      );
      return tokenModel;
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Login failed');
    }
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      final tokenModel = TokenModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      await secureStorage.write(
        key: ApiConstants.accessTokenKey,
        value: tokenModel.accessToken,
      );
      if (tokenModel.refreshToken.isNotEmpty) {
        await secureStorage.write(
          key: ApiConstants.refreshTokenKey,
          value: tokenModel.refreshToken,
        );
      }
      return tokenModel;
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Token refresh failed');
    }
  }

  @override
  Future<StaffModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.currentUser);
      return StaffModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(
        e,
        defaultMessage: 'Failed to get current user in datasource',
      );
    }
  }

  @override
  Future<void> register(String name, String email, String password) async {
    try {
      await dioClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'pharmacist',
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Registration failed');
    }
  }

  @override
  Future<void> registerPharmacy({
    required String pharmacyName,
    required String pharmacyEmail,
    String? pharmacyPhone,
    String? pharmacyAddress,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {
      final data = <String, dynamic>{
        'pharmacy_name': pharmacyName,
        'pharmacy_email': pharmacyEmail,
        'admin_name': adminName,
        'admin_email': adminEmail,
        'admin_password': adminPassword,
      };
      if (pharmacyPhone != null && pharmacyPhone.isNotEmpty) {
        data['pharmacy_phone'] = pharmacyPhone;
      }
      if (pharmacyAddress != null && pharmacyAddress.isNotEmpty) {
        data['pharmacy_address'] = pharmacyAddress;
      }
      await dioClient.dio.post(
        ApiConstants.registerPharmacy,
        data: data,
      );
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Pharmacy registration failed');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Failed to send OTP');
    }
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    try {
      await dioClient.dio.post(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'OTP verification failed');
    }
  }

  @override
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await dioClient.dio.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e, defaultMessage: 'Password reset failed');
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: ApiConstants.accessTokenKey);
    await secureStorage.delete(key: ApiConstants.refreshTokenKey);
  }

  Exception _mapDioException(DioException e, {required String defaultMessage}) {
    final customException = e.error;
    if (customException is UnauthorizedException) return customException;
    if (customException is ValidationException) return customException;
    if (customException is PermissionException) return customException;
    if (customException is NotFoundException) return customException;
    if (customException is NetworkException) return customException;
    if (customException is ConflictException) return customException;
    if (customException is ServerException) return customException;

    // Fallback — should rarely be hit now
    final data = e.response?.data;
    String message = defaultMessage;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is Map) {
        message = detail['message'] as String? ?? defaultMessage;
      } else if (detail is String) {
        message = detail;
      } else {
        message = data['message'] as String? ?? defaultMessage;
      }
    }

    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
