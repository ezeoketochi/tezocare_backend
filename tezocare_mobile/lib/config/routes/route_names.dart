class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/';

  static const String patients = '/patients';
  static const String patientDetail = '/patients/:id';
  static const String createPatient = '/patients/create';
  static const String editPatient = '/patients/:id/edit';

  static const String createVisit = '/visits/create';
  static const String visitDetail = '/patients/:patientId/visits/:visitId';
  static const String editVisit = '/patients/:patientId/visits/:visitId/edit';

  static const String medicationsOverview = '/medications';
  static const String dueRefills = '/refills';
  static const String followUp = '/follow-up';

  static const String medications = '/patients/:patientId/medications';
  static const String addMedication = '/patients/:patientId/medications/add';

  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String notifications = '/notifications';

  static const String pharmacySettings = '/pharmacy-settings';
  static const String addStaff = '/pharmacy-settings/add-staff';
  static const String editPharmacy = '/pharmacy-settings/edit';
  static const String editStaff = '/pharmacy-settings/edit-staff';
}
