import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'features/scanner/presentation/views/scanner_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Database
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: AttendanceScannerApp(),
    ),
  );
}

class AttendanceScannerApp extends StatelessWidget {
  const AttendanceScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تسجيل الحضور الجامعي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Arabic Localizations and RTL
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      locale: const Locale('ar', ''),
      home: const ScannerView(),
    );
  }
}