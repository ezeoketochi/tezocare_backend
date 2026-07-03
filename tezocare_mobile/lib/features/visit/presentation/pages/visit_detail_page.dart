// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes/app_colors.dart';
import '../../../../config/themes/app_text_styles.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/dialog/confirm_dialog.dart';
import '../../../../shared/services/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../../domain/entities/visit.dart';
import '../bloc/visit_state.dart';

class VisitDetailPage extends StatefulWidget {
  final String visitId;

  const VisitDetailPage({super.key, required this.visitId});

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<VisitBloc>().add(GetVisitDetailEvent(id: widget.visitId));
  }

  bool _canEdit(Visit visit) {
    try {
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) return false;

      return authState.staff.id == visit.staffId;
    } catch (e) {
      debugPrint('Error checking edit permission: $e');
      return false;
    }
  }

  bool _canDelete(Visit visit) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return false;
      return authState.staff.role == 'admin';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            if (state is VisitDetailLoaded) {
              final visit = state.visit;
              return Row(
                children: [
                  const Text('Visit Detail'),
                  const Spacer(),
                  _buildMenuButton(visit),
                ],
              );
            }
            return const Text('Visit Detail');
          },
        ),
      ),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (context, state) {
          if (state is VisitDeleteSuccess) {
            AppToast.success(context, title: 'Visit deleted');
            context.pop();
          }
        },
        builder: (context, state) {
          final isDeleting =
              state is VisitDetailLoaded && state.isBackgroundUpdating;

          if (state is VisitLoading) {
            return AppLoading.visitDetail();
          }
          if (state is VisitError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: state.message,
              actionLabel: 'Retry',
              onAction: () => context.read<VisitBloc>().add(
                GetVisitDetailEvent(id: widget.visitId),
              ),
            );
          }
          if (state is VisitError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: state.message,
              actionLabel: 'Retry',
              onAction: () => context.read<VisitBloc>().add(
                GetVisitDetailEvent(id: widget.visitId),
              ),
            );
          }

          if (state is VisitDetailLoaded) {
            final visit = state.visit;
            try {
              return AbsorbPointer(
                // 2. Automatically disables all user gestures on the screen when deleting is active
                absorbing: isDeleting,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Pass down the boolean to change the trash icon to a mini progress spinner
                      // _buildStatusHeader(visit, isDeleting: isDeleting),

                      // 4. Inject a clean micro progress bar right beneath the header row
                      if (isDeleting) ...[
                        SizedBox(height: 8.h),
                        const LinearProgressIndicator(
                          color: Colors.red,
                          backgroundColor: Colors.transparent,
                        ),
                      ],

                      SizedBox(height: 12.h),
                      _buildVisitStatusIndicator(visit.status),
                      SizedBox(height: 20.h),
                      _buildInfoCard(visit),
                      if (visit.chiefComplaints.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _buildComplaintsCard(visit),
                      ],
                      _buildAssessmentCard(visit),
                      _buildVitalsCard(visit),
                      if (visit.medicationsDispensed.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _buildMedsCard(visit),
                      ],
                      if (visit.counsellingAdvice != null &&
                          visit.counsellingAdvice!.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _buildCounsellingCard(visit),
                      ],
                      _buildFollowUpCard(visit),
                      _buildReferralCard(visit),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              );
            } catch (e, stack) {
              debugPrint('[VisitDetailPage] build error: $e\n$stack');
              return AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                message: 'Failed to display visit: $e',
                actionLabel: 'Retry',
                onAction: () => context.read<VisitBloc>().add(
                  GetVisitDetailEvent(id: widget.visitId),
                ),
              );
            }
          }
          // if (state is VisitDetailLoaded) {
          //   final visit = state.visit;
          //   try {
          //     return SingleChildScrollView(
          //       padding: EdgeInsets.all(20.w),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           _buildStatusHeader(visit),
          //           SizedBox(height: 12.h),
          //           _buildVisitStatusIndicator(visit.status),
          //           SizedBox(height: 20.h),
          //           _buildInfoCard(visit),
          //           if (visit.chiefComplaints.isNotEmpty) ...[
          //             SizedBox(height: 16.h),
          //             _buildComplaintsCard(visit),
          //           ],
          //           _buildAssessmentCard(visit),
          //           _buildVitalsCard(visit),
          //           if (visit.medicationsDispensed.isNotEmpty) ...[
          //             SizedBox(height: 16.h),
          //             _buildMedsCard(visit),
          //           ],
          //           if (visit.counsellingAdvice != null &&
          //               visit.counsellingAdvice!.isNotEmpty) ...[
          //             SizedBox(height: 16.h),
          //             _buildCounsellingCard(visit),
          //           ],
          //           _buildFollowUpCard(visit),
          //           _buildReferralCard(visit),
          //           SizedBox(height: 24.h),
          //         ],
          //       ),
          //     );
          //   } catch (e, stack) {
          //     debugPrint('[VisitDetailPage] build error: $e\n$stack');
          //     return AppEmptyState(
          //       icon: Icons.error_outline_rounded,
          //       title: 'Something went wrong',
          //       message: ' Failed to display visit: $e',
          //       actionLabel: 'Retry',
          //       onAction: () => context.read<VisitBloc>().add(
          //         GetVisitDetailEvent(id: widget.visitId),
          //       ),
          //     );
          //   }
          // }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMenuButton(Visit visit) {
    final edit = _canEdit(visit);
    final delete = _canDelete(visit);
    if (!edit && !delete) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.push(
              '/patients/${visit.patientId}/visits/${visit.id}/edit',
            );
          case 'delete':
            _confirmDelete(context, visit);
        }
      },
      itemBuilder: (context) => [
        if (edit)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (delete)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('Delete', style: TextStyle(color: AppColors.danger)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Visit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'Delete Visit',
        message:
            'Are you sure you want to delete this visit? This action cannot be undone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      if (context.mounted) {
        context.read<VisitBloc>().add(
          DeleteVisitEvent(id: visit.id, patientId: visit.patientId),
        );
      }
    }
  }

  Widget _buildStatusHeader(Visit visit, {bool isDeleting = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Visit Details', style: AppTextStyles.headlineMedium),
        IconButton(
          // Disable the icon click completely if background tasks are processing
          onPressed: isDeleting
              ? null
              : () => context.read<VisitBloc>().add(
                  DeleteVisitEvent(id: visit.id, patientId: visit.patientId),
                ),
          icon: isDeleting
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
              : const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildVisitStatusIndicator(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'completed':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Completed';
      case 'follow_up_pending':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
        icon = Icons.schedule_rounded;
        label = 'Follow-up Pending';
      case 'referred':
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF7C3AED);
        icon = Icons.swap_horiz_rounded;
        label = 'Referred';
      default:
        bgColor = AppColors.chipActiveBg;
        textColor = AppColors.chipActiveText;
        icon = Icons.circle_rounded;
        label = 'Active';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: textColor),
          SizedBox(width: 8.w),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
              child: Text(title, style: AppTextStyles.titleLarge),
            ),
            ...children,
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(visit) {
    return _buildSectionCard('Visit Info', [
      _detailRow('Date', _formatDate(visit.visitDate)),
      _detailRow(
        'Visit Number',
        visit.visitNumber.isNotEmpty ? visit.visitNumber : '#${visit.id}',
      ),
      _detailRow('Status', visit.status),
      if (visit.patientName != null) _detailRow('Patient', visit.patientName!),
      if (visit.staffName != null) _detailRow('Staff', visit.staffName!),
    ]);
  }

  Widget _buildComplaintsCard(visit) {
    final items = visit.chiefComplaints
        .where((c) => c.complaint != null && c.complaint!.isNotEmpty)
        .map<Widget>((c) {
          final label = (c.duration != null && c.duration!.isNotEmpty)
              ? '${c.complaint} for ${c.duration}'
              : c.complaint!;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          );
        })
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard('Chief Complaints', [
      Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(spacing: 6.w, runSpacing: 4.h, children: items),
        ),
      ),
    ]);
  }

  Widget _buildAssessmentCard(visit) {
    final assessment = visit.clinicalAssessment;
    if (assessment == null) return const SizedBox.shrink();

    final diagnosis = assessment.diagnosis?.isNotEmpty == true
        ? assessment.diagnosis
        : null;
    final severity = assessment.severity?.isNotEmpty == true
        ? assessment.severity
        : null;
    final notes = assessment.pharmacistNotes?.isNotEmpty == true
        ? assessment.pharmacistNotes
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: _buildSectionCard('Clinical Assessment', [
        if (diagnosis != null) _detailRow('Diagnosis', diagnosis),
        if (diagnosis == null)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diagnosis', style: AppTextStyles.bodySmall),
                Text('Not recorded', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        if (severity != null) _detailRow('Severity', severity),
        if (notes != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Text(notes, style: AppTextStyles.bodyMedium),
          ),
      ]),
    );
  }

  Widget _buildVitalsCard(visit) {
    final v = visit.vitals;
    if (v == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vitals', style: AppTextStyles.titleLarge),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 16.sp,
                      color: AppColors.textHint,
                    ),
                    SizedBox(width: 8.w),
                    Text('No vitals recorded', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    if (v.bloodPressureSystolic != null) {
      rows.add(
        _vitalRow(
          'BP',
          '${v.bloodPressureSystolic}/${v.bloodPressureDiastolic ?? "?"}',
          unit: 'mmHg',
        ),
      );
    }
    if (v.heartRate != null) {
      rows.add(_vitalRow('Heart Rate', '${v.heartRate}', unit: 'bpm'));
    }
    if (v.temperature != null) {
      rows.add(_vitalRow('Temperature', '${v.temperature}', unit: '°C'));
    }
    if (v.spo2 != null) rows.add(_vitalRow('SpO2', '${v.spo2}', unit: '%'));
    if (v.weight != null) {
      rows.add(_vitalRow('Weight', '${v.weight}', unit: 'kg'));
    }
    if (v.bmi != null) {
      rows.add(_vitalRow('BMI', v.bmi!.toStringAsFixed(1), unit: 'kg/m²'));
    }
    if (v.glucose != null) {
      rows.add(_vitalRow('Glucose', '${v.glucose}', unit: v.glucoseType ?? ''));
    }

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vitals', style: AppTextStyles.titleLarge),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 16.sp,
                      color: AppColors.textHint,
                    ),
                    SizedBox(width: 8.w),
                    Text('No vitals recorded', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: _buildSectionCard('Vitals', rows),
    );
  }

  Widget _buildMedsCard(visit) {
    return SizedBox(
      width: double.infinity,
      child: _buildSectionCard(
        'Medications Dispensed',
        visit.medicationsDispensed.map<Widget>((m) {
          final name = m.drugName ?? 'Medication';
          final sig = m.sigString;
          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium),
                if (sig.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      sig,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCounsellingCard(visit) {
    return SizedBox(
      width: double.infinity,
      child: _buildSectionCard('Counselling & Advice', [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          child: Text(
            visit.counsellingAdvice!,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ]),
    );
  }

  Widget _buildFollowUpCard(visit) {
    final fu = visit.followUp;

    if (fu == null || !fu.required) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Follow-up', style: AppTextStyles.titleLarge),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 16.sp,
                      color: AppColors.textHint,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'No follow-up scheduled',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isOverdue =
        !fu.isDone &&
        fu.scheduledDate != null &&
        fu.scheduledDate!.isBefore(DateTime.now());

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
              child: Row(
                children: [
                  Text('Follow-up', style: AppTextStyles.titleLarge),
                  const Spacer(),
                  if (isOverdue)
                    Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Overdue',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  StatusChip(
                    text: fu.isDone ? 'Done' : 'Pending',
                    variant: fu.isDone
                        ? StatusChipVariant.completed
                        : StatusChipVariant.active,
                  ),
                ],
              ),
            ),
            if (fu.scheduledDate != null) ...[
              _detailRow('Scheduled Date', _formatDate(fu.scheduledDate!)),
            ],
            if (fu.isDone && fu.dateCompleted != null)
              _detailRow('Date Followed Up', _formatDate(fu.dateCompleted!)),
            if (fu.isDone && fu.outcome != null)
              _detailRow('Outcome', fu.outcome!),
            if (fu.isDone && fu.outcome == null)
              _detailRow('Outcome', 'No outcome recorded'),
            if (fu.isRecurrent)
              _detailRow(
                'Recurrence',
                fu.recurrenceIntervalDays != null
                    ? 'Every ${fu.recurrenceIntervalDays} days'
                    : 'Recurrent',
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(visit) {
    final ref = visit.referral;
    if (ref == null || ref.destination == null || ref.destination!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
              child: Row(
                children: [
                  Text('Referral', style: AppTextStyles.titleLarge),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Referred',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _detailRow('Referred To', ref.destination!),
            if (ref.reason != null && ref.reason!.isNotEmpty)
              _detailRow('Reason', ref.reason!),
            if (visit.createdAt != null)
              _detailRow('Date', _formatDate(visit.createdAt!)),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _vitalRow(String label, String value, {String? unit}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: (unit != null && unit.isNotEmpty)
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.end,
                  )
                : Text(
                    value,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
