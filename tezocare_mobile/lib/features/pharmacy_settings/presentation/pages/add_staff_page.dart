import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/services/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/pharmacy_settings_bloc.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'pharmacist';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreate() {
    if (_formKey.currentState!.validate()) {
      context.read<PharmacySettingsBloc>().add(
        CreateStaffRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
          title: const Text('Add Staff Member'),
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
                SizedBox(height: 20.h),
                Text(
                  'PASSWORD',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Password',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _passwordController,
                  hint: 'Create a password',
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain an uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain a number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  'Confirm Password',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm password',
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm the password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                BlocBuilder<PharmacySettingsBloc, PharmacySettingsState>(
                  builder: (context, state) {
                    final isLoading = state is PharmacySettingsActionLoading;
                    return AppButton(
                      label: 'Create Staff Member',
                      onPressed: isLoading ? null : _onCreate,
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
