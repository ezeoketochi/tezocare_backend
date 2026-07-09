import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:tezocare_mobile/features/follow_up/domain/repositories/follow_up_repository.dart';
import 'package:tezocare_mobile/features/pharmacy_settings/presentation/bloc/pharmacy_settings_bloc.dart';
import 'package:tezocare_mobile/features/pharmacy_settings/presentation/pages/pharmacy_settings_page.dart';
import 'package:tezocare_mobile/features/pharmacy_settings/presentation/pages/add_staff_page.dart';
import 'package:tezocare_mobile/features/pharmacy_settings/presentation/pages/edit_pharmacy_page.dart';
import 'package:tezocare_mobile/features/pharmacy_settings/presentation/pages/edit_staff_page.dart';
import 'package:tezocare_mobile/features/visit/domain/repositories/visit_repository.dart';
import 'package:tezocare_mobile/features/visit/domain/usecases/update_visit_usecase.dart';
import '../../core/constants/api_constants.dart';
import '../../features/auth/presentation/bloc/auth_form_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import '../../features/follow_up/presentation/bloc/follow_up_bloc.dart';
import '../../features/follow_up/domain/usecases/get_due_follow_ups_usecase.dart';
import '../../features/follow_up/domain/usecases/mark_follow_up_done_usecase.dart';
import '../../features/follow_up/presentation/pages/follow_up_page.dart';
import '../../features/refills/presentation/bloc/refill_bloc.dart';
import '../../features/refills/domain/usecases/get_due_refills_usecase.dart';
import '../../features/refills/domain/usecases/mark_refill_contacted_usecase.dart';
import '../../features/refills/domain/usecases/mark_refill_fulfilled_usecase.dart';
import '../../features/refills/domain/usecases/create_refills_batch_usecase.dart';
import '../../features/refills/presentation/pages/due_refills_page.dart';
import '../../features/medication/presentation/bloc/medication_bloc.dart';
import '../../features/medication/domain/usecases/add_medication_usecase.dart';
import '../../features/medication/domain/usecases/deactivate_medication_usecase.dart';
import '../../features/medication/domain/usecases/get_patient_medications_usecase.dart';
import '../../features/medication/domain/usecases/update_medication_usecase.dart';
import '../../features/patient/presentation/bloc/patient_bloc.dart';
import '../../features/patient/domain/usecases/create_patient_usecase.dart';
import '../../features/patient/domain/usecases/get_patient_detail_usecase.dart';
import '../../features/patient/domain/usecases/get_patients_usecase.dart';
import '../../features/patient/domain/usecases/search_patients_usecase.dart';
import '../../features/patient/domain/usecases/update_patient_usecase.dart';
import '../../features/visit/presentation/bloc/visit_bloc.dart';
import '../../features/visit/domain/usecases/create_visit_usecase.dart';
import '../../features/visit/domain/usecases/get_patient_visits_usecase.dart';
import '../../features/visit/domain/usecases/get_visit_detail_usecase.dart';
import '../../features/visit/domain/usecases/delete_visit_usecase.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/medication/presentation/pages/add_medication_page.dart';
import '../../features/medication/presentation/pages/medications_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/patient/presentation/pages/create_patient_page.dart';
import '../../features/patient/presentation/pages/edit_patient_page.dart';
import '../../features/patient/presentation/pages/patient_detail_page.dart';
import '../../features/patient/presentation/pages/patients_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/visit/presentation/pages/create_visit_page.dart';
import '../../features/visit/presentation/pages/visit_detail_page.dart';
import '../../features/visit/presentation/pages/edit_visit_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../injection_container.dart';
import 'not_found_page.dart';
import 'route_names.dart';

class AppRouter {
  final FlutterSecureStorage secureStorage;
  static final ValueNotifier<int> authRefreshNotifier = ValueNotifier<int>(0);

  late final GoRouter router = GoRouter(
    refreshListenable: authRefreshNotifier,
    initialLocation: RouteNames.splash,
    redirect: _redirectLogic,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthFormBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthFormBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthFormBloc>(),
          child: OtpVerificationPage(
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthFormBloc>(),
          child: ResetPasswordPage(
            email: state.uri.queryParameters['email'] ?? '',
            otp: state.uri.queryParameters['otp'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardBloc>(
              create: (_) => DashboardBloc(
                getDashboardStatsUseCase: sl<GetDashboardStatsUseCase>(),
              ),
            ),
          ],
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                name: 'dashboard',
                builder: (context, state) => BlocProvider(
                  create: (_) => PatientBloc(
                    createPatientUseCase: sl<CreatePatientUseCase>(),
                    getPatientsUseCase: sl<GetPatientsUseCase>(),
                    getPatientDetailUseCase: sl<GetPatientDetailUseCase>(),
                    searchPatientsUseCase: sl<SearchPatientsUseCase>(),
                    updatePatientUseCase: sl<UpdatePatientUseCase>(),
                  ),
                  child: const DashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.patients,
                name: 'patients',
                builder: (context, state) => BlocProvider(
                  create: (_) => PatientBloc(
                    createPatientUseCase: sl<CreatePatientUseCase>(),
                    getPatientsUseCase: sl<GetPatientsUseCase>(),
                    getPatientDetailUseCase: sl<GetPatientDetailUseCase>(),
                    searchPatientsUseCase: sl<SearchPatientsUseCase>(),
                    updatePatientUseCase: sl<UpdatePatientUseCase>(),
                  ),
                  child: const PatientsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dueRefills,
                name: 'dueRefills',
                builder: (context, state) => BlocProvider(
                  create: (_) => RefillBloc(
                    getDueRefillsUseCase: sl<GetDueRefillsUseCase>(),
                    markRefillContactedUseCase:
                        sl<MarkRefillContactedUseCase>(),
                    markRefillFulfilledUseCase:
                        sl<MarkRefillFulfilledUseCase>(),
                    createRefillsBatchUseCase: sl<CreateRefillsBatchUseCase>(),
                  ),
                  child: const DueRefillsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.followUp,
                name: 'followUp',
                builder: (context, state) => BlocProvider(
                  create: (_) => FollowUpBloc(
                    getDueFollowUpsUseCase: sl<GetDueFollowUpsUseCase>(),
                    markFollowUpDoneUseCase: sl<MarkFollowUpDoneUseCase>(),
                    followUpRepository: sl<FollowUpRepository>(),
                  ),
                  child: const FollowUpPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/patients/create',
        name: 'createPatient',
        builder: (context, state) => BlocProvider(
          create: (_) => PatientBloc(
            createPatientUseCase: sl<CreatePatientUseCase>(),
            getPatientsUseCase: sl<GetPatientsUseCase>(),
            getPatientDetailUseCase: sl<GetPatientDetailUseCase>(),
            searchPatientsUseCase: sl<SearchPatientsUseCase>(),
            updatePatientUseCase: sl<UpdatePatientUseCase>(),
          ),
          child: const CreatePatientPage(),
        ),
      ),
      GoRoute(
        path: '/patients/:id',
        name: 'patientDetail',
        builder: (context, state) => BlocProvider(
          create: (_) => PatientBloc(
            createPatientUseCase: sl<CreatePatientUseCase>(),
            getPatientsUseCase: sl<GetPatientsUseCase>(),
            getPatientDetailUseCase: sl<GetPatientDetailUseCase>(),
            searchPatientsUseCase: sl<SearchPatientsUseCase>(),
            updatePatientUseCase: sl<UpdatePatientUseCase>(),
          ),
          child: PatientDetailPage(patientId: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editPatient',
            builder: (context, state) => BlocProvider(
              create: (_) => PatientBloc(
                createPatientUseCase: sl<CreatePatientUseCase>(),
                getPatientsUseCase: sl<GetPatientsUseCase>(),
                getPatientDetailUseCase: sl<GetPatientDetailUseCase>(),
                searchPatientsUseCase: sl<SearchPatientsUseCase>(),
                updatePatientUseCase: sl<UpdatePatientUseCase>(),
              ),
              child: EditPatientPage(patientId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'visits/:visitId',
            name: 'visitDetail',
            builder: (context, state) => BlocProvider(
              create: (_) => VisitBloc(
                createVisitUseCase: sl<CreateVisitUseCase>(),
                getPatientVisitsUseCase: sl<GetPatientVisitsUseCase>(),
                getVisitDetailUseCase: sl<GetVisitDetailUseCase>(),
                deleteVisitUseCase: sl<DeleteVisitUseCase>(),
                updateVisitUseCase: sl<UpdateVisitUseCase>(),
                visitRepository: sl<VisitRepository>(),
              ),
              child: VisitDetailPage(visitId: state.pathParameters['visitId']!),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'editVisit',
                builder: (context, state) => BlocProvider(
                  create: (_) => VisitBloc(
                    createVisitUseCase: sl<CreateVisitUseCase>(),
                    getPatientVisitsUseCase: sl<GetPatientVisitsUseCase>(),
                    getVisitDetailUseCase: sl<GetVisitDetailUseCase>(),
                    deleteVisitUseCase: sl<DeleteVisitUseCase>(),
                    updateVisitUseCase: sl<UpdateVisitUseCase>(),
                    visitRepository: sl<VisitRepository>(),
                  ),
                  child: EditVisitPage(
                    visitId: state.pathParameters['visitId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'medications',
            name: 'medications',
            builder: (context, state) => BlocProvider(
              create: (_) => MedicationBloc(
                addMedicationUseCase: sl<AddMedicationUseCase>(),
                getPatientMedicationsUseCase:
                    sl<GetPatientMedicationsUseCase>(),
                updateMedicationUseCase: sl<UpdateMedicationUseCase>(),
                deactivateMedicationUseCase: sl<DeactivateMedicationUseCase>(),
              ),
              child: MedicationsPage(patientId: state.pathParameters['id']),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'addMedication',
                builder: (context, state) => BlocProvider(
                  create: (_) => MedicationBloc(
                    addMedicationUseCase: sl<AddMedicationUseCase>(),
                    getPatientMedicationsUseCase:
                        sl<GetPatientMedicationsUseCase>(),
                    updateMedicationUseCase: sl<UpdateMedicationUseCase>(),
                    deactivateMedicationUseCase:
                        sl<DeactivateMedicationUseCase>(),
                  ),
                  child: AddMedicationPage(
                    patientId: state.pathParameters['id'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.createVisit,
        name: 'createVisit',
        builder: (context, state) => BlocProvider(
          create: (_) => VisitBloc(
            createVisitUseCase: sl<CreateVisitUseCase>(),
            getPatientVisitsUseCase: sl<GetPatientVisitsUseCase>(),
            getVisitDetailUseCase: sl<GetVisitDetailUseCase>(),
            deleteVisitUseCase: sl<DeleteVisitUseCase>(),
            updateVisitUseCase: sl<UpdateVisitUseCase>(),
            visitRepository: sl<VisitRepository>(),
          ),
          child: CreateVisitPage(
            patientId: state.uri.queryParameters['patientId'],
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: RouteNames.pharmacySettings,
        name: 'pharmacySettings',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<PharmacySettingsBloc>(),
          child: const PharmacySettingsPage(),
        ),
        routes: [
          GoRoute(
            path: 'add-staff',
            name: 'addStaff',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => sl<PharmacySettingsBloc>(),
                child: AddStaffPage(),
              );
            },
          ),
          GoRoute(
            path: 'edit',
            name: 'editPharmacy',
            builder: (context, state) {
              final pharmacy = state.extra as dynamic;
              return BlocProvider(
                create: (_) => sl<PharmacySettingsBloc>(),
                child: EditPharmacyPage(pharmacy: pharmacy),
              );
            },
          ),
          GoRoute(
            path: 'edit-staff',
            name: 'editStaff',
            builder: (context, state) {
              final staff = state.extra as dynamic;
              return BlocProvider(
                create: (_) => sl<PharmacySettingsBloc>(),
                child: EditStaffPage(staff: staff),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );

  AppRouter({required this.secureStorage});

  static const _publicRoutes = [
    RouteNames.login,
    RouteNames.splash,
    RouteNames.register,
    RouteNames.forgotPassword,
    RouteNames.verifyOtp,
    RouteNames.resetPassword,
  ];

  Future<String?> _redirectLogic(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated =
        await secureStorage.read(key: ApiConstants.accessTokenKey) != null;
    final location = state.matchedLocation;

    if (!isAuthenticated && !_publicRoutes.contains(location)) {
      return RouteNames.login;
    }

    if (isAuthenticated && location == RouteNames.login) {
      return RouteNames.dashboard;
    }

    if (isAuthenticated && location == RouteNames.splash) {
      return RouteNames.dashboard;
    }

    return null;
  }
}
