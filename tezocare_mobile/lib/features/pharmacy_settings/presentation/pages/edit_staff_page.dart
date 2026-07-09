import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/services/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/staff_member.dart';
import '../bloc/pharmacy_settings_bloc.dart';

class EditStaffPage extends StatefulWidget {
  final StaffMember staff;

  const EditStaffPage({super.key, required this.staff});

  @override
  State<EditStaffPage> createState() => _EditStaffPageState();
}

class _EditStaffPageState extends State<EditStaffPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _emailController = TextEditingController(text: widget.staff.email);
    _selectedRole = widget.staff.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      context.read<PharmacySettingsBloc>().add(
        UpdateStaffRequested(
          staffId: widget.staff.id,
          name: name.isNotEmpty ? name : null,
          email: email.isNotEmpty ? email : null,
          role: _selectedRole,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PharmacySettingsBloc, PharmacySettingsState>(
      listener: (context, state) {
        if (state is PharmacySettingsSuccess) {
          AppToast.success(context, title: state.message);
          context.pop(true);
        } else if (state is PharmacySettingsError) {
          AppToast.error(context, title: state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Staff Member'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FULL NAME',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Name',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _nameController,
                  hint: 'Enter full name',
                  prefixIcon: Icon(
                    Icons.person_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  'EMAIL ADDRESS',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Email',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _emailController,
                  hint: 'Enter email address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  'ROLE',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Role',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      size: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'pharmacist',
                      child: Text('Pharmacist'),
                    ),
                    DropdownMenuItem(
                      value: 'data_entry',
                      child: Text('Data Entry'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                SizedBox(height: 32.h),
                BlocBuilder<PharmacySettingsBloc, PharmacySettingsState>(
                  builder: (context, state) {
                    final isLoading = state is PharmacySettingsActionLoading;
                    return AppButton(
                      label: 'Save Changes',
                      onPressed: isLoading ? null : _onSave,
                      isLoading: isLoading,
                      isDisabled: isLoading,
                    );
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
