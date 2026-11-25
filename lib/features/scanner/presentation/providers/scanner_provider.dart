import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/security/qr_verification_service.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/student_qr_payload.dart';

enum ScanStatusType {
  idle,
  success,
  duplicate,
  invalid,
}

class ScanResultState {
  final ScanStatusType status;
  final String message;
  final AttendanceRecord? record;
  final String? existingTime;

  ScanResultState({
    required this.status,
    required this.message,
    this.record,
    this.existingTime,
  });

  factory ScanResultState.idle() => ScanResultState(
    status: ScanStatusType.idle,
    message: 'وجه الكاميرا نحو بطاقة الطالب',
  );
}

final scannerProvider =
StateNotifierProvider<ScannerNotifier, ScanResultState>(
      (ref) {
    return ScannerNotifier();
  },
);

class ScannerNotifier extends StateNotifier<ScanResultState> {
  ScannerNotifier() : super(ScanResultState.idle());

  bool _isProcessing = false;

  Box get _box => HiveService.getAttendanceBox();

  List<AttendanceRecord> get todayRecords {
    final today = DateFormatter.formatDate(
      DateTime.now(),
    );

    final records = _box.values
        .whereType<AttendanceRecord>()
        .where(
          (record) => record.attendanceDate == today,
    )
        .toList();

    records.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return records;
  }

  Future<void> processScannedCode(
      String rawCode,
      ) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      debugPrint(
        'Scanned Code Payload: $rawCode',
      );

      // ============================================================
      // 1. قراءة بيانات QR
      // ============================================================

      final StudentQRPayload payload =
      StudentQRPayload.fromJsonString(rawCode);

      // ============================================================
      // 2. التحقق من التوقيع الرقمي
      // ============================================================
      //
      // لا نعتمد على البيانات الموجودة داخل QR قبل التأكد
      // أنها صادرة من تطبيق الإدارة باستخدام الـ Private Key.
      //

      final isSignatureValid =
      await QrVerificationService.verify(
        studentId: payload.studentId,
        fullName: payload.fullName,
        universityId: payload.universityId,
        keyId: payload.keyId,
        signatureBase64: payload.signature,
      );

      if (!isSignatureValid) {
        await AudioService.playErrorBeep();

        state = ScanResultState(
          status: ScanStatusType.invalid,
          message:
          'بطاقة QR غير صالحة أو غير معتمدة',
        );

        debugPrint(
          'Rejected QR: invalid digital signature.',
        );

        return;
      }

      debugPrint(
        'QR signature verified successfully.',
      );

      // ============================================================
      // 3. تجهيز بيانات الحضور
      // ============================================================

      final now = DateTime.now();
      final todayStr =
      DateFormatter.formatDate(now);
      final timeStr =
      DateFormatter.formatTime(now);

      // ============================================================
      // 4. التأكد أن الطالب لم يسجل اليوم
      // ============================================================

      AttendanceRecord? existingRecord;

      for (final item in _box.values) {
        if (item is AttendanceRecord &&
            item.studentId == payload.studentId &&
            item.attendanceDate == todayStr) {
          existingRecord = item;
          break;
        }
      }

      if (existingRecord != null) {
        await AudioService.playErrorBeep();

        state = ScanResultState(
          status: ScanStatusType.duplicate,
          message: 'تم تسجيل الطالب مسبقاً',
          record: existingRecord,
          existingTime:
          existingRecord.attendanceTime,
        );

        return;
      }

      // ============================================================
      // 5. إنشاء سجل حضور جديد
      // ============================================================

      final recordId =
          '${payload.studentId}_${now.microsecondsSinceEpoch}';

      final newRecord = AttendanceRecord(
        id: recordId,
        studentId: payload.studentId,
        fullName: payload.fullName,
        universityId: payload.universityId,
        attendanceDate: todayStr,
        attendanceTime: timeStr,
        createdAt: now,
      );

      // ============================================================
      // 6. حفظ السجل في Hive
      // ============================================================

      await _box.put(
        recordId,
        newRecord,
      );

      debugPrint(
        'Attendance saved: ${newRecord.fullName}',
      );

      debugPrint(
        'Total students today: ${todayRecords.length}',
      );

      // ============================================================
      // 7. صوت النجاح
      // ============================================================

      await AudioService.playSuccessBeep();

      // ============================================================
      // 8. عرض آخر طالب تم تسجيله
      // ============================================================

      state = ScanResultState(
        status: ScanStatusType.success,
        message: 'تم تسجيل الحضور بنجاح',
        record: newRecord,
      );
    } on FormatException catch (e) {
      await AudioService.playErrorBeep();

      state = ScanResultState(
        status: ScanStatusType.invalid,
        message: e.message,
      );
    } catch (e) {
      debugPrint(
        'Scanner error: $e',
      );

      await AudioService.playErrorBeep();

      state = ScanResultState(
        status: ScanStatusType.invalid,
        message:
        'تعذر التحقق من بطاقة الطالب',
      );
    }
    finally {
      _isProcessing = false;
    }
  }

  Future<void> clearTodayRecords() async {
    final today = DateFormatter.formatDate(
      DateTime.now(),
    );

    final keysToDelete = _box.values
        .whereType<AttendanceRecord>()
        .where(
          (record) => record.attendanceDate == today,
    )
        .map(
          (record) => record.key,
    )
        .toList();

    await _box.deleteAll(keysToDelete);

    state = ScanResultState.idle();
  }
  void resetToIdle() {
    state = ScanResultState.idle();
  }
}