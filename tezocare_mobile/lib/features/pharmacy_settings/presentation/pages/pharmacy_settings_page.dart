import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/services/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_section_header.dart';

import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/staff_member.dart';
import '../bloc/pharmacy_settings_bloc.dart';

class PharmacySettingsPage extends StatelessWidget {
  const PharmacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PharmacySettingsBloc>()
        ..add(const LoadPharmacySettings()),
      child: const _PharmacySettingsView(),
    );
  }
}

class _PharmacySettingsView extends StatelessWidget {
  const _PharmacySettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Settings'),
      ),
      body: BlocConsumer<PharmacySettingsBloc, PharmacySettingsState>(
        listener: (context, state) {
          if (state is PharmacySettingsError) {
            AppToast.error(context, title: state.message);
          } else if (state is PharmacySettingsSuccess) {
            AppToast.success(context, title: state.message);
          }
        },
        builder: (context, state) {
          if (state is PharmacySettingsLoading) {
            return AppLoading.profile();
          }
          if (state is PharmacySettingsError &&
              state is! PharmacySettingsLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.sp,
                    color: AppColors.danger,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  AppButton(
                    label: 'Retry',
                    onPressed: () => context
                        .read<PharmacySettingsBloc>()
                        .add(const LoadPharmacySettings()),
                  ),
                ],
              ),
            );
          }

          final pharmacy = _getPharmacy(state);
          final staff = _getStaff(state);
          final isActionLoading = state is PharmacySettingsActionLoading;

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PharmacySettingsBloc>()
                  .add(const LoadPharmacySettings());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPharmacyInfoSection(context, pharmacy, isActionLoading),
                  SizedBox(height: 24.h),
                  _buildStaffSection(context, staff, isActionLoading),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Pharmacy _getPharmacy(PharmacySettingsState state) {
    if (state is PharmacySettingsLoaded) return state.pharmacy;
    if (state is PharmacySettingsActionLoading) return state.pharmacy;
    if (state is PharmacySettingsSuccess) return state.pharmacy;
    return const Pharmacy(
      id: '',
      name: '',
      email: '',
      isActive: true,
    );
  }

  List<StaffMember> _getStaff(PharmacySettingsState state) {
    if (state is PharmacySettingsLoaded) return state.staff;
    if (state is PharmacySettingsActionLoading) return state.staff;
    if (state is PharmacySettingsSuccess) return state.staff;
    return [];
  }

  Widget _buildPharmacyInfoSection(
    BuildContext context,
    Pharmacy pharmacy,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'PHARMACY INFORMATION',
          actionLabel: 'Edit',
          onAction: isLoading
              ? null
              : () => context.push(
                    '/pharmacy-settings/edit',
                    extra: pharmacy,
                  ),
        ),
        SizedBox(height: 4.h),
        AppCard(
          child: Column(
            children: [
              _infoRow(Icons.local_hospital_outlined, 'Name', pharmacy.name),
              _divider(),
              _infoRow(Icons.email_outlined, 'Email', pharmacy.email),
              _divider(),
              _infoRow(
                Icons.phone_outlined,
                'Phone',
                pharmacy.phone ?? 'Not set',
              ),
              _divider(),
              _infoRow(
                Icons.location_on_outlined,
                'Address',
                pharmacy.address ?? 'Not set',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primary),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(
    BuildContext context,
    List<StaffMember> staff,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'STAFF (${staff.length})',
          actionLabel: 'Add Staff',
          onAction: isLoading
              ? null
              : () async {
                  final bloc = context.read<PharmacySettingsBloc>();
                  final result = await context.push<bool>('/pharmacy-settings/add-staff');
                  if (result == true) {
                    bloc.add(const LoadPharmacySettings());
                  }
                },
        ),
        SizedBox(height: 4.h),
        if (staff.isEmpty)
          AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No staff members yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          )
        else
          ...staff.map(
            (member) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildStaffCard(context, member, isLoading),
            ),
          ),
      ],
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    StaffMember member,
    bool isLoading,
  ) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: AppTextStyles.titleMedium,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    member.email,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _roleChip(member.role),
                ],
              ),
            ),
            if (!isLoading && member.role != 'super_admin')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push(
                      '/pharmacy-settings/edit-staff',
                      extra: member,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20.sp,
                      color: AppColors.iconInactive,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (member.isActive && member.role != 'admin')
                    GestureDetector(
                      onTap: () => _confirmDeactivate(context, member.id),
                      child: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20.sp,
                        color: AppColors.danger,
                      ),
                    )
                  else if (!member.isActive)
                    _roleChip('inactive', isDanger: true),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, String staffId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Staff'),
        content: const Text(
          'Are you sure you want to deactivate this staff member? They will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<PharmacySettingsBloc>()
                  .add(DeactivateStaffRequested(staffId: staffId));
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role, {bool isDanger = false}) {
    final label = role.replaceAll('_', ' ');
    final isAdmin = role == 'admin' || role == 'super_admin';
    final Color bgColor;
    final Color textColor;
    if (isDanger) {
      bgColor = AppColors.dangerLight;
      textColor = AppColors.danger;
    } else if (isAdmin) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.primaryLight;
      textColor = AppColors.primary;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Satoshi',
          color: textColor,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: AppColors.border, height: 1, indent: 16.w, endIndent: 16.w);
  }
}
