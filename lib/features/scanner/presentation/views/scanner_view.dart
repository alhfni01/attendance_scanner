import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show kIsWeb;
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
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed:
    kIsWeb ? DetectionSpeed.noDuplicates : DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: true,
  );

  final Queue<String> _scanQueue = Queue<String>();

  bool _isProcessing = false;
  String? _activeScan;
  String? _lastBarcodeInView;

  Timer? _resultTimer;
  Timer? _barcodePresenceTimer;

  @override
  void dispose() {
    _resultTimer?.cancel();
    _barcodePresenceTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _handleDetectedBarcode(String value) {
    _barcodePresenceTimer?.cancel();

    _barcodePresenceTimer = Timer(
      const Duration(seconds: 3),
          () {
        _lastBarcodeInView = null;
      },
    );

    if (value == _lastBarcodeInView) {
      return;
    }

    _lastBarcodeInView = value;
    _queueScan(value);
  }

  void _queueScan(String value) {
    if (value == _activeScan || _scanQueue.contains(value)) {
      return;
    }

    _scanQueue.addLast(value);

    if (!_isProcessing) {
      unawaited(_processNextScan());
    }
  }

  Future<void> _processNextScan() async {
    if (_isProcessing || _scanQueue.isEmpty || !mounted) {
      return;
    }

    _isProcessing = true;
    final value = _scanQueue.removeFirst();
    _activeScan = value;

    try {
      // على الويب تبقى الكاميرا مفتوحة؛ على التطبيق الأصلي
      // نحافظ على سلوك إيقافها مؤقتًا أثناء معالجة البطاقة.
      if (!kIsWeb) {
        await _cameraController.stop();
      }

      await ref
          .read(scannerProvider.notifier)
          .processScannedCode(value);

      if (kIsWeb) {
        _resultTimer?.cancel();
        _resultTimer = Timer(
          const Duration(milliseconds: 1200),
          _resetScanResult,
        );
      } else {
        await Future<void>.delayed(
          const Duration(milliseconds: 1200),
        );

        if (!mounted) {
          return;
        }

        ref.read(scannerProvider.notifier).resetToIdle();
        await _cameraController.start();
      }
    } catch (error) {
      debugPrint('Scanner handling error: $error');

      if (mounted) {
        ref.read(scannerProvider.notifier).resetToIdle();

        if (!kIsWeb) {
          try {
            await _cameraController.start();
          } catch (cameraError) {
            debugPrint('Camera restart error: $cameraError');
          }
        }
      }
    } finally {
      _activeScan = null;
      _isProcessing = false;

      if (mounted && _scanQueue.isNotEmpty) {
        unawaited(_processNextScan());
      }
    }
  }

  void _resetScanResult() {
    if (!mounted) {
      return;
    }

    ref.read(scannerProvider.notifier).resetToIdle();
  }

  Widget _buildScanResultOverlay(ScanResultState scanState) {
    if (scanState.status == ScanStatusType.idle) {
      return const SizedBox.shrink();
    }

    final bool isSuccess = scanState.status == ScanStatusType.success;
    final bool isDuplicate = scanState.status == ScanStatusType.duplicate;
    final bool isInvalid = scanState.status == ScanStatusType.invalid;

    if (!isSuccess && !isDuplicate && !isInvalid) {
      return const SizedBox.shrink();
    }

    final Color color;
    if (isSuccess) {
      color = Colors.green;
    } else if (isDuplicate) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    final IconData icon =
    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    final String title = isSuccess
        ? 'تم قبول QR'
        : isDuplicate
        ? 'تم تسجيله من قبل'
        : 'تم رفض QR';

    final String subtitle = isSuccess
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
              scale: 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
    final scannerNotifier = ref.read(scannerProvider.notifier);
    final todayRecords = scannerNotifier.todayRecords;
    final todayDate = DateFormatter.formatDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور الجامعي'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(
                Icons.flash_on,
                color: Colors.white,
              ),
              onPressed: _isProcessing
                  ? null
                  : () {
                _cameraController.toggleTorch();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التاريخ الحالي',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            todayDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'تم مسح: ${todayRecords.length} طالبًا',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _cameraController,
                        onDetectError: (error, stackTrace) {
                          debugPrint('MOBILE SCANNER ERROR: $error');
                          debugPrint(stackTrace.toString());
                        },
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            final String? value = barcode.rawValue;

                            if (value != null && value.isNotEmpty) {
                              _handleDetectedBarcode(value);
                              break;
                            }
                          }
                        },
                      ),
                      const ScannerOverlay(),
                      _buildScanResultOverlay(scanState),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RecentScannedCard(scanState: scanState),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('إرسال الكشف'),
                onPressed: () {
                  if (todayRecords.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'لا توجد عمليات مسح. يرجى مسح بطاقة واحدة على الأقل.',
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) => ExportSummaryDialog(
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