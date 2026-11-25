import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/scanner/data/models/attendance_record.dart';

class HiveService {
  static const String attendanceBoxName = 'attendance_records_box';

  static Future init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AttendanceRecordAdapter());
    }

    await Hive.openBox(attendanceBoxName);
    debugPrint('Hive Initialized Successfully');
  }

  static Box getAttendanceBox() {
    return Hive.box(attendanceBoxName);
  }
}