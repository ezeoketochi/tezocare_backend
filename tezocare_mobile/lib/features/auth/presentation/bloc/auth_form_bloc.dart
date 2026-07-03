import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/register_pharmacy_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

abstract class AuthFormEvent extends Equatable {
  const AuthFormEvent();

  @override
  List<Object?> get props => [];
}

class RegisterRequested extends AuthFormEvent {
  final String name;
  final String email;
  final String password;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

class RegisterPharmacyRequested extends AuthFormEvent {
  final String pharmacyName;
  final String pharmacyEmail;
  final String? pharmacyPhone;
  final String? pharmacyAddress;
  final String adminName;
  final String adminEmail;
  final String adminPassword;

  const RegisterPharmacyRequested({
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

class ForgotPasswordRequested extends AuthFormEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class VerifyOtpRequested extends AuthFormEvent {
  final String email;
  final String otp;

  const VerifyOtpRequested({required this.email, required this.otp});

  @override
  List<Object> get props => [email, otp];
}

class ResetPasswordRequested extends AuthFormEvent {
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, otp, newPassword];
}

abstract class AuthFormState extends Equatable {
  const AuthFormState();

  @override
  List<Object?> get props => [];
}

class AuthFormInitial extends AuthFormState {
  const AuthFormInitial();
}

class AuthFormLoading extends AuthFormState {
  const AuthFormLoading();
}

class AuthFormSuccess extends AuthFormState {
  final String message;

  const AuthFormSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthFormOtpVerified extends AuthFormState {
  final String email;

  const AuthFormOtpVerified({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthFormError extends AuthFormState {
  final String message;

  const AuthFormError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  final RegisterUseCase registerUseCase;
  final RegisterPharmacyUseCase registerPharmacyUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthFormBloc({
    required this.registerUseCase,
    required this.registerPharmacyUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyOtpUseCase,
    required this.resetPasswordUseCase,
  }) : super(const AuthFormInitial()) {
    on<RegisterRequested>(_onRegister);
    on<RegisterPharmacyRequested>(_onRegisterPharmacy);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormLoading());
    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(AuthFormError(message: _failureMessage(failure))),
      (_) => emit(
        const AuthFormSuccess(message: 'Account created successfully'),
      ),
    );
  }

  Future<void> _onRegisterPharmacy(
    RegisterPharmacyRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormLoading());
    final result = await registerPharmacyUseCase(
      RegisterPharmacyParams(
        pharmacyName: event.pharmacyName,
        pharmacyEmail: event.pharmacyEmail,
        pharmacyPhone: event.pharmacyPhone,
        pharmacyAddress: event.pharmacyAddress,
        adminName: event.adminName,
        adminEmail: event.adminEmail,
        adminPassword: event.adminPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthFormError(message: _failureMessage(failure))),
      (_) => emit(
        const AuthFormSuccess(
          message: 'Pharmacy registered successfully. You can now log in.',
        ),
      ),
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormLoading());
    final result = await forgotPasswordUseCase(
      ForgotPasswordParams(email: event.email),
    );
    result.fold(
      (failure) => emit(AuthFormError(message: _failureMessage(failure))),
      (_) => emit(
        const AuthFormSuccess(
          message: 'If this email is registered, you will receive an OTP.',
        ),
      ),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormLoading());
    final result = await verifyOtpUseCase(
      VerifyOtpParams(email: event.email, otp: event.otp),
    );
    result.fold(
      (failure) => emit(AuthFormError(message: _failureMessage(failure))),
      (_) => emit(AuthFormOtpVerified(email: event.email)),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        email: event.email,
        otp: event.otp,
        newPassword: event.newPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthFormError(message: _failureMessage(failure))),
      (_) => emit(
        const AuthFormSuccess(
          message: 'Password reset successfully. You can now log in.',
        ),
      ),
    );
  }

  String _failureMessage(Failure failure) {
    if (failure is ValidationFailure && failure.errors.isNotEmpty) {
      return failure.errors.values.first.toString();
    }
    return failure.message.isNotEmpty
        ? failure.message
        : 'Something went wrong. Please try again.';
  }
}
