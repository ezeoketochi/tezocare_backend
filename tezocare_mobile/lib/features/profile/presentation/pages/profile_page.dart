import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../auth/domain/entities/staff.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return AppLoading.profile();
          }
          final staff = state is AuthAuthenticated ? state.staff : null;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(staff),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      _buildAccountGroup(context, staff),
                      SizedBox(height: 24.h),
                      _buildMoreGroup(context),
                      SizedBox(height: 24.h),
                      _buildLogoutRow(context),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Staff? staff) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(top: 60.h, bottom: 32.h),
      child: Column(
        children: [
          AppAvatar(
            name: staff?.name ?? 'User',
            size: AvatarSize.xlarge,
          ),
          SizedBox(height: 12.h),
          Text(
            staff?.name ?? 'User',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          SizedBox(height: 8.h),
          if (staff?.role != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                staff!.role!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (staff?.pharmacyName != null) ...[
            SizedBox(height: 4.h),
            Text(
              staff!.pharmacyName!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountGroup(BuildContext context, Staff? staff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            'ACCOUNT',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              _menuRow(
                context,
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {},
              ),
              if (staff != null &&
                  (staff.role == 'admin' || staff.role == 'super_admin')) ...[
                _divider(),
                _menuRow(
                  context,
                  icon: Icons.local_hospital_outlined,
                  label: 'Pharmacy Settings',
                  onTap: () => context.push(RouteNames.pharmacySettings),
                ),
              ],
              _divider(),
              _menuRow(
                context,
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => context.push(RouteNames.changePassword),
              ),
              _divider(),
              _menuRow(
                context,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            'MORE',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              _menuRow(
                context,
                icon: Icons.help_outline_rounded,
                label: 'Help Centre',
                onTap: () {},
              ),
              _divider(),
              _menuRow(
                context,
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColors.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.titleMedium,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: AppColors.border, height: 1, indent: 16.w, endIndent: 16.w);
  }

  Widget _buildLogoutRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(
                    const AuthLogoutRequested(),
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 20.sp,
              color: AppColors.danger,
            ),
            SizedBox(width: 8.w),
            Text(
              'Log Out',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
