import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../reports/presentation/views/export_summary_dialog.dart';
import '../providers/scanner_provider.dart';
import '../widgets/recent_scanned_card.dart';
import '../widgets/scanner_overlay.dart';

class ScannerView extends ConsumerStatefulWidget {
  const ScannerView({super.key});

  @override
  ConsumerState<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends ConsumerState<ScannerView> {
  final MobileScannerController _cameraController =
  MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: true,
  );

  // يمنع استقبال أي QR جديد أثناء معالجة QR الحالي.
  bool _isCameraLocked = false;

  // مؤقت لإخفاء نتيجة المسح.
  Timer? _resultTimer;

  @override
  void dispose() {
    _resultTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  // ============================================================
  // معالجة عملية المسح بالكامل
  // ============================================================

  Future<void> _handleScan(String value) async {
    // حماية من استقبال أكثر من QR
    if (_isCameraLocked) {
      return;
    }

    _isCameraLocked = true;

    debugPrint('========================================');
    debugPrint('QR SCAN STARTED');
    debugPrint('========================================');

    try {
      // ========================================================
      // 1. إيقاف الكاميرا فوراً
      // ========================================================

      await _cameraController.stop();

      // ========================================================
      // 2. معالجة QR
      // ========================================================

      await ref
          .read(scannerProvider.notifier)
          .processScannedCode(value);

      // ========================================================
      // 3. عرض النتيجة لمدة القفل
      // ========================================================

      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // 4. إخفاء دائرة النتيجة فور انتهاء مدة القفل
      // ========================================================

      ref
          .read(scannerProvider.notifier)
          .resetToIdle();

      // ========================================================
      // 5. تشغيل الكاميرا من جديد
      // ========================================================

      await _cameraController.start();
    } catch (e) {
      debugPrint('Scanner handling error: $e');

      if (mounted) {
        // إخفاء النتيجة حتى في حالة الخطأ
        ref
            .read(scannerProvider.notifier)
            .resetToIdle();

        try {
          await _cameraController.start();
        } catch (cameraError) {
          debugPrint(
            'Camera restart error: $cameraError',
          );
        }
      }
    } finally {
      _isCameraLocked = false;

      debugPrint('========================================');
      debugPrint('QR SCAN READY FOR NEXT STUDENT');
      debugPrint('========================================');
    }
  }

  // ============================================================
  // نتيجة المسح الكبيرة في منتصف الكاميرا
  // ============================================================

  Widget _buildScanResultOverlay(
      ScanResultState scanState,
      ) {
    if (scanState.status == ScanStatusType.idle) {
      return const SizedBox.shrink();
    }

    final bool isSuccess =
        scanState.status == ScanStatusType.success;

    final bool isDuplicate =
        scanState.status == ScanStatusType.duplicate;

    final bool isInvalid =
        scanState.status == ScanStatusType.invalid;

    if (!isSuccess && !isDuplicate && !isInvalid) {
      return const SizedBox.shrink();
    }

    // تحديد اللون حسب النتيجة
    final Color color;

    if (isSuccess) {
      color = Colors.green;
    } else if (isDuplicate) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    // تحديد الأيقونة
    final IconData icon =
    isSuccess
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    // تحديد العنوان
    final String title =
    isSuccess
        ? 'تم قبول QR'
        : isDuplicate
        ? 'تم تسجيله من قبل'
        : 'تم رفض QR';

    // تحديد الوصف
    final String subtitle =
    isSuccess
        ? 'تم تسجيل حضور الطالب بنجاح'
        : isDuplicate
        ? 'هذا الطالب مسجل حضور مسبقاً'
        : 'بطاقة QR غير صالحة';

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // الدائرة الكبيرة
                  // ==================================================

                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.55),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 105,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // العنوان
                  // ==================================================

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // الوصف
                  // ==================================================

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // ==================================================
                  // اسم الطالب
                  // ==================================================

                  if (scanState.record != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      scanState.record!.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);

    final scannerNotifier =
    ref.read(scannerProvider.notifier);

    final todayRecords =
        scannerNotifier.todayRecords;

    final todayDate =
    DateFormatter.formatDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تسجيل الحضور الجامعي',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: _isCameraLocked
                ? null
                : () {
              _cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ======================================================
              // Header Metadata Info
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التاريخ الحالي',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            todayDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Text(
                          'تم مسح: ${todayRecords.length} طالبًا',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ======================================================
              // Camera
              // ======================================================

              Expanded(
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ==================================================
                      // الكاميرا
                      // ==================================================

                      MobileScanner(
                        controller:
                        _cameraController,

                        onDetectError:
                            (error, stackTrace) {
                          debugPrint(
                            '========================================',
                          );
                          debugPrint(
                            'MOBILE SCANNER ERROR',
                          );
                          debugPrint(
                            'ERROR: ${error.toString()}',
                          );
                          debugPrint(
                            'STACK TRACE:',
                          );
                          debugPrint(
                            stackTrace.toString(),
                          );
                          debugPrint(
                            '========================================',
                          );
                        },

                        onDetect: (capture) {
                          // حماية سريعة جداً قبل الدخول
                          // في أي معالجة.
                          if (_isCameraLocked) {
                            return;
                          }

                          for (final barcode
                          in capture.barcodes) {
                            final String? value =
                                barcode.rawValue;

                            if (value != null &&
                                value.isNotEmpty) {
                              _handleScan(value);
                              break;
                            }
                          }
                        },
                      ),

                      // ==================================================
                      // إطار المسح الأصلي
                      // ==================================================

                      const ScannerOverlay(),

                      // ==================================================
                      // نتيجة المسح
                      // أخضر = قبول
                      // أحمر = رفض
                      // ==================================================

                      _buildScanResultOverlay(
                        scanState,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ======================================================
              // Recent Scanned Result Card
              // ======================================================

              RecentScannedCard(
                scanState: scanState,
              ),

              const SizedBox(height: 12),

              // ======================================================
              // Export PDF Button
              // ======================================================

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.accent,
                ),
                icon: const Icon(
                  Icons.send_rounded,
                ),
                label: const Text(
                  'إرسال الكشف',
                ),
                onPressed: () {
                  if (todayRecords.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'لا توجد عمليات مسح. يرجى مسح بطاقة واحدة على الأقل.',
                        ),
                        backgroundColor:
                        AppColors.warning,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (ctx) =>
                        ExportSummaryDialog(
                          records: todayRecords,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}