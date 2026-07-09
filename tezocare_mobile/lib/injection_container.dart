import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'config/routes/app_router.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/services/local_cache_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/logger.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/pharmacy_settings/data/datasources/pharmacy_remote_datasource.dart';
import 'features/pharmacy_settings/data/repositories/pharmacy_repository_impl.dart';
import 'features/pharmacy_settings/domain/repositories/pharmacy_repository.dart';
import 'features/pharmacy_settings/domain/usecases/create_staff_usecase.dart';
import 'features/pharmacy_settings/domain/usecases/deactivate_staff_usecase.dart';
import 'features/pharmacy_settings/domain/usecases/get_pharmacy_usecase.dart';
import 'features/pharmacy_settings/domain/usecases/list_staff_usecase.dart';
import 'features/pharmacy_settings/domain/usecases/update_pharmacy_usecase.dart';
import 'features/pharmacy_settings/domain/usecases/update_staff_usecase.dart';
import 'features/pharmacy_settings/presentation/bloc/pharmacy_settings_bloc.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/refresh_token_usecase.dart';
import 'features/auth/domain/usecases/register_pharmacy_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/presentation/bloc/auth_form_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'features/follow_up/data/datasources/follow_up_remote_datasource.dart';
import 'features/follow_up/data/repositories/follow_up_repository_impl.dart';
import 'features/follow_up/domain/repositories/follow_up_repository.dart';
import 'features/follow_up/domain/usecases/get_due_follow_ups_usecase.dart';
import 'features/follow_up/domain/usecases/mark_follow_up_done_usecase.dart';
import 'features/refills/data/datasources/refill_remote_datasource.dart';
import 'features/refills/data/repositories/refill_repository_impl.dart';
import 'features/refills/domain/repositories/refill_repository.dart';
import 'features/refills/domain/usecases/get_due_refills_usecase.dart';
import 'features/refills/domain/usecases/mark_refill_contacted_usecase.dart';
import 'features/refills/domain/usecases/mark_refill_fulfilled_usecase.dart';
import 'features/refills/domain/usecases/create_refills_batch_usecase.dart';
import 'features/medication/data/datasources/medication_remote_datasource.dart';
import 'features/medication/data/repositories/medication_repository_impl.dart';
import 'features/medication/domain/repositories/medication_repository.dart';
import 'features/medication/domain/usecases/add_medication_usecase.dart';
import 'features/medication/domain/usecases/deactivate_medication_usecase.dart';
import 'features/medication/domain/usecases/get_patient_medications_usecase.dart';
import 'features/medication/domain/usecases/update_medication_usecase.dart';
import 'features/patient/data/datasources/patient_remote_datasource.dart';
import 'features/patient/data/repositories/patient_repository_impl.dart';
import 'features/patient/domain/repositories/patient_repository.dart';
import 'features/patient/domain/usecases/create_patient_usecase.dart';
import 'features/patient/domain/usecases/get_patient_detail_usecase.dart';
import 'features/patient/domain/usecases/get_patients_usecase.dart';
import 'features/patient/domain/usecases/search_patients_usecase.dart';
import 'features/patient/domain/usecases/update_patient_usecase.dart';
import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/get_notifications_usecase.dart';

import 'features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'features/visit/data/datasources/visit_remote_datasource.dart';
import 'features/visit/data/repositories/visit_repository_impl.dart';
import 'features/visit/domain/repositories/visit_repository.dart';
import 'features/visit/domain/usecases/create_visit_usecase.dart';
import 'features/visit/domain/usecases/delete_visit_usecase.dart';
import 'features/visit/domain/usecases/get_patient_visits_usecase.dart';
import 'features/visit/domain/usecases/get_visit_detail_usecase.dart';
import 'features/visit/domain/usecases/update_visit_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await _initExternalDependencies();
  _initCore();
  _initAuth();
  _initPatient();
  _initVisit();
  _initMedication();
  _initDashboard();
  _initFollowUp();
  _initRefills();
  _initNotifications();
  _initPharmacySettings();
}

Future<void> _initExternalDependencies() async {
  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    ),
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );
}

void _initCore() {
  sl.registerLazySingleton<Logger>(() => Logger.instance);

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectionChecker: sl()),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      dio: sl(),
      secureStorage: sl(),
      connectionChecker: sl(),
      logger: sl(),
    ),
  );

  sl.registerLazySingleton<LocalCacheService>(() => LocalCacheService());

  sl.registerLazySingleton<AppRouter>(() => AppRouter(secureStorage: sl()));
  sl.registerLazySingleton<GoRouter>(() => sl<AppRouter>().router);

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(dio: sl()),
  );
}

void _initAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => LoginUseCase(repository: sl()));
  sl.registerFactory(() => LogoutUseCase(repository: sl()));
  sl.registerFactory(() => RefreshTokenUseCase(repository: sl()));
  sl.registerFactory(() => GetCurrentUserUseCase(repository: sl()));
  sl.registerFactory(() => RegisterUseCase(repository: sl()));
  sl.registerFactory(() => RegisterPharmacyUseCase(repository: sl()));
  sl.registerFactory(() => ForgotPasswordUseCase(repository: sl()));
  sl.registerFactory(() => VerifyOtpUseCase(repository: sl()));
  sl.registerFactory(() => ResetPasswordUseCase(repository: sl()));
  sl.registerFactory(
    () => AuthFormBloc(
      registerUseCase: sl(),
      registerPharmacyUseCase: sl(),
      forgotPasswordUseCase: sl(),
      verifyOtpUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );
}

void _initPatient() {
  sl.registerLazySingleton<PatientRemoteDataSource>(
    () => PatientRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => CreatePatientUseCase(repository: sl()));
  sl.registerFactory(() => GetPatientsUseCase(repository: sl()));
  sl.registerFactory(() => GetPatientDetailUseCase(repository: sl()));
  sl.registerFactory(() => SearchPatientsUseCase(repository: sl()));
  sl.registerFactory(() => UpdatePatientUseCase(repository: sl()));
}

void _initVisit() {
  sl.registerLazySingleton<VisitRemoteDataSource>(
    () => VisitRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => CreateVisitUseCase(repository: sl()));
  sl.registerFactory(() => GetPatientVisitsUseCase(repository: sl()));
  sl.registerFactory(() => GetVisitDetailUseCase(repository: sl()));
  sl.registerFactory(() => DeleteVisitUseCase(repository: sl()));
  sl.registerFactory(() => UpdateVisitUseCase(repository: sl()));
}

void _initMedication() {
  sl.registerLazySingleton<MedicationRemoteDataSource>(
    () => MedicationRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => AddMedicationUseCase(repository: sl()));
  sl.registerFactory(() => GetPatientMedicationsUseCase(repository: sl()));
  sl.registerFactory(() => UpdateMedicationUseCase(repository: sl()));
  sl.registerFactory(() => DeactivateMedicationUseCase(repository: sl()));
}

void _initDashboard() {
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => GetDashboardStatsUseCase(repository: sl()));
}

void _initFollowUp() {
  sl.registerLazySingleton<FollowUpRemoteDataSource>(
    () => FollowUpRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<FollowUpRepository>(
    () => FollowUpRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => GetDueFollowUpsUseCase(repository: sl()));
  sl.registerFactory(() => MarkFollowUpDoneUseCase(repository: sl()));
}

void _initRefills() {
  sl.registerLazySingleton<RefillRemoteDataSource>(
    () => RefillRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<RefillRepository>(
    () => RefillRepositoryImpl(remoteDataSource: sl(), networkInfo: sl(), cacheService: sl()),
  );
  sl.registerFactory(() => GetDueRefillsUseCase(repository: sl()));
  sl.registerFactory(() => MarkRefillContactedUseCase(repository: sl()));
  sl.registerFactory(() => MarkRefillFulfilledUseCase(repository: sl()));
  sl.registerFactory(() => CreateRefillsBatchUseCase(repository: sl()));
}

void _initNotifications() {
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      cacheService: sl(),
    ),
  );
  sl.registerFactory(() => GetNotificationsUseCase(repository: sl()));
  sl.registerFactory(() => MarkNotificationReadUseCase(repository: sl()));
}

void _initPharmacySettings() {
  sl.registerLazySingleton<PharmacyRemoteDataSource>(
    () => PharmacyRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<PharmacyRepository>(
    () => PharmacyRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerFactory(() => GetPharmacyUseCase(repository: sl()));
  sl.registerFactory(() => ListStaffUseCase(repository: sl()));
  sl.registerFactory(() => CreateStaffUseCase(repository: sl()));
  sl.registerFactory(() => DeactivateStaffUseCase(repository: sl()));
  sl.registerFactory(() => UpdatePharmacyUseCase(repository: sl()));
  sl.registerFactory(() => UpdateStaffUseCase(repository: sl()));
  sl.registerFactory(
    () => PharmacySettingsBloc(
      getPharmacyUseCase: sl(),
      listStaffUseCase: sl(),
      createStaffUseCase: sl(),
      deactivateStaffUseCase: sl(),
      updatePharmacyUseCase: sl(),
      updateStaffUseCase: sl(),
    ),
  );
}
