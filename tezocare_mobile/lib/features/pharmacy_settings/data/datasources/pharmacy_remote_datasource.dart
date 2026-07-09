import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pharmacy_model.dart';
import '../models/staff_model.dart';

abstract class PharmacyRemoteDataSource {
  Future<PharmacyModel> getPharmacy();
  Future<PharmacyModel> updatePharmacy({
    String? name,
    String? email,
    String? phone,
    String? address,
  });
  Future<List<StaffMemberModel>> listStaff();
  Future<StaffMemberModel> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<StaffMemberModel> updateStaff(
    String staffId, {
    String? name,
    String? email,
    String? role,
    bool? isActive,
  });
  Future<void> deactivateStaff(String staffId);
}

class PharmacyRemoteDataSourceImpl implements PharmacyRemoteDataSource {
  final DioClient dioClient;

  PharmacyRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PharmacyModel> getPharmacy() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.pharmacyMe);
      return PharmacyModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<PharmacyModel> updatePharmacy({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      final response = await dioClient.dio.patch(
        ApiConstants.pharmacyMe,
        data: data,
      );
      return PharmacyModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<List<StaffMemberModel>> listStaff() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.staffList);
      final dataList = response.data['data'] as List<dynamic>;
      return dataList
          .map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StaffMemberModel> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.authRegister,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return StaffMemberModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StaffMemberModel> updateStaff(
    String staffId, {
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;
      if (isActive != null) data['is_active'] = isActive;
      final response = await dioClient.dio.patch(
        '${ApiConstants.staffDetail}$staffId',
        data: data,
      );
      return StaffMemberModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deactivateStaff(String staffId) async {
    try {
      await dioClient.dio.delete('${ApiConstants.staffDetail}$staffId');
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  Exception _mapException(DioException e) {
    final customException = e.error;
    if (customException is UnauthorizedException) return customException;
    if (customException is ValidationException) return customException;
    if (customException is PermissionException) return customException;
    if (customException is NotFoundException) return customException;
    if (customException is NetworkException) return customException;
    if (customException is ConflictException) return customException;
    if (customException is ServerException) return customException;

    final data = e.response?.data;
    String message = 'Operation failed';
    if (data is Map) {
      final detail = data['detail'];
      if (detail is Map) {
        message = detail['message'] as String? ?? message;
      } else if (detail is String) {
        message = detail;
      } else {
        message = data['message'] as String? ?? message;
      }
    }
    return ServerException(message: message, statusCode: e.response?.statusCode);
  }
}
