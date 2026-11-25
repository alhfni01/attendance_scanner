import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/scanner_provider.dart';

class RecentScannedCard extends StatelessWidget {
  final ScanResultState scanState;

  const RecentScannedCard({super.key, required this.scanState});

  @override
  Widget build(BuildContext context) {
    if (scanState.status == ScanStatusType.idle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.textMuted, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'امسح بطاقة الطالب لبدء تسجيل الحضور...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    Color borderColor;
    IconData statusIcon;

    switch (scanState.status) {
      case ScanStatusType.success:
        bgColor = AppColors.successBg;
        borderColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ScanStatusType.duplicate:
        bgColor = AppColors.warningBg;
        borderColor = AppColors.warning;
        statusIcon = Icons.warning_rounded;
        break;
      case ScanStatusType.invalid:
      default:
        bgColor = AppColors.errorBg;
        borderColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
    }

    final record = scanState.record;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: borderColor, size: 24),
              const SizedBox(width: 8),
              Text(
                scanState.message,
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (record != null) ...[
            const Divider(height: 20),
            Text(
              record.fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الرقم الجامعي: ${record.universityId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'الوقت: ${record.attendanceTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}