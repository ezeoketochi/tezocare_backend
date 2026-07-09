import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/usecases/create_staff_usecase.dart';
import '../../domain/usecases/deactivate_staff_usecase.dart';
import '../../domain/usecases/get_pharmacy_usecase.dart';
import '../../domain/usecases/list_staff_usecase.dart';
import '../../domain/usecases/update_pharmacy_usecase.dart';
import '../../domain/usecases/update_staff_usecase.dart';

abstract class PharmacySettingsEvent extends Equatable {
  const PharmacySettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPharmacySettings extends PharmacySettingsEvent {
  const LoadPharmacySettings();
}

class CreateStaffRequested extends PharmacySettingsEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const CreateStaffRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object> get props => [name, email, password, role];
}

class DeactivateStaffRequested extends PharmacySettingsEvent {
  final String staffId;

  const DeactivateStaffRequested({required this.staffId});

  @override
  List<Object> get props => [staffId];
}

class UpdatePharmacyRequested extends PharmacySettingsEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;

  const UpdatePharmacyRequested({
    this.name,
    this.email,
    this.phone,
    this.address,
  });

  @override
  List<Object?> get props => [name, email, phone, address];
}

class UpdateStaffRequested extends PharmacySettingsEvent {
  final String staffId;
  final String? name;
  final String? email;
  final String? role;

  const UpdateStaffRequested({
    required this.staffId,
    this.name,
    this.email,
    this.role,
  });

  @override
  List<Object?> get props => [staffId, name, email, role];
}

abstract class PharmacySettingsState extends Equatable {
  const PharmacySettingsState();

  @override
  List<Object?> get props => [];
}

class PharmacySettingsInitial extends PharmacySettingsState {
  const PharmacySettingsInitial();
}

class PharmacySettingsLoading extends PharmacySettingsState {
  const PharmacySettingsLoading();
}

class PharmacySettingsLoaded extends PharmacySettingsState {
  final Pharmacy pharmacy;
  final List<StaffMember> staff;

  const PharmacySettingsLoaded({
    required this.pharmacy,
    required this.staff,
  });

  @override
  List<Object> get props => [pharmacy, staff];
}

class PharmacySettingsError extends PharmacySettingsState {
  final String message;

  const PharmacySettingsError({required this.message});

  @override
  List<Object> get props => [message];
}

class PharmacySettingsActionLoading extends PharmacySettingsState {
  final Pharmacy pharmacy;
  final List<StaffMember> staff;

  const PharmacySettingsActionLoading({
    required this.pharmacy,
    required this.staff,
  });

  @override
  List<Object> get props => [pharmacy, staff];
}

class PharmacySettingsSuccess extends PharmacySettingsState {
  final Pharmacy pharmacy;
  final List<StaffMember> staff;
  final String message;

  const PharmacySettingsSuccess({
    required this.pharmacy,
    required this.staff,
    required this.message,
  });

  @override
  List<Object> get props => [pharmacy, staff, message];
}

class PharmacySettingsBloc
    extends Bloc<PharmacySettingsEvent, PharmacySettingsState> {
  final GetPharmacyUseCase getPharmacyUseCase;
  final ListStaffUseCase listStaffUseCase;
  final CreateStaffUseCase createStaffUseCase;
  final DeactivateStaffUseCase deactivateStaffUseCase;
  final UpdatePharmacyUseCase updatePharmacyUseCase;
  final UpdateStaffUseCase updateStaffUseCase;

  PharmacySettingsBloc({
    required this.getPharmacyUseCase,
    required this.listStaffUseCase,
    required this.createStaffUseCase,
    required this.deactivateStaffUseCase,
    required this.updatePharmacyUseCase,
    required this.updateStaffUseCase,
  }) : super(const PharmacySettingsInitial()) {
    on<LoadPharmacySettings>(_onLoad);
    on<CreateStaffRequested>(_onCreateStaff);
    on<DeactivateStaffRequested>(_onDeactivateStaff);
    on<UpdatePharmacyRequested>(_onUpdatePharmacy);
    on<UpdateStaffRequested>(_onUpdateStaff);
  }

  Future<void> _onLoad(
    LoadPharmacySettings event,
    Emitter<PharmacySettingsState> emit,
  ) async {
    emit(const PharmacySettingsLoading());
    final pharmacyResult = await getPharmacyUseCase(const NoParams());
    final staffResult = await listStaffUseCase(const NoParams());

    await pharmacyResult.fold(
      (failure) async => emit(
        PharmacySettingsError(message: _failureMessage(failure)),
      ),
      (pharmacy) async {
        await staffResult.fold(
          (failure) async => emit(
            PharmacySettingsError(message: _failureMessage(failure)),
          ),
          (staff) async => emit(
            PharmacySettingsLoaded(pharmacy: pharmacy, staff: staff),
          ),
        );
      },
    );
  }

  Future<void> _onCreateStaff(
    CreateStaffRequested event,
    Emitter<PharmacySettingsState> emit,
  ) async {
    final current = state;
    if (current is PharmacySettingsLoaded) {
      emit(PharmacySettingsActionLoading(
        pharmacy: current.pharmacy,
        staff: current.staff,
      ));
    }
    final result = await createStaffUseCase(
      CreateStaffParams(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      ),
    );
    await result.fold(
      (failure) async {
        if (current is PharmacySettingsLoaded) {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
          emit(current);
        } else {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
        }
      },
      (_) async {
        final staffResult = await listStaffUseCase(const NoParams());
        await staffResult.fold(
          (failure) async => emit(
            PharmacySettingsError(message: _failureMessage(failure)),
          ),
          (staff) async {
            if (current is PharmacySettingsLoaded) {
              emit(PharmacySettingsSuccess(
                pharmacy: current.pharmacy,
                staff: staff,
                message: 'Staff member created successfully',
              ));
            }
          },
        );
      },
    );
  }

  Future<void> _onDeactivateStaff(
    DeactivateStaffRequested event,
    Emitter<PharmacySettingsState> emit,
  ) async {
    final current = state;
    if (current is PharmacySettingsLoaded) {
      emit(PharmacySettingsActionLoading(
        pharmacy: current.pharmacy,
        staff: current.staff,
      ));
    }
    final result = await deactivateStaffUseCase(event.staffId);
    await result.fold(
      (failure) async {
        if (current is PharmacySettingsLoaded) {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
          emit(current);
        } else {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
        }
      },
      (_) async {
        final staffResult = await listStaffUseCase(const NoParams());
        await staffResult.fold(
          (failure) async => emit(
            PharmacySettingsError(message: _failureMessage(failure)),
          ),
          (staff) async {
            if (current is PharmacySettingsLoaded) {
              emit(PharmacySettingsSuccess(
                pharmacy: current.pharmacy,
                staff: staff,
                message: 'Staff member deactivated',
              ));
            }
          },
        );
      },
    );
  }

  Future<void> _onUpdatePharmacy(
    UpdatePharmacyRequested event,
    Emitter<PharmacySettingsState> emit,
  ) async {
    final current = state;
    if (current is PharmacySettingsLoaded) {
      emit(PharmacySettingsActionLoading(
        pharmacy: current.pharmacy,
        staff: current.staff,
      ));
    }
    final result = await updatePharmacyUseCase(
      UpdatePharmacyParams(
        name: event.name,
        email: event.email,
        phone: event.phone,
        address: event.address,
      ),
    );
    await result.fold(
      (failure) async {
        if (current is PharmacySettingsLoaded) {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
          emit(current);
        } else {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
        }
      },
      (pharmacy) async {
        final staffResult = await listStaffUseCase(const NoParams());
        await staffResult.fold(
          (failure) async => emit(
            PharmacySettingsError(message: _failureMessage(failure)),
          ),
          (staff) async => emit(
            PharmacySettingsSuccess(
              pharmacy: pharmacy,
              staff: staff,
              message: 'Pharmacy updated successfully',
            ),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateStaff(
    UpdateStaffRequested event,
    Emitter<PharmacySettingsState> emit,
  ) async {
    final current = state;
    if (current is PharmacySettingsLoaded) {
      emit(PharmacySettingsActionLoading(
        pharmacy: current.pharmacy,
        staff: current.staff,
      ));
    }
    final result = await updateStaffUseCase(
      UpdateStaffParams(
        staffId: event.staffId,
        name: event.name,
        email: event.email,
        role: event.role,
      ),
    );
    await result.fold(
      (failure) async {
        if (current is PharmacySettingsLoaded) {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
          emit(current);
        } else {
          emit(PharmacySettingsError(message: _failureMessage(failure)));
        }
      },
      (_) async {
        final staffResult = await listStaffUseCase(const NoParams());
        await staffResult.fold(
          (failure) async => emit(
            PharmacySettingsError(message: _failureMessage(failure)),
          ),
          (staff) async {
            if (current is PharmacySettingsLoaded) {
              emit(PharmacySettingsSuccess(
                pharmacy: current.pharmacy,
                staff: staff,
                message: 'Staff member updated successfully',
              ));
            }
          },
        );
      },
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
