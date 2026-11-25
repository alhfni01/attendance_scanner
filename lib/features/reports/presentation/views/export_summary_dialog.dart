import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../scanner/data/models/attendance_record.dart';
import '../../services/pdf_generator_service.dart';

class ExportSummaryDialog extends StatelessWidget {
  final List records;

  const ExportSummaryDialog({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormatter.formatDate(DateTime.now());

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
          SizedBox(width: 8),
          Text('تأكيد إنشاء كشف الحضور'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التاريخ: $todayStr'),
          const SizedBox(height: 8),
          Text(
            'عدد الطلاب المسجلين: ${records.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            'سيتم إنشاء ملف PDF',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size(120, 45),
          ),
          onPressed: () async {
            Navigator.pop(context);
            await PdfGeneratorService.generateAndShareReport(
              records: records,
              dateStr: todayStr,
            );
          },
          child: const Text('إرسال الكشف'),
        ),
      ],
    );
  }
}