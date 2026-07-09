import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/services/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/pharmacy.dart';
import '../bloc/pharmacy_settings_bloc.dart';

class EditPharmacyPage extends StatefulWidget {
  final Pharmacy pharmacy;

  const EditPharmacyPage({super.key, required this.pharmacy});

  @override
  State<EditPharmacyPage> createState() => _EditPharmacyPageState();
}

class _EditPharmacyPageState extends State<EditPharmacyPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pharmacy.name);
    _emailController = TextEditingController(text: widget.pharmacy.email);
    _phoneController = TextEditingController(text: widget.pharmacy.phone ?? '');
    _addressController =
        TextEditingController(text: widget.pharmacy.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();

      context.read<PharmacySettingsBloc>().add(
        UpdatePharmacyRequested(
          name: name.isNotEmpty ? name : null,
          email: email.isNotEmpty ? email : null,
          phone: phone.isNotEmpty ? phone : null,
          address: address.isNotEmpty ? address : null,
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
          context.pop();
        } else if (state is PharmacySettingsError) {
          AppToast.error(context, title: state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Pharmacy'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHARMACY DETAILS',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Pharmacy Name',
                  style: AppTextStyles.titleSmall,
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _nameController,
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
                  controller: _emailController,
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
                  controller: _phoneController,
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
                  controller: _addressController,
                  hint: 'Enter pharmacy address',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
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
