import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/services/app_toast.dart';
import '../bloc/auth_form_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacyNameController = TextEditingController();
  final _pharmacyEmailController = TextEditingController();
  final _pharmacyPhoneController = TextEditingController();
  final _pharmacyAddressController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _pharmacyEmailController.dispose();
    _pharmacyPhoneController.dispose();
    _pharmacyAddressController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthFormBloc>().add(
        RegisterPharmacyRequested(
          pharmacyName: _pharmacyNameController.text.trim(),
          pharmacyEmail: _pharmacyEmailController.text.trim(),
          pharmacyPhone: _pharmacyPhoneController.text.trim(),
          pharmacyAddress: _pharmacyAddressController.text.trim(),
          adminName: _nameController.text.trim(),
          adminEmail: _emailController.text.trim(),
          adminPassword: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthFormBloc, AuthFormState>(
        listener: (context, state) {
          if (state is AuthFormSuccess) {
            AppToast.success(context, title: state.message);
            context.go(RouteNames.login);
          } else if (state is AuthFormError) {
            AppToast.error(context, title: state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 260.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60.h,
                        right: -40.w,
                        child: Container(
                          width: 180.w,
                          height: 180.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40.h,
                        left: -30.w,
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72.w,
                              height: 72.w,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Icon(
                                Icons.local_hospital_rounded,
                                size: 36.sp,
                                color: AppColors.primary,
                              ),
                            ).animate().fadeIn(duration: 500.ms).scaleXY(
                              begin: 0.8,
                              end: 1,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Create Account',
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ).animate().fadeIn(
                              duration: 600.ms,
                              delay: 100.ms,
                            ).slideY(begin: 0.2, end: 0),
                            SizedBox(height: 6.h),
                            Text(
                              'Sign up to get started',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ).animate().fadeIn(
                              duration: 600.ms,
                              delay: 200.ms,
                            ).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.w,
                      vertical: 32.h,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Text(
                              'PHARMACY DETAILS',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Pharmacy Name',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _pharmacyNameController,
                            hint: 'Enter pharmacy name',
                            prefixIcon: Icon(
                              Icons.local_hospital_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter pharmacy name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Pharmacy Email',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _pharmacyEmailController,
                            hint: 'Enter pharmacy email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter pharmacy email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Pharmacy Phone (optional)',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _pharmacyPhoneController,
                            hint: 'Enter pharmacy phone',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Pharmacy Address (optional)',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _pharmacyAddressController,
                            hint: 'Enter pharmacy address',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 28.h),
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Text(
                              'ADMIN DETAILS',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Full Name',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _nameController,
                            hint: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Email Address',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 8.h),
                          AppTextField(
                            controller: _emailController,
                            hint: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
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
                            hint: 'Confirm your password',
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              size: 20.sp,
                              color: AppColors.primary,
                            ),
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32.h),
                          AppButton(
                            label: 'Sign Up',
                            onPressed:
                                state is AuthFormLoading ? null : _onRegister,
                            isLoading: state is AuthFormLoading,
                            isDisabled: state is AuthFormLoading,
                          ),
                          SizedBox(height: 24.h),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go(RouteNames.login),
                              child: Text(
                                'Already have an account? Sign In',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
